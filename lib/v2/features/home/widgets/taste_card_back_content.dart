import 'package:eatwhat_app/v2/core/data/models/taste_selection_models.dart';
import 'package:eatwhat_app/v2/core/theme/app_colors.dart';
import 'package:eatwhat_app/v2/features/home/widgets/taste_card_chips.dart';
import 'package:eatwhat_app/v2/features/home/widgets/taste_card_copy_helpers.dart';
import 'package:eatwhat_app/v2/features/home/widgets/taste_card_style_helpers.dart';
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
    final examples = tasteCardBackExamples(card);
    final blurb = (card.blurb?.trim().isNotEmpty ?? false)
        ? card.blurb!.trim()
        : tasteCardDefaultBlurb(card);
    final compactView = compact || ultraCompact;
    final exampleCount = ultraCompact ? 1 : (compact ? 2 : 3);
    final visibleExamples = examples.take(exampleCount).toList();

    if (ultraCompact) {
      return _UltraCompactBackCardContent(
        card: card,
        accentA: accentA,
        previewColor: previewColor,
        categoryFontSize: categoryFontSize,
        labelFontSize: labelFontSize,
        activeReaction: activeReaction,
        examples: visibleExamples,
      );
    }

    if (compact) {
      return _CompactBackCardContent(
        card: card,
        accentA: accentA,
        previewColor: previewColor,
        categoryFontSize: categoryFontSize,
        labelFontSize: labelFontSize,
        descriptorSize: descriptorSize,
        activeReaction: activeReaction,
        blurb: blurb,
        examples: visibleExamples,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _BackSealBadge(
              key: ValueKey('taste-card-back-seal-${card.category}-${card.id}'),
              card: card,
              accent: accentA,
              compact: false,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _BackSerialPlate(
                key: ValueKey('taste-card-back-serial-${card.id}'),
                card: card,
                accent: accentA,
                compact: false,
              ),
            ),
            if (activeReaction != null) ...[
              const SizedBox(width: 4),
              TasteCardReactionChip(
                reaction: activeReaction!,
                color: previewColor,
                compact: true,
              ),
            ] else ...[
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: accentA.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: accentA.withValues(alpha: 0.16),
                  ),
                ),
                child: Text(
                  'TAP',
                  style: TextStyle(
                    color: AppColors.textPrimary.withValues(alpha: 0.48),
                    fontSize: 8,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ],
          ],
        ),
        SizedBox(height: ultraCompact ? 6 : 8),
        Expanded(
          child: ClipRect(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tasteCardBackTitle(card),
                  maxLines: compactView ? 1 : 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: ultraCompact
                        ? labelFontSize + 0.2
                        : labelFontSize + 0.8,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                    height: 0.98,
                    letterSpacing: -0.15,
                  ),
                ),
                SizedBox(height: ultraCompact ? 5 : 7),
                Container(
                  padding: EdgeInsets.symmetric(
                    horizontal: compactView ? 7 : 8,
                    vertical: compactView ? 4 : 7,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.22),
                    borderRadius: BorderRadius.circular(ultraCompact ? 12 : 14),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Text(
                    blurb,
                    maxLines: compactView ? 1 : 3,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: descriptorSize,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textPrimary.withValues(alpha: 0.62),
                      height: 1.15,
                    ),
                  ),
                ),
                SizedBox(height: ultraCompact ? 5 : 7),
                Expanded(
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: _BackCategoryLayout(
                      key: ValueKey(
                          'taste-card-back-layout-${card.category}-${card.id}'),
                      card: card,
                      accent: accentA,
                      compact: compactView,
                    ),
                  ),
                ),
                if (!compactView) ...[
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 26,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: visibleExamples.map((example) {
                          return Padding(
                            padding: const EdgeInsets.only(right: 5),
                            child: _BackExampleChip(
                              label: example,
                              accent: accentA,
                              compact: false,
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _BackSealBadge extends StatelessWidget {
  const _BackSealBadge({
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
    return Container(
      width: compact ? 24 : 28,
      height: compact ? 24 : 28,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: accent.withValues(alpha: 0.12),
        border: Border.all(
          color: accent.withValues(alpha: 0.22),
        ),
      ),
      child: Center(
        child: Text(
          tasteCardSignatureConfigFor(card.category).glyph,
          style: TextStyle(
            color: accent.withValues(alpha: 0.88),
            fontSize: compact ? 11 : 13,
            fontWeight: FontWeight.w900,
            height: 1,
          ),
        ),
      ),
    );
  }
}

class _BackSerialPlate extends StatelessWidget {
  const _BackSerialPlate({
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
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 7 : 8,
        vertical: compact ? 4 : 5,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.48),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: accent.withValues(alpha: 0.14),
        ),
      ),
      child: Text(
        'SIGN ${tasteCardMicroCode(card.id)} · ${tasteCardArtCode(card.artKey)}',
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          color: AppColors.textPrimary.withValues(alpha: 0.62),
          fontSize: compact ? 8 : 8.6,
          fontWeight: FontWeight.w900,
          letterSpacing: 0.8,
          height: 1,
        ),
      ),
    );
  }
}

class _CompactBackCardContent extends StatelessWidget {
  const _CompactBackCardContent({
    required this.card,
    required this.accentA,
    required this.previewColor,
    required this.categoryFontSize,
    required this.labelFontSize,
    required this.descriptorSize,
    required this.activeReaction,
    required this.blurb,
    required this.examples,
  });

  final TasteDeckCard card;
  final Color accentA;
  final Color previewColor;
  final double categoryFontSize;
  final double labelFontSize;
  final double descriptorSize;
  final TasteCardReaction? activeReaction;
  final String blurb;
  final List<String> examples;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _BackSealBadge(
              key: ValueKey('taste-card-back-seal-${card.category}-${card.id}'),
              card: card,
              accent: accentA,
              compact: true,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: _BackSerialPlate(
                key: ValueKey('taste-card-back-serial-${card.id}'),
                card: card,
                accent: accentA,
                compact: true,
              ),
            ),
            const SizedBox(width: 6),
            if (activeReaction != null)
              TasteCardReactionChip(
                reaction: activeReaction!,
                color: previewColor,
                compact: true,
              ),
          ],
        ),
        const SizedBox(height: 6),
        Expanded(
          child: ClipRect(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  tasteCardBackTitle(card),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: labelFontSize + 0.2,
                    fontWeight: FontWeight.w900,
                    color: AppColors.textPrimary,
                    height: 0.98,
                  ),
                ),
                const SizedBox(height: 6),
                Expanded(
                  child: Align(
                    alignment: Alignment.topLeft,
                    child: _BackCategoryLayout(
                      key: ValueKey(
                          'taste-card-back-layout-${card.category}-${card.id}'),
                      card: card,
                      accent: accentA,
                      compact: true,
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        blurb,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: descriptorSize,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary.withValues(alpha: 0.56),
                          height: 1.05,
                        ),
                      ),
                    ),
                    if (examples.isNotEmpty) ...[
                      const SizedBox(width: 6),
                      _BackExampleChip(
                        label: examples.first,
                        accent: accentA,
                        compact: true,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _UltraCompactBackCardContent extends StatelessWidget {
  const _UltraCompactBackCardContent({
    required this.card,
    required this.accentA,
    required this.previewColor,
    required this.categoryFontSize,
    required this.labelFontSize,
    required this.activeReaction,
    required this.examples,
  });

  final TasteDeckCard card;
  final Color accentA;
  final Color previewColor;
  final double categoryFontSize;
  final double labelFontSize;
  final TasteCardReaction? activeReaction;
  final List<String> examples;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            _BackSealBadge(
              key: ValueKey('taste-card-back-seal-${card.category}-${card.id}'),
              card: card,
              accent: accentA,
              compact: true,
            ),
            const SizedBox(width: 5),
            Expanded(
              child: _BackSerialPlate(
                key: ValueKey('taste-card-back-serial-${card.id}'),
                card: card,
                accent: accentA,
                compact: true,
              ),
            ),
            const SizedBox(width: 3),
            if (activeReaction != null)
              TasteCardReactionChip(
                reaction: activeReaction!,
                color: previewColor,
                compact: true,
              )
            else
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                decoration: BoxDecoration(
                  color: accentA.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Text(
                  '翻面',
                  style: TextStyle(
                    color: AppColors.textPrimary.withValues(alpha: 0.5),
                    fontSize: categoryFontSize,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 3),
        Expanded(
          child: ClipRect(
            child: Align(
              alignment: Alignment.topLeft,
              child: _BackCategoryLayout(
                key: ValueKey(
                    'taste-card-back-layout-${card.category}-${card.id}'),
                card: card,
                accent: accentA,
                compact: true,
              ),
            ),
          ),
        ),
        const SizedBox(height: 2),
        Text(
          tasteCardBackTitle(card),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: categoryFontSize + 1,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimary.withValues(alpha: 0.56),
            height: 1,
          ),
        ),
      ],
    );
  }
}

class _BackCategoryLayout extends StatelessWidget {
  const _BackCategoryLayout({
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
    return switch (card.category) {
      'flavor' => _BackFlavorLayout(accent: accent, compact: compact),
      'ingredient' => _BackIngredientLayout(accent: accent, compact: compact),
      'scene' => _BackSceneLayout(accent: accent, compact: compact),
      'cuisine' => _BackCuisineLayout(accent: accent, compact: compact),
      'fortune' => _BackFortuneLayout(accent: accent, compact: compact),
      _ => _BackGenericLayout(accent: accent, compact: compact),
    };
  }
}

class _BackExampleChip extends StatelessWidget {
  const _BackExampleChip({
    required this.label,
    required this.accent,
    required this.compact,
  });

  final String label;
  final Color accent;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 7 : 8,
        vertical: compact ? 4 : 5,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.42),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: accent.withValues(alpha: 0.16),
        ),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: AppColors.textPrimary.withValues(alpha: 0.72),
          fontSize: compact ? 8.5 : 9.2,
          fontWeight: FontWeight.w800,
          height: 1,
        ),
      ),
    );
  }
}

class _BackFlavorLayout extends StatelessWidget {
  const _BackFlavorLayout({
    required this.accent,
    required this.compact,
  });

  final Color accent;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    final heights = compact ? [10.0, 16.0, 12.0] : [12.0, 20.0, 14.0];
    return Row(
      children: [
        Container(
          width: compact ? 22 : 24,
          height: compact ? 28 : 32,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            color: accent.withValues(alpha: 0.12),
            border: Border.all(
              color: accent.withValues(alpha: 0.16),
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              Container(
                width: compact ? 10 : 12,
                height: compact ? 14 : 17,
                margin: const EdgeInsets.only(bottom: 3),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [
                      accent.withValues(alpha: 0.82),
                      accent.withValues(alpha: 0.26),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 7),
        Expanded(
          child: Row(
            children: List.generate(3, (index) {
              return Expanded(
                child: Padding(
                  padding: EdgeInsets.only(right: index == 2 ? 0 : 5),
                  child: Align(
                    alignment: Alignment.bottomCenter,
                    child: Container(
                      height: heights[index],
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(999),
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            accent.withValues(alpha: 0.68 - index * 0.08),
                            accent.withValues(alpha: 0.14),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}

class _BackIngredientLayout extends StatelessWidget {
  const _BackIngredientLayout({
    required this.accent,
    required this.compact,
  });

  final Color accent;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: compact ? 16 : 18,
          height: compact ? 24 : 28,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            color: accent.withValues(alpha: 0.12),
          ),
          child: Center(
            child: Container(
              width: 3,
              height: compact ? 14 : 18,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                color: accent.withValues(alpha: 0.55),
              ),
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            children: List.generate(2, (index) {
              return Container(
                margin: EdgeInsets.only(bottom: index == 0 ? 5 : 0),
                height: compact ? 7 : 8,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  gradient: LinearGradient(
                    colors: [
                      accent.withValues(alpha: 0.36 - index * 0.08),
                      accent.withValues(alpha: 0.08),
                    ],
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}

class _BackSceneLayout extends StatelessWidget {
  const _BackSceneLayout({
    required this.accent,
    required this.compact,
  });

  final Color accent;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(3, (index) {
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: index == 2 ? 0 : 6),
            child: Container(
              height: compact ? 20 : 24,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: Colors.white.withValues(alpha: 0.22),
                border: Border.all(
                  color: accent.withValues(alpha: 0.12),
                ),
              ),
              child: Center(
                child: Container(
                  width: compact ? 12 : 14,
                  height: compact ? 3 : 4,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    color: accent.withValues(alpha: 0.4 - index * 0.08),
                  ),
                ),
              ),
            ),
          ),
        );
      }),
    );
  }
}

class _BackCuisineLayout extends StatelessWidget {
  const _BackCuisineLayout({
    required this.accent,
    required this.compact,
  });

  final Color accent;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 7 : 8,
            vertical: compact ? 5 : 6,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(999),
            color: accent.withValues(alpha: 0.12),
          ),
          child: Icon(
            Icons.route_rounded,
            size: compact ? 11 : 12,
            color: accent.withValues(alpha: 0.8),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Row(
            children: List.generate(3, (index) {
              return Expanded(
                child: Container(
                  margin: EdgeInsets.only(right: index == 2 ? 0 : 5),
                  height: compact ? 6 : 7,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(999),
                    color: accent.withValues(alpha: 0.2 + index * 0.08),
                  ),
                ),
              );
            }),
          ),
        ),
      ],
    );
  }
}

class _BackFortuneLayout extends StatelessWidget {
  const _BackFortuneLayout({
    required this.accent,
    required this.compact,
  });

  final Color accent;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: compact ? 24 : 28,
          height: compact ? 24 : 28,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: accent.withValues(alpha: 0.1),
            border: Border.all(
              color: accent.withValues(alpha: 0.16),
            ),
          ),
          child: Icon(
            Icons.auto_awesome_rounded,
            size: compact ? 12 : 14,
            color: accent.withValues(alpha: 0.64),
          ),
        ),
        const SizedBox(width: 6),
        Expanded(
          child: Row(
            children: List.generate(3, (index) {
              return Expanded(
                child: Row(
                  children: [
                    Container(
                      margin: EdgeInsets.only(right: index == 2 ? 0 : 0),
                      width: compact ? 6 : 7,
                      height: compact ? 6 : 7,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: accent.withValues(alpha: 0.24 + index * 0.12),
                      ),
                    ),
                    if (index != 2)
                      Expanded(
                        child: Container(
                          height: 1.5,
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          color: accent.withValues(alpha: 0.18 + index * 0.06),
                        ),
                      ),
                  ],
                ),
              );
            }),
          ),
        ),
        Icon(
          Icons.stars_rounded,
          size: compact ? 12 : 14,
          color: accent.withValues(alpha: 0.42),
        ),
      ],
    );
  }
}

class _BackGenericLayout extends StatelessWidget {
  const _BackGenericLayout({
    required this.accent,
    required this.compact,
  });

  final Color accent;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: List.generate(2, (index) {
        return Expanded(
          child: Container(
            margin: EdgeInsets.only(right: index == 1 ? 0 : 6),
            height: compact ? 18 : 20,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(10),
              color: accent.withValues(alpha: 0.1 + index * 0.06),
            ),
          ),
        );
      }),
    );
  }
}
