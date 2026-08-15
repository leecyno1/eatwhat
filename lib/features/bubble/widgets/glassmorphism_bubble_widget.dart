import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:auto_size_text/auto_size_text.dart';
import 'dart:ui';
import 'dart:math' as math;

import '../../../core/models/bubble.dart';
import '../../../core/theme/glassmorphism_theme.dart';

/// Glassmorphism风格气泡组件 - 现代化毛玻璃效果
/// 增强滑动反馈功能：
/// - 滑动时显示彩色指示条（喜欢=绿色，不喜欢=红色）
/// - 滑动预览时气泡旋转和缩放
/// - 未达阈值时触发回弹动画和触感反馈
class GlassmorphismBubbleWidget extends StatefulWidget {
  final Bubble bubble;
  final bool isSelected;
  final int gradientIndex;
  final VoidCallback? onTap;
  final VoidCallback? onSwipeUp;
  final VoidCallback? onSwipeDown;
  final VoidCallback? onSwipeLeft;
  final VoidCallback? onSwipeRight;
  final VoidCallback? onLongPress;
  final bool enableHapticFeedback;

  const GlassmorphismBubbleWidget({
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
    this.enableHapticFeedback = true,
  });

  @override
  State<GlassmorphismBubbleWidget> createState() => _GlassmorphismBubbleWidgetState();
}

class _GlassmorphismBubbleWidgetState extends State<GlassmorphismBubbleWidget>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _glowController;
  late AnimationController _rotationController;
  late AnimationController _floatController;
  late AnimationController _pulseController;

  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _floatAnimation;
  late Animation<double> _pulseAnimation;

  Offset? _panStart;
  bool _isPanning = false;

  // 滑动反馈相关状态
  Offset _dragOffset = Offset.zero;
  double _swipeProgress = 0.0; // 滑动进度 0.0 - 1.0
  bool _showLikeIndicator = false; // 显示喜欢指示器
  bool _showDislikeIndicator = false; // 显示不喜欢指示器
  double _previewRotation = 0.0; // 预览旋转角度
  double _previewScale = 1.0; // 预览缩放

  // 气泡大小配置
  static const double minSize = 80.0;
  static const double maxSize = 120.0;
  static const double selectedScale = 1.2;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    // 缩放动画
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: selectedScale,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
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

    // 旋转动画
    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 1200),
      vsync: this,
    );
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 0.05,
    ).animate(CurvedAnimation(
      parent: _rotationController,
      curve: Curves.elasticOut,
    ));

    // 浮动动画
    _floatController = AnimationController(
      duration: const Duration(milliseconds: 3000),
      vsync: this,
    );
    _floatAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _floatController,
      curve: Curves.easeInOut,
    ));

    // 脉冲动画
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    // 启动动画
    _startAnimations();
  }

  void _startAnimations() {
    _floatController.repeat(reverse: true);
    _pulseController.repeat(reverse: true);

    if (widget.isSelected) {
      _glowController.repeat(reverse: true);
      _rotationController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(GlassmorphismBubbleWidget oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (widget.isSelected != oldWidget.isSelected) {
      if (widget.isSelected) {
        _scaleController.forward();
        _glowController.repeat(reverse: true);
        _rotationController.repeat(reverse: true);
        if (widget.enableHapticFeedback) {
          HapticFeedback.mediumImpact();
        }
      } else {
        _scaleController.reverse();
        _glowController.stop();
        _rotationController.stop();
      }
    }
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _glowController.dispose();
    _rotationController.dispose();
    _floatController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([
        _scaleController,
        _glowController,
        _rotationController,
        _floatController,
        _pulseController,
      ]),
      builder: (context, child) {
        // 计算预览时的总缩放
        final previewScaleValue = _pulseAnimation.value *
            (widget.isSelected ? _scaleAnimation.value : 1.0) *
            _previewScale;

        return Stack(
          children: [
            // 滑动方向指示器 - 顶部喜欢指示（绿色条）
            if (_showLikeIndicator)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 100),
                  height: 6,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.green.withValues(alpha: (_swipeProgress * 0.8).clamp(0.0, 0.8)),
                        Colors.green.withValues(alpha: 0.0),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.green.withValues(alpha: _swipeProgress * 0.5),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              ),

            // 滑动方向指示器 - 底部不喜欢指示（红色条）
            if (_showDislikeIndicator)
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 100),
                  height: 6,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        Colors.red.withValues(alpha: (_swipeProgress * 0.8).clamp(0.0, 0.8)),
                        Colors.red.withValues(alpha: 0.0),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.red.withValues(alpha: _swipeProgress * 0.5),
                        blurRadius: 8,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                ),
              ),

            // 主内容 - 带滑动偏移和旋转变换
            Transform.translate(
              offset: _dragOffset,
              child: Transform.scale(
                scale: previewScaleValue,
                child: Transform.rotate(
                  angle: _rotationAnimation.value + _previewRotation,
                  child: _buildBubbleContent(),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBubbleContent() {
    final size = _getBubbleSize();

    // 保留浮动动画效果
    final floatOffset = Offset(0, math.sin(_floatAnimation.value * 2 * math.pi) * 5);

    return GestureDetector(
      onTap: widget.onTap,
      onLongPress: widget.onLongPress,
      onPanStart: _onPanStart,
      onPanUpdate: _onPanUpdate,
      onPanEnd: _onPanEnd,
      child: Transform.translate(
        offset: floatOffset,
        child: Container(
          width: size,
          height: size,
          child: Stack(
            children: [
              // 背景毛玻璃效果
              _buildGlassBackground(),

              // 发光效果
              if (widget.isSelected) _buildGlowEffect(),

              // 内容
              _buildBubbleContentInner(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGlassBackground() {
    return ClipRRect(
      borderRadius: BorderRadius.circular(100.r),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
        child: Container(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              colors: _getBubbleColors(),
              center: Alignment.topLeft,
              radius: 1.2,
            ),
            borderRadius: BorderRadius.circular(100.r),
            border: Border.all(
              color: Colors.white.withValues(alpha: 0.3),
              width: 2,
            ),
            boxShadow: [
              BoxShadow(
                color: _getBubbleColors().first.withValues(alpha: 0.3),
                blurRadius: 20,
                spreadRadius: 2,
              ),
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: const Offset(0, 5),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGlowEffect() {
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(100.r),
            boxShadow: [
              BoxShadow(
                color: _getBubbleColors().first.withValues(alpha: _glowAnimation.value * 0.6),
                blurRadius: 30,
                spreadRadius: 5,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildBubbleContentInner() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // 图标
          Icon(
            _getBubbleIcon(),
            size: 24.sp,
            color: Colors.white,
          ),
          SizedBox(height: 4.h),

          // 文字
          AutoSizeText(
            widget.bubble.name,
            style: TextStyle(
              color: Colors.white,
              fontSize: 12.sp,
              fontWeight: FontWeight.w600,
              shadows: [
                Shadow(
                  color: Colors.black.withValues(alpha: 0.3),
                  offset: const Offset(0, 1),
                  blurRadius: 2,
                ),
              ],
            ),
            maxLines: 2,
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  double _getBubbleSize() {
    final baseSize = widget.bubble.size ?? 100.0;
    return (baseSize * 0.8).clamp(minSize, maxSize);
  }

  List<Color> _getBubbleColors() {
    final gradients = [
      GlassmorphismTheme.primaryGradients,
      GlassmorphismTheme.secondaryGradients,
      GlassmorphismTheme.accentGradients,
      GlassmorphismTheme.warmGradients,
    ];

    final index = widget.gradientIndex % gradients.length;
    return gradients[index];
  }

  IconData _getBubbleIcon() {
    // 根据气泡类型返回对应图标
    switch (widget.bubble.type) {
      case BubbleType.spicy:
        return Icons.local_fire_department;
      case BubbleType.sweet:
        return Icons.cake;
      case BubbleType.sour:
        return Icons.emoji_food_beverage;
      case BubbleType.bitter:
        return Icons.coffee;
      case BubbleType.salty:
        return Icons.water_drop;
      case BubbleType.umami:
        return Icons.restaurant;
      default:
        return Icons.favorite;
    }
  }

  void _onPanStart(DragStartDetails details) {
    _panStart = details.localPosition;
    _isPanning = true;
    _dragOffset = Offset.zero;
  }

  void _onPanUpdate(DragUpdateDetails details) {
    if (!_isPanning || _panStart == null) return;

    setState(() {
      _dragOffset = details.localPosition - _panStart!;
    });

    // 计算滑动进度 (0.0 - 1.0)
    final progress = (_dragOffset.dy.abs() / 200).clamp(0.0, 1.0);

    setState(() {
      _swipeProgress = progress;
    });

    // 滑动方向指示 - 实时更新
    if (_dragOffset.dy < -50) {
      // 上滑 = 喜欢
      setState(() {
        _showLikeIndicator = true;
        _showDislikeIndicator = false;
        _previewRotation = (_dragOffset.dy / 1000).clamp(-0.15, 0.0);
        _previewScale = 1.0 + (progress * 0.05); // 喜欢放大1.05倍
      });
    } else if (_dragOffset.dy > 50) {
      // 下滑 = 不喜欢
      setState(() {
        _showDislikeIndicator = true;
        _showLikeIndicator = false;
        _previewRotation = (_dragOffset.dy / 1000).clamp(0.0, 0.15);
        _previewScale = 1.0 - (progress * 0.05); // 不喜欢缩小0.95倍
      });
    } else {
      setState(() {
        _showLikeIndicator = false;
        _showDislikeIndicator = false;
        _previewRotation = 0.0;
        _previewScale = 1.0;
      });
    }

    debugPrint('[GlassmorphismBubbleWidget] Swipe progress: ${progress.toStringAsFixed(2)}, offset: $_dragOffset');
  }

  void _onPanEnd(DragEndDetails details) {
    if (!_isPanning || _panStart == null) return;

    final delta = _dragOffset;
    final threshold = 50.0;

    // 滑动未达阈值，取消操作
    if (delta.dy.abs() < threshold && delta.dx.abs() < threshold) {
      debugPrint('[GlassmorphismBubbleWidget] Swipe cancelled, distance: ${delta.dy.abs().toStringAsFixed(1)}');
      if (widget.enableHapticFeedback) {
        HapticFeedback.selectionClick();
      }
      _resetPosition();
      _hideSwipeIndicators();
      _isPanning = false;
      _panStart = null;
      return;
    }

    // 重置滑动状态
    _hideSwipeIndicators();
    _isPanning = false;

    // 触发滑动回调
    if (delta.dy.abs() > delta.dx.abs()) {
      if (delta.dy < 0) {
        widget.onSwipeUp?.call();
      } else {
        widget.onSwipeDown?.call();
      }
    } else {
      if (delta.dx < 0) {
        widget.onSwipeLeft?.call();
      } else {
        widget.onSwipeRight?.call();
      }
    }

    if (widget.enableHapticFeedback) {
      HapticFeedback.lightImpact();
    }
    _panStart = null;
  }

  /// 重置位置
  void _resetPosition() {
    setState(() {
      _dragOffset = Offset.zero;
      _previewScale = 1.0;
      _previewRotation = 0.0;
    });
  }

  /// 隐藏滑动指示器
  void _hideSwipeIndicators() {
    setState(() {
      _showLikeIndicator = false;
      _showDislikeIndicator = false;
      _swipeProgress = 0.0;
      _previewRotation = 0.0;
      _previewScale = 1.0;
    });
  }
}
