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
    required this.onSelect,
  });

  final String currentChoiceId;
  final List<RecipeModel> choices;
  final int recalledCount;
  final Map<String, String> aiReasonsByRecipeId;
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
              style: AppType.section,
            ),
            const Spacer(),
            Text(
              recalledCount > choices.length
                  ? '召回 $recalledCount · 精选 ${choices.length}'
                  : '${choices.length} 个候选',
              style: AppType.microLabel,
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          height: 76,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: choices.length,
            separatorBuilder: (_, __) => const SizedBox(width: 10),
            itemBuilder: (context, index) {
              final recipe = choices[index];
              final isActive = recipe.id == currentChoiceId;
              return GestureDetector(
                key: ValueKey('result-candidate-${recipe.id}'),
                onTap: () => onSelect(recipe),
                child: AnimatedContainer(
                  duration: AppMotion.fast,
                  curve: AppMotion.enter,
                  width: 156,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                  decoration: BoxDecoration(
                    borderRadius: AppRadii.small,
                    color: isActive
                        ? AppPalette.positiveSurface
                        : AppPalette.surfaceMuted,
                    border: Border.all(
                      color: isActive
                          ? AppPalette.chili.withValues(alpha: 0.34)
                          : AppPalette.divider,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Text(
                            '0${index + 1}',
                            style: TextStyle(
                              color: isActive
                                  ? AppPalette.chili
                                  : AppPalette.inkMuted,
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const Spacer(),
                          if (isActive)
                            const Text(
                              '当前',
                              style: TextStyle(
                                color: AppPalette.chili,
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                letterSpacing: 1,
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        recipe.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: AppPalette.ink,
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Expanded(
                        child: Text(
                          aiReasonsByRecipeId[recipe.id] ?? recipe.description,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: AppPalette.inkSoft,
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            height: 1.25,
                          ),
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
