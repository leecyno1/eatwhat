import 'package:flutter/material.dart';
import '../../../shared/themes/design_tokens.dart';

/// A large rounded card with soft shadow and optional gradient header area.
class RoundedCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final EdgeInsetsGeometry? margin;
  final Color? color;

  const RoundedCard(
      {super.key,
      required this.child,
      this.padding = const EdgeInsets.all(16),
      this.margin,
      this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin ?? const EdgeInsets.symmetric(vertical: DesignTokens.md),
      decoration: BoxDecoration(
        color: color ?? DesignTokens.surface,
        borderRadius: DesignTokens.bigRadius,
        boxShadow: DesignTokens.softShadows(),
      ),
      padding: padding,
      child: child,
    );
  }
}
