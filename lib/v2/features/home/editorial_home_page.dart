import 'dart:async';

import 'package:eatwhat_app/v2/core/data/models/taste_inference_input.dart';
import 'package:eatwhat_app/v2/core/data/models/taste_selection_models.dart';
import 'package:eatwhat_app/v2/core/data/repositories/tag_repository_v2.dart';
import 'package:eatwhat_app/v2/core/navigation/app_v2_router.dart';
import 'package:eatwhat_app/v2/core/services/v2_favorites_service.dart';
import 'package:eatwhat_app/v2/core/services/v2_preference_feedback_service.dart';
import 'package:eatwhat_app/v2/core/services/v2_speech_input_service.dart';
import 'package:eatwhat_app/v2/core/theme/app_tokens.dart';
import 'package:eatwhat_app/v2/features/decision/decision_page.dart';
import 'package:eatwhat_app/v2/features/favorites/favorites_page.dart';
import 'package:eatwhat_app/v2/features/home/controllers/home_recent_success_controller.dart';
import 'package:eatwhat_app/v2/features/home/controllers/home_taste_deck_builder.dart';
import 'package:eatwhat_app/v2/features/home/widgets/floating_editorial_background.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

typedef EditorialDecisionPageBuilder = Widget Function(
  TasteInferenceInput input,
);

class EditorialHomePage extends StatefulWidget {
  const EditorialHomePage({
    super.key,
    this.speechInputService,
    this.decisionPageBuilder,
    this.initialCards,
    this.favoritesPageBuilder,
  });

  final V2SpeechInputService? speechInputService;
  final EditorialDecisionPageBuilder? decisionPageBuilder;
  final List<TasteDeckCard>? initialCards;
  final WidgetBuilder? favoritesPageBuilder;

  @override
  State<EditorialHomePage> createState() => _EditorialHomePageState();
}

class _EditorialHomePageState extends State<EditorialHomePage> {
  static const _quickConstraints = <String>[
    '15 分钟内',
    '30 元内',
    '1 人',
    '在家做',
    '叫外卖',
    '去店里',
    '附近',
    '素食',
    '不要辣',
  ];

  final TextEditingController _requirementController = TextEditingController();
  final FocusNode _requirementFocusNode = FocusNode();
  final HomeTasteDeckBuilder _deckBuilder = const HomeTasteDeckBuilder();
  final HomeRecentSuccessController _recentSuccessController =
      const HomeRecentSuccessController();
  final V2FavoritesService _favorites = V2FavoritesService.instance;
  final V2PreferenceFeedbackService _feedback =
      V2PreferenceFeedbackService.instance;

  late final V2SpeechInputService _speechInputService;
  TasteDeckSessionState? _session;
  Map<String, int> _historyScores = const {};
  List<String> _recentRecipeIds = const [];
  bool _isLoading = true;
  bool _isListening = false;
  bool _isOpeningDecision = false;
  int _tasteOffset = 0;

  @override
  void initState() {
    super.initState();
    _speechInputService =
        widget.speechInputService ?? V2SpeechInputServiceImpl();
    unawaited(_speechInputService.initialize());
    final initialCards = widget.initialCards;
    if (initialCards != null) {
      _installDeck(initialCards, seed: 0);
    } else {
      unawaited(_prepareDeck());
    }
  }

  @override
  void dispose() {
    _requirementController.dispose();
    _requirementFocusNode.dispose();
    super.dispose();
  }

  Future<void> _prepareDeck() async {
    final historyScores = await _feedback.getTagScores();
    final recentRecipeIds = await _feedback.getRecentRecipeIds(limit: 8);
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
    });
    _installDeck(fallbackCards, seed: seed);

    final catalogCards = await _deckBuilder.buildDeckFromCatalog(
      seed: seed,
      historyScores: historyScores,
      favoriteTagIds: favoriteTagIds,
    );
    if (!mounted || catalogCards.isEmpty) return;
    final currentSession = _session;
    if (currentSession == null || currentSession.reviewedCount > 0) return;
    _installDeck(catalogCards, seed: seed);
  }

  void _installDeck(List<TasteDeckCard> cards, {required int seed}) {
    if (!mounted) return;
    final safeCards = cards.isEmpty ? _fallbackCards : cards;
    setState(() {
      _session = TasteDeckSessionState.initial(
        deck: safeCards,
        cardDeckSeed: seed,
      );
      _isLoading = false;
      _tasteOffset = 0;
    });
  }

  List<TasteDeckCard> get _visibleCards {
    final deck = _session?.deck ?? const <TasteDeckCard>[];
    if (deck.isEmpty) return const [];
    final count = deck.length < 8 ? deck.length : 8;
    return List<TasteDeckCard>.generate(
      count,
      (index) => deck[(_tasteOffset + index) % deck.length],
    );
  }

  void _rotateTasteCards() {
    final deck = _session?.deck ?? const <TasteDeckCard>[];
    if (deck.length <= 8) return;
    HapticFeedback.selectionClick();
    setState(() {
      _tasteOffset = (_tasteOffset + 8) % deck.length;
    });
  }

  void _toggleLiked(TasteDeckCard card) {
    final session = _session;
    if (session == null) return;
    final liked = List<String>.from(session.likedTagIds);
    final disliked = List<String>.from(session.dislikedTagIds)..remove(card.id);
    final isAdding = !liked.remove(card.id);
    if (isAdding) liked.add(card.id);
    HapticFeedback.selectionClick();
    setState(() {
      _session = session.copyWith(
        likedTagIds: liked,
        dislikedTagIds: disliked,
      );
    });
    if (isAdding) {
      unawaited(_feedback.recordPositiveTag(card.id));
    }
  }

  void _toggleDisliked(TasteDeckCard card) {
    final session = _session;
    if (session == null) return;
    final liked = List<String>.from(session.likedTagIds)..remove(card.id);
    final disliked = List<String>.from(session.dislikedTagIds);
    final isAdding = !disliked.remove(card.id);
    if (isAdding) disliked.add(card.id);
    HapticFeedback.mediumImpact();
    setState(() {
      _session = session.copyWith(
        likedTagIds: liked,
        dislikedTagIds: disliked,
      );
    });
    if (isAdding) {
      unawaited(_feedback.recordNegativeTag(card.id));
    }
  }

  void _toggleConstraint(String label) {
    final session = _session;
    if (session == null) return;
    final current = session.structuredConstraints;
    var next = current;

    switch (label) {
      case '15 分钟内':
        next = current.maxTimeMinutes == 15
            ? current.copyWith(clearMaxTimeMinutes: true)
            : current.copyWith(maxTimeMinutes: 15);
      case '30 元内':
        next = current.maxBudgetYuan == 30
            ? current.copyWith(clearMaxBudgetYuan: true)
            : current.copyWith(maxBudgetYuan: 30);
      case '1 人':
        next = current.partySize == 1
            ? current.copyWith(clearPartySize: true)
            : current.copyWith(partySize: 1);
      case '在家做':
        next = current.copyWith(
          executionPreference:
              current.executionPreference == TasteExecutionPreference.cook
                  ? TasteExecutionPreference.any
                  : TasteExecutionPreference.cook,
        );
      case '叫外卖':
        next = current.copyWith(
          executionPreference:
              current.executionPreference == TasteExecutionPreference.delivery
                  ? TasteExecutionPreference.any
                  : TasteExecutionPreference.delivery,
        );
      case '去店里':
        next = current.copyWith(
          executionPreference:
              current.executionPreference == TasteExecutionPreference.dineIn
                  ? TasteExecutionPreference.any
                  : TasteExecutionPreference.dineIn,
        );
      case '附近':
        next = current.copyWith(
          locationPreference:
              current.locationPreference == TasteLocationPreference.nearby
                  ? TasteLocationPreference.any
                  : TasteLocationPreference.nearby,
        );
      case '素食':
      case '不要辣':
        final restrictions = List<String>.from(current.dietaryRestrictions);
        if (!restrictions.remove(label)) restrictions.add(label);
        next = current.copyWith(dietaryRestrictions: restrictions);
    }

    HapticFeedback.selectionClick();
    setState(() {
      _session = session.copyWith(structuredConstraints: next);
    });
  }

  bool _isConstraintSelected(String label) {
    final constraints = _session?.structuredConstraints;
    if (constraints == null) return false;
    return switch (label) {
      '15 分钟内' => constraints.maxTimeMinutes == 15,
      '30 元内' => constraints.maxBudgetYuan == 30,
      '1 人' => constraints.partySize == 1,
      '在家做' => constraints.executionPreference == TasteExecutionPreference.cook,
      '叫外卖' =>
        constraints.executionPreference == TasteExecutionPreference.delivery,
      '去店里' =>
        constraints.executionPreference == TasteExecutionPreference.dineIn,
      '附近' => constraints.locationPreference == TasteLocationPreference.nearby,
      '素食' || '不要辣' => constraints.dietaryRestrictions.contains(label),
      _ => false,
    };
  }

  Future<void> _toggleVoiceInput() async {
    if (_isListening) {
      final transcript = await _speechInputService.stopListening();
      if (!mounted) return;
      setState(() {
        _isListening = false;
      });
      if (transcript.isNotEmpty) _setRequirementText(transcript);
      return;
    }

    final ready = await _speechInputService.initialize();
    if (!ready) {
      if (!mounted) return;
      _showMessage('语音暂时不可用，可以直接输入文字');
      _requirementFocusNode.requestFocus();
      return;
    }

    setState(() {
      _isListening = true;
    });
    await _speechInputService.startListening(
      onResult: (transcript, isFinal) {
        if (!mounted || transcript.trim().isEmpty) return;
        _setRequirementText(transcript.trim());
        if (isFinal) {
          setState(() {
            _isListening = false;
          });
        }
      },
    );
  }

  void _setRequirementText(String text) {
    _requirementController.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  Future<void> _submitGeneration() async {
    final session = _session;
    if (session == null || _isOpeningDecision) return;
    final nextSession = session.copyWith(
      freeformRequirement: _requirementController.text.trim(),
    );
    if (!nextSession.canStartInference) {
      _showMessage('先选一个口味，或者说说今天想吃什么');
      return;
    }

    setState(() {
      _session = nextSession;
    });
    final input = TasteInferenceInput.fromSession(
      nextSession,
      historyPreferenceSummary: _historyScores,
    );
    await _openDecision(input);
  }

  Future<void> _openRecentSuccess() async {
    final session = _session;
    if (session == null) return;
    final input = _recentSuccessController.buildInput(
      session: session,
      historyScores: _historyScores,
      recentRecipeIds: _recentRecipeIds,
    );
    if (input == null) {
      _showMessage('还没有吃过记录，先完成一次推荐吧');
      return;
    }
    await _openDecision(input);
  }

  Future<void> _openDecision(TasteInferenceInput input) async {
    if (_isOpeningDecision) return;
    setState(() {
      _isOpeningDecision = true;
    });
    try {
      if (widget.decisionPageBuilder != null) {
        await Navigator.of(context).push(
          MaterialPageRoute<void>(
            builder: (_) => widget.decisionPageBuilder!.call(input),
          ),
        );
        return;
      }

      if (GoRouter.maybeOf(context) != null) {
        await context.push(
          AppV2Routes.decision,
          extra: AppV2DecisionRouteData(input: input),
        );
        return;
      }

      if (!mounted) return;
      await Navigator.of(context).push(
        MaterialPageRoute<void>(
          builder: (_) => DecisionPage(input: input),
        ),
      );
    } finally {
      if (mounted) {
        setState(() {
          _isOpeningDecision = false;
        });
      }
    }
  }

  Future<void> _openFavorites() async {
    final page =
        widget.favoritesPageBuilder?.call(context) ?? const FavoritesPageV2();
    await Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => page),
    );
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final session = _session;
    final likedCount = session?.likedTagIds.length ?? 0;
    final dislikedCount = session?.dislikedTagIds.length ?? 0;
    final selectedLabels = session?.likedTagLabels ?? const <String>[];
    final heroReason = selectedLabels.isEmpty
        ? '热、香、下饭，25 分钟就能吃上。'
        : '${selectedLabels.take(2).join('、')}，先从这一口开始收窄。';

    return Scaffold(
      key: const ValueKey('editorial-home-page'),
      backgroundColor: AppPalette.broth,
      body: Stack(
        children: [
          const Positioned.fill(child: FloatingEditorialBackground()),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const _EditorialBrandHeader(),
                  const SizedBox(height: 24),
                  Text(
                    '今晚，\n吃点真的想吃的',
                    style: TextStyle(
                      color: AppPalette.ink,
                      fontFamily: 'Songti SC',
                      fontFamilyFallback: ['STSong', 'serif'],
                      fontSize: 34,
                      fontWeight: FontWeight.w700,
                      height: 1.13,
                      letterSpacing: -0.7,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '不用翻一百道菜。告诉我此刻的胃口，\n我替你把选择收窄到刚刚好。',
                    style: AppType.body,
                  ),
                  const SizedBox(height: 22),
                  Row(
                    children: [
                      Expanded(
                        child: Text('此刻的胃口', style: AppType.section),
                      ),
                      Text(
                        '喜欢 $likedCount · 排除 $dislikedCount',
                        style: AppType.label.copyWith(
                          color: likedCount + dislikedCount > 0
                              ? AppPalette.chili
                              : AppPalette.inkMuted,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        key: const ValueKey('editorial-refresh-tastes'),
                        tooltip: '换一组口味',
                        onPressed: _rotateTasteCards,
                        icon: const Icon(Icons.refresh_rounded, size: 19),
                        color: AppPalette.inkSoft,
                        visualDensity: VisualDensity.compact,
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  if (_isLoading)
                    const SizedBox(
                      height: 72,
                      child: Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  else
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        for (final card in _visibleCards)
                          _EditorialTasteChip(
                            card: card,
                            reaction: session?.pageReactionFor(card.id),
                            onTap: () => _toggleLiked(card),
                            onLongPress: () => _toggleDisliked(card),
                          ),
                      ],
                    ),
                  const SizedBox(height: 8),
                  Text(
                    '点一下表示喜欢，长按表示今天不想吃。',
                    style: AppType.label,
                  ),
                  const SizedBox(height: 18),
                  _EditorialHeroCard(reason: heroReason),
                  const SizedBox(height: 18),
                  Text('再加一点条件', style: AppType.section),
                  const SizedBox(height: 9),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final label in _quickConstraints) ...[
                          _EditorialConstraintChip(
                            label: label,
                            isSelected: _isConstraintSelected(label),
                            onTap: () => _toggleConstraint(label),
                          ),
                          const SizedBox(width: 7),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  _EditorialRequirementPanel(
                    controller: _requirementController,
                    focusNode: _requirementFocusNode,
                    isListening: _isListening,
                    isOpeningDecision: _isOpeningDecision,
                    onVoiceTap: _toggleVoiceInput,
                    onSubmit: _submitGeneration,
                  ),
                  const SizedBox(height: 14),
                  _EditorialBottomNav(
                    onFavorites: _openFavorites,
                    onRecent: _openRecentSuccess,
                    onProfile: () => _showMessage('个人口味档案正在整理中'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EditorialBrandHeader extends StatelessWidget {
  const _EditorialBrandHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppPalette.char,
            shape: BoxShape.circle,
          ),
          child: Icon(
            Icons.restaurant_rounded,
            size: 20,
            color: AppPalette.rice,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '吃什么',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppPalette.ink,
                  fontFamily: 'PingFang SC',
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                ),
              ),
              Text(
                'EAT WHAT · DAILY',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: AppPalette.inkMuted,
                  fontFamily: 'PingFang SC',
                  fontSize: 7.5,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.4,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
          decoration: BoxDecoration(
            color: AppPalette.cream,
            borderRadius: AppRadii.capsule,
            border: AppSurfaces.glassBorder,
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.location_on_outlined,
                size: 13,
                color: AppPalette.inkSoft,
              ),
              SizedBox(width: 4),
              Text('附近 · 晚餐', style: AppType.label),
            ],
          ),
        ),
      ],
    );
  }
}

class _EditorialTasteChip extends StatelessWidget {
  const _EditorialTasteChip({
    required this.card,
    required this.reaction,
    required this.onTap,
    required this.onLongPress,
  });

  final TasteDeckCard card;
  final TasteCardReaction? reaction;
  final VoidCallback onTap;
  final VoidCallback onLongPress;

  @override
  Widget build(BuildContext context) {
    final isLiked = reaction == TasteCardReaction.liked;
    final isDisliked = reaction == TasteCardReaction.disliked;
    final background = isLiked ? AppPalette.char : AppPalette.cream;
    final foreground = isLiked
        ? AppPalette.rice
        : isDisliked
            ? AppPalette.chili
            : AppPalette.inkSoft;
    final border = isDisliked ? AppPalette.chili : const Color(0xFFE3D6CA);

    return Semantics(
      button: true,
      selected: isLiked || isDisliked,
      label: '${card.label}，点击喜欢，长按排除',
      child: Material(
        color: background,
        borderRadius: AppRadii.capsule,
        child: InkWell(
          key: ValueKey('editorial-taste-chip-${card.id}'),
          borderRadius: AppRadii.capsule,
          onTap: onTap,
          onLongPress: onLongPress,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              borderRadius: AppRadii.capsule,
              border: Border.all(color: border),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (isDisliked) ...[
                  const Icon(Icons.block_rounded, size: 13),
                  const SizedBox(width: 4),
                ],
                Text(
                  card.label,
                  style: AppType.label.copyWith(
                    color: foreground,
                    fontWeight: FontWeight.w700,
                    decoration: isDisliked ? TextDecoration.lineThrough : null,
                    decorationColor: AppPalette.chili,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _EditorialHeroCard extends StatelessWidget {
  const _EditorialHeroCard({required this.reason});

  final String reason;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      key: const ValueKey('editorial-hero-card'),
      borderRadius: BorderRadius.circular(26),
      child: SizedBox(
        height: 238,
        width: double.infinity,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/images/prebuilt_dishes/dish-1-dish_768.jpg',
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const ColoredBox(
                color: Color(0xFFE5D5C8),
                child: Icon(
                  Icons.restaurant_menu_rounded,
                  size: 48,
                  color: AppPalette.chili,
                ),
              ),
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0x00000000), Color(0xD9241712)],
                  stops: [0.42, 1],
                ),
              ),
            ),
            Positioned(
              left: 15,
              top: 15,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppPalette.cream,
                  borderRadius: AppRadii.capsule,
                ),
                child: const Text(
                  '今晚候选 01',
                  style: TextStyle(
                    color: AppPalette.chiliDeep,
                    fontFamily: 'PingFang SC',
                    fontSize: 9,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.7,
                  ),
                ),
              ),
            ),
            Positioned(
              left: 18,
              right: 18,
              bottom: 16,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '麻婆豆腐',
                          style: TextStyle(
                            color: AppPalette.rice,
                            fontFamily: 'Songti SC',
                            fontFamilyFallback: ['STSong', 'serif'],
                            fontSize: 28,
                            fontWeight: FontWeight.w700,
                            height: 1.08,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          reason,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppType.label.copyWith(
                            color: const Color(0xFFF0DED3),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppPalette.rice.withValues(alpha: 0.14),
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppPalette.rice.withValues(alpha: 0.5),
                      ),
                    ),
                    child: Icon(
                      Icons.bookmark_border_rounded,
                      color: AppPalette.rice,
                      size: 20,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EditorialConstraintChip extends StatelessWidget {
  const _EditorialConstraintChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected ? const Color(0xFFF0D8CF) : AppPalette.cream,
      borderRadius: AppRadii.capsule,
      child: InkWell(
        key: ValueKey('editorial-constraint-chip-$label'),
        onTap: onTap,
        borderRadius: AppRadii.capsule,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            borderRadius: AppRadii.capsule,
            border: Border.all(
              color: isSelected ? AppPalette.chili : const Color(0xFFE3D6CA),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (isSelected) ...[
                const Icon(
                  Icons.check_rounded,
                  size: 13,
                  color: AppPalette.chili,
                ),
                const SizedBox(width: 4),
              ],
              Text(
                label,
                style: AppType.label.copyWith(
                  color: isSelected ? AppPalette.chiliDeep : AppPalette.inkSoft,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EditorialRequirementPanel extends StatelessWidget {
  const _EditorialRequirementPanel({
    required this.controller,
    required this.focusNode,
    required this.isListening,
    required this.isOpeningDecision,
    required this.onVoiceTap,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final bool isListening;
  final bool isOpeningDecision;
  final VoidCallback onVoiceTap;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: Container(
              decoration: BoxDecoration(
                color: AppPalette.cream,
                borderRadius: BorderRadius.circular(18),
                border: AppSurfaces.glassBorder,
              ),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      key: const ValueKey('editorial-requirement-input'),
                      controller: controller,
                      focusNode: focusNode,
                      minLines: 1,
                      maxLines: 3,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => onSubmit(),
                      style: AppType.body.copyWith(
                        color: AppPalette.ink,
                        fontWeight: FontWeight.w500,
                      ),
                      decoration: const InputDecoration(
                        hintText: '30 元内，一个人，想吃热的',
                        border: InputBorder.none,
                        enabledBorder: InputBorder.none,
                        focusedBorder: InputBorder.none,
                        filled: false,
                      ),
                    ),
                  ),
                  IconButton(
                    key: const ValueKey('editorial-voice-button'),
                    tooltip: isListening ? '停止语音输入' : '语音输入',
                    onPressed: onVoiceTap,
                    icon: Icon(
                      isListening ? Icons.stop_rounded : Icons.mic_none_rounded,
                    ),
                    color: isListening ? AppPalette.chili : AppPalette.inkMuted,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 94,
            child: FilledButton(
              key: const ValueKey('editorial-generate-button'),
              onPressed: isOpeningDecision ? null : onSubmit,
              style: FilledButton.styleFrom(
                backgroundColor: AppPalette.chili,
                foregroundColor: AppPalette.rice,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
              ),
              child: isOpeningDecision
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: AppPalette.rice,
                      ),
                    )
                  : const Text(
                      '帮我决定',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontFamily: 'PingFang SC',
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EditorialBottomNav extends StatelessWidget {
  const _EditorialBottomNav({
    required this.onFavorites,
    required this.onRecent,
    required this.onProfile,
  });

  final VoidCallback onFavorites;
  final VoidCallback onRecent;
  final VoidCallback onProfile;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        const _EditorialNavItem(
          icon: Icons.home_rounded,
          label: '今天',
          active: true,
        ),
        _EditorialNavItem(
          key: const ValueKey('editorial-favorites-button'),
          icon: Icons.favorite_border_rounded,
          label: '收藏',
          onTap: onFavorites,
        ),
        _EditorialNavItem(
          key: const ValueKey('editorial-recent-button'),
          icon: Icons.history_rounded,
          label: '吃过',
          onTap: onRecent,
        ),
        _EditorialNavItem(
          key: const ValueKey('editorial-profile-button'),
          icon: Icons.person_outline_rounded,
          label: '我的',
          onTap: onProfile,
        ),
      ],
    );
  }
}

class _EditorialNavItem extends StatelessWidget {
  const _EditorialNavItem({
    super.key,
    required this.icon,
    required this.label,
    this.active = false,
    this.onTap,
  });

  final IconData icon;
  final String label;
  final bool active;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final color = active ? AppPalette.chili : AppPalette.inkMuted;
    return InkResponse(
      onTap: onTap,
      radius: 30,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 19, color: color),
            const SizedBox(height: 2),
            Text(
              label,
              style: AppType.label.copyWith(
                color: color,
                fontSize: 9,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

const _fallbackCards = <TasteDeckCard>[
  TasteDeckCard(
    id: 'f_spicy',
    label: '热辣',
    category: 'flavor',
    accentHexes: ['0xFFC94B2C'],
    iconName: 'local_fire_department',
  ),
  TasteDeckCard(
    id: 'f_savory',
    label: '浓香',
    category: 'flavor',
    accentHexes: ['0xFF8B695F'],
    iconName: 'restaurant',
  ),
  TasteDeckCard(
    id: 'style_light',
    label: '清淡',
    category: 'flavor',
    accentHexes: ['0xFF8DA38B'],
    iconName: 'eco',
  ),
  TasteDeckCard(
    id: 'texture_crispy',
    label: '酥脆',
    category: 'texture',
    accentHexes: ['0xFFE6A44A'],
    iconName: 'restaurant_menu',
  ),
  TasteDeckCard(
    id: 'scene_soup',
    label: '汤汤水水',
    category: 'scene',
    accentHexes: ['0xFF59745D'],
    iconName: 'soup_kitchen',
  ),
  TasteDeckCard(
    id: 'ingredient_meat',
    label: '有肉',
    category: 'ingredient',
    accentHexes: ['0xFF8B695F'],
    iconName: 'restaurant',
  ),
];
