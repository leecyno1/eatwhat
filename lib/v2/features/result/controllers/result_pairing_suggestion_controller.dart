import 'package:eatwhat_app/v2/core/data/models/meal_planning_direction.dart';
import 'package:eatwhat_app/v2/core/data/models/recipe_model.dart';
import 'package:eatwhat_app/v2/core/data/models/recipe_pairing_model.dart';
import 'package:eatwhat_app/v2/features/result/widgets/result_pairing_band.dart';
import 'package:flutter/material.dart';

class ResultPairingSuggestionController {
  const ResultPairingSuggestionController();

  List<PairingSuggestion> buildCorpusPairings(
    List<RecipePairingModel> pairings,
  ) {
    return pairings
        .where((pairing) => pairing.name.trim().isNotEmpty)
        .map(_fromCorpusPairing)
        .take(4)
        .toList();
  }

  List<PairingSuggestion> buildSidePairings(RecipeModel recipe) {
    final joined =
        '${recipe.name}|${recipe.description}|${recipe.ingredients.join('|')}';

    bool hasAny(List<String> keys) => keys.any(joined.contains);
    final suggestions = <PairingSuggestion>[];

    if (hasAny(['锅', '汤', '辣', '肥牛', '羊肉', '麻辣', '火锅'])) {
      suggestions.add(
        const PairingSuggestion(
          category: '配菜',
          title: '凉拌黄瓜',
          subtitle: '清口解腻，能把热和辣往下收一点。',
          accent: Color(0xFF7ABF88),
          icon: Icons.eco_rounded,
        ),
      );
    }

    if (hasAny(['番茄', '牛腩', '炖', '煲', '焖'])) {
      suggestions.add(
        const PairingSuggestion(
          category: '配菜',
          title: '蒜蓉生菜',
          subtitle: '补一点脆感和青味，整口更平衡。',
          accent: Color(0xFF96B86C),
          icon: Icons.spa_rounded,
        ),
      );
    }

    if (suggestions.isEmpty) {
      suggestions.add(
        const PairingSuggestion(
          category: '配菜',
          title: '时蔬小菜',
          subtitle: '补一份清爽蔬菜，吃起来更完整。',
          accent: Color(0xFF7ABF88),
          icon: Icons.grass_rounded,
        ),
      );
    }

    return suggestions.take(2).toList();
  }

  List<PairingSuggestion> completeMealPairings(
    RecipeModel recipe,
    List<PairingSuggestion> pairings, {
    MealPlanningDirection direction = MealPlanningDirection.balanced,
  }) {
    final completed = <PairingSuggestion>[];
    final eligiblePairings = direction == MealPlanningDirection.health
        ? pairings.where((pairing) => !_isSugaryDrink(pairing)).toList()
        : pairings;

    void addFirstFor(String category) {
      final index = eligiblePairings.indexWhere(
        (pairing) => pairing.category == category,
      );
      if (index >= 0) completed.add(eligiblePairings[index]);
    }

    addFirstFor('配菜');
    if (!completed.any((pairing) => pairing.category == '配菜')) {
      completed.addAll(buildSidePairings(recipe).take(1));
    }

    addFirstFor('主食');
    if (!completed.any((pairing) => pairing.category == '主食') &&
        !_isStaple(recipe)) {
      completed.add(
        const PairingSuggestion(
          category: '主食',
          title: '一碗热米饭',
          subtitle: '接住主菜的汤汁和味道，让这一顿更完整。',
          accent: Color(0xFFC28B42),
          icon: Icons.rice_bowl_rounded,
        ),
      );
    }

    addFirstFor('饮品');
    if (!completed.any((pairing) => pairing.category == '饮品')) {
      completed.add(
        const PairingSuggestion(
          category: '饮品',
          title: '冰镇乌龙茶',
          subtitle: '清口解腻，把整顿饭的尾韵收得更干净。',
          accent: Color(0xFFF46B40),
          icon: Icons.local_drink_rounded,
        ),
      );
    }

    for (final pairing in eligiblePairings) {
      if (completed.length >= 3 || completed.contains(pairing)) continue;
      completed.add(pairing);
    }
    return completed.take(3).toList();
  }

  bool _isSugaryDrink(PairingSuggestion pairing) {
    if (pairing.category != '饮品') return false;
    final text = '${pairing.title}|${pairing.subtitle}';
    return const ['可乐', '雪碧', '奶茶', '果汁', '含糖', '甜饮'].any(text.contains);
  }

  bool _isStaple(RecipeModel recipe) {
    final text = '${recipe.name}|${recipe.tags.join('|')}';
    return ['饭', '面', '粉', '粥', '饺', '馄饨', '包子', '主食'].any(text.contains);
  }

  PairingSuggestion _fromCorpusPairing(RecipePairingModel pairing) {
    final type = pairing.type.trim().toLowerCase();
    final category = switch (type) {
      'drink' || 'beverage' || 'tea' => '饮品',
      'side' || 'appetizer' || 'vegetable' => '配菜',
      'staple' || 'carb' => '主食',
      'dessert' => '甜点',
      _ => '搭配',
    };

    return PairingSuggestion(
      category: category,
      title: pairing.name.trim(),
      subtitle: pairing.description.trim().isEmpty
          ? '和这道菜的口味结构更顺。'
          : pairing.description.trim(),
      accent: switch (category) {
        '饮品' => const Color(0xFFF46B40),
        '配菜' => const Color(0xFF7ABF88),
        '主食' => const Color(0xFFC28B42),
        '甜点' => const Color(0xFFD65F8F),
        _ => const Color(0xFF6F8FB8),
      },
      icon: switch (category) {
        '饮品' => Icons.local_drink_rounded,
        '配菜' => Icons.eco_rounded,
        '主食' => Icons.rice_bowl_rounded,
        '甜点' => Icons.icecream_rounded,
        _ => Icons.auto_awesome_rounded,
      },
    );
  }
}
