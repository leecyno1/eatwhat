import 'package:flutter/material.dart';

/// 偏好保存成功 Toast 组件
/// 显示在屏幕底部，带有淡入淡出动画
class PreferenceSavedToast extends StatefulWidget {
  final bool isLike;
  final VoidCallback onDismiss;

  const PreferenceSavedToast({
    super.key,
    required this.isLike,
    required this.onDismiss,
  });

  @override
  State<PreferenceSavedToast> createState() => _PreferenceSavedToastState();
}

class _PreferenceSavedToastState extends State<PreferenceSavedToast>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );

    // 淡入淡出动画
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.2, curve: Curves.easeIn),
      ),
    );

    // 底部滑入动画
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, 0.5),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.3, curve: Curves.easeOut),
      ),
    );

    _controller.forward();

    // 动画完成后自动消失
    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        Future.delayed(const Duration(milliseconds: 800), () {
          if (mounted) {
            _controller.reverse().then((_) {
              widget.onDismiss();
            });
          }
        });
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _fadeAnimation.value,
          child: SlideTransition(
            position: _slideAnimation,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: widget.isLike
                      ? [const Color(0xFF4CAF50), const Color(0xFF81C784)]
                      : [const Color(0xFFE57373), const Color(0xFFEF5350)],
                ),
                borderRadius: BorderRadius.circular(30),
                boxShadow: [
                  BoxShadow(
                    color: (widget.isLike ? Colors.green : Colors.red)
                        .withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    widget.isLike ? Icons.favorite : Icons.thumb_down,
                    color: Colors.white,
                    size: 20,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    widget.isLike ? '已保存偏好 ✓' : '已记录不喜欢',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Toast 显示管理器
class ToastManager {
  static OverlayEntry? _currentToast;

  /// 显示偏好保存 Toast
  static void showPreferenceSavedToast(BuildContext context, bool isLike) {
    // 移除已存在的 Toast
    _currentToast?.remove();

    _currentToast = OverlayEntry(
      builder: (context) => Positioned(
        bottom: 100,
        left: 0,
        right: 0,
        child: Center(
          child: Material(
            color: Colors.transparent,
            child: PreferenceSavedToast(
              isLike: isLike,
              onDismiss: () {
                _currentToast?.remove();
                _currentToast = null;
              },
            ),
          ),
        ),
      ),
    );

    Overlay.of(context).insert(_currentToast!);
  }
}
