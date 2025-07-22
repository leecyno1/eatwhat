import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'dart:math' as math;

import '../../../core/models/physical_entity.dart';

/// 高级物理实体组件 - 商业级白色透明毛玻璃效果
class PremiumPhysicalEntityWidget extends StatefulWidget {
  final PhysicalEntity entity;
  final bool isSelected;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final double scale;
  final double glowIntensity;

  const PremiumPhysicalEntityWidget({
    super.key,
    required this.entity,
    this.isSelected = false,
    this.onTap,
    this.onLongPress,
    this.scale = 1.0,
    this.glowIntensity = 0.0,
  });

  @override
  State<PremiumPhysicalEntityWidget> createState() =>
      _PremiumPhysicalEntityWidgetState();
}

class _PremiumPhysicalEntityWidgetState
    extends State<PremiumPhysicalEntityWidget> with TickerProviderStateMixin {
  late AnimationController _hoverController;
  late AnimationController _tapController;
  late AnimationController _glowController;
  late AnimationController _floatController;

  late Animation<double> _hoverAnimation;
  late Animation<double> _tapAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _floatAnimation;

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

    // 启动浮动动画
    // _floatController.repeat(); // 禁用浮动动画

    // 根据选中状态启动发光动画
    if (widget.isSelected) {
      _glowController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(PremiumPhysicalEntityWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isSelected != oldWidget.isSelected) {
      if (widget.isSelected) {
        _glowController.repeat(reverse: true);
      } else {
        _glowController.stop();
        _glowController.reset();
      }
    }
  }

  @override
  void dispose() {
    _hoverController.dispose();
    _tapController.dispose();
    _glowController.dispose();
    _floatController.dispose();
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
      ]),
      builder: (context, child) {
        final floatOffset = 0.0; // 禁用浮动效果
        final hoverScale = 1.0 + (_hoverAnimation.value * 0.1);
        final tapScale = _tapAnimation.value;
        final glowRadius = _glowAnimation.value * 30.0;

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
                      // 外层发光效果
                      if (widget.isSelected || _isHovered)
                        Container(
                          width: size + glowRadius,
                          height: size + glowRadius,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color:
                                    widget.entity.primaryColor.withValues(alpha: 0.3),
                                blurRadius: 20.0 + glowRadius,
                                spreadRadius: 5.0,
                              ),
                            ],
                          ),
                        ),

                      // 主体毛玻璃效果
                      GlassmorphicContainer(
                        width: size,
                        height: size,
                        borderRadius: size / 2,
                        linearGradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            Colors.white.withValues(alpha: 0.2),
                            Colors.white.withValues(alpha: 0.05),
                          ],
                        ),
                        border: _isHovered ? 3.0 : 2.0,
                        borderGradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            widget.entity.primaryColor.withValues(alpha: 0.6),
                            widget.entity.secondaryColor.withValues(alpha: 0.3),
                          ],
                        ),
                        blur: 20.0,
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: RadialGradient(
                              center: Alignment.topLeft,
                              radius: 1.0,
                              colors: [
                                Colors.white.withValues(alpha: 0.1),
                                Colors.transparent,
                              ],
                            ),
                          ),
                          child: _buildEntityContent(),
                        ),
                      ),

                      // 选中状态的内发光
                      if (widget.isSelected)
                        Container(
                          width: size - 6,
                          height: size - 6,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color:
                                  widget.entity.primaryColor.withValues(alpha: 0.9),
                              width: 3.0,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color:
                                    widget.entity.primaryColor.withValues(alpha: 0.8),
                                blurRadius: 15.0,
                                spreadRadius: 2.0,
                              ),
                              BoxShadow(
                                color: Colors.white.withValues(alpha: 0.5),
                                blurRadius: 5.0,
                                spreadRadius: -2.0,
                              ),
                            ],
                          ),
                        ),

                      // 选中状态指示器
                      if (widget.isSelected)
                        Positioned(
                          top: -5,
                          right: -5,
                          child: Container(
                            width: 20.w,
                            height: 20.w,
                            decoration: BoxDecoration(
                              color: Colors.green,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: Colors.white,
                                width: 2,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.green.withValues(alpha: 0.5),
                                  blurRadius: 8.0,
                                  spreadRadius: 1.0,
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 12.sp,
                            ),
                          ),
                        ),
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

  Widget _buildEntityContent() {
    return Container(
      padding: EdgeInsets.all(8.w),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 主表情符号 - 放大显示
          Expanded(
            flex: 3,
            child: Center(
              child: Text(
                widget.entity.emoji,
                style: TextStyle(
                  fontSize: (widget.entity.radius * 0.8).sp,
                  height: 1.0,
                ),
              ),
            ),
          ),

          // 实体名称
          Expanded(
            flex: 1,
            child: Center(
              child: Text(
                widget.entity.name,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 11.sp,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                  shadows: [
                    Shadow(
                      color: Colors.black.withValues(alpha: 0.8),
                      offset: const Offset(0, 1),
                      blurRadius: 3,
                    ),
                  ],
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
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
