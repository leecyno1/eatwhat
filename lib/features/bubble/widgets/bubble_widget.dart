import 'package:flutter/material.dart';
import '../../../core/models/bubble.dart';

/// 气泡UI组件
class BubbleWidget extends StatefulWidget {
  final Bubble bubble;
  final Function(Bubble, BubbleGesture, Offset, double)? onGesture;
  final bool isInteractive;

  const BubbleWidget({
    super.key,
    required this.bubble,
    this.onGesture,
    this.isInteractive = true,
  });

  @override
  State<BubbleWidget> createState() => _BubbleWidgetState();
}

class _BubbleWidgetState extends State<BubbleWidget>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _glowController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;

  @override
  void initState() {
    super.initState();
    
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    
    _glowController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.elasticOut,
    ));

    _glowAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ));

    // 如果气泡被选中，播放动画
    if (widget.bubble.isSelected) {
      _scaleController.forward();
      _glowController.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(BubbleWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    
    if (widget.bubble.isSelected != oldWidget.bubble.isSelected) {
      if (widget.bubble.isSelected) {
        _scaleController.forward();
        _glowController.repeat(reverse: true);
      } else {
        _scaleController.reverse();
        _glowController.stop();
      }
    }
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: widget.bubble.position.dx - widget.bubble.size / 2,
      top: widget.bubble.position.dy - widget.bubble.size / 2,
      child: GestureDetector(
        onTap: widget.isInteractive ? _handleTap : null,
        onPanStart: widget.isInteractive ? _handlePanStart : null,
        onPanUpdate: widget.isInteractive ? _handlePanUpdate : null,
        onPanEnd: widget.isInteractive ? _handlePanEnd : null,
        onLongPress: widget.isInteractive ? _handleLongPress : null,
        child: AnimatedBuilder(
          animation: Listenable.merge([_scaleAnimation, _glowAnimation]),
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
                      widget.bubble.color.withOpacity(0.8),
                      widget.bubble.color.withOpacity(0.6),
                      widget.bubble.color.withOpacity(0.4),
                    ],
                    stops: const [0.0, 0.7, 1.0],
                  ),
                  boxShadow: [
                    // 基础阴影
                    BoxShadow(
                      color: widget.bubble.color.withOpacity(0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4),
                    ),
                    // 发光效果
                    if (widget.bubble.isSelected)
                      BoxShadow(
                        color: widget.bubble.color.withOpacity(
                          0.6 * _glowAnimation.value,
                        ),
                        blurRadius: 20 * _glowAnimation.value,
                        spreadRadius: 5 * _glowAnimation.value,
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
                            fontSize: widget.bubble.size * 0.3,
                          ),
                        ),
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
      ),
    );
  }

  void _handleTap() {
    _triggerHapticFeedback();
    widget.onGesture?.call(
      widget.bubble,
      BubbleGesture.tap,
      widget.bubble.position,
      0.0,
    );
  }

  void _handleLongPress() {
    _triggerHapticFeedback();
    widget.onGesture?.call(
      widget.bubble,
      BubbleGesture.longPress,
      widget.bubble.position,
      0.0,
    );
  }

  Offset? _panStartPosition;
  DateTime? _panStartTime;

  void _handlePanStart(DragStartDetails details) {
    _panStartPosition = details.globalPosition;
    _panStartTime = DateTime.now();
  }

  void _handlePanUpdate(DragUpdateDetails details) {
    // 实时更新气泡位置（可选）
    // widget.bubble.position = details.globalPosition;
  }

  void _handlePanEnd(DragEndDetails details) {
    if (_panStartPosition == null || _panStartTime == null) return;

    final endPosition = details.globalPosition;
    final deltaTime = DateTime.now().difference(_panStartTime!).inMilliseconds;
    final deltaPosition = endPosition - _panStartPosition!;
    
    // 计算滑动速度
    final velocity = deltaPosition.distance / deltaTime * 1000;
    
    // 判断滑动方向
    BubbleGesture? gesture;
    
    if (deltaPosition.distance > 50) { // 最小滑动距离
      final angle = deltaPosition.direction;
      
      if (angle > -3 * 3.14159 / 4 && angle < -3.14159 / 4) {
        gesture = BubbleGesture.swipeUp;
      } else if (angle > 3.14159 / 4 && angle < 3 * 3.14159 / 4) {
        gesture = BubbleGesture.swipeDown;
      } else if (angle > -3.14159 / 4 && angle < 3.14159 / 4) {
        gesture = BubbleGesture.swipeRight;
      } else {
        gesture = BubbleGesture.swipeLeft;
      }
    }

    if (gesture != null) {
      _triggerHapticFeedback();
      widget.onGesture?.call(
        widget.bubble,
        gesture,
        endPosition,
        velocity,
      );
    }

    _panStartPosition = null;
    _panStartTime = null;
  }

  void _triggerHapticFeedback() {
    // 触觉反馈
    // HapticFeedback.lightImpact();
  }
}

/// 气泡类型指示器
class BubbleTypeIndicator extends StatelessWidget {
  final BubbleType type;
  final double size;

  const BubbleTypeIndicator({
    super.key,
    required this.type,
    this.size = 20.0,
  });

  @override
  Widget build(BuildContext context) {
    final color = BubbleFactory.getColorByType(type);
    final name = BubbleFactory.getNameByType(type);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white,
          width: 2,
        ),
      ),
      child: Center(
        child: Text(
          name[0], // 显示类型名称的第一个字符
          style: TextStyle(
            color: Colors.white,
            fontSize: size * 0.5,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
    );
  }
}

/// 气泡拖尾效果
class BubbleTrail extends StatelessWidget {
  final List<Offset> trailPoints;
  final Color color;
  final double opacity;

  const BubbleTrail({
    super.key,
    required this.trailPoints,
    required this.color,
    this.opacity = 0.5,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _BubbleTrailPainter(
        trailPoints: trailPoints,
        color: color,
        opacity: opacity,
      ),
    );
  }
}

class _BubbleTrailPainter extends CustomPainter {
  final List<Offset> trailPoints;
  final Color color;
  final double opacity;

  _BubbleTrailPainter({
    required this.trailPoints,
    required this.color,
    required this.opacity,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (trailPoints.length < 2) return;

    final paint = Paint()
      ..color = color.withValues(alpha: opacity)
      ..strokeWidth = 3.0
      ..strokeCap = StrokeCap.round
      ..style = PaintingStyle.stroke;

    final path = Path();
    path.moveTo(trailPoints.first.dx, trailPoints.first.dy);

    for (int i = 1; i < trailPoints.length; i++) {
      final point = trailPoints[i];
      final opacity = (i / trailPoints.length) * this.opacity;
      paint.color = color.withValues(alpha: opacity);
      
      if (i == 1) {
        path.lineTo(point.dx, point.dy);
      } else {
        final previousPoint = trailPoints[i - 1];
        final controlPoint = Offset(
          (previousPoint.dx + point.dx) / 2,
          (previousPoint.dy + point.dy) / 2,
        );
        path.quadraticBezierTo(
          previousPoint.dx,
          previousPoint.dy,
          controlPoint.dx,
          controlPoint.dy,
        );
      }
    }

    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return true;
  }
} 