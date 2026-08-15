import 'package:eatwhat_app/v2/core/data/models/recipe_model.dart';
import 'package:eatwhat_app/v2/core/data/models/recommendation_resolution.dart';
import 'package:eatwhat_app/v2/core/data/models/recommendation_telemetry_context.dart';
import 'package:eatwhat_app/v2/core/data/models/taste_selection_models.dart';
import 'package:eatwhat_app/v2/core/external/platform/platform_types.dart';
import 'package:eatwhat_app/v2/features/result/controllers/result_execution_intent_controller.dart';
import 'package:eatwhat_app/v2/features/result/widgets/result_pairing_band.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ResultExecutionIntentController', () {
    test('builds execution intent from recipe, pairings and source tags', () {
      const controller = ResultExecutionIntentController();
      final recipe = _recipe(tags: const ['热菜', '下饭']);

      final intent = controller.buildIntent(
        recipe: recipe,
        preferredPath: ExecutionPath.delivery,
        pairings: const [
          PairingSuggestion(
            category: '饮品',
            title: '冰乌龙',
            subtitle: '解腻清口',
            accent: Colors.orange,
            icon: Icons.local_drink_rounded,
          ),
        ],
        displayTags: const ['家常', '微辣'],
        structuredConstraints: const TasteStructuredConstraints(),
      );

      expect(intent.recipe, recipe);
      expect(intent.preferredPath, ExecutionPath.delivery);
      expect(intent.sourceTags, ['家常', '微辣']);
      expect(intent.locationPreference, ExecutionLocationPreference.any);
      expect(intent.pairings, hasLength(1));
      expect(intent.pairings.single.category, '饮品');
      expect(intent.pairings.single.title, '冰乌龙');
      expect(intent.pairings.single.subtitle, '解腻清口');
    });

    test('falls back to recipe tags when display tags are empty', () {
      const controller = ResultExecutionIntentController();

      final intent = controller.buildIntent(
        recipe: _recipe(tags: const ['凉面', '外卖']),
        preferredPath: ExecutionPath.dineIn,
        pairings: const [],
        displayTags: const [],
        structuredConstraints: const TasteStructuredConstraints(),
      );

      expect(intent.sourceTags, ['凉面', '外卖']);
    });

    test('maps nearby structured constraint to execution location preference',
        () {
      const controller = ResultExecutionIntentController();

      final intent = controller.buildIntent(
        recipe: _recipe(),
        preferredPath: ExecutionPath.dineIn,
        pairings: const [],
        displayTags: const ['附近'],
        structuredConstraints: const TasteStructuredConstraints(
          locationPreference: TasteLocationPreference.nearby,
        ),
      );

      expect(intent.locationPreference, ExecutionLocationPreference.nearby);
    });

    test('preserves recommendation telemetry context and candidate position',
        () {
      const controller = ResultExecutionIntentController();
      const recommendationContext = RecommendationTelemetryContext(
        recommendationId: 'rec_shared',
        algorithmVersion: 'hybrid_v3_0',
        primarySource: 'unified_db',
        resolutionStatus: RecommendationResolutionStatus.dbResolved,
        recalledCount: 12,
        finalCount: 5,
        latencyMs: 180,
        diversityScore: 0.8,
        appliedConstraintCount: 2,
      );

      final intent = controller.buildIntent(
        recipe: _recipe(),
        preferredPath: ExecutionPath.cook,
        pairings: const [],
        displayTags: const ['家常'],
        recommendationContext: recommendationContext,
        recommendationPosition: 2,
      );

      expect(intent.recommendationContext, same(recommendationContext));
      expect(intent.recommendationPosition, 2);
    });
  });
}

RecipeModel _recipe({List<String> tags = const ['家常']}) {
  return RecipeModel(
    id: 'dish_1',
    name: '番茄肥牛锅',
    description: '热乎下饭',
    tags: tags,
  );
}
