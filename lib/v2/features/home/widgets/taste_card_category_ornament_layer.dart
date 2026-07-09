import 'package:eatwhat_app/v2/core/data/models/taste_selection_models.dart';
import 'package:flutter/material.dart';

class TasteCardCategoryOrnamentLayer extends StatelessWidget {
  const TasteCardCategoryOrnamentLayer({
    super.key,
    required this.card,
    required this.accentA,
    required this.accentB,
  });

  final TasteDeckCard card;
  final Color accentA;
  final Color accentB;

  @override
  Widget build(BuildContext context) {
    final category = card.category;
    switch (category) {
      case 'flavor':
        return Stack(
          children: [
            Positioned(
              top: -18,
              right: -10,
              child: Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      accentA.withValues(alpha: 0.18),
                      accentA.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              top: 18,
              right: 14,
              child: Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: accentA.withValues(alpha: 0.16),
                  ),
                ),
              ),
            ),
            if (card.motionPreset == 'flare' || card.motionPreset == 'pulse')
              Positioned(
                top: 20,
                right: 24,
                child: Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        accentB.withValues(alpha: 0.18),
                        accentB.withValues(alpha: 0),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        );
      case 'ingredient':
        return Stack(
          children: [
            Positioned(
              left: 12,
              top: 12,
              bottom: 12,
              child: Container(
                width: 18,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      accentA.withValues(alpha: 0.16),
                      accentB.withValues(alpha: 0.05),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              left: 18,
              top: 18,
              bottom: 18,
              child: Container(
                width: 3,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: Colors.white.withValues(alpha: 0.38),
                ),
              ),
            ),
            if (card.symbolLayout == 'vertical')
              Positioned(
                left: 24,
                top: 26,
                bottom: 26,
                child: Container(
                  width: 1.2,
                  color: accentA.withValues(alpha: 0.16),
                ),
              ),
          ],
        );
      case 'scene':
        return Stack(
          children: [
            Positioned(
              left: -6,
              right: -6,
              bottom: 18,
              child: Transform.rotate(
                angle: -0.18,
                child: Container(
                  height: 34,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        accentA.withValues(alpha: 0.12),
                        accentB.withValues(alpha: 0.03),
                      ],
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              right: 14,
              bottom: 14,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(3, (index) {
                  return Container(
                    margin: EdgeInsets.only(left: index == 0 ? 0 : 4),
                    width: 4,
                    height: 4,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: accentA.withValues(alpha: 0.32 - index * 0.07),
                    ),
                  );
                }),
              ),
            ),
            if (card.motionPreset == 'twinkle')
              Positioned(
                top: 18,
                right: 26,
                child: Icon(
                  Icons.auto_awesome_rounded,
                  size: 16,
                  color: accentB.withValues(alpha: 0.18),
                ),
              ),
          ],
        );
      default:
        return Stack(
          children: [
            Positioned(
              left: 14,
              right: 14,
              top: 22,
              child: Container(
                height: 1.5,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  gradient: LinearGradient(
                    colors: [
                      accentA.withValues(alpha: 0.28),
                      accentB.withValues(alpha: 0.08),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              right: 16,
              bottom: 16,
              child: Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      accentA.withValues(alpha: 0.2),
                      accentB.withValues(alpha: 0),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
    }
  }
}
