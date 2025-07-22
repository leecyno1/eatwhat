import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// 页面切换动画类型枚举
enum PageTransitionType {
  fade,
  slide,
  scale,
  rotation,
  wave,
  morphing,
}

/// 现代化页面切换动画组件
class ModernPageTransition extends StatelessWidget {
  final Widget child;
  final PageTransitionType type;
  final Duration duration;
  final Curve curve;
  final Offset? slideDirection;

  const ModernPageTransition({
    super.key,
    required this.child,
    this.type = PageTransitionType.fade,
    this.duration = const Duration(milliseconds: 300),
    this.curve = Curves.easeInOut,
    this.slideDirection,
  });

  @override
  Widget build(BuildContext context) {
    switch (type) {
      case PageTransitionType.fade:
        return _buildFadeTransition();
      case PageTransitionType.slide:
        return _buildSlideTransition();
      case PageTransitionType.scale:
        return _buildScaleTransition();
      case PageTransitionType.rotation:
        return _buildRotationTransition();
      case PageTransitionType.wave:
        return _buildWaveTransition();
      case PageTransitionType.morphing:
        return _buildMorphingTransition();
    }
  }

  Widget _buildFadeTransition() {
    return child
        .animate()
        .fadeIn(duration: duration, curve: curve)
        .moveY(begin: 20, end: 0, duration: duration, curve: curve);
  }

  Widget _buildSlideTransition() {
    final direction = slideDirection ?? const Offset(1, 0);
    return child
        .animate()
        .slideX(
          begin: direction.dx,
          end: 0,
          duration: duration,
          curve: curve,
        )
        .slideY(
          begin: direction.dy,
          end: 0,
          duration: duration,
          curve: curve,
        )
        .fadeIn(duration: duration, curve: curve);
  }

  Widget _buildScaleTransition() {
    return child
        .animate()
        .scale(
          begin: const Offset(0.8, 0.8),
          end: const Offset(1.0, 1.0),
          duration: duration,
          curve: Curves.elasticOut,
        )
        .fadeIn(duration: duration, curve: curve);
  }

  Widget _buildRotationTransition() {
    return child
        .animate()
        .rotate(
          begin: 0.1,
          end: 0,
          duration: duration,
          curve: curve,
        )
        .scale(
          begin: const Offset(0.9, 0.9),
          end: const Offset(1.0, 1.0),
          duration: duration,
          curve: curve,
        )
        .fadeIn(duration: duration, curve: curve);
  }

  Widget _buildWaveTransition() {
    return child
        .animate()
        .custom(
          duration: duration,
          builder: (context, value, child) {
            return Transform(
              alignment: Alignment.center,
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.001)
                ..rotateY(value * 0.5)
                ..scale(0.8 + value * 0.2),
              child: child,
            );
          },
        )
        .fadeIn(duration: duration, curve: curve);
  }

  Widget _buildMorphingTransition() {
    return child
        .animate()
        .custom(
          duration: duration,
          builder: (context, value, child) {
            return ClipPath(
              clipper: _MorphingClipper(value),
              child: child,
            );
          },
        );
  }
}

/// 形变裁剪器
class _MorphingClipper extends CustomClipper<Path> {
  final double progress;

  _MorphingClipper(this.progress);

  @override
  Path getClip(Size size) {
    final path = Path();
    final width = size.width;
    final height = size.height;

    if (progress <= 0.5) {
      // 第一阶段：从中心向外扩展
      final radius = (progress * 2) * (width > height ? width : height);
      path.addOval(Rect.fromCircle(
        center: Offset(width / 2, height / 2),
        radius: radius,
      ));
    } else {
      // 第二阶段：形变为矩形
      final morphProgress = (progress - 0.5) * 2;
      final centerX = width / 2;
      final centerY = height / 2;
      final maxRadius = width > height ? width : height;
      
      final currentRadius = maxRadius * (1 - morphProgress);
      final rectProgress = morphProgress;
      
      if (rectProgress < 1) {
        // 圆形到矩形的过渡
        final rect = Rect.fromCenter(
          center: Offset(centerX, centerY),
          width: currentRadius + (width - currentRadius) * rectProgress,
          height: currentRadius + (height - currentRadius) * rectProgress,
        );
        
        final cornerRadius = currentRadius * (1 - rectProgress);
        path.addRRect(RRect.fromRectAndRadius(
          rect,
          Radius.circular(cornerRadius),
        ));
      } else {
        path.addRect(Rect.fromLTWH(0, 0, width, height));
      }
    }

    return path;
  }

  @override
  bool shouldReclip(covariant CustomClipper<Path> oldClipper) => true;
}

/// 底部导航页面切换动画
class BottomNavPageTransition extends StatelessWidget {
  final Widget child;
  final int currentIndex;
  final int previousIndex;

  const BottomNavPageTransition({
    super.key,
    required this.child,
    required this.currentIndex,
    required this.previousIndex,
  });

  @override
  Widget build(BuildContext context) {
    // 根据导航方向选择动画
    final isForward = currentIndex > previousIndex;
    
    return child
        .animate()
        .slideX(
          begin: isForward ? 0.3 : -0.3,
          end: 0,
          duration: 250.ms,
          curve: Curves.easeOut,
        )
        .fadeIn(
          duration: 200.ms,
          curve: Curves.easeOut,
        );
  }
}

/// 卡片展开动画
class CardExpandTransition extends StatelessWidget {
  final Widget child;
  final bool isExpanded;
  final Duration duration;

  const CardExpandTransition({
    super.key,
    required this.child,
    required this.isExpanded,
    this.duration = const Duration(milliseconds: 300),
  });

  @override
  Widget build(BuildContext context) {
    return child
        .animate(target: isExpanded ? 1 : 0)
        .scaleY(
          begin: 0.8,
          end: 1.0,
          duration: duration,
          curve: Curves.easeOut,
        )
        .fadeIn(
          duration: duration,
          curve: Curves.easeOut,
        )
        .moveY(
          begin: -20,
          end: 0,
          duration: duration,
          curve: Curves.easeOut,
        );
  }
}

/// 列表项入场动画
class ListItemTransition extends StatelessWidget {
  final Widget child;
  final int index;
  final Duration delay;

  const ListItemTransition({
    super.key,
    required this.child,
    required this.index,
    this.delay = const Duration(milliseconds: 100),
  });

  @override
  Widget build(BuildContext context) {
    return child
        .animate(delay: delay * index)
        .slideX(
          begin: 1,
          end: 0,
          duration: 400.ms,
          curve: Curves.easeOut,
        )
        .fadeIn(
          duration: 300.ms,
          curve: Curves.easeOut,
        );
  }
}

/// 悬浮按钮动画
class FloatingActionButtonTransition extends StatelessWidget {
  final Widget child;
  final bool isVisible;

  const FloatingActionButtonTransition({
    super.key,
    required this.child,
    required this.isVisible,
  });

  @override
  Widget build(BuildContext context) {
    return child
        .animate(target: isVisible ? 1 : 0)
        .scale(
          begin: const Offset(0.0, 0.0),
          end: const Offset(1.0, 1.0),
          duration: 200.ms,
          curve: Curves.elasticOut,
        )
        .rotate(
          begin: -0.5,
          end: 0,
          duration: 200.ms,
        );
  }
}

/// 搜索栏展开动画
class SearchBarTransition extends StatelessWidget {
  final Widget child;
  final bool isExpanded;

  const SearchBarTransition({
    super.key,
    required this.child,
    required this.isExpanded,
  });

  @override
  Widget build(BuildContext context) {
    return child
        .animate(target: isExpanded ? 1 : 0)
        .scaleX(
          begin: 0.3,
          end: 1.0,
          duration: 300.ms,
          curve: Curves.easeOut,
        )
        .fadeIn(
          duration: 200.ms,
        );
  }
}

/// 模态框动画
class ModalTransition extends StatelessWidget {
  final Widget child;
  final bool isShowing;

  const ModalTransition({
    super.key,
    required this.child,
    required this.isShowing,
  });

  @override
  Widget build(BuildContext context) {
    return child
        .animate(target: isShowing ? 1 : 0)
        .scale(
          begin: const Offset(0.8, 0.8),
          end: const Offset(1.0, 1.0),
          duration: 200.ms,
          curve: Curves.easeOut,
        )
        .fadeIn(
          duration: 150.ms,
        )
        .moveY(
          begin: 50,
          end: 0,
          duration: 200.ms,
          curve: Curves.easeOut,
        );
  }
}

/// 拖拽反馈动画
class DragFeedbackTransition extends StatelessWidget {
  final Widget child;
  final bool isDragging;

  const DragFeedbackTransition({
    super.key,
    required this.child,
    required this.isDragging,
  });

  @override
  Widget build(BuildContext context) {
    return child
        .animate(target: isDragging ? 1 : 0)
        .scale(
          begin: const Offset(1.0, 1.0),
          end: const Offset(1.1, 1.1),
          duration: 100.ms,
        )
        .rotate(
          begin: 0,
          end: 0.05,
          duration: 100.ms,
        )
        .tint(
          color: Colors.white,
          begin: 0.0,
          end: 0.2,
          duration: 100.ms,
        );
  }
} 