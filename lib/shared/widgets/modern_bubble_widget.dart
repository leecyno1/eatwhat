import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'dart:math' as math;
import '../../core/models/bubble.dart';

/// 现代化气泡组件 - 使用flutter_animate实现丰富动画效果
class ModernBubbleWidget extends StatefulWidget {
  final Bubble bubble;
  final VoidCallback? onTap;
  final Function(String)? onSwipeUp;
  final Function(String)? onSwipeDown;
  final Function(String)? onSwipeLeft;
  final Function(String)? onSwipeRight;
  final Function(String)? onLongPress;
  final bool isSelected;
  final bool isHighlighted;
  final double animationDelay;

  const ModernBubbleWidget({
    super.key,
    required this.bubble,
    this.onTap,
    this.onSwipeUp,
    this.onSwipeDown,
    this.onSwipeLeft,
    this.onSwipeRight,
    this.onLongPress,
    this.isSelected = false,
    this.isHighlighted = false,
    this.animationDelay = 0.0,
  });

  @override
  State<ModernBubbleWidget> createState() => _ModernBubbleWidgetState();
}

class _ModernBubbleWidgetState extends State<ModernBubbleWidget>
    with TickerProviderStateMixin {
  bool _isPressed = false;
  bool _isHovered = false;
  
  late AnimationController _floatingController;
  late AnimationController _interactionController;
  
  @override
  void initState() {
    super.initState();
    
    // 浮动动画控制器（持续运行）
    _floatingController = AnimationController(
      duration: Duration(milliseconds: 2000 + (widget.animationDelay * 1000).round()),
      vsync: this,
    )..repeat(reverse: true);
    
    // 交互动画控制器
    _interactionController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _floatingController.dispose();
    _interactionController.dispose();
    super.dispose();
  }

  void _handleTapDown(TapDownDetails details) {
    setState(() => _isPressed = true);
    _interactionController.forward();
  }

  void _handleTapUp(TapUpDetails details) {
    setState(() => _isPressed = false);
    _interactionController.reverse();
    widget.onTap?.call();
  }

  void _handleTapCancel() {
    setState(() => _isPressed = false);
    _interactionController.reverse();
  }

  void _handleLongPress() {
    widget.onLongPress?.call(widget.bubble.name);
  }

  void _handlePanEnd(DragEndDetails details) {
    final velocity = details.velocity.pixelsPerSecond;
    const threshold = 300.0;
    
    if (velocity.dx.abs() > velocity.dy.abs()) {
      // 水平滑动
      if (velocity.dx > threshold) {
        widget.onSwipeRight?.call(widget.bubble.name);
      } else if (velocity.dx < -threshold) {
        widget.onSwipeLeft?.call(widget.bubble.name);
      }
    } else {
      // 垂直滑动
      if (velocity.dy > threshold) {
        widget.onSwipeDown?.call(widget.bubble.name);
      } else if (velocity.dy < -threshold) {
        widget.onSwipeUp?.call(widget.bubble.name);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => setState(() => _isHovered = true),
      onExit: (_) => setState(() => _isHovered = false),
      child: GestureDetector(
        onTapDown: _handleTapDown,
        onTapUp: _handleTapUp,
        onTapCancel: _handleTapCancel,
        onLongPress: _handleLongPress,
        onPanEnd: _handlePanEnd,
        child: SizedBox(
          width: widget.bubble.size,
          height: widget.bubble.size,
          child: _buildAnimatedBubble(),
        ),
      ),
    );
  }

  Widget _buildAnimatedBubble() {
    return Container(
      width: widget.bubble.size,
      height: widget.bubble.size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: _buildGradient(),
        boxShadow: _buildShadows(),
      ),
      child: Center(
        child: Text(
          widget.bubble.name,
          style: TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
            fontSize: _calculateFontSize(),
            shadows: [
              Shadow(
                offset: const Offset(1, 1),
                blurRadius: 2,
                color: Colors.black.withValues(alpha: 0.3),
              ),
            ],
          ),
          textAlign: TextAlign.center,
        ),
      ),
    )
        // 入场动画
        .animate(delay: Duration(milliseconds: (widget.animationDelay * 100).round()))
        .fadeIn(duration: 600.ms, curve: Curves.easeOutQuart)
        .scale(
          begin: const Offset(0.3, 0.3),
          end: const Offset(1.0, 1.0),
          duration: 800.ms,
          curve: Curves.elasticOut,
        )
        .moveY(
          begin: 50,
          end: 0,
          duration: 600.ms,
          curve: Curves.easeOutCubic,
        )
        
        // 浮动效果
        .animate(
          onPlay: (controller) => controller.repeat(reverse: true),
        )
        .moveY(
          begin: -3,
          end: 3,
          duration: 2000.ms,
          curve: Curves.easeInOut,
        )
        .rotate(
          begin: -0.02,
          end: 0.02,
          duration: 3000.ms,
          curve: Curves.easeInOut,
        )
        
        // 悬停效果
        .animate(target: _isHovered ? 1 : 0)
        .scale(
          begin: const Offset(1.0, 1.0),
          end: const Offset(1.1, 1.1),
          duration: 200.ms,
          curve: Curves.easeOut,
        )
        .tint(
          begin: 0.0,
          end: 0.2,
          color: Colors.white,
          duration: 200.ms,
        )
        
        // 按压效果
        .animate(target: _isPressed ? 1 : 0)
        .scale(
          begin: const Offset(1.0, 1.0),
          end: const Offset(0.95, 0.95),
          duration: 100.ms,
          curve: Curves.easeOut,
        )
        
        // 选中状态
        .animate(target: widget.isSelected ? 1 : 0)
        .shimmer(
          duration: 1500.ms,
          color: Colors.white.withValues(alpha: 0.6),
        )
        .scale(
          begin: const Offset(1.0, 1.0),
          end: const Offset(1.05, 1.05),
          duration: 300.ms,
        )
        
        // 高亮状态
        .animate(target: widget.isHighlighted ? 1 : 0)
        .tint(
          color: Colors.yellow,
          begin: 0.0,
          end: 0.3,
          duration: 200.ms,
        )
        .scale(
          begin: const Offset(1.0, 1.0),
          end: const Offset(1.08, 1.08),
          duration: 200.ms,
        );
  }

  /// 构建渐变效果
  Gradient _buildGradient() {
    final baseColor = widget.bubble.color;
    
    if (widget.isSelected) {
      return RadialGradient(
        colors: [
          baseColor.withValues(alpha: 0.9),
          baseColor,
          baseColor.withValues(alpha: 0.8),
        ],
        stops: const [0.0, 0.7, 1.0],
      );
    }
    
    return LinearGradient(
      colors: [
        baseColor.withValues(alpha: 0.9),
        baseColor,
        baseColor.withValues(alpha: 0.7),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      stops: const [0.0, 0.5, 1.0],
    );
  }

  /// 构建阴影效果
  List<BoxShadow> _buildShadows() {
    final baseColor = widget.bubble.color;
    
    List<BoxShadow> shadows = [
      BoxShadow(
        color: baseColor.withValues(alpha: 0.3),
        blurRadius: 8,
        spreadRadius: 2,
        offset: const Offset(2, 4),
      ),
    ];
    
    if (widget.isSelected) {
      shadows.add(
        BoxShadow(
          color: baseColor.withValues(alpha: 0.5),
          blurRadius: 20,
          spreadRadius: 5,
          offset: const Offset(0, 0),
        ),
      );
    }
    
    if (_isHovered) {
      shadows.add(
        BoxShadow(
          color: baseColor.withValues(alpha: 0.4),
          blurRadius: 15,
          spreadRadius: 3,
          offset: const Offset(0, 8),
        ),
      );
    }
    
    return shadows;
  }

  /// 计算字体大小
  double _calculateFontSize() {
    final baseSize = widget.bubble.size * 0.15;
    return math.max(10, math.min(16, baseSize));
  }
}

/// 气泡交互指示器
class BubbleInteractionIndicator extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color color;
  final bool isVisible;

  const BubbleInteractionIndicator({
    super.key,
    required this.label,
    required this.icon,
    required this.color,
    this.isVisible = false,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withValues(alpha: 0.3),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 16,
            color: Colors.white,
          ),
          const SizedBox(width: 4),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    )
        .animate(target: isVisible ? 1 : 0)
        .fadeIn(duration: 200.ms)
        .scale(
          begin: const Offset(0.8, 0.8),
          end: const Offset(1.0, 1.0),
          duration: 200.ms,
          curve: Curves.elasticOut,
        )
        .moveY(begin: 10, end: 0, duration: 200.ms);
  }
}

/// 气泡连接线动画
class BubbleConnectionLine extends StatelessWidget {
  final Offset start;
  final Offset end;
  final Color color;
  final bool isAnimating;

  const BubbleConnectionLine({
    super.key,
    required this.start,
    required this.end,
    required this.color,
    this.isAnimating = false,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _ConnectionLinePainter(
        start: start,
        end: end,
        color: color,
      ),
    )
        .animate(target: isAnimating ? 1 : 0)
        .fadeIn(duration: 300.ms)
        .custom(
          duration: 800.ms,
          builder: (context, value, child) {
            return CustomPaint(
              painter: _ConnectionLinePainter(
                start: start,
                end: end,
                color: color,
                progress: value,
              ),
            );
          },
        );
  }
}

/// 连接线绘制器
class _ConnectionLinePainter extends CustomPainter {
  final Offset start;
  final Offset end;
  final Color color;
  final double progress;

  _ConnectionLinePainter({
    required this.start,
    required this.end,
    required this.color,
    this.progress = 1.0,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color.withValues(alpha: 0.6)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;

    final actualEnd = Offset(
      start.dx + (end.dx - start.dx) * progress,
      start.dy + (end.dy - start.dy) * progress,
    );

    canvas.drawLine(start, actualEnd, paint);
    
    // 绘制终点圆点
    if (progress > 0.8) {
      final dotPaint = Paint()
        ..color = color
        ..style = PaintingStyle.fill;
      
      canvas.drawCircle(actualEnd, 3, dotPaint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
} 