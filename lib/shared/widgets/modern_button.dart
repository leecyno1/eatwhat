import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// 现代化按钮组件
class ModernButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color? backgroundColor;
  final Color? textColor;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final bool isLoading;
  final bool isOutlined;
  final Gradient? gradient;
  final bool hasRippleEffect;
  final double elevation;

  const ModernButton({
    super.key,
    required this.text,
    this.onPressed,
    this.icon,
    this.backgroundColor,
    this.textColor,
    this.width,
    this.height,
    this.borderRadius,
    this.isLoading = false,
    this.isOutlined = false,
    this.gradient,
    this.hasRippleEffect = true,
    this.elevation = 4.0,
  });

  @override
  State<ModernButton> createState() => _ModernButtonState();
}

class _ModernButtonState extends State<ModernButton> with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    _animationController.forward();
  }

  void _onTapUp(TapUpDetails details) {
    _animationController.reverse();
  }

  void _onTapCancel() {
    _animationController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: GestureDetector(
            onTapDown: widget.onPressed != null ? _onTapDown : null,
            onTapUp: widget.onPressed != null ? _onTapUp : null,
            onTapCancel: widget.onPressed != null ? _onTapCancel : null,
            onTap: widget.isLoading ? null : widget.onPressed,
            child: Container(
              width: widget.width,
              height: widget.height ?? 48.h,
              decoration: BoxDecoration(
                gradient: widget.gradient ??
                    (widget.isOutlined
                        ? null
                        : LinearGradient(
                            colors: [
                              widget.backgroundColor ?? Theme.of(context).primaryColor,
                              (widget.backgroundColor ?? Theme.of(context).primaryColor)
                                  .withValues(alpha: 0.8),
                            ],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          )),
                color: widget.isOutlined
                    ? Colors.transparent
                    : (widget.gradient == null ? widget.backgroundColor : null),
                borderRadius: widget.borderRadius ?? BorderRadius.circular(12.r),
                border: widget.isOutlined
                    ? Border.all(
                        color: widget.backgroundColor ?? Theme.of(context).primaryColor,
                        width: 2,
                      )
                    : null,
                boxShadow: !widget.isOutlined && widget.elevation > 0
                    ? [
                        BoxShadow(
                          color: (widget.backgroundColor ?? Theme.of(context).primaryColor)
                              .withValues(alpha: 0.3),
                          blurRadius: widget.elevation * 2,
                          offset: Offset(0, widget.elevation),
                        ),
                      ]
                    : null,
              ),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  borderRadius: widget.borderRadius ?? BorderRadius.circular(12.r),
                  onTap: widget.isLoading ? null : widget.onPressed,
                  splashColor: widget.hasRippleEffect
                      ? Colors.white.withValues(alpha: 0.2)
                      : Colors.transparent,
                  highlightColor: widget.hasRippleEffect
                      ? Colors.white.withValues(alpha: 0.1)
                      : Colors.transparent,
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 12.h),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        if (widget.isLoading)
                          SizedBox(
                            width: 20.w,
                            height: 20.w,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                widget.textColor ?? Colors.white,
                              ),
                            ),
                          )
                        else if (widget.icon != null)
                          Icon(
                            widget.icon,
                            color: widget.isOutlined
                                ? (widget.backgroundColor ?? Theme.of(context).primaryColor)
                                : (widget.textColor ?? Colors.white),
                            size: 20.sp,
                          ),
                        if ((widget.icon != null || widget.isLoading) && widget.text.isNotEmpty)
                          SizedBox(width: 8.w),
                        if (widget.text.isNotEmpty)
                          Text(
                            widget.text,
                            style: TextStyle(
                              color: widget.isOutlined
                                  ? (widget.backgroundColor ?? Theme.of(context).primaryColor)
                                  : (widget.textColor ?? Colors.white),
                              fontSize: 16.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    )
        .animate()
        .fadeIn(duration: 300.ms)
        .slideY(begin: 0.2, end: 0, duration: 300.ms, curve: Curves.easeOutCubic);
  }
}
