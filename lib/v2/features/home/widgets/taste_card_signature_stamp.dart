import 'package:eatwhat_app/v2/core/data/models/taste_selection_models.dart';
import 'package:eatwhat_app/v2/features/home/widgets/taste_card_style_helpers.dart';
import 'package:flutter/material.dart';

class TasteCardSignatureStamp extends StatelessWidget {
  const TasteCardSignatureStamp({
    super.key,
    required this.card,
    required this.accent,
    required this.compact,
  });

  final TasteDeckCard card;
  final Color accent;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final config = tasteCardSignatureConfigForCard(card);

    return IgnorePointer(
      child: Transform.rotate(
        angle: config.angle,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xFF110B09).withValues(alpha: 0.52),
            borderRadius: BorderRadius.circular(config.radius),
            border: Border.all(
              color: accent.withValues(alpha: 0.34),
            ),
            boxShadow: [
              BoxShadow(
                color: accent.withValues(alpha: 0.18),
                blurRadius: 16,
                offset: const Offset(0, 7),
              ),
            ],
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 6 : 7,
              vertical: compact ? 3 : 4,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  config.glyph,
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.78),
                    fontSize: compact ? 13 : 16,
                    fontWeight: FontWeight.w900,
                    height: 0.92,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  config.code,
                  style: TextStyle(
                    color: accent.withValues(alpha: 0.76),
                    fontSize: compact ? 6.4 : 6.8,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.9,
                    height: 1,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
