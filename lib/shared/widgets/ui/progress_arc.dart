import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../../shared/themes/design_tokens.dart';

/// A simple arc progress with a knob, mimicking the dial in the reference.
class ProgressArc extends StatelessWidget {
  final double value; // 0..1
  final double height;
  final List<Color> colors;

  const ProgressArc(
      {super.key,
      required this.value,
      this.height = 160,
      this.colors = const [DesignTokens.mint, DesignTokens.orange]});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: height,
      child: CustomPaint(
        painter: _ArcPainter(value: value.clamp(0, 1), colors: colors),
        child: Center(
          child: Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: DesignTokens.softShadows(),
            ),
            child: const Icon(Icons.play_arrow_rounded, color: DesignTokens.ink),
          ),
        ),
      ),
    );
  }
}

class _ArcPainter extends CustomPainter {
  final double value;
  final List<Color> colors;

  _ArcPainter({required this.value, required this.colors});

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromLTWH(0, 0, size.width, size.height);
    final center = Offset(rect.center.dx, rect.bottom - 16);
    final radius = math.min(size.width, size.height) * 0.48;

    final background = Paint()
      ..color = DesignTokens.surfaceMuted
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16
      ..strokeCap = StrokeCap.round;

    final foreground = Paint()
      ..shader = LinearGradient(colors: colors)
          .createShader(Rect.fromCircle(center: center, radius: radius))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 16
      ..strokeCap = StrokeCap.round;

    // Angles for semi-circle (200 degrees for a nicer look)
    final start = math.pi + math.pi * 0.1; // 198°
    final sweep = math.pi - math.pi * 0.2; // 162° total

    canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius), start, sweep, false, background);
    canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius), start, sweep * value, false, foreground);

    // Knob
    final knobAngle = start + sweep * value;
    final knobPos =
        Offset(center.dx + radius * math.cos(knobAngle), center.dy + radius * math.sin(knobAngle));
    final knobPaint = Paint()..color = Colors.white;
    canvas.drawCircle(knobPos, 10, knobPaint);
    final stroke = Paint()
      ..color = DesignTokens.ink.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;
    canvas.drawCircle(knobPos, 10, stroke);
  }

  @override
  bool shouldRepaint(covariant _ArcPainter oldDelegate) =>
      oldDelegate.value != value || oldDelegate.colors != colors;
}
