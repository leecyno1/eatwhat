import 'package:flutter/material.dart';
import '../../../core/models/bubble.dart';

/// 气泡UI组件
class BubbleWidget extends StatefulWidget {
  final Bubble bubble;
  final VoidCallback? onTap;
  final void Function(Bubble bubble, BubbleGesture gesture, {DragUpdateDetails? details})? onGesture;
  final bool isSelected;
  final double scale;

  const BubbleWidget({
    Key? key,
    required this.bubble,
    this.onTap,
    this.onGesture,
    this.isSelected = false,
    this.scale = 1.0,
  }) : super(key: key);

  @override
  State<BubbleWidget> createState() => _BubbleWidgetState();
}

class _BubbleWidgetState extends State<BubbleWidget>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _rotationController;
  late AnimationController _pulseController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    
    // 缩放动画控制器
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));

    // 旋转动画控制器
    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 0.1,
    ).animate(CurvedAnimation(
      parent: _rotationController,
      curve: Curves.easeInOut,
    ));

    // 脉冲动画控制器
    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.3, // 放大脉冲动画的幅度
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.easeInOut,
    ));

    // 如果气泡被选中，开始脉冲动画
    if (widget.isSelected) {
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(BubbleWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // 处理选中状态变化
    if (widget.isSelected != oldWidget.isSelected) {
      if (widget.isSelected) {
        _scaleController.forward();
        _pulseController.repeat(reverse: true);
      } else {
        _scaleController.reverse();
        _pulseController.stop();
        _pulseController.reset();
      }
    }
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _rotationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  void _handleTap() {
    widget.onTap?.call();
    widget.onGesture?.call(widget.bubble, BubbleGesture.tap);
    
    // 播放点击动画
    _scaleController.forward().then((_) {
      _scaleController.reverse();
    });
  }

  void _handleLongPress() {
    widget.onGesture?.call(widget.bubble, BubbleGesture.longPress);
    
    // 播放长按动画
    _rotationController.forward().then((_) {
      _rotationController.reverse();
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      onLongPress: _handleLongPress,
      onPanStart: (details) {
        widget.onGesture?.call(widget.bubble, BubbleGesture.dragStart);
      },
      onVerticalDragUpdate: (details) {
        // 处理上下滑动
        if (details.primaryDelta! < -5) { // 上滑
          widget.onGesture?.call(widget.bubble, BubbleGesture.swipeUp);
        } else if (details.primaryDelta! > 5) { // 下滑
          widget.onGesture?.call(widget.bubble, BubbleGesture.swipeDown);
        }
        // 处理拖拽更新，直接传递原始的details
        widget.onGesture?.call(widget.bubble, BubbleGesture.dragUpdate, details: details);
      },
      onPanEnd: (details) {
        widget.onGesture?.call(widget.bubble, BubbleGesture.dragEnd);
      },
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _scaleAnimation,
          _rotationAnimation,
          _pulseAnimation,
        ]),
        builder: (context, child) {
          final scale = widget.scale * 
                       _scaleAnimation.value * 
                       (widget.isSelected ? _pulseAnimation.value : 1.0) * 1.2; // 整体放大气泡
          
          // 更新气泡的实际显示大小，用于碰撞检测
          widget.bubble.currentDisplaySize = widget.bubble.size * scale;

          return Transform.scale(
            scale: scale,
            child: Transform.rotate(
              angle: _rotationAnimation.value,
              child: Container(
                width: widget.bubble.size,
                height: widget.bubble.size,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.bubble.color.withOpacity(0.8), // 增加透明感
                  border: widget.isSelected
                      ? Border.all(
                          color: Colors.white,
                          width: 3.0,
                        )
                      : null,
                  boxShadow: [
                    BoxShadow(
                      color: widget.bubble.color.withOpacity(0.3), // 使用 withOpacity 替代 withValues
                      blurRadius: widget.isSelected ? 15.0 : 8.0,
                      spreadRadius: widget.isSelected ? 3.0 : 1.0,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (widget.bubble.icon != null)
                      Text(
                        widget.bubble.icon!,
                        style: TextStyle(
                          fontSize: widget.bubble.size * 0.3,
                        ),
                      ),
                    const SizedBox(height: 2),
                    Text(
                      widget.bubble.name,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: widget.bubble.size * 0.15,
                        fontWeight: FontWeight.bold,
                        shadows: const [
                          Shadow(
                            color: Colors.black26,
                            offset: Offset(1, 1),
                            blurRadius: 2,
                          ),
                        ],
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

}

/// 气泡类型指示器
class BubbleTypeIndicator extends StatelessWidget {
  final BubbleType type;
  final double size;

  const BubbleTypeIndicator({
    Key? key,
    required this.type,
    this.size = 24,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: _getTypeColor(type),
      ),
      child: Icon(
        _getTypeIcon(type),
        size: size * 0.6,
        color: Colors.white,
      ),
    );
  }

  Color _getTypeColor(BubbleType type) {
    // 根据视觉设计规范调整颜色
    switch (type) {
      case BubbleType.taste: // 口味 - 暖橙色
        return const Color(0xFFFFAB91); // 对应规范中的 暖橙
      case BubbleType.cuisine: // 菜系 - 青蓝
        return const Color(0xFF81D4FA); // 对应规范中的 青蓝
      case BubbleType.ingredient: // 食材 - 自然绿
        return const Color(0xFFA5D6A7); // 对应规范中的 自然绿
      case BubbleType.scenario: // 场景 - 活力黄
        return const Color(0xFFFFE082); // 对应规范中的 活力黄
      case BubbleType.nutrition: // 营养 - 健康紫
        return const Color(0xFFCE93D8); // 对应规范中的 健康紫
    }
  }

  IconData _getTypeIcon(BubbleType type) {
    switch (type) {
      case BubbleType.taste:
        return Icons.restaurant;
      case BubbleType.cuisine:
        return Icons.public;
      case BubbleType.ingredient:
        return Icons.eco;
      case BubbleType.scenario:
        return Icons.mood;
      case BubbleType.nutrition:
        return Icons.fitness_center;
    }
  }
}

/// 气泡选择计数器
class BubbleCounter extends StatelessWidget {
  final int selectedCount;
  final int totalCount;
  final Color? color;

  const BubbleCounter({
    Key? key,
    required this.selectedCount,
    required this.totalCount,
    this.color,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color ?? Theme.of(context).primaryColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        '$selectedCount / $totalCount',
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }
}