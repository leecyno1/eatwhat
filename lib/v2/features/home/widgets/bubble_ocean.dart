import 'dart:async';
import 'dart:ui';

import 'package:flame/game.dart';
import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../decision/decision_page.dart';
import '../../favorites/selected_tags_sheet.dart';
import '../game/bubble_game.dart';

class BubbleSelectionState {
  const BubbleSelectionState({
    required this.labels,
    required this.ids,
  });

  final List<String> labels;
  final List<String> ids;
}

class BubbleOcean extends StatefulWidget {
  const BubbleOcean({
    super.key,
    this.showDecisionButton = true,
    this.onSelectionChanged,
  });

  final bool showDecisionButton;
  final ValueChanged<BubbleSelectionState>? onSelectionChanged;

  @override
  State<BubbleOcean> createState() => _BubbleOceanState();
}

class _BubbleOceanState extends State<BubbleOcean> {
  late final BubbleGame _game;
  SwipeFeedbackEvent? _feedback;
  Timer? _feedbackClearTimer;

  @override
  void initState() {
    super.initState();
    _game = BubbleGame();
    _game.selectionCount.addListener(_notifySelectionChanged);
    _game.swipeFeedback.addListener(_handleSwipeFeedback);
  }

  @override
  void dispose() {
    _feedbackClearTimer?.cancel();
    _game.selectionCount.removeListener(_notifySelectionChanged);
    _game.swipeFeedback.removeListener(_handleSwipeFeedback);
    super.dispose();
  }

  void _notifySelectionChanged() {
    final callback = widget.onSelectionChanged;
    if (callback == null) return;
    callback(
      BubbleSelectionState(
        labels: List.unmodifiable(_game.selectedItems),
        ids: List.unmodifiable(_game.selectedTagIds),
      ),
    );
  }

  void _handleSwipeFeedback() {
    final event = _game.swipeFeedback.value;
    if (event == null || !mounted) return;
    _feedbackClearTimer?.cancel();
    setState(() {
      _feedback = event;
    });

    _feedbackClearTimer = Timer(const Duration(milliseconds: 900), () {
      if (!mounted) return;
      if (_feedback?.nonce != event.nonce) return;
      setState(() {
        _feedback = null;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        GameWidget(
          game: _game,
          errorBuilder: (context, error) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, color: Colors.red, size: 48),
                  const SizedBox(height: 16),
                  Text(
                    '游戏加载失败',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          },
          loadingBuilder: (context) {
            return const Center(
              child: CircularProgressIndicator(
                color: AppColors.sunsetOrange,
              ),
            );
          },
        ),
        if (widget.showDecisionButton)
          Positioned(
            bottom: 30,
            left: 0,
            right: 0,
            child: ValueListenableBuilder<int>(
              valueListenable: _game.selectionCount,
              builder: (context, count, child) {
                if (count == 0) return const SizedBox.shrink();

                return Center(
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: 1),
                    duration: const Duration(milliseconds: 300),
                    curve: Curves.elasticOut,
                    builder: (context, value, child) {
                      return Transform.scale(
                        scale: value,
                        child: child,
                      );
                    },
                    child: GestureDetector(
                      onTap: () {
                        if (_game.selectedItems.isEmpty) return;

                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (context) => DecisionPage(
                              selectedTagLabels: List.from(_game.selectedItems),
                              selectedTagIds: List.from(_game.selectedTagIds),
                            ),
                          ),
                        );
                      },
                      onLongPress: () {
                        final tags = <SelectedTag>[];
                        for (final id in _game.selectedTagIds) {
                          tags.add(
                            SelectedTag(
                              id: id,
                              label: _game.selectedTagIdToLabel[id] ?? id,
                            ),
                          );
                        }
                        SelectedTagsSheet.show(context, tags: tags);
                      },
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 32,
                          vertical: 16,
                        ),
                        decoration: BoxDecoration(
                          gradient: AppColors.primaryGradient,
                          borderRadius: BorderRadius.circular(30),
                          boxShadow: [
                            BoxShadow(
                              color: AppColors.sunsetOrange.withValues(
                                alpha: 0.4,
                              ),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: Text(
                          '决定 ($count)',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        Positioned(
          top: 52,
          left: 0,
          right: 0,
          child: IgnorePointer(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 220),
              switchInCurve: Curves.easeOutCubic,
              switchOutCurve: Curves.easeInCubic,
              child: _feedback == null
                  ? const SizedBox.shrink()
                  : _SwipeFeedbackChip(
                      key: ValueKey(_feedback!.nonce),
                      event: _feedback!,
                    ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SwipeFeedbackChip extends StatelessWidget {
  const _SwipeFeedbackChip({
    super.key,
    required this.event,
  });

  final SwipeFeedbackEvent event;

  @override
  Widget build(BuildContext context) {
    final accent =
        event.positive ? const Color(0xFFF56A3D) : const Color(0xFF7D8EA3);
    final title = event.positive ? '已收进偏爱' : '先划走这味';
    final subtitle = event.positive ? '系统会提高这类口味的出现权重' : '先把它们压到背景层，避免打扰你';

    return Center(
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0.94, end: 1),
        duration: const Duration(milliseconds: 260),
        curve: Curves.easeOutCubic,
        builder: (context, value, child) {
          return Opacity(
            opacity: value.clamp(0, 1),
            child: Transform.translate(
              offset: Offset(0, 18 * (1 - value)),
              child: Transform.scale(
                scale: 0.985 + value * 0.015,
                child: child,
              ),
            ),
          );
        },
        child: SizedBox(
          width: 268,
          height: 82,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              Positioned.fill(
                child: CustomPaint(
                  painter: _SwipeFeedbackEchoPainter(
                    accent: accent,
                    positive: event.positive,
                  ),
                ),
              ),
              ClipRRect(
                borderRadius: BorderRadius.circular(28),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 18, sigmaY: 18),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          Colors.white.withValues(alpha: 0.88),
                          Colors.white.withValues(alpha: 0.58),
                        ],
                      ),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.92),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: accent.withValues(alpha: 0.18),
                          blurRadius: 26,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                              colors: [
                                accent.withValues(alpha: 0.28),
                                accent.withValues(alpha: 0.12),
                              ],
                            ),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.72),
                            ),
                          ),
                          child: Icon(
                            event.positive
                                ? Icons.arrow_upward_rounded
                                : Icons.arrow_downward_rounded,
                            color: accent,
                            size: 18,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                title,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                event.label,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: AppColors.textPrimary
                                      .withValues(alpha: 0.7),
                                  fontSize: 11,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(height: 3),
                              Text(
                                subtitle,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  color: AppColors.textPrimary
                                      .withValues(alpha: 0.48),
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
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
    );
  }
}

class _SwipeFeedbackEchoPainter extends CustomPainter {
  const _SwipeFeedbackEchoPainter({
    required this.accent,
    required this.positive,
  });

  final Color accent;
  final bool positive;

  @override
  void paint(Canvas canvas, Size size) {
    final centerY = size.height * 0.5;
    final direction = positive ? -1.0 : 1.0;

    final beamPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.15
      ..strokeCap = StrokeCap.round;

    final left = Path()
      ..moveTo(18, centerY + 6 * direction)
      ..quadraticBezierTo(
          42, centerY - 12 * direction, 74, centerY - 7 * direction);
    beamPaint.color = accent.withValues(alpha: 0.2);
    canvas.drawPath(left, beamPaint);

    final right = Path()
      ..moveTo(size.width - 18, centerY - 6 * direction)
      ..quadraticBezierTo(
        size.width - 42,
        centerY + 12 * direction,
        size.width - 74,
        centerY + 7 * direction,
      );
    canvas.drawPath(right, beamPaint);

    final dotPaint = Paint()
      ..style = PaintingStyle.fill
      ..color = accent.withValues(alpha: 0.14)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    canvas.drawCircle(Offset(28, centerY - 12 * direction), 8, dotPaint);
    canvas.drawCircle(
      Offset(size.width - 28, centerY + 12 * direction),
      8,
      dotPaint,
    );
  }

  @override
  bool shouldRepaint(covariant _SwipeFeedbackEchoPainter oldDelegate) {
    return oldDelegate.accent != accent || oldDelegate.positive != positive;
  }
}
