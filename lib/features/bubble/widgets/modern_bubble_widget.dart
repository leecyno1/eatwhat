import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:auto_size_text/auto_size_text.dart';

import '../../../core/models/bubble.dart';
import '../../../core/theme/modern_theme.dart';

/// 现代化气泡组件 - 支持完整手势交互
class ModernBubbleWidget extends StatefulWidget {
  final Bubble bubble;
  final bool isSelected;
  final int gradientIndex;
  final VoidCallback? onTap;
  final VoidCallback? onSwipeUp;
  final VoidCallback? onSwipeDown;
  final VoidCallback? onSwipeLeft;
  final VoidCallback? onSwipeRight;
  final VoidCallback? onLongPress;

  const ModernBubbleWidget({
    super.key,
    required this.bubble,
    this.isSelected = false,
    this.gradientIndex = 0,
    this.onTap,
    this.onSwipeUp,
    this.onSwipeDown,
    this.onSwipeLeft,
    this.onSwipeRight,
    this.onLongPress,
  });

  @override
  State<ModernBubbleWidget> createState() => _ModernBubbleWidgetState();
}

class _ModernBubbleWidgetState extends State<ModernBubbleWidget> with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _glowController;
  late AnimationController _rotationController;

  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _rotationAnimation;

  Offset? _panStart;
  bool _isPanning = false;

  @override
  void initState() {
    super.initState();

    // 缩放动画
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeInOut,
    ));

    // 发光动画
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _glowAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ));

    // 旋转动画
    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 0.1,
    ).animate(CurvedAnimation(
      parent: _rotationController,
      curve: Curves.elasticOut,
    ));

    // 禁用发光动画以解决乱窜问题
    /*
    if (widget.isSelected) {
      _glowController.repeat(reverse: true);
    }
    */
  }

  @override
  void didUpdateWidget(ModernBubbleWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    // 禁用动画更新
    // if (widget.isSelected != oldWidget.isSelected) {
    //   if (widget.isSelected) {
    //     _glowController.repeat(reverse: true);
    //     _rotationController.forward();
    //   } else {
    //     _glowController.stop();
    //     _glowController.reset();
    //     _rotationController.reverse();
    //   }
    // }
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _glowController.dispose();
    _rotationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final bubbleSize = widget.bubble.size.clamp(48.0, 120.0); // 放宽下限以适配更多口味
    final gradient = ModernTheme.getBubbleGradient(widget.gradientIndex);

    return AnimatedBuilder(
      animation: Listenable.merge([_scaleAnimation, _glowAnimation, _rotationAnimation]),
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: Transform.rotate(
            angle: _rotationAnimation.value,
            child: GestureDetector(
              onTapDown: (_) {
                _scaleController.forward();
                HapticFeedback.lightImpact();
              },
              onTapUp: (_) {
                _scaleController.reverse();
                widget.onTap?.call();
              },
              onTapCancel: () {
                _scaleController.reverse();
              },
              onLongPress: () {
                HapticFeedback.heavyImpact();
                widget.onLongPress?.call();
              },
              onPanStart: (details) {
                _panStart = details.localPosition;
                _isPanning = true;
              },
              onPanUpdate: (details) {
                // 可以在这里添加实时拖拽效果
              },
              onPanEnd: (details) {
                if (_panStart == null || !_isPanning) return;

                _isPanning = false;
                final velocity = details.velocity.pixelsPerSecond;
                const threshold = 200.0; // 降低阈值使手势更敏感

                // 根据速度大小判断手势方向
                if (velocity.dx.abs() > velocity.dy.abs()) {
                  // 水平手势优先
                  if (velocity.dx > threshold) {
                    HapticFeedback.lightImpact();
                    widget.onSwipeRight?.call();
                    return;
                  } else if (velocity.dx < -threshold) {
                    HapticFeedback.lightImpact();
                    widget.onSwipeLeft?.call();
                    return;
                  }
                }

                // 垂直手势
                if (velocity.dy.abs() > threshold) {
                  if (velocity.dy < 0) {
                    HapticFeedback.lightImpact();
                    widget.onSwipeUp?.call();
                  } else {
                    HapticFeedback.lightImpact();
                    widget.onSwipeDown?.call();
                  }
                }

                _panStart = null;
              },
              onPanCancel: () {
                _isPanning = false;
                _panStart = null;
              },
              child: SizedBox(
                width: bubbleSize,
                height: bubbleSize,
                child: Stack(
                  children: [
                    // 发光效果
                    if (widget.isSelected)
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: gradient.colors.first
                                    .withValues(alpha: _glowAnimation.value * 0.5),
                                blurRadius: 20.0 + (_glowAnimation.value * 15.0),
                                spreadRadius: 5.0 + (_glowAnimation.value * 10.0),
                              ),
                            ],
                          ),
                        ),
                      ),

                    // 主气泡容器
                    Positioned.fill(
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: gradient,
                          boxShadow: [
                            BoxShadow(
                              color: gradient.colors.first.withValues(alpha: 0.3),
                              blurRadius: widget.isSelected ? 20 : 10,
                              spreadRadius: widget.isSelected ? 3 : 1,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: widget.isSelected
                                  ? Colors.white.withValues(alpha: 0.8)
                                  : Colors.white.withValues(alpha: 0.3),
                              width: widget.isSelected ? 3 : 1,
                            ),
                          ),
                          child: Center(
                            child: Padding(
                              padding: EdgeInsets.all(6.w),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  // 气泡图标
                                  if (widget.bubble.icon != null)
                                    Text(
                                      widget.bubble.icon!,
                                      style: TextStyle(
                                        fontSize: (bubbleSize * 0.25).sp,
                                      ),
                                    )
                                  else
                                    Icon(
                                      _getBubbleIcon(widget.bubble.type),
                                      size: (bubbleSize * 0.3).w,
                                      color: Colors.white,
                                    ),

                                  SizedBox(height: 1.h),

                                  // 气泡文字
                                  AutoSizeText(
                                    widget.bubble.name,
                                    style: TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600,
                                      fontSize: 12.sp,
                                      shadows: [
                                        Shadow(
                                          color: Colors.black.withValues(alpha: 0.3),
                                          offset: const Offset(0, 1),
                                          blurRadius: 2,
                                        ),
                                      ],
                                    ),
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    minFontSize: 8,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    // 选中状态指示器
                    if (widget.isSelected)
                      Positioned(
                        top: -5.h,
                        right: -5.w,
                        child: Container(
                          width: 24.w,
                          height: 24.w,
                          decoration: BoxDecoration(
                            color: ModernTheme.accentColor,
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: Colors.white,
                              width: 2,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: ModernTheme.accentColor.withValues(alpha: 0.5),
                                blurRadius: 8,
                                spreadRadius: 2,
                              ),
                            ],
                          ),
                          child: Icon(
                            Icons.check,
                            color: Colors.white,
                            size: 14.w,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  IconData _getBubbleIcon(BubbleType type) {
    switch (type) {
      case BubbleType.taste:
        return Icons.restaurant;
      case BubbleType.cuisine:
        return Icons.public;
      case BubbleType.ingredient:
        return Icons.grass;
      case BubbleType.scenario:
        return Icons.schedule;
      case BubbleType.nutrition:
        return Icons.fitness_center;
      case BubbleType.spicy:
        return Icons.local_fire_department;
      case BubbleType.sweet:
        return Icons.cake;
      case BubbleType.sour:
        return Icons.eco;
      case BubbleType.bitter:
        return Icons.medical_services;
      case BubbleType.salty:
        return Icons.water_drop;
      case BubbleType.umami:
        return Icons.restaurant_menu;
    }
  }
}
