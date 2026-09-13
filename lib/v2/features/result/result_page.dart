import 'dart:async';

import 'package:eatwhat_app/core/services/unified_recipe_database_service.dart';
import 'package:eatwhat_app/core/services/auth_service.dart';
import 'package:eatwhat_app/v2/core/data/models/ai_generation_models.dart';
import 'package:eatwhat_app/v2/core/data/models/dish_model.dart';
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
import 'package:eatwhat_app/v2/core/theme/app_tokens.dart';
import 'package:eatwhat_app/v2/features/auth/auth_sheet.dart';
import 'package:eatwhat_app/v2/features/details/recipe_detail_page.dart';
import 'package:eatwhat_app/v2/features/execution/meituan_menu_builder_page.dart';
import 'package:eatwhat_app/v2/features/result/controllers/result_choice_controller.dart';
import 'package:eatwhat_app/v2/features/result/controllers/result_choice_state_coordinator.dart';
import 'package:eatwhat_app/v2/features/result/controllers/result_enrichment_controller.dart';
import 'package:eatwhat_app/v2/features/result/controllers/result_image_state_controller.dart';
import 'package:eatwhat_app/v2/features/result/controllers/result_pairing_suggestion_controller.dart';
import 'package:eatwhat_app/v2/features/result/widgets/result_action_bar.dart';
import 'package:eatwhat_app/v2/features/result/widgets/result_candidate_rail.dart';
import 'package:eatwhat_app/v2/features/result/widgets/result_hero_media.dart';
import 'package:eatwhat_app/v2/features/result/widgets/result_execution_shortcuts.dart';
import 'package:eatwhat_app/v2/features/result/widgets/result_feedback_band.dart';
import 'package:eatwhat_app/v2/features/result/widgets/result_pairing_band.dart';
import 'package:eatwhat_app/v2/features/result/widgets/result_status_panels.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:url_launcher/url_launcher.dart';

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
    this.aiEnhancement,
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

  /// Background MiniMax refine bundle: the page opens instantly on local
  /// results and this future lands a few seconds later, swapping the reason
  /// line for the chef's words without disturbing whatever the user is
  /// already looking at.
  final Future<Phase2RecommendationBundle>? aiEnhancement;
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

class _ResultPageState extends State<ResultPage>
    with SingleTickerProviderStateMixin {
  late final ResultChoiceController _choiceController;

  /// One-shot entrance choreography: the full-bleed photography settles
  /// from a soft zoom while the overlay layers rise in sequence — a
  /// curtain lift over the night stage. Finite by design so scroll and
  /// test pumps are never held hostage.
  late final AnimationController _entrance;
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

  String get _executionKeyword {
    final recipe = _choiceController.currentChoice;
    if (recipe == null) return '';
    return recipe.name;
  }

  @override
  void initState() {
    super.initState();
    _entrance = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..forward();
    _imageCatalog =
        widget.imageCatalogService ?? PrebuiltDishImageCatalogService.instance;
    _howToCookRecipeService =
        widget.howToCookRecipeService ?? V2HowToCookRecipeService.instance;
    _platformJumpService =
        widget.platformJumpService ?? const V2PlatformJumpService();
    _choiceController = ResultChoiceController(widget.recommendations);
    _reasonsByRecipeId = Map<String, String>.from(widget.aiReasonsByRecipeId);
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
    _listenForAiEnhancement();
  }

  String? _enhancedAiSummary;

  /// AI 点菜师后台重排状态：_aiEnhancing=增强中；_aiEnhanced=已换入 AI 结果。
  bool _aiEnhancing = false;
  bool _aiEnhanced = false;

  /// 每道菜的推荐理由。初始沿用决策页带来的理由，AI 包落地后被覆盖合并。
  late Map<String, String> _reasonsByRecipeId;

  /// Horizontal pager driving the big dish photos.
  final PageController _heroPageController = PageController();

  /// 程序性翻页期间静默 hero_swipe 埋点：AI 换菜的 jumpToPage 与缩略图点选
  /// 的 animateToPage 都会触发 onPageChanged（后者还会途经中间页逐个触发），
  /// 这些是代码驱动的翻页，不能记成用户主动滑动，否则推荐漏斗数据失真。
  bool _muteHeroPageTelemetry = false;

  void _listenForAiEnhancement() {
    final future = widget.aiEnhancement;
    if (future == null) return;
    setState(() => _aiEnhancing = true);
    future.then((bundle) {
      if (!mounted) return;
      setState(() {
        _aiEnhancing = false;
        _aiEnhanced = true;
        final summary = bundle.aiSummary?.trim();
        if (summary != null && summary.isNotEmpty) {
          _enhancedAiSummary = summary;
        }
        // 换入 AI 为每道菜写的组合理由（覆盖/合并本地理由）。
        if (bundle.aiReasonsByRecipeId.isNotEmpty) {
          _reasonsByRecipeId = {
            ..._reasonsByRecipeId,
            ...bundle.aiReasonsByRecipeId,
          };
        }
        // 换入 AI 重排/融合后的候选（含智能组合菜）。
        _applyAiCandidates(bundle.finalRecommendations);
      });
    }).catchError((_) {
      // 本地结果兜底：AI 失败仅熄灭"增强中"，不打扰现有本地候选。
      if (!mounted) return;
      setState(() => _aiEnhancing = false);
    });
  }

  /// AI 包落地后换入重排候选：保留当前正在看的菜（若仍在 AI 名单里），
  /// 大图 PageView 落到其最新索引避免越界，并补齐新候选的缩略图与详情。
  void _applyAiCandidates(List<RecipeModel> aiCandidates) {
    if (aiCandidates.isEmpty) return;
    _choiceController.replaceAllPreserving(aiCandidates);
    final current = _choiceController.currentChoice;
    if (current != null && _heroPageController.hasClients) {
      _muteHeroPageTelemetry = true;
      _heroPageController.jumpToPage(_positionFor(current));
      // jumpToPage 的 onPageChanged 回调在本帧布局时触发，帧末再解除静默。
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _muteHeroPageTelemetry = false;
      });
    }
    unawaited(_loadCandidateThumbnails());
    _refreshCurrentChoiceState();
  }

  String? get _effectiveAiSummary {
    final enhanced = _enhancedAiSummary?.trim();
    if (enhanced != null && enhanced.isNotEmpty) return enhanced;
    final initial = widget.aiSummary?.trim();
    return (initial != null && initial.isNotEmpty) ? initial : null;
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
            _reasonsByRecipeId[recipe.id],
            widget.inferenceInput?.freeformRequirement,
          ) ??
          _generation.generateDishIntroduction(
            recipe,
            recommendationReason: _reasonsByRecipeId[recipe.id],
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

  @override
  void dispose() {
    _heroPageController.dispose();
    _entrance.dispose();
    super.dispose();
  }

  /// Thumbnail tap: switch the choice and slide the big photo to match.
  void _selectChoiceWithHero(RecipeModel recipe) {
    final choices = _choiceController.availableChoices;
    final index = choices.indexWhere((c) => c.id == recipe.id);
    if (index < 0) return;
    _selectChoice(recipe);
    if (_heroPageController.hasClients) {
      // 滑动动画途经的中间页会逐个触发 onPageChanged——静默埋点直到动画结束。
      _muteHeroPageTelemetry = true;
      _heroPageController
          .animateToPage(
        index,
        duration: AppMotion.standard,
        curve: AppMotion.enter,
      )
          .whenComplete(() {
        _muteHeroPageTelemetry = false;
      });
    }
  }

  void _selectChoice(
    RecipeModel recipe, {
    String action = 'candidate_tap',
    bool recordTelemetry = true,
  }) {
    if (!_choiceController.select(recipe)) return;
    HapticFeedback.selectionClick();
    if (recordTelemetry) {
      unawaited(
        _recommendationTelemetry.recordSelection(
          context: _recommendationContext,
          recipeId: recipe.id,
          position: _positionFor(recipe),
          action: action,
        ),
      );
    }
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

  void _confirm() {
    final currentChoice = _choiceController.currentChoice;
    if (currentChoice == null) return;
    // 「就吃这个」= 一键直达首选渠道：结果页的三渠道卡片本身已是"点即直达"
    // 的选择器（卡片上有「首选」徽标），这里不再打开重复的三选一中间页。
    // 首选缺失时回退到「在家开火 / 菜谱直出」——离线必可用，永不落空。
    // 震动、选菜与渠道埋点统一交给 _openExecutionShortcut，避免重复记录。
    unawaited(
      _recommendationTelemetry.recordSelection(
        context: _recommendationContext,
        recipeId: currentChoice.id,
        position: _positionFor(currentChoice),
        action: 'confirm',
      ),
    );
    final targetPath = _preferredPath == ExecutionPath.any
        ? ExecutionPath.cook
        : _preferredPath;
    unawaited(_openExecutionShortcut(targetPath));
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
        final deliveryClient =
            widget.meituanOrderClient ?? MeituanDeliveryOrderClient();
        if (!deliveryClient.isConfigured) {
          // 代理未配置：商家还没接入，直接引导去美团开放平台注册。
          await _openMeituanOpenPlatform('外卖服务接入中，请先在美团开放平台注册商家');
          return;
        }
        // 代理在，但美团侧可能还没完成授权：探测连接状态，未连接则引导授权。
        try {
          final status = await deliveryClient.getOAuthStatus();
          if (!status.connected) {
            await _openMeituanAuthorization(deliveryClient);
            return;
          }
        } catch (_) {
          await _openMeituanOpenPlatform('美团服务暂时不可用，请先去开放平台完成接入');
          return;
        }
        // Ordering gate: Meituan orders belong to an eatwhat account; a
        // signed-out user signs in (or registers) before the menu builder.
        if (!AuthService.isLoggedIn) {
          final signedIn = await showEatWhatAuthSheet(
            context,
            reason: '登录后才能使用美团下单',
          );
          if (!signedIn || !mounted) return;
        }
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => MeituanMenuBuilderPage(
              intent: ExecutionIntent(
                recipe: recipe,
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

  /// 外卖未接入时的兜底引导：直接打开美团开放平台注册页。
  Future<void> _openMeituanOpenPlatform(String tip) async {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(tip)));
    }
    try {
      await launchUrl(
        Uri.parse('https://open.meituan.com/'),
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {
      // 无浏览器/测试环境打不开链接时静默，提示文案已展示。
    }
  }

  /// 已配置但美团侧未授权：打开授权页；拿不到授权链接则回退开放平台首页。
  Future<void> _openMeituanAuthorization(
    MeituanDeliveryOrderClient client,
  ) async {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('请先完成美团商家授权')),
      );
    }
    try {
      final uri = await client.createOAuthAuthorizationUri();
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } catch (_) {
      try {
        await launchUrl(
          Uri.parse('https://open.meituan.com/'),
          mode: LaunchMode.externalApplication,
        );
      } catch (_) {
        // 同上：打不开链接时提示文案已展示。
      }
    }
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
    final choices = _choiceController.availableChoices;

    return Scaffold(
      backgroundColor: GoldPalette.nightDeep,
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
                confirmLabel: '就吃这个',
              ),
            ),
      body: currentChoice == null
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.lg),
                child: EmptyRecommendationState(
                  tags: _displayTags,
                  resolutionStatus: _resolvedStatus,
                  primarySource: widget.primarySource,
                  onReselect: _returnToPreferenceSelection,
                ),
              ),
            )
          : Stack(
              fit: StackFit.expand,
              children: [
                // 1 · 全屏美食摄影：整屏出血，横向滑动切换候选，入场时从
                // 轻微推近中缓缓落定，像镜头对焦完成的一瞬。
                AnimatedBuilder(
                  animation: _entrance,
                  builder: (context, child) {
                    final t = Curves.easeOutCubic.transform(_entrance.value);
                    return Transform.scale(
                      scale: 1.07 - 0.07 * t,
                      child: child,
                    );
                  },
                  child: PageView.builder(
                    key: const ValueKey('result-hero-pager'),
                    controller: _heroPageController,
                    itemCount: choices.length,
                    onPageChanged: (index) => _selectChoice(
                      choices[index],
                      action: 'hero_swipe',
                      recordTelemetry: !_muteHeroPageTelemetry,
                    ),
                    itemBuilder: (context, index) {
                      final recipe = choices[index];
                      return ResultHeroMedia(
                        recipe: recipe,
                        imageLoadState: _imageStateController.stateFor(
                          recipe.id,
                        ),
                        imageSource: _imageStateController.sourceFor(
                          recipe.id,
                        ),
                        onRetryImage: () => _maybeGenerateImageForCurrentChoice(
                          force: true,
                        ),
                      );
                    },
                  ),
                ),
                // 2 · 金色发丝内框：把整屏装裱成一张高级餐厅的菜单卡。
                const IgnorePointer(child: _GoldInsetFrame()),
                // 3 · 悬浮层：页眉压住顶部帘幕，其余信息沿照片底部的
                // 黑色沉降带依次浮起。
                SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.xs,
                      AppSpacing.md,
                      AppSpacing.sm,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _StageHeader(
                          onBack: _returnToPreferenceSelection,
                          favorited: _isFavorited,
                          onToggleFavorite: _toggleFavorite,
                        ),
                        const Spacer(),
                        if (currentChoice.tags.isNotEmpty) ...[
                          _Reveal(
                            controller: _entrance,
                            interval: const (0.20, 0.55),
                            child: SizedBox(
                              height: 26,
                              child: ListView.separated(
                                scrollDirection: Axis.horizontal,
                                itemCount: currentChoice.tags.take(3).length,
                                separatorBuilder: (_, __) =>
                                    const SizedBox(width: 6),
                                itemBuilder: (context, index) => _GoldTagChip(
                                  label: currentChoice.tags[index],
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                        ],
                        _Reveal(
                          controller: _entrance,
                          interval: const (0.30, 0.68),
                          child: _GoldNameplate(
                            recipe: currentChoice,
                            index: _positionFor(currentChoice),
                            total: choices.length,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        // AI 点菜师增强状态：增强中 / 已重排。
                        if (_aiEnhancing || _aiEnhanced) ...[
                          _Reveal(
                            controller: _entrance,
                            interval: const (0.36, 0.74),
                            child: _AiChefStatusChip(enhancing: _aiEnhancing),
                          ),
                          const SizedBox(height: AppSpacing.xs),
                        ],
                        // One line of gold: why the chef picked this dish.
                        _Reveal(
                          controller: _entrance,
                          interval: const (0.42, 0.80),
                          child: _GoldReasonLine(
                            text: _effectiveAiSummary ??
                                _buildRecommendationSubtitle(),
                          ),
                        ),
                        const SizedBox(height: AppSpacing.md),
                        // Gallery rail: tap a frame to re-hang the stage.
                        if (choices.length > 1) ...[
                          _Reveal(
                            controller: _entrance,
                            interval: const (0.52, 0.92),
                            child: ResultCandidateRail(
                              currentChoiceId: currentChoice.id,
                              choices: choices,
                              recalledCount: widget.recalledCount,
                              thumbUrlByRecipeId: _thumbUrlByRecipeId,
                              onSelect: _selectChoiceWithHero,
                            ),
                          ),
                          const SizedBox(height: AppSpacing.sm),
                        ],
                        // Three gold cards: delivery, cook at home, dine out.
                        _Reveal(
                          controller: _entrance,
                          interval: const (0.62, 1.0),
                          child: ResultExecutionShortcuts(
                            preferredPath: _preferredPath,
                            onCook: () => _openExecutionShortcut(
                              ExecutionPath.cook,
                            ),
                            onDelivery: () => _openExecutionShortcut(
                              ExecutionPath.delivery,
                            ),
                            onDineIn: () => _openExecutionShortcut(
                              ExecutionPath.dineIn,
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

  String _buildRecommendationSubtitle() {
    final currentChoice = _choiceController.currentChoice;
    if (currentChoice == null) {
      return '这轮没有收束出合适的菜，请调整口味签名后再试一次。';
    }

    final reason = _reasonsByRecipeId[currentChoice.id];
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
}

/// Gold-ringed favorite star floating over the hero photo — the only
/// chrome allowed on the image, small enough to never compete with it.
class _GoldFavoriteButton extends StatelessWidget {
  const _GoldFavoriteButton({
    required this.favorited,
    required this.onTap,
  });

  final bool favorited;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: const ValueKey('result-favorite-toggle'),
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.55),
          shape: BoxShape.circle,
          border: Border.all(
            color: favorited ? GoldPalette.gold : GoldPalette.goldHairline,
          ),
        ),
        child: Icon(
          favorited ? Icons.star_rounded : Icons.star_outline_rounded,
          size: 19,
          color: favorited ? GoldPalette.gold : GoldPalette.goldSoft,
        ),
      ),
    );
  }
}

/// A single line of champagne gold explaining why the chef picked this
/// dish, framed by a hairline above and below.
class _GoldReasonLine extends StatelessWidget {
  const _GoldReasonLine({required this.text});

  final String text;

  @override
  Widget build(BuildContext context) {
    return Column(
      key: const ValueKey('result-gold-reason-line'),
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(height: 0.6, color: GoldPalette.goldHairline),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Row(
            children: [
              const SizedBox(width: 2),
              const Icon(
                Icons.auto_awesome_rounded,
                size: 13,
                color: GoldPalette.gold,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  text,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: GoldPalette.creamText,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    height: 1.5,
                    letterSpacing: 0.4,
                  ),
                ),
              ),
            ],
          ),
        ),
        Container(height: 0.6, color: GoldPalette.goldHairline),
      ],
    );
  }
}

/// Small gold-rimmed tag chip floating on the photography — smoked glass
/// body, hairline gold rim, wide-tracked ink.
class _GoldTagChip extends StatelessWidget {
  const _GoldTagChip({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.42),
        borderRadius: AppRadii.capsule,
        border: Border.all(color: GoldPalette.goldHairline),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: GoldPalette.goldSoft,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
        ),
      ),
    );
  }
}

/// AI 点菜师增强状态徽章：黑玻璃体 + 金发丝描边 + 柔金文字。增强中显示
/// 「增强中…」，AI 包落地后切为「已重排」，让后台换菜不显突兀。
class _AiChefStatusChip extends StatelessWidget {
  const _AiChefStatusChip({required this.enhancing});

  final bool enhancing;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          key: ValueKey(enhancing ? 'ai-chef-enhancing' : 'ai-chef-enhanced'),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.42),
            borderRadius: AppRadii.capsule,
            border: Border.all(color: GoldPalette.goldHairline),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                enhancing
                    ? Icons.auto_awesome_outlined
                    : Icons.auto_awesome_rounded,
                size: 12,
                color: GoldPalette.gold,
              ),
              const SizedBox(width: 6),
              Text(
                enhancing ? 'AI 点菜师增强中…' : 'AI 点菜师已重排',
                style: const TextStyle(
                  color: GoldPalette.goldSoft,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Gallery mount for the whole stage: a hairline gold frame inset from
/// the screen edges, turning the full-bleed photograph into a framed
/// menu card from a maison you cannot afford.
class _GoldInsetFrame extends StatelessWidget {
  const _GoldInsetFrame();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(10),
      child: DecoratedBox(
        decoration: BoxDecoration(
          border: Border.all(color: GoldPalette.goldHairline, width: 0.8),
          borderRadius: BorderRadius.circular(6),
        ),
        child: const SizedBox.expand(),
      ),
    );
  }
}

/// Staggered curtain-lift: each overlay layer fades and rises inside its
/// own interval of the one-shot entrance controller.
class _Reveal extends StatelessWidget {
  const _Reveal({
    required this.controller,
    required this.interval,
    required this.child,
  });

  final AnimationController controller;
  final (double, double) interval;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final curve = CurvedAnimation(
      parent: controller,
      curve: Interval(interval.$1, interval.$2, curve: AppMotion.enter),
    );
    return FadeTransition(
      opacity: curve,
      child: SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.06),
          end: Offset.zero,
        ).animate(curve),
        child: child,
      ),
    );
  }
}

/// Editorial nameplate floating over the photograph's bottom falloff: a
/// gold dash and the menu ordinal with tabular figures, then the serif
/// dish name. Switching candidates crossfades the name instead of
/// jumping — the frame stays, the dish changes.
class _GoldNameplate extends StatelessWidget {
  const _GoldNameplate({
    required this.recipe,
    required this.index,
    required this.total,
  });

  final RecipeModel recipe;
  final int index;
  final int total;

  @override
  Widget build(BuildContext context) {
    final ordinal = (index < 0 ? 0 : index) + 1;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Container(width: 22, height: 1, color: GoldPalette.gold),
            const SizedBox(width: 8),
            Text(
              'N°${ordinal.toString().padLeft(2, '0')} / ${total.toString().padLeft(2, '0')}',
              style: const TextStyle(
                color: GoldPalette.gold,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 2.6,
                fontFeatures: [FontFeature.tabularFigures()],
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        AnimatedSwitcher(
          duration: AppMotion.page,
          switchInCurve: AppMotion.enter,
          transitionBuilder: (child, animation) => FadeTransition(
            opacity: animation,
            child: SlideTransition(
              position: Tween<Offset>(
                begin: const Offset(0, 0.12),
                end: Offset.zero,
              ).animate(animation),
              child: child,
            ),
          ),
          child: Text(
            recipe.name,
            key: ValueKey('result-nameplate-${recipe.id}'),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: GoldPalette.creamText,
              fontFamily: 'serif',
              fontSize: 34,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              height: 1.05,
              shadows: [
                Shadow(
                  color: Colors.black.withValues(alpha: 0.65),
                  blurRadius: 18,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// Slim maison header floating on the photography's top curtain: a
/// gold-ringed back key, the house wordmark in wide-tracked caps, and
/// the favorite star — the only chrome above the dish.
class _StageHeader extends StatelessWidget {
  const _StageHeader({
    required this.onBack,
    required this.favorited,
    required this.onToggleFavorite,
  });

  final VoidCallback onBack;
  final bool favorited;
  final VoidCallback onToggleFavorite;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 40,
      child: Row(
        children: [
          _GoldCircleKey(
            icon: Icons.arrow_back_ios_new_rounded,
            onTap: onBack,
            semanticLabel: '返回重选',
          ),
          const Expanded(
            child: Text(
              "主厨甄选 · CHEF'S SELECTION",
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: GoldPalette.goldSoft,
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 3.2,
              ),
            ),
          ),
          _GoldFavoriteButton(
            favorited: favorited,
            onTap: onToggleFavorite,
          ),
        ],
      ),
    );
  }
}

/// Small gold-rimmed circular key used by the stage header.
class _GoldCircleKey extends StatelessWidget {
  const _GoldCircleKey({
    required this.icon,
    required this.onTap,
    required this.semanticLabel,
  });

  final IconData icon;
  final VoidCallback onTap;
  final String semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      label: semanticLabel,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: GoldPalette.panel,
            shape: BoxShape.circle,
            border: Border.all(color: GoldPalette.goldHairline),
          ),
          child: Icon(icon, size: 16, color: GoldPalette.goldSoft),
        ),
      ),
    );
  }
}
