import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// 喜欢/不喜欢控制组件（顶部版本）
class TopLikeDislikeControls extends StatefulWidget {
  final int likedCount;
  final int dislikedCount;
  final VoidCallback? onShowLiked;
  final VoidCallback? onShowDisliked;
  final VoidCallback? onReset;
  final Color? backgroundColor;
  final Color? textColor;

  const TopLikeDislikeControls({
    super.key,
    this.likedCount = 0,
    this.dislikedCount = 0,
    this.onShowLiked,
    this.onShowDisliked,
    this.onReset,
    this.backgroundColor,
    this.textColor,
  });

  @override
  State<TopLikeDislikeControls> createState() => _TopLikeDislikeControlsState();
}

class _TopLikeDislikeControlsState extends State<TopLikeDislikeControls>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _countController;
  late Animation<double> _pulseAnimation;
  late Animation<double> _scaleAnimation;

  int _previousLikedCount = 0;
  int _previousDislikedCount = 0;

  @override
  void initState() {
    super.initState();
    _previousLikedCount = widget.likedCount;
    _previousDislikedCount = widget.dislikedCount;

    _pulseController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );

    _countController = AnimationController(
      duration: const Duration(milliseconds: 800),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 1.0,
      end: 1.2,
    ).animate(CurvedAnimation(
      parent: _pulseController,
      curve: Curves.elasticOut,
    ));

    _scaleAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _countController,
      curve: Curves.bounceOut,
    ));
  }

  @override
  void didUpdateWidget(TopLikeDislikeControls oldWidget) {
    super.didUpdateWidget(oldWidget);

    // 检测计数变化并触发动画
    if (widget.likedCount != _previousLikedCount ||
        widget.dislikedCount != _previousDislikedCount) {
      _triggerCountAnimation();
      _previousLikedCount = widget.likedCount;
      _previousDislikedCount = widget.dislikedCount;
    }
  }

  void _triggerCountAnimation() {
    _countController.reset();
    _countController.forward();

    // 添加触觉反馈
    HapticFeedback.lightImpact();
  }

  void _triggerPulseAnimation() {
    _pulseController.reset();
    _pulseController.forward().then((_) {
      _pulseController.reverse();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
      decoration: BoxDecoration(
        color: (widget.backgroundColor ?? Colors.white).withValues(alpha: 0.9),
        borderRadius: BorderRadius.circular(25),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 10,
            spreadRadius: 1,
            offset: const Offset(0, 2),
          ),
        ],
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          // 喜欢按钮
          AnimatedBuilder(
            animation: Listenable.merge([_pulseAnimation, _scaleAnimation]),
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: GestureDetector(
                  onTap: () {
                    _triggerPulseAnimation();
                    widget.onShowLiked?.call();
                  },
                  child: AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _pulseAnimation.value,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFFFF6B8A), Color(0xFFFF8E9B)],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFFFF6B8A).withValues(alpha: 0.3),
                                blurRadius: 8,
                                spreadRadius: 0,
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.favorite,
                                color: Colors.white,
                                size: 18,
                              ),
                              const SizedBox(width: 6),
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 300),
                                transitionBuilder: (child, animation) {
                                  return ScaleTransition(
                                    scale: animation,
                                    child: child,
                                  );
                                },
                                child: Text(
                                  '${widget.likedCount}',
                                  key: ValueKey(widget.likedCount),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          ),

          const SizedBox(width: 16),

          // 分割线
          Container(
            width: 1,
            height: 20,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.transparent,
                  (widget.textColor ?? Colors.black54).withValues(alpha: 0.3),
                  Colors.transparent,
                ],
              ),
            ),
          ),

          const SizedBox(width: 16),

          // 不喜欢按钮
          AnimatedBuilder(
            animation: Listenable.merge([_pulseAnimation, _scaleAnimation]),
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: GestureDetector(
                  onTap: () {
                    _triggerPulseAnimation();
                    widget.onShowDisliked?.call();
                  },
                  child: AnimatedBuilder(
                    animation: _pulseAnimation,
                    builder: (context, child) {
                      return Transform.scale(
                        scale: _pulseAnimation.value,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF9B9B9B), Color(0xFFB8B8B8)],
                            ),
                            borderRadius: BorderRadius.circular(20),
                            boxShadow: [
                              BoxShadow(
                                color: const Color(0xFF9B9B9B).withValues(alpha: 0.3),
                                blurRadius: 8,
                                spreadRadius: 0,
                              ),
                            ],
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.thumb_down,
                                color: Colors.white,
                                size: 18,
                              ),
                              const SizedBox(width: 6),
                              AnimatedSwitcher(
                                duration: const Duration(milliseconds: 300),
                                transitionBuilder: (child, animation) {
                                  return ScaleTransition(
                                    scale: animation,
                                    child: child,
                                  );
                                },
                                child: Text(
                                  '${widget.dislikedCount}',
                                  key: ValueKey(widget.dislikedCount),
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              );
            },
          ),

          // 重置按钮
          if (widget.onReset != null && (widget.likedCount > 0 || widget.dislikedCount > 0)) ...[
            const SizedBox(width: 16),
            GestureDetector(
              onTap: () {
                _triggerPulseAnimation();
                widget.onReset?.call();
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: (widget.textColor ?? Colors.black54).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  Icons.refresh,
                  color: widget.textColor ?? Colors.black54,
                  size: 16,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _countController.dispose();
    super.dispose();
  }
}

/// 状态指示器组件
class StatusIndicator extends StatefulWidget {
  final String text;
  final IconData icon;
  final Color color;
  final bool isActive;

  const StatusIndicator({
    super.key,
    required this.text,
    required this.icon,
    required this.color,
    this.isActive = false,
  });

  @override
  State<StatusIndicator> createState() => _StatusIndicatorState();
}

class _StatusIndicatorState extends State<StatusIndicator> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 1),
      vsync: this,
    );

    _pulseAnimation = Tween<double>(
      begin: 0.8,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    ));

    if (widget.isActive) {
      _controller.repeat(reverse: true);
    }
  }

  @override
  void didUpdateWidget(StatusIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isActive != oldWidget.isActive) {
      if (widget.isActive) {
        _controller.repeat(reverse: true);
      } else {
        _controller.stop();
        _controller.value = 1.0;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: widget.isActive ? _pulseAnimation.value : 1.0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: widget.color.withValues(alpha: widget.isActive ? 0.2 : 0.1),
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: widget.color.withValues(alpha: widget.isActive ? 0.5 : 0.3),
                width: 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  widget.icon,
                  color: widget.color,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  widget.text,
                  style: TextStyle(
                    color: widget.color,
                    fontWeight: FontWeight.w500,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }
}
