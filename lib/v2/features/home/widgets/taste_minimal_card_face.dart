import 'package:eatwhat_app/v2/core/data/models/taste_selection_models.dart';
import 'package:eatwhat_app/v2/core/theme/app_tokens.dart';
import 'package:eatwhat_app/v2/features/home/widgets/taste_card_back_content.dart';
import 'package:eatwhat_app/v2/features/home/widgets/taste_card_icon_helpers.dart';
import 'package:flutter/material.dart';

class TasteMinimalCardFace extends StatelessWidget {
  const TasteMinimalCardFace({
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
    final activeReaction = reaction ?? dragReaction;
    final accent = _accentFor(card);
    final surface = _surfaceFor(activeReaction);
    final border = _borderFor(activeReaction);
    return LayoutBuilder(
      builder: (context, constraints) {
        final ultraCompact = constraints.maxHeight < 76;
        final compact = ultraCompact ||
            constraints.maxWidth < 180 ||
            constraints.maxHeight < 112;

        return AnimatedContainer(
          duration: AppMotion.fast,
          curve: AppMotion.enter,
          decoration: AppDecorations.card(
            color: surface,
            borderColor: border,
          ),
          child: Stack(
            children: [
              Positioned.fill(
                child: Padding(
                  padding:
                      EdgeInsets.all(ultraCompact ? 6 : (compact ? 8 : 10)),
                  child: AnimatedSwitcher(
                    duration: AppMotion.standard,
                    switchInCurve: AppMotion.enter,
                    switchOutCurve: AppMotion.enter,
                    transitionBuilder: (child, animation) => FadeTransition(
                      opacity: animation,
                      child: child,
                    ),
                    child: isFlipped
                        ? KeyedSubtree(
                            key: ValueKey(
                                'taste-card-back-${card.category}-${card.id}'),
                            child: TasteCardBackContent(
                              card: card,
                              accentA: accent,
                              previewColor: border,
                              compact: true,
                              ultraCompact: compact,
                              categoryFontSize: compact ? 8 : 9,
                              labelFontSize: compact ? 17 : 20,
                              descriptorSize: compact ? 8 : 9,
                              activeReaction: activeReaction,
                            ),
                          )
                        : _MinimalFront(
                            key: ValueKey(
                              'taste-card-front-${card.category}-${card.id}',
                            ),
                            card: card,
                            accent: accent,
                            compact: compact,
                            ultraCompact: ultraCompact,
                          ),
                  ),
                ),
              ),
              if (!isFlipped && dragReaction != null)
                Positioned(
                  left: 8,
                  right: 8,
                  top: dragReaction == TasteCardReaction.liked ? 8 : null,
                  bottom: dragReaction == TasteCardReaction.disliked ? 8 : null,
                  child: _ReactionPreview(reaction: dragReaction!),
                ),
              if (reaction != null)
                Positioned(
                  right: 8,
                  top: 8,
                  child: _ReactionMark(
                    key: ValueKey(
                      'taste-card-reaction-stamp-${reaction!.name}-${card.id}',
                    ),
                    reaction: reaction!,
                  ),
                ),
              if (isCommitting)
                Positioned.fill(
                  child: ColoredBox(
                    color: AppPalette.surface.withValues(alpha: 0.72),
                    child: Center(
                      child: Text(
                        dragReaction == TasteCardReaction.liked ? '已喜欢' : '已排除',
                        style: AppType.label.copyWith(color: AppPalette.ink),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Color _accentFor(TasteDeckCard card) {
    final hex = card.accentHexes.firstOrNull;
    if (hex == null) return AppPalette.chili;
    final normalized = hex.replaceFirst('0x', '').replaceFirst('#', '');
    final value = int.tryParse(normalized, radix: 16);
    if (value == null) return AppPalette.chili;
    return Color(normalized.length == 6 ? 0xFF000000 | value : value);
  }

  Color _surfaceFor(TasteCardReaction? reaction) {
    return switch (reaction) {
      TasteCardReaction.liked => AppPalette.positiveSurface,
      TasteCardReaction.disliked => AppPalette.negativeSurface,
      _ => AppPalette.surface,
    };
  }

  Color _borderFor(TasteCardReaction? reaction) {
    return switch (reaction) {
      TasteCardReaction.liked => AppPalette.chili,
      TasteCardReaction.disliked => AppPalette.inkMuted,
      _ => AppPalette.divider,
    };
  }
}

class _MinimalFront extends StatelessWidget {
  const _MinimalFront({
    super.key,
    required this.card,
    required this.accent,
    required this.compact,
    required this.ultraCompact,
  });

  final TasteDeckCard card;
  final Color accent;
  final bool compact;
  final bool ultraCompact;

  @override
  Widget build(BuildContext context) {
    if (ultraCompact) {
      return Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: accent.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(AppRadii.xs),
            ),
            child: Icon(
              tasteCardIconFor(card.iconName, card.category),
              size: 14,
              color: accent,
            ),
          ),
          const SizedBox(width: 7),
          Expanded(
            child: Text(
              card.label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppType.label.copyWith(
                fontSize: 15,
                height: 1,
                color: AppPalette.ink,
              ),
            ),
          ),
          const SizedBox(width: 4),
          Text(
            _categoryLabel(card.category),
            style: AppType.microLabel.copyWith(
              color: AppPalette.inkMuted,
              fontSize: 8,
            ),
          ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: compact ? 26 : 30,
              height: compact ? 26 : 30,
              decoration: BoxDecoration(
                color: accent.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(AppRadii.xs),
              ),
              child: Icon(
                tasteCardIconFor(card.iconName, card.category),
                size: compact ? 15 : 17,
                color: accent,
              ),
            ),
            const Spacer(),
            Text(
              _categoryLabel(card.category),
              style: AppType.microLabel.copyWith(
                color: AppPalette.inkMuted,
                fontSize: compact ? 8 : 9,
              ),
            ),
          ],
        ),
        const Spacer(),
        Text(
          card.label,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: AppType.section.copyWith(
            fontSize: compact ? 17 : 20,
            height: 1.05,
            color: AppPalette.ink,
          ),
        ),
        if (card.blurb?.trim().isNotEmpty == true) ...[
          SizedBox(height: compact ? 3 : 5),
          Text(
            card.blurb!.trim(),
            maxLines: compact ? 1 : 2,
            overflow: TextOverflow.ellipsis,
            style: AppType.microLabel.copyWith(
              fontSize: compact ? 8 : 9,
              height: 1.25,
              letterSpacing: 0,
            ),
          ),
        ],
      ],
    );
  }

  String _categoryLabel(String category) {
    return switch (category) {
      'flavor' => '口味',
      'ingredient' => '食材',
      'scene' => '场景',
      'cuisine' => '菜系',
      'fortune' => '灵感',
      _ => '偏好',
    };
  }
}

class _ReactionPreview extends StatelessWidget {
  const _ReactionPreview({required this.reaction});

  final TasteCardReaction reaction;

  @override
  Widget build(BuildContext context) {
    final liked = reaction == TasteCardReaction.liked;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: liked ? AppPalette.chili : AppPalette.ink,
        borderRadius: BorderRadius.circular(AppRadii.xs),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            liked
                ? Icons.keyboard_arrow_up_rounded
                : Icons.keyboard_arrow_down_rounded,
            size: 13,
            color: AppPalette.surface,
          ),
          const SizedBox(width: 2),
          Text(
            liked ? '喜欢' : '不要',
            style: AppType.microLabel.copyWith(
              color: AppPalette.surface,
              letterSpacing: 0,
            ),
          ),
        ],
      ),
    );
  }
}

class _ReactionMark extends StatelessWidget {
  const _ReactionMark({super.key, required this.reaction});

  final TasteCardReaction reaction;

  @override
  Widget build(BuildContext context) {
    final liked = reaction == TasteCardReaction.liked;
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(
        color: liked ? AppPalette.chili : AppPalette.inkMuted,
        shape: BoxShape.circle,
      ),
      child: Icon(
        liked ? Icons.check_rounded : Icons.close_rounded,
        size: 14,
        color: AppPalette.surface,
      ),
    );
  }
}

extension<T> on Iterable<T> {
  T? get firstOrNull => isEmpty ? null : first;
}
