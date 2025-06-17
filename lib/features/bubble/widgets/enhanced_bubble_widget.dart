import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/models/bubble.dart';

/// 增强的气泡UI组件
class EnhancedBubbleWidget extends StatefulWidget {
  final Bubble bubble;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final Function(DragUpdateDetails)? onPanUpdate;
  final VoidCallback? onPanEnd;

  const EnhancedBubbleWidget({
    Key? key,
    required this.bubble,
    this.onTap,
    this.onLongPress,
    this.onPanUpdate,
    this.onPanEnd,
  }) : super(key: key);

  @override
  State<EnhancedBubbleWidget> createState() => _EnhancedBubbleWidgetState();
}

class _EnhancedBubbleWidgetState extends State<EnhancedBubbleWidget>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _rotationController;
  late AnimationController _glowController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _rotationAnimation;
  late Animation<double> _glowAnimation;

  bool _isPressed = false;
  bool _isDragging = false;

  @override
  void initState() {
    super.initState();
    
    // 缩放动画控制器
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    // 旋转动画控制器
    _rotationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );

    // 发光动画控制器
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeInOut,
    ));

    _rotationAnimation = Tween<double>(
      begin: 0.0,
      end: 0.1,
    ).animate(CurvedAnimation(
      parent: _rotationController,
      curve: Curves.elasticOut,
    ));

    _glowAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ));

    // 如果气泡被选中，启动发光动画
    if (widget.bubble.isSelected) {
      _glowController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(EnhancedBubbleWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    // 根据选中状态控制发光动画
    if (widget.bubble.isSelected != oldWidget.bubble.isSelected) {
      if (widget.bubble.isSelected) {
        _glowController.repeat(reverse: true);
        _rotationController.forward().then((_) {
          _rotationController.reverse();
        });
      } else {
        _glowController.reset();
      }
    }
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _rotationController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  void _handleTapDown() {
    setState(() {
      _isPressed = true;
    });
    _scaleController.forward();
    
    // 轻触觉反馈
    HapticFeedback.lightImpact();
  }

  void _handleTapUp() {
    setState(() {
      _isPressed = false;
    });
    _scaleController.reverse();
  }

  void _handleTap() {
    // 中等触觉反馈
    HapticFeedback.mediumImpact();
    widget.onTap?.call();
  }

  void _handleLongPress() {
    // 重触觉反馈
    HapticFeedback.heavyImpact();
    widget.onLongPress?.call();
  }

  @override
  Widget build(BuildContext context) {
    return Transform.translate(
      offset: Offset(
        widget.bubble.position.dx - widget.bubble.size / 2,
        widget.bubble.position.dy - widget.bubble.size / 2,
      ),
      child: GestureDetector(
        onTapDown: (_) => _handleTapDown(),
        onTapUp: (_) => _handleTapUp(),
        onTapCancel: () => _handleTapUp(),
        onTap: _handleTap,
        onLongPress: _handleLongPress,
        onPanStart: (details) {
          setState(() {
            _isDragging = true;
          });
          _handleTapDown();
        },
        onPanUpdate: (details) {
          widget.onPanUpdate?.call(details);
        },
        onPanEnd: (details) {
          setState(() {
            _isDragging = false;
          });
          _handleTapUp();
          widget.onPanEnd?.call();
        },
        child: AnimatedBuilder(
          animation: Listenable.merge([
            _scaleAnimation,
            _rotationAnimation,
            _glowAnimation,
          ]),
          builder: (context, child) {
            return Transform.scale(
              scale: _scaleAnimation.value,
              child: Transform.rotate(
                angle: _rotationAnimation.value,
                child: Container(
                  width: widget.bubble.size,
                  height: widget.bubble.size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: _getGradientColors(),
                      stops: const [0.0, 0.7, 1.0],
                    ),
                    boxShadow: _getBoxShadows(),
                    border: Border.all(
                      color: widget.bubble.isSelected 
                          ? Colors.white.withOpacity(0.8)
                          : Colors.white.withOpacity(0.3),
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          widget.bubble.emoji,
                          style: TextStyle(
                            fontSize: widget.bubble.size * 0.35,
                          ),
                        ),
                        if (widget.bubble.size > 40)
                          Text(
                            widget.bubble.text,
                            style: TextStyle(
                              fontSize: widget.bubble.size * 0.15,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                              shadows: const [
                                Shadow(
                                  color: Colors.black26,
                                  offset: Offset(0, 1),
                                  blurRadius: 2,
                                ),
                              ],
                            ),
                            textAlign: TextAlign.center,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
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
    );
  }

  List<Color> _getGradientColors() {
    final baseColor = _getBubbleColor();
    
    if (widget.bubble.isSelected) {
      final glowIntensity = _glowAnimation.value;
      return [
        baseColor.withOpacity(0.9 + 0.1 * glowIntensity),
        baseColor.withOpacity(0.7 + 0.2 * glowIntensity),
        baseColor.withOpacity(0.5 + 0.3 * glowIntensity),
      ];
    }
    
    return [
      baseColor.withOpacity(0.8),
      baseColor.withOpacity(0.6),
      baseColor.withOpacity(0.4),
    ];
  }

  Color _getBubbleColor() {
    switch (widget.bubble.type) {
      case BubbleType.taste:
        return Colors.pink;
      case BubbleType.cuisine:
        return Colors.orange;
      case BubbleType.ingredient:
        return Colors.green;
      case BubbleType.context:
        return Colors.blue;
      case BubbleType.nutrition:
        return Colors.purple;
      case BubbleType.temperature:
        return Colors.red;
      case BubbleType.spiciness:
        return Colors.deepOrange;
      default:
        return Colors.grey;
    }
  }

  List<BoxShadow> _getBoxShadows() {
    if (widget.bubble.isSelected) {
      final glowIntensity = _glowAnimation.value;
      final color = _getBubbleColor();
      return [
        BoxShadow(
          color: color.withOpacity(0.3 + 0.4 * glowIntensity),
          blurRadius: 8 + 12 * glowIntensity,
          spreadRadius: 2 + 4 * glowIntensity,
          offset: const Offset(0, 4),
        ),
        BoxShadow(
          color: Colors.black.withOpacity(0.1),
          blurRadius: 4,
          offset: const Offset(0, 2),
        ),
      ];
    }
    
    return [
      BoxShadow(
        color: Colors.black.withOpacity(_isPressed ? 0.2 : 0.1),
        blurRadius: _isPressed ? 8 : 4,
        offset: Offset(0, _isPressed ? 4 : 2),
      ),
    ];
  }
} 