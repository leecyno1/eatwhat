import 'package:eatwhat_app/v2/core/data/models/taste_selection_models.dart';
import 'package:flutter/material.dart';

class TasteCardCategoryLayoutMotif extends StatelessWidget {
  const TasteCardCategoryLayoutMotif({
    super.key,
    required this.card,
    required this.accentA,
    required this.accentB,
    required this.compact,
  });

  final TasteDeckCard card;
  final Color accentA;
  final Color accentB;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final category = card.category;
    switch (category) {
      case 'flavor':
        return Positioned(
          left: 16,
          right: 20,
          top: compact ? 46 : 52,
          child: IgnorePointer(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: compact ? 36 : 42,
                  height: compact ? 36 : 42,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: RadialGradient(
                      colors: [
                        accentA.withValues(alpha: 0.26),
                        accentA.withValues(alpha: 0.04),
                      ],
                    ),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Icon(
                    Icons.brightness_high_rounded,
                    size: compact ? 16 : 18,
                    color: accentA.withValues(alpha: 0.48),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        height: 6,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          gradient: LinearGradient(
                            colors: [
                              accentA.withValues(alpha: 0.42),
                              accentB.withValues(alpha: 0.08),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 6,
                        margin: const EdgeInsets.only(right: 28),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          color: accentA.withValues(alpha: 0.18),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 6,
                        margin: const EdgeInsets.only(right: 54),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(999),
                          color: accentB.withValues(alpha: 0.16),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      case 'ingredient':
        return Positioned(
          left: 14,
          right: 18,
          top: compact ? 48 : 54,
          child: IgnorePointer(
            child: Row(
              children: [
                Container(
                  width: 18,
                  height: compact ? 68 : 76,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        accentA.withValues(alpha: 0.28),
                        accentB.withValues(alpha: 0.08),
                      ],
                    ),
                  ),
                  child: Center(
                    child: Container(
                      width: 4,
                      height: compact ? 48 : 56,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.28),
                        borderRadius: BorderRadius.circular(999),
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _IngredientGuideBar(
                        widthFactor: 0.92,
                        accent: accentA,
                        compact: compact,
                      ),
                      const SizedBox(height: 8),
                      _IngredientGuideBar(
                        widthFactor: 0.74,
                        accent: accentB,
                        compact: compact,
                      ),
                      const SizedBox(height: 8),
                      _IngredientGuideBar(
                        widthFactor: 0.56,
                        accent: accentA,
                        compact: compact,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      case 'cuisine':
        return Positioned(
          left: 16,
          right: 18,
          top: compact ? 44 : 50,
          child: IgnorePointer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: compact ? 6 : 8,
                    vertical: compact ? 5 : 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.24),
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: accentA.withValues(alpha: 0.16),
                    ),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: compact ? 14 : 16,
                        height: compact ? 14 : 16,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: accentA.withValues(alpha: 0.14),
                        ),
                        child: Icon(
                          Icons.menu_book_rounded,
                          size: compact ? 8 : 10,
                          color: accentA.withValues(alpha: 0.46),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Container(
                          height: 4,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(999),
                            gradient: LinearGradient(
                              colors: [
                                accentA.withValues(alpha: 0.34),
                                accentB.withValues(alpha: 0.12),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                Container(
                  height: compact ? 34 : 40,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    color: Colors.white.withValues(alpha: 0.16),
                  ),
                  child: Row(
                    children: List.generate(3, (index) {
                      return Expanded(
                        child: Container(
                          margin: EdgeInsets.only(
                            left: index == 0 ? 6 : 3,
                            right: index == 2 ? 6 : 3,
                            top: 6,
                            bottom: 6,
                          ),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            color: (index == 1 ? accentB : accentA)
                                .withValues(alpha: 0.08 + index * 0.03),
                          ),
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),
        );
      case 'fortune':
        return Positioned(
          left: 18,
          right: 22,
          top: compact ? 42 : 48,
          child: IgnorePointer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Transform.rotate(
                  angle: -0.08,
                  child: Container(
                    width: compact ? 82 : 92,
                    padding: EdgeInsets.symmetric(
                      horizontal: compact ? 10 : 12,
                      vertical: compact ? 7 : 8,
                    ),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      color: Colors.white.withValues(alpha: 0.24),
                      border: Border.all(
                        color: accentA.withValues(alpha: 0.14),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.auto_awesome_rounded,
                          size: compact ? 12 : 14,
                          color: accentA.withValues(alpha: 0.46),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Container(
                            height: 5,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(999),
                              color: accentB.withValues(alpha: 0.16),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Row(
                  children: List.generate(3, (index) {
                    return Expanded(
                      child: Container(
                        margin: EdgeInsets.only(right: index == 2 ? 0 : 6),
                        height: compact ? 38 : 44,
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.14),
                          ),
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              (index == 1 ? accentB : accentA)
                                  .withValues(alpha: 0.12),
                              Colors.white.withValues(alpha: 0.04),
                            ],
                          ),
                        ),
                      ),
                    );
                  }),
                ),
              ],
            ),
          ),
        );
      case 'scene':
        return Positioned(
          left: 14,
          right: 18,
          top: compact ? 46 : 52,
          child: IgnorePointer(
            child: Stack(
              children: [
                Transform.rotate(
                  angle: -0.07,
                  child: Container(
                    height: compact ? 38 : 44,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(18),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.16),
                      ),
                      gradient: LinearGradient(
                        colors: [
                          accentA.withValues(alpha: 0.12),
                          accentB.withValues(alpha: 0.04),
                        ],
                      ),
                    ),
                  ),
                ),
                Positioned(
                  left: 12,
                  top: compact ? 12 : 14,
                  child: Container(
                    width: compact ? 52 : 60,
                    height: 4,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      color: Colors.white.withValues(alpha: 0.26),
                    ),
                  ),
                ),
                Positioned(
                  right: 12,
                  bottom: compact ? 10 : 12,
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: List.generate(3, (index) {
                      return Container(
                        margin: EdgeInsets.only(left: index == 0 ? 0 : 4),
                        width: compact ? 5 : 6,
                        height: compact ? 5 : 6,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: accentA.withValues(alpha: 0.34 - index * 0.08),
                        ),
                      );
                    }),
                  ),
                ),
              ],
            ),
          ),
        );
      default:
        return Positioned(
          left: 16,
          right: 18,
          top: compact ? 48 : 54,
          child: IgnorePointer(
            child: Container(
              height: compact ? 42 : 50,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(18),
                gradient: LinearGradient(
                  colors: [
                    accentA.withValues(alpha: 0.08),
                    accentB.withValues(alpha: 0.03),
                  ],
                ),
              ),
            ),
          ),
        );
    }
  }
}

class _IngredientGuideBar extends StatelessWidget {
  const _IngredientGuideBar({
    required this.widthFactor,
    required this.accent,
    required this.compact,
  });

  final double widthFactor;
  final Color accent;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return FractionallySizedBox(
      alignment: Alignment.centerLeft,
      widthFactor: widthFactor,
      child: Container(
        height: compact ? 12 : 14,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: accent.withValues(alpha: 0.12),
        ),
      ),
    );
  }
}
