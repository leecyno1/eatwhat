import 'package:flutter/material.dart';
import '../../../shared/themes/design_tokens.dart';
import 'rounded_card.dart';

class PercentCard extends StatelessWidget {
  final int percent;
  final String title;
  final String? subtitle;

  const PercentCard({super.key, required this.percent, required this.title, this.subtitle});

  @override
  Widget build(BuildContext context) {
    return RoundedCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: DesignTokens.h3),
          if (subtitle != null) ...[
            const SizedBox(height: 4),
            Text(subtitle!, style: DesignTokens.caption),
          ],
          const SizedBox(height: 12),
          Row(
            children: [
              Text('$percent%',
                  style: const TextStyle(
                      fontSize: 52, fontWeight: FontWeight.w800, color: DesignTokens.ink)),
              const Spacer(),
              Icon(Icons.open_in_new_rounded, color: DesignTokens.inkMuted)
            ],
          ),
        ],
      ),
    );
  }
}
