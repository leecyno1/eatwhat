import 'dart:math' as math;

import 'package:eatwhat_app/v2/core/data/models/taste_selection_models.dart';
import 'package:eatwhat_app/v2/core/theme/app_colors.dart';
import 'package:eatwhat_app/v2/features/home/widgets/taste_card_back_content.dart';
import 'package:eatwhat_app/v2/features/home/widgets/taste_card_chips.dart';
import 'package:eatwhat_app/v2/features/home/widgets/taste_card_copy_helpers.dart';
import 'package:eatwhat_app/v2/features/home/widgets/taste_card_footer_panel.dart';
import 'package:eatwhat_app/v2/features/home/widgets/taste_card_game_assets.dart';
import 'package:eatwhat_app/v2/features/home/widgets/taste_card_icon_helpers.dart';
import 'package:eatwhat_app/v2/features/home/widgets/taste_card_reaction_effects.dart';
import 'package:eatwhat_app/v2/features/home/widgets/taste_card_signature_stamp.dart';
import 'package:eatwhat_app/v2/features/home/widgets/taste_card_style_helpers.dart';
import 'package:eatwhat_app/v2/features/home/widgets/taste_card_surface_pattern_layer.dart';
import 'package:flutter/material.dart';

class TasteGridCardFace extends StatelessWidget {
  const TasteGridCardFace({
    super.key,
    required this.card,
    required this.reaction,
    required this.dragReaction,
    required this.dragProgress,
    required this.isCommitting,
    required this.isFlipped,
  });

  final TasteDeckCard card;
  final TasteCardReaction? reaction;
  final TasteCardReaction? dragReaction;
  final double dragProgress;
  final bool isCommitting;
  final bool isFlipped;

  @override
  Widget build(BuildContext context) {
    final colors = card.accentHexes.map(tasteCardParseHexColor).toList();
    final accentA = colors.isNotEmpty ? colors.first : const Color(0xFFF46B40);
    final accentB =
        colors.length > 1 ? colors[1] : accentA.withValues(alpha: 0.72);
    final activeReaction = reaction ?? dragReaction;
    final isResolved = reaction != null;
    final isPreviewing = reaction == null && dragReaction != null;
    final previewColor = _reactionColor(activeReaction, accentA);
    final descriptor = tasteCardDescriptor(card);
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxHeight <= 220;
        final ultraCompact = constraints.maxHeight < 132;
        final sidePadding = ultraCompact ? 7.0 : 8.0;
        final topPadding = ultraCompact ? 6.0 : 7.0;
        final bottomPadding = ultraCompact ? 6.0 : 7.0;
        final labelFontSize = ultraCompact ? 17.2 : 19.2;
        final descriptorSize = ultraCompact ? 8.2 : 9.2;
        final categoryFontSize = ultraCompact ? 7.2 : 8.0;
        final frontContent = KeyedSubtree(
          key: ValueKey('taste-card-front-${card.category}-${card.id}'),
          child: _UnifiedCardContent(
            card: card,
            activeReaction: activeReaction,
            previewColor: previewColor,
            accentA: accentA,
            accentB: accentB,
            descriptor: descriptor,
            compact: compact,
            ultraCompact: ultraCompact,
            categoryFontSize: categoryFontSize,
            labelFontSize: labelFontSize,
            descriptorSize: descriptorSize,
          ),
        );
        final backContent = KeyedSubtree(
          key: ValueKey('taste-card-back-${card.category}-${card.id}'),
          child: TasteCardBackContent(
            card: card,
            accentA: accentA,
            previewColor: previewColor,
            compact: compact,
            ultraCompact: ultraCompact,
            categoryFontSize: categoryFontSize,
            labelFontSize: labelFontSize,
            descriptorSize: descriptorSize,
            activeReaction: activeReaction,
          ),
        );

        return AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24),
            border: Border.all(
              color: activeReaction == null
                  ? Colors.white.withValues(alpha: isResolved ? 0.92 : 0.78)
                  : previewColor.withValues(
                      alpha: isResolved ? 0.9 : 0.78,
                    ),
              width: activeReaction == null ? 1.1 : 1.3,
            ),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                Colors.white.withValues(alpha: isResolved ? 0.82 : 0.68),
                accentA.withValues(
                  alpha: activeReaction == null
                      ? (isResolved ? 0.24 : 0.18)
                      : 0.2 + (dragProgress * 0.06),
                ),
                (activeReaction == null ? accentB : previewColor).withValues(
                  alpha: activeReaction == null
                      ? (isResolved ? 0.3 : 0.22)
                      : 0.24 + (dragProgress * 0.08),
                ),
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: (activeReaction == null ? accentA : previewColor)
                    .withValues(
                  alpha: isResolved ? 0.16 : (0.1 + dragProgress * 0.08),
                ),
                blurRadius: activeReaction == null ? 18 : 22,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Stack(
            children: [
              Positioned(
                left: 10,
                right: 10,
                top: 8,
                child: IgnorePointer(
                  child: Container(
                    height: ultraCompact ? 18 : 24,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withValues(alpha: 0.34),
                          Colors.white.withValues(alpha: 0),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
              TasteGameCardFrameLayer(
                key: ValueKey(
                    'taste-card-game-frame-${card.category}-${card.id}'),
                card: card,
                compact: compact,
              ),
              TasteCardSurfacePatternLayer(
                key: ValueKey(
                    'taste-card-pattern-${card.id}-${card.surfacePattern}'),
                card: card,
                accentA: accentA,
                accentB: accentB,
                compact: compact,
              ),
              TasteGameCardArtLayer(
                key:
                    ValueKey('taste-card-game-art-${card.category}-${card.id}'),
                card: card,
                compact: compact,
              ),
              if (reaction != null)
                Positioned.fill(
                  child: IgnorePointer(
                    child: TasteReactionImpactPulse(
                      key: ValueKey(
                          'taste-card-reaction-pulse-${reaction!.name}-${card.id}'),
                      reaction: reaction!,
                      accent: previewColor,
                    ),
                  ),
                ),
              TasteGameCardEffectLayer(
                key: ValueKey(
                    'taste-card-game-effect-${card.category}-${card.id}'),
                reaction: activeReaction,
                progress: dragProgress,
              ),
              Positioned(
                right: compact ? 16 : 20,
                top: compact ? 23 : 31,
                child: TasteCardSignatureStamp(
                  key: ValueKey(
                      'taste-card-signature-${card.category}-${card.id}'),
                  card: card,
                  accent: accentA,
                  compact: compact,
                ),
              ),
              Positioned(
                right: tasteCardSymbolIconOffset(card.symbolLayout, compact).dx,
                bottom:
                    tasteCardSymbolIconOffset(card.symbolLayout, compact).dy,
                child: IgnorePointer(
                  child: Icon(
                    tasteCardIconFor(card.iconName, card.category),
                    size: compact ? 24 : 34,
                    color: accentA.withValues(
                      alpha: tasteCardIconOpacity(card.motionPreset, compact),
                    ),
                  ),
                ),
              ),
              Positioned.fill(
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    sidePadding,
                    topPadding,
                    sidePadding,
                    bottomPadding,
                  ),
                  child: _CardFaceFlip(
                    isFlipped: isFlipped,
                    front: frontContent,
                    back: backContent,
                  ),
                ),
              ),
              if (isPreviewing)
                Align(
                  alignment: dragReaction == TasteCardReaction.liked
                      ? Alignment.topCenter
                      : Alignment.bottomCenter,
                  child: Container(
                    margin: EdgeInsets.only(
                      top: dragReaction == TasteCardReaction.liked ? 8 : 0,
                      bottom:
                          dragReaction == TasteCardReaction.disliked ? 8 : 0,
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: const Color(0xFF160D09).withValues(alpha: 0.78),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: previewColor.withValues(alpha: 0.62),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: previewColor.withValues(alpha: 0.28),
                          blurRadius: 18,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    foregroundDecoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(999),
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.white.withValues(alpha: 0.18),
                          Colors.transparent,
                        ],
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          dragReaction == TasteCardReaction.liked
                              ? Icons.keyboard_arrow_up_rounded
                              : Icons.keyboard_arrow_down_rounded,
                          size: 15,
                          color: Colors.white.withValues(alpha: 0.92),
                        ),
                        const SizedBox(width: 2),
                        Text(
                          dragReaction == TasteCardReaction.liked
                              ? '加入牌组'
                              : '弃置',
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.96),
                            fontSize: 10.2,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              if (isCommitting)
                Align(
                  child: Container(
                    key: ValueKey('taste-card-commit-indicator-${card.id}'),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.72),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: previewColor.withValues(alpha: 0.24),
                      ),
                    ),
                    child: Text(
                      dragReaction == TasteCardReaction.liked ? '已入牌组' : '已弃置',
                      style: TextStyle(
                        color: previewColor,
                        fontSize: 10,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.3,
                      ),
                    ),
                  ),
                ),
              if (reaction != null)
                Positioned(
                  top: 8,
                  right: 8,
                  child: _ReactionStampBadge(
                    key: ValueKey(
                        'taste-card-reaction-stamp-${reaction!.name}-${card.id}'),
                    reaction: reaction!,
                    accent: previewColor,
                  ),
                ),
            ],
          ),
        );
      },
    );
  }
}

class _ReactionStampBadge extends StatelessWidget {
  const _ReactionStampBadge({
    super.key,
    required this.reaction,
    required this.accent,
  });

  final TasteCardReaction reaction;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final style = _StampVisualSpec.fromReaction(reaction, accent);

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.72, end: 1),
      duration: const Duration(milliseconds: 260),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Opacity(
            opacity: value.clamp(0.0, 1.0),
            child: child,
          ),
        );
      },
      child: Transform.rotate(
        angle: style.angle,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            gradient: style.outerGradient,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: style.color.withValues(alpha: 0.56),
              width: 1.1,
            ),
            boxShadow: [
              BoxShadow(
                color: style.color.withValues(alpha: 0.2),
                blurRadius: 12,
                offset: const Offset(0, 5),
              ),
            ],
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: Stack(
              children: [
                Positioned.fill(
                  child: TasteStampTextureLayer(
                    reaction: reaction,
                    color: style.color,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    gradient: style.innerGradient,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: style.color.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        style.icon,
                        size: 10,
                        color: style.color,
                      ),
                      const SizedBox(width: 3),
                      Text(
                        style.label,
                        style: TextStyle(
                          color: style.color,
                          fontSize: 8.6,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.25,
                          height: 1,
                        ),
                      ),
                    ],
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

class _StampVisualSpec {
  const _StampVisualSpec({
    required this.label,
    required this.color,
    required this.icon,
    required this.angle,
    required this.outerGradient,
    required this.innerGradient,
  });

  factory _StampVisualSpec.fromReaction(
    TasteCardReaction reaction,
    Color accent,
  ) {
    switch (reaction) {
      case TasteCardReaction.liked:
        const color = Color(0xFFF46B40);
        return _StampVisualSpec(
          label: '战利品',
          color: color,
          icon: Icons.bookmark_added_rounded,
          angle: -0.16,
          outerGradient: LinearGradient(
            colors: [
              Colors.white.withValues(alpha: 0.82),
              color.withValues(alpha: 0.2),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          innerGradient: LinearGradient(
            colors: [
              Colors.white.withValues(alpha: 0.58),
              color.withValues(alpha: 0.08),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        );
      case TasteCardReaction.disliked:
        const color = Color(0xFF6A626B);
        return _StampVisualSpec(
          label: '封印',
          color: color,
          icon: Icons.block_rounded,
          angle: 0.13,
          outerGradient: LinearGradient(
            colors: [
              Colors.white.withValues(alpha: 0.78),
              color.withValues(alpha: 0.22),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          innerGradient: LinearGradient(
            colors: [
              color.withValues(alpha: 0.1),
              Colors.white.withValues(alpha: 0.46),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        );
      case TasteCardReaction.skipped:
        final color = accent.withValues(alpha: 0.78);
        return _StampVisualSpec(
          label: '略过',
          color: color,
          icon: Icons.skip_next_rounded,
          angle: -0.1,
          outerGradient: LinearGradient(
            colors: [
              Colors.white.withValues(alpha: 0.8),
              color.withValues(alpha: 0.18),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
          innerGradient: LinearGradient(
            colors: [
              color.withValues(alpha: 0.08),
              Colors.white.withValues(alpha: 0.5),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        );
    }
  }

  final String label;
  final Color color;
  final IconData icon;
  final double angle;
  final LinearGradient outerGradient;
  final LinearGradient innerGradient;
}

class _UnifiedCardContent extends StatelessWidget {
  const _UnifiedCardContent({
    required this.card,
    required this.activeReaction,
    required this.previewColor,
    required this.accentA,
    required this.accentB,
    required this.descriptor,
    required this.compact,
    required this.ultraCompact,
    required this.categoryFontSize,
    required this.labelFontSize,
    required this.descriptorSize,
  });

  final TasteDeckCard card;
  final TasteCardReaction? activeReaction;
  final Color previewColor;
  final Color accentA;
  final Color accentB;
  final String descriptor;
  final bool compact;
  final bool ultraCompact;
  final double categoryFontSize;
  final double labelFontSize;
  final double descriptorSize;

  @override
  Widget build(BuildContext context) {
    final rarity = tasteCardCategoryLabel(card.category);
    final affixes = tasteCardAffixesFor(card);
    final effect = tasteCardEffectFor(card);
    final symbol = tasteCardSignatureConfigForCard(card);
    if (compact) {
      return ClipRect(
        child: FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.topLeft,
          child: SizedBox(
            width: 124,
            child: _CompactUnifiedCardContent(
              card: card,
              activeReaction: activeReaction,
              previewColor: previewColor,
              accentA: accentA,
              accentB: accentB,
              descriptor: descriptor,
              categoryFontSize: categoryFontSize,
              labelFontSize: labelFontSize,
              descriptorSize: descriptorSize,
              rarity: rarity,
              ultraCompact: ultraCompact,
            ),
          ),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _RarityBadge(
              key: ValueKey('taste-card-rarity-${card.category}-${card.id}'),
              rarity: rarity,
              accentA: accentA,
              accentB: accentB,
              compact: compact,
              categoryFontSize: categoryFontSize,
            ),
            const Spacer(),
            if (activeReaction != null)
              TasteCardReactionChip(
                reaction: activeReaction!,
                color: previewColor,
                compact: true,
              )
            else
              TasteCardMicroCodePill(
                text: tasteCardMicroCode(card.id),
                accent: accentA,
              ),
          ],
        ),
        const SizedBox(height: 5),
        _TasteHeroVisual(
          key: ValueKey('taste-card-hero-${card.category}-${card.id}'),
          card: card,
          accentA: accentA,
          accentB: accentB,
          compact: compact,
          ultraCompact: ultraCompact,
          symbol: symbol,
        ),
        const SizedBox(height: 5),
        _CardTitleBlock(
          key: ValueKey('taste-card-title-block-${card.category}-${card.id}'),
          card: card,
          accent: accentA,
          descriptor: descriptor,
          compact: compact,
          ultraCompact: ultraCompact,
          labelFontSize: labelFontSize,
          descriptorSize: descriptorSize,
        ),
        const SizedBox(height: 5),
        _TasteAffixRow(
          key: ValueKey('taste-card-affixes-${card.category}-${card.id}'),
          affixes: affixes,
          accent: accentA,
          compact: compact,
        ),
        const SizedBox(height: 5),
        _TasteEffectPanel(
          key: ValueKey('taste-card-effect-${card.category}-${card.id}'),
          effect: effect,
          accent: previewColor,
          compact: compact,
          ultraCompact: ultraCompact,
        ),
        if (!compact && !ultraCompact) ...[
          const Spacer(),
          _TasteCardFooterRow(
            key: ValueKey('taste-card-footer-${card.category}-${card.id}'),
            card: card,
            accent: accentA,
            compact: compact,
            descriptor: descriptor,
          )
        ] else
          TasteCardFooterPanel(
            key: ValueKey('taste-card-footer-${card.category}-${card.id}'),
            card: card,
            accent: accentA,
            ultraCompact: true,
            labelFontSize: labelFontSize,
            descriptorSize: descriptorSize,
            descriptor: descriptor,
          ),
      ],
    );
  }
}

class _CompactUnifiedCardContent extends StatelessWidget {
  const _CompactUnifiedCardContent({
    required this.card,
    required this.activeReaction,
    required this.previewColor,
    required this.accentA,
    required this.accentB,
    required this.descriptor,
    required this.categoryFontSize,
    required this.labelFontSize,
    required this.descriptorSize,
    required this.rarity,
    required this.ultraCompact,
  });

  final TasteDeckCard card;
  final TasteCardReaction? activeReaction;
  final Color previewColor;
  final Color accentA;
  final Color accentB;
  final String descriptor;
  final double categoryFontSize;
  final double labelFontSize;
  final double descriptorSize;
  final String rarity;
  final bool ultraCompact;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 124,
      height: ultraCompact ? 126 : 204,
      child: Stack(
        children: [
          Positioned(
            left: 8,
            top: ultraCompact ? 7 : 10,
            child: _RarityBadge(
              key: ValueKey('taste-card-rarity-${card.category}-${card.id}'),
              rarity: rarity,
              accentA: accentA,
              accentB: accentB,
              compact: true,
              categoryFontSize: categoryFontSize,
            ),
          ),
          Positioned(
            right: 8,
            top: ultraCompact ? 7 : 10,
            child: activeReaction == null
                ? const SizedBox.shrink()
                : TasteCardReactionChip(
                    reaction: activeReaction!,
                    color: previewColor,
                    compact: true,
                  ),
          ),
          Positioned(
            left: 6,
            right: 6,
            top: ultraCompact ? 25 : 34,
            child: _CompactPreferenceSignal(
              key: ValueKey('taste-card-hero-${card.category}-${card.id}'),
              card: card,
              accent: accentA,
              ultraCompact: ultraCompact,
            ),
          ),
          Positioned(
            left: 8,
            right: 8,
            bottom: ultraCompact ? 30 : 43,
            child: _CompactCardTitlePlaque(
              key: ValueKey(
                'taste-card-title-block-${card.category}-${card.id}',
              ),
              card: card,
              accent: accentA,
              descriptor: descriptor,
              labelFontSize: labelFontSize,
              descriptorSize: descriptorSize,
              ultraCompact: ultraCompact,
            ),
          ),
          SizedBox(
            key: ValueKey('taste-card-affixes-${card.category}-${card.id}'),
            height: 0,
          ),
          Positioned(
            left: 6,
            right: 6,
            bottom: ultraCompact ? 7 : 14,
            child: _CompactPreferenceRule(
              key: ValueKey('taste-card-effect-${card.category}-${card.id}'),
              card: card,
              accent: previewColor,
              ultraCompact: ultraCompact,
            ),
          ),
          SizedBox(
            key: ValueKey('taste-card-footer-${card.category}-${card.id}'),
            height: 0,
          ),
        ],
      ),
    );
  }
}

class _CompactPreferenceSignal extends StatelessWidget {
  const _CompactPreferenceSignal({
    super.key,
    required this.card,
    required this.accent,
    required this.ultraCompact,
  });

  final TasteDeckCard card;
  final Color accent;
  final bool ultraCompact;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: ultraCompact ? 42 : 52,
        height: ultraCompact ? 42 : 52,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: const Color(0xFF0E0907).withValues(alpha: 0.34),
          border: Border.all(color: accent.withValues(alpha: 0.46)),
          boxShadow: [
            BoxShadow(
              color: accent.withValues(alpha: 0.26),
              blurRadius: 22,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            Text(
              card.label.isEmpty ? '' : card.label[0],
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.76),
                fontSize: ultraCompact ? 22 : 26,
                fontWeight: FontWeight.w900,
                height: 1,
              ),
            ),
            Icon(
              tasteCardIconFor(card.iconName, card.category),
              size: ultraCompact ? 18 : 22,
              color: accent.withValues(alpha: 0.9),
            ),
          ],
        ),
      ),
    );
  }
}

class _CompactCardTitlePlaque extends StatelessWidget {
  const _CompactCardTitlePlaque({
    super.key,
    required this.card,
    required this.accent,
    required this.descriptor,
    required this.labelFontSize,
    required this.descriptorSize,
    required this.ultraCompact,
  });

  final TasteDeckCard card;
  final Color accent;
  final String descriptor;
  final double labelFontSize;
  final double descriptorSize;
  final bool ultraCompact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        ultraCompact ? 8 : 9,
        ultraCompact ? 5 : 7,
        ultraCompact ? 8 : 9,
        ultraCompact ? 5 : 7,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFF140D09).withValues(alpha: 0.68),
        borderRadius: BorderRadius.circular(ultraCompact ? 13 : 15),
        border: Border.all(color: accent.withValues(alpha: 0.38)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.24),
            blurRadius: 10,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            card.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.96),
              fontSize:
                  ultraCompact ? labelFontSize + 0.8 : labelFontSize + 1.0,
              fontWeight: tasteCardHeadlineWeight(card.headlineStyle),
              height: 1,
              fontStyle: tasteCardHeadlineItalic(card.headlineStyle)
                  ? FontStyle.italic
                  : FontStyle.normal,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            descriptor,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: accent.withValues(alpha: 0.78),
              fontSize:
                  ultraCompact ? descriptorSize + 0.1 : descriptorSize + 0.3,
              fontWeight: FontWeight.w900,
              height: 1,
            ),
          ),
        ],
      ),
    );
  }
}

class _CompactPreferenceRule extends StatelessWidget {
  const _CompactPreferenceRule({
    super.key,
    required this.card,
    required this.accent,
    required this.ultraCompact,
  });

  final TasteDeckCard card;
  final Color accent;
  final bool ultraCompact;

  @override
  Widget build(BuildContext context) {
    final examples = tasteCardBackExamples(card).take(2).join(' / ');
    final rule = _preferenceRuleFor(card);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: ultraCompact ? 5 : 6,
        vertical: ultraCompact ? 2 : 3,
      ),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.72),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: accent.withValues(alpha: 0.22)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.tune_rounded,
            size: ultraCompact ? 7 : 8,
            color: accent,
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              ultraCompact ? rule : '$rule · $examples',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.textPrimary.withValues(alpha: 0.74),
                fontSize: ultraCompact ? 6.8 : 7.2,
                fontWeight: FontWeight.w900,
                height: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String _preferenceRuleFor(TasteDeckCard card) {
  switch (card.id) {
    case 'd_low_carb':
      return '减主食 加蛋白';
    case 'd_high_protein':
      return '蛋白优先';
    case 'd_vegetarian':
      return '素食过滤';
    case 'd_light':
    case 's_healthy':
    case 'ft_health':
      return '低负担';
    case 'm_cheap':
      return '预算优先';
    case 'm_random':
      return '随机开局';
    case 'm_surprise':
      return '保留惊喜';
    case 'i_potato':
      return '土豆主角';
    case 'st_porridge':
      return '软糯饱腹';
    case 'f_numbing':
      return '花椒电感';
    case 'f_spicy':
      return '热辣增强';
    default:
      return tasteCardDescriptor(card);
  }
}

class _RarityBadge extends StatelessWidget {
  const _RarityBadge({
    super.key,
    required this.rarity,
    required this.accentA,
    required this.accentB,
    required this.compact,
    required this.categoryFontSize,
  });

  final String rarity;
  final Color accentA;
  final Color accentB;
  final bool compact;
  final double categoryFontSize;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 6 : 8,
        vertical: compact ? 2 : 4,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(999),
        gradient: LinearGradient(
          colors: [
            Colors.white.withValues(alpha: compact ? 0.68 : 0.82),
            accentA.withValues(alpha: compact ? 0.08 : 0.12),
            accentB.withValues(alpha: 0.08),
          ],
        ),
        border: Border.all(color: accentA.withValues(alpha: 0.18)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.category_rounded,
            size: compact ? 7 : 9,
            color: accentA,
          ),
          const SizedBox(width: 4),
          Text(
            rarity,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: categoryFontSize,
              fontWeight: FontWeight.w900,
              letterSpacing: 0.45,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}

class _TasteHeroVisual extends StatelessWidget {
  const _TasteHeroVisual({
    super.key,
    required this.card,
    required this.accentA,
    required this.accentB,
    required this.compact,
    required this.ultraCompact,
    required this.symbol,
  });

  final TasteDeckCard card;
  final Color accentA;
  final Color accentB;
  final bool compact;
  final bool ultraCompact;
  final TasteCardSignatureConfig symbol;

  @override
  Widget build(BuildContext context) {
    final marker = card.label.trim().isEmpty ? symbol.glyph : card.label[0];
    final category = tasteCardCategoryLabel(card.category);

    return Container(
      height: ultraCompact ? 28 : (compact ? 32 : 46),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(ultraCompact ? 14 : 18),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Colors.white.withValues(alpha: 0.88),
            accentA.withValues(alpha: 0.18),
            accentB.withValues(alpha: 0.08),
          ],
        ),
        border: Border.all(color: accentA.withValues(alpha: 0.16)),
        boxShadow: [
          BoxShadow(
            color: accentA.withValues(alpha: 0.08),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Align(
              child: Container(
                width: ultraCompact ? 44 : (compact ? 54 : 72),
                height: ultraCompact ? 24 : (compact ? 30 : 40),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(999),
                  color: Colors.white.withValues(alpha: 0.58),
                  border: Border.all(
                    color: accentA.withValues(alpha: 0.16),
                    width: 1.1,
                  ),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Positioned(
                      left: 7,
                      child: Text(
                        marker,
                        maxLines: 1,
                        overflow: TextOverflow.clip,
                        style: TextStyle(
                          fontSize: ultraCompact ? 12 : (compact ? 14 : 18),
                          fontWeight: FontWeight.w900,
                          color: accentA.withValues(alpha: 0.68),
                          height: 1,
                        ),
                      ),
                    ),
                    Positioned(
                      right: 7,
                      child: Icon(
                        tasteCardIconFor(card.iconName, card.category),
                        size: ultraCompact ? 13 : (compact ? 16 : 20),
                        color: accentA,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: CustomPaint(
                painter: _TasteHeroBracketPainter(
                  color: accentA.withValues(alpha: 0.18),
                ),
              ),
            ),
          ),
          Positioned(
            left: 10,
            top: 8,
            child: Container(
              width: ultraCompact ? 16 : 20,
              height: ultraCompact ? 16 : 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: accentA.withValues(alpha: 0.14),
              ),
              child: Icon(
                tasteCardIconFor(card.iconName, card.category),
                size: ultraCompact ? 9 : 11,
                color: accentA,
              ),
            ),
          ),
          Positioned(
            left: 14,
            bottom: ultraCompact ? 6 : 8,
            child: Text(
              category,
              style: TextStyle(
                fontSize: ultraCompact ? 7 : (compact ? 7.4 : 8),
                fontWeight: FontWeight.w900,
                color: accentA.withValues(alpha: 0.42),
                letterSpacing: 0.3,
              ),
            ),
          ),
          Positioned(
            right: 10,
            top: ultraCompact ? 7 : 10,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                color: Colors.white.withValues(alpha: 0.74),
                border: Border.all(color: accentB.withValues(alpha: 0.18)),
              ),
              child: Text(
                symbol.code,
                style: TextStyle(
                  fontSize: ultraCompact ? 6.8 : 7.3,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.9,
                  color: AppColors.textPrimary.withValues(alpha: 0.56),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TasteHeroBracketPainter extends CustomPainter {
  const _TasteHeroBracketPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;
    final insetX = size.width * 0.18;
    final insetY = size.height * 0.26;
    final arm = size.height * 0.2;
    final left = insetX;
    final right = size.width - insetX;
    final top = insetY;
    final bottom = size.height - insetY;
    final segments = [
      (Offset(left, top), Offset(left + arm, top)),
      (Offset(left, top), Offset(left, top + arm)),
      (Offset(right, top), Offset(right - arm, top)),
      (Offset(right, top), Offset(right, top + arm)),
      (Offset(left, bottom), Offset(left + arm, bottom)),
      (Offset(left, bottom), Offset(left, bottom - arm)),
      (Offset(right, bottom), Offset(right - arm, bottom)),
      (Offset(right, bottom), Offset(right, bottom - arm)),
    ];

    for (final (from, to) in segments) {
      canvas.drawLine(from, to, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _TasteHeroBracketPainter oldDelegate) {
    return oldDelegate.color != color;
  }
}

class _TasteAffixRow extends StatelessWidget {
  const _TasteAffixRow({
    super.key,
    required this.affixes,
    required this.accent,
    required this.compact,
  });

  final List<String> affixes;
  final Color accent;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final affix in affixes.take(compact ? 2 : 3))
          Container(
            padding: EdgeInsets.symmetric(
              horizontal: compact ? 5 : 7,
              vertical: compact ? 1.5 : 3,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(999),
              color: Colors.white.withValues(alpha: compact ? 0.58 : 0.7),
              border: Border.all(color: accent.withValues(alpha: 0.12)),
            ),
            child: Text(
              affix,
              style: TextStyle(
                color: AppColors.textPrimary.withValues(alpha: 0.66),
                fontSize: compact ? 7.1 : 8.4,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
      ],
    );
  }
}

class _TasteEffectPanel extends StatelessWidget {
  const _TasteEffectPanel({
    super.key,
    required this.effect,
    required this.accent,
    required this.compact,
    required this.ultraCompact,
  });

  final String effect;
  final Color accent;
  final bool compact;
  final bool ultraCompact;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(
        compact ? 6 : 7,
        compact ? 4 : 5,
        compact ? 6 : 7,
        compact ? 4 : 5,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(compact ? 14 : 16),
        color: Colors.white.withValues(alpha: 0.54),
        border: Border.all(color: accent.withValues(alpha: 0.16)),
      ),
      child: Row(
        children: [
          Container(
            width: compact ? 14 : 16,
            height: compact ? 14 : 16,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accent.withValues(alpha: 0.15),
            ),
            child: Icon(
              Icons.bolt_rounded,
              size: compact ? 9 : 10,
              color: accent,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              effect,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.textPrimary.withValues(alpha: 0.72),
                fontSize: ultraCompact ? 8.0 : (compact ? 8.4 : 8.8),
                height: 1.15,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TasteCardFooterRow extends StatelessWidget {
  const _TasteCardFooterRow({
    super.key,
    required this.card,
    required this.accent,
    required this.compact,
    required this.descriptor,
  });

  final TasteDeckCard card;
  final Color accent;
  final bool compact;
  final String descriptor;

  @override
  Widget build(BuildContext context) {
    final rarity = tasteCardRarityFor(card);
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 7 : 8,
        vertical: compact ? 5 : 6,
      ),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(compact ? 14 : 16),
        color: Colors.white.withValues(alpha: 0.26),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: compact ? 16 : 18,
            height: compact ? 16 : 18,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: accent.withValues(alpha: 0.14),
            ),
            child: Icon(
              tasteCardIconFor(card.iconName, card.category),
              size: compact ? 9 : 10,
              color: accent,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              '${card.label} · $rarity · $descriptor',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: AppColors.textPrimary.withValues(alpha: 0.74),
                fontSize: compact ? 8.4 : 8.8,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CardFaceFlip extends StatelessWidget {
  const _CardFaceFlip({
    required this.isFlipped,
    required this.front,
    required this.back,
  });

  final bool isFlipped;
  final Widget front;
  final Widget back;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween<double>(end: isFlipped ? 1 : 0),
      duration: const Duration(milliseconds: 320),
      curve: Curves.easeInOutCubic,
      builder: (context, value, _) {
        final angle = value * math.pi;
        final showBack = value >= 0.5;
        final displayAngle = showBack ? angle - math.pi : angle;
        final sweepStrength =
            (1 - ((value - 0.5).abs() * 2).clamp(0, 1)).toDouble();
        final lift = 1 + sweepStrength * 0.012;

        return ClipRRect(
          borderRadius: BorderRadius.circular(18),
          child: Stack(
            fit: StackFit.expand,
            children: [
              Transform(
                alignment: Alignment.center,
                transform: Matrix4.identity()
                  ..setEntry(3, 2, 0.0015)
                  ..scale(lift)
                  ..rotateY(displayAngle),
                child: showBack ? back : front,
              ),
              Positioned.fill(
                child: IgnorePointer(
                  child: TasteFlipLightOverlay(
                    progress: value,
                    strength: sweepStrength,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _CardTitleBlock extends StatelessWidget {
  const _CardTitleBlock({
    super.key,
    required this.card,
    required this.accent,
    required this.descriptor,
    required this.compact,
    required this.ultraCompact,
    required this.labelFontSize,
    required this.descriptorSize,
  });

  final TasteDeckCard card;
  final Color accent;
  final String descriptor;
  final bool compact;
  final bool ultraCompact;
  final double labelFontSize;
  final double descriptorSize;

  @override
  Widget build(BuildContext context) {
    if (ultraCompact) {
      return SizedBox(
        child: Text(
          card.label,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            fontSize: labelFontSize,
            fontWeight: tasteCardHeadlineWeight(card.headlineStyle),
            color: AppColors.textPrimary,
            height: 0.96,
          ),
        ),
      );
    }

    return SizedBox(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            card.label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: compact ? labelFontSize + 0.2 : labelFontSize + 1.8,
              fontWeight: tasteCardHeadlineWeight(card.headlineStyle),
              color: AppColors.textPrimary,
              height: 0.96,
              letterSpacing: tasteCardHeadlineSpacing(card.headlineStyle),
              fontStyle: tasteCardHeadlineItalic(card.headlineStyle)
                  ? FontStyle.italic
                  : FontStyle.normal,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            '${tasteCardCategoryLabel(card.category)} · $descriptor',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: compact ? descriptorSize - 0.8 : descriptorSize,
              fontWeight: FontWeight.w800,
              color: accent.withValues(alpha: 0.62),
              letterSpacing: 0.2,
            ),
          ),
          const SizedBox(height: 4),
          FractionallySizedBox(
            alignment: Alignment.centerLeft,
            widthFactor:
                tasteCardHeadlineBarWidth(card.headlineStyle, ultraCompact),
            child: Container(
              height: 3,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(999),
                gradient: LinearGradient(
                  colors: [
                    accent.withValues(alpha: 0.72),
                    accent.withValues(alpha: 0.1),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

Color _reactionColor(TasteCardReaction? reaction, Color accent) {
  switch (reaction) {
    case TasteCardReaction.liked:
      return const Color(0xFFF46B40);
    case TasteCardReaction.disliked:
      return const Color(0xFF6F6770);
    case TasteCardReaction.skipped:
      return accent;
    case null:
      return accent;
  }
}
