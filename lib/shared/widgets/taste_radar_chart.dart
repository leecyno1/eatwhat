import 'dart:math';
import 'package:flutter/material.dart';

/// 味觉雷达图组件
/// 使用CustomPaint绘制雷达图，展示用户味觉画像
class TasteRadarChart extends StatelessWidget {
  final Map<String, double> data; // 维度 -> 值
  final double maxValue; // 最大值（用于标准化）
  final Color fillColor;
  final Color borderColor;
  final double size;

  const TasteRadarChart({
    super.key,
    required this.data,
    this.maxValue = 10.0,
    this.fillColor = const Color(0xFF6366F1),
    this.borderColor = const Color(0xFF6366F1),
    this.size = 300,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RadarChartPainter(
          data: data,
          maxValue: maxValue,
          fillColor: fillColor.withAlpha(77),
          borderColor: borderColor,
        ),
      ),
    );
  }
}

class _RadarChartPainter extends CustomPainter {
  final Map<String, double> data;
  final double maxValue;
  final Color fillColor;
  final Color borderColor;

  _RadarChartPainter({
    required this.data,
    required this.maxValue,
    required this.fillColor,
    required this.borderColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (data.isEmpty) return;

    final center = Offset(size.width / 2, size.height / 2);
    final radius = min(size.width, size.height) / 2 - 40; // 留出标签空间

    final dimensions = data.keys.toList();
    final angleStep = 2 * pi / dimensions.length;

    // 绘制背景网格
    _drawGrid(canvas, center, radius, dimensions.length, angleStep);

    // 绘制数据多边形
    _drawDataPolygon(canvas, center, radius, dimensions, angleStep);

    // 绘制维度标签
    _drawLabels(canvas, center, radius, dimensions, angleStep);
  }

  void _drawGrid(Canvas canvas, Offset center, double radius, int sides, double angleStep) {
    final gridPaint = Paint()
      ..color = Colors.grey.withAlpha(51)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    final gridFillPaint = Paint()
      ..color = Colors.grey.withAlpha(13)
      ..style = PaintingStyle.fill;

    // 绘制同心多边形
    for (int level = 1; level <= 5; level++) {
      final levelRadius = radius * level / 5;
      final path = Path();

      for (int i = 0; i <= sides; i++) {
        final angle = -pi / 2 + angleStep * i;
        final x = center.dx + levelRadius * cos(angle);
        final y = center.dy + levelRadius * sin(angle);

        if (i == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      path.close();

      // 填充
      canvas.drawPath(path, gridFillPaint);
      // 边框
      canvas.drawPath(path, gridPaint);
    }

    // 绘制从中心到每个顶点的线
    for (int i = 0; i < sides; i++) {
      final angle = -pi / 2 + angleStep * i;
      final x = center.dx + radius * cos(angle);
      final y = center.dy + radius * sin(angle);

      canvas.drawLine(center, Offset(x, y), gridPaint);
    }
  }

  void _drawDataPolygon(
    Canvas canvas,
    Offset center,
    double radius,
    List<String> dimensions,
    double angleStep,
  ) {
    if (data.isEmpty) return;

    final path = Path();
    final borderPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    final fillPaint = Paint()
      ..color = fillColor
      ..style = PaintingStyle.fill;

    bool first = true;

    for (int i = 0; i < dimensions.length; i++) {
      final value = (data[dimensions[i]] ?? 0).clamp(0.0, maxValue);
      final normalizedValue = value / maxValue;
      final angle = -pi / 2 + angleStep * i;
      final x = center.dx + radius * normalizedValue * cos(angle);
      final y = center.dy + radius * normalizedValue * sin(angle);

      if (first) {
        path.moveTo(x, y);
        first = false;
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    // 填充
    canvas.drawPath(path, fillPaint);
    // 边框
    canvas.drawPath(path, borderPaint);

    // 绘制数据点
    final dotPaint = Paint()
      ..color = borderColor
      ..style = PaintingStyle.fill;

    for (int i = 0; i < dimensions.length; i++) {
      final value = (data[dimensions[i]] ?? 0).clamp(0.0, maxValue);
      final normalizedValue = value / maxValue;
      final angle = -pi / 2 + angleStep * i;
      final x = center.dx + radius * normalizedValue * cos(angle);
      final y = center.dy + radius * normalizedValue * sin(angle);

      canvas.drawCircle(Offset(x, y), 4, dotPaint);
    }
  }

  void _drawLabels(
    Canvas canvas,
    Offset center,
    double radius,
    List<String> dimensions,
    double angleStep,
  ) {
    final textStyle = TextStyle(
      color: Colors.grey[700]!,
      fontSize: 12,
      fontWeight: FontWeight.w500,
    );

    for (int i = 0; i < dimensions.length; i++) {
      final angle = -pi / 2 + angleStep * i;
      final labelRadius = radius + 25;
      final x = center.dx + labelRadius * cos(angle);
      final y = center.dy + labelRadius * sin(angle);

      final textSpan = TextSpan(text: dimensions[i], style: textStyle);
      final textPainter = TextPainter(
        text: textSpan,
        textDirection: TextDirection.ltr,
        textAlign: TextAlign.center,
      );
      textPainter.layout();

      // 根据角度调整文本位置以实现更好的显示效果
      double dx = 0;
      double dy = 0;

      if (angle >= -pi / 4 && angle < pi / 4) {
        // 右侧
        dx = 0;
        dy = -textPainter.height / 2;
      } else if (angle >= pi / 4 && angle < 3 * pi / 4) {
        // 下方
        dx = -textPainter.width / 2;
        dy = 0;
      } else if (angle >= 3 * pi / 4 || angle < -3 * pi / 4) {
        // 左侧
        dx = -textPainter.width;
        dy = -textPainter.height / 2;
      } else {
        // 上方
        dx = -textPainter.width / 2;
        dy = -textPainter.height;
      }

      textPainter.paint(canvas, Offset(x + dx, y + dy));
    }
  }

  @override
  bool shouldRepaint(covariant _RadarChartPainter oldDelegate) {
    return data != oldDelegate.data ||
        maxValue != oldDelegate.maxValue ||
        fillColor != oldDelegate.fillColor ||
        borderColor != oldDelegate.borderColor;
  }
}

/// 味觉雷达图包装组件，支持编辑模式
class TasteRadarChartInteractive extends StatefulWidget {
  final Map<String, double> data;
  final double maxValue;
  final Color fillColor;
  final Color borderColor;
  final double size;
  final bool isEditing;
  final ValueChanged<Map<String, double>>? onDataChanged;

  const TasteRadarChartInteractive({
    super.key,
    required this.data,
    this.maxValue = 10.0,
    this.fillColor = const Color(0xFF6366F1),
    this.borderColor = const Color(0xFF6366F1),
    this.size = 300,
    this.isEditing = false,
    this.onDataChanged,
  });

  @override
  State<TasteRadarChartInteractive> createState() => _TasteRadarChartInteractiveState();
}

class _TasteRadarChartInteractiveState extends State<TasteRadarChartInteractive> {
  late Map<String, double> _data;
  int? _selectedIndex;

  @override
  void initState() {
    super.initState();
    _data = Map<String, double>.from(widget.data);
  }

  @override
  void didUpdateWidget(covariant TasteRadarChartInteractive oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.data != oldWidget.data) {
      _data = Map<String, double>.from(widget.data);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: widget.size,
          height: widget.size,
          child: GestureDetector(
            onTapDown: widget.isEditing ? _handleTapDown : null,
            child: CustomPaint(
              painter: _InteractiveRadarChartPainter(
                data: _data,
                maxValue: widget.maxValue,
                fillColor: widget.fillColor.withAlpha(77),
                borderColor: widget.borderColor,
                selectedIndex: _selectedIndex,
              ),
            ),
          ),
        ),
      ],
    );
  }

  void _handleTapDown(TapDownDetails details) {
    if (!widget.isEditing) return;

    final center = Offset(widget.size / 2, widget.size / 2);
    final radius = widget.size / 2 - 40;

    // 计算点击位置相对于中心点的角度
    final dx = details.localPosition.dx - center.dx;
    final dy = details.localPosition.dy - center.dy;
    final distance = sqrt(dx * dx + dy * dy);

    if (distance > radius + 25 || distance < 10) return;

    var angle = atan2(dy, dx) + pi / 2;
    if (angle < 0) angle += 2 * pi;

    final dimensions = _data.keys.toList();
    final angleStep = 2 * pi / dimensions.length;
    final index = (angle / angleStep).floor() % dimensions.length;

    setState(() {
      _selectedIndex = index;
    });
  }
}

class _InteractiveRadarChartPainter extends _RadarChartPainter {
  final int? selectedIndex;

  _InteractiveRadarChartPainter({
    required super.data,
    required super.maxValue,
    required super.fillColor,
    required super.borderColor,
    this.selectedIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    super.paint(canvas, size);

    // 如果有选中的维度，绘制选中高亮
    if (selectedIndex != null && data.isNotEmpty) {
      final center = Offset(size.width / 2, size.height / 2);
      final radius = min(size.width, size.height) / 2 - 40;
      final dimensions = data.keys.toList();
      final angleStep = 2 * pi / dimensions.length;
      final angle = -pi / 2 + angleStep * selectedIndex!;

      final highlightPaint = Paint()
        ..color = Colors.blue.withAlpha(77)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3;

      final value = (data[dimensions[selectedIndex!]] ?? 0).clamp(0.0, maxValue);
      final normalizedValue = value / maxValue;
      final x = center.dx + radius * normalizedValue * cos(angle);
      final y = center.dy + radius * normalizedValue * sin(angle);

      canvas.drawCircle(Offset(x, y), 8, highlightPaint);
    }
  }
}
