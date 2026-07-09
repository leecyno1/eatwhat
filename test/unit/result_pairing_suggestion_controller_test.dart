import 'package:eatwhat_app/v2/core/data/models/recipe_model.dart';
import 'package:eatwhat_app/v2/core/data/models/recipe_pairing_model.dart';
import 'package:eatwhat_app/v2/features/result/controllers/result_pairing_suggestion_controller.dart';
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
  });
}
