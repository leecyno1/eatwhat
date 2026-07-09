import 'package:eatwhat_app/v2/core/data/models/taste_selection_models.dart';
import 'package:eatwhat_app/v2/core/theme/app_colors.dart';
import 'package:eatwhat_app/v2/features/home/widgets/taste_card_copy_helpers.dart';
import 'package:eatwhat_app/v2/features/home/widgets/taste_card_icon_helpers.dart';
import 'package:flutter/material.dart';

class TasteCardFooterPanel extends StatelessWidget {
  const TasteCardFooterPanel({
    super.key,
    required this.card,
    required this.accent,
    required this.ultraCompact,
    required this.labelFontSize,
    required this.descriptorSize,
    required this.descriptor,
  });

  final TasteDeckCard card;
  final Color accent;
  final bool ultraCompact;
  final double labelFontSize;
  final double descriptorSize;
  final String descriptor;

  @override
  Widget build(BuildContext context) {
    return switch (card.category) {
      'flavor' => _FlavorFooter(
          card: card,
          accent: accent,
          ultraCompact: ultraCompact,
          labelFontSize: labelFontSize,
          descriptorSize: descriptorSize,
          descriptor: descriptor,
        ),
      'ingredient' => _IngredientFooter(
          card: card,
          accent: accent,
          ultraCompact: ultraCompact,
          labelFontSize: labelFontSize,
          descriptorSize: descriptorSize,
          descriptor: descriptor,
        ),
      'scene' => _SceneFooter(
          card: card,
          accent: accent,
          ultraCompact: ultraCompact,
          labelFontSize: labelFontSize,
          descriptorSize: descriptorSize,
          descriptor: descriptor,
        ),
      'cuisine' => _CuisineFooter(
          card: card,
          accent: accent,
          ultraCompact: ultraCompact,
          labelFontSize: labelFontSize,
          descriptorSize: descriptorSize,
          descriptor: descriptor,
        ),
      'fortune' => _FortuneFooter(
          card: card,
          accent: accent,
          ultraCompact: ultraCompact,
          labelFontSize: labelFontSize,
          descriptorSize: descriptorSize,
          descriptor: descriptor,
        ),
      _ => _GenericFooter(
          card: card,
          accent: accent,
          ultraCompact: ultraCompact,
          labelFontSize: labelFontSize,
          descriptorSize: descriptorSize,
          descriptor: descriptor,
        ),
    };
  }
}

class _FooterBase extends StatelessWidget {
  const _FooterBase({
    required this.child,
    required this.accent,
    required this.ultraCompact,
    this.dashed = false,
  });

  final Widget child;
  final Color accent;
  final bool ultraCompact;
  final bool dashed;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        ultraCompact ? 5 : 7,
        ultraCompact ? 4 : 6,
        ultraCompact ? 5 : 7,
        ultraCompact ? 4 : 6,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.34),
        borderRadius: BorderRadius.circular(ultraCompact ? 12 : 14),
        border: Border.all(
          color: dashed
              ? accent.withValues(alpha: 0.26)
              : Colors.white.withValues(alpha: 0.24),
          width: dashed ? 1.1 : 1,
        ),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.18),
            accent.withValues(alpha: 0.07),
          ],
        ),
      ),
      child: child,
    );
  }
}

class _FlavorFooter extends StatelessWidget {
  const _FlavorFooter({
    required this.card,
    required this.accent,
    required this.ultraCompact,
    required this.labelFontSize,
    required this.descriptorSize,
    required this.descriptor,
  });

  final TasteDeckCard card;
  final Color accent;
  final bool ultraCompact;
  final double labelFontSize;
  final double descriptorSize;
  final String descriptor;

  @override
  Widget build(BuildContext context) {
    return _FooterBase(
      accent: accent,
      ultraCompact: ultraCompact,
      child: Row(
        children: [
          Container(
            width: ultraCompact ? 16 : 18,
            height: ultraCompact ? 16 : 18,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accent.withValues(alpha: 0.16),
            ),
            child: Center(
              child: Text(
                card.label.isEmpty ? '' : card.label.substring(0, 1),
                style: TextStyle(
                  color: accent,
                  fontSize: ultraCompact ? 10 : 12,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            child: _FooterTextBlock(
              card.label,
              descriptor,
              labelFontSize,
              descriptorSize,
              ultraCompact,
            ),
          ),
          const SizedBox(width: 4),
          _FooterOrb(
            accent: accent,
            ultraCompact: true,
            icon: tasteCardIconFor(card.iconName, card.category),
          ),
        ],
      ),
    );
  }
}

class _IngredientFooter extends StatelessWidget {
  const _IngredientFooter({
    required this.card,
    required this.accent,
    required this.ultraCompact,
    required this.labelFontSize,
    required this.descriptorSize,
    required this.descriptor,
  });

  final TasteDeckCard card;
  final Color accent;
  final bool ultraCompact;
  final double labelFontSize;
  final double descriptorSize;
  final String descriptor;

  @override
  Widget build(BuildContext context) {
    return _FooterBase(
      accent: accent,
      ultraCompact: ultraCompact,
      child: Row(
        children: [
          Container(
            width: 4,
            height: ultraCompact ? 22 : 28,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  accent.withValues(alpha: 0.82),
                  accent.withValues(alpha: 0.18),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _FooterTextBlock(
              card.label,
              descriptor,
              labelFontSize,
              descriptorSize,
              ultraCompact,
            ),
          ),
          const SizedBox(width: 8),
          Text(
            tasteCardMicroCode(card.id),
            style: TextStyle(
              color: accent.withValues(alpha: 0.42),
              fontSize: 8,
              fontWeight: FontWeight.w900,
              letterSpacing: 1.2,
            ),
          ),
        ],
      ),
    );
  }
}

class _SceneFooter extends StatelessWidget {
  const _SceneFooter({
    required this.card,
    required this.accent,
    required this.ultraCompact,
    required this.labelFontSize,
    required this.descriptorSize,
    required this.descriptor,
  });

  final TasteDeckCard card;
  final Color accent;
  final bool ultraCompact;
  final double labelFontSize;
  final double descriptorSize;
  final String descriptor;

  @override
  Widget build(BuildContext context) {
    return _FooterBase(
      accent: accent,
      ultraCompact: ultraCompact,
      dashed: true,
      child: Row(
        children: [
          Expanded(
            child: _FooterTextBlock(
              card.label,
              descriptor,
              labelFontSize,
              descriptorSize,
              ultraCompact,
            ),
          ),
          const SizedBox(width: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(3, (index) {
              return Container(
                margin: EdgeInsets.only(left: index == 0 ? 0 : 3),
                width: 4,
                height: 4,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: accent.withValues(alpha: 0.32 - index * 0.08),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}

class _CuisineFooter extends StatelessWidget {
  const _CuisineFooter({
    required this.card,
    required this.accent,
    required this.ultraCompact,
    required this.labelFontSize,
    required this.descriptorSize,
    required this.descriptor,
  });

  final TasteDeckCard card;
  final Color accent;
  final bool ultraCompact;
  final double labelFontSize;
  final double descriptorSize;
  final String descriptor;

  @override
  Widget build(BuildContext context) {
    return _FooterBase(
      accent: accent,
      ultraCompact: ultraCompact,
      child: Row(
        children: [
          Container(
            width: ultraCompact ? 18 : 20,
            height: ultraCompact ? 18 : 20,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: accent.withValues(alpha: 0.12),
            ),
            child: Icon(
              Icons.menu_book_rounded,
              size: ultraCompact ? 10 : 12,
              color: accent.withValues(alpha: 0.72),
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: _FooterTextBlock(
              card.label,
              descriptor,
              labelFontSize,
              descriptorSize,
              ultraCompact,
            ),
          ),
          Container(
            width: 3,
            height: ultraCompact ? 18 : 22,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.22),
              borderRadius: BorderRadius.circular(999),
            ),
          ),
        ],
      ),
    );
  }
}

class _FortuneFooter extends StatelessWidget {
  const _FortuneFooter({
    required this.card,
    required this.accent,
    required this.ultraCompact,
    required this.labelFontSize,
    required this.descriptorSize,
    required this.descriptor,
  });

  final TasteDeckCard card;
  final Color accent;
  final bool ultraCompact;
  final double labelFontSize;
  final double descriptorSize;
  final String descriptor;

  @override
  Widget build(BuildContext context) {
    return _FooterBase(
      accent: accent,
      ultraCompact: ultraCompact,
      dashed: true,
      child: Row(
        children: [
          Expanded(
            child: _FooterTextBlock(
              card.label,
              descriptor,
              labelFontSize,
              descriptorSize,
              ultraCompact,
            ),
          ),
          const SizedBox(width: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.auto_awesome_rounded,
                size: ultraCompact ? 12 : 14,
                color: accent.withValues(alpha: 0.54),
              ),
              const SizedBox(width: 4),
              Text(
                'LUCK',
                style: TextStyle(
                  color: accent.withValues(alpha: 0.48),
                  fontSize: 7.5,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 1.2,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GenericFooter extends StatelessWidget {
  const _GenericFooter({
    required this.card,
    required this.accent,
    required this.ultraCompact,
    required this.labelFontSize,
    required this.descriptorSize,
    required this.descriptor,
  });

  final TasteDeckCard card;
  final Color accent;
  final bool ultraCompact;
  final double labelFontSize;
  final double descriptorSize;
  final String descriptor;

  @override
  Widget build(BuildContext context) {
    return _FooterBase(
      accent: accent,
      ultraCompact: ultraCompact,
      child: Row(
        children: [
          Expanded(
            child: _FooterTextBlock(
              card.label,
              descriptor,
              labelFontSize,
              descriptorSize,
              ultraCompact,
            ),
          ),
          const SizedBox(width: 8),
          _FooterOrb(
            accent: accent,
            ultraCompact: ultraCompact,
            icon: tasteCardIconFor(card.iconName, card.category),
          ),
        ],
      ),
    );
  }
}

class _FooterTextBlock extends StatelessWidget {
  const _FooterTextBlock(
    this.title,
    this.subtitle,
    this.labelFontSize,
    this.descriptorSize,
    this.ultraCompact,
  );

  final String title;
  final String subtitle;
  final double labelFontSize;
  final double descriptorSize;
  final bool ultraCompact;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: labelFontSize,
            fontWeight: FontWeight.w900,
            color: AppColors.textPrimary,
            height: 1.0,
          ),
        ),
        if (!ultraCompact) ...[
          const SizedBox(height: 4),
          Text(
            subtitle,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: descriptorSize,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary.withValues(alpha: 0.5),
              letterSpacing: 0.2,
            ),
          ),
        ],
      ],
    );
  }
}

class _FooterOrb extends StatelessWidget {
  const _FooterOrb({
    required this.accent,
    required this.ultraCompact,
    required this.icon,
  });

  final Color accent;
  final bool ultraCompact;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: ultraCompact ? 24 : 30,
      height: ultraCompact ? 24 : 30,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            Colors.white.withValues(alpha: 0.88),
            accent.withValues(alpha: 0.2),
          ],
        ),
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.32),
        ),
      ),
      child: Icon(
        icon,
        size: ultraCompact ? 13 : 16,
        color: accent,
      ),
    );
  }
}
