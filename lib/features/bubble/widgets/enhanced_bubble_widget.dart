import 'package:flutter/material.dart';
import '../../../core/models/bubble.dart';

/// 增强版气泡组件 (已简化)
/// 移除了复杂的液态效果，现在是一个带有动画效果的标准气泡
class EnhancedBubbleWidget extends StatefulWidget {
  final Bubble bubble;
  final VoidCallback? onTap;

  const EnhancedBubbleWidget({
    super.key,
    required this.bubble,
    this.onTap,
  });

  @override
  State<EnhancedBubbleWidget> createState() => _EnhancedBubbleWidgetState();
}

class _EnhancedBubbleWidgetState extends State<EnhancedBubbleWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );

    _scaleAnimation = Tween<double>(begin: 1.0, end: 1.1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _controller.forward(),
      onExit: (_) => _controller.reverse(),
      child: GestureDetector(
        onTap: widget.onTap,
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: Container(
            width: widget.bubble.size,
            height: widget.bubble.size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: LinearGradient(
                colors: [widget.bubble.color, widget.bubble.color.withValues(alpha: 0.7)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: widget.bubble.color.withValues(alpha: 0.4),
                  blurRadius: 10,
                  spreadRadius: 2,
                )
              ],
            ),
            child: Center(
              child: Text(
                widget.bubble.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
