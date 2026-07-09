import 'package:eatwhat_app/v2/core/data/models/taste_selection_models.dart';
import 'package:flutter/material.dart';

class TasteStampTextureLayer extends StatelessWidget {
  const TasteStampTextureLayer({
    super.key,
    required this.reaction,
    required this.color,
  });

  final TasteCardReaction reaction;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: CustomPaint(
        painter: _StampTexturePainter(
          reaction: reaction,
          color: color,
        ),
      ),
    );
  }
}

class TasteFlipLightOverlay extends StatelessWidget {
  const TasteFlipLightOverlay({
    super.key,
    required this.progress,
    required this.strength,
  });

  final double progress;
  final double strength;

  @override
  Widget build(BuildContext context) {
    final centerX = -1.25 + progress * 2.5;
    final edgeAlpha = 0.08 + strength * 0.14;
    final beamAlpha = strength * 0.3;
    final trailAlpha = 0.05 + strength * 0.08;

    return DecoratedBox(
      decoration: BoxDecoration(
        border: Border.all(
          color: Colors.white.withValues(alpha: edgeAlpha),
          width: 0.9,
        ),
        gradient: LinearGradient(
          begin: Alignment(centerX - 0.28, -1),
          end: Alignment(centerX + 0.28, 1),
          colors: [
            Colors.white.withValues(alpha: 0),
            Colors.white.withValues(alpha: trailAlpha),
            Colors.white.withValues(alpha: beamAlpha),
            Colors.white.withValues(alpha: trailAlpha),
            Colors.white.withValues(alpha: 0),
          ],
          stops: const [0.0, 0.28, 0.5, 0.72, 1.0],
        ),
      ),
    );
  }
}

class TasteReactionImpactPulse extends StatelessWidget {
  const TasteReactionImpactPulse({
    super.key,
    required this.reaction,
    required this.accent,
  });

  final TasteCardReaction reaction;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final pulseColor = switch (reaction) {
      TasteCardReaction.liked => const Color(0xFFF46B40),
      TasteCardReaction.disliked => const Color(0xFF6A626B),
      TasteCardReaction.skipped => accent,
    };

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0, end: 1),
      duration: const Duration(milliseconds: 360),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        final rippleScale = 0.38 + value * 1.7;
        final ringOpacity = (1 - value) * 0.28;
        final coreOpacity = (1 - value) * 0.2;
        final washOpacity = (1 - value) * 0.14;

        return Stack(
          alignment: Alignment.center,
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    colors: [
                      pulseColor.withValues(alpha: washOpacity),
                      pulseColor.withValues(alpha: 0),
                    ],
                    radius: 0.92 + value * 0.46,
                  ),
                ),
              ),
            ),
            Transform.scale(
              scale: rippleScale,
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: pulseColor.withValues(alpha: ringOpacity),
                    width: 2.2,
                  ),
                ),
              ),
            ),
            Container(
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: pulseColor.withValues(alpha: coreOpacity),
              ),
            ),
          ],
        );
      },
    );
  }
}

class _StampTexturePainter extends CustomPainter {
  const _StampTexturePainter({
    required this.reaction,
    required this.color,
  });

  final TasteCardReaction reaction;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    switch (reaction) {
      case TasteCardReaction.liked:
        _paintLikedDots(canvas, size);
        break;
      case TasteCardReaction.disliked:
        _paintDislikedHatch(canvas, size);
        break;
      case TasteCardReaction.skipped:
        _paintSkippedBubbles(canvas, size);
        break;
    }
  }

  void _paintLikedDots(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;
    for (double x = 8; x < size.width; x += 10) {
      canvas
        ..drawCircle(
          Offset(x, size.height * 0.32 + ((x ~/ 10).isEven ? 0 : 2)),
          1.1,
          paint,
        )
        ..drawCircle(
          Offset(x + 2, size.height * 0.68 + ((x ~/ 10).isOdd ? 0 : 2)),
          0.9,
          paint,
        );
    }
  }

  void _paintDislikedHatch(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.12)
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    for (double x = -size.height; x < size.width + size.height; x += 8) {
      canvas.drawLine(
        Offset(x, 0),
        Offset(x + size.height, size.height),
        paint,
      );
    }
  }

  void _paintSkippedBubbles(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.12)
      ..style = PaintingStyle.fill;
    for (double y = 6; y < size.height; y += 7) {
      for (double x = 10; x < size.width; x += 12) {
        canvas.drawCircle(
          Offset(x + ((y ~/ 7).isEven ? 0 : 3), y),
          0.8,
          paint,
        );
      }
    }
  }

  @override
  bool shouldRepaint(covariant _StampTexturePainter oldDelegate) {
    return oldDelegate.reaction != reaction || oldDelegate.color != color;
  }
}
