import 'package:flutter/material.dart';

class LinearTexturePainter extends CustomPainter {
  const LinearTexturePainter({
    required this.primary,
    required this.secondary,
    required this.angleSeed,
  });

  final Color primary;
  final Color secondary;
  final double angleSeed;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    final center = Offset(size.width / 2, size.height / 2);

    for (var index = -4; index < 8; index++) {
      final shift = index * 14.0;
      paint.color = (index.isEven ? primary : secondary)
          .withValues(alpha: 0.07 - (index.abs() * 0.004).clamp(0, 0.04));
      final start = Offset(0, center.dy + shift + angleSeed * 12);
      final end =
          Offset(size.width, center.dy + shift - angleSeed * size.width * 0.3);
      canvas.drawLine(start, end, paint);
    }
  }

  @override
  bool shouldRepaint(covariant LinearTexturePainter oldDelegate) {
    return oldDelegate.primary != primary ||
        oldDelegate.secondary != secondary ||
        oldDelegate.angleSeed != angleSeed;
  }
}

class GridTexturePainter extends CustomPainter {
  const GridTexturePainter({
    required this.color,
  });

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.08)
      ..strokeWidth = 0.8;

    for (double x = 16; x < size.width; x += 18) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 14; y < size.height; y += 18) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant GridTexturePainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

class ArcTexturePainter extends CustomPainter {
  const ArcTexturePainter({
    required this.color,
    required this.secondary,
    required this.mode,
  });

  final Color color;
  final Color secondary;
  final String mode;

  @override
  void paint(Canvas canvas, Size size) {
    final rect = Rect.fromCircle(
      center: Offset(size.width * 0.82, size.height * 0.28),
      radius: size.width * 0.34,
    );
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    final loops = switch (mode) {
      'steam-ring' => 3,
      'sunbeam' => 4,
      _ => 2,
    };

    for (var index = 0; index < loops; index++) {
      paint
        ..strokeWidth = 1.2 + index * 0.4
        ..color = (index.isEven ? color : secondary)
            .withValues(alpha: 0.12 - index * 0.02);
      canvas.drawArc(
        rect.inflate(index * 10),
        switch (mode) {
          'sunbeam' => -1.9,
          'moon-arc' => -2.6,
          _ => -2.25,
        },
        switch (mode) {
          'sunbeam' => 1.2,
          'moon-arc' => 1.45,
          _ => 1.6,
        },
        false,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant ArcTexturePainter oldDelegate) {
    return oldDelegate.color != color ||
        oldDelegate.secondary != secondary ||
        oldDelegate.mode != mode;
  }
}

class ConstellationTexturePainter extends CustomPainter {
  const ConstellationTexturePainter({
    required this.primary,
    required this.secondary,
  });

  final Color primary;
  final Color secondary;

  static const List<Offset> _points = [
    Offset(0.18, 0.24),
    Offset(0.34, 0.18),
    Offset(0.48, 0.3),
    Offset(0.66, 0.22),
    Offset(0.76, 0.38),
    Offset(0.58, 0.5),
  ];

  @override
  void paint(Canvas canvas, Size size) {
    final linePaint = Paint()
      ..color = primary.withValues(alpha: 0.08)
      ..strokeWidth = 0.9;
    final dotPaint = Paint()..style = PaintingStyle.fill;

    Offset pointAt(Offset point) =>
        Offset(size.width * point.dx, size.height * point.dy);

    for (var index = 0; index < _points.length - 1; index++) {
      canvas.drawLine(
        pointAt(_points[index]),
        pointAt(_points[index + 1]),
        linePaint,
      );
    }

    for (var index = 0; index < _points.length; index++) {
      dotPaint.color =
          (index.isEven ? primary : secondary).withValues(alpha: 0.18);
      canvas.drawCircle(pointAt(_points[index]), 2.4 + (index % 2), dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant ConstellationTexturePainter oldDelegate) {
    return oldDelegate.primary != primary || oldDelegate.secondary != secondary;
  }
}
