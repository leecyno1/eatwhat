import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:math' as math;

import '../../../core/models/physical_entity.dart';

/// 文字物理实体组件 - 使用文字替代图标的高级设计
class TextPhysicalEntityWidget extends StatefulWidget {
  final PhysicalEntity entity;
  final bool isSelected;
  final bool isLiked;
  final bool isDisliked;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double scale;
  final double glowIntensity;

  const TextPhysicalEntityWidget({
    super.key,
    required this.entity,
    this.isSelected = false,
    this.isLiked = false,
    this.isDisliked = false,
    this.onTap,
    this.onLongPress,
    this.scale = 1.0,
    this.glowIntensity = 0.0,
  });

  @override
  State<TextPhysicalEntityWidget> createState() => _TextPhysicalEntityWidgetState();
}

class _TextPhysicalEntityWidgetState extends State<TextPhysicalEntityWidget>
    with TickerProviderStateMixin {
  late AnimationController _hoverController;
  late AnimationController _tapController;
  late AnimationController _glowController;
  late AnimationController _floatController;
  late AnimationController _specialEffectController;
  
  late Animation<double> _hoverAnimation;
  late Animation<double> _tapAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _floatAnimation;
  late Animation<double> _specialEffectAnimation;
  
  bool _isHovered = false;
  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    
    // 悬停动画
    _hoverController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _hoverAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _hoverController,
      curve: Curves.easeOutCubic,
    ));
    
    // 点击动画
    _tapController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _tapAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _tapController,
      curve: Curves.easeOutCubic,
    ));
    
    // 发光动画
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _glowAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ));
    
    // 浮动动画
    _floatController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );
    _floatAnimation = Tween<double>(
      begin: 0.0,
      end: 2 * math.pi,
    ).animate(CurvedAnimation(
      parent: _floatController,
      curve: Curves.linear,
    ));
    
    // 特殊效果动画（如热气、闪光等）
    _specialEffectController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );
    _specialEffectAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _specialEffectController,
      curve: Curves.easeInOut,
    ));
    
    // 禁用所有无限循环动画以解决乱窜问题
    // _floatController.repeat();
    // _specialEffectController.repeat();
    
    // 禁用发光动画
    /*
    if (widget.isSelected) {
      _glowController.repeat(reverse: true);
    }
    */
  }

  @override
  void didUpdateWidget(TextPhysicalEntityWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // 禁用动画更新
    /*
    if (widget.isSelected != oldWidget.isSelected) {
      if (widget.isSelected) {
        _glowController.repeat(reverse: true);
      } else {
        _glowController.stop();
        _glowController.reset();
      }
    }
    */
  }

  @override
  void dispose() {
    _hoverController.dispose();
    _tapController.dispose();
    _glowController.dispose();
    _floatController.dispose();
    _specialEffectController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.entity.radius * 2 * widget.scale;
    
    return AnimatedBuilder(
      animation: Listenable.merge([
        _hoverAnimation,
        _tapAnimation,
        _glowAnimation,
        _floatAnimation,
        _specialEffectAnimation,
      ]),
      builder: (context, child) {
        final floatOffset = 0.0; // 禁用浮动效果
        final hoverScale = 1.0; // 禁用悬停缩放
        final tapScale = _tapAnimation.value; // 保留点击反馈
        final glowRadius = 0.0; // 禁用发光效果
        
        return Transform.translate(
          offset: Offset(0, floatOffset),
          child: Transform.scale(
            scale: hoverScale * tapScale,
            child: GestureDetector(
              onTap: _handleTap,
              onLongPress: _handleLongPress,
              onTapDown: (_) => _handleTapDown(),
              onTapUp: (_) => _handleTapUp(),
              onTapCancel: _handleTapUp,
              child: MouseRegion(
                onEnter: (_) => _handleHover(true),
                onExit: (_) => _handleHover(false),
                child: SizedBox(
                  width: size,
                  height: size,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // 特殊效果层（热气、闪光等）
                      _buildSpecialEffects(),
                      
                      // 外层发光效果
                      if (widget.isSelected || _isHovered || widget.isLiked)
                        Container(
                          width: size + glowRadius,
                          height: size + glowRadius,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: _getGlowColor().withValues(alpha: 0.4),
                                blurRadius: 25.0 + glowRadius,
                                spreadRadius: 8.0,
                              ),
                            ],
                          ),
                        ),
                      
                      // 主体文字背景
                      _buildTextBackground(),
                      
                      // 文字内容
                      _buildTextContent(),
                      
                      // 状态指示器
                      if (widget.isLiked)
                        _buildStatusIndicator(Icons.thumb_up, Colors.green),
                      if (widget.isDisliked)
                        _buildStatusIndicator(Icons.thumb_down, Colors.red),
                      if (widget.isSelected && !widget.isLiked && !widget.isDisliked)
                        _buildStatusIndicator(Icons.check, Colors.blue),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSpecialEffects() {
    // 根据不同口味添加特殊效果
    switch (widget.entity.name) {
      case '辣':
        return _buildHeatEffect();
      case '甜':
        return _buildSparkleEffect();
      case '鲜':
        return _buildWaveEffect();
      case '香':
        return _buildAromaEffect();
      default:
        return const SizedBox();
    }
  }

  Widget _buildHeatEffect() {
    // 辣椒的热气效果
    return Positioned.fill(
      child: CustomPaint(
        painter: HeatEffectPainter(_specialEffectAnimation.value),
      ),
    );
  }

  Widget _buildSparkleEffect() {
    // 甜味的闪光效果
    return Positioned.fill(
      child: CustomPaint(
        painter: SparkleEffectPainter(_specialEffectAnimation.value),
      ),
    );
  }

  Widget _buildWaveEffect() {
    // 鲜味的波纹效果
    return Positioned.fill(
      child: CustomPaint(
        painter: WaveEffectPainter(_specialEffectAnimation.value),
      ),
    );
  }

  Widget _buildAromaEffect() {
    // 香味的芳香效果
    return Positioned.fill(
      child: CustomPaint(
        painter: AromaEffectPainter(_specialEffectAnimation.value),
      ),
    );
  }

  Widget _buildTextBackground() {
    return Container(
      width: widget.entity.radius * 2,
      height: widget.entity.radius * 2,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          center: Alignment.topLeft,
          radius: 1.2,
          colors: [
            Colors.white.withValues(alpha: 0.3),
            Colors.white.withValues(alpha: 0.1),
            Colors.transparent,
          ],
        ),
        border: Border.all(
          color: _getBorderColor(),
          width: widget.isSelected ? 3.0 : 2.0,
        ),
        boxShadow: [
          BoxShadow(
            color: _getShadowColor(),
            blurRadius: 15.0,
            spreadRadius: 2.0,
          ),
        ],
      ),
    );
  }

  Widget _buildTextContent() {
    return Text(
      widget.entity.emoji,
      style: TextStyle(
        fontSize: _getTextSize(),
        fontWeight: FontWeight.bold,
        color: _getTextColor(),
        fontFamily: _getFontFamily(),
        shadows: _getTextShadows(),
      ),
    );
  }

  Widget _buildStatusIndicator(IconData icon, Color color) {
    return Positioned(
      top: -8,
      right: -8,
      child: Container(
        width: 24.w,
        height: 24.w,
        decoration: BoxDecoration(
          color: color,
          shape: BoxShape.circle,
          border: Border.all(
            color: Colors.white,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: color.withValues(alpha: 0.5),
              blurRadius: 8.0,
              spreadRadius: 1.0,
            ),
          ],
        ),
        child: Icon(
          icon,
          color: Colors.white,
          size: 14.sp,
        ),
      ),
    );
  }

  Color _getGlowColor() {
    if (widget.isLiked) return Colors.green;
    if (widget.isDisliked) return Colors.red;
    return widget.entity.primaryColor;
  }

  Color _getBorderColor() {
    if (widget.isLiked) return Colors.green.withValues(alpha: 0.8);
    if (widget.isDisliked) return Colors.red.withValues(alpha: 0.8);
    return widget.entity.primaryColor.withValues(alpha: 0.6);
  }

  Color _getShadowColor() {
    return widget.entity.primaryColor.withValues(alpha: 0.3);
  }

  Color _getTextColor() {
    // 根据不同口味返回不同颜色
    switch (widget.entity.name) {
      case '辣':
        return const Color(0xFFFF4444);
      case '酸':
        return const Color(0xFFFFD700);
      case '甜':
        return const Color(0xFFFFB347);
      case '咸':
        return const Color(0xFF888888);
      case '鲜':
        return const Color(0xFF4A90E2);
      case '香':
        return const Color(0xFF228B22);
      default:
        return widget.entity.primaryColor;
    }
  }

  double _getTextSize() {
    // 根据文字长度调整大小
    final textLength = widget.entity.emoji.length;
    if (textLength <= 1) {
      return (widget.entity.radius * 0.8).sp;
    } else if (textLength <= 2) {
      return (widget.entity.radius * 0.6).sp;
    } else {
      return (widget.entity.radius * 0.4).sp;
    }
  }

  String? _getFontFamily() {
    // 可以根据不同口味使用不同字体
    switch (widget.entity.name) {
      case '辣':
        return null; // 使用默认字体，但加粗
      case '甜':
        return null; // 可以使用圆润字体
      default:
        return null;
    }
  }

  List<Shadow> _getTextShadows() {
    final baseColor = _getTextColor();
    return [
      Shadow(
        color: baseColor.withValues(alpha: 0.5),
        offset: const Offset(2, 2),
        blurRadius: 4,
      ),
      Shadow(
        color: Colors.black.withValues(alpha: 0.3),
        offset: const Offset(1, 1),
        blurRadius: 2,
      ),
    ];
  }

  void _handleTap() {
    HapticFeedback.lightImpact();
    widget.onTap?.call();
  }

  void _handleLongPress() {
    HapticFeedback.mediumImpact();
    widget.onLongPress?.call();
  }

  void _handleTapDown() {
    setState(() {
      _isPressed = true;
    });
    _tapController.forward();
  }

  void _handleTapUp() {
    setState(() {
      _isPressed = false;
    });
    _tapController.reverse();
  }

  void _handleHover(bool isHovered) {
    setState(() {
      _isHovered = isHovered;
    });
    
    if (isHovered) {
      _hoverController.forward();
    } else {
      _hoverController.reverse();
    }
  }
}

// 热气效果绘制器
class HeatEffectPainter extends CustomPainter {
  final double progress;

  HeatEffectPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.red.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;

    final center = Offset(size.width / 2, size.height / 2);
    
    // 绘制上升的热气波浪
    for (int i = 0; i < 3; i++) {
      final waveOffset = (progress + i * 0.3) % 1.0;
      final y = center.dy - (waveOffset * size.height * 0.6);
      final amplitude = 8.0 * (1.0 - waveOffset);
      
      final path = Path();
      path.moveTo(center.dx - amplitude, y);
      path.quadraticBezierTo(
        center.dx,
        y - 10,
        center.dx + amplitude,
        y,
      );
      
      canvas.drawPath(path, paint..color = Colors.red.withValues(alpha: 0.3 * (1.0 - waveOffset)));
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// 闪光效果绘制器
class SparkleEffectPainter extends CustomPainter {
  final double progress;

  SparkleEffectPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.yellow.withValues(alpha: 0.8)
      ..style = PaintingStyle.fill;

    final center = Offset(size.width / 2, size.height / 2);
    final random = math.Random(42); // 固定种子确保一致性

    // 绘制闪光点
    for (int i = 0; i < 8; i++) {
      final angle = (i / 8) * 2 * math.pi + progress * 2 * math.pi;
      final radius = 20 + math.sin(progress * 4 + i) * 10;
      final sparkleCenter = Offset(
        center.dx + math.cos(angle) * radius,
        center.dy + math.sin(angle) * radius,
      );
      
      final sparkleSize = 2 + math.sin(progress * 6 + i) * 1.5;
      canvas.drawCircle(sparkleCenter, sparkleSize, paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// 波纹效果绘制器
class WaveEffectPainter extends CustomPainter {
  final double progress;

  WaveEffectPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.blue.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;

    final center = Offset(size.width / 2, size.height / 2);
    
    // 绘制扩散的波纹
    for (int i = 0; i < 3; i++) {
      final waveRadius = (progress + i * 0.3) % 1.0 * size.width * 0.6;
      final opacity = 1.0 - ((progress + i * 0.3) % 1.0);
      
      canvas.drawCircle(
        center,
        waveRadius,
        paint..color = Colors.blue.withValues(alpha: 0.4 * opacity),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}

// 芳香效果绘制器
class AromaEffectPainter extends CustomPainter {
  final double progress;

  AromaEffectPainter(this.progress);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.green.withValues(alpha: 0.3)
      ..style = PaintingStyle.fill;

    final center = Offset(size.width / 2, size.height / 2);
    
    // 绘制螺旋上升的芳香线条
    for (int i = 0; i < 4; i++) {
      final spiralProgress = (progress + i * 0.25) % 1.0;
      final path = Path();
      
      for (double t = 0; t <= spiralProgress; t += 0.1) {
        final angle = t * 4 * math.pi;
        final radius = 15 * (1.0 - t);
        final y = center.dy - t * size.height * 0.8;
        final x = center.dx + math.cos(angle) * radius;
        
        if (t == 0) {
          path.moveTo(x, y);
        } else {
          path.lineTo(x, y);
        }
      }
      
      canvas.drawPath(
        path,
        paint
          ..style = PaintingStyle.stroke
          ..strokeWidth = 3.0
          ..color = Colors.green.withValues(alpha: 0.3 * (1.0 - spiralProgress)),
      );
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}