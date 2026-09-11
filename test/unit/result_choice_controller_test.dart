import 'package:eatwhat_app/v2/core/data/models/recipe_model.dart';
import 'package:eatwhat_app/v2/features/result/controllers/result_choice_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ResultChoiceController', () {
    test('starts empty when no recommendations are available', () {
      final controller = ResultChoiceController(const []);

      expect(controller.currentChoice, isNull);
      expect(controller.availableChoices, isEmpty);
      expect(controller.hasCurrentChoice, isFalse);
      expect(controller.canReroll, isFalse);
      expect(controller.nextChoice(), isNull);
    });

    test('selects the first recommendation and rerolls in order', () {
      final controller = ResultChoiceController([
        _recipe('r1', '麻婆豆腐'),
        _recipe('r2', '红烧肉'),
        _recipe('r3', '宫保鸡丁'),
      ]);

      expect(controller.currentChoice?.id, 'r1');
      expect(controller.canReroll, isTrue);
      expect(controller.nextChoice()?.id, 'r2');

      expect(controller.select(controller.nextChoice()!), isTrue);
      expect(controller.currentChoice?.id, 'r2');
      expect(controller.nextChoice()?.id, 'r3');
    });

    test('ignores selecting the same recipe twice', () {
      final recipe = _recipe('r1', '麻婆豆腐');
      final controller = ResultChoiceController([recipe]);

      expect(controller.select(recipe), isFalse);
      expect(controller.currentChoice?.id, 'r1');
      expect(controller.canReroll, isFalse);
    });

    test('replaces current choice and keeps candidate rail synchronized', () {
      final controller = ResultChoiceController([
        _recipe('r1', '麻婆豆腐'),
        _recipe('r2', '红烧肉'),
      ]);
      final enriched = _recipe(
        'r1',
        '麻婆豆腐',
        imageUrl: 'assets/images/prebuilt_dishes/mapo.jpg',
      );

      controller.replaceCurrent(enriched);

      expect(controller.currentChoice?.imageUrl, enriched.imageUrl);
      expect(controller.availableChoices.first.imageUrl, enriched.imageUrl);
      expect(controller.availableChoices.last.id, 'r2');
    });

    test('replaceAllPreserving ignores an empty list', () {
      final controller = ResultChoiceController([
        _recipe('r1', '麻婆豆腐'),
        _recipe('r2', '红烧肉'),
      ]);

      controller.replaceAllPreserving(const []);

      expect(controller.availableChoices.map((r) => r.id), ['r1', 'r2']);
      expect(controller.currentChoice?.id, 'r1');
    });

    test('replaceAllPreserving keeps the current dish when it survives', () {
      final controller = ResultChoiceController([
        _recipe('r1', '麻婆豆腐'),
        _recipe('r2', '红烧肉'),
        _recipe('r3', '宫保鸡丁'),
      ]);
      controller.select(_recipe('r2', '红烧肉'));

      controller.replaceAllPreserving([
        _recipe('r3', '宫保鸡丁'),
        _recipe('r2', '红烧肉'),
      ]);

      expect(controller.availableChoices.map((r) => r.id), ['r3', 'r2']);
      expect(controller.currentChoice?.id, 'r2');
    });

    test('replaceAllPreserving falls back to first when current is dropped',
        () {
      final controller = ResultChoiceController([
        _recipe('r1', '麻婆豆腐'),
        _recipe('r2', '红烧肉'),
      ]);
      controller.select(_recipe('r2', '红烧肉'));

      controller.replaceAllPreserving([
        _recipe('r9', '清蒸鲈鱼'),
        _recipe('r8', '白灼虾'),
      ]);

      expect(controller.availableChoices.map((r) => r.id), ['r9', 'r8']);
      expect(controller.currentChoice?.id, 'r9');
    });

    test('replaceAllPreserving replaces the whole candidate list', () {
      final controller = ResultChoiceController([
        _recipe('r1', '麻婆豆腐'),
        _recipe('r2', '红烧肉'),
        _recipe('r3', '宫保鸡丁'),
      ]);

      controller.replaceAllPreserving([
        _recipe('r7', '番茄牛腩'),
      ]);

      expect(controller.availableChoices.map((r) => r.id), ['r7']);
      expect(controller.currentChoice?.id, 'r7');
      expect(controller.canReroll, isFalse);
    });
  });
}

RecipeModel _recipe(String id, String name, {String? imageUrl}) {
  return RecipeModel(
    id: id,
    name: name,
    description: '$name 描述',
    imageUrl: imageUrl,
  );
}
