import 'package:flutter/material.dart';
import 'dart:math' as math;
import 'dart:math';

/// 漂浮问号组件
class FloatingQuestionMarks extends StatefulWidget {
  final int count;
  final double areaWidth;
  final double areaHeight;
  final Color color;
  final double minSize;
  final double maxSize;
  final Duration animationDuration;

  const FloatingQuestionMarks({
    super.key,
    this.count = 8,
    this.areaWidth = 300,
    this.areaHeight = 200,
    this.color = Colors.white,
    this.minSize = 16,
    this.maxSize = 24,
    this.animationDuration = const Duration(seconds: 3),
  });

  @override
  State<FloatingQuestionMarks> createState() => _FloatingQuestionMarksState();
}

class _FloatingQuestionMarksState extends State<FloatingQuestionMarks>
    with TickerProviderStateMixin {
  late List<QuestionMarkData> _questionMarks;
  late AnimationController _animationController;
  final Random _random = Random();

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: widget.animationDuration,
      vsync: this,
    )..repeat();
    
    _initializeQuestionMarks();
  }

  void _initializeQuestionMarks() {
    _questionMarks = List.generate(widget.count, (index) {
      return QuestionMarkData(
        initialX: _random.nextDouble() * widget.areaWidth,
        initialY: _random.nextDouble() * widget.areaHeight,
        size: widget.minSize + _random.nextDouble() * (widget.maxSize - widget.minSize),
        opacity: 0.1 + _random.nextDouble() * 0.3, // 0.1 - 0.4
        speed: 0.3 + _random.nextDouble() * 0.7, // 0.3 - 1.0
        direction: _random.nextDouble() * 2 * math.pi,
        phaseOffset: _random.nextDouble() * 2 * math.pi,
        rotationSpeed: _random.nextDouble() * 0.5 + 0.2, // 0.2 - 0.7
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.areaWidth,
      height: widget.areaHeight,
      child: AnimatedBuilder(
        animation: _animationController,
        builder: (context, child) {
          return CustomPaint(
            painter: QuestionMarksPainter(
              questionMarks: _questionMarks,
              animationValue: _animationController.value,
              color: widget.color,
            ),
            size: Size(widget.areaWidth, widget.areaHeight),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
}

/// 问号数据模型
class QuestionMarkData {
  final double initialX;
  final double initialY;
  final double size;
  final double opacity;
  final double speed;
  final double direction;
  final double phaseOffset;
  final double rotationSpeed;

  QuestionMarkData({
    required this.initialX,
    required this.initialY,
    required this.size,
    required this.opacity,
    required this.speed,
    required this.direction,
    required this.phaseOffset,
    required this.rotationSpeed,
  });
}

/// 问号绘制器
class QuestionMarksPainter extends CustomPainter {
  final List<QuestionMarkData> questionMarks;
  final double animationValue;
  final Color color;

  QuestionMarksPainter({
    required this.questionMarks,
    required this.animationValue,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    for (final mark in questionMarks) {
      // 计算当前位置（循环漂浮）
      final phase = (animationValue + mark.phaseOffset) * 2 * math.pi;
      final floatOffset = math.sin(phase) * 20; // 上下浮动20像素
      
      final x = mark.initialX + math.cos(animationValue * 2 * math.pi * mark.speed + mark.direction) * 30;
      final y = mark.initialY + floatOffset + math.sin(animationValue * 2 * math.pi * mark.speed + mark.direction) * 15;
      
      // 确保在边界内
      final clampedX = x.clamp(0.0, size.width);
      final clampedY = y.clamp(0.0, size.height);
      
      // 计算透明度（呼吸效果）
      final breathe = math.sin(animationValue * 2 * math.pi * 0.5 + mark.phaseOffset);
      final currentOpacity = mark.opacity * (0.7 + 0.3 * breathe);
      
      // 计算旋转角度
      final rotation = animationValue * 2 * math.pi * mark.rotationSpeed;
      
      // 绘制问号
      canvas.save();
      canvas.translate(clampedX, clampedY);
      canvas.rotate(rotation);
      
      final textPainter = TextPainter(
        text: TextSpan(
          text: '?',
          style: TextStyle(
            fontSize: mark.size,
            color: color.withValues(alpha: currentOpacity),
            fontWeight: FontWeight.w300,
            shadows: [
              Shadow(
                offset: const Offset(1, 1),
                blurRadius: 2,
                color: Colors.black.withValues(alpha: 0.1),
              ),
            ],
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(-textPainter.width / 2, -textPainter.height / 2),
      );
      
      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(QuestionMarksPainter oldDelegate) {
    return oldDelegate.animationValue != animationValue ||
           oldDelegate.color != color;
  }
}

/// 简化版漂浮问号（用于较小空间）
class SimpleFloatingQuestionMarks extends StatefulWidget {
  final Color color;
  final double size;

  const SimpleFloatingQuestionMarks({
    super.key,
    this.color = Colors.white,
    this.size = 100,
  });

  @override
  State<SimpleFloatingQuestionMarks> createState() => _SimpleFloatingQuestionMarksState();
}

class _SimpleFloatingQuestionMarksState extends State<SimpleFloatingQuestionMarks>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _floatAnimation;
  late Animation<double> _opacityAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);
    
    _floatAnimation = Tween<double>(
      begin: -5,
      end: 5,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
    
    _opacityAnimation = Tween<double>(
      begin: 0.2,
      end: 0.6,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: AnimatedBuilder(
        animation: _controller,
        builder: (context, child) {
          return Transform.translate(
            offset: Offset(0, _floatAnimation.value),
            child: Opacity(
              opacity: _opacityAnimation.value,
              child: const Center(
                child: Text(
                  '?',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w300,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}