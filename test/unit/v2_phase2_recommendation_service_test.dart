import 'package:eatwhat_app/v2/core/data/models/ai_generation_models.dart';
import 'package:eatwhat_app/v2/core/data/models/meal_planning_direction.dart';
import 'package:eatwhat_app/v2/core/data/models/recipe_model.dart';
import 'package:eatwhat_app/v2/core/data/models/recommendation_resolution.dart';
import 'package:eatwhat_app/v2/core/data/models/taste_inference_input.dart';
import 'package:eatwhat_app/v2/core/data/models/taste_selection_models.dart';
import 'package:eatwhat_app/v2/core/services/unified_recommendation_service_v2.dart';
import 'package:eatwhat_app/v2/core/services/v2_howtocook_recipe_service.dart';
import 'package:eatwhat_app/v2/core/services/v2_phase2_recommendation_service.dart';
import 'package:eatwhat_app/v2/core/services/v2_recommendation_canary_service.dart';
import 'package:eatwhat_app/v2/core/services/v2_tag_catalog_service.dart';
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

  test('未配置 AI 时默认服务会从随包数据库返回正式候选', () async {
    final service = V2Phase2RecommendationService(
      enableAiEnhancement: false,
      howToCookRecipeService: _emptyHowToCookService(),
    );

    final result = await service.buildRecommendations(
      input: const TasteInferenceInput(
        likedTagIds: [],
        likedTagLabels: ['家常菜'],
        dislikedTagIds: [],
        dislikedTagLabels: [],
        skippedTagIds: [],
        skippedTagLabels: [],
        freeformRequirement: '今晚想吃热一点',
        historyPreferenceSummary: {},
      ),
    );

    expect(
      result.finalRecommendations,
      isNotEmpty,
      reason:
          'status=${result.resolutionStatus}, fallback=${result.fallbackReason}, summary=${result.aiSummary}',
    );
    expect(result.finalRecommendations.length, lessThanOrEqualTo(5));
    expect(result.resolutionStatus, RecommendationResolutionStatus.dbResolved);
    expect(result.primarySource, 'unified_db');
    expect(
      result.finalRecommendations.every(
        (recipe) =>
            recipe.id.trim().isNotEmpty && recipe.name.trim().isNotEmpty,
      ),
      isTrue,
    );
  });

  test('灰度命中的算法版本会穿透到第二阶段结果', () async {
    final recommendationService = UnifiedRecommendationServiceV2(
      tagCatalogService: V2TagCatalogService(
        dbTagLoader: () async => const [],
      ),
      tagRecipeLoader: (_, __) async => const [],
      searchRecipeLoader: (_, __) async => [_unifiedRow()],
      defaultRecipeLoader: (_) async => [_unifiedRow()],
      tagScoreLoader: () async => const {},
      favoriteTagLoader: () async => const {},
      favoriteDishLoader: () async => const {},
      recentRecipeLoader: () async => const [],
      canaryDecisionLoader: () async => const RecommendationCanaryDecision(
        useExperiment: true,
        rankingVersion: 'local_rank_v3_quality_shadow',
        algorithmVersion: 'hybrid_v3_0_rank_v3_canary',
      ),
    );
    final service = V2Phase2RecommendationService(
      recommendationService: recommendationService,
      enableAiEnhancement: false,
      howToCookRecipeService: _emptyHowToCookService(),
    );

    final result = await service.buildRecommendations(input: _input());

    expect(result.finalRecommendations.map((recipe) => recipe.id), ['42']);
    expect(result.algorithmVersion, 'hybrid_v3_0_rank_v3_canary');
  });

  test('第二环节先使用本地候选，再让 AI 只在候选集内精排', () async {
    var localCalled = false;
    var refinerCalled = false;

    final service = V2Phase2RecommendationService(
      localRecommendationLoader: (input, selectedTagLabels, limit) async {
        localCalled = true;
        expect(selectedTagLabels, contains('夜宵'));
        return const [
          RecipeModel(
            id: 'local_1',
            name: '番茄牛腩煲',
            description: '本地菜谱一。',
            source: 'unified_db',
          ),
          RecipeModel(
            id: 'local_2',
            name: '金汤肥牛',
            description: '本地菜谱二。',
            source: 'unified_db',
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
        expect(candidates.map((item) => item.id), ['local_1', 'local_2']);
        return const AiRefinedRecommendations(
          recipeIds: ['local_2', 'local_1'],
          reasonsById: {
            'local_2': '酸香热口，更贴合今晚。',
            'local_1': '热乎、浓口、带汤感。',
          },
          summary: '已在本地正式菜品中完成智能收束。',
        );
      },
      howToCookRecipeService: _emptyHowToCookService(),
    );

    final result = await service.buildRecommendations(
      input: _input(),
    );

    expect(localCalled, isTrue);
    expect(refinerCalled, isTrue);
    expect(
      result.resolutionStatus,
      RecommendationResolutionStatus.hybridResolved,
    );
    expect(result.primarySource, 'hybrid');
    expect(result.recalledCount, 2);
    expect(result.finalRecommendations.map((item) => item.id), [
      'local_2',
      'local_1',
    ]);
    expect(result.aiReasonsByRecipeId['local_2'], contains('今晚'));
    expect(result.aiSummary, contains('本地正式菜品'));
    expect(result.algorithmVersion, 'hybrid_v3_0');
  });

  test('第二环节会把结构化约束、历史偏好和排除项交给精排', () async {
    String? capturedRequirement;
    List<String> capturedTags = const [];

    final service = V2Phase2RecommendationService(
      localRecommendationLoader: (_, __, ___) async => const [
        RecipeModel(
          id: 'local_1',
          name: '番茄豆腐面',
          description: '快手家常。',
          source: 'unified_db',
        ),
      ],
      recommendationRefiner: ({
        required selectedTags,
        required candidates,
        required limit,
        required customRequirement,
      }) async {
        capturedTags = selectedTags;
        capturedRequirement = customRequirement;
        return const AiRefinedRecommendations(
          recipeIds: ['local_1'],
          reasonsById: {},
        );
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
        planningDirection: MealPlanningDirection.health,
      ),
    );

    expect(
      capturedTags,
      containsAll(['家常', '高蛋白', '15 分钟内', '30 元内', '1 人']),
    );
    expect(capturedRequirement, contains('规划方向：健康向'));
    expect(capturedRequirement, contains('硬性约束：15 分钟内、30 元内、1 人'));
    expect(capturedRequirement, contains('历史偏好'));
    expect(capturedRequirement, contains('不要：辣'));
    expect(capturedRequirement, contains('这轮略过：聚会'));
  });

  test('精排返回未知或重复 dishId 时只保留正式本地候选', () async {
    final service = V2Phase2RecommendationService(
      localRecommendationLoader: (_, __, ___) async => const [
        RecipeModel(
          id: 'local_1',
          name: '番茄牛腩煲',
          description: '本地候选一。',
          source: 'unified_db',
        ),
        RecipeModel(
          id: 'local_2',
          name: '金汤肥牛',
          description: '本地候选二。',
          source: 'unified_db',
        ),
      ],
      recommendationRefiner: ({
        required selectedTags,
        required candidates,
        required limit,
        required customRequirement,
      }) async {
        return const AiRefinedRecommendations(
          recipeIds: ['unknown', 'local_2', 'local_2'],
          reasonsById: {
            'unknown': '不允许进入正式结果。',
            'local_2': '允许保留。',
          },
        );
      },
      howToCookRecipeService: _emptyHowToCookService(),
    );

    final result = await service.buildRecommendations(input: _input());

    expect(result.finalRecommendations.map((item) => item.id), [
      'local_2',
      'local_1',
    ]);
    expect(result.aiReasonsByRecipeId.keys, isNot(contains('unknown')));
    expect(
        result.finalRecommendations
            .every((item) => item.source == 'unified_db'),
        isTrue);
  });

  test('本地召回会过滤占位菜名和本轮排除项', () async {
    final service = V2Phase2RecommendationService(
      enableAiEnhancement: false,
      localRecommendationLoader: (_, __, ___) async => const [
        RecipeModel(
          id: 'placeholder',
          name: 'dessert_示例菜谱1',
          description: '占位数据。',
          source: 'unified_db',
        ),
        RecipeModel(
          id: 'blocked',
          name: '聚会拼盘',
          description: '命中略过项。',
          tags: ['聚会'],
          source: 'unified_db',
        ),
        RecipeModel(
          id: 'real',
          name: '番茄牛腩煲',
          description: '热乎、浓口、带汤感。',
          source: 'unified_db',
        ),
      ],
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

    expect(result.finalRecommendations.map((item) => item.id), ['real']);
    expect(result.resolutionStatus, RecommendationResolutionStatus.dbResolved);
    expect(result.primarySource, 'unified_db');
  });

  test('有替代方案时优先展示不同类型的候选', () async {
    final service = V2Phase2RecommendationService(
      enableAiEnhancement: false,
      localRecommendationLoader: (_, __, ___) async => const [
        RecipeModel(
          id: 'chicken',
          name: '黄焖鸡',
          description: '家常下饭。',
          tags: ['家常'],
          ingredients: ['鸡肉'],
          source: 'unified_db',
        ),
        RecipeModel(
          id: 'beef',
          name: '土豆烧牛肉',
          description: '家常热菜。',
          tags: ['家常'],
          ingredients: ['牛肉'],
          source: 'unified_db',
        ),
        RecipeModel(
          id: 'tofu',
          name: '番茄豆腐煲',
          description: '清爽素食。',
          tags: ['素食'],
          ingredients: ['豆腐'],
          source: 'unified_db',
        ),
      ],
      howToCookRecipeService: _emptyHowToCookService(),
    );

    final result = await service.buildRecommendations(
      input: _input(),
      recallLimit: 3,
      finalLimit: 2,
    );

    expect(result.finalRecommendations.map((recipe) => recipe.id), [
      'chicken',
      'tofu',
    ]);
    expect(result.diversityScore, 1);
  });

  test('兼容旧 AI loader 时只按菜名映射回本地 canonical dishId', () async {
    final service = V2Phase2RecommendationService(
      localRecommendationLoader: (_, __, ___) async => const [
        RecipeModel(
          id: 'dish_42',
          name: '黄焖鸡',
          description: '本地正式描述。',
          source: 'unified_db',
        ),
      ],
      aiRecommendationLoader: ({
        required tags,
        required userProfile,
      }) async =>
          const [
        RecipeModel(
          id: 'ai_unknown_id',
          name: '黄焖鸡',
          description: 'AI 判断它更贴合本轮口味。',
          source: 'AI Recommendation',
        ),
        RecipeModel(
          id: 'ai_invented',
          name: '不存在的幻想料理',
          description: '不能进入结果。',
          source: 'AI Recommendation',
        ),
      ],
      howToCookRecipeService: _emptyHowToCookService(),
    );

    final result = await service.buildRecommendations(input: _input());

    expect(result.finalRecommendations, hasLength(1));
    expect(result.finalRecommendations.first.id, 'dish_42');
    expect(result.finalRecommendations.first.source, 'unified_db');
    expect(result.aiReasonsByRecipeId['dish_42'], contains('AI 判断'));
    expect(
        result.resolutionStatus, RecommendationResolutionStatus.hybridResolved);
  });

  test('AI 返回空结果时保留本地候选并标记 local fallback', () async {
    final service = V2Phase2RecommendationService(
      localRecommendationLoader: (_, __, ___) async => const [
        RecipeModel(
          id: 'local_1',
          name: '番茄炒蛋',
          description: '稳定的本地候选。',
          source: 'unified_db',
        ),
      ],
      aiRecommendationLoader: ({
        required tags,
        required userProfile,
      }) async =>
          const [],
      howToCookRecipeService: _emptyHowToCookService(),
    );

    final result = await service.buildRecommendations(input: _input());

    expect(result.finalRecommendations.map((item) => item.id), ['local_1']);
    expect(
      result.resolutionStatus,
      RecommendationResolutionStatus.localFallback,
    );
    expect(result.primarySource, 'local_fallback');
    expect(result.fallbackReason, 'ai_empty');
  });

  test('AI 服务异常时返回本地候选而不是错误空状态', () async {
    final service = V2Phase2RecommendationService(
      localRecommendationLoader: (_, __, ___) async => const [
        RecipeModel(
          id: 'local_1',
          name: '番茄炒蛋',
          description: '稳定的本地候选。',
          source: 'unified_db',
        ),
      ],
      aiRecommendationLoader: ({
        required tags,
        required userProfile,
      }) async =>
          throw Exception('ai failed'),
      howToCookRecipeService: _emptyHowToCookService(),
    );

    final result = await service.buildRecommendations(input: _input());

    expect(result.finalRecommendations.map((item) => item.id), ['local_1']);
    expect(
      result.resolutionStatus,
      RecommendationResolutionStatus.localFallback,
    );
    expect(result.primarySource, 'local_fallback');
    expect(result.fallbackReason, 'ai_error');
    expect(result.aiSummary, contains('本地候选'));
  });

  test('AI 超时时立即返回本地候选', () async {
    final service = V2Phase2RecommendationService(
      stageTimeout: const Duration(milliseconds: 1),
      localRecommendationLoader: (_, __, ___) async => const [
        RecipeModel(
          id: 'local_1',
          name: '快手拌面',
          description: '稳定的本地候选。',
          source: 'unified_db',
        ),
      ],
      aiRecommendationLoader: ({
        required tags,
        required userProfile,
      }) async {
        await Future<void>.delayed(const Duration(seconds: 1));
        return const [];
      },
      howToCookRecipeService: _emptyHowToCookService(),
    );

    final result = await service.buildRecommendations(input: _input());

    expect(result.finalRecommendations.map((item) => item.id), ['local_1']);
    expect(result.fallbackReason, 'ai_timeout');
  });

  test('HowToCook 富化失败或超时时仍保留本地 canonical 候选', () async {
    final service = V2Phase2RecommendationService(
      enrichmentTimeout: const Duration(milliseconds: 1),
      localRecommendationLoader: (_, __, ___) async => const [
        RecipeModel(
          id: 'dish_42',
          name: '番茄肥牛锅',
          description: '本地正式描述。',
          ingredients: ['番茄', '肥牛'],
          source: 'unified_db',
        ),
      ],
      recommendationRefiner: ({
        required selectedTags,
        required candidates,
        required limit,
        required customRequirement,
      }) async =>
          const AiRefinedRecommendations(
        recipeIds: ['dish_42'],
        reasonsById: {'dish_42': '酸甜热汤底贴合本轮口味。'},
      ),
      howToCookRecipeService: V2HowToCookRecipeService(
        searchLoader: (_, __) async {
          await Future<void>.delayed(const Duration(seconds: 1));
          return const [];
        },
        completeLoader: (_) async => null,
        assetIndexLoader: () async => '{"items":[]}',
      ),
    );

    final result = await service.buildRecommendations(input: _input());

    expect(result.finalRecommendations, hasLength(1));
    expect(result.finalRecommendations.first.id, 'dish_42');
    expect(result.finalRecommendations.first.description, '本地正式描述。');
    expect(result.finalRecommendations.first.ingredients, ['番茄', '肥牛']);
    expect(result.finalRecommendations.first.source, 'unified_db');
  });

  test('本地数据库没有正式候选时才返回 empty', () async {
    final service = V2Phase2RecommendationService(
      localRecommendationLoader: (_, __, ___) async => const [],
      aiRecommendationLoader: ({
        required tags,
        required userProfile,
      }) async =>
          const [
        RecipeModel(
          id: 'ai_only',
          name: 'AI 独立生成菜',
          description: '没有本地身份，不能进入正式结果。',
        ),
      ],
      howToCookRecipeService: _emptyHowToCookService(),
    );

    final result = await service.buildRecommendations(input: _input());

    expect(result.resolutionStatus, RecommendationResolutionStatus.empty);
    expect(result.primarySource, 'unified_db');
    expect(result.finalRecommendations, isEmpty);
  });

  group('pickImageCousin 融合菜借近亲图', () {
    const fusion = RecipeModel(
      id: 'ai_fusion_1',
      name: '麻辣豆腐牛肉粒盖饭',
      description: '麻辣鲜香',
      ingredients: ['牛肉粒', '嫩豆腐'],
      tags: ['麻辣'],
      source: 'ai_fusion',
    );

    test('信号重叠 ≥2 时借到近亲的图', () {
      final cousin = V2Phase2RecommendationService.pickImageCousin(
        fusion,
        const [
          RecipeModel(
            id: '42',
            name: '麻婆豆腐',
            description: '川菜经典',
            ingredients: ['嫩豆腐', '牛肉末'],
            tags: ['麻辣', '下饭'],
            imageUrl: 'assets/images/prebuilt_dishes/mapo.jpg',
          ),
        ],
      );

      expect(cousin?.id, '42');
      expect(cousin?.imageUrl, 'assets/images/prebuilt_dishes/mapo.jpg');
    });

    test('仅 1 个信号重叠不借图，避免牵强配图', () {
      final cousin = V2Phase2RecommendationService.pickImageCousin(
        fusion,
        const [
          RecipeModel(
            id: '7',
            name: '清蒸鲈鱼',
            description: '清淡',
            ingredients: ['鲈鱼'],
            tags: ['清淡'],
            imageUrl: 'assets/images/prebuilt_dishes/fish.jpg',
          ),
        ],
      );

      expect(cousin, isNull);
    });

    test('无可用信号或无候选时返回 null', () {
      expect(
        V2Phase2RecommendationService.pickImageCousin(
          const RecipeModel(
            id: 'ai_fusion_2',
            name: '无名',
            description: '',
            source: 'ai_fusion',
          ),
          const [
            RecipeModel(
              id: '42',
              name: '麻婆豆腐',
              description: '',
              imageUrl: 'a.jpg',
            ),
          ],
        ),
        isNull,
      );
      expect(
        V2Phase2RecommendationService.pickImageCousin(fusion, const []),
        isNull,
      );
    });
  });
}

TasteInferenceInput _input() {
  return const TasteInferenceInput(
    likedTagIds: ['scene_night'],
    likedTagLabels: ['夜宵'],
    dislikedTagIds: [],
    dislikedTagLabels: [],
    skippedTagIds: [],
    skippedTagLabels: [],
    freeformRequirement: '今晚想吃热一点',
    historyPreferenceSummary: {},
  );
}

V2HowToCookRecipeService _emptyHowToCookService() {
  return V2HowToCookRecipeService(
    searchLoader: (_, __) async => const [],
    completeLoader: (_) async => null,
    allRecipesLoader: (_) async => const [],
    assetIndexLoader: () async => '{"items":[]}',
  );
}

Map<String, dynamic> _unifiedRow() {
  return {
    'dish_id': 42,
    'dish_name': '番茄牛腩煲',
    'cuisine': '家常菜',
    'taste_profile': '{}',
    'cooking_methods': const [],
    'scenes': const [],
    'health_tags': const [],
    'main_ingredients': const [],
    'popularity_score': 80,
    'average_rating': 4.8,
    'recipe_id': 142,
    'source': 'unified_db',
    'source_recipe_id': '142',
    'recipe_title': '番茄牛腩煲',
    'recipe_description': '本地正式描述。',
    'difficulty': 2,
    'total_time_minutes': 30,
    'servings': 2,
    'cover_image_url': '',
    'tags': const ['家常菜'],
    'ingredients': const [
      {'name': '番茄', 'amount': '2', 'unit': '个'},
      {'name': '牛腩', 'amount': '300', 'unit': '克'},
    ],
    'steps': const [],
    'nutrition': const {},
    'taste_profile_map': const {},
    'main_ingredients_list': const [],
  };
}
