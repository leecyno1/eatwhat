import 'dart:math' as math;

import 'package:flutter/material.dart';

class TasteCardBoardShell extends StatelessWidget {
  const TasteCardBoardShell({
    super.key,
    required this.pageCount,
    required this.currentPage,
    required this.progress,
    required this.blendProgress,
    required this.slotRectFor,
  });

  final int pageCount;
  final int currentPage;
  final double progress;
  final double blendProgress;
  final Rect Function(int index) slotRectFor;

  @override
  Widget build(BuildContext context) {
    final blendPulse = math.sin(blendProgress * math.pi);
    final warmGlow = const Color(0xFFF46B40)
        .withValues(alpha: 0.12 + progress * 0.1 + blendPulse * 0.04);
    final coolGlow = const Color(0xFF8186D8)
        .withValues(alpha: 0.08 + progress * 0.08 + blendPulse * 0.03);

    return Stack(
      children: [
        const Positioned.fill(
          child: _BoardCornerMarkers(
            key: ValueKey('taste-board-corner-markers'),
          ),
        ),
        Positioned(
          left: -18,
          top: -14,
          child: Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  warmGlow,
                  Colors.white.withValues(alpha: 0),
                ],
              ),
            ),
          ),
        ),
        Positioned(
          right: -20,
          bottom: 24,
          child: Container(
            width: 160,
            height: 160,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: RadialGradient(
                colors: [
                  coolGlow,
                  Colors.white.withValues(alpha: 0),
                ],
              ),
            ),
          ),
        ),
        ...List.generate(16, (index) {
          final rect = slotRectFor(index);
          return Positioned(
            left: rect.left,
            top: rect.top,
            width: rect.width,
            height: rect.height,
            child: IgnorePointer(
              child: DecoratedBox(
                key: ValueKey('taste-board-slot-$index'),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.08),
                    width: 0.7,
                  ),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      Colors.white.withValues(alpha: 0.06),
                      Colors.white.withValues(alpha: 0.015),
                    ],
                  ),
                ),
              ),
            ),
          );
        }),
        Positioned(
          left: 0,
          right: 0,
          bottom: 8,
          child: IgnorePointer(
            child: Transform.translate(
              offset: Offset(0, -blendPulse * 2),
              child: Row(
                key: const ValueKey('taste-board-progress-dots'),
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(pageCount, (index) {
                  final active = index + 1 == currentPage;
                  final pulseScale =
                      active ? 1 + blendPulse * 0.1 : 1 + blendPulse * 0.04;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    transform: Matrix4.identity()..scale(pulseScale),
                    width: active ? 20 + blendPulse * 3 : 6,
                    height: active ? 6 + blendPulse * 0.8 : 6,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      color: active
                          ? const Color(0xFFF46B40).withValues(alpha: 0.82)
                          : Colors.white.withValues(alpha: 0.36),
                    ),
                  );
                }),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class TastePageDealFan extends StatelessWidget {
  const TastePageDealFan({
    super.key,
    required this.progress,
    required this.direction,
  });

  final double progress;
  final int direction;

  @override
  Widget build(BuildContext context) {
    final opacity = (0.24 + progress * 0.34).clamp(0.24, 0.58);

    return SizedBox(
      width: 196,
      height: 128,
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: IgnorePointer(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFFF46B40)
                          .withValues(alpha: 0.12 * progress),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
          ),
          ...List.generate(5, (index) {
            final layer = index - 2;
            final shift = layer * 14.0 * direction;
            final angle = layer * 0.11 * direction;
            final depth = 1 - layer.abs() * 0.08;
            return Transform.translate(
              offset: Offset(shift, -4 + index * 2.6),
              child: Transform.rotate(
                angle: angle,
                child: Container(
                  width: 80 + depth * 12,
                  height: 100 + depth * 12,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    color: Colors.white.withValues(
                      alpha: (opacity - index * 0.045).clamp(0.16, 0.62),
                    ),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.36),
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: const Color(0xFFF46B40).withValues(
                          alpha: 0.04 + progress * 0.05,
                        ),
                        blurRadius: 18,
                        offset: const Offset(0, 10),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _BoardCornerMarkers extends StatelessWidget {
  const _BoardCornerMarkers({super.key});

  @override
  Widget build(BuildContext context) {
    return const Stack(
      children: [
        _BoardCornerMarker(alignment: Alignment.topLeft),
        _BoardCornerMarker(alignment: Alignment.topRight),
        _BoardCornerMarker(alignment: Alignment.bottomLeft),
        _BoardCornerMarker(alignment: Alignment.bottomRight),
      ],
    );
  }
}

class _BoardCornerMarker extends StatelessWidget {
  const _BoardCornerMarker({required this.alignment});

  final Alignment alignment;

  @override
  Widget build(BuildContext context) {
    final isTop = alignment.y < 0;
    final isLeft = alignment.x < 0;

    return Align(
      alignment: alignment,
      child: Padding(
        padding: const EdgeInsets.all(10),
        child: SizedBox(
          width: 22,
          height: 22,
          child: Stack(
            children: [
              Align(
                alignment:
                    isLeft ? Alignment.centerLeft : Alignment.centerRight,
                child: Container(
                  width: 16,
                  height: 1.4,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.42),
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              Align(
                alignment: isTop ? Alignment.topCenter : Alignment.bottomCenter,
                child: Container(
                  width: 1.4,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.42),
                    borderRadius: BorderRadius.circular(999),
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
