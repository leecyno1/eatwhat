import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'dart:ui';

/// Glassmorphism主题系统 - 现代化毛玻璃效果
class GlassmorphismTheme {
  // 主色调 - 渐变色彩系统
  static const List<Color> primaryGradients = [
    Color(0xFF667eea), // 梦幻紫蓝
    Color(0xFF764ba2), // 优雅紫色
  ];

  static const List<Color> secondaryGradients = [
    Color(0xFFf093fb), // 温柔粉紫
    Color(0xFFf5576c), // 活力粉红
  ];

  static const List<Color> accentGradients = [
    Color(0xFF4facfe), // 清新蓝
    Color(0xFF00f2fe), // 青蓝
  ];

  static const List<Color> warmGradients = [
    Color(0xFFfa709a), // 温暖粉
    Color(0xFFfee140), // 明亮黄
  ];

  // 毛玻璃效果配置
  static const double blurRadius = 20.0;
  static const double opacity = 0.15;
  static const Color glassColor = Colors.white;

  // 阴影配置
  static const Color shadowColor = Color(0x1A000000);
  static const double shadowBlurRadius = 20.0;
  static const Offset shadowOffset = Offset(0, 10);

  /// 创建毛玻璃容器
  static Widget glassContainer({
    required Widget child,
    double? blurRadius,
    double? opacity,
    Color? color,
    EdgeInsetsGeometry? padding,
    BorderRadius? borderRadius,
    BoxBorder? border,
  }) {
    return ClipRRect(
      borderRadius: borderRadius ?? BorderRadius.circular(20.r),
      child: BackdropFilter(
        filter: ImageFilter.blur(
          sigmaX: blurRadius ?? GlassmorphismTheme.blurRadius,
          sigmaY: blurRadius ?? GlassmorphismTheme.blurRadius,
        ),
        child: Container(
          padding: padding ?? EdgeInsets.all(20.w),
          decoration: BoxDecoration(
            color: (color ?? glassColor).withOpacity(opacity ?? GlassmorphismTheme.opacity),
            borderRadius: borderRadius ?? BorderRadius.circular(20.r),
            border: border ??
                Border.all(
                  color: Colors.white.withOpacity(0.2),
                  width: 1.5,
                ),
            boxShadow: [
              BoxShadow(
                color: shadowColor,
                blurRadius: shadowBlurRadius,
                offset: shadowOffset,
              ),
            ],
          ),
          child: child,
        ),
      ),
    );
  }

  /// 创建渐变背景
  static Widget gradientBackground({
    required List<Color> colors,
    AlignmentGeometry? begin,
    AlignmentGeometry? end,
    required Widget child,
  }) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: colors,
          begin: begin ?? Alignment.topLeft,
          end: end ?? Alignment.bottomRight,
        ),
      ),
      child: child,
    );
  }

  /// 创建浮动卡片
  static Widget floatingCard({
    required Widget child,
    EdgeInsetsGeometry? margin,
    EdgeInsetsGeometry? padding,
    BorderRadius? borderRadius,
    List<BoxShadow>? shadows,
  }) {
    return Container(
      margin: margin ?? EdgeInsets.all(16.w),
      child: glassContainer(
        padding: padding ?? EdgeInsets.all(16.w),
        borderRadius: borderRadius ?? BorderRadius.circular(16.r),
        child: child,
      ),
    );
  }

  /// 创建按钮样式
  static ButtonStyle glassButtonStyle({
    Color? backgroundColor,
    double? borderRadius,
    EdgeInsetsGeometry? padding,
  }) {
    return ButtonStyle(
      backgroundColor: MaterialStateProperty.all(
        (backgroundColor ?? Colors.white).withOpacity(0.2),
      ),
      padding: MaterialStateProperty.all(
        padding ?? EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
      ),
      shape: MaterialStateProperty.all(
        RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadius ?? 12.r),
        ),
      ),
      elevation: MaterialStateProperty.all(0),
      shadowColor: MaterialStateProperty.all(Colors.transparent),
    );
  }

  /// 创建输入框样式
  static InputDecoration glassInputDecoration({
    String? hintText,
    Widget? prefixIcon,
    Widget? suffixIcon,
    Color? borderColor,
  }) {
    return InputDecoration(
      hintText: hintText,
      prefixIcon: prefixIcon,
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.white.withOpacity(0.1),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: BorderSide(
          color: (borderColor ?? Colors.white).withOpacity(0.3),
          width: 1,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: BorderSide(
          color: (borderColor ?? Colors.white).withOpacity(0.3),
          width: 1,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12.r),
        borderSide: BorderSide(
          color: (borderColor ?? Colors.white).withOpacity(0.6),
          width: 2,
        ),
      ),
      hintStyle: TextStyle(
        color: Colors.white.withOpacity(0.6),
        fontSize: 16.sp,
      ),
    );
  }

  /// 创建动画渐变背景
  static Widget animatedGradientBackground({
    required List<List<Color>> gradientSets,
    Duration? duration,
    required Widget child,
  }) {
    return AnimatedGradientBackground(
      gradientSets: gradientSets,
      duration: duration ?? const Duration(seconds: 8),
      child: child,
    );
  }
}

/// 动画渐变背景组件
class AnimatedGradientBackground extends StatefulWidget {
  final List<List<Color>> gradientSets;
  final Duration duration;
  final Widget child;

  const AnimatedGradientBackground({
    super.key,
    required this.gradientSets,
    required this.duration,
    required this.child,
  });

  @override
  State<AnimatedGradientBackground> createState() => _AnimatedGradientBackgroundState();
}

class _AnimatedGradientBackgroundState extends State<AnimatedGradientBackground>
    with TickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(_controller);
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final currentGradient = widget.gradientSets[_currentIndex];
        final nextGradient = widget.gradientSets[(_currentIndex + 1) % widget.gradientSets.length];

        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: _interpolateColors(currentGradient, nextGradient, _animation.value),
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: widget.child,
        );
      },
    );
  }

  List<Color> _interpolateColors(List<Color> colors1, List<Color> colors2, double t) {
    final maxLength = colors1.length > colors2.length ? colors1.length : colors2.length;
    final result = <Color>[];

    for (int i = 0; i < maxLength; i++) {
      final color1 = i < colors1.length ? colors1[i] : colors1.last;
      final color2 = i < colors2.length ? colors2[i] : colors2.last;

      result.add(Color.lerp(color1, color2, t)!);
    }

    return result;
  }
}
