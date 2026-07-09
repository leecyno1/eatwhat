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
