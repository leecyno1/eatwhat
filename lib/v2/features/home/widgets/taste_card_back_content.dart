import 'package:eatwhat_app/v2/core/data/models/taste_selection_models.dart';
import 'package:eatwhat_app/v2/core/theme/app_tokens.dart';
import 'package:eatwhat_app/v2/features/home/widgets/taste_card_chips.dart';
import 'package:eatwhat_app/v2/features/home/widgets/taste_card_copy_helpers.dart';
import 'package:flutter/material.dart';

class TasteCardBackContent extends StatelessWidget {
  const TasteCardBackContent({
    super.key,
    required this.card,
    required this.accentA,
    required this.previewColor,
    required this.compact,
    required this.ultraCompact,
    required this.categoryFontSize,
    required this.labelFontSize,
    required this.descriptorSize,
    required this.activeReaction,
  });

  final TasteDeckCard card;
  final Color accentA;
  final Color previewColor;
  final bool compact;
  final bool ultraCompact;
  final double categoryFontSize;
  final double labelFontSize;
  final double descriptorSize;
  final TasteCardReaction? activeReaction;

  @override
  Widget build(BuildContext context) {
    final blurb = (card.blurb?.trim().isNotEmpty ?? false)
        ? card.blurb!.trim()
        : tasteCardDefaultBlurb(card);
    final examples = tasteCardBackExamples(card)
        .take(ultraCompact
            ? 1
            : compact
                ? 2
                : 3)
        .toList();

    return Column(
      key: ValueKey('taste-card-back-layout-${card.category}-${card.id}'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: ultraCompact ? 26 : 32,
              height: ultraCompact ? 26 : 32,
              decoration: BoxDecoration(
                color: accentA.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadii.xs),
              ),
              child: Icon(
                _iconFor(card.category),
                size: ultraCompact ? 15 : 18,
                color: accentA,
              ),
            ),
            const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: Text(
                tasteCardCategoryLabel(card.category),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppType.microLabel.copyWith(
                  color: AppPalette.inkMuted,
                  fontSize: categoryFontSize,
                ),
              ),
            ),
            if (activeReaction != null)
              TasteCardReactionChip(
                reaction: activeReaction!,
                color: previewColor,
                compact: true,
              ),
          ],
        ),
        SizedBox(height: ultraCompact ? 6 : 10),
        Text(
          tasteCardBackTitle(card),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppType.section.copyWith(
            fontSize: labelFontSize,
            color: AppPalette.ink,
          ),
        ),
        SizedBox(height: ultraCompact ? 4 : 8),
        Expanded(
          child: Text(
            blurb,
            maxLines: ultraCompact
                ? 2
                : compact
                    ? 3
                    : 5,
            overflow: TextOverflow.ellipsis,
            style: AppType.body.copyWith(
              fontSize: descriptorSize,
              height: 1.35,
            ),
          ),
        ),
        if (examples.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.xs),
          Wrap(
            spacing: 5,
            runSpacing: 5,
            children: [
              for (final example in examples)
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: ultraCompact ? 5 : 7,
                    vertical: ultraCompact ? 3 : 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppPalette.surfaceMuted,
                    borderRadius: AppRadii.capsule,
                  ),
                  child: Text(
                    example,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppType.microLabel.copyWith(
                      color: AppPalette.inkSoft,
                      fontSize: ultraCompact ? 7 : 9,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ],
    );
  }

  IconData _iconFor(String category) {
    return switch (category) {
      'flavor' => Icons.tune_rounded,
      'ingredient' => Icons.restaurant_menu_rounded,
      'scene' => Icons.schedule_rounded,
      'cuisine' => Icons.public_rounded,
      'staple' => Icons.rice_bowl_rounded,
      'dietary' => Icons.eco_rounded,
      _ => Icons.notes_rounded,
    };
  }
}
