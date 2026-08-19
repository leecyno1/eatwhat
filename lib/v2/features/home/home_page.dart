import 'dart:async';

import 'package:eatwhat_app/core/config/env_config.dart';
import 'package:eatwhat_app/v2/core/data/models/meal_planning_direction.dart';
import 'package:eatwhat_app/v2/core/data/models/taste_inference_input.dart';
import 'package:eatwhat_app/v2/core/data/models/taste_selection_models.dart';
import 'package:eatwhat_app/v2/core/data/repositories/tag_repository_v2.dart';
import 'package:eatwhat_app/v2/core/navigation/app_v2_router.dart';
import 'package:eatwhat_app/v2/core/services/v2_favorites_service.dart';
import 'package:eatwhat_app/v2/core/services/v2_meal_habit_learning_service.dart';
import 'package:eatwhat_app/v2/core/services/v2_preference_feedback_service.dart';
import 'package:eatwhat_app/v2/core/services/v2_speech_input_service.dart';
import 'package:eatwhat_app/v2/features/favorites/favorites_page.dart';
import 'package:eatwhat_app/v2/features/home/controllers/home_recent_success_controller.dart';
import 'package:eatwhat_app/v2/features/home/controllers/home_taste_deck_builder.dart';
import 'package:eatwhat_app/v2/features/home/widgets/bubble_ocean.dart';
import 'package:eatwhat_app/v2/features/home/widgets/fresh_physical_preference_stage.dart';
import 'package:eatwhat_app/v2/features/home/widgets/home_overlays.dart';
import 'package:eatwhat_app/v2/features/home/widgets/taste_signature_panel.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme/app_tokens.dart';

typedef HomeDecisionPageBuilder = Widget Function(TasteInferenceInput input);

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    this.speechInputService,
    this.decisionPageBuilder,
    this.initialCards,
  });

  final V2SpeechInputService? speechInputService;
  final HomeDecisionPageBuilder? decisionPageBuilder;
  final List<TasteDeckCard>? initialCards;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  static const _guideSeenKey = 'v2_home_generation_guide_seen';

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
      _showFirstUseGuideIfNeeded();
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

  Future<void> _showFirstUseGuideIfNeeded() async {
    if (EnvConfig.debugMode) return;
    final prefs = await SharedPreferences.getInstance();
    final hasSeenGuide = prefs.getBool(_guideSeenKey) ?? false;
    if (hasSeenGuide || !mounted) return;

    await showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: '首页引导',
      barrierColor: AppSurfaces.scrim,
      pageBuilder: (context, _, __) {
        return SafeArea(
          child: Center(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSpacing.xl),
              child: HomeFirstUseGuideCard(
                onDismiss: () => Navigator.of(context).pop(),
              ),
            ),
          ),
        );
      },
    );

    await prefs.setBool(_guideSeenKey, true);
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
                    onOpenFavorites: () {
                      Navigator.of(context).push(
                        MaterialPageRoute<void>(
                          builder: (_) => const FavoritesPageV2(),
                        ),
                      );
                    },
                    onOpenRecent: _submitRecentSuccessRecommendation,
                  ),
                  const SizedBox(height: 7),
                  Expanded(
                    child: _buildMainStage(session),
                  ),
                  if (session?.faceStage != TasteDeckFaceStage.signature) ...[
                    const SizedBox(height: 7),
                    _buildBottomControlPanel(),
                  ],
                ],
              ),
            ),
          ),
          if (_isTransitioning)
            const Positioned.fill(
              child: HomeGenerationTransitionOverlay(),
            ),
        ],
      ),
    );
  }

  Widget _buildBottomControlPanel() {
    return Container(
      height: 58,
      padding: const EdgeInsets.all(6),
      decoration: AppDecorations.floating(
        color: AppPalette.nightSurface.withValues(alpha: 0.94),
        borderColor: AppPalette.nightDivider,
      ),
      child: Row(
        children: [
          Expanded(child: _buildRequirementPanel()),
          const SizedBox(width: 7),
          _buildGenerateButton(),
        ],
      ),
    );
  }

  Widget _buildGenerateButton() {
    final session = _session;
    final canStart = session != null &&
        session
            .copyWith(freeformRequirement: _controller.text.trim())
            .canStartInference;
    final selectionCount = session == null
        ? 0
        : session.likedTagIds.length + session.dislikedTagIds.length;
    return SizedBox(
      width: 124,
      height: 46,
      child: FilledButton.icon(
        key: const ValueKey('home-start-inference-button'),
        onPressed: canStart && !_isTransitioning ? _submitGeneration : null,
        icon: const Icon(Icons.auto_awesome_rounded, size: 17),
        label: Text(
          selectionCount == 0 ? '生成建议' : '生成 · $selectionCount',
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w800),
        ),
        style: FilledButton.styleFrom(
          backgroundColor: AppPalette.leaf,
          disabledBackgroundColor: AppPalette.nightElevated,
          foregroundColor: AppPalette.night,
          disabledForegroundColor: AppPalette.moonMuted,
          elevation: canStart ? 5 : 0,
          shadowColor: AppPalette.leaf.withValues(alpha: 0.3),
        ),
      ),
    );
  }

  Widget _buildRequirementPanel() {
    return Container(
      height: 46,
      padding: const EdgeInsets.symmetric(horizontal: 11),
      decoration: AppDecorations.card(
        color: AppPalette.nightElevated.withValues(alpha: 0.82),
        borderColor: AppPalette.nightDivider,
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              key: const ValueKey('home-requirement-input'),
              controller: _controller,
              focusNode: _focusNode,
              textInputAction: TextInputAction.done,
              minLines: 1,
              style: const TextStyle(
                color: AppPalette.moonlight,
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                height: 1.2,
              ),
              decoration: InputDecoration(
                isDense: true,
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
                hintText: '补充忌口或今天特别想吃的',
                hintStyle: TextStyle(
                  color: AppPalette.moonMuted.withValues(alpha: 0.72),
                  fontSize: 12.5,
                  fontWeight: FontWeight.w500,
                ),
              ),
              onSubmitted: (_) => _submitGeneration(),
            ),
          ),
          const SizedBox(width: 7),
          GestureDetector(
            key: const ValueKey('home-requirement-mode-pill'),
            behavior: HitTestBehavior.opaque,
            onLongPressStart: (_) => _startVoiceCapture(),
            onLongPressEnd: (_) => _finishVoiceCapture(),
            child: SizedBox(
              width: 32,
              height: 32,
              child: Icon(
                _isListening
                    ? Icons.graphic_eq_rounded
                    : Icons.mic_none_rounded,
                size: 18,
                color: _isListening
                    ? AppPalette.leaf
                    : AppPalette.moonMuted,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainStage(TasteDeckSessionState? session) {
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
                  ? const Center(
                      key: ValueKey('taste-physical-loading'),
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
    required this.onOpenFavorites,
    required this.onOpenRecent,
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
  final VoidCallback onOpenFavorites;
  final VoidCallback onOpenRecent;

  static const _categories = <({String label, String? value})>[
    (label: '全部', value: null),
    (label: '食材健康', value: 'ingredient_dietary'),
    (label: '口味主食', value: 'flavor_staple'),
    (label: '菜系', value: 'cuisine'),
    (label: '场景趣味', value: 'scene_fun'),
  ];

  @override
  Widget build(BuildContext context) {
    final matchesHistory = habitSnapshot?.recommendedDirection == planningDirection;
    return SizedBox(
      key: const ValueKey('taste-entity-category-tabs'),
      height: 40,
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
          _FilterIconPill<int>(
            key: const ValueKey('filter-budget'),
            icon: Icons.payments_outlined,
            tooltip: '预算',
            active: constraints.maxBudgetYuan != null,
            value: constraints.maxBudgetYuan ?? 0,
            options: const [
              _FilterOption(key: 'filter-budget-any', label: '不限', value: 0),
              _FilterOption(key: 'filter-budget-30', label: '30 元内', value: 30),
              _FilterOption(key: 'filter-budget-60', label: '60 元内', value: 60),
              _FilterOption(
                  key: 'filter-budget-100', label: '100 元内', value: 100),
            ],
            onSelected: (value) => onStructuredConstraintsChanged(
              constraints.copyWith(
                maxBudgetYuan: value == 0 ? null : value,
                clearMaxBudgetYuan: value == 0,
              ),
            ),
          ),
          const SizedBox(width: 5),
          _FilterIconPill<int>(
            key: const ValueKey('filter-party'),
            icon: Icons.group_outlined,
            tooltip: '人数',
            active: constraints.partySize != null,
            value: constraints.partySize ?? 0,
            options: const [
              _FilterOption(key: 'filter-party-any', label: '不限', value: 0),
              _FilterOption(key: 'filter-party-1', label: '1 人', value: 1),
              _FilterOption(key: 'filter-party-2', label: '2 人', value: 2),
              _FilterOption(key: 'filter-party-4', label: '4 人', value: 4),
            ],
            onSelected: (value) => onStructuredConstraintsChanged(
              constraints.copyWith(
                partySize: value == 0 ? null : value,
                clearPartySize: value == 0,
              ),
            ),
          ),
          const SizedBox(width: 5),
          _FilterIconPill<TasteExecutionPreference>(
            key: const ValueKey('filter-execution'),
            icon: Icons.restaurant_rounded,
            tooltip: '方式',
            active:
                constraints.executionPreference != TasteExecutionPreference.any,
            value: constraints.executionPreference,
            options: [
              for (final preference in TasteExecutionPreference.values)
                _FilterOption(
                  key: 'filter-execution-${preference.name}',
                  label: preference.label,
                  value: preference,
                ),
            ],
            onSelected: (value) => onStructuredConstraintsChanged(
              constraints.copyWith(executionPreference: value),
            ),
          ),
          const Spacer(),
          _HeaderSelectionSummary(
            likedCount: likedCount,
            blockedCount: blockedCount,
            onTap: onShowSignature,
          ),
          const SizedBox(width: 5),
          _HeaderAction(
            key: const ValueKey('home-favorites-button'),
            icon: Icons.favorite_border_rounded,
            tooltip: '收藏',
            onTap: onOpenFavorites,
          ),
          const SizedBox(width: 5),
          _HeaderAction(
            key: const ValueKey('home-recent-button'),
            icon: Icons.history_rounded,
            tooltip: '吃过',
            onTap: onOpenRecent,
          ),
        ],
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
      child: Container(
        width: 34,
        height: 34,
        decoration: BoxDecoration(
          color: AppPalette.nightSurface.withValues(alpha: 0.92),
          borderRadius: AppRadii.capsule,
          border: Border.all(
            color: active ? AppPalette.leaf : AppPalette.nightDivider,
            width: active ? 1.4 : 1,
          ),
        ),
        child: Icon(
          icon,
          size: 16,
          color: active ? AppPalette.leaf : AppPalette.moonMuted,
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
                  style: const TextStyle(
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

class _HeaderAction extends StatelessWidget {
  const _HeaderAction({
    super.key,
    required this.icon,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: AppPalette.nightSurface.withValues(alpha: 0.92),
        shape: const CircleBorder(
          side: BorderSide(color: AppPalette.nightDivider),
        ),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: SizedBox(
            width: 34,
            height: 34,
            child: Icon(icon, size: 16, color: AppPalette.moonMuted),
          ),
        ),
      ),
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
    return Material(
      key: const ValueKey('taste-signature-button'),
      color: AppPalette.nightSurface.withValues(alpha: 0.92),
      borderRadius: AppRadii.capsule,
      child: InkWell(
        key: const ValueKey('taste-entity-selection-summary'),
        onTap: onTap,
        borderRadius: AppRadii.capsule,
        child: Container(
          height: 34,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            borderRadius: AppRadii.capsule,
            border: Border.all(color: AppPalette.nightDivider),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.favorite_rounded,
                size: 14,
                color: AppPalette.leaf,
              ),
              const SizedBox(width: 3),
              Text(
                '$likedCount',
                style: const TextStyle(
                  color: AppPalette.moonlight,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(width: 7),
              const Icon(
                Icons.block_rounded,
                size: 13,
                color: AppPalette.tomato,
              ),
              const SizedBox(width: 3),
              Text(
                '$blockedCount',
                style: const TextStyle(
                  color: AppPalette.moonlight,
                  fontSize: 11,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
