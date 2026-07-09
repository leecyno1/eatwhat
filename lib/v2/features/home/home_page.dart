import 'dart:async';
import 'dart:math';
import 'dart:ui';

import 'package:eatwhat_app/v2/core/data/models/taste_inference_input.dart';
import 'package:eatwhat_app/v2/core/data/models/taste_selection_models.dart';
import 'package:eatwhat_app/v2/core/data/repositories/tag_repository_v2.dart';
import 'package:eatwhat_app/v2/core/navigation/app_v2_router.dart';
import 'package:eatwhat_app/v2/core/services/v2_favorites_service.dart';
import 'package:eatwhat_app/v2/core/services/v2_preference_feedback_service.dart';
import 'package:eatwhat_app/v2/core/services/v2_speech_input_service.dart';
import 'package:eatwhat_app/v2/features/favorites/favorites_page.dart';
import 'package:eatwhat_app/v2/features/home/controllers/home_recent_success_controller.dart';
import 'package:eatwhat_app/v2/features/home/controllers/home_taste_deck_builder.dart';
import 'package:eatwhat_app/v2/features/home/widgets/floating_editorial_background.dart';
import 'package:eatwhat_app/v2/features/home/widgets/home_action_surfaces.dart';
import 'package:eatwhat_app/v2/features/home/widgets/home_overlays.dart';
import 'package:eatwhat_app/v2/features/home/widgets/taste_card_deck.dart';
import 'package:eatwhat_app/v2/features/home/widgets/taste_signature_panel.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_tokens.dart';

typedef HomeDecisionPageBuilder = Widget Function(TasteInferenceInput input);

const _quickConstraintPhrases = <String>[
  '15 分钟内',
  '30 元内',
  '1 人',
  '2-3 人',
  '在家做',
  '叫外卖',
  '去店里',
  '附近',
  '素食',
  '清真',
  '不要辣',
];

const _quickConstraintSpecs = <String, TasteStructuredConstraints>{
  '15 分钟内': TasteStructuredConstraints(maxTimeMinutes: 15),
  '30 元内': TasteStructuredConstraints(maxBudgetYuan: 30),
  '1 人': TasteStructuredConstraints(partySize: 1),
  '2-3 人': TasteStructuredConstraints(partySize: 3),
  '在家做': TasteStructuredConstraints(
    executionPreference: TasteExecutionPreference.cook,
  ),
  '叫外卖': TasteStructuredConstraints(
    executionPreference: TasteExecutionPreference.delivery,
  ),
  '去店里': TasteStructuredConstraints(
    executionPreference: TasteExecutionPreference.dineIn,
  ),
  '附近': TasteStructuredConstraints(
    locationPreference: TasteLocationPreference.nearby,
  ),
  '素食': TasteStructuredConstraints(dietaryRestrictions: ['素食']),
  '清真': TasteStructuredConstraints(dietaryRestrictions: ['清真']),
};

class HomePage extends StatefulWidget {
  const HomePage({
    super.key,
    this.speechInputService,
    this.decisionPageBuilder,
  });

  final V2SpeechInputService? speechInputService;
  final HomeDecisionPageBuilder? decisionPageBuilder;

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> with TickerProviderStateMixin {
  static const _guideSeenKey = 'v2_home_generation_guide_seen';
  static const _flipHintSeenKey = 'v2_home_flip_hint_seen';

  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final HomeTasteDeckBuilder _deckBuilder = const HomeTasteDeckBuilder();
  final HomeRecentSuccessController _recentSuccessController =
      const HomeRecentSuccessController();
  final V2FavoritesService _favorites = V2FavoritesService.instance;
  final V2PreferenceFeedbackService _feedback =
      V2PreferenceFeedbackService.instance;
  late final AnimationController _entranceController;
  late final AnimationController _headerMotionController;
  late final AnimationController _legendBreathController;
  late final AnimationController _legendCueController;
  late final V2SpeechInputService _speechInputService;

  Timer? _transitionCueTimer;
  Completer<void>? _transitionCueCompleter;
  bool _isTransitioning = false;
  bool _isLoadingDeck = true;
  bool _isListening = false;
  bool _showFlipHint = false;
  int _lastPageDirection = -1;
  int _pageAnimationSerial = 0;
  String _liveTranscript = '';
  _LegendCue _activeLegendCue = _LegendCue.none;
  _LegendCue _previewLegendCue = _LegendCue.none;
  TasteDeckSessionState? _session;
  Map<String, int> _historyScores = const {};
  List<String> _recentRecipeIds = const [];

  @override
  void initState() {
    super.initState();
    _controller.addListener(_handleRequirementChanged);
    _entranceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..forward();
    _headerMotionController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 320),
    );
    _legendBreathController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );
    _legendCueController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    )..addStatusListener((status) {
        if (status != AnimationStatus.completed || !mounted) return;
        setState(() {
          _activeLegendCue = _LegendCue.none;
        });
        _legendCueController.value = 0;
      });
    final isWidgetTestBinding = WidgetsBinding.instance.runtimeType
        .toString()
        .contains('TestWidgetsFlutterBinding');
    if (!isWidgetTestBinding) {
      _legendBreathController.repeat();
    } else {
      _legendBreathController.value = 0.35;
    }
    _speechInputService =
        widget.speechInputService ?? V2SpeechInputServiceImpl();
    unawaited(_speechInputService.initialize());
    _restoreHintStates();
    _prepareDeck();
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
    _controller.removeListener(_handleRequirementChanged);
    _entranceController.dispose();
    _headerMotionController.dispose();
    _legendBreathController.dispose();
    _legendCueController.dispose();
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _handleRequirementChanged() {
    if (!mounted) return;
    setState(() {});
  }

  void _triggerLegendCue(_LegendCue cue) {
    setState(() {
      _activeLegendCue = cue;
    });
    _legendCueController
      ..stop()
      ..value = 0
      ..forward();
  }

  void _setPreviewLegendCue(_LegendCue cue) {
    if (_previewLegendCue == cue) return;
    setState(() {
      _previewLegendCue = cue;
    });
  }

  _LegendCue get _effectiveCue {
    return _activeLegendCue != _LegendCue.none
        ? _activeLegendCue
        : _previewLegendCue;
  }

  double _stageCueIntensity(double focus) {
    if (_activeLegendCue != _LegendCue.none) {
      return (0.18 + focus * 0.82).clamp(0.0, 1.0);
    }
    if (_previewLegendCue != _LegendCue.none) {
      return 0.62;
    }
    if (_isListening) {
      return 0.58;
    }
    return 0;
  }

  Future<void> _prepareDeck() async {
    final historyScores = await _feedback.getTagScores();
    final recentRecipeIds = await _feedback.getRecentRecipeIds(limit: 5);
    final favoriteTagIds = await _favorites.getFavoriteTagIds();
    final seed = DateTime.now().millisecondsSinceEpoch.remainder(1 << 31);

    final fallbackCards = HomeTasteDeckBuilder(
      tagRepository: TagRepositoryV2(),
    ).buildDeck(
      seed: seed,
      historyScores: historyScores,
      favoriteTagIds: favoriteTagIds,
    );

    if (!mounted) return;
    setState(() {
      _historyScores = historyScores;
      _recentRecipeIds = recentRecipeIds;
      _session = TasteDeckSessionState.initial(
        deck: fallbackCards,
        cardDeckSeed: seed,
      );
      _isLoadingDeck = false;
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

  Future<void> _restoreHintStates() async {
    final prefs = await SharedPreferences.getInstance();
    final hasSeenFlipHint = prefs.getBool(_flipHintSeenKey) ?? false;
    if (!mounted) return;
    setState(() {
      _showFlipHint = !hasSeenFlipHint;
    });
  }

  Future<void> _showFirstUseGuideIfNeeded() async {
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

  Future<void> _handleReaction(
    TasteDeckCard card,
    TasteCardReaction reaction,
  ) async {
    final session = _session;
    if (session == null) return;

    if (reaction == TasteCardReaction.liked) {
      unawaited(_feedback.recordPositiveTag(card.id));
      _triggerLegendCue(_LegendCue.like);
    } else if (reaction == TasteCardReaction.disliked) {
      unawaited(_feedback.recordNegativeTag(card.id));
      _triggerLegendCue(_LegendCue.dislike);
    }

    setState(() {
      _session = session.recordReaction(card, reaction);
    });
  }

  void _advancePage() {
    final session = _session;
    if (session == null) return;
    setState(() {
      _session = session.advancePage();
      _pageAnimationSerial += 1;
    });
    _headerMotionController
      ..stop()
      ..value = 0
      ..forward();
  }

  void _handlePageAdvanceDirection(int direction) {
    setState(() {
      _lastPageDirection = direction == 0 ? -1 : direction.sign;
    });
    _triggerLegendCue(_LegendCue.refresh);
  }

  void _handleCardPreview(TasteCardReaction? reaction) {
    final cue = switch (reaction) {
      TasteCardReaction.liked => _LegendCue.like,
      TasteCardReaction.disliked => _LegendCue.dislike,
      TasteCardReaction.skipped => _LegendCue.none,
      null => _LegendCue.none,
    };
    _setPreviewLegendCue(cue);
  }

  void _handlePagePreview(int direction) {
    _setPreviewLegendCue(direction == 0 ? _LegendCue.none : _LegendCue.refresh);
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

  Future<void> _handleFirstFlip() async {
    if (!_showFlipHint) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_flipHintSeenKey, true);
    if (!mounted) return;
    setState(() {
      _showFlipHint = false;
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
    _triggerLegendCue(_LegendCue.voice);

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

  void _appendConstraintPhrase(String phrase) {
    final session = _session;
    final current = _controller.text.trim();
    final parts = current
        .split(RegExp(r'[，,、]+'))
        .map((part) => part.trim())
        .where((part) => part.isNotEmpty)
        .toList();
    if (!parts.contains(phrase)) {
      parts.add(phrase);
    }
    final nextText = parts.join('，');
    _controller.value = TextEditingValue(
      text: nextText,
      selection: TextSelection.collapsed(offset: nextText.length),
    );
    final spec = _quickConstraintSpecs[phrase];
    if (session == null || spec == null) return;
    late final TasteDeckSessionState nextSession;
    setState(() {
      nextSession = session.copyWith(
        structuredConstraints: _mergeStructuredConstraints(
          session.structuredConstraints,
          spec,
        ),
      );
      _session = nextSession;
    });
  }

  TasteStructuredConstraints _mergeStructuredConstraints(
    TasteStructuredConstraints current,
    TasteStructuredConstraints next,
  ) {
    final restrictions = {
      ...current.dietaryRestrictions,
      ...next.dietaryRestrictions,
    }.toList();
    return current.copyWith(
      maxTimeMinutes: next.maxTimeMinutes,
      maxBudgetYuan: next.maxBudgetYuan,
      partySize: next.partySize,
      dietaryRestrictions: restrictions,
      executionPreference: next.executionPreference,
      locationPreference: next.locationPreference,
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
        const SnackBar(content: Text('先滑几张卡，或者补一句今天想吃的')),
      );
      return;
    }

    final input = TasteInferenceInput.fromSession(
      nextSession,
      historyPreferenceSummary: _historyScores,
    );

    setState(() {
      _session = nextSession;
    });
    await _openDecisionFlow(input);
  }

  Future<void> _submitRecentSuccessRecommendation() async {
    final session = _session;
    if (_isTransitioning || session == null || _recentRecipeIds.isEmpty) {
      return;
    }

    final input = _recentSuccessController.buildInput(
      session: session,
      historyScores: _historyScores,
      recentRecipeIds: _recentRecipeIds,
    );
    if (input == null) return;

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
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => widget.decisionPageBuilder!.call(input),
          ),
        );
      } else {
        await context.push(
          AppV2Routes.decision,
          extra: AppV2DecisionRouteData(input: input),
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

  @override
  Widget build(BuildContext context) {
    final session = _session;
    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          const FloatingEditorialBackground(),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(8, 4, 8, 6),
              child: Column(
                children: [
                  Expanded(
                    child: _buildMainStage(session),
                  ),
                  const SizedBox(height: 6),
                  _buildBottomControlPanel(session),
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

  Widget _buildBottomControlPanel(TasteDeckSessionState? session) {
    return Container(
      padding: const EdgeInsets.fromLTRB(8, 7, 8, 8),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.62)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.72),
            const Color(0xFFFFEEE8).withValues(alpha: 0.38),
          ],
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: _BottomNavTile(
                  icon: Icons.favorite_rounded,
                  label: '收藏',
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute<void>(
                        builder: (_) => const FavoritesPageV2(),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _BottomNavTile(
                  icon: Icons.history_rounded,
                  label: '吃过',
                  onTap: _submitRecentSuccessRecommendation,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _BottomNavTile(
                  icon: Icons.tune_rounded,
                  label: '限制',
                  onTap: () => _appendConstraintPhrase('15 分钟内'),
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: _BottomNavTile(
                  icon: Icons.auto_awesome_rounded,
                  label: '签名',
                  onTap: _showSignature,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          _buildRequirementPanel(),
        ],
      ),
    );
  }

  Widget _buildRequirementPanel() {
    return Container(
      padding: const EdgeInsets.fromLTRB(9, 5, 9, 6),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.54)),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.78),
            const Color(0xFFFFEEE8).withValues(alpha: 0.46),
          ],
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: TextField(
                        key: const ValueKey('home-requirement-input'),
                        controller: _controller,
                        focusNode: _focusNode,
                        textInputAction: TextInputAction.done,
                        minLines: 1,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          height: 1.1,
                        ),
                        decoration: InputDecoration(
                          isDense: true,
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.zero,
                          hintText: '今天想怎么吃',
                          hintStyle: TextStyle(
                            color:
                                AppColors.textPrimary.withValues(alpha: 0.42),
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        onSubmitted: (_) => _showSignature(),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      key: const ValueKey('home-requirement-mode-pill'),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.52),
                        borderRadius: BorderRadius.circular(999),
                        border: Border.all(
                          color: Colors.white.withValues(alpha: 0.58),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            Icons.keyboard_alt_rounded,
                            size: 11,
                            color:
                                AppColors.textPrimary.withValues(alpha: 0.46),
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '输入/长按',
                            style: TextStyle(
                              color:
                                  AppColors.textPrimary.withValues(alpha: 0.46),
                              fontSize: 8.6,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      for (final phrase in _quickConstraintPhrases) ...[
                        _RequirementConstraintChip(
                          label: phrase,
                          onTap: () => _appendConstraintPhrase(phrase),
                        ),
                        const SizedBox(width: 5),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMainStage(TasteDeckSessionState? session) {
    final effectiveCue = _effectiveCue;
    final canStartInference = session != null &&
        session
            .copyWith(freeformRequirement: _controller.text.trim())
            .canStartInference;
    final readySelectionCount = session == null
        ? 0
        : session.likedTagIds.length + session.dislikedTagIds.length;
    return Container(
      key: const ValueKey('taste-card-stage-shell'),
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.68),
          width: 0.9,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x1818100D),
            blurRadius: 22,
            offset: Offset(0, 10),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: Stack(
          children: [
            Positioned.fill(
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 20, sigmaY: 20),
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white.withValues(alpha: 0.34),
                        const Color(0xFFFDE8DE).withValues(alpha: 0.24),
                        const Color(0xFFFFF7F2).withValues(alpha: 0.18),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned.fill(
              child: AnimatedBuilder(
                animation: Listenable.merge([
                  _headerMotionController,
                  _legendCueController,
                ]),
                builder: (context, _) {
                  final burst = Curves.easeOutCubic
                      .transform(_headerMotionController.value);
                  final focus = sin(_legendCueController.value * pi);
                  return _StageResponseOverlay(
                    cue: effectiveCue,
                    intensity: _stageCueIntensity(focus),
                    horizontalDirection: _lastPageDirection,
                    burst: burst,
                  );
                },
              ),
            ),
            if (_isLoadingDeck || session == null)
              const Center(child: CircularProgressIndicator())
            else
              Padding(
                padding: const EdgeInsets.fromLTRB(6, 6, 6, 6),
                child: session.faceStage == TasteDeckFaceStage.signature
                    ? TasteSignaturePanel(
                        session: session.copyWith(
                          freeformRequirement: _controller.text.trim(),
                        ),
                        onBack: _showDeck,
                        onStartInference: _submitGeneration,
                      )
                    : AnimatedSwitcher(
                        duration: const Duration(milliseconds: 260),
                        switchInCurve: Curves.easeOutCubic,
                        switchOutCurve: Curves.easeInCubic,
                        transitionBuilder: (child, animation) {
                          final slide = Tween<Offset>(
                            begin: const Offset(0.08, 0),
                            end: Offset.zero,
                          ).animate(animation);
                          return FadeTransition(
                            opacity: animation,
                            child: SlideTransition(
                              position: slide,
                              child: child,
                            ),
                          );
                        },
                        child: TasteCardDeck(
                          key: ValueKey(
                            'taste-grid-page-${session.currentPageNumber}-$_pageAnimationSerial',
                          ),
                          cards: session.currentPageCards,
                          session: session,
                          onReact: _handleReaction,
                          onReactionPreview: _handleCardPreview,
                          onAdvancePage: _advancePage,
                          onPageAdvanceDirection: _handlePageAdvanceDirection,
                          onPagePreviewDirection: _handlePagePreview,
                          onVoiceStart: _startVoiceCapture,
                          onVoiceEnd: _finishVoiceCapture,
                          isListening: _isListening,
                          showFlipHint: _showFlipHint,
                          onFirstFlip: () {
                            unawaited(_handleFirstFlip());
                          },
                        ),
                      ),
              ),
            if (!_isLoadingDeck &&
                session != null &&
                session.faceStage == TasteDeckFaceStage.deck)
              Positioned(
                left: 12,
                top: 10,
                child: _StageCornerMetrics(session: session),
              ),
            if (!_isLoadingDeck &&
                session != null &&
                session.faceStage == TasteDeckFaceStage.deck)
              Positioned(
                right: 12,
                top: 10,
                child: _StageSignatureCornerButton(
                  onPressed: _showSignature,
                  isListening: _isListening,
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
            if (!_isLoadingDeck &&
                session != null &&
                session.faceStage == TasteDeckFaceStage.deck &&
                canStartInference)
              Positioned(
                left: 18,
                right: 18,
                bottom: 18,
                child: IgnorePointer(
                  ignoring: _isListening,
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: HomeStartInferenceButton(
                      canStartInference: canStartInference,
                      readySelectionCount: readySelectionCount,
                      onPressed: _submitGeneration,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _RequirementConstraintChip extends StatelessWidget {
  const _RequirementConstraintChip({
    required this.label,
    required this.onTap,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      key: ValueKey('home-constraint-chip-$label'),
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(999),
        onTap: onTap,
        child: Ink(
          height: 25,
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.54),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: Colors.white.withValues(alpha: 0.6)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                _iconForLabel(label),
                size: 12,
                color: const Color(0xFFF46B40),
              ),
              const SizedBox(width: 4),
              Text(
                label,
                style: TextStyle(
                  color: AppColors.textPrimary.withValues(alpha: 0.66),
                  fontSize: 9.6,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _iconForLabel(String label) {
    if (label.contains('分钟')) return Icons.timer_rounded;
    if (label.contains('元')) return Icons.payments_rounded;
    if (label.contains('人')) return Icons.group_rounded;
    if (label.contains('在家')) return Icons.soup_kitchen_rounded;
    if (label.contains('外卖')) return Icons.delivery_dining_rounded;
    if (label.contains('店')) return Icons.storefront_rounded;
    if (label.contains('附近')) return Icons.near_me_rounded;
    if (label.contains('素')) return Icons.eco_rounded;
    if (label.contains('清真')) return Icons.verified_rounded;
    return Icons.tune_rounded;
  }
}

class _BottomNavTile extends StatelessWidget {
  const _BottomNavTile({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Ink(
          height: 34,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.52),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.white.withValues(alpha: 0.58)),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 14,
                color: const Color(0xFFF46B40),
              ),
              const SizedBox(height: 1),
              Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppColors.textPrimary.withValues(alpha: 0.66),
                  fontSize: 9,
                  fontWeight: FontWeight.w900,
                  height: 1,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _StageCornerMetrics extends StatelessWidget {
  const _StageCornerMetrics({
    required this.session,
  });

  final TasteDeckSessionState session;

  @override
  Widget build(BuildContext context) {
    return Row(
      key: const ValueKey('taste-stage-corner-metrics'),
      mainAxisSize: MainAxisSize.min,
      children: [
        _StageMetricChip(
          label: '${session.currentPageNumber}/${session.totalPageCount}',
          tone: _MetricTone.neutral,
        ),
        const SizedBox(width: 4),
        _StageMetricChip(
          label: '选 ${session.likedTagIds.length}',
          tone: _MetricTone.warm,
        ),
        const SizedBox(width: 4),
        _StageMetricChip(
          label: '排 ${session.dislikedTagIds.length}',
          tone: _MetricTone.cool,
        ),
      ],
    );
  }
}

class _StageSignatureCornerButton extends StatelessWidget {
  const _StageSignatureCornerButton({
    required this.onPressed,
    required this.isListening,
  });

  final VoidCallback onPressed;
  final bool isListening;

  @override
  Widget build(BuildContext context) {
    return TextButton.icon(
      key: const ValueKey('taste-signature-button'),
      onPressed: onPressed,
      style: TextButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        backgroundColor: Colors.white.withValues(alpha: 0.62),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(999),
          side: BorderSide(color: Colors.white.withValues(alpha: 0.58)),
        ),
      ),
      icon: Icon(
        isListening ? Icons.mic_rounded : Icons.auto_awesome_rounded,
        size: 12,
        color: const Color(0xFFF46B40),
      ),
      label: const Text(
        '签名',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w900,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}

enum _LegendCue {
  none,
  like,
  dislike,
  refresh,
  voice,
}

enum _MetricTone {
  neutral,
  warm,
  cool,
}

class _StageMetricChip extends StatelessWidget {
  const _StageMetricChip({
    required this.label,
    required this.tone,
  });

  final String label;
  final _MetricTone tone;

  @override
  Widget build(BuildContext context) {
    final colors = switch (tone) {
      _MetricTone.neutral => (
          background: Colors.white.withValues(alpha: 0.56),
          foreground: AppColors.textPrimary.withValues(alpha: 0.66),
        ),
      _MetricTone.warm => (
          background: const Color(0xFFF46B40).withValues(alpha: 0.14),
          foreground: const Color(0xFFF46B40),
        ),
      _MetricTone.cool => (
          background: const Color(0xFF6E6973).withValues(alpha: 0.1),
          foreground: const Color(0xFF6E6973),
        ),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: colors.background,
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.54),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.white.withValues(alpha: 0.14),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Text(
        label,
        style: TextStyle(
          color: colors.foreground,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

class _StageResponseOverlay extends StatelessWidget {
  const _StageResponseOverlay({
    required this.cue,
    required this.intensity,
    required this.horizontalDirection,
    required this.burst,
  });

  final _LegendCue cue;
  final double intensity;
  final int horizontalDirection;
  final double burst;

  @override
  Widget build(BuildContext context) {
    if (intensity <= 0) {
      return const SizedBox.shrink(
        key: ValueKey('taste-stage-response-overlay'),
      );
    }

    final clamped = intensity.clamp(0.0, 1.0);
    final directional = horizontalDirection == 0 ? -1 : horizontalDirection;
    final lateralShift = burst * 22 * directional;

    return IgnorePointer(
      child: Container(
        key: const ValueKey('taste-stage-response-overlay'),
        decoration: BoxDecoration(
          gradient: switch (cue) {
            _LegendCue.like => LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFFF46B40)
                      .withValues(alpha: 0.16 + clamped * 0.2),
                  const Color(0xFFFFC7B4)
                      .withValues(alpha: 0.08 + clamped * 0.14),
                  Colors.transparent,
                ],
                stops: const [0, 0.36, 0.82],
              ),
            _LegendCue.dislike => LinearGradient(
                begin: Alignment.bottomCenter,
                end: Alignment.topCenter,
                colors: [
                  const Color(0xFF6A626B)
                      .withValues(alpha: 0.18 + clamped * 0.18),
                  const Color(0xFFB6B0B8)
                      .withValues(alpha: 0.08 + clamped * 0.1),
                  Colors.transparent,
                ],
                stops: const [0, 0.32, 0.82],
              ),
            _LegendCue.refresh => LinearGradient(
                begin: directional > 0
                    ? Alignment.centerLeft
                    : Alignment.centerRight,
                end: directional > 0
                    ? Alignment.centerRight
                    : Alignment.centerLeft,
                colors: [
                  const Color(0xFF8A7CF7)
                      .withValues(alpha: 0.12 + clamped * 0.14),
                  const Color(0xFFCAD3FF)
                      .withValues(alpha: 0.08 + clamped * 0.1),
                  Colors.transparent,
                ],
                stops: const [0, 0.42, 0.9],
              ),
            _LegendCue.voice => RadialGradient(
                radius: 0.86,
                colors: [
                  const Color(0xFF45A6D8)
                      .withValues(alpha: 0.16 + clamped * 0.14),
                  const Color(0xFFAEE4FF)
                      .withValues(alpha: 0.08 + clamped * 0.08),
                  Colors.transparent,
                ],
                stops: const [0, 0.36, 1],
              ),
            _ => const LinearGradient(
                colors: [Colors.transparent, Colors.transparent],
              ),
          },
        ),
        child: Stack(
          children: [
            if (cue == _LegendCue.like)
              Align(
                alignment: Alignment.topCenter,
                child: FractionallySizedBox(
                  widthFactor: 0.92,
                  heightFactor: 0.48,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: const Alignment(0, -0.6),
                        radius: 1,
                        colors: [
                          Colors.white.withValues(alpha: 0.1 + clamped * 0.08),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            if (cue == _LegendCue.dislike)
              Align(
                alignment: Alignment.bottomCenter,
                child: FractionallySizedBox(
                  widthFactor: 0.96,
                  heightFactor: 0.44,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        center: const Alignment(0, 0.9),
                        radius: 1,
                        colors: [
                          Colors.black.withValues(alpha: 0.05 + clamped * 0.06),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            if (cue == _LegendCue.refresh)
              Transform.translate(
                offset: Offset(lateralShift, 0),
                child: Align(
                  alignment: directional > 0
                      ? Alignment.centerLeft
                      : Alignment.centerRight,
                  child: FractionallySizedBox(
                    widthFactor: 0.36,
                    heightFactor: 1,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: directional > 0
                              ? Alignment.centerLeft
                              : Alignment.centerRight,
                          end: directional > 0
                              ? Alignment.centerRight
                              : Alignment.centerLeft,
                          colors: [
                            Colors.white.withValues(alpha: 0.02),
                            const Color(0xFFD9E1FF)
                                .withValues(alpha: 0.1 + clamped * 0.12),
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            if (cue == _LegendCue.voice)
              Align(
                child: FractionallySizedBox(
                  widthFactor: 0.7,
                  heightFactor: 0.7,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: RadialGradient(
                        radius: 1,
                        colors: [
                          Colors.white.withValues(alpha: 0.04 + clamped * 0.05),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
