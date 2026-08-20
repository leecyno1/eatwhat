import 'dart:async';

import 'package:eatwhat_app/core/services/unified_recipe_database_service.dart';
import 'package:eatwhat_app/v2/core/data/models/ai_generation_models.dart';
import 'package:eatwhat_app/v2/core/data/models/dish_model.dart';
import 'package:eatwhat_app/v2/core/data/models/meal_planning_direction.dart';
import 'package:eatwhat_app/v2/core/data/models/recipe_model.dart';
import 'package:eatwhat_app/v2/core/data/models/recipe_pairing_model.dart';
import 'package:eatwhat_app/v2/core/data/models/recommendation_resolution.dart';
import 'package:eatwhat_app/v2/core/data/models/recommendation_telemetry_context.dart';
import 'package:eatwhat_app/v2/core/data/models/taste_inference_input.dart';
import 'package:eatwhat_app/v2/core/data/models/taste_selection_models.dart';
import 'package:eatwhat_app/v2/core/external/platform/meituan_delivery_order_client.dart';
import 'package:eatwhat_app/v2/core/external/platform/platform_types.dart';
import 'package:eatwhat_app/v2/core/navigation/app_v2_router.dart';
import 'package:eatwhat_app/v2/core/services/generation_service.dart';
import 'package:eatwhat_app/v2/core/services/prebuilt_dish_image_catalog_service.dart';
import 'package:eatwhat_app/v2/core/services/v2_favorites_service.dart';
import 'package:eatwhat_app/v2/core/services/v2_howtocook_recipe_service.dart';
import 'package:eatwhat_app/v2/core/services/v2_phase2_recommendation_service.dart';
import 'package:eatwhat_app/v2/core/services/v2_platform_jump_service.dart';
import 'package:eatwhat_app/v2/core/services/v2_preference_feedback_service.dart';
import 'package:eatwhat_app/v2/core/services/v2_recommendation_telemetry_service.dart';
import 'package:eatwhat_app/v2/core/theme/app_colors.dart';
import 'package:eatwhat_app/v2/core/theme/app_tokens.dart';
import 'package:eatwhat_app/v2/features/details/howtocook_library_page.dart';
import 'package:eatwhat_app/v2/features/details/recipe_detail_page.dart';
import 'package:eatwhat_app/v2/features/execution/execution_sheet.dart';
import 'package:eatwhat_app/v2/features/execution/meituan_menu_builder_page.dart';
import 'package:eatwhat_app/v2/features/result/controllers/result_choice_controller.dart';
import 'package:eatwhat_app/v2/features/result/controllers/result_choice_state_coordinator.dart';
import 'package:eatwhat_app/v2/features/result/controllers/result_enrichment_controller.dart';
import 'package:eatwhat_app/v2/features/result/controllers/result_feedback_controller.dart';
import 'package:eatwhat_app/v2/features/result/controllers/result_image_state_controller.dart';
import 'package:eatwhat_app/v2/features/result/controllers/result_pairing_suggestion_controller.dart';
import 'package:eatwhat_app/v2/features/result/widgets/result_action_bar.dart';
import 'package:eatwhat_app/v2/features/result/widgets/result_candidate_rail.dart';
import 'package:eatwhat_app/v2/features/result/widgets/result_execution_shortcuts.dart';
import 'package:eatwhat_app/v2/features/result/widgets/result_feedback_band.dart';
import 'package:eatwhat_app/v2/features/result/widgets/result_hero_media.dart';
import 'package:eatwhat_app/v2/features/result/widgets/result_meal_plan_card.dart';
import 'package:eatwhat_app/v2/features/result/widgets/result_nutrition_summary.dart';
import 'package:eatwhat_app/v2/features/result/widgets/result_pairing_band.dart';
import 'package:eatwhat_app/v2/features/result/widgets/result_recommendation_mode_tabs.dart';
import 'package:eatwhat_app/v2/features/result/widgets/result_status_panels.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
    this.recommendationContext,
    this.recommendationTelemetryService,
    this.imageGenerator,
    this.nutritionLoader,
    this.pairingLoader,
    this.corpusPairingLoader,
    this.imageCatalogService,
    this.dishIntroLoader,
    this.howToCookRecipeService,
    this.platformJumpService,
    this.meituanOrderClient,
    this.meituanLocationResolver,
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
  final RecommendationTelemetryContext? recommendationContext;
  final V2RecommendationTelemetryService? recommendationTelemetryService;
  final RecipeImageGenerator? imageGenerator;
  final NutritionLoader? nutritionLoader;
  final PairingLoader? pairingLoader;
  final CorpusPairingLoader? corpusPairingLoader;
  final PrebuiltDishImageCatalogService? imageCatalogService;
  final DishIntroLoader? dishIntroLoader;
  final V2HowToCookRecipeService? howToCookRecipeService;
  final V2PlatformJumpService? platformJumpService;
  final MeituanDeliveryOrderClient? meituanOrderClient;
  final Future<GeoPoint> Function()? meituanLocationResolver;

  @override
  State<ResultPage> createState() => _ResultPageState();
}

class _ResultPageState extends State<ResultPage> {
  late final ResultChoiceController _choiceController;
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
  late final V2PlatformJumpService _platformJumpService;
  late final V2RecommendationTelemetryService _recommendationTelemetry;
  late final RecommendationTelemetryContext _recommendationContext;
  final V2FavoritesService _favorites = V2FavoritesService.instance;
  final V2PreferenceFeedbackService _feedback =
      V2PreferenceFeedbackService.instance;
  final GenerationService _generation = GenerationService.instance;
  List<PairingSuggestion> _pairings = const [];
  ResultRecommendationMode _recommendationMode =
      ResultRecommendationMode.single;
  bool _isFavorited = false;
  bool _isGeneratingImage = false;
  ResultFeedbackSelection? _feedbackSelection;
  Map<String, String> _thumbUrlByRecipeId = const {};

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
      case 'hybrid':
        return '本地 + AI';
      case 'local_fallback':
        return '本地可靠推荐';
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
      case RecommendationResolutionStatus.hybridResolved:
        return '本地召回 · AI 辅助';
      case RecommendationResolutionStatus.localFallback:
        return '本地可靠推荐';
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

  bool get _isMealMode => _recommendationMode == ResultRecommendationMode.meal;

  List<PairingSuggestion> get _mealPairings {
    final recipe = _choiceController.currentChoice;
    if (recipe == null) return const [];
    return _pairingSuggestionController.completeMealPairings(
      recipe,
      _pairings,
      direction: widget.inferenceInput?.planningDirection ??
          MealPlanningDirection.balanced,
    );
  }

  String get _executionKeyword {
    final recipe = _choiceController.currentChoice;
    if (recipe == null) return '';
    if (!_isMealMode) return recipe.name;
    return [recipe.name, ..._mealPairings.map((pairing) => pairing.title)]
        .join(' ');
  }

  void _setRecommendationMode(ResultRecommendationMode mode) {
    if (_recommendationMode == mode) return;
    HapticFeedback.selectionClick();
    setState(() => _recommendationMode = mode);
  }

  @override
  void initState() {
    super.initState();
    _imageCatalog =
        widget.imageCatalogService ?? PrebuiltDishImageCatalogService.instance;
    _howToCookRecipeService =
        widget.howToCookRecipeService ?? V2HowToCookRecipeService.instance;
    _platformJumpService =
        widget.platformJumpService ?? const V2PlatformJumpService();
    _choiceController = ResultChoiceController(widget.recommendations);
    _recommendationTelemetry = widget.recommendationTelemetryService ??
        V2RecommendationTelemetryService.instance;
    _recommendationContext = widget.recommendationContext ??
        RecommendationTelemetryContext(
          recommendationId: _recommendationTelemetry.createRecommendationId(
            algorithmVersion: V2Phase2RecommendationService.algorithmVersion,
          ),
          algorithmVersion: V2Phase2RecommendationService.algorithmVersion,
          primarySource: widget.primarySource ?? 'unified_db',
          resolutionStatus: _resolvedStatus,
          recalledCount: widget.recalledCount,
          finalCount: widget.recommendations.length,
          latencyMs: 0,
          diversityScore: 0,
          appliedConstraintCount:
              (widget.inferenceInput?.structuredConstraints.labels.length ??
                      0) +
                  (widget.inferenceInput?.dislikedTagLabels.length ?? 0),
        );
    unawaited(
      _recommendationTelemetry.recordExposure(
        context: _recommendationContext,
        recipeIds: widget.recommendations.map((recipe) => recipe.id).toList(),
      ),
    );
    if (_choiceController.hasCurrentChoice) {
      _refreshCurrentChoiceState();
    }
    unawaited(_loadCandidateThumbnails());
  }

  /// Resolves the prebuilt thumbnail for every candidate up front so the
  /// candidate rail can show each dish's photo immediately, matching the
  /// fully prebuilt image library (340/340 dishes).
  Future<void> _loadCandidateThumbnails() async {
    final results = <String, String>{};
    for (final recipe in widget.recommendations) {
      final url = await _imageCatalog.resolveThumbUrl(recipe);
      if (url != null && url.trim().isNotEmpty) {
        results[recipe.id] = url.trim();
      }
    }
    if (!mounted || results.isEmpty) return;
    setState(() {
      _thumbUrlByRecipeId = results;
    });
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
    final isFavorited = await _favorites.isDishFavorited(recipe.dishId);
    await HapticFeedback.lightImpact();
    if (!mounted) return;
    setState(() {
      _isFavorited = isFavorited;
    });
    unawaited(
      _recommendationTelemetry.recordFavoriteToggled(
        context: _recommendationContext,
        recipeId: recipe.id,
        position: _positionFor(recipe),
        isFavorited: isFavorited,
      ),
    );
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
    final currentChoice = _choiceController.currentChoice;
    final nextChoice = _choiceController.nextChoice();
    if (currentChoice == null || nextChoice == null) return;
    unawaited(HapticFeedback.mediumImpact());
    unawaited(
      _recommendationTelemetry.recordReroll(
        context: _recommendationContext,
        fromRecipeId: currentChoice.id,
        toRecipeId: nextChoice.id,
        fromPosition: _positionFor(currentChoice),
        toPosition: _positionFor(nextChoice),
      ),
    );
    _selectChoice(nextChoice, action: 'reroll');
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

  int _positionFor(RecipeModel recipe) {
    final index = _choiceController.availableChoices.indexWhere(
      (candidate) => candidate.id == recipe.id,
    );
    return index < 0 ? 0 : index;
  }

  void _selectChoice(
    RecipeModel recipe, {
    String action = 'candidate_tap',
  }) {
    if (!_choiceController.select(recipe)) return;
    HapticFeedback.selectionClick();
    unawaited(
      _recommendationTelemetry.recordSelection(
        context: _recommendationContext,
        recipeId: recipe.id,
        position: _positionFor(recipe),
        action: action,
      ),
    );
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
    unawaited(
      _recommendationTelemetry.recordTasteFeedback(
        context: _recommendationContext,
        recipeId: currentChoice.id,
        position: _positionFor(currentChoice),
        isPositive: selection == ResultFeedbackSelection.enjoyed,
      ),
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
    unawaited(
      _recommendationTelemetry.recordSelection(
        context: _recommendationContext,
        recipeId: currentChoice.id,
        position: _positionFor(currentChoice),
        action: 'confirm',
      ),
    );
    ExecutionSheet.show(
      context,
      recipe: currentChoice,
      pairings: (_isMealMode ? _mealPairings : _pairings)
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
      recommendationContext: _recommendationContext,
      recommendationPosition: _positionFor(currentChoice),
    );
  }

  Future<void> _openExecutionShortcut(ExecutionPath path) async {
    final recipe = _choiceController.currentChoice;
    if (recipe == null) return;
    unawaited(HapticFeedback.mediumImpact());
    unawaited(_feedback.recordRecipeChosen(recipe.id));
    unawaited(_feedback.recordExecutionPathChosen(path));
    unawaited(
      _recommendationTelemetry.recordExecutionStarted(
        context: _recommendationContext,
        recipeId: recipe.id,
        position: _positionFor(recipe),
        executionPath: path.name,
      ),
    );

    switch (path) {
      case ExecutionPath.cook:
        await _openRecipeDetail(
          recipe,
          startInCookingMode: true,
        );
        return;
      case ExecutionPath.delivery:
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => MeituanMenuBuilderPage(
              intent: ExecutionIntent(
                recipe: recipe,
                pairings: (_isMealMode ? _mealPairings : _pairings)
                    .map(
                      (pairing) => PairingSelection(
                        category: pairing.category,
                        title: pairing.title,
                        subtitle: pairing.subtitle,
                      ),
                    )
                    .toList(),
                sourceTags: _displayTags,
                preferredPath: ExecutionPath.delivery,
                recommendationContext: _recommendationContext,
                recommendationPosition: _positionFor(recipe),
              ),
              client: widget.meituanOrderClient,
              locationResolver: widget.meituanLocationResolver,
            ),
          ),
        );
        return;
      case ExecutionPath.dineIn:
        final opened =
            await _platformJumpService.openDianpingDineIn(_executionKeyword);
        if (!opened && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('暂时无法打开附近餐馆')),
          );
        }
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
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final contentTransitionDuration =
        reduceMotion ? AppMotion.fast : AppMotion.standard;
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
      backgroundColor: AppPalette.night,
      bottomNavigationBar: currentChoice == null
          ? null
          : SafeArea(
              top: false,
              minimum: const EdgeInsets.fromLTRB(
                AppSpacing.lg,
                AppSpacing.xs,
                AppSpacing.lg,
                AppSpacing.sm,
              ),
              child: ResultPrimaryConfirmBar(
                onConfirm: _confirm,
                confirmLabel: _isMealMode ? '就吃这套' : '就吃这个',
              ),
            ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(
            AppSpacing.lg,
            AppSpacing.sm,
            AppSpacing.lg,
            AppSpacing.md,
          ),
          child: Column(
            children: [
              Row(
                children: [
                  const Text('今日推荐板', style: AppTypeNight.microLabel),
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
              const SizedBox(height: 12),
              Expanded(
                child: Container(
                  key: const ValueKey('result-stage-shell'),
                  decoration: AppDecorations.nightCard(radius: AppRadii.lg),
                  child: ClipRRect(
                    borderRadius: AppRadii.panel,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.md,
                        AppSpacing.md,
                        AppSpacing.md,
                        AppSpacing.md,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            '今晚这口，替你收好了',
                            style: AppTypeNight.title,
                          ),
                          const SizedBox(height: AppSpacing.xxs),
                          Text(
                            widget.aiSummary?.trim().isNotEmpty == true
                                ? widget.aiSummary!.trim()
                                : '基于你刚刚的口味表达和偏好轨迹，先把选择缩成一口更像你的答案。',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              color: AppPalette.moonMuted,
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              height: 1.45,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.md),
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
                                            ResultRecommendationModeTabs(
                                              value: _recommendationMode,
                                              onChanged: _setRecommendationMode,
                                            ),
                                            if (!_isMealMode &&
                                                _choiceController
                                                        .availableChoices
                                                        .length >
                                                    1) ...[
                                              const SizedBox(height: 10),
                                              ResultCandidateRail(
                                                key: const ValueKey(
                                                  'result-candidate-rail',
                                                ),
                                                currentChoiceId:
                                                    currentChoice.id,
                                                choices: _choiceController
                                                    .availableChoices,
                                                recalledCount:
                                                    widget.recalledCount,
                                                aiReasonsByRecipeId:
                                                    widget.aiReasonsByRecipeId,
                                                thumbUrlByRecipeId:
                                                    _thumbUrlByRecipeId,
                                                onSelect: _selectChoice,
                                              ),
                                            ],
                                            if (!_isMealMode) ...[
                                              const SizedBox(height: 10),
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
                                              ),
                                            ],
                                            const SizedBox(height: 10),
                                            AnimatedSwitcher(
                                              duration:
                                                  contentTransitionDuration,
                                              reverseDuration:
                                                  contentTransitionDuration,
                                              switchInCurve: AppMotion.enter,
                                              switchOutCurve: AppMotion.enter,
                                              transitionBuilder:
                                                  (child, animation) {
                                                final fade = FadeTransition(
                                                  opacity: animation,
                                                  child: child,
                                                );
                                                if (reduceMotion) {
                                                  return fade;
                                                }
                                                return ScaleTransition(
                                                  scale: Tween<double>(
                                                    begin: 0.97,
                                                    end: 1,
                                                  ).animate(
                                                    CurvedAnimation(
                                                      parent: animation,
                                                      curve: AppMotion.enter,
                                                    ),
                                                  ),
                                                  child: fade,
                                                );
                                              },
                                              child: _isMealMode
                                                  ? ResultMealPlanCard(
                                                      key: ValueKey(
                                                        'meal-${currentChoice.id}',
                                                      ),
                                                      mainDish: currentChoice,
                                                      pairings: _mealPairings,
                                                      partySize: widget
                                                          .inferenceInput
                                                          ?.structuredConstraints
                                                          .partySize,
                                                    )
                                                  : ResultHeroMedia(
                                                      key: ValueKey(
                                                        'single-${currentChoice.id}',
                                                      ),
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
                                            if (_isMealMode) ...[
                                              const SizedBox(height: 10),
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
                                              ),
                                            ],
                                            const SizedBox(height: 12),
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
                                            ),
                                            const SizedBox(height: 12),
                                            Text(
                                              currentChoice.name,
                                              style: AppTypeNight.display,
                                            ),
                                            const SizedBox(height: 8),
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
                                                    color: AppPalette
                                                        .moonlight
                                                        .withValues(
                                                      alpha: 0.82,
                                                    ),
                                                    fontSize: 16,
                                                    fontWeight: FontWeight.w600,
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
                                                      color: AppPalette
                                                          .moonMuted,
                                                      fontSize: 12,
                                                      fontWeight:
                                                          FontWeight.w700,
                                                    ),
                                                  ),
                                                ],
                                              ],
                                            ),
                                            if (!_isMealMode) ...[
                                              const SizedBox(height: 12),
                                              PairingBand(
                                                key: const ValueKey(
                                                  'result-pairing-band',
                                                ),
                                                pairings: _pairings,
                                                loadState: pairingState,
                                              ),
                                            ],
                                            const SizedBox(height: 14),
                                            NutritionSummaryCard(
                                              key: const ValueKey(
                                                'result-nutrition-card',
                                              ),
                                              data: nutrition,
                                              loadState: nutritionState,
                                            ),
                                            const SizedBox(height: 12),
                                            RecommendationExplanationCard(
                                              key: const ValueKey(
                                                'result-explanation-card',
                                              ),
                                              resolutionStatus: _resolvedStatus,
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
                                            const SizedBox(height: 12),
                                            ResultFeedbackBand(
                                              selection: _feedbackSelection,
                                              onEnjoyed: () =>
                                                  _recordResultFeedback(
                                                ResultFeedbackSelection.enjoyed,
                                              ),
                                              onNotForMe: () =>
                                                  _recordResultFeedback(
                                                ResultFeedbackSelection
                                                    .notForMe,
                                              ),
                                            ),
                                            const SizedBox(height: 14),
                                            ResultActionBar(
                                              onReroll: _reroll,
                                              onOpenSimilarRecipes: () =>
                                                  _openHowToCookLibrary(
                                                currentChoice,
                                              ),
                                              onOpenRecipe: () =>
                                                  _openRecipeDetail(
                                                currentChoice,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                          ],
                                        ),
                                      ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
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

    // Local, rule-based explanation when the AI chef is not configured:
    // intersect the dish's own tags with the user's liked tags so the
    // reason names the concrete matches instead of a generic line.
    final liked =
        (widget.inferenceInput?.likedTagLabels ?? const <String>[]).toSet();
    final hits = currentChoice.tags
        .where(liked.contains)
        .take(3)
        .toList(growable: false);
    final ingredients = currentChoice.ingredients.take(2).join('、');
    final buffer = StringBuffer();
    if (hits.isNotEmpty) {
      buffer.write('命中你的偏好：${hits.join('、')}');
      if (ingredients.isNotEmpty) buffer.write('；');
    }
    if (ingredients.isNotEmpty) {
      buffer.write('主料$ingredients，口味扎实');
    }
    if (buffer.isEmpty) {
      final labels = _displayTags.take(3).join('、');
      if (labels.isNotEmpty) {
        return '根据你的口味签名推荐：$labels';
      }
      return '根据你的口味推荐';
    }
    return buffer.toString();
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
        borderRadius: AppRadii.small,
        onTap: onTap,
        child: Ink(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: AppPalette.nightElevated,
            borderRadius: AppRadii.small,
            border: Border.all(color: AppPalette.nightDivider),
          ),
          child: Icon(
            icon,
            color: accent ?? AppPalette.moonlight,
            size: 18,
          ),
        ),
      ),
    );
  }
}
