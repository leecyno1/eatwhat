import 'dart:async';
import 'dart:math' as math;

import 'package:eatwhat_app/v2/core/data/models/taste_selection_models.dart';
import 'package:eatwhat_app/v2/core/theme/app_colors.dart';
import 'package:eatwhat_app/v2/core/theme/app_tokens.dart';
import 'package:eatwhat_app/v2/features/home/widgets/taste_card_board_shell.dart';
import 'package:eatwhat_app/v2/features/home/widgets/taste_minimal_card_face.dart';
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
    this.onFirstFlip,
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
  final VoidCallback? onFirstFlip;

  @override
  State<TasteCardDeck> createState() => _TasteCardDeckState();
}

class _TasteCardDeckState extends State<TasteCardDeck> {
  static const double _pageTriggerDistance = 96;
  static const double _pageSnapCommitDistance = 82;
  static const double _pageDragSoftZoneStart = 34;
  static const double _pageDragSoftZoneEnd = 118;
  static const double _pageCommitDistance = 28;
  static const Duration _pageCommitDuration = Duration(milliseconds: 140);
  static const double _focusedPreviewDistance = 42;
  static const double _focusedTriggerDistance = 88;
  static const double _focusedCommitOffset = 280;
  static const Duration _focusedCommitDuration = Duration(milliseconds: 220);
  static const Duration _focusedCommitApplyDelay = Duration(milliseconds: 180);
  double _horizontalDrag = 0;
  double _horizontalRawDrag = 0;
  bool _isPageCommitting = false;
  int _pageCommitDirection = 0;
  int _pagePreviewDirection = 0;
  Timer? _pageCommitTimer;
  TasteDeckCard? _focusedCard;
  double _focusedVerticalDrag = 0;
  TasteCardReaction? _focusedPreviewReaction;
  TasteCardReaction? _focusedCommittingReaction;
  Timer? _focusedCommitTimer;

  @override
  void didUpdateWidget(covariant TasteCardDeck oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.session.currentPageNumber !=
        widget.session.currentPageNumber) {
      _focusedCommitTimer?.cancel();
      _focusedCard = null;
      _focusedVerticalDrag = 0;
      _focusedPreviewReaction = null;
      _focusedCommittingReaction = null;
    }
  }

  @override
  void dispose() {
    _pageCommitTimer?.cancel();
    _focusedCommitTimer?.cancel();
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
      onVerticalDragUpdate: _isPageCommitting
          ? null
          : (details) {
              setState(() {
                _horizontalRawDrag += details.delta.dy;
                _horizontalDrag =
                    _applyPageDampedDrag(_horizontalDrag, details.delta.dy);
                final previewDirection = _resolvePagePreviewDirection(
                    _horizontalRawDrag, _horizontalDrag);
                if (previewDirection != _pagePreviewDirection) {
                  _pagePreviewDirection = previewDirection;
                  widget.onPagePreviewDirection?.call(previewDirection);
                }
              });
            },
      onVerticalDragEnd: _isPageCommitting
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
                  0,
                  displayedHorizontalOffset * 0.001,
                  0,
                ),
                child: Stack(
                  children: [
                    Positioned.fill(
                      child: Transform.translate(
                        offset: Offset(0, displayedHorizontalOffset * 0.34),
                        child: TasteCardBoardShell(
                          slotCount: TasteDeckSessionState.pageSize,
                          slotRectFor: (index) =>
                              _slotRectFor(index, constraints.biggest),
                        ),
                      ),
                    ),
                    ...List.generate(TasteDeckSessionState.pageSize, (index) {
                      final rect = _slotRectFor(index, constraints.biggest);
                      final card = index < widget.cards.length
                          ? widget.cards[index]
                          : null;
                      final rowIndex = index ~/ 2;

                      return Positioned(
                        key: ValueKey('taste-grid-slot-$index'),
                        left: rect.left,
                        top: rect.top,
                        width: rect.width,
                        height: rect.height,
                        child: Transform.translate(
                          offset: Offset(0, displayedHorizontalOffset),
                          child: Padding(
                            key: index % 2 == 0
                                ? ValueKey('taste-grid-row-$rowIndex')
                                : null,
                            padding: EdgeInsets.zero,
                            child: AnimatedSwitcher(
                              duration: AppMotion.standard,
                              switchInCurve: AppMotion.enter,
                              switchOutCurve: AppMotion.enter,
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
                                return FadeTransition(
                                  opacity: animation,
                                  child: child,
                                );
                              },
                              child: card == null
                                  ? const SizedBox.shrink()
                                  : _TasteGridCard(
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
                                      onFocus: () => _focusCard(card),
                                      onFocusDragUpdate: (offset) =>
                                          _updateFocusedDragFromLongPress(
                                        card,
                                        offset,
                                      ),
                                      onFocusDragEnd: () =>
                                          _finishFocusedDrag(card),
                                      onFocusDragCancel: () =>
                                          _cancelFocusedDrag(card),
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
                child: Align(
                  alignment: (_isPageCommitting
                          ? _pageCommitDirection > 0
                          : _horizontalDrag > 0)
                      ? Alignment.topCenter
                      : Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.all(18),
                    child: AnimatedOpacity(
                      duration: AppMotion.press,
                      opacity: _isPageCommitting ? 1 : pageChangeProgress,
                      child: Container(
                        key: _isPageCommitting
                            ? const ValueKey('taste-page-commit-indicator')
                            : null,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 14,
                          vertical: 9,
                        ),
                        decoration: AppDecorations.card(
                          radius: AppRadii.sm,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              (_isPageCommitting
                                      ? _pageCommitDirection > 0
                                      : _horizontalDrag > 0)
                                  ? Icons.keyboard_arrow_down_rounded
                                  : Icons.keyboard_arrow_up_rounded,
                              size: 18,
                              color: AppPalette.ink,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              _isPageCommitting ? '正在切换' : '继续滚动',
                              style: AppType.label.copyWith(
                                color: AppPalette.ink,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
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
                  color: const Color(0xFFC94B2C).withValues(alpha: 0.92),
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
          if (_focusedCard case final TasteDeckCard focusedCard)
            Positioned.fill(
              child: _TasteCardFocusOverlay(
                card: focusedCard,
                reaction: widget.session.pageReactionFor(focusedCard.id),
                verticalDrag: _focusedVerticalDrag,
                previewReaction: _focusedPreviewReaction,
                committingReaction: _focusedCommittingReaction,
                triggerDistance: _focusedTriggerDistance,
                commitOffset: _focusedCommitOffset,
                commitDuration: _focusedCommitDuration,
                onVerticalDragUpdate: _updateFocusedDragBy,
                onVerticalDragEnd: () => _finishFocusedDrag(focusedCard),
                onVerticalDragCancel: () => _cancelFocusedDrag(focusedCard),
                onDismiss: _dismissFocusedCard,
              ),
            ),
        ],
      ),
    );
  }

  void _focusCard(TasteDeckCard card) {
    if (_focusedCard?.id == card.id) return;
    _focusedCommitTimer?.cancel();
    setState(() {
      _focusedCard = card;
      _focusedVerticalDrag = 0;
      _focusedPreviewReaction = null;
      _focusedCommittingReaction = null;
      _horizontalDrag = 0;
      _horizontalRawDrag = 0;
      _pagePreviewDirection = 0;
    });
    widget.onPagePreviewDirection?.call(0);
  }

  void _dismissFocusedCard() {
    if (_focusedCard == null) return;
    _focusedCommitTimer?.cancel();
    widget.onReactionPreview?.call(null);
    HapticFeedback.selectionClick();
    setState(() {
      _focusedCard = null;
      _focusedVerticalDrag = 0;
      _focusedPreviewReaction = null;
      _focusedCommittingReaction = null;
    });
  }

  void _updateFocusedDragFromLongPress(
    TasteDeckCard card,
    double offset,
  ) {
    if (_focusedCard?.id != card.id) return;
    _setFocusedDrag(offset);
  }

  void _updateFocusedDragBy(double delta) {
    _setFocusedDrag(_focusedVerticalDrag + delta);
  }

  void _setFocusedDrag(double value) {
    if (_focusedCard == null || _focusedCommittingReaction != null) return;
    final nextReaction = _resolveFocusedPreviewReaction(value);
    if (nextReaction != null && nextReaction != _focusedPreviewReaction) {
      HapticFeedback.selectionClick();
    }
    if (nextReaction != _focusedPreviewReaction) {
      widget.onReactionPreview?.call(nextReaction);
    }
    setState(() {
      _focusedVerticalDrag = value;
      _focusedPreviewReaction = nextReaction;
    });
  }

  void _finishFocusedDrag(TasteDeckCard card) {
    if (_focusedCard?.id != card.id || _focusedCommittingReaction != null) {
      return;
    }
    final reaction = _resolveFocusedReaction(_focusedVerticalDrag);
    if (reaction == null) {
      widget.onReactionPreview?.call(null);
      setState(() {
        _focusedVerticalDrag = 0;
        _focusedPreviewReaction = null;
      });
      return;
    }

    HapticFeedback.mediumImpact();
    widget.onReactionPreview?.call(null);
    _focusedCommitTimer?.cancel();
    setState(() {
      _focusedPreviewReaction = reaction;
      _focusedCommittingReaction = reaction;
    });
    _focusedCommitTimer = Timer(_focusedCommitApplyDelay, () {
      if (!mounted || _focusedCard?.id != card.id) return;
      final submittedCard = _focusedCard!;
      setState(() {
        _focusedCard = null;
        _focusedVerticalDrag = 0;
        _focusedPreviewReaction = null;
        _focusedCommittingReaction = null;
      });
      widget.onReact(submittedCard, reaction);
    });
  }

  void _cancelFocusedDrag(TasteDeckCard card) {
    if (_focusedCard?.id != card.id || _focusedCommittingReaction != null) {
      return;
    }
    widget.onReactionPreview?.call(null);
    setState(() {
      _focusedVerticalDrag = 0;
      _focusedPreviewReaction = null;
    });
  }

  TasteCardReaction? _resolveFocusedPreviewReaction(double dragValue) {
    if (dragValue <= -_focusedPreviewDistance) {
      return TasteCardReaction.liked;
    }
    if (dragValue >= _focusedPreviewDistance) {
      return TasteCardReaction.disliked;
    }
    return null;
  }

  TasteCardReaction? _resolveFocusedReaction(double dragValue) {
    if (dragValue <= -_focusedTriggerDistance) {
      return TasteCardReaction.liked;
    }
    if (dragValue >= _focusedTriggerDistance) {
      return TasteCardReaction.disliked;
    }
    return null;
  }

  Rect _slotRectFor(int index, Size size) {
    const columnCount = 2;
    const rowCount = 4;
    const columnGap = 8.0;
    const rowGap = 8.0;
    final rowIndex = index ~/ columnCount;
    final columnIndex = index % columnCount;
    final rowHeight = (size.height - rowGap * (rowCount - 1)) / rowCount;
    final rowTop = rowIndex * (rowHeight + rowGap);
    final cellWidth =
        (size.width - columnGap * (columnCount - 1)) / columnCount;
    final left = columnIndex * (cellWidth + columnGap);

    return Rect.fromLTWH(left, rowTop, cellWidth, rowHeight);
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

class _TasteCardFocusOverlay extends StatelessWidget {
  const _TasteCardFocusOverlay({
    required this.card,
    required this.reaction,
    required this.verticalDrag,
    required this.previewReaction,
    required this.committingReaction,
    required this.triggerDistance,
    required this.commitOffset,
    required this.commitDuration,
    required this.onVerticalDragUpdate,
    required this.onVerticalDragEnd,
    required this.onVerticalDragCancel,
    required this.onDismiss,
  });

  final TasteDeckCard card;
  final TasteCardReaction? reaction;
  final double verticalDrag;
  final TasteCardReaction? previewReaction;
  final TasteCardReaction? committingReaction;
  final double triggerDistance;
  final double commitOffset;
  final Duration commitDuration;
  final ValueChanged<double> onVerticalDragUpdate;
  final VoidCallback onVerticalDragEnd;
  final VoidCallback onVerticalDragCancel;
  final VoidCallback onDismiss;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      key: const ValueKey('taste-card-focus-overlay'),
      behavior: HitTestBehavior.opaque,
      onTap: onDismiss,
      onLongPress: () {},
      child: DecoratedBox(
        decoration: const BoxDecoration(color: AppSurfaces.scrim),
        child: LayoutBuilder(
          builder: (context, constraints) {
            const horizontalInset = 24.0;
            const verticalInset = 24.0;
            const cardAspectRatio = 0.78;
            final availableWidth = math.max(
              0.0,
              constraints.maxWidth - horizontalInset * 2,
            );
            final availableHeight = math.max(
              0.0,
              constraints.maxHeight - verticalInset * 2,
            );
            final targetWidth = math.min(
              math.min(availableWidth, 420.0),
              availableHeight * cardAspectRatio,
            );
            final targetHeight = math.min(
              availableHeight,
              targetWidth / cardAspectRatio,
            );
            final isCommitting = committingReaction != null;
            final activeReaction = committingReaction ?? previewReaction;
            final dragProgress = (verticalDrag.abs() / triggerDistance)
                .clamp(0.0, 1.0)
                .toDouble();
            final displayOffset = isCommitting
                ? (committingReaction == TasteCardReaction.liked
                    ? -commitOffset
                    : commitOffset)
                : verticalDrag.clamp(-140.0, 140.0) * 0.62;
            final displayTilt = isCommitting
                ? (committingReaction == TasteCardReaction.liked
                    ? -0.055
                    : 0.055)
                : (verticalDrag / 1800).clamp(-0.045, 0.045).toDouble();
            final displayScale = isCommitting ? 0.96 : 1 + dragProgress * 0.025;

            return Center(
              child: AnimatedOpacity(
                duration: isCommitting ? commitDuration : AppMotion.fast,
                curve: AppMotion.enter,
                opacity: isCommitting ? 0 : 1,
                child: AnimatedContainer(
                  duration: isCommitting ? commitDuration : AppMotion.fast,
                  curve: AppMotion.enter,
                  transform: Matrix4.identity()
                    ..translate(0.0, displayOffset)
                    ..rotateZ(displayTilt)
                    ..scale(displayScale),
                  transformAlignment: Alignment.center,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.94, end: 1),
                    duration: AppMotion.standard,
                    curve: AppMotion.enter,
                    builder: (context, value, child) {
                      return Opacity(
                        opacity: value.clamp(0.0, 1.0),
                        child: Transform.scale(
                          scale: value,
                          child: child,
                        ),
                      );
                    },
                    child: Semantics(
                      label: '${card.label}详情',
                      explicitChildNodes: true,
                      child: GestureDetector(
                        behavior: HitTestBehavior.opaque,
                        onTap: () {},
                        onLongPress: () {},
                        onVerticalDragUpdate: isCommitting
                            ? null
                            : (details) =>
                                onVerticalDragUpdate(details.delta.dy),
                        onVerticalDragEnd:
                            isCommitting ? null : (_) => onVerticalDragEnd(),
                        onVerticalDragCancel:
                            isCommitting ? null : onVerticalDragCancel,
                        child: SizedBox(
                          key: ValueKey('taste-card-focus-surface-${card.id}'),
                          width: targetWidth,
                          height: targetHeight,
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Positioned.fill(
                                child: TasteMinimalCardFace(
                                  card: card,
                                  reaction: reaction,
                                  dragReaction:
                                      reaction == null ? activeReaction : null,
                                  dragProgress: dragProgress,
                                  isCommitting: isCommitting,
                                  isFlipped: true,
                                ),
                              ),
                              Positioned(
                                top: 12,
                                right: 12,
                                child: Material(
                                  color: AppPalette.surface,
                                  shape: const CircleBorder(),
                                  child: IconButton(
                                    key: const ValueKey(
                                        'taste-card-focus-close'),
                                    tooltip: '关闭详情',
                                    onPressed: onDismiss,
                                    icon: const Icon(Icons.close_rounded),
                                    color: AppColors.textPrimary,
                                    iconSize: 21,
                                    visualDensity: VisualDensity.compact,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

class _TasteGridCard extends StatefulWidget {
  const _TasteGridCard({
    super.key,
    required this.card,
    required this.reaction,
    required this.onReact,
    this.onPreviewReaction,
    this.onFirstFlip,
    required this.onFocus,
    required this.onFocusDragUpdate,
    required this.onFocusDragEnd,
    required this.onFocusDragCancel,
  });

  final TasteDeckCard card;
  final TasteCardReaction? reaction;
  final ValueChanged<TasteCardReaction> onReact;
  final ValueChanged<TasteCardReaction?>? onPreviewReaction;
  final VoidCallback? onFirstFlip;
  final VoidCallback onFocus;
  final ValueChanged<double> onFocusDragUpdate;
  final VoidCallback onFocusDragEnd;
  final VoidCallback onFocusDragCancel;

  @override
  State<_TasteGridCard> createState() => _TasteGridCardState();
}

class _TasteGridCardState extends State<_TasteGridCard> {
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
  bool _hasReportedFlip = false;
  Timer? _commitTimer;

  @override
  void dispose() {
    _commitTimer?.cancel();
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
      _hasReportedFlip = false;
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
      onTap: isCommitting ? null : _focus,
      onLongPressStart: isCommitting ? null : (_) => _focus(),
      onLongPressMoveUpdate: isCommitting
          ? null
          : (details) => widget.onFocusDragUpdate(details.offsetFromOrigin.dy),
      onLongPressEnd: isCommitting ? null : (_) => widget.onFocusDragEnd(),
      onLongPressCancel: isCommitting ? null : widget.onFocusDragCancel,
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
      child: AnimatedOpacity(
        duration: isCommitting ? _commitDuration : AppMotion.press,
        curve: AppMotion.enter,
        opacity: displayOpacity,
        child: AnimatedContainer(
          duration: isCommitting ? _commitDuration : AppMotion.press,
          curve: AppMotion.enter,
          transform: Matrix4.identity()
            ..translate(0.0, displayOffset)
            ..rotateZ(displayTilt)
            ..scale(displayScale),
          transformAlignment: Alignment.center,
          child: TasteMinimalCardFace(
            card: widget.card,
            reaction: reaction,
            dragReaction: reaction == null ? displayedReaction : null,
            dragProgress: (_verticalDrag.abs() / _triggerDistance).clamp(0, 1),
            isCommitting: isCommitting,
            isFlipped: false,
          ),
        ),
      ),
    );
  }

  void _focus() {
    HapticFeedback.lightImpact();
    if (!_hasReportedFlip) {
      _hasReportedFlip = true;
      widget.onFirstFlip?.call();
    }
    widget.onFocus();
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
