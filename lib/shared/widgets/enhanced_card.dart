import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../themes/colors.dart';

/// 增强的卡片组件 - 现代化设计和交互动画
class EnhancedCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final Color? backgroundColor;
  final Gradient? gradient;
  final double? borderRadius;
  final List<BoxShadow>? customShadow;
  final bool showShimmer;
  final bool isClickable;
  final double? elevation;
  final Border? border;

  const EnhancedCard({
    super.key,
    required this.child,
    this.onTap,
    this.onLongPress,
    this.padding,
    this.margin,
    this.backgroundColor,
    this.gradient,
    this.borderRadius,
    this.customShadow,
    this.showShimmer = false,
    this.isClickable = true,
    this.elevation,
    this.border,
  });

  @override
  State<EnhancedCard> createState() => _EnhancedCardState();
}

class _EnhancedCardState extends State<EnhancedCard>
    with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late AnimationController _shimmerController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _shimmerAnimation;

  bool _isPressed = false;
  bool _isHovered = false;

  @override
  void initState() {
    super.initState();

    _scaleController = AnimationController(
      duration: const Duration(milliseconds: 150),
      vsync: this,
    );

    _shimmerController = AnimationController(
      duration: const Duration(milliseconds: 2000),
      vsync: this,
    );

    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.98,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeInOut,
    ));

    _shimmerAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _shimmerController,
      curve: Curves.easeInOut,
    ));

    if (widget.showShimmer) {
      _shimmerController.repeat();
    }
  }

  @override
  void dispose() {
    _scaleController.dispose();
    _shimmerController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (!widget.isClickable || widget.onTap == null) return;

    setState(() {
      _isPressed = true;
    });

    _scaleController.forward();
    HapticFeedback.lightImpact();
  }

  void _onTapUp(TapUpDetails details) {
    if (!widget.isClickable || widget.onTap == null) return;

    setState(() {
      _isPressed = false;
    });

    _scaleController.reverse();
    widget.onTap?.call();
  }

  void _onTapCancel() {
    if (!widget.isClickable || widget.onTap == null) return;

    setState(() {
      _isPressed = false;
    });

    _scaleController.reverse();
  }

  void _onPointerEnter(PointerEnterEvent event) {
    if (!widget.isClickable) return;

    setState(() {
      _isHovered = true;
    });
  }

  void _onPointerExit(PointerExitEvent event) {
    if (!widget.isClickable) return;

    setState(() {
      _isHovered = false;
    });
  }

  void _onLongPress() {
    if (!widget.isClickable) return;

    HapticFeedback.heavyImpact();
    widget.onLongPress?.call();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return AnimatedBuilder(
      animation: Listenable.merge([_scaleAnimation, _shimmerAnimation]),
      builder: (context, child) {
        return Container(
          margin: widget.margin,
          child: MouseRegion(
            onEnter: _onPointerEnter,
            onExit: _onPointerExit,
            child: GestureDetector(
              onTapDown: _onTapDown,
              onTapUp: _onTapUp,
              onTapCancel: _onTapCancel,
              onLongPress: _onLongPress,
              child: Transform.scale(
                scale: _scaleAnimation.value,
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 200),
                  curve: Curves.easeInOut,
                  padding: widget.padding ?? const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: widget.gradient == null
                        ? (widget.backgroundColor ?? colorScheme.surface)
                        : null,
                    gradient: widget.gradient,
                    borderRadius: BorderRadius.circular(
                      widget.borderRadius ?? 16,
                    ),
                    border: widget.border ??
                        (_isHovered
                            ? Border.all(
                                color:
                                    colorScheme.primary.withValues(alpha: 0.3),
                                width: 1,
                              )
                            : null),
                    boxShadow: _buildBoxShadow(colorScheme),
                  ),
                  child: Stack(
                    children: [
                      widget.child,
                      if (widget.showShimmer) _buildShimmerOverlay(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  /// 构建阴影效果
  List<BoxShadow> _buildBoxShadow(ColorScheme colorScheme) {
    if (widget.customShadow != null) {
      return widget.customShadow!;
    }

    if (_isHovered || _isPressed) {
      return [
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.12),
          blurRadius: 20,
          spreadRadius: 0,
          offset: const Offset(0, 8),
        ),
        BoxShadow(
          color: Colors.black.withValues(alpha: 0.08),
          blurRadius: 6,
          spreadRadius: 0,
          offset: const Offset(0, 4),
        ),
      ];
    }

    return AppShadows.cardShadow;
  }

  /// 构建微光覆盖层
  Widget _buildShimmerOverlay() {
    return Positioned.fill(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(widget.borderRadius ?? 16),
        child: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: 0.0),
                Colors.white.withValues(alpha: 0.1 * _shimmerAnimation.value),
                Colors.white.withValues(alpha: 0.2 * _shimmerAnimation.value),
                Colors.white.withValues(alpha: 0.0),
              ],
              stops: const [0.0, 0.4, 0.6, 1.0],
            ),
          ),
        ),
      ),
    );
  }
}

/// 加载中的卡片占位符
class LoadingCard extends StatelessWidget {
  final double? height;
  final double? width;
  final EdgeInsetsGeometry? margin;

  const LoadingCard({
    super.key,
    this.height,
    this.width,
    this.margin,
  });

  @override
  Widget build(BuildContext context) {
    return EnhancedCard(
      isClickable: false,
      showShimmer: true,
      margin: margin,
      child: Container(
        height: height ?? 120,
        width: width,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}

/// 空状态卡片
class EmptyStateCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onActionPressed;
  final String? actionText;
  final Color? iconColor;

  const EmptyStateCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.onActionPressed,
    this.actionText,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return EnhancedCard(
      isClickable: false,
      padding: const EdgeInsets.all(32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: (iconColor ?? colorScheme.primary).withValues(alpha: 0.1),
            ),
            child: const Icon(Icons.star),
          ),
          const SizedBox(height: 24),
          Text(
            title,
            style: theme.textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w600,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: theme.textTheme.bodyMedium?.copyWith(
              color: colorScheme.onSurface.withValues(alpha: 0.7),
            ),
            textAlign: TextAlign.center,
          ),
          if (onActionPressed != null && actionText != null) ...[
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: onActionPressed,
              icon: const Icon(Icons.add),
              label: Text(actionText!),
            ),
          ],
        ],
      ),
    );
  }
}
