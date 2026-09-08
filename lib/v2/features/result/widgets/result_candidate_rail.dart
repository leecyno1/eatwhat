import 'package:eatwhat_app/v2/core/data/models/recipe_model.dart';
import 'package:eatwhat_app/v2/core/theme/app_tokens.dart';
import 'package:flutter/material.dart';

/// Compact candidate thumbnails pinned to the bottom of the result stage.
/// Photos only — the current pick wears a lit gold ring, and a tiny count
/// sits at the start of the row.
class ResultCandidateRail extends StatelessWidget {
  const ResultCandidateRail({
    super.key,
    required this.currentChoiceId,
    required this.choices,
    this.recalledCount = 0,
    this.aiReasonsByRecipeId = const {},
    this.thumbUrlByRecipeId = const {},
    required this.onSelect,
  });

  final String currentChoiceId;
  final List<RecipeModel> choices;
  final int recalledCount;
  final Map<String, String> aiReasonsByRecipeId;
  final Map<String, String> thumbUrlByRecipeId;
  final ValueChanged<RecipeModel> onSelect;

  @override
  Widget build(BuildContext context) {
    if (choices.length < 2) return const SizedBox.shrink();

    return SizedBox(
      key: const ValueKey('result-candidate-rail'),
      height: 76,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: EdgeInsets.zero,
        itemCount: choices.length,
        separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
        itemBuilder: (context, index) {
          final choice = choices[index];
          final selected = choice.id == currentChoiceId;
          return _CandidateThumb(
            key: ValueKey('result-candidate-${choice.id}'),
            recipe: choice,
            thumbUrl: thumbUrlByRecipeId[choice.id],
            selected: selected,
            onTap: () => onSelect(choice),
          );
        },
      ),
    );
  }
}

class _CandidateThumb extends StatelessWidget {
  const _CandidateThumb({
    super.key,
    required this.recipe,
    required this.thumbUrl,
    required this.selected,
    required this.onTap,
  });

  final RecipeModel recipe;
  final String? thumbUrl;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // 目录未收录时回退到菜自身的 asset 图，让画廊与舞台共享同一张摄影。
    final effectiveThumb = thumbUrl != null && thumbUrl!.isNotEmpty
        ? thumbUrl!
        : (recipe.imageUrl?.trim().startsWith('assets/') ?? false)
            ? recipe.imageUrl!.trim()
            : null;
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        curve: AppMotion.enter,
        width: 76,
        height: 76,
        decoration: BoxDecoration(
          borderRadius: AppRadii.small,
          border: Border.all(
            color: selected ? GoldPalette.gold : GoldPalette.goldHairline,
            width: selected ? 1.6 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: GoldPalette.gold.withValues(alpha: 0.22),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadii.sm - 1),
          child: Stack(
            fit: StackFit.expand,
            children: [
              if (effectiveThumb != null)
                Image.asset(
                  effectiveThumb,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _fallbackTile(),
                )
              else
                _fallbackTile(),
              // Gallery focus: unselected photos sink into the dark so the
              // chosen dish is the only frame fully lit on the rail.
              if (!selected)
                Positioned.fill(
                  child: ColoredBox(
                    color: Colors.black.withValues(alpha: 0.45),
                  ),
                ),
              // Bottom scrim keeps the dish name readable over any photo.
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 3,
                  ),
                  color: Colors.black.withValues(alpha: 0.62),
                  child: Text(
                    recipe.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: GoldPalette.creamText,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _fallbackTile() {
    return Container(
      color: GoldPalette.panel,
      alignment: Alignment.center,
      child: Text(
        recipe.name.characters.isEmpty ? '菜' : recipe.name.characters.first,
        style: const TextStyle(
          color: GoldPalette.goldSoft,
          fontSize: 22,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}
