import 'package:eatwhat_app/v2/core/data/models/taste_inference_input.dart';
import 'package:eatwhat_app/v2/core/data/models/taste_selection_models.dart';
import 'package:eatwhat_app/v2/core/data/schema/unified_tag_model.dart';
import 'package:eatwhat_app/v2/core/services/unified_recommendation_service_v2.dart';
import 'package:eatwhat_app/v2/core/services/v2_tag_catalog_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UnifiedRecommendationServiceV2', () {
    test('优先使用 dish_tag 标签召回，FTS 为空时仍能推荐', () async {
      var capturedTagIds = <String>[];
      var searchCalled = false;

      final service = UnifiedRecommendationServiceV2(
        tagCatalogService: _StaticCatalogService([
          const UnifiedTagModel(
            id: 'db_howtocook_category_7',
            label: '荤菜',
            category: 'ingredient',
            iconAsset: 'restaurant',
            visual: VisualConfig(
              shapeType: 'squircle',
              colors: ['0xFF4F9D69', '0xFF7ABF88'],
            ),
          ),
        ]),
        tagRecipeLoader: (tagIds, limit) async {
          capturedTagIds = tagIds;
          return [
            _row(
              dishId: 101,
              recipeId: 201,
              name: '黄焖鸡',
              tags: const ['荤菜', '家常菜'],
            ),
          ];
        },
        searchRecipeLoader: (query, limit) async {
          searchCalled = true;
          return const [];
        },
        tagScoreLoader: () async => const {},
        favoriteTagLoader: () async => const {},
        favoriteDishLoader: () async => const {},
        recentRecipeLoader: () async => const [],
      );

      final result = await service.recommendRecipes(
        input: const TasteInferenceInput(
          likedTagIds: ['db_howtocook_category_7'],
          likedTagLabels: ['荤菜'],
          dislikedTagIds: [],
          dislikedTagLabels: [],
          skippedTagIds: [],
          skippedTagLabels: [],
          freeformRequirement: '',
          historyPreferenceSummary: {},
        ),
        recallLabels: const ['荤菜'],
      );

      expect(capturedTagIds, ['7']);
      expect(searchCalled, isTrue);
      expect(result.map((recipe) => recipe.name), ['黄焖鸡']);
    });

    test('推荐 bundle 会返回可展示的本地打分解释', () async {
      final service = UnifiedRecommendationServiceV2(
        tagCatalogService: _StaticCatalogService([
          const UnifiedTagModel(
            id: 'db_howtocook_category_7',
            label: '荤菜',
            category: 'ingredient',
            iconAsset: 'restaurant',
            visual: VisualConfig(
              shapeType: 'squircle',
              colors: ['0xFF4F9D69', '0xFF7ABF88'],
            ),
          ),
        ]),
        tagRecipeLoader: (tagIds, limit) async => [
          _row(
            dishId: 101,
            recipeId: 201,
            name: '黄焖鸡',
            tags: const ['荤菜', '家常菜'],
            popularity: 80,
            rating: 4.8,
          ),
        ],
        searchRecipeLoader: (query, limit) async => const [],
        tagScoreLoader: () async => const {'db_howtocook_category_7': 3},
        favoriteTagLoader: () async => const {'db_howtocook_category_7'},
        favoriteDishLoader: () async => const {},
        recentRecipeLoader: () async => const [],
      );

      final bundle = await service.buildRecommendationBundle(
        input: const TasteInferenceInput(
          likedTagIds: ['db_howtocook_category_7'],
          likedTagLabels: ['荤菜'],
          dislikedTagIds: [],
          dislikedTagLabels: [],
          skippedTagIds: [],
          skippedTagLabels: [],
          freeformRequirement: '',
          historyPreferenceSummary: {'db_howtocook_category_7': 3},
        ),
        recallLabels: const ['荤菜'],
      );

      expect(bundle.recipes.map((recipe) => recipe.name), ['黄焖鸡']);
      expect(bundle.reasonsByRecipeId['101'], contains('命中 荤菜'));
      expect(bundle.reasonsByRecipeId['101'], contains('评分 4.8'));
      expect(bundle.summary, contains('HowToCook'));
    });

    test('硬约束会过滤超过用餐时间要求的候选', () async {
      final service = _serviceWithRows([
        _row(
          dishId: 101,
          recipeId: 201,
          name: '快手番茄蛋',
          tags: const ['家常菜'],
          totalTimeMinutes: 12,
        ),
        _row(
          dishId: 102,
          recipeId: 202,
          name: '慢炖红烧肉',
          tags: const ['家常菜'],
          totalTimeMinutes: 45,
        ),
      ]);

      final bundle = await service.buildRecommendationBundle(
        input: const TasteInferenceInput(
          likedTagIds: [],
          likedTagLabels: ['家常菜'],
          dislikedTagIds: [],
          dislikedTagLabels: [],
          skippedTagIds: [],
          skippedTagLabels: [],
          freeformRequirement: '15 分钟内吃上',
          historyPreferenceSummary: {},
        ),
        recallLabels: const ['家常菜', '15'],
      );

      expect(bundle.recipes.map((recipe) => recipe.name), ['快手番茄蛋']);
      expect(bundle.reasonsByRecipeId['101'], contains('15 分钟内'));
      expect(bundle.summary, contains('已按时间约束过滤'));
    });

    test('结构化时间约束不依赖自然语言也会过滤候选', () async {
      final service = _serviceWithRows([
        _row(
          dishId: 101,
          recipeId: 201,
          name: '快手拌面',
          tags: const ['家常菜'],
          totalTimeMinutes: 10,
        ),
        _row(
          dishId: 102,
          recipeId: 202,
          name: '慢炖牛腩',
          tags: const ['家常菜'],
          totalTimeMinutes: 70,
        ),
      ]);

      final bundle = await service.buildRecommendationBundle(
        input: const TasteInferenceInput(
          likedTagIds: [],
          likedTagLabels: ['家常菜'],
          dislikedTagIds: [],
          dislikedTagLabels: [],
          skippedTagIds: [],
          skippedTagLabels: [],
          freeformRequirement: '',
          structuredConstraints: TasteStructuredConstraints(maxTimeMinutes: 15),
          historyPreferenceSummary: {},
        ),
        recallLabels: const ['家常菜'],
      );

      expect(bundle.recipes.map((recipe) => recipe.name), ['快手拌面']);
      expect(bundle.summary, contains('时间约束'));
    });

    test('硬约束会过滤明确忌口的食材和标签', () async {
      final service = _serviceWithRows([
        _row(
          dishId: 101,
          recipeId: 201,
          name: '清炒时蔬',
          tags: const ['素菜'],
          ingredients: const ['青菜'],
        ),
        _row(
          dishId: 102,
          recipeId: 202,
          name: '蒜蓉虾仁',
          tags: const ['海鲜'],
          ingredients: const ['虾仁'],
        ),
      ]);

      final bundle = await service.buildRecommendationBundle(
        input: const TasteInferenceInput(
          likedTagIds: [],
          likedTagLabels: ['家常菜'],
          dislikedTagIds: ['allergy_seafood'],
          dislikedTagLabels: ['海鲜过敏'],
          skippedTagIds: [],
          skippedTagLabels: [],
          freeformRequirement: '',
          historyPreferenceSummary: {},
        ),
        recallLabels: const ['家常菜'],
      );

      expect(bundle.recipes.map((recipe) => recipe.name), ['清炒时蔬']);
      expect(bundle.summary, contains('忌口'));
    });

    test('自然语言素食约束会过滤肉类候选', () async {
      final service = _serviceWithRows([
        _row(
          dishId: 101,
          recipeId: 201,
          name: '番茄豆腐煲',
          tags: const ['素菜', '家常菜'],
          ingredients: const ['番茄', '豆腐'],
        ),
        _row(
          dishId: 102,
          recipeId: 202,
          name: '土豆烧牛肉',
          tags: const ['荤菜', '家常菜'],
          ingredients: const ['土豆', '牛肉'],
        ),
      ]);

      final bundle = await service.buildRecommendationBundle(
        input: const TasteInferenceInput(
          likedTagIds: [],
          likedTagLabels: ['家常菜'],
          dislikedTagIds: [],
          dislikedTagLabels: [],
          skippedTagIds: [],
          skippedTagLabels: [],
          freeformRequirement: '今天吃素食，不要肉',
          historyPreferenceSummary: {},
        ),
        recallLabels: const ['家常菜'],
      );

      expect(bundle.recipes.map((recipe) => recipe.name), ['番茄豆腐煲']);
      expect(bundle.summary, contains('忌口'));
    });

    test('自然语言清真约束会过滤猪肉候选', () async {
      final service = _serviceWithRows([
        _row(
          dishId: 101,
          recipeId: 201,
          name: '孜然羊肉',
          tags: const ['清真友好', '家常菜'],
          ingredients: const ['羊肉', '孜然'],
        ),
        _row(
          dishId: 102,
          recipeId: 202,
          name: '红烧五花肉',
          tags: const ['家常菜'],
          ingredients: const ['五花肉', '猪肉'],
        ),
      ]);

      final bundle = await service.buildRecommendationBundle(
        input: const TasteInferenceInput(
          likedTagIds: [],
          likedTagLabels: ['家常菜'],
          dislikedTagIds: [],
          dislikedTagLabels: [],
          skippedTagIds: [],
          skippedTagLabels: [],
          freeformRequirement: '清真一点，别有猪肉',
          historyPreferenceSummary: {},
        ),
        recallLabels: const ['家常菜'],
      );

      expect(bundle.recipes.map((recipe) => recipe.name), ['孜然羊肉']);
      expect(bundle.summary, contains('忌口'));
    });

    test('预算约束会下沉明显高成本候选', () async {
      final service = _serviceWithRows([
        _row(
          dishId: 101,
          recipeId: 201,
          name: '青菜豆腐汤',
          tags: const ['家常菜'],
          ingredients: const ['青菜', '豆腐'],
          popularity: 40,
          rating: 4.0,
        ),
        _row(
          dishId: 102,
          recipeId: 202,
          name: '帝王蟹海鲜锅',
          tags: const ['海鲜', '聚会'],
          ingredients: const ['帝王蟹', '虾', '鲍鱼'],
          popularity: 90,
          rating: 4.9,
        ),
      ]);

      final bundle = await service.buildRecommendationBundle(
        input: const TasteInferenceInput(
          likedTagIds: [],
          likedTagLabels: ['家常菜'],
          dislikedTagIds: [],
          dislikedTagLabels: [],
          skippedTagIds: [],
          skippedTagLabels: [],
          freeformRequirement: '30 元内，经济一点',
          historyPreferenceSummary: {},
        ),
        recallLabels: const ['家常菜'],
        limit: 2,
      );

      expect(bundle.recipes.map((recipe) => recipe.name).first, '青菜豆腐汤');
      expect(bundle.reasonsByRecipeId['101'], contains('预算友好'));
      expect(bundle.summary, contains('预算'));
    });

    test('结构化预算和人数约束会参与排序', () async {
      final service = _serviceWithRows([
        _row(
          dishId: 101,
          recipeId: 201,
          name: '一人份番茄豆腐面',
          tags: const ['家常菜'],
          ingredients: const ['番茄', '豆腐', '面'],
          servings: 1,
          rating: 4.1,
        ),
        _row(
          dishId: 102,
          recipeId: 202,
          name: '家庭帝王蟹锅',
          tags: const ['家常菜'],
          ingredients: const ['帝王蟹', '虾'],
          servings: 6,
          popularity: 90,
          rating: 4.9,
        ),
      ]);

      final bundle = await service.buildRecommendationBundle(
        input: const TasteInferenceInput(
          likedTagIds: [],
          likedTagLabels: ['家常菜'],
          dislikedTagIds: [],
          dislikedTagLabels: [],
          skippedTagIds: [],
          skippedTagLabels: [],
          freeformRequirement: '',
          structuredConstraints: TasteStructuredConstraints(
            maxBudgetYuan: 30,
            partySize: 1,
          ),
          historyPreferenceSummary: {},
        ),
        recallLabels: const ['家常菜'],
        limit: 2,
      );

      expect(bundle.recipes.map((recipe) => recipe.name).first, '一人份番茄豆腐面');
      expect(bundle.summary, contains('预算、人数'));
    });

    test('人数约束会优先推荐分量匹配的候选', () async {
      final service = _serviceWithRows([
        _row(
          dishId: 101,
          recipeId: 201,
          name: '一人食番茄面',
          tags: const ['家常菜'],
          servings: 1,
          rating: 4.2,
        ),
        _row(
          dishId: 102,
          recipeId: 202,
          name: '家庭装炖锅',
          tags: const ['家常菜'],
          servings: 6,
          popularity: 90,
          rating: 4.8,
        ),
      ]);

      final bundle = await service.buildRecommendationBundle(
        input: const TasteInferenceInput(
          likedTagIds: [],
          likedTagLabels: ['家常菜'],
          dislikedTagIds: [],
          dislikedTagLabels: [],
          skippedTagIds: [],
          skippedTagLabels: [],
          freeformRequirement: '1人吃，别太多',
          historyPreferenceSummary: {},
        ),
        recallLabels: const ['家常菜'],
        limit: 2,
      );

      expect(bundle.recipes.map((recipe) => recipe.name).first, '一人食番茄面');
      expect(bundle.reasonsByRecipeId['101'], contains('适合 1 人'));
      expect(bundle.summary, contains('人数'));
    });
  });
}

UnifiedRecommendationServiceV2 _serviceWithRows(
  List<Map<String, dynamic>> rows,
) {
  return UnifiedRecommendationServiceV2(
    tagCatalogService: _StaticCatalogService(const []),
    tagRecipeLoader: (tagIds, limit) async => rows,
    searchRecipeLoader: (query, limit) async => rows,
    tagScoreLoader: () async => const {},
    favoriteTagLoader: () async => const {},
    favoriteDishLoader: () async => const {},
    recentRecipeLoader: () async => const [],
  );
}

Map<String, dynamic> _row({
  required int dishId,
  required int recipeId,
  required String name,
  required List<String> tags,
  List<String> ingredients = const ['鸡腿'],
  int popularity = 50,
  double rating = 4.5,
  int totalTimeMinutes = 30,
  int servings = 2,
}) {
  return {
    'dish_id': dishId,
    'dish_name': name,
    'cuisine': '家常菜',
    'taste_profile': '{}',
    'cooking_methods': const [],
    'scenes': const [],
    'health_tags': const [],
    'main_ingredients': const [],
    'popularity_score': popularity,
    'average_rating': rating,
    'recipe_id': recipeId,
    'source': 'test',
    'source_recipe_id': '$recipeId',
    'recipe_title': name,
    'recipe_description': '适合今晚的一道热菜。',
    'difficulty': 2,
    'total_time_minutes': totalTimeMinutes,
    'servings': servings,
    'cover_image_url': '',
    'tags': tags,
    'ingredients': [
      for (final ingredient in ingredients)
        {'name': ingredient, 'amount': '适量', 'unit': ''},
    ],
    'steps': const [],
    'nutrition': const {},
    'taste_profile_map': const {},
    'main_ingredients_list': const [],
  };
}

class _StaticCatalogService extends V2TagCatalogService {
  _StaticCatalogService(this.tags) : super(dbTagLoader: () async => const []);

  final List<UnifiedTagModel> tags;

  @override
  Future<List<UnifiedTagModel>> loadTags(
      {int minimumFallbackCount = 36}) async {
    return tags;
  }
}
