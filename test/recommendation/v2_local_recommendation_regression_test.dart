import 'package:eatwhat_app/v2/core/data/models/recipe_model.dart';
import 'package:eatwhat_app/v2/core/data/models/taste_inference_input.dart';
import 'package:eatwhat_app/v2/core/data/models/taste_selection_models.dart';
import 'package:eatwhat_app/v2/core/services/v2_howtocook_recipe_service.dart';
import 'package:eatwhat_app/v2/core/services/v2_phase2_recommendation_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../test_bootstrap.dart';

void main() {
  setUpAll(() async {
    await bootstrapTestEnvironment();
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('V2 bundled database recommendation regressions', () {
    test('家常热菜场景持续返回稳定、多样的正式本地候选', () async {
      final result = await _service().buildRecommendations(
        input: _input(
          likedTagLabels: const ['家常菜'],
          freeformRequirement: '今晚想吃热一点',
        ),
      );

      _expectCanonicalLocalCandidates(result);
      expect(result.finalRecommendations.length, greaterThanOrEqualTo(3));
      expect(result.diversityScore, greaterThanOrEqualTo(0.4));
      expect(
        result.finalRecommendations.any(
          (recipe) => _containsAny(
            _recipeText(recipe),
            const ['荤菜', '素菜', '主食', '汤羹', '快手', '热菜'],
          ),
        ),
        isTrue,
      );
      expect(
        result.latency,
        lessThan(const Duration(seconds: 3)),
        reason: '真实本地推荐耗时 ${result.latency.inMilliseconds}ms',
      );
    });

    test('海鲜过敏场景不会让水产候选穿透本地硬约束', () async {
      final result = await _service().buildRecommendations(
        input: _input(
          likedTagLabels: const ['家常菜'],
          dislikedTagLabels: const ['海鲜过敏'],
        ),
      );

      _expectCanonicalLocalCandidates(result);
      expect(
        result.finalRecommendations.every(
          (recipe) => !_containsAny(
            _recipeText(recipe),
            const ['海鲜', '虾', '鱼', '蟹', '贝'],
          ),
        ),
        isTrue,
      );
    });

    test('素食场景不会让肉类候选穿透自然语言约束', () async {
      final result = await _service().buildRecommendations(
        input: _input(
          likedTagLabels: const ['家常菜'],
          freeformRequirement: '今天吃素食，不要肉',
          structuredConstraints: const TasteStructuredConstraints(
            dietaryRestrictions: ['素食'],
          ),
        ),
      );

      _expectCanonicalLocalCandidates(result);
      expect(
        result.finalRecommendations.every(
          (recipe) => !_containsAny(
            _recipeText(recipe),
            const ['猪', '牛', '羊', '鸡', '鸭', '鱼', '虾', '肉', '荤'],
          ),
        ),
        isTrue,
      );
    });
  });
}

V2Phase2RecommendationService _service() {
  return V2Phase2RecommendationService(
    enableAiEnhancement: false,
    howToCookRecipeService: V2HowToCookRecipeService(
      searchLoader: (_, __) async => const [],
      completeLoader: (_) async => null,
      allRecipesLoader: (_) async => const [],
      assetIndexLoader: () async => '{"items":[]}',
    ),
  );
}

TasteInferenceInput _input({
  List<String> likedTagLabels = const [],
  List<String> dislikedTagLabels = const [],
  String freeformRequirement = '',
  TasteStructuredConstraints structuredConstraints =
      const TasteStructuredConstraints(),
}) {
  return TasteInferenceInput(
    likedTagIds: const [],
    likedTagLabels: likedTagLabels,
    dislikedTagIds: const [],
    dislikedTagLabels: dislikedTagLabels,
    skippedTagIds: const [],
    skippedTagLabels: const [],
    freeformRequirement: freeformRequirement,
    structuredConstraints: structuredConstraints,
    historyPreferenceSummary: const {},
  );
}

void _expectCanonicalLocalCandidates(Phase2RecommendationBundle result) {
  expect(result.finalRecommendations, isNotEmpty);
  expect(result.primarySource, 'unified_db');
  expect(result.finalRecommendations.length, lessThanOrEqualTo(5));
  expect(
    result.finalRecommendations.every(
      (recipe) =>
          int.tryParse(recipe.id) != null &&
          recipe.name.trim().isNotEmpty &&
          !recipe.name.contains('示例菜谱'),
    ),
    isTrue,
  );
  expect(
    result.finalRecommendations.map((recipe) => recipe.id).toSet().length,
    result.finalRecommendations.length,
  );
}

String _recipeText(RecipeModel recipe) {
  return [
    recipe.name,
    recipe.description,
    ...recipe.ingredients,
    ...recipe.tags,
  ].join('|');
}

bool _containsAny(String text, List<String> terms) {
  return terms.any(text.contains);
}
