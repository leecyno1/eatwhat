import 'package:flutter/material.dart';
import '../../../shared/themes/design_tokens.dart';

class StatPill extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  final Color color;

  const StatPill(
      {super.key,
      required this.icon,
      required this.value,
      required this.label,
      this.color = DesignTokens.mint});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: DesignTokens.surface,
        borderRadius: DesignTokens.pillRadius,
        boxShadow: DesignTokens.softShadows(),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: BoxDecoration(color: color.withOpacity(0.2), shape: BoxShape.circle),
            child: Icon(icon, color: color, size: 16),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(value,
                      style: const TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 16, color: DesignTokens.ink)),
                  const SizedBox(width: 6),
                  Text(label, style: const TextStyle(fontSize: 12, color: DesignTokens.inkMuted)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
