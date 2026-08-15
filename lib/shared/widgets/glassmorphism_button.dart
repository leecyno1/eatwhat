import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import '../../core/theme/glassmorphism_theme.dart';

/// Glassmorphism风格按钮组件
class GlassmorphismButton extends StatefulWidget {
  final String? text;
  final Widget? icon;
  final VoidCallback? onPressed;
  final VoidCallback? onLongPress;
  final bool isLoading;
  final bool isEnabled;
  final GlassmorphismButtonStyle style;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final bool enableHapticFeedback;

  const GlassmorphismButton({
    super.key,
    this.text,
    this.icon,
    this.onPressed,
    this.onLongPress,
    this.isLoading = false,
    this.isEnabled = true,
    this.style = GlassmorphismButtonStyle.primary,
    this.width,
    this.height,
    this.padding,
    this.enableHapticFeedback = true,
  }) : assert(text != null || icon != null, 'Button must have either text or icon');

  @override
  State<GlassmorphismButton> createState() => _GlassmorphismButtonState();
}

class _GlassmorphismButtonState extends State<GlassmorphismButton> with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _glowController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;

  bool _isPressed = false;

  @override
  void initState() {
    super.initState();
    _initializeAnimations();
  }

  void _initializeAnimations() {
    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeInOut,
    ));

    _glowController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _glowAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _glowController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _glowController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_scaleController, _glowController]),
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: GestureDetector(
            onTapDown: _onTapDown,
            onTapUp: _onTapUp,
            onTapCancel: _onTapCancel,
            onLongPress: widget.onLongPress,
            child: _buildButtonContent(),
          ),
        );
      },
    );
  }

  Widget _buildButtonContent() {
    final isEnabled = widget.isEnabled && !widget.isLoading && widget.onPressed != null;

    return Container(
      width: widget.width,
      height: widget.height ?? 48.h,
      child: GlassmorphismTheme.glassContainer(
        padding: widget.padding ?? EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
        opacity: isEnabled ? 0.2 : 0.1,
        child: Stack(
          children: [
            // 发光效果
            if (_isPressed && isEnabled) _buildGlowEffect(),

            // 内容
            _buildContent(),
          ],
        ),
      ),
    );
  }

  Widget _buildGlowEffect() {
    return AnimatedBuilder(
      animation: _glowAnimation,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12.r),
            boxShadow: [
              BoxShadow(
                color: _getButtonColor().withOpacity(_glowAnimation.value * 0.5),
                blurRadius: 20,
                spreadRadius: 2,
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildContent() {
    if (widget.isLoading) {
      return Center(
        child: SizedBox(
          width: 20.w,
          height: 20.h,
          child: CircularProgressIndicator(
            strokeWidth: 2,
            valueColor: AlwaysStoppedAnimation<Color>(_getButtonColor()),
          ),
        ),
      );
    }

    final isEnabled = widget.isEnabled && widget.onPressed != null;
    final textColor = isEnabled ? Colors.white : Colors.white.withOpacity(0.5);
    final iconColor = isEnabled ? Colors.white : Colors.white.withOpacity(0.5);

    if (widget.icon != null && widget.text != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconTheme(
            data: IconThemeData(color: iconColor, size: 20.sp),
            child: widget.icon!,
          ),
          SizedBox(width: 8.w),
          Text(
            widget.text!,
            style: TextStyle(
              color: textColor,
              fontSize: 16.sp,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      );
    } else if (widget.icon != null) {
      return IconTheme(
        data: IconThemeData(color: iconColor, size: 24.sp),
        child: widget.icon!,
      );
    } else {
      return Text(
        widget.text!,
        style: TextStyle(
          color: textColor,
          fontSize: 16.sp,
          fontWeight: FontWeight.w600,
        ),
        textAlign: TextAlign.center,
      );
    }
  }

  Color _getButtonColor() {
    switch (widget.style) {
      case GlassmorphismButtonStyle.primary:
        return GlassmorphismTheme.primaryGradients.first;
      case GlassmorphismButtonStyle.secondary:
        return GlassmorphismTheme.secondaryGradients.first;
      case GlassmorphismButtonStyle.accent:
        return GlassmorphismTheme.accentGradients.first;
      case GlassmorphismButtonStyle.warm:
        return GlassmorphismTheme.warmGradients.first;
      case GlassmorphismButtonStyle.success:
        return Colors.green;
      case GlassmorphismButtonStyle.warning:
        return Colors.orange;
      case GlassmorphismButtonStyle.danger:
        return Colors.red;
    }
  }

  void _onTapDown(TapDownDetails details) {
    if (widget.isEnabled && !widget.isLoading && widget.onPressed != null) {
      setState(() {
        _isPressed = true;
      });
      _scaleController.forward();
      _glowController.forward();

      if (widget.enableHapticFeedback) {
        HapticFeedback.lightImpact();
      }
    }
  }

  void _onTapUp(TapUpDetails details) {
    if (widget.isEnabled && !widget.isLoading && widget.onPressed != null) {
      setState(() {
        _isPressed = false;
      });
      _scaleController.reverse();
      _glowController.reverse();

      widget.onPressed!();

      if (widget.enableHapticFeedback) {
        HapticFeedback.mediumImpact();
      }
    }
  }

  void _onTapCancel() {
    if (widget.isEnabled && !widget.isLoading) {
      setState(() {
        _isPressed = false;
      });
      _scaleController.reverse();
      _glowController.reverse();
    }
  }
}

/// 按钮样式枚举
enum GlassmorphismButtonStyle {
  primary,
  secondary,
  accent,
  warm,
  success,
  warning,
  danger,
}

/// 图标按钮
class GlassmorphismIconButton extends StatelessWidget {
  final Widget icon;
  final VoidCallback? onPressed;
  final VoidCallback? onLongPress;
  final bool isEnabled;
  final double size;
  final GlassmorphismButtonStyle style;
  final bool enableHapticFeedback;

  const GlassmorphismIconButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.onLongPress,
    this.isEnabled = true,
    this.size = 48.0,
    this.style = GlassmorphismButtonStyle.primary,
    this.enableHapticFeedback = true,
  });

  @override
  Widget build(BuildContext context) {
    return GlassmorphismButton(
      icon: icon,
      onPressed: onPressed,
      onLongPress: onLongPress,
      isEnabled: isEnabled,
      style: style,
      width: size,
      height: size,
      padding: EdgeInsets.all(12.w),
      enableHapticFeedback: enableHapticFeedback,
    );
  }
}

/// 浮动操作按钮
class GlassmorphismFloatingActionButton extends StatelessWidget {
  final Widget icon;
  final VoidCallback? onPressed;
  final GlassmorphismButtonStyle style;
  final double size;
  final bool enableHapticFeedback;

  const GlassmorphismFloatingActionButton({
    super.key,
    required this.icon,
    this.onPressed,
    this.style = GlassmorphismButtonStyle.primary,
    this.size = 56.0,
    this.enableHapticFeedback = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      child: GlassmorphismTheme.glassContainer(
        borderRadius: BorderRadius.circular(size / 2),
        child: IconButton(
          icon: icon,
          onPressed: onPressed,
          iconSize: size * 0.4,
          color: Colors.white,
        ),
      ),
    );
  }
}

/// 按钮组
class GlassmorphismButtonGroup extends StatelessWidget {
  final List<GlassmorphismButton> buttons;
  final Axis direction;
  final double spacing;

  const GlassmorphismButtonGroup({
    super.key,
    required this.buttons,
    this.direction = Axis.horizontal,
    this.spacing = 16.0,
  });

  @override
  Widget build(BuildContext context) {
    if (direction == Axis.horizontal) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: _buildButtonList(),
      );
    } else {
      return Column(
        mainAxisSize: MainAxisSize.min,
        children: _buildButtonList(),
      );
    }
  }

  List<Widget> _buildButtonList() {
    final List<Widget> widgets = [];

    for (int i = 0; i < buttons.length; i++) {
      widgets.add(buttons[i]);

      if (i < buttons.length - 1) {
        widgets.add(SizedBox(
          width: direction == Axis.horizontal ? spacing : 0,
          height: direction == Axis.vertical ? spacing : 0,
        ));
      }
    }

    return widgets;
  }
}
