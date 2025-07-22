import 'package:flutter/material.dart';
import '../../../core/models/bubble.dart';

/// 基础气泡组件
class BubbleWidget extends StatelessWidget {
  final Bubble bubble;
  final Function(PointerEvent)? onPointerDown;
  final Function(PointerEvent)? onPointerUp;
  final Function(PointerEvent)? onPointerMove;

  const BubbleWidget({
    super.key,
    required this.bubble,
    this.onPointerDown,
    this.onPointerUp,
    this.onPointerMove,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: bubble.position.dx,
      top: bubble.position.dy,
      child: Listener(
        onPointerDown: onPointerDown,
        onPointerUp: onPointerUp,
        onPointerMove: onPointerMove,
        child: Container(
          width: bubble.size,
          height: bubble.size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: LinearGradient(
              colors: [bubble.color, bubble.color.withValues(alpha: 0.7)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Center(
            child: Text(
              bubble.name,
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// 气泡类型指示器
class BubbleTypeIndicator extends StatelessWidget {
  final BubbleType type;
  final double size;

  const BubbleTypeIndicator({
    super.key,
    required this.type,
    this.size = 24,
  });

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
    switch (type) {
      case BubbleType.taste:
        return const Color(0xFFFFAB91);
      case BubbleType.cuisine:
        return const Color(0xFF81D4FA);
      case BubbleType.ingredient:
        return const Color(0xFFA5D6A7);
      case BubbleType.scenario:
        return const Color(0xFFFFE082);
      case BubbleType.nutrition:
        return const Color(0xFFCE93D8);
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
    super.key,
    required this.selectedCount,
    required this.totalCount,
    this.color,
  });

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
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
