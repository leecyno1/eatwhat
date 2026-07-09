import 'package:eatwhat_app/v2/core/data/models/ai_generation_models.dart';
import 'package:eatwhat_app/v2/features/result/controllers/result_enrichment_controller.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ResultEnrichmentController', () {
    test('tracks dish intro loading and caches completed copy', () {
      final controller = ResultEnrichmentController();

      expect(controller.introFor('r1'), isNull);
      expect(controller.isIntroLoading('r1'), isFalse);

      controller.markIntroLoading('r1');
      expect(controller.isIntroLoading('r1'), isTrue);

      controller.completeIntro('r1', '  鲜香下饭，适合今天的胃口。 ');
      expect(controller.isIntroLoading('r1'), isFalse);
      expect(controller.introFor('r1'), '鲜香下饭，适合今天的胃口。');
    });

    test('does not replace cached intro with blank copy', () {
      final controller = ResultEnrichmentController()
        ..completeIntro('r1', '已有简介')
        ..completeIntro('r1', '   ');

      expect(controller.introFor('r1'), '已有简介');
      expect(controller.isIntroLoading('r1'), isFalse);
    });

    test('tracks pairing loading, loaded cache and fallback state', () {
      final controller = ResultEnrichmentController<String>();

      expect(controller.pairingStateFor('r1'), PairingLoadState.loading);
      expect(controller.pairingsFor('r1'), isNull);

      controller.markPairingsLoading('r1');
      expect(controller.pairingStateFor('r1'), PairingLoadState.loading);

      controller.completePairings('r1', const ['冰镇乌龙茶', '凉拌黄瓜']);
      expect(controller.pairingStateFor('r1'), PairingLoadState.loaded);
      expect(controller.pairingsFor('r1'), ['冰镇乌龙茶', '凉拌黄瓜']);
      expect(controller.hasPairings('r1'), isTrue);

      controller.completeFallbackPairings('r2', const ['时蔬小菜']);
      expect(controller.pairingStateFor('r2'), PairingLoadState.fallback);
      expect(controller.pairingsFor('r2'), ['时蔬小菜']);
    });

    test('tracks nutrition loaded cache and unavailable state', () {
      final controller = ResultEnrichmentController<String>();
      final nutrition = _nutrition();

      expect(controller.nutritionStateFor('r1'), NutritionLoadState.loading);
      expect(controller.nutritionFor('r1'), isNull);

      controller.markNutritionLoading('r1');
      expect(controller.nutritionStateFor('r1'), NutritionLoadState.loading);

      controller.completeNutrition('r1', nutrition);
      expect(controller.nutritionStateFor('r1'), NutritionLoadState.loaded);
      expect(controller.nutritionFor('r1'), nutrition);

      controller.markNutritionUnavailable('r2');
      expect(
        controller.nutritionStateFor('r2'),
        NutritionLoadState.unavailable,
      );
      expect(controller.nutritionFor('r2'), isNull);
    });
  });
}

NutritionAnalysis _nutrition() {
  return const NutritionAnalysis(
    nutrition: NutritionInfo(
      calories: 520,
      protein: 28,
      carbs: 42,
      fat: 24,
      fiber: 5,
      sodium: 860,
      sugar: 8,
    ),
    healthScore: 7,
    balanceAdvice: ['加一份青菜更均衡'],
    dietaryTags: ['高蛋白'],
    servingSize: '1人份',
  );
}
