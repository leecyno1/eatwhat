import 'dart:async';

import 'package:eatwhat_app/core/services/auth_service.dart';
import 'package:eatwhat_app/core/services/unified_recipe_database_service.dart';
import 'package:eatwhat_app/v2/core/data/models/meal_planning_direction.dart';
import 'package:eatwhat_app/v2/core/data/models/recipe_model.dart';
import 'package:eatwhat_app/v2/core/data/models/taste_inference_input.dart';
import 'package:eatwhat_app/v2/core/data/models/taste_selection_models.dart';
import 'package:eatwhat_app/v2/core/data/repositories/tag_repository_v2.dart';
import 'package:eatwhat_app/v2/core/navigation/app_v2_routes.dart';
import 'package:eatwhat_app/v2/core/services/v2_favorites_service.dart';
import 'package:eatwhat_app/v2/core/services/v2_meal_habit_learning_service.dart';
import 'package:eatwhat_app/v2/core/services/v2_preference_feedback_service.dart';
import 'package:eatwhat_app/v2/core/services/v2_speech_input_service.dart';
import 'package:eatwhat_app/v2/features/auth/auth_sheet.dart';
import 'package:eatwhat_app/v2/features/favorites/favorites_page.dart';
import 'package:eatwhat_app/v2/features/home/controllers/home_recent_success_controller.dart';
import 'package:eatwhat_app/v2/features/home/controllers/home_taste_deck_builder.dart';
import 'package:eatwhat_app/v2/features/home/widgets/bubble_ocean.dart';
import 'package:eatwhat_app/v2/features/home/widgets/conditions_sheet.dart';
import 'package:eatwhat_app/v2/features/home/widgets/fresh_physical_preference_stage.dart';
import 'package:eatwhat_app/v2/features/home/widgets/home_overlays.dart';
import 'package:eatwhat_app/v2/features/home/widgets/home_storefront.dart';
import 'package:eatwhat_app/v2/features/home/widgets/pantry_ingredient_sheet.dart';
import 'package:eatwhat_app/v2/features/home/widgets/taste_signature_panel.dart';
import 'package:eatwhat_app/v2/features/home/widgets/theme_sheet.dart';
import 'package:eatwhat_app/v2/features/home/widgets/weekly_report_sheet.dart';
import 'package:eatwhat_app/v2/features/onboarding/handfeel_tutorial.dart';
import 'package:eatwhat_app/v2/features/onboarding/onboarding_service.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_tokens.dart';

typedef HomeDecisionPageBuilder = Widget Function(TasteInferenceInput input);

typedef HomePantryResultPageBuilder = Widget Function(
  List<RecipeModel> recipes,
  List<String> pantry,
);

typedef HomePantrySearchLoader = Future<List<Map<String, dynamic>>> Function(
    List<String> ingredients);

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    this.speechInputService,
    this.decisionPageBuilder,
    this.pantryResultPageBuilder,
    this.pantrySearchLoader,
    this.initialCards,
  });

  final V2SpeechInputService? speechInputService;
  final HomeDecisionPageBuilder? decisionPageBuilder;
  final HomePantryResultPageBuilder? pantryResultPageBuilder;
  final HomePantrySearchLoader? pantrySearchLoader;
  final List<TasteDeckCard>? initialCards;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final HomeTasteDeckBuilder _deckBuilder = const HomeTasteDeckBuilder();
  final HomeRecentSuccessController _recentSuccessController =
      const HomeRecentSuccessController();
  final V2FavoritesService _favorites = V2FavoritesService.instance;
  final V2PreferenceFeedbackService _feedback =
      V2PreferenceFeedbackService.instance;
  final V2MealHabitLearningService _habitLearning =
      V2MealHabitLearningService.instance;
  late final V2SpeechInputService _speechInputService;

  Timer? _transitionCueTimer;
  Completer<void>? _transitionCueCompleter;
  bool _isTransitioning = false;
  bool _isLoadingDeck = true;
  bool _isListening = false;
  bool _hasChosenPlanningDirection = false;
  bool _showHandfeelTutorial = false;
  String _liveTranscript = '';
  String? _tasteCategory;
  TasteDeckSessionState? _session;
  MealPlanningDirection _planningDirection = MealPlanningDirection.balanced;
  MealHabitSnapshot? _habitSnapshot;
  Map<String, int> _historyScores = const {};
  List<String> _recentRecipeIds = const [];

  @override
  void initState() {
    super.initState();
    _controller.addListener(_handleRequirementChanged);
    _speechInputService =
        widget.speechInputService ?? V2SpeechInputServiceImpl();
    final initialCards = widget.initialCards;
    if (initialCards != null && initialCards.isNotEmpty) {
      _session = TasteDeckSessionState.initial(
        deck: initialCards,
        cardDeckSeed: 0,
      );
      _isLoadingDeck = false;
      unawaited(_loadInitialHistoryContext());
    } else {
      _prepareDeck();
    }
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeShowHandfeelTutorial();
    });
  }

  @override
  void dispose() {
    _transitionCueTimer?.cancel();
    if (!(_transitionCueCompleter?.isCompleted ?? true)) {
      _transitionCueCompleter?.complete();
    }
    _controller
      ..removeListener(_handleRequirementChanged)
      ..dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleRequirementChanged() {
    if (!mounted) return;
    setState(() {});
  }

  void _prepareDeck() {
    final seed = DateTime.now().millisecondsSinceEpoch.remainder(1 << 31);
    final fallbackCards = HomeTasteDeckBuilder(
      tagRepository: TagRepositoryV2(),
    ).buildDeck(
      seed: seed,
      historyScores: const {},
      favoriteTagIds: const {},
    );
    _session = TasteDeckSessionState.initial(
      deck: fallbackCards,
      cardDeckSeed: seed,
    );
    _isLoadingDeck = false;
    unawaited(_hydrateDeck(seed));
  }

  Future<void> _hydrateDeck(int seed) async {
    Map<String, int> historyScores = const {};
    List<String> recentRecipeIds = const [];
    Set<String> favoriteTagIds = const {};
    var habitSnapshot = const MealHabitSnapshot(
      recommendedDirection: MealPlanningDirection.balanced,
      evidenceCount: 0,
      confidence: 0,
      insight: '还没有足够历史，先从均衡开始',
    );

    try {
      historyScores = await _feedback.getTagScores();
    } catch (_) {}
    try {
      recentRecipeIds = await _feedback.getRecentRecipeIds(limit: 5);
    } catch (_) {}
    try {
      favoriteTagIds = await _favorites.getFavoriteTagIds();
    } catch (_) {}
    try {
      habitSnapshot = await _habitLearning.buildSnapshot(
        tagScores: historyScores,
      );
    } catch (_) {}

    if (!mounted) return;
    final personalizedCards = HomeTasteDeckBuilder(
      tagRepository: TagRepositoryV2(),
    ).buildDeck(
      seed: seed,
      historyScores: historyScores,
      favoriteTagIds: favoriteTagIds,
    );
    setState(() {
      _historyScores = historyScores;
      _recentRecipeIds = recentRecipeIds;
      _habitSnapshot = habitSnapshot;
      if (!_hasChosenPlanningDirection) {
        _planningDirection = habitSnapshot.recommendedDirection;
      }
      final currentSession = _session;
      if (currentSession != null &&
          currentSession.reviewedCount == 0 &&
          currentSession.freeformRequirement.trim().isEmpty) {
        _session = TasteDeckSessionState.initial(
          deck: personalizedCards,
          cardDeckSeed: seed,
        );
      }
    });

    final catalogCards = await _deckBuilder.buildDeckFromCatalog(
      seed: seed,
      historyScores: historyScores,
      favoriteTagIds: favoriteTagIds,
    );
    if (!mounted || catalogCards.length < TasteDeckSessionState.pageSize) {
      return;
    }
    final currentSession = _session;
    if (currentSession == null ||
        currentSession.reviewedCount > 0 ||
        currentSession.freeformRequirement.trim().isNotEmpty) {
      return;
    }
    setState(() {
      _session = TasteDeckSessionState.initial(
        deck: catalogCards,
        cardDeckSeed: seed,
      );
    });
  }

  Future<void> _loadInitialHistoryContext() async {
    Map<String, int> historyScores = const {};
    List<String> recentRecipeIds = const [];
    var habitSnapshot = const MealHabitSnapshot(
      recommendedDirection: MealPlanningDirection.balanced,
      evidenceCount: 0,
      confidence: 0,
      insight: '还没有足够历史，先从均衡开始',
    );
    try {
      historyScores = await _feedback.getTagScores();
      recentRecipeIds = await _feedback.getRecentRecipeIds(limit: 5);
      habitSnapshot = await _habitLearning.buildSnapshot(
        tagScores: historyScores,
      );
    } catch (_) {}
    if (!mounted) return;
    setState(() {
      _historyScores = historyScores;
      _recentRecipeIds = recentRecipeIds;
      _habitSnapshot = habitSnapshot;
      if (!_hasChosenPlanningDirection) {
        _planningDirection = habitSnapshot.recommendedDirection;
      }
    });
  }

  Future<void> _maybeShowHandfeelTutorial() async {
    if (!mounted) return;
    final shouldShow = await OnboardingService().shouldShowHandfeelTutorial();
    if (!mounted || !shouldShow) return;
    setState(() => _showHandfeelTutorial = true);
  }

  Future<void> _finishHandfeelTutorial() async {
    await OnboardingService().markHandfeelTutorialSeen();
    if (!mounted) return;
    setState(() => _showHandfeelTutorial = false);
  }

  void _handleBubbleSelectionChanged(BubbleSelectionState selection) {
    final session = _session;
    if (session == null) return;
    final labelsById = <String, String>{
      for (final card in session.deck) card.id: card.label,
      for (var index = 0; index < selection.likedIds.length; index++)
        selection.likedIds[index]: index < selection.likedLabels.length
            ? selection.likedLabels[index]
            : selection.likedIds[index],
      for (var index = 0; index < selection.blockedIds.length; index++)
        selection.blockedIds[index]: index < selection.blockedLabels.length
            ? selection.blockedLabels[index]
            : selection.blockedIds[index],
    };
    setState(() {
      _session = session.copyWith(
        likedTagIds: List<String>.from(selection.likedIds),
        dislikedTagIds: List<String>.from(selection.blockedIds),
        tagLabelsById: labelsById,
      );
    });
  }

  void _handlePlanningDirectionChanged(MealPlanningDirection direction) {
    setState(() {
      _planningDirection = direction;
      _hasChosenPlanningDirection = true;
    });
  }

  void _handleCategoryChanged(String? category) {
    setState(() {
      _tasteCategory = category;
    });
  }

  void _handleStructuredConstraintsChanged(
    TasteStructuredConstraints constraints,
  ) {
    final session = _session;
    if (session == null) return;
    setState(() {
      _session = session.copyWith(structuredConstraints: constraints);
    });
  }

  void _showSignature() {
    final session = _session;
    if (session == null) return;
    setState(() {
      _session = session.copyWith(faceStage: TasteDeckFaceStage.signature);
    });
  }

  /// Account entry: signed-in users get the account/membership sheet,
  /// signed-out users get the login/register sheet. Either way the header
  /// re-renders so the person icon reflects the new session state.
  Future<void> _openAccount() async {
    if (AuthService.isLoggedIn) {
      await showEatWhatAccountSheet(context);
    } else {
      await showEatWhatAuthSheet(
        context,
        reason: '登录后可同步偏好与订单',
      );
    }
    if (mounted) setState(() {});
  }

  void _showDeck() {
    final session = _session;
    if (session == null) return;
    setState(() {
      _session = session.copyWith(faceStage: TasteDeckFaceStage.deck);
    });
  }

  Future<void> _startVoiceCapture() async {
    if (_isListening) return;
    final ready = await _speechInputService.initialize();
    if (!ready) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('语音输入暂时不可用，请直接输入文字')),
      );
      return;
    }

    setState(() {
      _isListening = true;
      _liveTranscript = '';
    });
    await _speechInputService.startListening(
      onResult: (transcript, _) {
        if (!mounted || transcript.trim().isEmpty) return;
        final trimmed = transcript.trim();
        setState(() {
          _liveTranscript = trimmed;
        });
        _controller.value = TextEditingValue(
          text: trimmed,
          selection: TextSelection.collapsed(
            offset: trimmed.length,
          ),
        );
      },
    );
  }

  Future<void> _finishVoiceCapture() async {
    if (!_isListening) return;
    final transcript = await _speechInputService.stopListening();
    if (!mounted) return;
    setState(() {
      _isListening = false;
      _liveTranscript = '';
    });
    if (transcript.trim().isEmpty) return;
    _controller.value = TextEditingValue(
      text: transcript.trim(),
      selection: TextSelection.collapsed(offset: transcript.trim().length),
    );
  }

  Future<void> _submitGeneration() async {
    final session = _session;
    if (_isTransitioning || session == null) return;

    final nextSession = session.copyWith(
      freeformRequirement: _controller.text.trim(),
    );
    if (!nextSession.canStartInference) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('先选几个偏好，或者补一句今天想吃的')),
      );
      return;
    }

    final input = TasteInferenceInput.fromSession(
      nextSession,
      historyPreferenceSummary: _historyScores,
      planningDirection: _planningDirection,
    );

    setState(() {
      _session = nextSession;
    });
    unawaited(_habitLearning.recordDirection(_planningDirection));
    await _openDecisionFlow(input);
  }

  Future<void> _openPantrySheet() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(sheetContext).size.height * 0.85,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: AppPalette.nightElevated,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: PantryIngredientSheet(onConfirm: _submitPantrySearch),
        ),
      ),
    );
  }

  Future<void> _openWeeklyReport() async {
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (sheetContext) => ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(sheetContext).size.height * 0.85,
        ),
        child: Container(
          decoration: BoxDecoration(
            color: AppPalette.nightElevated,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: const WeeklyReportSheet(),
        ),
      ),
    );
  }

  Future<void> _submitPantrySearch(List<String> ingredients) async {
    if (!mounted || ingredients.isEmpty) return;
    final loader = widget.pantrySearchLoader ??
        UnifiedRecipeDatabaseService.instance.searchByPantryIngredients;
    final rows = await loader(ingredients);
    if (!mounted) return;

    if (rows.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('没找到能配上的菜，再加几样食材试试')),
      );
      return;
    }

    final recipes = rows.map(RecipeModel.fromUnifiedDbRow).toList();
    final builder = widget.pantryResultPageBuilder;
    if (builder != null) {
      unawaited(
        Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => builder(recipes, ingredients),
          ),
        ),
      );
      return;
    }
    unawaited(
      context.push(
        AppV2Routes.result,
        extra: AppV2ResultRouteData(
          recommendations: recipes,
          inferenceInput: TasteInferenceInput(
            likedTagIds: const [],
            likedTagLabels: const [],
            dislikedTagIds: const [],
            dislikedTagLabels: const [],
            skippedTagIds: const [],
            skippedTagLabels: const [],
            freeformRequirement: '家里有 ${ingredients.join('、')}',
            historyPreferenceSummary: const {},
          ),
          recallLabels: ingredients,
          recalledCount: recipes.length,
          primarySource: 'unified_db',
        ),
      ),
    );
  }

  Future<void> _submitRecentSuccessRecommendation() async {
    final session = _session;
    if (_isTransitioning || session == null || _recentRecipeIds.isEmpty) {
      return;
    }

    final baseInput = _recentSuccessController.buildInput(
      session: session,
      historyScores: _historyScores,
      recentRecipeIds: _recentRecipeIds,
    );
    if (baseInput == null) return;

    final input = baseInput.copyWith(planningDirection: _planningDirection);
    unawaited(_habitLearning.recordDirection(_planningDirection));
    await _openDecisionFlow(input);
  }

  Future<void> _openDecisionFlow(TasteInferenceInput input) async {
    if (_isTransitioning) return;
    setState(() {
      _isTransitioning = true;
    });

    try {
      await _waitForTransitionCue();
      if (!mounted) return;

      if (widget.decisionPageBuilder != null) {
        unawaited(
          Navigator.of(context).push(
            MaterialPageRoute<void>(
              builder: (_) => widget.decisionPageBuilder!.call(input),
            ),
          ),
        );
      } else {
        unawaited(
          context.push(
            AppV2Routes.decision,
            extra: AppV2DecisionRouteData(input: input),
          ),
        );
      }
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('推荐页打开失败，请再试一次')),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isTransitioning = false;
        });
      }
    }
  }

  Future<void> _waitForTransitionCue() {
    _transitionCueTimer?.cancel();
    final completer = Completer<void>();
    _transitionCueCompleter = completer;
    _transitionCueTimer = Timer(const Duration(milliseconds: 260), () {
      if (!completer.isCompleted) {
        completer.complete();
      }
      if (_transitionCueCompleter == completer) {
        _transitionCueCompleter = null;
        _transitionCueTimer = null;
      }
    });
    return completer.future;
  }

  void _removeTasteSelection(String id, {required bool liked}) {
    final session = _session;
    if (session == null) return;
    setState(() {
      _session = session.copyWith(
        likedTagIds: liked
            ? session.likedTagIds.where((item) => item != id).toList()
            : session.likedTagIds,
        dislikedTagIds: liked
            ? session.dislikedTagIds
            : session.dislikedTagIds.where((item) => item != id).toList(),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = _session;
    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: AppPalette.night,
      body: Stack(
        children: [
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 6, 12, 10),
              child: Column(
                children: [
                  _FreshCompactHeader(
                    planningDirection: _planningDirection,
                    habitSnapshot: _habitSnapshot,
                    category: _tasteCategory,
                    constraints: session?.structuredConstraints ??
                        const TasteStructuredConstraints(),
                    likedCount: session?.likedTagIds.length ?? 0,
                    blockedCount: session?.dislikedTagIds.length ?? 0,
                    onPlanningDirectionChanged: _handlePlanningDirectionChanged,
                    onCategoryChanged: _handleCategoryChanged,
                    onStructuredConstraintsChanged:
                        _handleStructuredConstraintsChanged,
                    onShowSignature: _showSignature,
                    onOpenAccount: _openAccount,
                    onToggleTheme: () {
                      showAppThemeSheet(context);
                    },
                    onOpenFavorites: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const FavoritesPageV2(),
                        ),
                      );
                    },
                    onOpenRecent: _submitRecentSuccessRecommendation,
                    onOpenWeeklyReport: _openWeeklyReport,
                  ),
                  const SizedBox(height: 6),
                  Expanded(
                    child: session?.faceStage == TasteDeckFaceStage.signature
                        ? _buildMainStage(session)
                        : _buildStorefront(session),
                  ),
                ],
              ),
            ),
          ),
          if (_isTransitioning)
            const Positioned.fill(
              child: HomeGenerationTransitionOverlay(),
            ),
          if (_showHandfeelTutorial)
            Positioned.fill(
              child: HandfeelTutorial(
                onFinished: _finishHandfeelTutorial,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStorefront(TasteDeckSessionState? session) {
    final canStart = session != null &&
        session
            .copyWith(freeformRequirement: _controller.text.trim())
            .canStartInference;
    final selectionCount = session == null
        ? 0
        : session.likedTagIds.length + session.dislikedTagIds.length;
    return HomeStorefront(
      stage: _buildMainStage(session, embedded: true),
      selectionCount: selectionCount,
      canGenerate: canStart && !_isTransitioning,
      // 零选择时保持可点：点击弹出引导提示，比静默禁用更能让新用户
      // 明白下一步该做什么。
      onGenerate: () {
        if (canStart) {
          _submitGeneration();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('先收下几个口味气泡，或写一句今天想吃的'),
            ),
          );
        }
      },
      requirementController: _controller,
      requirementFocusNode: _focusNode,
      isListening: _isListening,
      onPantry: _openPantrySheet,
      onVoiceStart: _startVoiceCapture,
      onVoiceEnd: _finishVoiceCapture,
      onSubmitted: _submitGeneration,
    );
  }

  Widget _buildMainStage(
    TasteDeckSessionState? session, {
    bool embedded = false,
  }) {
    return SizedBox(
      key: const ValueKey('taste-card-stage-shell'),
      width: double.infinity,
      child: Stack(
        children: [
          Positioned.fill(
            child: AnimatedSwitcher(
              duration: AppMotion.standard,
              switchInCurve: AppMotion.enter,
              switchOutCurve: AppMotion.enter,
              child: _isLoadingDeck || session == null
                  ? Center(
                      key: const ValueKey('taste-physical-loading'),
                      child: CircularProgressIndicator(
                        color: AppPalette.garden,
                      ),
                    )
                  : session.faceStage == TasteDeckFaceStage.signature
                      ? Container(
                          key: const ValueKey('taste-signature-stage'),
                          padding: const EdgeInsets.all(8),
                          decoration: AppDecorations.card(
                            color: AppPalette.nightSurface.withValues(
                              alpha: 0.94,
                            ),
                            borderColor: AppPalette.nightDivider,
                            radius: AppRadii.lg,
                          ),
                          child: TasteSignaturePanel(
                            session: session.copyWith(
                              freeformRequirement: _controller.text.trim(),
                            ),
                            onBack: _showDeck,
                            onStartInference: _submitGeneration,
                            onRemoveLiked: (id) =>
                                _removeTasteSelection(id, liked: true),
                            onRemoveDisliked: (id) =>
                                _removeTasteSelection(id, liked: false),
                          ),
                        )
                      : FreshPhysicalPreferenceStage(
                          key: const ValueKey(
                            'fresh-physical-preference-stage',
                          ),
                          session: session,
                          isLoading: _isLoadingDeck,
                          category: _tasteCategory,
                          onSelectionChanged: _handleBubbleSelectionChanged,
                          embedded: embedded,
                        ),
            ),
          ),
          if (_isListening)
            Positioned.fill(
              child: IgnorePointer(
                child: HomeVoiceStageOverlay(
                  transcript: _liveTranscript,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class _FreshCompactHeader extends StatelessWidget {
  const _FreshCompactHeader({
    required this.planningDirection,
    required this.habitSnapshot,
    required this.category,
    required this.constraints,
    required this.likedCount,
    required this.blockedCount,
    required this.onPlanningDirectionChanged,
    required this.onCategoryChanged,
    required this.onStructuredConstraintsChanged,
    required this.onShowSignature,
    required this.onOpenAccount,
    required this.onOpenFavorites,
    required this.onOpenRecent,
    required this.onOpenWeeklyReport,
    required this.onToggleTheme,
  });

  final MealPlanningDirection planningDirection;
  final MealHabitSnapshot? habitSnapshot;
  final String? category;
  final TasteStructuredConstraints constraints;
  final int likedCount;
  final int blockedCount;
  final ValueChanged<MealPlanningDirection> onPlanningDirectionChanged;
  final ValueChanged<String?> onCategoryChanged;
  final ValueChanged<TasteStructuredConstraints> onStructuredConstraintsChanged;
  final VoidCallback onShowSignature;
  final VoidCallback onOpenAccount;
  final VoidCallback onOpenFavorites;
  final VoidCallback onOpenRecent;
  final VoidCallback onOpenWeeklyReport;
  final VoidCallback onToggleTheme;

  static const _categories = <({String label, String? value})>[
    (label: '全部', value: null),
    (label: '食材健康', value: 'ingredient_dietary'),
    (label: '口味主食', value: 'flavor_staple'),
    (label: '菜系', value: 'cuisine'),
    (label: '场景趣味', value: 'scene_fun'),
  ];

  @override
  Widget build(BuildContext context) {
    final matchesHistory =
        habitSnapshot?.recommendedDirection == planningDirection;
    final conditionCount = <bool>[
      constraints.maxBudgetYuan != null,
      constraints.partySize != null,
      constraints.executionPreference != TasteExecutionPreference.any,
    ].where((active) => active).length;

    return SizedBox(
      key: const ValueKey('taste-entity-category-tabs'),
      height: 34,
      child: Row(
        children: [
          Expanded(
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _FilterIconPill<MealPlanningDirection>(
                    key: const ValueKey('meal-planning-direction-selector'),
                    icon: matchesHistory
                        ? Icons.auto_awesome_rounded
                        : Icons.psychology_alt_rounded,
                    tooltip: '习惯方向',
                    active: matchesHistory,
                    value: planningDirection,
                    options: [
                      for (final direction in MealPlanningDirection.values)
                        _FilterOption(
                          key: 'meal-direction-${direction.name}',
                          label: direction.label,
                          value: direction,
                        ),
                    ],
                    onSelected: onPlanningDirectionChanged,
                  ),
                  const SizedBox(width: 5),
                  _FilterIconPill<String>(
                    key: const ValueKey('filter-type'),
                    icon: Icons.category_rounded,
                    tooltip: '类型',
                    active: category != null && category!.isNotEmpty,
                    value: category ?? '__all__',
                    options: [
                      for (final item in _categories)
                        _FilterOption(
                          key: 'taste-category-${item.label}',
                          label: item.label,
                          value: item.value ?? '__all__',
                        ),
                    ],
                    onSelected: (value) =>
                        onCategoryChanged(value == '__all__' ? null : value),
                  ),
                  const SizedBox(width: 5),
                  _ConditionEntryPill(
                    activeCount: conditionCount,
                    onTap: () => showHomeConditionsSheet(
                      context: context,
                      constraints: constraints,
                      onChanged: onStructuredConstraintsChanged,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 6),
          _HeaderSelectionSummary(
            likedCount: likedCount,
            blockedCount: blockedCount,
            onTap: onShowSignature,
          ),
          const SizedBox(width: 4),
          _HeaderOverflowMenu(
            onToggleTheme: onToggleTheme,
            onOpenAccount: onOpenAccount,
            onOpenFavorites: onOpenFavorites,
            onOpenRecent: onOpenRecent,
            onOpenWeeklyReport: onOpenWeeklyReport,
          ),
        ],
      ),
    );
  }
}

enum _HeaderMenuAction { theme, account, favorites, recent, weeklyReport }

class _HeaderOverflowMenu extends StatelessWidget {
  const _HeaderOverflowMenu({
    required this.onToggleTheme,
    required this.onOpenAccount,
    required this.onOpenFavorites,
    required this.onOpenRecent,
    required this.onOpenWeeklyReport,
  });

  final VoidCallback onToggleTheme;
  final VoidCallback onOpenAccount;
  final VoidCallback onOpenFavorites;
  final VoidCallback onOpenRecent;
  final VoidCallback onOpenWeeklyReport;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<_HeaderMenuAction>(
      key: const ValueKey('home-overflow-menu'),
      tooltip: '更多',
      position: PopupMenuPosition.under,
      offset: const Offset(0, 6),
      color: AppPalette.nightElevated,
      surfaceTintColor: Colors.transparent,
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: AppRadii.card),
      constraints: const BoxConstraints(minWidth: 188, maxWidth: 220),
      onSelected: (action) {
        switch (action) {
          case _HeaderMenuAction.theme:
            onToggleTheme();
          case _HeaderMenuAction.account:
            onOpenAccount();
          case _HeaderMenuAction.favorites:
            onOpenFavorites();
          case _HeaderMenuAction.recent:
            onOpenRecent();
          case _HeaderMenuAction.weeklyReport:
            onOpenWeeklyReport();
        }
      },
      itemBuilder: (context) => [
        _menuItem(
          key: 'home-theme-toggle',
          icon: Icons.palette_outlined,
          label: '外观主题',
          action: _HeaderMenuAction.theme,
        ),
        _menuItem(
          key: 'home-account-button',
          icon: AuthService.isLoggedIn
              ? Icons.person_rounded
              : Icons.person_outline_rounded,
          label: AuthService.isLoggedIn ? '账号与会员' : '登录 / 注册',
          action: _HeaderMenuAction.account,
        ),
        const PopupMenuDivider(height: 8),
        _menuItem(
          key: 'home-favorites-button',
          icon: Icons.favorite_border_rounded,
          label: '收藏',
          action: _HeaderMenuAction.favorites,
        ),
        _menuItem(
          key: 'home-recent-button',
          icon: Icons.history_rounded,
          label: '吃过',
          action: _HeaderMenuAction.recent,
        ),
        _menuItem(
          key: 'home-weekly-report-button',
          icon: Icons.insights_rounded,
          label: '一周报告',
          action: _HeaderMenuAction.weeklyReport,
        ),
      ],
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: AppPalette.nightSurface.withValues(alpha: 0.96),
          shape: BoxShape.circle,
          border: Border.all(color: AppPalette.nightDivider),
        ),
        child: Icon(
          Icons.more_horiz_rounded,
          size: 18,
          color: AppPalette.inkSoft,
        ),
      ),
    );
  }

  PopupMenuItem<_HeaderMenuAction> _menuItem({
    required String key,
    required IconData icon,
    required String label,
    required _HeaderMenuAction action,
  }) {
    return PopupMenuItem<_HeaderMenuAction>(
      key: ValueKey(key),
      value: action,
      height: 44,
      child: Row(
        children: [
          Icon(icon, size: 17, color: AppPalette.inkSoft),
          const SizedBox(width: 10),
          Text(
            label,
            style: TextStyle(
              color: AppPalette.ink,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _ConditionEntryPill extends StatelessWidget {
  const _ConditionEntryPill({
    required this.activeCount,
    required this.onTap,
  });

  final int activeCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final active = activeCount > 0;
    final color = active ? AppPalette.night : AppPalette.ink;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        key: const ValueKey('filter-conditions'),
        onTap: onTap,
        borderRadius: AppRadii.capsule,
        child: AnimatedContainer(
          duration: AppMotion.fast,
          height: 34,
          padding: const EdgeInsets.symmetric(horizontal: 9),
          decoration: BoxDecoration(
            color: active
                ? AppPalette.leaf
                : AppPalette.nightSurface.withValues(alpha: 0.96),
            borderRadius: AppRadii.capsule,
            border: Border.all(
              color: active ? AppPalette.leaf : AppPalette.nightDivider,
              width: active ? 1.4 : 1,
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.tune_rounded, size: 14, color: color),
              const SizedBox(width: 4),
              Text(
                active ? '条件 $activeCount' : '条件',
                style: TextStyle(
                  color: color,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
              Icon(
                Icons.expand_more_rounded,
                size: 13,
                color: color.withValues(alpha: .7),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _FilterOption<T> {
  const _FilterOption({
    required this.key,
    required this.label,
    required this.value,
  });

  final String key;
  final String label;
  final T value;
}

class _FilterIconPill<T> extends StatelessWidget {
  const _FilterIconPill({
    super.key,
    required this.icon,
    required this.active,
    required this.value,
    required this.options,
    required this.onSelected,
    this.tooltip,
  });

  final IconData icon;
  final bool active;
  final T value;
  final List<_FilterOption<T>> options;
  final ValueChanged<T> onSelected;
  final String? tooltip;

  @override
  Widget build(BuildContext context) {
    final current = options.firstWhere(
      (option) => option.value == value,
      orElse: () => options.first,
    );
    final color = active ? AppPalette.night : AppPalette.ink;
    return PopupMenuButton<T>(
      initialValue: value,
      onSelected: onSelected,
      position: PopupMenuPosition.under,
      offset: const Offset(0, 6),
      constraints: const BoxConstraints(minWidth: 168, maxWidth: 220),
      color: AppPalette.nightElevated,
      surfaceTintColor: Colors.transparent,
      elevation: 8,
      shape: RoundedRectangleBorder(borderRadius: AppRadii.card),
      tooltip: tooltip,
      child: AnimatedContainer(
        duration: AppMotion.fast,
        height: 34,
        padding: const EdgeInsets.symmetric(horizontal: 9),
        decoration: BoxDecoration(
          color: active
              ? AppPalette.leaf
              : AppPalette.nightSurface.withValues(alpha: 0.96),
          borderRadius: AppRadii.capsule,
          border: Border.all(
            color: active ? AppPalette.leaf : AppPalette.nightDivider,
            width: active ? 1.4 : 1,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              current.label,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
            Icon(
              Icons.expand_more_rounded,
              size: 13,
              color: color.withValues(alpha: .7),
            ),
          ],
        ),
      ),
      itemBuilder: (context) => [
        for (final option in options)
          PopupMenuItem<T>(
            key: ValueKey(option.key),
            value: option.value,
            height: 42,
            child: Row(
              children: [
                Icon(
                  option.value == value
                      ? Icons.check_circle_rounded
                      : Icons.circle_outlined,
                  size: 17,
                  color: option.value == value
                      ? AppPalette.leaf
                      : AppPalette.moonMuted,
                ),
                const SizedBox(width: 9),
                Text(
                  option.label,
                  style: TextStyle(
                    color: AppPalette.moonlight,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
      ],
    );
  }
}

class _HeaderSelectionSummary extends StatelessWidget {
  const _HeaderSelectionSummary({
    required this.likedCount,
    required this.blockedCount,
    required this.onTap,
  });

  final int likedCount;
  final int blockedCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final total = likedCount + blockedCount;
    // The capsule pops whenever a sweep or tap changes the counts, so every
    // collect lands with a visible pulse right where the tally lives.
    return TweenAnimationBuilder<double>(
      key: ValueKey('taste-summary-bounce-$likedCount-$blockedCount'),
      tween: Tween<double>(begin: 1.16, end: 1),
      duration: AppMotion.standard,
      curve: AppMotion.enter,
      builder: (context, scale, child) => Transform.scale(
        scale: scale,
        child: child,
      ),
      child: Material(
        key: const ValueKey('taste-signature-button'),
        color: AppPalette.nightSurface.withValues(alpha: 0.92),
        borderRadius: AppRadii.capsule,
        child: InkWell(
          key: const ValueKey('taste-entity-selection-summary'),
          onTap: onTap,
          borderRadius: AppRadii.capsule,
          child: Container(
            height: 34,
            padding: const EdgeInsets.symmetric(horizontal: 9),
            decoration: BoxDecoration(
              borderRadius: AppRadii.capsule,
              border: Border.all(color: AppPalette.nightDivider),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.favorite_rounded,
                  size: 13,
                  color: AppPalette.leaf,
                ),
                const SizedBox(width: 4),
                Text(
                  '已选 $total',
                  style: TextStyle(
                    color: AppPalette.ink,
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (blockedCount > 0) ...[
                  const SizedBox(width: 5),
                  const Icon(
                    Icons.block_rounded,
                    size: 11,
                    color: AppPalette.tomato,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
