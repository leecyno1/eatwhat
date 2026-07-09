import 'package:eatwhat_app/v2/core/data/models/recipe_model.dart';
import 'package:eatwhat_app/v2/core/theme/app_colors.dart';
import 'package:flutter/material.dart';

class ResultCandidateRail extends StatelessWidget {
  const ResultCandidateRail({
    super.key,
    required this.currentChoiceId,
    required this.choices,
    required this.aiReasonsByRecipeId,
    required this.onSelect,
  });

  final String currentChoiceId;
  final List<RecipeModel> choices;
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
              style: TextStyle(
                color: AppColors.textPrimary,
                fontSize: 16,
                fontWeight: FontWeight.w800,
              ),
            ),
            const Spacer(),
            Text(
              '${choices.length} 个候选',
              style: TextStyle(
                color: AppColors.textPrimary.withValues(alpha: 0.46),
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
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
                  duration: const Duration(milliseconds: 220),
                  width: 160,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(22),
                    color: isActive
                        ? Colors.white.withValues(alpha: 0.76)
                        : Colors.white.withValues(alpha: 0.46),
                    border: Border.all(
                      color: isActive
                          ? AppColors.sunsetOrange.withValues(alpha: 0.32)
                          : Colors.white.withValues(alpha: 0.68),
                    ),
                    boxShadow: isActive
                        ? [
                            BoxShadow(
                              color: AppColors.sunsetOrange
                                  .withValues(alpha: 0.14),
                              blurRadius: 18,
                              offset: const Offset(0, 10),
                            ),
                          ]
                        : null,
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
                                  ? AppColors.sunsetOrange
                                  : AppColors.textPrimary
                                      .withValues(alpha: 0.34),
                              fontSize: 10,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 1.2,
                            ),
                          ),
                          const Spacer(),
                          if (isActive)
                            Text(
                              '当前',
                              style: TextStyle(
                                color: AppColors.sunsetOrange
                                    .withValues(alpha: 0.74),
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
                          color: AppColors.textPrimary,
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
                          style: TextStyle(
                            color:
                                AppColors.textPrimary.withValues(alpha: 0.52),
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
