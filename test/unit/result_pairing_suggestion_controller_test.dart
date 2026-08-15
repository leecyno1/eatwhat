import 'package:eatwhat_app/v2/core/data/models/recipe_model.dart';
import 'package:eatwhat_app/v2/core/data/models/recipe_pairing_model.dart';
import 'package:eatwhat_app/v2/core/data/models/meal_planning_direction.dart';
import 'package:eatwhat_app/v2/features/result/controllers/result_pairing_suggestion_controller.dart';
import 'package:eatwhat_app/v2/features/result/widgets/result_pairing_band.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ResultPairingSuggestionController', () {
    test('converts corpus pairings into visible food pairing bubbles', () {
      const controller = ResultPairingSuggestionController();

      final pairings = controller.buildCorpusPairings(
        const [
          RecipePairingModel(
            id: 'p1',
            dishId: '1',
            type: 'drink',
            name: '冰镇乌龙茶',
            description: '清口解腻，压住油香。',
            strength: 0.9,
            source: 'rule',
          ),
          RecipePairingModel(
            id: 'p2',
            dishId: '1',
            type: 'side',
            name: '凉拌黄瓜',
            description: '补一口脆爽。',
            strength: 0.8,
            source: 'rule',
          ),
        ],
      );

      expect(pairings, hasLength(2));
      expect(pairings.first.category, '饮品');
      expect(pairings.first.title, '冰镇乌龙茶');
      expect(pairings.first.subtitle, contains('清口解腻'));
      expect(pairings.last.category, '配菜');
      expect(pairings.last.title, '凉拌黄瓜');
    });

    test('suggests cucumber for hot pot and spicy dishes', () {
      const controller = ResultPairingSuggestionController();

      final pairings = controller.buildSidePairings(
        const RecipeModel(
          id: 'dish_hot',
          name: '麻辣肥牛锅',
          description: '热辣浓郁',
        ),
      );

      expect(pairings, hasLength(1));
      expect(pairings.single.category, '配菜');
      expect(pairings.single.title, '凉拌黄瓜');
      expect(pairings.single.subtitle, contains('清口解腻'));
    });

    test('suggests greens for tomato and braised dishes', () {
      const controller = ResultPairingSuggestionController();

      final pairings = controller.buildSidePairings(
        const RecipeModel(
          id: 'dish_tomato',
          name: '番茄牛腩煲',
          description: '慢炖入味',
        ),
      );

      expect(pairings, hasLength(1));
      expect(pairings.single.title, '蒜蓉生菜');
      expect(pairings.single.subtitle, contains('青味'));
    });

    test('falls back to vegetable side dish when no rule matches', () {
      const controller = ResultPairingSuggestionController();

      final pairings = controller.buildSidePairings(
        const RecipeModel(
          id: 'dish_plain',
          name: '葱油拌面',
          description: '快手面食',
        ),
      );

      expect(pairings, hasLength(1));
      expect(pairings.single.title, '时蔬小菜');
    });

    test('completes a main dish into a full meal', () {
      const controller = ResultPairingSuggestionController();

      final meal = controller.completeMealPairings(
        const RecipeModel(
          id: 'dish_meal',
          name: '番茄肥牛锅',
          description: '热乎下饭',
        ),
        const [
          PairingSuggestion(
            category: '配菜',
            title: '蒜蓉生菜',
            subtitle: '清爽平衡。',
            accent: Color(0xFF7ABF88),
            icon: Icons.eco_rounded,
          ),
        ],
      );

      expect(meal.map((item) => item.category), ['配菜', '主食', '饮品']);
      expect(meal.map((item) => item.title),
          containsAll(['蒜蓉生菜', '一碗热米饭', '冰镇乌龙茶']));
    });

    test('健康向整餐会排除含糖饮品', () {
      const controller = ResultPairingSuggestionController();

      final meal = controller.completeMealPairings(
        const RecipeModel(
          id: 'dish_health',
          name: '清蒸鱼',
          description: '清淡高蛋白',
        ),
        const [
          PairingSuggestion(
            category: '饮品',
            title: '冰镇可乐',
            subtitle: '甜口气泡饮。',
            accent: Color(0xFFF46B40),
            icon: Icons.local_drink_rounded,
          ),
        ],
        direction: MealPlanningDirection.health,
      );

      expect(meal.map((item) => item.title), isNot(contains('冰镇可乐')));
      expect(meal.map((item) => item.title), contains('冰镇乌龙茶'));
    });
  });
}
