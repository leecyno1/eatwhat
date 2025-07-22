import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:glassmorphism/glassmorphism.dart';
import 'package:flutter_animate/flutter_animate.dart';

/// 现代化卡片组件
class ModernCard extends StatefulWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? backgroundColor;
  final double? width;
  final double? height;
  final BorderRadius? borderRadius;
  final bool hasGlassEffect;
  final bool hasShadow;
  final VoidCallback? onTap;
  final double elevation;
  final Gradient? gradient;
  final Border? border;
  final bool isAnimated;

  const ModernCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.backgroundColor,
    this.width,
    this.height,
    this.borderRadius,
    this.hasGlassEffect = false,
    this.hasShadow = true,
    this.onTap,
    this.elevation = 4.0,
    this.gradient,
    this.border,
    this.isAnimated = true,
  });

  @override
  State<ModernCard> createState() => _ModernCardState();
}

class _ModernCardState extends State<ModernCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 200),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.98,
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
    if (widget.onTap != null && widget.isAnimated) {
      _animationController.forward();
    }
  }

  void _onTapUp(TapUpDetails details) {
    if (widget.onTap != null && widget.isAnimated) {
      _animationController.reverse();
    }
  }

  void _onTapCancel() {
    if (widget.onTap != null && widget.isAnimated) {
      _animationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    Widget cardContent = Container(
      width: widget.width,
      height: widget.height,
      padding: widget.padding ?? EdgeInsets.all(16.w),
      child: widget.child,
    );

    Widget decoratedCard;

    if (widget.hasGlassEffect) {
      decoratedCard = GlassmorphicContainer(
        width: widget.width ?? double.infinity,
        height: widget.height ?? double.infinity,
        borderRadius: (widget.borderRadius ?? BorderRadius.circular(16.r)).topLeft.x,
        linearGradient: LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.2),
            Colors.white.withValues(alpha: 0.1),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: 1,
        borderGradient: LinearGradient(
          colors: [
            Colors.white.withValues(alpha: 0.5),
            Colors.white.withValues(alpha: 0.2),
          ],
        ),
        blur: 20.0,
        child: cardContent,
      );
    } else {
      decoratedCard = Container(
        width: widget.width,
        height: widget.height,
        padding: widget.padding ?? EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          color: widget.backgroundColor ?? Colors.white,
          gradient: widget.gradient,
          borderRadius: widget.borderRadius ?? BorderRadius.circular(16.r),
          border: widget.border,
          boxShadow: widget.hasShadow
              ? [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.1),
                    blurRadius: widget.elevation * 2,
                    offset: Offset(0, widget.elevation),
                  ),
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.05),
                    blurRadius: widget.elevation,
                    offset: Offset(0, widget.elevation / 2),
                  ),
                ]
              : null,
        ),
        child: widget.child,
      );
    }

    Widget animatedCard = widget.isAnimated
        ? AnimatedBuilder(
            animation: _scaleAnimation,
            builder: (context, child) {
              return Transform.scale(
                scale: _scaleAnimation.value,
                child: decoratedCard,
              );
            },
          )
        : decoratedCard;

    return Container(
      margin: widget.margin,
      child: widget.onTap != null
          ? GestureDetector(
              onTapDown: _onTapDown,
              onTapUp: _onTapUp,
              onTapCancel: _onTapCancel,
              onTap: widget.onTap,
              child: animatedCard,
            )
          : animatedCard,
    ).animate()
      .fadeIn(duration: 400.ms, delay: 100.ms)
      .slideY(begin: 0.3, end: 0, duration: 400.ms, curve: Curves.easeOutCubic);
  }
}

/// 现代化信息卡片
class ModernInfoCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color iconColor;
  final VoidCallback? onTap;
  final Widget? trailing;

  const ModernInfoCard({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.iconColor,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return ModernCard(
      onTap: onTap,
      hasGlassEffect: true,
      child: Row(
        children: [
          Container(
            width: 48.w,
            height: 48.w,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(12.r),
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 24.sp,
            ),
          ),
          SizedBox(width: 16.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 14.sp,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

/// 现代化统计卡片
class ModernStatsCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final String? trend;
  final bool isPositiveTrend;

  const ModernStatsCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    this.trend,
    this.isPositiveTrend = true,
  });

  @override
  Widget build(BuildContext context) {
    return ModernCard(
      hasGlassEffect: true,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(
                icon,
                color: color,
                size: 24.sp,
              ),
              if (trend != null)
                Container(
                  padding: EdgeInsets.symmetric(horizontal: 8.w, vertical: 4.h),
                  decoration: BoxDecoration(
                    color: isPositiveTrend
                        ? Colors.green.withValues(alpha: 0.2)
                        : Colors.red.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8.r),
                  ),
                  child: Text(
                    trend!,
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: isPositiveTrend ? Colors.green : Colors.red,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: 12.h),
          Text(
            value,
            style: TextStyle(
              fontSize: 24.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            label,
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}