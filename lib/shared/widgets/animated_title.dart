import 'package:flutter/material.dart';
import 'floating_question_marks.dart';
import 'dart:math' as math;

/// 动画标题组件 - "吃什么"
class AnimatedTitle extends StatefulWidget {
  final String title;
  final double fontSize;
  final Color textColor;
  final Color questionMarkColor;
  final bool showQuestionMarks;

  const AnimatedTitle({
    super.key,
    this.title = '吃什么',
    this.fontSize = 48,
    this.textColor = Colors.black87,
    this.questionMarkColor = Colors.white,
    this.showQuestionMarks = true,
  });

  @override
  State<AnimatedTitle> createState() => _AnimatedTitleState();
}

class _AnimatedTitleState extends State<AnimatedTitle>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _bounceController;
  late AnimationController _glowController;

  late Animation<double> _scaleAnimation;
  late Animation<double> _bounceAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();

    // 缩放动画控制器
    _scaleController = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    // 弹跳动画控制器
    _bounceController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    // 发光动画控制器
    _glowController = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat();

    _scaleAnimation = Tween<double>(
      begin: 0.9,
      end: 1.15, // 更大的缩放范围
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeInOut,
    ));

    _bounceAnimation = Tween<double>(
      begin: 0,
      end: 15, // 更大的弹跳范围
    ).animate(CurvedAnimation(
      parent: _bounceController,
      curve: Curves.elasticOut,
    ));

    _glowAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 400,
      height: 150,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          // 背景浮动问号装饰 - 使用Container限制边界
          if (widget.showQuestionMarks)
            Positioned.fill(
              child: Container(
                width: 400,
                height: 150,
                child: ClipRect(
                  child: FloatingQuestionMarks(
                    count: 8, // 增加问号数量
                    areaWidth: 400, // 扩大动画区域
                    areaHeight: 150,
                    color: widget.questionMarkColor.withValues(alpha: 0.15),
                    minSize: 20, // 增加问号大小
                    maxSize: 35,
                    animationDuration: const Duration(seconds: 4),
                  ),
                ),
              ),
            ),

          // 主标题 - 使用Container限制边界
          Container(
            width: 400,
            height: 150,
            alignment: Alignment.center,
            child: AnimatedBuilder(
              animation: Listenable.merge([
                _scaleController,
                _bounceController,
                _glowController,
              ]),
              builder: (context, child) {
                return Transform.scale(
                  scale: _scaleAnimation.value,
                  child: Transform.translate(
                    offset: Offset(
                      math.sin(_bounceController.value * math.pi * 2) *
                          8, // 添加水平摇摆
                      -_bounceAnimation.value *
                          math.sin(_bounceController.value * math.pi * 2),
                    ),
                    child: Transform.rotate(
                      angle: math.sin(_bounceController.value * math.pi * 4) *
                          0.05, // 添加轻微旋转
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 32, vertical: 16), // 增加内边距
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(35),
                          boxShadow: [
                            BoxShadow(
                              color: widget.textColor.withValues(
                                  alpha: 0.15 +
                                      _glowAnimation.value * 0.3), // 增强发光效果
                              blurRadius:
                                  25 + _glowAnimation.value * 20, // 更大的阴影范围
                              spreadRadius: 3,
                            ),
                          ],
                        ),
                        child: ShaderMask(
                          shaderCallback: (bounds) {
                            return LinearGradient(
                              colors: [
                                widget.textColor,
                                widget.textColor.withValues(
                                    alpha: 0.8 + _glowAnimation.value * 0.2),
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
                              color: Colors.white, // 需要白色才能应用shader
                              letterSpacing: 6, // 增加字母间距
                              shadows: [
                                Shadow(
                                  offset: const Offset(3, 3), // 增强阴影
                                  blurRadius: 6,
                                  color: Colors.black.withValues(alpha: 0.3),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // 额外的装饰问号（在标题两侧）- 使用有界布局
          if (widget.showQuestionMarks) ...[
            Positioned(
              left: -10,
              top: 0,
              width: 120,
              height: 150,
              child: Container(
                width: 120,
                height: 150,
                child: AnimatedBuilder(
                  animation: _bounceController,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: math.sin(_bounceController.value * math.pi * 2) *
                          0.4, // 增大旋转范围
                      child: Transform.translate(
                        offset: Offset(
                          math.sin(_bounceController.value * math.pi * 3) *
                              15, // 添加水平移动
                          math.cos(_bounceController.value * math.pi * 2) *
                              8, // 添加垂直移动
                        ),
                        child: Opacity(
                          opacity: 0.4 +
                              math.sin(_glowController.value * math.pi * 2) *
                                  0.3,
                          child: Text(
                            '?',
                            style: TextStyle(
                              fontSize: widget.fontSize * 0.7, // 增大问号
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
            ),
            Positioned(
              right: -10,
              top: 0,
              width: 120,
              height: 150,
              child: Container(
                width: 120,
                height: 150,
                child: AnimatedBuilder(
                  animation: _bounceController,
                  builder: (context, child) {
                    return Transform.rotate(
                      angle: -math.sin(_bounceController.value * math.pi * 2) *
                          0.4, // 增大旋转范围
                      child: Transform.translate(
                        offset: Offset(
                          -math.sin(_bounceController.value * math.pi * 3) *
                              15, // 添加水平移动
                          math.sin(_bounceController.value * math.pi * 2) *
                              8, // 添加垂直移动
                        ),
                        child: Opacity(
                          opacity: 0.4 +
                              math.cos(_glowController.value * math.pi * 2) *
                                  0.3,
                          child: Text(
                            '?',
                            style: TextStyle(
                              fontSize: widget.fontSize * 0.7, // 增大问号
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
            ),
          ],
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

/// 简化版动画标题（用于其他页面）
class SimpleAnimatedTitle extends StatefulWidget {
  final String title;
  final double fontSize;
  final Color textColor;

  const SimpleAnimatedTitle({
    super.key,
    this.title = '吃什么',
    this.fontSize = 32,
    this.textColor = Colors.black87,
  });

  @override
  State<SimpleAnimatedTitle> createState() => _SimpleAnimatedTitleState();
}

class _SimpleAnimatedTitleState extends State<SimpleAnimatedTitle>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat(reverse: true);

    _fadeAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _fadeAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: Text(
            widget.title,
            style: TextStyle(
              fontSize: widget.fontSize,
              fontWeight: FontWeight.bold,
              color: widget.textColor,
              letterSpacing: 2,
              shadows: [
                Shadow(
                  offset: const Offset(1, 1),
                  blurRadius: 2,
                  color: Colors.black.withValues(alpha: 0.2),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
