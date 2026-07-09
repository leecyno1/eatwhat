import 'package:eatwhat_app/v2/core/data/models/ai_generation_models.dart';
import 'package:eatwhat_app/v2/core/data/models/recipe_model.dart';
import 'package:eatwhat_app/v2/core/data/models/recommendation_resolution.dart';
import 'package:eatwhat_app/v2/core/data/models/taste_inference_input.dart';
import 'package:eatwhat_app/v2/core/data/models/taste_selection_models.dart';
import 'package:eatwhat_app/v2/core/services/v2_howtocook_recipe_service.dart';
import 'package:eatwhat_app/v2/core/services/v2_phase2_recommendation_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('第二环节服务优先使用 AI 生成菜品，不调用本地召回或精排', () async {
    var localCalled = false;
    var refinerCalled = false;

    final service = V2Phase2RecommendationService(
      localRecommendationLoader: (input, selectedTagLabels, limit) async {
        localCalled = true;
        return const [
          RecipeModel(
            id: 'local_1',
            name: '本地候选菜',
            description: '不应该进入结果。',
          ),
        ];
      },
      recommendationRefiner: ({
        required selectedTags,
        required candidates,
        required limit,
        required customRequirement,
      }) async {
        refinerCalled = true;
        return const AiRefinedRecommendations(
          recipeIds: ['local_1'],
          reasonsById: {},
        );
      },
      aiRecommendationLoader: ({
        required tags,
        required userProfile,
      }) async {
        return const [
          RecipeModel(
            id: 'ai_1',
            name: '金汤肥牛',
            description: '酸香热口，适合今晚。',
            ingredients: ['肥牛', '金针菇'],
            source: 'AI Recommendation',
          ),
          RecipeModel(
            id: 'ai_2',
            name: '番茄牛腩煲',
            description: '热乎、浓口、带汤感。',
            ingredients: ['牛腩', '番茄'],
            source: 'AI Recommendation',
          ),
        ];
      },
      howToCookRecipeService: _emptyHowToCookService(),
    );

    final result = await service.buildRecommendations(
      input: const TasteInferenceInput(
        likedTagIds: ['scene_night'],
        likedTagLabels: ['夜宵'],
        dislikedTagIds: [],
        dislikedTagLabels: [],
        skippedTagIds: [],
        skippedTagLabels: [],
        freeformRequirement: '今晚想吃热一点',
        historyPreferenceSummary: {},
      ),
    );

    expect(localCalled, isFalse);
    expect(refinerCalled, isFalse);
    expect(result.resolutionStatus, RecommendationResolutionStatus.aiResolved);
    expect(result.primarySource, 'ai');
    expect(result.recalledCount, 2);
    expect(result.finalRecommendations.map((item) => item.name), [
      '金汤肥牛',
      '番茄牛腩煲',
    ]);
    expect(result.aiSummary, contains('AI 已根据口味签名生成'));
  });

  test('第二环节服务会把结构化约束和历史偏好交给 AI', () async {
    String capturedUserProfile = '';
    List<String> capturedTags = const [];

    final service = V2Phase2RecommendationService(
      aiRecommendationLoader: ({
        required tags,
        required userProfile,
      }) async {
        capturedTags = tags;
        capturedUserProfile = userProfile;
        return const [
          RecipeModel(
            id: 'ai_1',
            name: '番茄豆腐面',
            description: '预算友好，15 分钟内能落地。',
            ingredients: ['番茄', '豆腐', '面'],
            source: 'AI Recommendation',
          ),
        ];
      },
      howToCookRecipeService: _emptyHowToCookService(),
    );

    await service.buildRecommendations(
      input: const TasteInferenceInput(
        likedTagIds: ['f_home'],
        likedTagLabels: ['家常'],
        dislikedTagIds: ['f_spicy'],
        dislikedTagLabels: ['辣'],
        skippedTagIds: ['scene_party'],
        skippedTagLabels: ['聚会'],
        freeformRequirement: '想吃清爽一点',
        structuredConstraints: TasteStructuredConstraints(
          maxTimeMinutes: 15,
          maxBudgetYuan: 30,
          partySize: 1,
        ),
        historyPreferenceSummary: {'f_home': 3},
      ),
    );

    expect(capturedTags, containsAll(['家常', '15 分钟内', '30 元内', '1 人']));
    expect(capturedUserProfile, contains('硬性约束：15 分钟内、30 元内、1 人'));
    expect(capturedUserProfile, contains('历史偏好'));
    expect(capturedUserProfile, contains('不要：辣'));
    expect(capturedUserProfile, contains('这轮略过：聚会'));
  });

  test('第二环节服务会过滤 AI 泛化菜名、占位菜和排除项', () async {
    final service = V2Phase2RecommendationService(
      aiRecommendationLoader: ({
        required tags,
        required userProfile,
      }) async {
        return const [
          RecipeModel(
            id: 'ai_placeholder',
            name: 'dessert_示例菜谱1',
            description: '占位数据。',
            source: 'AI Recommendation',
          ),
          RecipeModel(
            id: 'ai_generic',
            name: '今晚推荐热菜',
            description: '泛化名称。',
            source: 'AI Recommendation',
          ),
          RecipeModel(
            id: 'ai_blocked',
            name: '聚会拼盘',
            description: '命中略过项。',
            tags: ['聚会'],
            source: 'AI Recommendation',
          ),
          RecipeModel(
            id: 'ai_real',
            name: '番茄牛腩煲',
            description: '热乎、浓口、带汤感。',
            ingredients: ['牛腩', '番茄'],
            source: 'AI Recommendation',
          ),
        ];
      },
      howToCookRecipeService: _emptyHowToCookService(),
    );

    final result = await service.buildRecommendations(
      input: const TasteInferenceInput(
        likedTagIds: ['scene_night'],
        likedTagLabels: ['夜宵'],
        dislikedTagIds: [],
        dislikedTagLabels: [],
        skippedTagIds: ['scene_party'],
        skippedTagLabels: ['聚会'],
        freeformRequirement: '今晚想吃热一点',
        historyPreferenceSummary: {},
      ),
    );

    expect(result.finalRecommendations.map((item) => item.id), ['ai_real']);
  });

  test('AI 生成菜品后只用 HowToCook 补图片食材步骤，不改变 AI 理由和来源', () async {
    final service = V2Phase2RecommendationService(
      aiRecommendationLoader: ({
        required tags,
        required userProfile,
      }) async {
        return const [
          RecipeModel(
            id: 'ai_1',
            name: '黄焖鸡',
            description: 'AI 判断它下饭、热口，贴合今晚偏好。',
            ingredients: ['鸡腿肉'],
            source: 'AI Recommendation',
          ),
        ];
      },
      howToCookRecipeService: V2HowToCookRecipeService(
        searchLoader: (query, limit) async => [
          {
            'id': 'htc_1',
            'name': '黄焖鸡',
            'description': 'HowToCook 原菜谱描述。',
            'difficulty': 3,
            'category': '荤菜',
            'cooking_time': 35,
            'servings': 2,
          },
        ],
        completeLoader: (recipeId) async => {
          'id': recipeId,
          'name': '黄焖鸡',
          'description': 'HowToCook 原菜谱描述。',
          'difficulty': 3,
          'category': '荤菜',
          'cooking_time': 35,
          'servings': 2,
          'ingredients': [
            {'name': '鸡腿', 'amount': '2', 'unit': '只'},
          ],
          'steps': [
            {'description': '鸡腿洗净剁块。'},
          ],
        },
        assetIndexLoader: () async => '''
{
  "items": [
    {
      "recipeId": "htc_1",
      "name": "黄焖鸡",
      "aliases": ["黄焖鸡"],
      "assetImageUrls": ["assets/images/howtocook_gallery/huangmenji/1.jpg"],
      "markdownPath": "HowToCook/dishes/meat_dish/黄焖鸡.md",
      "sourceProject": "HowToCook"
    }
  ]
}
''',
      ),
    );

    final result = await service.buildRecommendations(
      input: const TasteInferenceInput(
        likedTagIds: ['f_home'],
        likedTagLabels: ['家常'],
        dislikedTagIds: [],
        dislikedTagLabels: [],
        skippedTagIds: [],
        skippedTagLabels: [],
        freeformRequirement: '今晚想吃热一点',
        historyPreferenceSummary: {},
      ),
    );

    expect(result.resolutionStatus, RecommendationResolutionStatus.aiResolved);
    expect(result.primarySource, 'ai');
    expect(result.finalRecommendations, hasLength(1));
    expect(result.finalRecommendations.first.description, contains('AI 判断'));
    expect(result.finalRecommendations.first.source, 'AI Recommendation');
    expect(result.finalRecommendations.first.ingredients, contains('鸡腿 2只'));
    expect(result.finalRecommendations.first.steps, contains('鸡腿洗净剁块。'));
    expect(
      result.finalRecommendations.first.imageUrl,
      'assets/images/howtocook_gallery/huangmenji/1.jpg',
    );
    expect(result.aiReasonsByRecipeId['ai_1'], contains('AI 判断'));
  });

  test('AI 为空时不使用 HowToCook 兜底生成菜品', () async {
    var howToCookSearchCalled = false;
    final service = V2Phase2RecommendationService(
      aiRecommendationLoader: ({
        required tags,
        required userProfile,
      }) async =>
          const [],
      howToCookRecipeService: V2HowToCookRecipeService(
        searchLoader: (_, __) async {
          howToCookSearchCalled = true;
          return const [
            {
              'id': 'htc_1',
              'name': '番茄炒蛋',
              'description': '不应该作为兜底结果出现。',
            },
          ];
        },
        completeLoader: (_) async => null,
        assetIndexLoader: () async => '{"items":[]}',
      ),
    );

    final result = await service.buildRecommendations(
      input: const TasteInferenceInput(
        likedTagIds: [],
        likedTagLabels: [],
        dislikedTagIds: [],
        dislikedTagLabels: [],
        skippedTagIds: [],
        skippedTagLabels: [],
        freeformRequirement: '15',
        historyPreferenceSummary: {},
      ),
    );

    expect(result.resolutionStatus, RecommendationResolutionStatus.empty);
    expect(result.primarySource, 'ai');
    expect(result.finalRecommendations, isEmpty);
    expect(howToCookSearchCalled, isFalse);
  });

  test('AI 服务异常时返回错误态而不是本地候选', () async {
    final service = V2Phase2RecommendationService(
      aiRecommendationLoader: ({
        required tags,
        required userProfile,
      }) async {
        throw Exception('ai failed');
      },
      howToCookRecipeService: _emptyHowToCookService(),
    );

    final result = await service.buildRecommendations(
      input: const TasteInferenceInput(
        likedTagIds: ['scene_night'],
        likedTagLabels: ['夜宵'],
        dislikedTagIds: [],
        dislikedTagLabels: [],
        skippedTagIds: [],
        skippedTagLabels: [],
        freeformRequirement: '今晚想吃热一点',
        historyPreferenceSummary: {},
      ),
    );

    expect(result.resolutionStatus, RecommendationResolutionStatus.empty);
    expect(result.primarySource, 'error');
    expect(result.finalRecommendations, isEmpty);
    expect(result.aiSummary, contains('AI 推荐服务暂时不可用'));
  });

  test('HowToCook 富化失败或超时时会保留 AI 原始候选', () async {
    final service = V2Phase2RecommendationService(
      enrichmentTimeout: const Duration(milliseconds: 1),
      aiRecommendationLoader: ({
        required tags,
        required userProfile,
      }) async {
        return const [
          RecipeModel(
            id: 'ai_1',
            name: '番茄肥牛锅',
            description: 'AI 生成的酸甜热汤底。',
            ingredients: ['番茄', '肥牛'],
            source: 'AI Recommendation',
          ),
        ];
      },
      howToCookRecipeService: V2HowToCookRecipeService(
        searchLoader: (_, __) async {
          await Future<void>.delayed(const Duration(seconds: 1));
          return const [];
        },
        completeLoader: (_) async => null,
        assetIndexLoader: () async => '{"items":[]}',
      ),
    );

    final result = await service.buildRecommendations(
      input: const TasteInferenceInput(
        likedTagIds: ['f_hot'],
        likedTagLabels: ['热菜'],
        dislikedTagIds: [],
        dislikedTagLabels: [],
        skippedTagIds: [],
        skippedTagLabels: [],
        freeformRequirement: '',
        historyPreferenceSummary: {},
      ),
    );

    expect(result.resolutionStatus, RecommendationResolutionStatus.aiResolved);
    expect(result.finalRecommendations, hasLength(1));
    expect(result.finalRecommendations.first.description, 'AI 生成的酸甜热汤底。');
    expect(result.finalRecommendations.first.ingredients, ['番茄', '肥牛']);
  });
}

V2HowToCookRecipeService _emptyHowToCookService() {
  return V2HowToCookRecipeService(
    searchLoader: (_, __) async => const [],
    completeLoader: (_) async => null,
    allRecipesLoader: (_) async => const [],
    assetIndexLoader: () async => '{"items":[]}',
  );
}
