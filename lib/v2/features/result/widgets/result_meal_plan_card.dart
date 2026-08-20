import 'package:eatwhat_app/v2/core/data/models/recipe_model.dart';
import 'package:eatwhat_app/v2/core/theme/app_tokens.dart';
import 'package:eatwhat_app/v2/features/result/widgets/result_pairing_band.dart';
import 'package:flutter/material.dart';

class ResultMealPlanCard extends StatelessWidget {
  const ResultMealPlanCard({
    super.key,
    required this.mainDish,
    required this.pairings,
    this.partySize,
  });

  final RecipeModel mainDish;
  final List<PairingSuggestion> pairings;
  final int? partySize;

  @override
  Widget build(BuildContext context) {
    final items = [
      _MealItem(
        category: '主菜',
        title: mainDish.name,
        subtitle: _mainDishSubtitle(mainDish),
        icon: Icons.restaurant_menu_rounded,
        accent: AppPalette.leaf,
      ),
      ...pairings.map(
        (pairing) => _MealItem(
          category: pairing.category,
          title: pairing.title,
          subtitle: pairing.subtitle,
          icon: pairing.icon,
          accent: pairing.accent,
        ),
      ),
    ];

    return Container(
      key: const ValueKey('result-meal-plan-card'),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
      decoration: AppDecorations.nightCard(
        color: AppPalette.nightElevated,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text('这一顿这样搭', style: AppTypeNight.section),
                    const SizedBox(height: 4),
                    Text(
                      '${partySize ?? 1} 人份 · ${items.length} 样组合',
                      style: AppTypeNight.label,
                    ),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: AppRadii.capsule,
                  color: AppPalette.leaf.withValues(alpha: 0.14),
                ),
                child: Text(
                  '完整一餐',
                  style: AppTypeNight.microLabel.copyWith(color: AppPalette.leaf),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          for (var index = 0; index < items.length; index++) ...[
            _MealItemTile(item: items[index], index: index + 1),
            if (index != items.length - 1) const SizedBox(height: 9),
          ],
        ],
      ),
    );
  }

  String _mainDishSubtitle(RecipeModel recipe) {
    final description = recipe.description.trim();
    if (description.isNotEmpty) return description;
    final ingredients = recipe.ingredients.take(3).join('、');
    return ingredients.isEmpty ? '承担这一餐的主体味道。' : '以$ingredients为主味。';
  }
}

class _MealItem {
  const _MealItem({
    required this.category,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.accent,
  });

  final String category;
  final String title;
  final String subtitle;
  final IconData icon;
  final Color accent;
}

class _MealItemTile extends StatelessWidget {
  const _MealItemTile({required this.item, required this.index});

  final _MealItem item;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: AppDecorations.nightCard(radius: AppRadii.sm),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: item.accent.withValues(alpha: 0.15),
            ),
            child: Icon(item.icon, color: item.accent, size: 21),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '${item.category} · ${item.title}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    color: AppPalette.moonlight,
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  item.subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: AppPalette.moonlight.withValues(alpha: 0.52),
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            index.toString().padLeft(2, '0'),
            style: TextStyle(
              color: item.accent.withValues(alpha: 0.68),
              fontSize: 12,
              fontWeight: FontWeight.w900,
            ),
          ),
        ],
      ),
    );
  }
}
