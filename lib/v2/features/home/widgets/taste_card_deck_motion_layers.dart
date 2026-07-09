import 'package:eatwhat_app/v2/core/data/models/taste_selection_models.dart';
import 'package:eatwhat_app/v2/core/theme/app_colors.dart';
import 'package:eatwhat_app/v2/features/home/widgets/taste_card_copy_helpers.dart';
import 'package:eatwhat_app/v2/features/home/widgets/taste_card_style_helpers.dart';
import 'package:flutter/material.dart';

class TasteDealEntryCard extends StatelessWidget {
  const TasteDealEntryCard({
    super.key,
    required this.index,
    required this.animation,
    required this.child,
  });

  final int index;
  final Animation<double> animation;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animation,
      child: child,
      builder: (context, builtChild) {
        final row = index ~/ 3;
        final column = index % 3;
        final laneBias = (column - 1).toDouble();
        final rowBias = (row - 1).toDouble();
        final start = (row * 0.09 + column * 0.035).clamp(0.0, 0.6);
        final end = (start + 0.42).clamp(0.42, 1.0);
        final raw = ((animation.value - start) / (end - start)).clamp(0.0, 1.0);
        final eased = Curves.easeOutBack.transform(raw);
        final settle = Curves.easeOutCubic.transform(raw);

        final dx = (1 - settle) * laneBias * 16;
        final dy = (1 - settle) * (22 + row * 6);
        final tilt =
            (1 - settle) * laneBias * 0.08 + (1 - settle) * rowBias * 0.015;
        final scale = 0.88 + eased * 0.12;
        final opacity = 0.08 + settle * 0.92;
        final glow = (1 - settle) * 0.2;

        return Opacity(
          opacity: opacity.clamp(0, 1),
          child: Transform(
            transform: Matrix4.identity()
              ..setEntry(3, 2, 0.001)
              ..translate(dx, dy)
              ..rotateZ(tilt)
              ..scale(scale),
            alignment: Alignment.center,
            child: DecoratedBox(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFF46B40).withValues(alpha: glow),
                    blurRadius: 18,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: builtChild,
            ),
          ),
        );
      },
    );
  }
}

class TasteOutgoingPageGhostCard extends StatelessWidget {
  const TasteOutgoingPageGhostCard({
    super.key,
    required this.card,
  });

  final TasteDeckCard card;

  @override
  Widget build(BuildContext context) {
    final colors = card.accentHexes.map(tasteCardParseHexColor).toList();
    final accentA = colors.isNotEmpty ? colors.first : const Color(0xFFF46B40);
    final accentB =
        colors.length > 1 ? colors[1] : accentA.withValues(alpha: 0.62);
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.52),
          width: 1.05,
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.52),
            accentA.withValues(alpha: 0.2),
            accentB.withValues(alpha: 0.24),
          ],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              tasteCardCategoryLabel(card.category),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 8,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary.withValues(alpha: 0.42),
                letterSpacing: 0.45,
              ),
            ),
            const Spacer(),
            Text(
              card.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w900,
                color: AppColors.textPrimary.withValues(alpha: 0.82),
                height: 1,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              tasteCardDescriptor(card),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 9,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary.withValues(alpha: 0.46),
                letterSpacing: 0.2,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class TasteFlipHintPill extends StatelessWidget {
  const TasteFlipHintPill({super.key});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.42),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFF46B40).withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.touch_app_rounded,
              size: 14,
              color: AppColors.textPrimary.withValues(alpha: 0.76),
            ),
            const SizedBox(width: 6),
            Text(
              '点按卡片翻面',
              style: TextStyle(
                color: AppColors.textPrimary.withValues(alpha: 0.78),
                fontSize: 11,
                fontWeight: FontWeight.w800,
                letterSpacing: 0.2,
              ),
            ),
            const SizedBox(width: 6),
            Container(
              width: 18,
              height: 18,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFF46B40).withValues(alpha: 0.12),
              ),
              child: const Icon(
                Icons.flip_rounded,
                size: 10,
                color: Color(0xFFF46B40),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
