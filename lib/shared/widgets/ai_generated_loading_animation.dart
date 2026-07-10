import 'package:flutter/material.dart';

/// AI生成风格的加载动画组件
/// 使用现代动画技术，提供流畅的用户体验
class AIGeneratedLoadingAnimation extends StatefulWidget {
  final String? text;
  final Color? primaryColor;
  final Color? secondaryColor;
  final double size;

  const AIGeneratedLoadingAnimation({
    super.key,
    this.text,
    this.primaryColor,
    this.secondaryColor,
    this.size = 80.0,
  });

  @override
  State<AIGeneratedLoadingAnimation> createState() => _AIGeneratedLoadingAnimationState();
}

class _AIGeneratedLoadingAnimationState extends State<AIGeneratedLoadingAnimation>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late AnimationController _pulseController;
  late Animation<double> _rotationAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();

    // 主旋转控制器
    _controller = AnimationController(
      duration: const Duration(seconds: 2),
      vsync: this,
    )..repeat();

    // 脉冲控制器
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    )..repeat(reverse: true);

    // 旋转动画
    _rotationAnimation = Tween<double>(
      begin: 0,
      end: 1,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.linear,
    ));

    // 缩放动画
    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    // 脉冲动画
    _pulseAnimation = Tween<double>(
      begin: 0.3,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final primaryColor = widget.primaryColor ?? theme.primaryColor;
    final secondaryColor = widget.secondaryColor ?? theme.colorScheme.secondary;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // 主动画区域
        SizedBox(
          width: widget.size,
          height: widget.size,
          child: AnimatedBuilder(
            animation: Listenable.merge([_controller, _pulseController]),
            builder: (context, child) {
              return Stack(
                alignment: Alignment.center,
                children: [
                  // 外层脉冲圈
                  Transform.scale(
                    scale: _pulseAnimation.value * 1.5,
                    child: Container(
                      width: widget.size,
                      height: widget.size,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: primaryColor.withValues(alpha: 0.3),
                          width: 2,
                        ),
                      ),
                    ),
                  ),

                  // 中层旋转环
                  Transform.rotate(
                    angle: _rotationAnimation.value * 2 * 3.14159,
                    child: Container(
                      width: widget.size * 0.7,
                      height: widget.size * 0.7,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: LinearGradient(
                          colors: [
                            primaryColor,
                            secondaryColor,
                            primaryColor.withValues(alpha: 0.1),
                          ],
                          stops: const [0.0, 0.5, 1.0],
                        ),
                      ),
                      child: Stack(
                        children: List.generate(3, (index) {
                          return Positioned(
                            top: 2,
                            left: widget.size * 0.35 - 4,
                            child: Transform.rotate(
                              angle: (index * 2 * 3.14159 / 3) +
                                  (_rotationAnimation.value * 2 * 3.14159),
                              child: Container(
                                width: 8,
                                height: 8,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                  boxShadow: [
                                    BoxShadow(
                                      color: primaryColor.withValues(alpha: 0.3),
                                      blurRadius: 4,
                                      spreadRadius: 1,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ),
                  ),

                  // 内核食物图标
                  Transform.scale(
                    scale: _scaleAnimation.value * 0.3,
                    child: Container(
                      width: widget.size * 0.4,
                      height: widget.size * 0.4,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: primaryColor,
                        boxShadow: [
                          BoxShadow(
                            color: primaryColor.withValues(alpha: 0.3),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: const Icon(Icons.star),
                    ),
                  ),
                ],
              );
            },
          ),
        ),

        // 文字提示
        if (widget.text != null) ...[
          const SizedBox(height: 16),
          AnimatedBuilder(
            animation: _pulseAnimation,
            builder: (context, child) {
              return Opacity(
                opacity: _pulseAnimation.value,
                child: Text(
                  widget.text!,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: primaryColor,
                    fontWeight: FontWeight.w500,
                  ),
                  textAlign: TextAlign.center,
                ),
              );
            },
          ),
        ],
      ],
    );
  }
}

/// AI风格的按钮点击动画
class AIButtonAnimation extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Duration duration;

  const AIButtonAnimation({
    super.key,
    required this.child,
    this.onTap,
    this.duration = const Duration(milliseconds: 200),
  });

  @override
  State<AIButtonAnimation> createState() => _AIButtonAnimationState();
}

class _AIButtonAnimationState extends State<AIButtonAnimation> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => _controller.forward(),
      onTapUp: (_) {
        _controller.reverse();
        widget.onTap?.call();
      },
      onTapCancel: () => _controller.reverse(),
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: widget.child,
          );
        },
      ),
    );
  }
}

/// AI生成的粒子效果背景
class AIParticleBackground extends StatefulWidget {
  final Widget child;
  final int particleCount;
  final Color particleColor;

  const AIParticleBackground({
    super.key,
    required this.child,
    this.particleCount = 50,
    this.particleColor = Colors.white,
  });

  @override
  State<AIParticleBackground> createState() => _AIParticleBackgroundState();
}

class _AIParticleBackgroundState extends State<AIParticleBackground>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  List<Particle> particles = [];

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 10),
      vsync: this,
    )..repeat();

    // 生成粒子
    particles = List.generate(widget.particleCount, (index) => Particle());
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // 粒子层
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return CustomPaint(
              painter: ParticlePainter(
                particles: particles,
                animationValue: _controller.value,
                color: widget.particleColor,
              ),
              size: Size.infinite,
            );
          },
        ),
        // 内容层
        widget.child,
      ],
    );
  }
}

class Particle {
  double x = 0;
  double y = 0;
  double vx = 0;
  double vy = 0;
  double size = 0;
  double opacity = 0;

  Particle() {
    reset();
  }

  void reset() {
    x = (DateTime.now().millisecondsSinceEpoch % 1000) / 1000;
    y = (DateTime.now().microsecondsSinceEpoch % 1000) / 1000;
    vx = (DateTime.now().millisecondsSinceEpoch % 200 - 100) / 10000;
    vy = (DateTime.now().microsecondsSinceEpoch % 200 - 100) / 10000;
    size = 1 + (DateTime.now().millisecondsSinceEpoch % 3);
    opacity = 0.3 + (DateTime.now().microsecondsSinceEpoch % 700) / 1000;
  }
}

class ParticlePainter extends CustomPainter {
  final List<Particle> particles;
  final double animationValue;
  final Color color;

  ParticlePainter({
    required this.particles,
    required this.animationValue,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.1)
      ..style = PaintingStyle.fill;

    for (final particle in particles) {
      final x = (particle.x + particle.vx * animationValue) % 1 * size.width;
      final y = (particle.y + particle.vy * animationValue) % 1 * size.height;

      canvas.drawCircle(
        Offset(x, y),
        particle.size,
        paint..color = color.withValues(alpha: particle.opacity * 0.5),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
