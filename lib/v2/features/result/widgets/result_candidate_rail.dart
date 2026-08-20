import 'package:eatwhat_app/v2/core/data/models/recipe_model.dart';
import 'package:eatwhat_app/v2/core/theme/app_tokens.dart';
import 'package:flutter/material.dart';

class ResultCandidateRail extends StatelessWidget {
  const ResultCandidateRail({
    super.key,
    required this.currentChoiceId,
    required this.choices,
    this.recalledCount = 0,
    required this.aiReasonsByRecipeId,
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
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Text(
              '候选菜品',
              style: AppTypeNight.section,
            ),
            const Spacer(),
            Text(
              recalledCount > choices.length
                  ? '召回 $recalledCount · 精选 ${choices.length}'
                  : '${choices.length} 个候选',
              style: AppTypeNight.microLabel,
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 86,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: choices.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final recipe = choices[index];
              final isActive = recipe.id == currentChoiceId;
              final thumbUrl = thumbUrlByRecipeId[recipe.id]?.trim() ?? '';
              return GestureDetector(
                key: ValueKey('result-candidate-${recipe.id}'),
                onTap: () => onSelect(recipe),
                child: AnimatedContainer(
                  duration: AppMotion.fast,
                  curve: AppMotion.enter,
                  width: 172,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  decoration: BoxDecoration(
                    borderRadius: AppRadii.small,
                    color: isActive
                        ? AppPalette.nightElevated
                        : AppPalette.nightSurface,
                    border: Border.all(
                      color: isActive
                          ? AppPalette.leaf.withValues(alpha: 0.55)
                          : AppPalette.nightDivider,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(AppRadii.xs),
                        child: SizedBox(
                          width: 56,
                          height: 68,
                          child: thumbUrl.isEmpty
                              ? Container(
                                  color: AppPalette.nightElevated,
                                  child: Center(
                                    child: Text(
                                      recipe.name.trim().isEmpty
                                          ? '味'
                                          : recipe.name.trim()[0],
                                      style: const TextStyle(
                                        color: AppPalette.moonMuted,
                                        fontSize: 20,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ),
                                )
                              : Image.asset(
                                  thumbUrl,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      Container(
                                    color: AppPalette.nightElevated,
                                    child: Center(
                                      child: Text(
                                        recipe.name.trim().isEmpty
                                            ? '味'
                                            : recipe.name.trim()[0],
                                        style: const TextStyle(
                                          color: AppPalette.moonMuted,
                                          fontSize: 20,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                        ),
                      ),
                      const SizedBox(width: 9),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '0${index + 1}',
                              style: TextStyle(
                                color: isActive
                                    ? AppPalette.leaf
                                    : AppPalette.moonMuted,
                                fontSize: 10,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1.2,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              recipe.name,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: AppPalette.moonlight,
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Expanded(
                              child: Text(
                                aiReasonsByRecipeId[recipe.id] ??
                                    recipe.description,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppPalette.moonMuted,
                                  fontSize: 10.5,
                                  fontWeight: FontWeight.w600,
                                  height: 1.25,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
