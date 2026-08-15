import 'package:eatwhat_app/v2/core/services/v2_howtocook_recipe_service.dart';
import 'package:eatwhat_app/v2/core/services/v2_phase2_recommendation_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../test_bootstrap.dart';
import 'fixtures/v2_recommendation_eval_cases.dart';
import 'support/v2_recommendation_eval_harness.dart';

void main() {
  setUpAll(() async {
    await bootstrapTestEnvironment();
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('8 个真实语料场景达到推荐质量发布门槛', () async {
    final report = await _harness().run(v2RecommendationEvalCases);
    debugPrint('V2_RECOMMENDATION_EVAL ${report.format()}');

    expect(
      report.failedObservations,
      isEmpty,
      reason: report.format(),
    );
    expect(report.passAt1, 1);
    expect(report.canonicalIdentityRate, 1);
    expect(report.hardConstraintPassRate, 1);
    expect(report.coverageRate, 1);
    expect(report.averageDiversity, greaterThanOrEqualTo(0.55));
    expect(report.p95Latency, lessThan(const Duration(seconds: 3)));
  });

  test('海鲜、素食和不要辣场景达到 pass^3 且结果稳定', () async {
    final harness = _harness();
    final criticalCases =
        v2RecommendationEvalCases.where((item) => item.critical);

    for (final evalCase in criticalCases) {
      final observations = <V2RecommendationEvalObservation>[];
      for (var attempt = 0; attempt < 3; attempt++) {
        observations.add(await harness.runCase(evalCase));
      }

      expect(
        observations.every((item) => item.passed),
        isTrue,
        reason: '${evalCase.id} pass^3 failed: '
            '${observations.map((item) => item.failures).toList()}',
      );
      expect(
        observations.map((item) => item.recipeIds.join('|')).toSet(),
        hasLength(1),
        reason: '${evalCase.id} 三次运行结果顺序不稳定',
      );
    }
  });
}

V2RecommendationEvalHarness _harness() {
  final service = V2Phase2RecommendationService(
    enableAiEnhancement: false,
    howToCookRecipeService: V2HowToCookRecipeService(
      searchLoader: (_, __) async => const [],
      completeLoader: (_) async => null,
      allRecipesLoader: (_) async => const [],
      assetIndexLoader: () async => '{"items":[]}',
    ),
  );
  return V2RecommendationEvalHarness(
    runner: (input) => service.buildRecommendations(input: input),
  );
}
