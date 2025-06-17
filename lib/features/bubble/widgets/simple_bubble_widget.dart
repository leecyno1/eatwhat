import 'package:flutter/material.dart';
import '../../../core/models/bubble.dart';

/// 简化的气泡UI组件
class SimpleBubbleWidget extends StatefulWidget {
  final Bubble bubble;
  final VoidCallback? onTap;

  const SimpleBubbleWidget({
    Key? key,
    required this.bubble,
    this.onTap,
  }) : super(key: key);

  @override
  State<SimpleBubbleWidget> createState() => _SimpleBubbleWidgetState();
}

class _SimpleBubbleWidgetState extends State<SimpleBubbleWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    
    _controller = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.1,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    ));

    if (widget.bubble.isSelected) {
      _controller.forward();
    }
  }

  @override
  void didUpdateWidget(SimpleBubbleWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.bubble.isSelected != oldWidget.bubble.isSelected) {
      if (widget.bubble.isSelected) {
        _controller.forward();
      } else {
        _controller.reverse();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.onTap,
      child: AnimatedBuilder(
        animation: _scaleAnimation,
        builder: (context, child) {
          return Transform.scale(
            scale: _scaleAnimation.value,
            child: Container(
              width: widget.bubble.size,
              height: widget.bubble.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: RadialGradient(
                  colors: [
                    widget.bubble.color.withOpacity(0.9),
                    widget.bubble.color.withOpacity(0.7),
                    widget.bubble.color.withOpacity(0.5),
                  ],
                  stops: const [0.0, 0.7, 1.0],
                ),
                boxShadow: [
                  BoxShadow(
                    color: widget.bubble.color.withOpacity(0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 4),
                  ),
                  if (widget.bubble.isSelected)
                    BoxShadow(
                      color: widget.bubble.color.withOpacity(0.6),
                      blurRadius: 20,
                      spreadRadius: 5,
                    ),
                ],
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (widget.bubble.icon != null)
                      Text(
                        widget.bubble.icon!,
                        style: TextStyle(
                          fontSize: widget.bubble.size * 0.25,
                        ),
                      ),
                    Text(
                      widget.bubble.name,
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: widget.bubble.size * 0.12,
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
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
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