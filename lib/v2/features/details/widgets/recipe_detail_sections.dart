import 'dart:async';

import 'package:eatwhat_app/v2/core/data/models/howtocook_recipe_detail.dart';
import 'package:eatwhat_app/v2/core/data/models/recipe_model.dart';
import 'package:eatwhat_app/v2/core/theme/app_colors.dart';
import 'package:eatwhat_app/v2/core/theme/app_tokens.dart';
import 'package:eatwhat_app/v2/features/details/widgets/recipe_detail_controls.dart';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class RecipeHeaderSection extends StatelessWidget {
  const RecipeHeaderSection({
    super.key,
    required this.recipe,
    required this.loadingDetail,
  });

  final RecipeModel recipe;
  final bool loadingDetail;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          recipe.name,
          style: AppType.display.copyWith(fontSize: 28),
        ).animate().fadeIn().slideX(),
        const SizedBox(height: AppSpacing.xs),
        Text(
          recipe.description,
          style: AppType.body.copyWith(
            fontSize: 16,
            color: AppColors.textSecondary,
          ),
        ).animate().fadeIn(delay: 200.ms),
        const SizedBox(height: AppSpacing.md),
        Wrap(
          spacing: AppSpacing.xs,
          runSpacing: AppSpacing.xs,
          children: [
            RecipeInfoChip(Icons.restaurant_menu, recipe.difficulty),
            if (recipe.source.trim().isNotEmpty)
              RecipeInfoChip(Icons.menu_book_rounded, _sourceLabel(recipe)),
            RecipeInfoChip(
              Icons.kitchen_rounded,
              '食材 ${recipe.ingredients.length}',
            ),
            RecipeInfoChip(
              Icons.format_list_numbered_rounded,
              '步骤 ${recipe.steps.length}',
            ),
          ],
        ).animate().fadeIn(delay: 300.ms),
        if (loadingDetail)
          Padding(
            padding: const EdgeInsets.only(top: AppSpacing.sm),
            child: Text(
              '正在补全更完整的食材和步骤…',
              style: AppType.label.copyWith(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }

  String _sourceLabel(RecipeModel recipe) {
    final source = recipe.source.trim().toLowerCase();
    if (source == 'howtocook' || source == 'unified_db') {
      return 'HowToCook 原菜谱';
    }
    return recipe.source;
  }
}

class RecipeIngredientsSection extends StatelessWidget {
  const RecipeIngredientsSection({
    super.key,
    required this.ingredients,
    required this.servings,
    required this.substitutionSuggestions,
    required this.onDecreaseServings,
    required this.onIncreaseServings,
    required this.onOpenShoppingList,
  });

  final List<String> ingredients;
  final int servings;
  final List<String> substitutionSuggestions;
  final VoidCallback? onDecreaseServings;
  final VoidCallback onIncreaseServings;
  final VoidCallback onOpenShoppingList;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text('食材清单', style: AppType.section),
            ),
            TextButton.icon(
              key: const ValueKey('recipe-shopping-list-button'),
              onPressed: onOpenShoppingList,
              icon: const Icon(Icons.playlist_add_check_rounded, size: 18),
              label: const Text('购物清单'),
            ),
            const SizedBox(width: AppSpacing.xs),
            ServingAdjuster(
              servings: servings,
              onDecrease: onDecreaseServings,
              onIncrease: onIncreaseServings,
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        RecipeSurface(
          child: Column(
            children: ingredients.map((ingredient) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: AppColors.freshLime,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.sm),
                    Expanded(
                      child: Text(
                        ingredient,
                        style: AppType.body.copyWith(
                          fontSize: 16,
                          color: AppColors.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
        if (substitutionSuggestions.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          RecipeSurface(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('替换建议', style: AppType.section),
                const SizedBox(height: AppSpacing.sm),
                for (final item in substitutionSuggestions)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.xs),
                    child: Text(
                      item,
                      style: AppType.body.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ],
    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1);
  }
}

class RecipeCookBriefSection extends StatelessWidget {
  const RecipeCookBriefSection({
    super.key,
    required this.recipe,
    required this.completedStepIndexes,
    required this.onStartCooking,
    required this.onOpenShoppingList,
  });

  final RecipeModel recipe;
  final Set<int> completedStepIndexes;
  final VoidCallback onStartCooking;
  final VoidCallback onOpenShoppingList;

  @override
  Widget build(BuildContext context) {
    final timerMinutes = _timerMinutes(recipe.steps);
    final completedCount =
        recipe.steps.asMap().keys.where(completedStepIndexes.contains).length;

    return Container(
      key: const ValueKey('recipe-cook-brief-section'),
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: AppPalette.char,
        borderRadius: BorderRadius.circular(AppRadii.lg),
        boxShadow: AppSurfaces.softShadow(
          AppPalette.char.withValues(alpha: 0.18),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppPalette.yolk.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(AppRadii.sm),
                ),
                child: const Icon(
                  Icons.restaurant_menu_rounded,
                  color: AppPalette.yolk,
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '照着做',
                      style: AppType.section.copyWith(
                        color: AppPalette.moonlight,
                        fontSize: 20,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.xxs),
                    Text(
                      'HowToCook 原菜谱已整理成备料、步骤和计时任务。',
                      style: AppType.body.copyWith(
                        color: AppPalette.moonlight.withValues(alpha: 0.72),
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Wrap(
            spacing: AppSpacing.xs,
            runSpacing: AppSpacing.xs,
            children: [
              _CookBriefChip(
                icon: Icons.kitchen_rounded,
                label: '备料 ${recipe.ingredients.length}',
              ),
              _CookBriefChip(
                icon: Icons.format_list_numbered_rounded,
                label: '${recipe.steps.length} 步',
              ),
              _CookBriefChip(
                icon: Icons.check_circle_rounded,
                label: '进度 $completedCount/${recipe.steps.length}',
              ),
              if (timerMinutes > 0)
                _CookBriefChip(
                  icon: Icons.timer_rounded,
                  label: '计时 $timerMinutes 分钟',
                ),
            ],
          ),
          const SizedBox(height: AppSpacing.md),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: onOpenShoppingList,
                  icon: const Icon(Icons.playlist_add_check_rounded, size: 18),
                  label: const Text('备料清单'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppPalette.yolk,
                    side: BorderSide(
                      color: AppPalette.yolk.withValues(alpha: 0.42),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadii.sm),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: AppSpacing.sm),
              Expanded(
                child: FilledButton.icon(
                  key: const ValueKey('recipe-brief-start-cooking-button'),
                  onPressed: onStartCooking,
                  icon: const Icon(Icons.play_arrow_rounded, size: 20),
                  label: const Text('开始做'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppPalette.garden,
                    foregroundColor: AppPalette.night,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(AppRadii.sm),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 320.ms).slideY(begin: 0.08);
  }

  int _timerMinutes(List<String> steps) {
    var total = 0;
    for (final step in steps) {
      final match = RegExp(r'(\d+)\s*分钟').firstMatch(step);
      if (match == null) continue;
      total += int.tryParse(match.group(1) ?? '') ?? 0;
    }
    return total;
  }
}

class _CookBriefChip extends StatelessWidget {
  const _CookBriefChip({
    required this.icon,
    required this.label,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppPalette.moonlight.withValues(alpha: 0.08),
        borderRadius: AppRadii.capsule,
        border: Border.all(
          color: AppPalette.moonlight.withValues(alpha: 0.12),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 15, color: AppPalette.yolk),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: AppType.label.copyWith(
              color: AppPalette.moonlight.withValues(alpha: 0.86),
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}

class RecipeStepsSection extends StatelessWidget {
  const RecipeStepsSection({
    super.key,
    required this.steps,
    required this.completedStepIndexes,
    required this.onToggleStep,
  });

  final List<String> steps;
  final Set<int> completedStepIndexes;
  final ValueChanged<int> onToggleStep;

  @override
  Widget build(BuildContext context) {
    final completedCount =
        steps.asMap().keys.where(completedStepIndexes.contains).length;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(child: Text('烹饪步骤', style: AppType.section)),
            RecipeInfoChip(
              Icons.check_circle_rounded,
              '完成 $completedCount/${steps.length}',
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        ListView.separated(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: steps.length,
          separatorBuilder: (context, index) =>
              const SizedBox(height: AppSpacing.md),
          itemBuilder: (context, index) {
            final isCompleted = completedStepIndexes.contains(index);
            final timerLabel = cookingTimerLabelForStep(steps[index]);
            return RecipeSurface(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  InkWell(
                    key: ValueKey('recipe-step-toggle-$index'),
                    borderRadius: AppRadii.capsule,
                    onTap: () => onToggleStep(index),
                    child: Container(
                      width: 36,
                      height: 36,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: isCompleted
                            ? AppColors.freshLime
                            : AppColors.sunsetOrange,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        isCompleted
                            ? Icons.check_rounded
                            : Icons.restaurant_menu_rounded,
                        color: AppPalette.moonlight,
                        size: 20,
                      ),
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '第 ${index + 1} 步',
                          style: AppType.label.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          steps[index],
                          style: AppType.body.copyWith(
                            fontSize: 16,
                            color: isCompleted
                                ? AppColors.textSecondary
                                : AppColors.textPrimary,
                            decoration:
                                isCompleted ? TextDecoration.lineThrough : null,
                            decorationThickness: 1.8,
                          ),
                        ),
                        if (timerLabel != null) ...[
                          const SizedBox(height: AppSpacing.sm),
                          InkWell(
                            key: ValueKey('recipe-step-timer-$index'),
                            borderRadius: AppRadii.capsule,
                            onTap: () => showTimerSheet(
                              context,
                              title: '步骤 ${index + 1}',
                              minutes: int.tryParse(
                                    RegExp(r'(\d+)')
                                            .firstMatch(timerLabel)
                                            ?.group(1) ??
                                        '',
                                  ) ??
                                  0,
                            ),
                            child:
                                RecipeInfoChip(Icons.timer_rounded, timerLabel),
                          ),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ],
    ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.1);
  }
}

String? cookingTimerLabelForStep(String step) {
  final match = RegExp(r'(\d+)\s*分钟').firstMatch(step);
  if (match == null) return null;
  return '约 ${match.group(1)} 分钟';
}

Future<void> showTimerSheet(
  BuildContext context, {
  required String title,
  required int minutes,
  VoidCallback? onCompleted,
}) async {
  final completed = await showModalBottomSheet<bool>(
    context: context,
    showDragHandle: true,
    backgroundColor: AppColors.lightBackground,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
    ),
    builder: (context) {
      return _TimerSheet(title: title, minutes: minutes);
    },
  );
  if (completed == true) onCompleted?.call();
}

class _TimerSheet extends StatefulWidget {
  const _TimerSheet({
    required this.title,
    required this.minutes,
  });

  final String title;
  final int minutes;

  @override
  State<_TimerSheet> createState() => _TimerSheetState();
}

class _TimerSheetState extends State<_TimerSheet> {
  int _remainingSeconds = 0;
  bool _running = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _remainingSeconds = widget.minutes * 60;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _startTimer() {
    if (_running || _remainingSeconds <= 0) return;
    setState(() => _running = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted || !_running) {
        timer.cancel();
        return;
      }
      if (_remainingSeconds <= 1) {
        timer.cancel();
        setState(() {
          _remainingSeconds = 0;
          _running = false;
        });
        Navigator.of(context).pop(true);
        return;
      }
      setState(() => _remainingSeconds -= 1);
    });
  }

  String get _displayTime {
    final totalMinutes = (_remainingSeconds / 60).ceil();
    if (totalMinutes <= 0) return '时间到';
    return _running ? '剩余 $totalMinutes 分钟' : '$totalMinutes 分钟';
  }

  @override
  Widget build(BuildContext context) {
    final showStart = !_running && _remainingSeconds > 0;
    return SingleChildScrollView(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.md,
          AppSpacing.lg,
          AppSpacing.lg,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(widget.title, style: AppType.section),
            const SizedBox(height: AppSpacing.sm),
            RecipeSurface(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _displayTime,
                    style: AppType.display.copyWith(fontSize: 24),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    _running ? '正在计时' : '可直接开始这个步骤的等待时间。',
                    style:
                        AppType.body.copyWith(color: AppColors.textSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: showStart ? _startTimer : null,
                child: Text(showStart ? '开始计时' : '计时中'),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('关闭'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class RecipeShoppingListSheet extends StatefulWidget {
  const RecipeShoppingListSheet({
    super.key,
    required this.ingredients,
    required this.completedIndexes,
    required this.onToggleItem,
    required this.onCopy,
  });

  final List<String> ingredients;
  final Set<int> completedIndexes;
  final ValueChanged<int> onToggleItem;
  final VoidCallback onCopy;

  @override
  State<RecipeShoppingListSheet> createState() =>
      _RecipeShoppingListSheetState();
}

class _RecipeShoppingListSheetState extends State<RecipeShoppingListSheet> {
  late Set<int> _completedIndexes;

  @override
  void initState() {
    super.initState();
    _completedIndexes = Set<int>.from(widget.completedIndexes);
  }

  @override
  Widget build(BuildContext context) {
    final completedCount = widget.ingredients
        .asMap()
        .keys
        .where(_completedIndexes.contains)
        .length;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.fromLTRB(
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.lg,
          AppSpacing.xl,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text('购物清单', style: AppType.section),
                ),
                RecipeInfoChip(
                  Icons.shopping_bag_rounded,
                  '已买 $completedCount/${widget.ingredients.length}',
                ),
                const SizedBox(width: AppSpacing.xs),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: AppSpacing.sm),
            RecipeSurface(
              child: Column(
                children: [
                  for (final entry in widget.ingredients.asMap().entries)
                    InkWell(
                      key: ValueKey('recipe-shopping-item-${entry.key}'),
                      borderRadius: AppRadii.small,
                      onTap: () => _toggleItem(entry.key),
                      child: Padding(
                        padding:
                            const EdgeInsets.symmetric(vertical: AppSpacing.xs),
                        child: Row(
                          children: [
                            Icon(
                              _completedIndexes.contains(entry.key)
                                  ? Icons.check_box_rounded
                                  : Icons.check_box_outline_blank_rounded,
                              size: 22,
                              color: _completedIndexes.contains(entry.key)
                                  ? AppColors.freshLime
                                  : AppColors.sunsetOrange,
                            ),
                            const SizedBox(width: AppSpacing.sm),
                            Expanded(
                              child: Text(
                                entry.value,
                                style: AppType.body.copyWith(
                                  fontSize: 16,
                                  color: _completedIndexes.contains(entry.key)
                                      ? AppColors.textSecondary
                                      : AppColors.textPrimary,
                                  decoration:
                                      _completedIndexes.contains(entry.key)
                                          ? TextDecoration.lineThrough
                                          : null,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                key: const ValueKey('recipe-shopping-list-copy'),
                onPressed: widget.onCopy,
                icon: const Icon(Icons.copy_rounded),
                label: const Text('复制清单'),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColors.sunsetOrange,
                  foregroundColor: AppPalette.rice,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _toggleItem(int index) {
    setState(() {
      if (!_completedIndexes.add(index)) {
        _completedIndexes.remove(index);
      }
    });
    widget.onToggleItem(index);
  }
}

class RelatedRecipesSection extends StatelessWidget {
  const RelatedRecipesSection({
    super.key,
    required this.relatedRecipes,
    required this.onOpenLibrary,
    required this.onOpenRecipe,
  });

  final List<HowToCookRecipeDetail> relatedRecipes;
  final VoidCallback onOpenLibrary;
  final ValueChanged<HowToCookRecipeDetail> onOpenRecipe;

  @override
  Widget build(BuildContext context) {
    if (relatedRecipes.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text('相似做法', style: AppType.section),
            ),
            TextButton(
              onPressed: onOpenLibrary,
              child: const Text('查看更多'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        SizedBox(
          height: 126,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: relatedRecipes.length,
            separatorBuilder: (_, __) => const SizedBox(width: AppSpacing.sm),
            itemBuilder: (context, index) {
              final item = relatedRecipes[index];
              return GestureDetector(
                onTap: () => onOpenRecipe(item),
                child: Container(
                  width: 220,
                  padding: const EdgeInsets.all(AppSpacing.sm),
                  decoration: recipeSurfaceDecoration(),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppType.section.copyWith(fontSize: 17),
                      ),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        item.description.trim().isEmpty
                            ? '同类风格的家常做法。'
                            : item.description,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppType.body.copyWith(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const Spacer(),
                      Wrap(
                        spacing: AppSpacing.xs,
                        runSpacing: AppSpacing.xs,
                        children: [
                          if (item.category.trim().isNotEmpty)
                            RecipeInfoChip(Icons.sell_rounded, item.category),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    ).animate().fadeIn(delay: 550.ms).slideY(begin: 0.1);
  }
}

class RecipeInfoChip extends StatelessWidget {
  const RecipeInfoChip(
    this.icon,
    this.label, {
    super.key,
  });

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: AppColors.sunsetOrange.withValues(alpha: 0.1),
        borderRadius: AppRadii.capsule,
        border: Border.all(
          color: AppColors.sunsetOrange.withValues(alpha: 0.2),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppColors.sunsetOrange),
          const SizedBox(width: AppSpacing.xs),
          Text(
            label,
            style: AppType.label.copyWith(
              color: AppColors.sunsetOrange,
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }
}

class RecipeSurface extends StatelessWidget {
  const RecipeSurface({
    super.key,
    required this.child,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: recipeSurfaceDecoration(),
      child: child,
    );
  }
}

BoxDecoration recipeSurfaceDecoration({double radius = AppRadii.md}) {
  return BoxDecoration(
    color: AppPalette.rice,
    borderRadius: BorderRadius.circular(radius),
    boxShadow: [
      BoxShadow(
        color: AppPalette.char.withValues(alpha: 0.05),
        blurRadius: 10,
        offset: const Offset(0, 4),
      ),
    ],
  );
}
