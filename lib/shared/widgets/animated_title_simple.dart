import 'package:flutter/material.dart';
import 'dart:math' as math;

// 简化版的动画标题，去除所有 OverflowBox - 更新
class AnimatedTitleSimple extends StatefulWidget {
  final String title;
  final double fontSize;
  final Color textColor;
  final Color questionMarkColor;
  final bool showQuestionMarks;

  const AnimatedTitleSimple({
    super.key,
    required this.title,
    this.fontSize = 28,
    this.textColor = Colors.white,
    this.questionMarkColor = Colors.orange,
    this.showQuestionMarks = true,
  });

  @override
  State<AnimatedTitleSimple> createState() => _AnimatedTitleSimpleState();
}

class _AnimatedTitleSimpleState extends State<AnimatedTitleSimple> with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _bounceController;
  late AnimationController _glowController;

  @override
  void initState() {
    super.initState();

    _scaleController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    _bounceController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    );

    _glowController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    );

    // 启动动画
    _scaleController.repeat(reverse: true);
    _bounceController.repeat();
    _glowController.repeat(reverse: true);
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 400,
      height: 150,
      child: Stack(
        clipBehavior: Clip.hardEdge,
        alignment: Alignment.center,
        children: [
          // 主标题
          Center(
            child: AnimatedBuilder(
              animation: Listenable.merge([
                _scaleController,
                _bounceController,
                _glowController,
              ]),
              builder: (context, child) {
                return Transform.scale(
                  scale: 1.0 + _scaleController.value * 0.1,
                  child: Transform.translate(
                    offset: Offset(
                      math.sin(_bounceController.value * math.pi * 2) * 3,
                      math.sin(_bounceController.value * math.pi) * 2,
                    ),
                    child: ShaderMask(
                      shaderCallback: (bounds) {
                        return LinearGradient(
                          colors: [
                            widget.textColor,
                            widget.textColor.withOpacity(0.8 + _glowController.value * 0.2),
                            widget.textColor,
                          ],
                          stops: const [0.0, 0.5, 1.0],
                        ).createShader(bounds);
                      },
                      child: Text(
                        widget.title,
                        style: TextStyle(
                          fontSize: widget.fontSize,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                          letterSpacing: 6,
                          shadows: [
                            Shadow(
                              offset: const Offset(2, 2),
                              blurRadius: 4,
                              color: Colors.black26,
                            ),
                            Shadow(
                              offset: const Offset(0, 0),
                              blurRadius: 20,
                              color: widget.textColor.withOpacity(0.5),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // 左侧装饰问号
          if (widget.showQuestionMarks)
            Positioned(
              left: 20,
              child: AnimatedBuilder(
                animation: _bounceController,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: math.sin(_bounceController.value * math.pi * 2) * 0.2,
                    child: Transform.translate(
                      offset: Offset(
                        math.sin(_bounceController.value * math.pi * 3) * 10,
                        math.sin(_bounceController.value * math.pi * 2) * 5,
                      ),
                      child: Opacity(
                        opacity: 0.4 + math.sin(_glowController.value * math.pi * 2) * 0.3,
                        child: Text(
                          '?',
                          style: TextStyle(
                            fontSize: widget.fontSize * 0.6,
                            color: widget.questionMarkColor,
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),

          // 右侧装饰问号
          if (widget.showQuestionMarks)
            Positioned(
              right: 20,
              child: AnimatedBuilder(
                animation: _bounceController,
                builder: (context, child) {
                  return Transform.rotate(
                    angle: -math.sin(_bounceController.value * math.pi * 2) * 0.2,
                    child: Transform.translate(
                      offset: Offset(
                        -math.sin(_bounceController.value * math.pi * 3) * 10,
                        math.sin(_bounceController.value * math.pi * 2) * 5,
                      ),
                      child: Opacity(
                        opacity: 0.4 + math.cos(_glowController.value * math.pi * 2) * 0.3,
                        child: Text(
                          '?',
                          style: TextStyle(
                            fontSize: widget.fontSize * 0.6,
                            color: widget.questionMarkColor,
                            fontWeight: FontWeight.w300,
                          ),
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _bounceController.dispose();
    _glowController.dispose();
    super.dispose();
  }
}
