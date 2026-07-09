import 'dart:async';
import 'dart:ui';

import 'package:eatwhat_app/core/services/unified_recipe_database_service.dart';
import 'package:eatwhat_app/v2/core/data/models/ai_generation_models.dart';
import 'package:eatwhat_app/v2/core/data/models/dish_model.dart';
import 'package:eatwhat_app/v2/core/data/models/recipe_model.dart';
import 'package:eatwhat_app/v2/core/data/models/recipe_pairing_model.dart';
import 'package:eatwhat_app/v2/core/data/models/recommendation_resolution.dart';
import 'package:eatwhat_app/v2/core/data/models/taste_inference_input.dart';
import 'package:eatwhat_app/v2/core/data/models/taste_selection_models.dart';
import 'package:eatwhat_app/v2/core/external/platform/platform_types.dart';
import 'package:eatwhat_app/v2/core/navigation/app_v2_router.dart';
import 'package:eatwhat_app/v2/core/services/generation_service.dart';
import 'package:eatwhat_app/v2/core/services/prebuilt_dish_image_catalog_service.dart';
import 'package:eatwhat_app/v2/core/services/v2_favorites_service.dart';
import 'package:eatwhat_app/v2/core/services/v2_howtocook_recipe_service.dart';
import 'package:eatwhat_app/v2/core/services/v2_preference_feedback_service.dart';
import 'package:eatwhat_app/v2/core/theme/app_colors.dart';
import 'package:eatwhat_app/v2/core/theme/app_tokens.dart';
import 'package:eatwhat_app/v2/features/details/howtocook_library_page.dart';
import 'package:eatwhat_app/v2/features/details/recipe_detail_page.dart';
import 'package:eatwhat_app/v2/features/execution/execution_home_page.dart';
import 'package:eatwhat_app/v2/features/execution/execution_sheet.dart';
import 'package:eatwhat_app/v2/features/home/widgets/floating_editorial_background.dart';
import 'package:eatwhat_app/v2/features/result/controllers/result_choice_controller.dart';
import 'package:eatwhat_app/v2/features/result/controllers/result_choice_state_coordinator.dart';
import 'package:eatwhat_app/v2/features/result/controllers/result_enrichment_controller.dart';
import 'package:eatwhat_app/v2/features/result/controllers/result_execution_intent_controller.dart';
import 'package:eatwhat_app/v2/features/result/controllers/result_feedback_controller.dart';
import 'package:eatwhat_app/v2/features/result/controllers/result_image_state_controller.dart';
import 'package:eatwhat_app/v2/features/result/controllers/result_pairing_suggestion_controller.dart';
import 'package:eatwhat_app/v2/features/result/widgets/result_action_bar.dart';
import 'package:eatwhat_app/v2/features/result/widgets/result_candidate_rail.dart';
import 'package:eatwhat_app/v2/features/result/widgets/result_execution_shortcuts.dart';
import 'package:eatwhat_app/v2/features/result/widgets/result_feedback_band.dart';
import 'package:eatwhat_app/v2/features/result/widgets/result_hero_media.dart';
import 'package:eatwhat_app/v2/features/result/widgets/result_nutrition_summary.dart';
import 'package:eatwhat_app/v2/features/result/widgets/result_pairing_band.dart';
import 'package:eatwhat_app/v2/features/result/widgets/result_status_panels.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';

typedef RecipeImageGenerator = Future<String?> Function(RecipeModel recipe);
typedef NutritionLoader = Future<NutritionAnalysis> Function(
    RecipeModel recipe);
typedef PairingLoader = Future<WinePairing> Function(RecipeModel recipe);
typedef CorpusPairingLoader = Future<List<RecipePairingModel>> Function(
  RecipeModel recipe,
);
typedef DishIntroLoader = Future<String?> Function(
  RecipeModel recipe,
  String? recommendationReason,
  String? userRequirement,
);

class ResultPage extends StatefulWidget {
  const ResultPage({
    super.key,
    required this.recommendations,
    this.fallbackTags = const [],
    this.recallLabels = const [],
    this.recalledCount = 0,
    this.inferenceInput,
    this.aiReasonsByRecipeId = const {},
    this.aiSummary,
    this.resolutionStatus,
    this.primarySource,
    this.imageGenerator,
    this.nutritionLoader,
    this.pairingLoader,
    this.corpusPairingLoader,
    this.imageCatalogService,
    this.dishIntroLoader,
    this.howToCookRecipeService,
  });

  final List<RecipeModel> recommendations;
  final List<String> fallbackTags;
  final List<String> recallLabels;
  final int recalledCount;
  final TasteInferenceInput? inferenceInput;
  final Map<String, String> aiReasonsByRecipeId;
  final String? aiSummary;
  final RecommendationResolutionStatus? resolutionStatus;
  final String? primarySource;
  final RecipeImageGenerator? imageGenerator;
  final NutritionLoader? nutritionLoader;
  final PairingLoader? pairingLoader;
  final CorpusPairingLoader? corpusPairingLoader;
  final PrebuiltDishImageCatalogService? imageCatalogService;
  final DishIntroLoader? dishIntroLoader;
  final V2HowToCookRecipeService? howToCookRecipeService;

  @override
  State<ResultPage> createState() => _ResultPageState();
}

class _ResultPageState extends State<ResultPage> {
  late final ResultChoiceController _choiceController;
  final ResultExecutionIntentController _executionIntentController =
      const ResultExecutionIntentController();
  final ResultFeedbackController _feedbackController = ResultFeedbackController(
    recordRecipeChosen: V2PreferenceFeedbackService.instance.recordRecipeChosen,
    recordPositiveTag: V2PreferenceFeedbackService.instance.recordPositiveTag,
    recordNegativeTag: V2PreferenceFeedbackService.instance.recordNegativeTag,
  );
  final ResultPairingSuggestionController _pairingSuggestionController =
      const ResultPairingSuggestionController();
  final ResultChoiceStateCoordinator<PairingSuggestion>
      _choiceStateCoordinator =
      const ResultChoiceStateCoordinator<PairingSuggestion>();
  final ResultEnrichmentController<PairingSuggestion> _enrichmentController =
      ResultEnrichmentController<PairingSuggestion>();
  final ResultImageStateController _imageStateController =
      ResultImageStateController();
  late final PrebuiltDishImageCatalogService _imageCatalog;
  late final V2HowToCookRecipeService _howToCookRecipeService;
  final V2FavoritesService _favorites = V2FavoritesService.instance;
  final V2PreferenceFeedbackService _feedback =
      V2PreferenceFeedbackService.instance;
  final GenerationService _generation = GenerationService.instance;
  List<PairingSuggestion> _pairings = const [];
  bool _isFavorited = false;
  bool _isGeneratingImage = false;
  ResultFeedbackSelection? _feedbackSelection;

  List<String> get _displayTags {
    if (widget.recallLabels.isNotEmpty) return widget.recallLabels;
    final fromInference = widget.inferenceInput?.likedTagLabels ?? const [];
    if (fromInference.isNotEmpty) return fromInference;
    return widget.fallbackTags;
  }

  RecommendationResolutionStatus get _resolvedStatus {
    return widget.resolutionStatus ??
        (_choiceController.availableChoices.isNotEmpty
            ? RecommendationResolutionStatus.dbResolved
            : RecommendationResolutionStatus.empty);
  }

  String get _displayPrimarySourceLabel {
    final source = widget.primarySource?.trim() ?? '';
    switch (source) {
      case 'unified_db':
        return 'HowToCook 菜谱';
      case 'ai':
        return 'AI 生成';
      case 'empty':
        return '本轮未命中';
      case 'error':
        return '推荐服务异常';
      case '':
        return '推荐结果';
      default:
        return source;
    }
  }

  String get _displayResolutionLabel {
    switch (_resolvedStatus) {
      case RecommendationResolutionStatus.dbResolved:
        return 'HowToCook 优先';
      case RecommendationResolutionStatus.aiResolved:
        return 'AI 生成推荐';
      case RecommendationResolutionStatus.empty:
        return '暂无正式结果';
    }
  }

  ExecutionPath get _preferredPath {
    final preference =
        widget.inferenceInput?.structuredConstraints.executionPreference;
    return switch (preference) {
      TasteExecutionPreference.cook => ExecutionPath.cook,
      TasteExecutionPreference.delivery => ExecutionPath.delivery,
      TasteExecutionPreference.dineIn => ExecutionPath.dineIn,
      TasteExecutionPreference.any || null => ExecutionPath.any,
    };
  }

  @override
  void initState() {
    super.initState();
    _imageCatalog =
        widget.imageCatalogService ?? PrebuiltDishImageCatalogService.instance;
    _howToCookRecipeService =
        widget.howToCookRecipeService ?? V2HowToCookRecipeService.instance;
    _choiceController = ResultChoiceController(widget.recommendations);
    if (_choiceController.hasCurrentChoice) {
      _refreshCurrentChoiceState();
    }
  }

  Future<void> _refreshFavoriteState() async {
    final recipe = _choiceController.currentChoice;
    if (recipe == null) return;
    final isFav = await _favorites.isDishFavorited(recipe.dishId);
    if (!mounted) return;
    setState(() {
      _isFavorited = isFav;
    });
  }

  Future<void> _toggleFavorite() async {
    final recipe = _choiceController.currentChoice;
    if (recipe == null) return;
    await _favorites.toggleFavoriteDish(recipe.dishId);
    await HapticFeedback.lightImpact();
    await _refreshFavoriteState();
  }

  Future<void> _maybeGenerateImageForCurrentChoice({bool force = false}) async {
    final recipe = _choiceController.currentChoice;
    if (recipe == null || _isGeneratingImage) return;

    final prebuiltEntry = await _imageCatalog.resolveEntry(recipe);
    final prebuiltUrl =
        prebuiltEntry == null || prebuiltEntry.heroUrl.trim().isEmpty
            ? null
            : await _imageCatalog.resolveHeroUrl(recipe);
    if (!mounted) return;
    if (prebuiltUrl != null && prebuiltUrl.trim().isNotEmpty) {
      setState(() {
        _imageStateController.markResolved(
          recipe.id,
          source: ImageSourceBadgeData.fromManifest(prebuiltEntry),
        );
      });
      _replaceCurrentChoice(recipe.copyWith(imageUrl: prebuiltUrl.trim()));
      return;
    }

    final existingImageUrl = recipe.imageUrl?.trim() ?? '';
    if (_isRenderableImageSource(existingImageUrl)) {
      setState(() {
        _imageStateController.markExistingImage(recipe.id);
      });
      return;
    }

    if (_isGeneratingImage) return;
    if (!force && _imageStateController.hasFailed(recipe.id)) {
      return;
    }
    setState(() => _isGeneratingImage = true);
    setState(() {
      _imageStateController.markLoading(recipe.id);
    });
    try {
      final url = await (widget.imageGenerator?.call(recipe) ??
          _generation.generateRecipeImageUrl(recipe));
      if (!mounted) return;
      if (url == null || url.trim().isEmpty) {
        setState(() {
          _imageStateController.markFailed(recipe.id);
        });
        return;
      }
      setState(() {
        _imageStateController.markResolved(
          recipe.id,
          source: const ImageSourceBadgeData(
            label: 'AI 生成图',
            tone: ImageSourceTone.ai,
          ),
        );
      });
      _replaceCurrentChoice(recipe.copyWith(imageUrl: url.trim()));
    } catch (_) {
      if (mounted) {
        setState(() {
          _imageStateController.markFailed(recipe.id);
        });
      }
    } finally {
      if (mounted) setState(() => _isGeneratingImage = false);
    }
  }

  Future<void> _loadIntroForCurrentChoice() async {
    final recipe = _choiceController.currentChoice;
    if (recipe == null) return;
    final cached = _enrichmentController.introFor(recipe.id) ?? '';
    if (cached.isNotEmpty || _enrichmentController.isIntroLoading(recipe.id)) {
      return;
    }

    setState(() {
      _enrichmentController.markIntroLoading(recipe.id);
    });

    try {
      final intro = await (widget.dishIntroLoader?.call(
            recipe,
            widget.aiReasonsByRecipeId[recipe.id],
            widget.inferenceInput?.freeformRequirement,
          ) ??
          _generation.generateDishIntroduction(
            recipe,
            recommendationReason: widget.aiReasonsByRecipeId[recipe.id],
            userRequirement: widget.inferenceInput?.freeformRequirement,
          ));
      if (!mounted || _choiceController.currentChoice?.id != recipe.id) return;
      setState(() {
        _enrichmentController.completeIntro(recipe.id, intro);
      });
    } catch (_) {
      if (!mounted || _choiceController.currentChoice?.id != recipe.id) return;
      setState(() {
        _enrichmentController.failIntro(recipe.id);
      });
    }
  }

  void _reroll() {
    final nextChoice = _choiceController.nextChoice();
    if (nextChoice == null) return;
    unawaited(HapticFeedback.mediumImpact());
    _selectChoice(nextChoice);
  }

  Future<void> _loadPairingsForCurrentChoice() async {
    final recipe = _choiceController.currentChoice;
    if (recipe == null) return;
    final cached = _enrichmentController.pairingsFor(recipe.id);
    if (cached != null && cached.isNotEmpty) {
      setState(() {
        _pairings = cached;
      });
      return;
    }
    setState(() {
      _enrichmentController.markPairingsLoading(recipe.id);
    });

    final corpusSuggestions = await _loadCorpusPairingSuggestions(recipe);
    if (corpusSuggestions.isNotEmpty) {
      if (!mounted || _choiceController.currentChoice?.id != recipe.id) return;
      setState(() {
        _pairings = corpusSuggestions;
        _enrichmentController.completePairings(recipe.id, corpusSuggestions);
      });
      return;
    }

    try {
      final drink = await (widget.pairingLoader?.call(recipe) ??
          _generation.getWinePairing(recipe));
      final pairings = <PairingSuggestion>[
        PairingSuggestion(
          category: '饮品',
          title: drink.name,
          subtitle: drink.reason,
          accent: const Color(0xFFF46B40),
          icon: Icons.local_drink_rounded,
        ),
        ..._pairingSuggestionController.buildSidePairings(recipe),
      ];

      if (!mounted || _choiceController.currentChoice?.id != recipe.id) return;
      setState(() {
        _pairings = pairings;
        _enrichmentController.completePairings(recipe.id, pairings);
      });
    } catch (_) {
      if (!mounted || _choiceController.currentChoice?.id != recipe.id) return;
      final fallback = _pairingSuggestionController.buildSidePairings(recipe);
      setState(() {
        _pairings = fallback;
        _enrichmentController.completeFallbackPairings(recipe.id, fallback);
      });
    }
  }

  Future<List<PairingSuggestion>> _loadCorpusPairingSuggestions(
    RecipeModel recipe,
  ) async {
    if (widget.corpusPairingLoader == null && recipe.source != 'unified_db') {
      return const [];
    }
    try {
      final corpusPairings = await (widget.corpusPairingLoader?.call(recipe) ??
          UnifiedRecipeDatabaseService.instance
              .fetchPairingsForDishId(recipe.id));
      return _pairingSuggestionController.buildCorpusPairings(corpusPairings);
    } catch (_) {
      return const [];
    }
  }

  Future<void> _loadNutritionForCurrentChoice() async {
    final recipe = _choiceController.currentChoice;
    if (recipe == null) return;
    final cached = _enrichmentController.nutritionFor(recipe.id);
    if (cached != null) {
      setState(() {
        _enrichmentController.completeNutrition(recipe.id, cached);
      });
      return;
    }

    setState(() {
      _enrichmentController.markNutritionLoading(recipe.id);
    });
    try {
      final nutrition = await (widget.nutritionLoader?.call(recipe) ??
          _generation.getNutritionAnalysis(recipe));
      if (!mounted || _choiceController.currentChoice?.id != recipe.id) return;
      setState(() {
        _enrichmentController.completeNutrition(recipe.id, nutrition);
      });
    } catch (_) {
      if (!mounted || _choiceController.currentChoice?.id != recipe.id) return;
      setState(() {
        _enrichmentController.markNutritionUnavailable(recipe.id);
      });
    }
  }

  void _refreshCurrentChoiceState() {
    if (!_choiceController.hasCurrentChoice) return;
    _refreshFavoriteState();
    _maybeGenerateImageForCurrentChoice();
    _loadIntroForCurrentChoice();
    _loadPairingsForCurrentChoice();
    _loadNutritionForCurrentChoice();
  }

  void _selectChoice(RecipeModel recipe) {
    if (!_choiceController.select(recipe)) return;
    HapticFeedback.selectionClick();
    final selectionState = _choiceStateCoordinator.prepareSelection(
      recipeId: recipe.id,
      enrichmentController: _enrichmentController,
      currentFeedbackSelection: _feedbackSelection,
    );
    setState(() {
      _feedbackSelection = selectionState.feedbackSelection;
      _pairings = selectionState.pairings;
    });
    _refreshCurrentChoiceState();
  }

  Future<void> _recordResultFeedback(ResultFeedbackSelection selection) async {
    final currentChoice = _choiceController.currentChoice;
    if (currentChoice == null) return;
    final message = await _feedbackController.recordFeedback(
      recipeId: currentChoice.id,
      tagIds: widget.inferenceInput?.likedTagIds ?? const [],
      selection: selection,
    );
    await HapticFeedback.selectionClick();
    if (!mounted) return;
    setState(() {
      _feedbackSelection = selection;
    });
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        duration: const Duration(milliseconds: 1300),
      ),
    );
  }

  void _confirm() {
    final currentChoice = _choiceController.currentChoice;
    if (currentChoice == null) return;
    HapticFeedback.mediumImpact();
    _feedback.recordRecipeChosen(currentChoice.id);
    ExecutionSheet.show(
      context,
      recipe: currentChoice,
      pairings: _pairings
          .map(
            (pairing) => PairingSelection(
              category: pairing.category,
              title: pairing.title,
              subtitle: pairing.subtitle,
            ),
          )
          .toList(),
      sourceTags: _displayTags,
      structuredConstraints: widget.inferenceInput?.structuredConstraints,
    );
  }

  ExecutionIntent _executionIntentFor(
    RecipeModel recipe,
    ExecutionPath preferredPath,
  ) {
    return _executionIntentController.buildIntent(
      recipe: recipe,
      preferredPath: preferredPath,
      pairings: _pairings,
      displayTags: _displayTags,
      structuredConstraints: widget.inferenceInput?.structuredConstraints,
    );
  }

  Future<void> _openExecutionShortcut(ExecutionPath path) async {
    final recipe = _choiceController.currentChoice;
    if (recipe == null) return;
    unawaited(HapticFeedback.mediumImpact());
    unawaited(_feedback.recordRecipeChosen(recipe.id));
    unawaited(_feedback.recordExecutionPathChosen(path));

    switch (path) {
      case ExecutionPath.cook:
        await _openRecipeDetail(
          recipe,
          startInCookingMode: true,
        );
        return;
      case ExecutionPath.delivery:
        final intent = _executionIntentFor(recipe, ExecutionPath.delivery);
        if (!mounted) return;
        if (GoRouter.maybeOf(context) != null) {
          await context.push(
            AppV2Routes.executionDelivery,
            extra: AppV2DeliveryExecutionRouteData(intent: intent),
          );
          return;
        }
        if (!mounted) return;
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => DeliveryExecutionPage(intent: intent),
          ),
        );
        return;
      case ExecutionPath.dineIn:
        final intent = _executionIntentFor(recipe, ExecutionPath.dineIn);
        if (!mounted) return;
        if (GoRouter.maybeOf(context) != null) {
          await context.push(
            AppV2Routes.executionDineIn,
            extra: AppV2DineInExecutionRouteData(intent: intent),
          );
          return;
        }
        if (!mounted) return;
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => DineInExecutionPage(intent: intent),
          ),
        );
        return;
      case ExecutionPath.any:
        _confirm();
        return;
    }
  }

  Future<void> _openHowToCookLibrary(RecipeModel recipe) async {
    final initialCategory = _resolveHowToCookCategory(recipe);
    final routeData = AppV2HowToCookLibraryRouteData(
      service: _howToCookRecipeService,
      initialCategory: initialCategory,
    );
    if (GoRouter.maybeOf(context) != null) {
      await context.push(AppV2Routes.howtocookLibrary, extra: routeData);
      return;
    }
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => HowToCookLibraryPage(
          service: _howToCookRecipeService,
          initialCategory: initialCategory,
        ),
      ),
    );
  }

  Future<void> _openRecipeDetail(
    RecipeModel recipe, {
    bool startInCookingMode = false,
  }) async {
    final routeData = AppV2RecipeDetailRouteData(
      recipe: recipe,
      howToCookRecipeService: _howToCookRecipeService,
      startInCookingMode: startInCookingMode,
    );
    if (GoRouter.maybeOf(context) != null) {
      await context.push(AppV2Routes.recipeDetail, extra: routeData);
      return;
    }
    if (!mounted) return;
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (_) => RecipeDetailPage(
          recipe: recipe,
          howToCookRecipeService: _howToCookRecipeService,
          startInCookingMode: startInCookingMode,
        ),
      ),
    );
  }

  void _replaceCurrentChoice(RecipeModel recipe) {
    if (!mounted) return;
    setState(() {
      _choiceController.replaceCurrent(recipe);
    });
  }

  bool _isRenderableImageSource(String value) {
    if (value.isEmpty) return false;
    return value.startsWith('assets/') ||
        value.startsWith('http://') ||
        value.startsWith('https://') ||
        value.startsWith('data:image/');
  }

  void _returnToPreferenceSelection() {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
      return;
    }
    navigator.popUntil((route) => route.isFirst);
  }

  @override
  Widget build(BuildContext context) {
    final currentChoice = _choiceController.currentChoice;
    final viewportHeight = MediaQuery.sizeOf(context).height;
    final heroMediaHeight = viewportHeight < 700 ? 188.0 : 268.0;
    final nutrition = currentChoice == null
        ? null
        : _enrichmentController.nutritionFor(currentChoice.id);
    final pairingState = currentChoice == null
        ? PairingLoadState.loading
        : _enrichmentController.pairingStateFor(currentChoice.id);
    final nutritionState = currentChoice == null
        ? NutritionLoadState.loading
        : _enrichmentController.nutritionStateFor(currentChoice.id);
    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      body: Stack(
        children: [
          const FloatingEditorialBackground(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(
                AppSpacing.lg - 2,
                AppSpacing.sm,
                AppSpacing.lg - 2,
                AppSpacing.lg,
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 9,
                        ),
                        decoration: BoxDecoration(
                          color: AppSurfaces.glassSoft,
                          borderRadius: AppRadii.capsule,
                          border: AppSurfaces.glassBorder,
                        ),
                        child: const Text(
                          '今日推荐板',
                          style: AppType.microLabel,
                        ),
                      ),
                      const Spacer(),
                      _HeaderCircleButton(
                        icon: Icons.arrow_back_ios_new_rounded,
                        onTap: () => Navigator.of(context).popUntil(
                          (route) => route.isFirst,
                        ),
                      ),
                      const SizedBox(width: 10),
                      _HeaderCircleButton(
                        icon: _isFavorited
                            ? Icons.favorite_rounded
                            : Icons.favorite_border_rounded,
                        accent: _isFavorited ? AppColors.sunsetOrange : null,
                        onTap: currentChoice == null ? () {} : _toggleFavorite,
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: Container(
                      key: const ValueKey('result-stage-shell'),
                      decoration: BoxDecoration(
                        borderRadius: AppRadii.hero,
                        border: AppSurfaces.glassBorder,
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white.withValues(alpha: 0.66),
                            Colors.white.withValues(alpha: 0.34),
                          ],
                        ),
                        boxShadow: [
                          ...AppSurfaces.softShadow(
                            const Color(0x33A14D33).withValues(alpha: 0.14),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: AppRadii.hero,
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: BackdropFilter(
                                filter:
                                    ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                                child: const SizedBox.expand(),
                              ),
                            ),
                            Positioned.fill(
                              child: DecoratedBox(
                                decoration: BoxDecoration(
                                  gradient: RadialGradient(
                                    center: const Alignment(0.82, -0.6),
                                    radius: 1.15,
                                    colors: [
                                      AppPalette.chili.withValues(
                                        alpha: 0.12,
                                      ),
                                      Colors.transparent,
                                    ],
                                  ),
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.fromLTRB(
                                AppSpacing.xl - 2,
                                AppSpacing.lg,
                                AppSpacing.xl - 2,
                                AppSpacing.xl - 2,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    '今晚这口，已经替你收束好了',
                                    style: AppType.title,
                                  ),
                                  const SizedBox(height: AppSpacing.xs),
                                  Text(
                                    widget.aiSummary?.trim().isNotEmpty == true
                                        ? widget.aiSummary!.trim()
                                        : '基于你刚刚的口味表达和偏好轨迹，先把选择缩成一口更像你的答案。',
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: TextStyle(
                                      color: AppColors.textPrimary.withValues(
                                        alpha: 0.58,
                                      ),
                                      fontSize: 13,
                                      fontWeight: FontWeight.w600,
                                      height: 1.45,
                                    ),
                                  ),
                                  const SizedBox(height: 18),
                                  Expanded(
                                    child: currentChoice == null
                                        ? EmptyRecommendationState(
                                            tags: _displayTags,
                                            resolutionStatus: _resolvedStatus,
                                            primarySource: widget.primarySource,
                                            onReselect:
                                                _returnToPreferenceSelection,
                                          )
                                        : SingleChildScrollView(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                ResultExecutionShortcuts(
                                                  preferredPath: _preferredPath,
                                                  onCook: () =>
                                                      _openExecutionShortcut(
                                                    ExecutionPath.cook,
                                                  ),
                                                  onDelivery: () =>
                                                      _openExecutionShortcut(
                                                    ExecutionPath.delivery,
                                                  ),
                                                  onDineIn: () =>
                                                      _openExecutionShortcut(
                                                    ExecutionPath.dineIn,
                                                  ),
                                                )
                                                    .animate()
                                                    .fadeIn(delay: 80.ms)
                                                    .slideY(
                                                      begin: 0.08,
                                                      end: 0,
                                                      delay: 80.ms,
                                                    ),
                                                if (_choiceController
                                                        .availableChoices
                                                        .length >
                                                    1) ...[
                                                  const SizedBox(height: 14),
                                                  ResultCandidateRail(
                                                    key: const ValueKey(
                                                      'result-candidate-rail',
                                                    ),
                                                    currentChoiceId:
                                                        currentChoice.id,
                                                    choices: _choiceController
                                                        .availableChoices,
                                                    aiReasonsByRecipeId: widget
                                                        .aiReasonsByRecipeId,
                                                    onSelect: _selectChoice,
                                                  ),
                                                ],
                                                const SizedBox(height: 16),
                                                AnimatedSwitcher(
                                                  duration: const Duration(
                                                    milliseconds: 420,
                                                  ),
                                                  child: ResultHeroMedia(
                                                    key: ValueKey(
                                                        currentChoice.id),
                                                    recipe: currentChoice,
                                                    isGeneratingImage:
                                                        _isGeneratingImage,
                                                    imageLoadState:
                                                        _imageStateController
                                                            .stateFor(
                                                      currentChoice.id,
                                                    ),
                                                    imageSource:
                                                        _imageStateController
                                                            .sourceFor(
                                                      currentChoice.id,
                                                    ),
                                                    onRetryImage: () =>
                                                        _maybeGenerateImageForCurrentChoice(
                                                      force: true,
                                                    ),
                                                    height: heroMediaHeight,
                                                  ),
                                                ),
                                                const SizedBox(height: 16),
                                                Wrap(
                                                  spacing: 8,
                                                  runSpacing: 8,
                                                  children: [
                                                    ResultTagChip(
                                                      label:
                                                          _displayResolutionLabel,
                                                    ),
                                                    ResultTagChip(
                                                      label: _displayPrimarySourceLabel ==
                                                              '推荐结果'
                                                          ? _displayPrimarySourceLabel
                                                          : '来源 $_displayPrimarySourceLabel',
                                                    ),
                                                    for (final tag
                                                        in _displayTags.take(3))
                                                      ResultTagChip(label: tag),
                                                  ],
                                                ).animate().fadeIn().slideX(),
                                                const SizedBox(height: 18),
                                                Text(
                                                  currentChoice.name,
                                                  style: const TextStyle(
                                                    color:
                                                        AppColors.textPrimary,
                                                    fontSize: 38,
                                                    fontWeight: FontWeight.w800,
                                                    fontFamily:
                                                        'SF Pro Rounded',
                                                    height: 1.02,
                                                  ),
                                                ).animate().fadeIn().slideY(
                                                      begin: 0.15,
                                                      end: 0,
                                                    ),
                                                const SizedBox(height: 10),
                                                Column(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    Text(
                                                      _buildDishIntroduction(),
                                                      key: const ValueKey(
                                                        'result-hero-intro',
                                                      ),
                                                      style: TextStyle(
                                                        color: AppColors
                                                            .textPrimary
                                                            .withValues(
                                                          alpha: 0.72,
                                                        ),
                                                        fontSize: 16,
                                                        fontWeight:
                                                            FontWeight.w600,
                                                        height: 1.45,
                                                      ),
                                                    ),
                                                    if (_enrichmentController
                                                        .isIntroLoading(
                                                      currentChoice.id,
                                                    )) ...[
                                                      const SizedBox(height: 8),
                                                      Text(
                                                        '正在整理这道 HowToCook 菜谱简介',
                                                        style: TextStyle(
                                                          color: AppColors
                                                              .textPrimary
                                                              .withValues(
                                                            alpha: 0.42,
                                                          ),
                                                          fontSize: 12,
                                                          fontWeight:
                                                              FontWeight.w700,
                                                        ),
                                                      ),
                                                    ],
                                                  ],
                                                ).animate().fadeIn().slideY(
                                                      begin: 0.15,
                                                      end: 0,
                                                      delay: 100.ms,
                                                    ),
                                                const SizedBox(height: 18),
                                                PairingBand(
                                                  key: const ValueKey(
                                                    'result-pairing-band',
                                                  ),
                                                  pairings: _pairings,
                                                  loadState: pairingState,
                                                )
                                                    .animate()
                                                    .fadeIn(
                                                      delay: 140.ms,
                                                    )
                                                    .slideY(
                                                      begin: 0.08,
                                                      end: 0,
                                                      delay: 140.ms,
                                                    ),
                                                const SizedBox(height: 22),
                                                NutritionSummaryCard(
                                                  key: const ValueKey(
                                                    'result-nutrition-card',
                                                  ),
                                                  data: nutrition,
                                                  loadState: nutritionState,
                                                ),
                                                const SizedBox(height: 18),
                                                RecommendationExplanationCard(
                                                  key: const ValueKey(
                                                    'result-explanation-card',
                                                  ),
                                                  resolutionStatus:
                                                      _resolvedStatus,
                                                  primarySource:
                                                      widget.primarySource,
                                                  recalledCount:
                                                      widget.recalledCount,
                                                  recallLabels: _displayTags,
                                                  constraintLabels: widget
                                                          .inferenceInput
                                                          ?.structuredConstraints
                                                          .labels ??
                                                      const [],
                                                  reason:
                                                      _buildRecommendationSubtitle(),
                                                ),
                                                const SizedBox(height: 16),
                                                ResultFeedbackBand(
                                                  selection: _feedbackSelection,
                                                  onEnjoyed: () =>
                                                      _recordResultFeedback(
                                                    ResultFeedbackSelection
                                                        .enjoyed,
                                                  ),
                                                  onNotForMe: () =>
                                                      _recordResultFeedback(
                                                    ResultFeedbackSelection
                                                        .notForMe,
                                                  ),
                                                ),
                                                const SizedBox(height: 22),
                                                ResultActionBar(
                                                  onReroll: _reroll,
                                                  onConfirm: _confirm,
                                                  onOpenSimilarRecipes: () =>
                                                      _openHowToCookLibrary(
                                                    currentChoice,
                                                  ),
                                                  onOpenRecipe: () =>
                                                      _openRecipeDetail(
                                                    currentChoice,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _resolveHowToCookCategory(RecipeModel recipe) {
    const knownCategories = <String>[
      '荤菜',
      '素菜',
      '汤羹',
      '主食',
      '小吃',
      '凉菜',
    ];
    for (final tag in recipe.tags) {
      final trimmed = tag.trim();
      if (knownCategories.contains(trimmed)) {
        return trimmed;
      }
    }
    return '';
  }

  String _buildRecommendationSubtitle() {
    final currentChoice = _choiceController.currentChoice;
    if (currentChoice == null) {
      return '这轮没有收束出合适的菜，请调整口味签名后再试一次。';
    }

    final reason = widget.aiReasonsByRecipeId[currentChoice.id];
    if (reason != null && reason.trim().isNotEmpty) {
      return reason.trim();
    }

    final summary = widget.aiSummary;
    if (summary != null && summary.trim().isNotEmpty) {
      return summary.trim();
    }

    final labels = _displayTags.take(3).join('、');
    if (labels.isNotEmpty) {
      return '根据你的口味签名推荐：$labels';
    }

    return '根据你的口味推荐';
  }

  String _buildDishIntroduction() {
    final currentChoice = _choiceController.currentChoice;
    if (currentChoice == null) return '';

    final cachedIntro = _enrichmentController.introFor(currentChoice.id) ?? '';
    if (cachedIntro.isNotEmpty) {
      return cachedIntro;
    }

    final description = currentChoice.description.trim();
    if (description.isNotEmpty && !_looksLikePlaceholderText(description)) {
      return description;
    }

    final reason = widget.aiReasonsByRecipeId[currentChoice.id]?.trim() ?? '';
    if (reason.isNotEmpty) {
      return reason;
    }

    final ingredients = currentChoice.ingredients.take(3).join('、');
    if (ingredients.isNotEmpty) {
      return '${currentChoice.name}以$ingredients铺开主体味道，是这轮 HowToCook 候选里更贴近口味的一道。';
    }
    return '${currentChoice.name}是这轮 HowToCook 菜谱里更稳的一道主菜选择。';
  }

  bool _looksLikePlaceholderText(String value) {
    final normalized = value.trim().toLowerCase();
    return normalized.isEmpty ||
        normalized.contains('ai生成') ||
        normalized.contains('平平无奇') ||
        normalized.contains('推荐理由');
  }
}

class _HeaderCircleButton extends StatelessWidget {
  const _HeaderCircleButton({
    required this.icon,
    required this.onTap,
    this.accent,
  });

  final IconData icon;
  final VoidCallback onTap;
  final Color? accent;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Ink(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white.withValues(alpha: 0.5),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.72),
            ),
          ),
          child: Icon(
            icon,
            color: accent ?? AppColors.textPrimary,
            size: 18,
          ),
        ),
      ),
    );
  }
}
