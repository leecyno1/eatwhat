import 'package:flutter/material.dart';
import '../../../shared/themes/design_tokens.dart';

class PrimaryCtaButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  const PrimaryCtaButton({super.key, required this.label, this.onPressed, this.icon});

  @override
  Widget build(BuildContext context) {
    final btn = ElevatedButton.icon(
      onPressed: onPressed,
      icon: Icon(icon ?? Icons.play_arrow_rounded, size: 20),
      label: Text(label, style: const TextStyle(fontWeight: FontWeight.w700)),
      style: ElevatedButton.styleFrom(
        backgroundColor: DesignTokens.ink,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        shape: const StadiumBorder(),
        elevation: 0,
      ),
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: DesignTokens.pillRadius,
        boxShadow: DesignTokens.softShadows(DesignTokens.ink),
      ),
      child: btn,
    );
  }
}
