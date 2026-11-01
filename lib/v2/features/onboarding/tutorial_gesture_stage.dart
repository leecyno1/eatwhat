import 'dart:math' as math;

import 'package:eatwhat_app/v2/core/theme/app_tokens.dart';
import 'package:flutter/material.dart';

enum TutorialGesture { tap, drag, shake }

/// 首启教学里的迷你气泡舞台：三段动作共用同一张主卡和同一空间。
class TutorialGestureStage extends StatefulWidget {
  const TutorialGestureStage({
    super.key,
    required this.gesture,
    required this.animationsEnabled,
  });

  final TutorialGesture gesture;
  final bool animationsEnabled;

  @override
  State<TutorialGestureStage> createState() => _TutorialGestureStageState();
}

class _TutorialGestureStageState extends State<TutorialGestureStage>
    with SingleTickerProviderStateMixin {
  /// 教学固定黑金，不随米色主题分发，避免浅底金字失去对比。
  static const Color _leafGreen = Color(0xFF7ABF88);

  late final AnimationController _controller;

  Duration get _duration => switch (widget.gesture) {
        TutorialGesture.tap => const Duration(milliseconds: 700),
        TutorialGesture.drag => const Duration(milliseconds: 1800),
        TutorialGesture.shake => const Duration(milliseconds: 2000),
      };

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _duration);
    _restart();
  }

  @override
  void didUpdateWidget(covariant TutorialGestureStage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.gesture != widget.gesture ||
        oldWidget.animationsEnabled != widget.animationsEnabled) {
      _controller.duration = _duration;
      _restart();
    }
  }

  void _restart() {
    _controller.stop();
    if (widget.animationsEnabled) {
      _controller.forward(from: 0);
    } else {
      _controller.value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = math.min(constraints.maxWidth, 340.0);
        final height = math.min(constraints.maxHeight, 320.0);
        return Center(
          child: SizedBox(
            width: width,
            height: height,
            child: RepaintBoundary(
              key: ValueKey('tutorial-stage-${widget.gesture.name}'),
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return _buildStage(width, height, _controller.value);
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStage(double width, double height, double rawProgress) {
    final staticProgress = switch (widget.gesture) {
      TutorialGesture.tap => 0.34,
      TutorialGesture.drag => 0.48,
      TutorialGesture.shake => 0.15,
    };
    final t = widget.animationsEnabled
        ? Curves.easeInOutCubic.transform(rawProgress)
        : staticProgress;
    var mainOffsetY = 0.0;
    var mainScale = 1.0;
    var stageRotation = 0.0;
    var handOpacity = 0.0;
    var handOffsetY = 20.0;
    var topGlow = 0.0;
    var bottomGlow = 0.0;
    var ripple = 0.0;

    switch (widget.gesture) {
      case TutorialGesture.tap:
        final press = _bell(t, 0.20, 0.48);
        mainScale = 1 - press * 0.055;
        handOpacity = 1 - _phase(t, 0.64, 1.0);
        handOffsetY = 18 + press * 8;
        ripple = _phase(t, 0.38, 1.0);
        break;
      case TutorialGesture.drag:
        // Lift the card slightly while dragging so it stays inside the
        // mini stage even at the 190px floor height.
        mainScale = 0.88;
        handOpacity = 1 - _phase(t, 0.92, 1.0);
        if (t < 0.42) {
          final p = _smooth(_phase(t, 0, 0.42));
          mainOffsetY = -height * 0.24 * p;
          topGlow = p;
        } else if (t < 0.54) {
          mainOffsetY = -height * 0.24;
          topGlow = 1;
        } else if (t < 0.66) {
          final p = _smooth(_phase(t, 0.54, 0.66));
          mainOffsetY = -height * 0.24 * (1 - p);
          topGlow = 1 - p;
        } else if (t < 0.90) {
          final p = _smooth(_phase(t, 0.66, 0.90));
          mainOffsetY = height * 0.24 * p;
          bottomGlow = p;
        } else {
          final p = _smooth(_phase(t, 0.90, 1.0));
          mainOffsetY = height * 0.24 * (1 - p);
          bottomGlow = 1 - p;
        }
        handOffsetY = mainOffsetY + 22;
        break;
      case TutorialGesture.shake:
        mainOffsetY = math.sin(t * math.pi * 8) * (1 - t) * 6;
        stageRotation = math.sin(t * math.pi * 10) * (1 - t) * 0.06;
        break;
    }

    return Transform.rotate(
      angle: stageRotation,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          _ambientOrb(width, height),
          _dropZone(
            alignment: Alignment.topCenter,
            color: _leafGreen,
            label: '顶部 · 收下',
            opacity: widget.gesture == TutorialGesture.drag
                ? 0.24 + topGlow * 0.76
                : 0.12,
          ),
          _dropZone(
            alignment: Alignment.bottomCenter,
            color: AppPalette.tomato,
            label: '底部 · 拉黑',
            opacity: widget.gesture == TutorialGesture.drag
                ? 0.24 + bottomGlow * 0.76
                : 0.12,
          ),
          if (widget.gesture == TutorialGesture.tap && ripple > 0)
            IgnorePointer(
              child: Container(
                width: 100 + ripple * 110,
                height: 100 + ripple * 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: GoldPalette.gold.withValues(
                      alpha: (1 - ripple) * 0.55,
                    ),
                  ),
                ),
              ),
            ),
          Transform.rotate(
            angle: -0.13,
            child: Transform.translate(
              offset: const Offset(-34, 8),
              child: _entityCard(
                width: 90,
                height: 112,
                asset: 'assets/images/preference_entities/c_hotpot.webp',
                opacity: 0.65,
              ),
            ),
          ),
          Transform.rotate(
            angle: 0.12,
            child: Transform.translate(
              offset: const Offset(36, 14),
              child: _entityCard(
                width: 84,
                height: 104,
                asset: 'assets/images/preference_entities/i_egg.webp',
                opacity: 0.52,
              ),
            ),
          ),
          Transform.translate(
            offset: Offset(0, mainOffsetY),
            child: Transform.scale(
              scale: mainScale,
              child: _entityCard(
                width: 116,
                height: 144,
                asset: 'assets/images/preference_entities/i_beef.webp',
                label: '今晚这一口',
              ),
            ),
          ),
          if (handOpacity > 0.01)
            Positioned(
              left: width / 2 + 32,
              top: height / 2 + handOffsetY,
              child: Opacity(
                opacity: handOpacity,
                child: const Icon(
                  Icons.touch_app_rounded,
                  size: 42,
                  color: GoldPalette.goldSoft,
                ),
              ),
            ),
          if (widget.gesture == TutorialGesture.shake) ...[
            _spark(width * 0.30, height * 0.34, t),
            _spark(width * 0.72, height * 0.31, t + 0.22),
            _spark(width * 0.27, height * 0.68, t + 0.41),
            _spark(width * 0.74, height * 0.70, t + 0.63),
          ],
        ],
      ),
    );
  }

  Widget _ambientOrb(double width, double height) {
    return IgnorePointer(
      child: Container(
        width: math.min(width, height) * 0.9,
        height: math.min(width, height) * 0.9,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              GoldPalette.gold.withValues(alpha: 0.12),
              GoldPalette.nightDeep.withValues(alpha: 0),
            ],
          ),
          border: Border.all(
            color: GoldPalette.goldHairline.withValues(alpha: 0.55),
          ),
        ),
      ),
    );
  }

  Widget _dropZone({
    required Alignment alignment,
    required Color color,
    required String label,
    required double opacity,
  }) {
    return Align(
      alignment: alignment,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: opacity * 0.12),
          borderRadius: AppRadii.capsule,
          border: Border.all(
            color: color.withValues(alpha: opacity * 0.72),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: color.withValues(alpha: 0.55 + opacity * 0.45),
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
          ),
        ),
      ),
    );
  }

  Widget _entityCard({
    required double width,
    required double height,
    required String asset,
    String? label,
    double opacity = 1,
  }) {
    return Opacity(
      opacity: opacity,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: GoldPalette.panel,
          borderRadius: AppRadii.card,
          border: Border.all(color: GoldPalette.goldHairline),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.45),
              blurRadius: 24,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              asset,
              fit: BoxFit.cover,
              cacheWidth: (width * 3).round(),
              errorBuilder: (_, __, ___) => const Center(
                child: Icon(
                  Icons.restaurant_rounded,
                  color: GoldPalette.goldSoft,
                ),
              ),
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Color(0xCC0B0B0E)],
                ),
              ),
            ),
            if (label != null)
              Positioned(
                left: 12,
                right: 12,
                bottom: 11,
                child: Text(
                  label,
                  style: const TextStyle(
                    color: GoldPalette.creamText,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _spark(double left, double top, double phase) {
    final value = math.sin(phase * math.pi * 2).abs();
    return Positioned(
      left: left,
      top: top,
      child: Container(
        width: 4 + value * 4,
        height: 4 + value * 4,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: GoldPalette.gold.withValues(alpha: 0.25 + value * 0.45),
        ),
      ),
    );
  }

  static double _phase(double value, double begin, double end) {
    if (end <= begin) return 0;
    return ((value - begin) / (end - begin)).clamp(0.0, 1.0);
  }

  static double _smooth(double value) {
    return Curves.easeInOutCubic.transform(value);
  }

  static double _bell(double value, double begin, double peak) {
    if (value <= begin || value >= peak) return 0;
    final progress = (value - begin) / (peak - begin);
    return math.sin(progress * math.pi);
  }
}
