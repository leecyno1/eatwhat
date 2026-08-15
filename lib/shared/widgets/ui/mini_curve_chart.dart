import 'package:flutter/material.dart';
import 'dart:math' as math;
import '../../../shared/themes/design_tokens.dart';

/// A very lightweight mini curve chart (sparkline-like) with a highlighted point.
class MiniCurveChart extends StatelessWidget {
  final List<double> points; // normalized 0..1
  final int highlightIndex;
  final Color lineColor;

  const MiniCurveChart(
      {super.key,
      required this.points,
      this.highlightIndex = -1,
      this.lineColor = DesignTokens.pink});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 120,
      child: CustomPaint(
        painter: _CurvePainter(points: points, highlightIndex: highlightIndex, color: lineColor),
      ),
    );
  }
}

class _CurvePainter extends CustomPainter {
  final List<double> points;
  final int highlightIndex;
  final Color color;

  _CurvePainter({required this.points, required this.highlightIndex, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;
    final path = Path();
    final stepX = size.width / (points.length - 1);
    final y = (double v) => size.height - v * size.height;

    // Smooth cubic path
    path.moveTo(0, y(points.first));
    for (int i = 1; i < points.length; i++) {
      final x = stepX * i;
      final prevX = stepX * (i - 1);
      final ctrlX1 = prevX + stepX / 2;
      final ctrlX2 = x - stepX / 2;
      path.cubicTo(ctrlX1, y(points[i - 1]), ctrlX2, y(points[i]), x, y(points[i]));
    }

    // Fill under curve (soft gradient)
    final fillPath = Path.from(path)
      ..lineTo(size.width, size.height)
      ..lineTo(0, size.height)
      ..close();
    final fillPaint = Paint()
      ..shader = LinearGradient(
              colors: [color.withOpacity(0.18), Colors.transparent],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter)
          .createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(fillPath, fillPaint);

    // Stroke line
    final stroke = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawPath(path, stroke);

    // Highlight dot and tooltip
    if (highlightIndex >= 0 && highlightIndex < points.length) {
      final hx = stepX * highlightIndex;
      final hy = y(points[highlightIndex]);
      canvas.drawCircle(Offset(hx, hy), 4, Paint()..color = color);

      // Tooltip bubble
      final bubble = RRect.fromRectAndRadius(
          Rect.fromCenter(center: Offset(hx, hy - 22), width: 44, height: 24),
          const Radius.circular(12));
      final bubblePaint = Paint()..color = DesignTokens.surface;
      canvas.drawRRect(bubble, bubblePaint);
      final tp = TextPainter(
        text: TextSpan(
            text: '${(points[highlightIndex] * 100).round()}%',
            style: const TextStyle(
                fontSize: 12, fontWeight: FontWeight.w700, color: DesignTokens.ink)),
        textDirection: TextDirection.ltr,
      )..layout();
      tp.paint(canvas, Offset(hx - tp.width / 2, hy - 22 - tp.height / 2));
    }
  }

  @override
  bool shouldRepaint(covariant _CurvePainter oldDelegate) {
    return oldDelegate.points != points ||
        oldDelegate.highlightIndex != highlightIndex ||
        oldDelegate.color != color;
  }
}
