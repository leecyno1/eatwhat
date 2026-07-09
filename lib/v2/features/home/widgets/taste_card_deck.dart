import 'dart:async';
import 'dart:math' as math;

import 'package:eatwhat_app/v2/core/data/models/taste_selection_models.dart';
import 'package:eatwhat_app/v2/core/theme/app_colors.dart';
import 'package:eatwhat_app/v2/features/home/widgets/taste_card_board_shell.dart';
import 'package:eatwhat_app/v2/features/home/widgets/taste_card_deck_motion_layers.dart';
import 'package:eatwhat_app/v2/features/home/widgets/taste_grid_card_face.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class TasteCardDeck extends StatefulWidget {
  const TasteCardDeck({
    super.key,
    required this.cards,
    required this.session,
    required this.onReact,
    this.onReactionPreview,
    required this.onAdvancePage,
    this.onPageAdvanceDirection,
    this.onPagePreviewDirection,
    required this.onVoiceStart,
    required this.onVoiceEnd,
    required this.isListening,
    required this.showFlipHint,
    required this.onFirstFlip,
  });

  final List<TasteDeckCard> cards;
  final TasteDeckSessionState session;
  final void Function(TasteDeckCard card, TasteCardReaction reaction) onReact;
  final ValueChanged<TasteCardReaction?>? onReactionPreview;
  final VoidCallback onAdvancePage;
  final ValueChanged<int>? onPageAdvanceDirection;
  final ValueChanged<int>? onPagePreviewDirection;
  final VoidCallback onVoiceStart;
  final VoidCallback onVoiceEnd;
  final bool isListening;
  final bool showFlipHint;
  final VoidCallback onFirstFlip;

  @override
  State<TasteCardDeck> createState() => _TasteCardDeckState();
}

class _TasteCardDeckState extends State<TasteCardDeck>
    with TickerProviderStateMixin {
  static const double _pageTriggerDistance = 96;
  static const double _pageSnapCommitDistance = 82;
  static const double _pageDragSoftZoneStart = 34;
  static const double _pageDragSoftZoneEnd = 118;
  static const double _pageCommitDistance = 34;
  static const Duration _pageCommitDuration = Duration(milliseconds: 140);
  static const Duration _dealDuration = Duration(milliseconds: 520);
  double _horizontalDrag = 0;
  double _horizontalRawDrag = 0;
  bool _isPageCommitting = false;
  int _pageCommitDirection = 0;
  int _lastPageCommitDirection = -1;
  int _pagePreviewDirection = 0;
  Timer? _pageCommitTimer;
  late final AnimationController _dealController;
  late final AnimationController _pageBlendController;
  List<TasteDeckCard> _outgoingCards = const [];

  @override
  void initState() {
    super.initState();
    _dealController = AnimationController(
      vsync: this,
      duration: _dealDuration,
    )..forward();
    _pageBlendController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    )..addStatusListener((status) {
        if (status == AnimationStatus.completed && mounted) {
          setState(() {
            _outgoingCards = const [];
          });
        }
      });
  }

  @override
  void didUpdateWidget(covariant TasteCardDeck oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.session.currentPageNumber !=
        widget.session.currentPageNumber) {
      _outgoingCards = List<TasteDeckCard>.unmodifiable(oldWidget.cards);
      _pageBlendController
        ..stop()
        ..value = 0
        ..forward();
      _dealController
        ..stop()
        ..value = 0
        ..forward();
    }
  }

  @override
  void dispose() {
    _pageCommitTimer?.cancel();
    _dealController.dispose();
    _pageBlendController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final displayedHorizontalOffset = _isPageCommitting
        ? _pageCommitDirection * _pageCommitDistance.toDouble()
        : _horizontalDrag.clamp(-18, 18).toDouble();
    final pageChangeProgress =
        ((_horizontalDrag.abs() > _horizontalRawDrag.abs()
                    ? _horizontalDrag.abs()
                    : _horizontalRawDrag.abs()) /
                100)
            .clamp(0.0, 1.0);
    return GestureDetector(
      key: const ValueKey('taste-grid-board'),
      behavior: HitTestBehavior.opaque,
      onHorizontalDragUpdate: _isPageCommitting
          ? null
          : (details) {
              setState(() {
                _horizontalRawDrag += details.delta.dx;
                _horizontalDrag =
                    _applyPageDampedDrag(_horizontalDrag, details.delta.dx);
                final previewDirection = _resolvePagePreviewDirection(
                    _horizontalRawDrag, _horizontalDrag);
                if (previewDirection != _pagePreviewDirection) {
                  _pagePreviewDirection = previewDirection;
                  widget.onPagePreviewDirection?.call(previewDirection);
                }
              });
            },
      onHorizontalDragEnd: _isPageCommitting
          ? null
          : (details) {
              final flingVelocity = details.primaryVelocity ?? 0;
              final shouldCommit = _shouldCommitPage(_horizontalRawDrag) ||
                  flingVelocity.abs() >= 620;
              if (shouldCommit) {
                HapticFeedback.mediumImpact();
                _pageCommitTimer?.cancel();
                setState(() {
                  _isPageCommitting = true;
                  final dragSource = _horizontalRawDrag == 0
                      ? (flingVelocity == 0 ? _horizontalDrag : flingVelocity)
                      : _horizontalRawDrag;
                  _pageCommitDirection = dragSource > 0 ? 1 : -1;
                  _lastPageCommitDirection = _pageCommitDirection;
                  _pagePreviewDirection = 0;
                });
                widget.onPagePreviewDirection?.call(0);
                widget.onPageAdvanceDirection?.call(_pageCommitDirection);
                _pageCommitTimer = Timer(_pageCommitDuration, () {
                  if (!mounted) return;
                  widget.onAdvancePage();
                  setState(() {
                    _horizontalDrag = 0;
                    _horizontalRawDrag = 0;
                    _isPageCommitting = false;
                    _pageCommitDirection = 0;
                  });
                });
                return;
              }
              setState(() {
                _horizontalDrag = 0;
                _horizontalRawDrag = 0;
                _pagePreviewDirection = 0;
              });
              widget.onPagePreviewDirection?.call(0);
            },
      onLongPressStart: (_) => widget.onVoiceStart(),
      onLongPressEnd: (_) => widget.onVoiceEnd(),
      child: Stack(
        children: [
          LayoutBuilder(
            builder: (context, constraints) {
              return AnimatedContainer(
                duration: _isPageCommitting
                    ? _pageCommitDuration
                    : const Duration(milliseconds: 70),
                curve: _isPageCommitting ? Curves.easeOutCubic : Curves.linear,
                // Keep a tiny host transform so implicit animation frames continue
                // during commit, allowing timer-driven page advance to settle in tests.
                transform: Matrix4.translationValues(
                  displayedHorizontalOffset * 0.001,
                  0,
                  0,
                ),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: AnimatedBuilder(
                        animation: _pageBlendController,
                        builder: (context, _) {
                          final blendProgress = _outgoingCards.isEmpty
                              ? 0.0
                              : Curves.easeOutCubic
                                  .transform(_pageBlendController.value);
                          return Transform.translate(
                            offset: Offset(displayedHorizontalOffset * 0.34, 0),
                            child: TasteCardBoardShell(
                              pageCount: widget.session.totalPageCount,
                              currentPage: widget.session.currentPageNumber,
                              progress:
                                  (_horizontalDrag.abs() / _pageTriggerDistance)
                                      .clamp(0, 1),
                              blendProgress: blendProgress,
                              slotRectFor: (index) =>
                                  _slotRectFor(index, constraints.biggest),
                            ),
                          );
                        },
                      ),
                    ),
                    if (_outgoingCards.isNotEmpty)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: AnimatedBuilder(
                            animation: _pageBlendController,
                            builder: (context, _) {
                              final progress = Curves.easeOutCubic
                                  .transform(_pageBlendController.value);
                              final direction = _lastPageCommitDirection == 0
                                  ? -1
                                  : _lastPageCommitDirection;
                              return Opacity(
                                opacity: (1 - progress) * 0.78,
                                child: Stack(
                                  children: List.generate(
                                      TasteDeckSessionState.pageSize, (index) {
                                    final rect = _slotRectFor(
                                        index, constraints.biggest);
                                    final card = index < _outgoingCards.length
                                        ? _outgoingCards[index]
                                        : null;
                                    if (card == null) {
                                      return const SizedBox.shrink();
                                    }
                                    final row = index ~/ 4;
                                    final rowSpeed = switch (row) {
                                      0 => 1.12,
                                      1 => 1.0,
                                      _ => 0.9,
                                    };
                                    final driftX = direction *
                                        (6 + progress * 22) *
                                        rowSpeed;
                                    final driftY = progress * (2 + row);
                                    final shrink = 1 - progress * 0.03;
                                    return Positioned(
                                      left: rect.left,
                                      top: rect.top,
                                      width: rect.width,
                                      height: rect.height,
                                      child: Transform(
                                        alignment: Alignment.center,
                                        transform: Matrix4.identity()
                                          ..translate(driftX, driftY)
                                          ..scale(shrink),
                                        child: TasteOutgoingPageGhostCard(
                                          card: card,
                                        ),
                                      ),
                                    );
                                  }),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                    if (_horizontalDrag.abs() >= 16 || _isPageCommitting)
                      Positioned.fill(
                        child: IgnorePointer(
                          child: DecoratedBox(
                            decoration: BoxDecoration(
                              gradient: LinearGradient(
                                begin: displayedHorizontalOffset >= 0
                                    ? Alignment.centerLeft
                                    : Alignment.centerRight,
                                end: displayedHorizontalOffset >= 0
                                    ? Alignment.centerRight
                                    : Alignment.centerLeft,
                                colors: [
                                  Colors.white.withValues(alpha: 0.12),
                                  Colors.white.withValues(alpha: 0),
                                ],
                                stops: const [0, 0.42],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ...List.generate(TasteDeckSessionState.pageSize, (index) {
                      final rect = _slotRectFor(index, constraints.biggest);
                      final rowIndex = index ~/ 4;
                      final card = index < widget.cards.length
                          ? widget.cards[index]
                          : null;
                      final rowSpeedFactor = switch (rowIndex) {
                        0 => 1.08,
                        1 => 1.0,
                        _ => 0.92,
                      };

                      return Positioned(
                        key: ValueKey('taste-grid-slot-$index'),
                        left: rect.left,
                        top: rect.top,
                        width: rect.width,
                        height: rect.height,
                        child: Transform.translate(
                          offset: Offset(
                            displayedHorizontalOffset * rowSpeedFactor,
                            0,
                          ),
                          child: Padding(
                            key: index % 4 == 0
                                ? ValueKey('taste-grid-row-$rowIndex')
                                : null,
                            padding: EdgeInsets.zero,
                            child: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 240),
                              switchInCurve: Curves.easeOutCubic,
                              switchOutCurve: Curves.easeInCubic,
                              layoutBuilder: (currentChild, previousChildren) {
                                return Stack(
                                  fit: StackFit.expand,
                                  children: [
                                    ...previousChildren,
                                    if (currentChild != null) currentChild,
                                  ],
                                );
                              },
                              transitionBuilder: (child, animation) {
                                final slide = Tween<Offset>(
                                  begin: const Offset(0, -0.22),
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
                              child: card == null
                                  ? const SizedBox.shrink()
                                  : TasteDealEntryCard(
                                      key: ValueKey(
                                          'taste-card-deal-entry-$index-${card.id}'),
                                      index: index,
                                      animation: _dealController,
                                      child: _TasteGridCard(
                                        key: ValueKey(
                                            'taste-grid-card-${card.id}'),
                                        card: card,
                                        reaction: widget.session
                                            .pageReactionFor(card.id),
                                        onReact: (reaction) =>
                                            widget.onReact(card, reaction),
                                        onPreviewReaction:
                                            widget.onReactionPreview,
                                        onFirstFlip: widget.onFirstFlip,
                                      ),
                                    ),
                            ),
                          ),
                        ),
                      );
                    }),
                  ],
                ),
              );
            },
          ),
          if (_horizontalDrag.abs() >= 20 ||
              _horizontalRawDrag.abs() >= 20 ||
              _isPageCommitting)
            Positioned.fill(
              child: IgnorePointer(
                child: Center(
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      TastePageDealFan(
                        key: const ValueKey('taste-page-deal-fan'),
                        progress: _isPageCommitting ? 1 : pageChangeProgress,
                        direction: (_isPageCommitting
                                ? _pageCommitDirection > 0
                                : (_horizontalRawDrag == 0
                                    ? _horizontalDrag > 0
                                    : _horizontalRawDrag > 0))
                            ? 1
                            : -1,
                      ),
                      AnimatedOpacity(
                        duration: const Duration(milliseconds: 120),
                        opacity: _isPageCommitting ? 1 : pageChangeProgress,
                        child: Container(
                          key: _isPageCommitting
                              ? const ValueKey('taste-page-commit-indicator')
                              : null,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.78),
                            borderRadius: BorderRadius.circular(999),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                (_isPageCommitting
                                        ? _pageCommitDirection > 0
                                        : _horizontalDrag > 0)
                                    ? Icons.arrow_back_rounded
                                    : Icons.arrow_forward_rounded,
                                size: 16,
                                color: AppColors.textPrimary,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                _isPageCommitting ? '已锁定换一版' : '换一版口味',
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          if (widget.showFlipHint)
            const Positioned(
              left: 24,
              right: 24,
              top: 12,
              child: IgnorePointer(
                child: TasteFlipHintPill(
                  key: ValueKey('taste-flip-hint-pill'),
                ),
              ),
            ),
          if (widget.isListening)
            Positioned(
              right: 12,
              top: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF46B40).withValues(alpha: 0.92),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.mic_rounded,
                      color: Colors.white,
                      size: 14,
                    ),
                    SizedBox(width: 6),
                    Text(
                      '语音采集中',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          if (widget.isListening)
            Positioned(
              left: 12,
              right: 12,
              bottom: 12,
              child: IgnorePointer(
                child: Align(
                  alignment: Alignment.bottomCenter,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.56),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.58),
                      ),
                    ),
                    child: Text(
                      '松手后写回文本要求',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: AppColors.textPrimary.withValues(alpha: 0.72),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Rect _slotRectFor(int index, Size size) {
    const columnCount = 4;
    const rowCount = 4;
    const columnGap = 5.0;
    const rowGap = 5.0;
    final rowIndex = index ~/ columnCount;
    final columnIndex = index % columnCount;
    final rowPadding = _rowPaddingFor(rowIndex);
    final rowHeight = (size.height - rowGap * (rowCount - 1)) / rowCount;
    final rowTop = rowIndex * (rowHeight + rowGap);
    final usableWidth = size.width - rowPadding.left - rowPadding.right;
    final cellWidth =
        (usableWidth - columnGap * (columnCount - 1)) / columnCount;
    final left = rowPadding.left + columnIndex * (cellWidth + columnGap);

    return Rect.fromLTWH(left, rowTop, cellWidth, rowHeight);
  }

  EdgeInsets _rowPaddingFor(int rowIndex) {
    switch (rowIndex) {
      case 0:
        return const EdgeInsets.only(left: 4, right: 1);
      case 1:
        return const EdgeInsets.only(left: 1, right: 3);
      case 2:
        return const EdgeInsets.only(left: 3, right: 1);
      case 3:
        return const EdgeInsets.only(left: 1, right: 4);
      default:
        return EdgeInsets.zero;
    }
  }

  bool _shouldCommitPage(double dragValue) {
    if (dragValue.abs() >= _pageTriggerDistance) {
      return true;
    }
    return dragValue.abs() >= _pageSnapCommitDistance;
  }

  double _applyPageDampedDrag(double current, double delta) {
    if (delta == 0) return current;
    final travel = current.abs();
    final magnitude = delta.abs();
    final direction = delta.sign;

    double resistance;
    if (travel <= _pageDragSoftZoneStart) {
      resistance = 1;
    } else if (travel < _pageDragSoftZoneEnd) {
      final t = ((travel - _pageDragSoftZoneStart) /
              (_pageDragSoftZoneEnd - _pageDragSoftZoneStart))
          .clamp(0, 1)
          .toDouble();
      resistance = 1 - t * 0.52;
    } else {
      final overshoot =
          (travel - _pageDragSoftZoneEnd).clamp(0, 120).toDouble();
      resistance = (0.48 - overshoot / 260).clamp(0.24, 0.48).toDouble();
    }

    final applied = magnitude * resistance;
    return current + direction * applied;
  }

  int _resolvePagePreviewDirection(double rawDrag, double dampedDrag) {
    final source = rawDrag == 0 ? dampedDrag : rawDrag;
    if (source.abs() < _pageSnapCommitDistance) {
      return 0;
    }
    return source.sign.toInt();
  }
}

class _TasteGridCard extends StatefulWidget {
  const _TasteGridCard({
    super.key,
    required this.card,
    required this.reaction,
    required this.onReact,
    this.onPreviewReaction,
    required this.onFirstFlip,
  });

  final TasteDeckCard card;
  final TasteCardReaction? reaction;
  final ValueChanged<TasteCardReaction> onReact;
  final ValueChanged<TasteCardReaction?>? onPreviewReaction;
  final VoidCallback onFirstFlip;

  @override
  State<_TasteGridCard> createState() => _TasteGridCardState();
}

class _TasteGridCardState extends State<_TasteGridCard>
    with SingleTickerProviderStateMixin {
  static const double _triggerDistance = 70;
  static const double _previewDistance = 36;
  static const double _snapCommitDistance = 58;
  static const double _dragSoftZoneStart = 26;
  static const double _dragSoftZoneEnd = 82;
  static const double _commitDistance = 168;
  static const Duration _commitDuration = Duration(milliseconds: 220);
  static const Duration _commitApplyDelay = Duration(milliseconds: 180);
  double _verticalDrag = 0;
  TasteCardReaction? _previewReaction;
  TasteCardReaction? _committingReaction;
  bool _isFlipped = false;
  bool _hasReportedFlip = false;
  Timer? _commitTimer;
  late final AnimationController _idleController;

  @override
  void initState() {
    super.initState();
    _idleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );
    if (!kDebugMode ||
        WidgetsBinding.instance.runtimeType.toString() !=
            'AutomatedTestWidgetsFlutterBinding') {
      _idleController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _commitTimer?.cancel();
    _idleController.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(covariant _TasteGridCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.card.id != widget.card.id) {
      _commitTimer?.cancel();
      _verticalDrag = 0;
      _previewReaction = null;
      widget.onPreviewReaction?.call(null);
      _committingReaction = null;
      _isFlipped = false;
      _hasReportedFlip = false;
    }
    if (oldWidget.reaction != widget.reaction && widget.reaction != null) {
      _isFlipped = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    final reaction = widget.reaction;
    final isCommitting = _committingReaction != null;
    final displayedReaction =
        reaction ?? _committingReaction ?? _previewReaction;
    final double displayOffset = isCommitting
        ? (_committingReaction == TasteCardReaction.liked
            ? -_commitDistance
            : _commitDistance)
        : _verticalDrag.clamp(-20, 20).toDouble();
    final double displayTilt = isCommitting
        ? (_committingReaction == TasteCardReaction.liked ? -0.08 : 0.08)
        : (_verticalDrag / 900).clamp(-0.035, 0.035).toDouble();
    final double liftProgress =
        (_verticalDrag.abs() / _triggerDistance).clamp(0, 1).toDouble();
    final double displayScale =
        isCommitting ? 0.98 : 1.0 + liftProgress * 0.035;
    final double displayOpacity = isCommitting ? 0 : 1;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: isCommitting
          ? null
          : () {
              HapticFeedback.lightImpact();
              setState(() {
                _isFlipped = !_isFlipped;
              });
              if (_isFlipped && !_hasReportedFlip) {
                _hasReportedFlip = true;
                widget.onFirstFlip();
              }
            },
      onVerticalDragUpdate: reaction != null || isCommitting
          ? null
          : (details) {
              final nextDrag =
                  _applyDampedDrag(_verticalDrag, details.delta.dy);
              final nextPreviewReaction = _resolvePreviewReaction(nextDrag);
              if (nextPreviewReaction != null &&
                  nextPreviewReaction != _previewReaction) {
                HapticFeedback.selectionClick();
              }
              if (nextPreviewReaction != _previewReaction) {
                widget.onPreviewReaction?.call(nextPreviewReaction);
              }
              setState(() {
                _verticalDrag = nextDrag;
                _previewReaction = nextPreviewReaction;
              });
            },
      onVerticalDragEnd: reaction != null || isCommitting
          ? null
          : (_) {
              final nextReaction = _resolveReaction();
              if (nextReaction != null) {
                HapticFeedback.mediumImpact();
                _commitTimer?.cancel();
                setState(() {
                  _committingReaction = nextReaction;
                  _previewReaction = nextReaction;
                });
                widget.onPreviewReaction?.call(null);
                _commitTimer = Timer(_commitApplyDelay, () {
                  if (!mounted) return;
                  widget.onReact(nextReaction);
                  setState(() {
                    _verticalDrag = 0;
                    _previewReaction = null;
                    _committingReaction = null;
                  });
                });
                return;
              }
              setState(() {
                _verticalDrag = 0;
                _previewReaction = null;
              });
              widget.onPreviewReaction?.call(null);
            },
      child: AnimatedBuilder(
        animation: _idleController,
        builder: (context, _) {
          final idle = math.sin(_idleController.value * math.pi * 2);
          final idleLift = reaction == null && !isCommitting ? idle * 1.2 : 0.0;
          final idleTilt =
              reaction == null && !isCommitting ? idle * 0.004 : 0.0;

          return AnimatedOpacity(
            duration: isCommitting
                ? _commitDuration
                : const Duration(milliseconds: 90),
            curve: isCommitting ? Curves.easeOutQuart : Curves.easeOut,
            opacity: displayOpacity,
            child: AnimatedContainer(
              duration: isCommitting
                  ? _commitDuration
                  : const Duration(milliseconds: 70),
              curve: isCommitting ? Curves.easeOutQuart : Curves.linear,
              transform: Matrix4.identity()
                ..translate(0.0, displayOffset + idleLift)
                ..rotateZ(displayTilt + idleTilt)
                ..scale(displayScale),
              transformAlignment: Alignment.center,
              child: TasteGridCardFace(
                card: widget.card,
                reaction: reaction,
                dragReaction: reaction == null ? displayedReaction : null,
                dragProgress:
                    (_verticalDrag.abs() / _triggerDistance).clamp(0, 1),
                isCommitting: isCommitting,
                isFlipped: _isFlipped,
              ),
            ),
          );
        },
      ),
    );
  }

  TasteCardReaction? _resolvePreviewReaction(double dragValue) {
    if (dragValue <= -_previewDistance) {
      return TasteCardReaction.liked;
    }
    if (dragValue >= _previewDistance) {
      return TasteCardReaction.disliked;
    }
    return null;
  }

  TasteCardReaction? _resolveReaction() {
    if (_verticalDrag <= -_triggerDistance) {
      return TasteCardReaction.liked;
    }
    if (_verticalDrag >= _triggerDistance) {
      return TasteCardReaction.disliked;
    }
    if (_previewReaction != null &&
        _verticalDrag.abs() >= _snapCommitDistance) {
      return _verticalDrag < 0
          ? TasteCardReaction.liked
          : TasteCardReaction.disliked;
    }
    return null;
  }

  double _applyDampedDrag(double current, double delta) {
    if (delta == 0) return current;
    final travel = current.abs();
    final magnitude = delta.abs();
    final direction = delta.sign;

    double resistance;
    if (travel <= _dragSoftZoneStart) {
      resistance = 1;
    } else if (travel < _dragSoftZoneEnd) {
      final t = ((travel - _dragSoftZoneStart) /
              (_dragSoftZoneEnd - _dragSoftZoneStart))
          .clamp(0, 1)
          .toDouble();
      resistance = 1 - t * 0.55;
    } else {
      final overshoot = (travel - _dragSoftZoneEnd).clamp(0, 80).toDouble();
      resistance = (0.45 - overshoot / 200).clamp(0.2, 0.45).toDouble();
    }

    final applied = magnitude * resistance;
    return current + direction * applied;
  }
}
