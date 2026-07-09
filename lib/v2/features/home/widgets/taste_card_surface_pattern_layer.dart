import 'package:eatwhat_app/v2/core/data/models/taste_selection_models.dart';
import 'package:eatwhat_app/v2/features/home/widgets/taste_card_texture_painters.dart';
import 'package:flutter/material.dart';

class TasteCardSurfacePatternLayer extends StatelessWidget {
  const TasteCardSurfacePatternLayer({
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
    switch (card.surfacePattern) {
      case 'ember':
        return Positioned(
          left: 14,
          right: 14,
          bottom: 14,
          child: IgnorePointer(
            child: Row(
              children: List.generate(5, (index) {
                return Expanded(
                  child: Container(
                    margin: EdgeInsets.only(right: index == 4 ? 0 : 4),
                    height: compact ? 18 : 22,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          accentA.withValues(alpha: 0.18 + index * 0.02),
                          accentB.withValues(alpha: 0.02),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        );
      case 'ripples':
        return Positioned.fill(
          child: IgnorePointer(
            child: Stack(
              children: List.generate(3, (index) {
                final size = (compact ? 42.0 : 52.0) + index * 18;
                return Positioned(
                  right: 10 + index * 8,
                  top: 26 + index * 10,
                  child: Container(
                    width: size,
                    height: size,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: (index.isEven ? accentA : accentB)
                            .withValues(alpha: 0.11 - index * 0.02),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        );
      case 'confetti':
        return Positioned.fill(
          child: IgnorePointer(
            child: Stack(
              children: List.generate(7, (index) {
                final isWarm = index.isEven;
                return Positioned(
                  left: 18 + (index % 3) * 24,
                  top: 26 + (index ~/ 3) * 18,
                  child: Transform.rotate(
                    angle: (index.isEven ? -1 : 1) * 0.36,
                    child: Container(
                      width: index % 2 == 0 ? 16 : 10,
                      height: 4,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        color: (isWarm ? accentA : accentB)
                            .withValues(alpha: 0.14),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        );
      case 'zigzag':
        return Positioned(
          right: 16,
          top: compact ? 54 : 60,
          child: IgnorePointer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(4, (index) {
                return Container(
                  margin: EdgeInsets.only(bottom: index == 3 ? 0 : 7),
                  width: 34 - index * 4,
                  height: 5,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    color: (index.isEven ? accentA : accentB)
                        .withValues(alpha: 0.16),
                  ),
                );
              }),
            ),
          ),
        );
      case 'velvet':
        return Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    accentA.withValues(alpha: 0.04),
                    accentB.withValues(alpha: 0.08),
                  ],
                  stops: const [0.0, 0.58, 1.0],
                ),
              ),
            ),
          ),
        );
      case 'marble':
      case 'grain':
      case 'paper':
      case 'porcelain':
        return Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: LinearTexturePainter(
                primary: accentA,
                secondary: accentB,
                angleSeed: switch (card.surfacePattern) {
                  'paper' => -0.18,
                  'porcelain' => 0.08,
                  'grain' => 0.28,
                  _ => 0.18,
                },
              ),
            ),
          ),
        );
      case 'grid':
        return Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: GridTexturePainter(color: accentA),
            ),
          ),
        );
      case 'seed':
      case 'coin':
        return Positioned(
          left: 16,
          right: 16,
          bottom: 18,
          child: IgnorePointer(
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: List.generate(8, (index) {
                return Container(
                  width: compact ? 6 : 8,
                  height: compact ? 6 : 8,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: (index % 3 == 0 ? accentB : accentA)
                        .withValues(alpha: 0.14),
                    border: card.surfacePattern == 'coin'
                        ? Border.all(
                            color: Colors.white.withValues(alpha: 0.18),
                            width: 0.8,
                          )
                        : null,
                  ),
                );
              }),
            ),
          ),
        );
      case 'feather':
      case 'petals':
        return Positioned(
          left: 14,
          bottom: 18,
          child: IgnorePointer(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: List.generate(3, (index) {
                return Transform.rotate(
                  angle: -0.24 + index * 0.12,
                  child: Container(
                    margin: EdgeInsets.only(bottom: index == 2 ? 0 : 6),
                    width: 30 - index * 4,
                    height: 14,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      gradient: LinearGradient(
                        colors: [
                          accentA.withValues(alpha: 0.16),
                          accentB.withValues(alpha: 0.05),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        );
      case 'sunbeam':
      case 'moon-arc':
      case 'steam-ring':
        return Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: ArcTexturePainter(
                color: accentA,
                secondary: accentB,
                mode: card.surfacePattern,
              ),
            ),
          ),
        );
      case 'constellation':
        return Positioned.fill(
          child: IgnorePointer(
            child: CustomPaint(
              painter: ConstellationTexturePainter(
                primary: accentA,
                secondary: accentB,
              ),
            ),
          ),
        );
      default:
        return const SizedBox.shrink();
    }
  }
}
