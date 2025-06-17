import 'package:flutter/material.dart';
import '../../../core/models/bubble.dart';
import '../../../core/utils/performance_optimizer.dart';

/// 优化的气泡UI组件
class OptimizedBubbleWidget extends StatefulWidget {
  final Bubble bubble;
  final VoidCallback? onTap;
  final void Function(Bubble bubble, BubbleGesture gesture, {DragUpdateDetails? details})? onGesture;
  final bool isSelected;
  final double scale;

  const OptimizedBubbleWidget({
    Key? key,
    required this.bubble,
    this.onTap,
    this.onGesture,
    this.isSelected = false,
    this.scale = 1.0,
  }) : super(key: key);

  @override
  State<OptimizedBubbleWidget> createState() => _OptimizedBubbleWidgetState();
}

class _OptimizedBubbleWidgetState extends State<OptimizedBubbleWidget>
    with SingleTickerProviderStateMixin {
  
  // 使用单个动画控制器管理所有动画
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _pulseAnimation;
  late Animation<double> _rotationAnimation;
  
  // 性能优化组件
  late final PerformanceOptimizer.FrameRateLimiter _animationLimiter;
  
  // 缓存计算结果
  Color? _cachedColor;
  double? _cachedSize;
  
  @override
  void initState() {
    super.initState();
    
    // 初始化性能优化组件
    _animationLimiter = PerformanceOptimizer.FrameRateLimiter(
      minInterval: const Duration(milliseconds: 16),
    );
    
    // 单个动画控制器
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    
    // 缩放动画
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 0.5, curve: Curves.easeOut),
    ));
    
    // 脉冲动画
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.0, 1.0, curve: Curves.easeInOut),
    ));
    
    // 旋转动画
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 0.1,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: const Interval(0.5, 1.0, curve: Curves.easeInOut),
    ));
    
    // 如果气泡被选中，开始动画
    if (widget.isSelected) {
      _startSelectedAnimation();
    }
  }
  
  @override
  void didUpdateWidget(OptimizedBubbleWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // 只在选中状态改变时更新动画
    if (widget.isSelected != oldWidget.isSelected) {
      if (widget.isSelected) {
        _startSelectedAnimation();
      } else {
        _stopSelectedAnimation();
      }
    }
    
    // 清除缓存如果气泡属性改变
    if (widget.bubble.color != oldWidget.bubble.color) {
      _cachedColor = null;
    }
    if (widget.bubble.size != oldWidget.bubble.size) {
      _cachedSize = null;
    }
  }
  
  void _startSelectedAnimation() {
    _animationController.repeat(reverse: true);
  }
  
  void _stopSelectedAnimation() {
    _animationController.stop();
    _animationController.reset();
  }
  
  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }
  
  void _handleTap() {
    PerformanceOptimizer.PerformanceProfiler.startTiming('bubble_tap');
    widget.onTap?.call();
    widget.onGesture?.call(widget.bubble, BubbleGesture.tap);
    PerformanceOptimizer.PerformanceProfiler.endTiming('bubble_tap');
    
    // 播放点击动画
    _animationController.forward().then((_) {
      _animationController.reverse();
    });
  }
  
  void _handleLongPress() {
    widget.onGesture?.call(widget.bubble, BubbleGesture.longPress);
    
    // 播放长按动画
    _animationController.forward().then((_) {
      _animationController.reverse();
    });
  }
  
  // 缓存颜色计算
  Color _getBubbleColor() {
    _cachedColor ??= _calculateBubbleColor();
    return _cachedColor!;
  }
  
  Color _calculateBubbleColor() {
    switch (widget.bubble.type) {
      case BubbleType.taste:
        return Colors.orange.withOpacity(0.8);
      case BubbleType.cuisine:
        return Colors.blue.withOpacity(0.8);
      case BubbleType.ingredient:
        return Colors.green.withOpacity(0.8);
      case BubbleType.scenario:
        return Colors.purple.withOpacity(0.8);
      case BubbleType.nutrition:
        return Colors.red.withOpacity(0.8);
    }
  }
  
  // 缓存大小计算
  double _getBubbleSize() {
    _cachedSize ??= widget.bubble.size * widget.scale;
    return _cachedSize!;
  }
  
  @override
  Widget build(BuildContext context) {
    return RepaintBoundary(
      child: GestureDetector(
        onTap: _handleTap,
        onLongPress: _handleLongPress,
        onPanStart: (details) {
          widget.onGesture?.call(widget.bubble, BubbleGesture.dragStart);
        },
        onPanUpdate: (details) {
          widget.onGesture?.call(
            widget.bubble,
            BubbleGesture.dragUpdate,
            details: details,
          );
        },
        onPanEnd: (details) {
          widget.onGesture?.call(widget.bubble, BubbleGesture.dragEnd);
        },
        child: AnimatedBuilder(
          animation: _animationController,
          builder: (context, child) {
            // 使用帧率限制器控制重建频率
            if (!_animationLimiter.shouldUpdate() && _animationController.isAnimating) {
              return child ?? const SizedBox.shrink();
            }

            // 计算当前缩放和旋转值
            final currentScale = widget.isSelected ? _pulseAnimation.value : _scaleAnimation.value;
            final currentRotation = widget.isSelected ? _rotationAnimation.value : 0.0;

            // 缓存大小和颜色
            final bubbleSize = _getBubbleSize();
            final bubbleColor = _getBubbleColor();

            return Transform.scale(
              scale: currentScale,
              child: Transform.rotate(
                angle: currentRotation,
                child: Container(
                  width: bubbleSize,
                  height: bubbleSize,
                  decoration: BoxDecoration(
                    color: bubbleColor,
                    shape: BoxShape.circle,
                    boxShadow: [ // 添加阴影效果
                      BoxShadow(
                        color: Colors.black.withOpacity(0.2),
                        spreadRadius: 1,
                        blurRadius: 3,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Center(
                    child: widget.bubble.icon != null && widget.bubble.icon!.isNotEmpty
                        ? Icon(
                            IconData(int.parse(widget.bubble.icon!), fontFamily: 'MaterialIcons'),
                            size: bubbleSize * 0.6,
                            color: Colors.white,
                          )
                        : Text(
                            widget.bubble.name,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: bubbleSize * 0.3,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}

/// 轻量级气泡UI组件，用于列表等不需要复杂动画的场景
class LightweightBubbleWidget extends StatelessWidget {
  final Bubble bubble;
  final double scale;

  const LightweightBubbleWidget({
    Key? key,
    required this.bubble,
    this.scale = 1.0,
  }) : super(key: key);

  Color _calculateBubbleColor() {
    switch (bubble.type) {
      case BubbleType.taste:
        return Colors.orange.withOpacity(0.8);
      case BubbleType.cuisine:
        return Colors.blue.withOpacity(0.8);
      case BubbleType.ingredient:
        return Colors.green.withOpacity(0.8);
      case BubbleType.scenario:
        return Colors.purple.withOpacity(0.8);
      case BubbleType.nutrition:
        return Colors.red.withOpacity(0.8);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bubbleSize = bubble.size * scale;
    final bubbleColor = _calculateBubbleColor();

    return Container(
      width: bubbleSize,
      height: bubbleSize,
      decoration: BoxDecoration(
        color: bubbleColor,
        shape: BoxShape.circle,
      ),
      child: Center(
        child: bubble.icon != null && bubble.icon!.isNotEmpty
            ? Icon(
                IconData(int.parse(bubble.icon!), fontFamily: 'MaterialIcons'),
                size: bubbleSize * 0.6,
                color: Colors.white,
              )
            : Text(
                bubble.name,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: bubbleSize * 0.3,
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }
}