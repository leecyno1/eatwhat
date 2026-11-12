import 'dart:async';

import 'package:dio/dio.dart';
import 'package:eatwhat_app/core/services/unified_recipe_database_service.dart';
import 'package:eatwhat_app/v2/core/data/models/ai_generation_models.dart';
import 'package:eatwhat_app/v2/core/data/models/meal_planning_direction.dart';
import 'package:eatwhat_app/v2/core/data/models/recipe_model.dart';
import 'package:eatwhat_app/v2/core/data/models/recommendation_resolution.dart';
import 'package:eatwhat_app/v2/core/data/models/taste_inference_input.dart';
import 'package:eatwhat_app/v2/core/data/models/taste_selection_models.dart';
import 'package:eatwhat_app/v2/core/services/generation_service.dart';
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

  group('餐食候选边界', () {
    const input = TasteInferenceInput(
      likedTagIds: [],
      likedTagLabels: [],
      dislikedTagIds: [],
      dislikedTagLabels: [],
      skippedTagIds: [],
      skippedTagLabels: [],
      freeformRequirement: '',
      historyPreferenceSummary: {},
      structuredConstraints: TasteStructuredConstraints(
        executionPreference: TasteExecutionPreference.cook,
      ),
    );
    const meal = RecipeModel(
      id: 'meal',
      name: '青菜豆腐汤',
      description: '',
      ingredients: ['青菜', '豆腐'],
      tags: ['汤羹'],
      steps: ['加水煮熟。'],
    );
    const sauce = RecipeModel(
      id: 'sauce',
      name: '炸串酱料',
      description: '',
      ingredients: ['辣椒面'],
      tags: ['调料', '主食', '夜宵'],
      steps: ['拌匀。'],
    );
    const cocktail = RecipeModel(
      id: 'cocktail',
      name: 'B52轰炸机',
      description: '',
      ingredients: ['伏特加'],
      tags: ['饮品', '夜宵'],
      steps: ['分层倒入。'],
    );

    for (final hour in [15, 23, 2]) {
      test('真实SQLite 零输入 balanced cook 在 $hour 点只返回有步骤餐食', () async {
        expect(input.planningDirection, MealPlanningDirection.balanced);
        // 使用正式 DB、标签目录、召回 SQL 与模型映射，只固定时钟和用户历史。
        final unified = UnifiedRecommendationServiceV2(
          tagScoreLoader: () async => const {},
          favoriteTagLoader: () async => const {},
          favoriteDishLoader: () async => const {},
          recentRecipeLoader: () async => const [],
          mealPeriodClock: () => DateTime(2026, 11, 8, hour),
        );
        final service = V2Phase2RecommendationService(
          recommendationService: unified,
          enableAiEnhancement: false,
          howToCookRecipeService: _emptyHowToCookService(),
        );
        final session = await service.startRecommendationSession(input: input);
        final corpus = await UnifiedRecipeDatabaseService.instance
            .fetchTopRecipes(limit: 500);
        for (final bundle in [session.local, await session.enhanced]) {
          expect(bundle.finalRecommendations, isNotEmpty);
          expect(bundle.finalRecommendations.length, lessThanOrEqualTo(3));
          for (final recipe in bundle.finalRecommendations) {
            final row =
                corpus.firstWhere((row) => '${row['dish_id']}' == recipe.id);
            expect(recipe.name, row['dish_name']);
            expect(recipe.steps, isNotEmpty);
            expect(recipe.ingredients, isNotEmpty);
            expect(recipe.id, isNot(isIn(['53', '78', '152', '203'])));
            expect(row['cuisine'], isNot(isIn(['调料', '饮品', '甜品'])));
          }
        }
      });
    }

    test('真实SQLite 强制默认池仍排除非餐并遵守显式limit', () async {
      final db = UnifiedRecipeDatabaseService.instance;
      final service = UnifiedRecommendationServiceV2(
        tagRecipeLoader: (_, __) async => [],
        searchRecipeLoader: (_, __) async => [],
        defaultRecipeLoader: (limit) => db.fetchDefaultRecipes(limit: limit),
        tagScoreLoader: () async => const {},
        favoriteTagLoader: () async => const {},
        favoriteDishLoader: () async => const {},
        recentRecipeLoader: () async => const [],
        mealPeriodClock: () => DateTime(2026, 11, 8, 23),
      );
      final pool = await db.fetchDefaultRecipes();
      expect(pool.map((row) => row['dish_id']), containsAll([53, 78]));
      final bundle = await service.buildRecommendationBundle(
          input: input, recallLabels: [], limit: 80);
      final nonMeals = pool
          .where((row) => ['调料', '饮品', '甜品'].contains(row['cuisine']))
          .map((row) => '${row['dish_id']}')
          .toSet();
      expect(bundle.recipes, isNotEmpty);
      expect(bundle.recipes.every((recipe) => !nonMeals.contains(recipe.id)),
          isTrue);
      expect(bundle.recipes.every((recipe) => recipe.steps.isNotEmpty), isTrue);
      expect(
          await service.recommendRecipes(
              input: input, recallLabels: [], limit: 1),
          hasLength(1));
      expect(
          await service.recommendRecipes(
              input: input, recallLabels: [], limit: 5),
          hasLength(5));
    });

    test('真实SQLite 全库筛选保留酱牛肉啤酒鸭及水产，拒绝误分荤菜的番茄红酱', () async {
      final rows = await UnifiedRecipeDatabaseService.instance
          .fetchTopRecipes(limit: 500);
      final service = UnifiedRecommendationServiceV2(
        tagRecipeLoader: (_, __) async => rows,
        searchRecipeLoader: (_, __) async => rows,
        defaultRecipeLoader: (_) async => rows,
        tagScoreLoader: () async => const {},
        favoriteTagLoader: () async => const {},
        favoriteDishLoader: () async => const {},
        recentRecipeLoader: () async => const [],
      );
      final recipes = await service.recommendRecipes(
          input: input, recallLabels: [], limit: rows.length);
      final ids = recipes.map((recipe) => recipe.id).toSet();
      expect(ids, containsAll(['20', '111', '118', '183', '206']));
      expect(ids.intersection({'53', '78', '152', '203'}), isEmpty);
      final excluded =
          rows.where((row) => ['调料', '饮品', '甜品'].contains(row['cuisine']));
      expect(
          excluded.every((row) => !ids.contains('${row['dish_id']}')), isTrue);
    });

    for (final path in ['local', 'legacy', 'fusion', 'ai_error']) {
      test('$path 同一餐食边界且fallback不补回酱料酒类', () async {
        final service = V2Phase2RecommendationService(
          localRecommendationLoader: (_, __, ___) async =>
              [sauce, cocktail, meal],
          enableAiEnhancement: path != 'local',
          aiRecommendationLoader: path == 'legacy' || path == 'ai_error'
              ? ({required tags, required userProfile}) async {
                  if (path == 'ai_error') throw StateError('offline');
                  return [sauce, cocktail, meal];
                }
              : null,
          generationService: path == 'fusion'
              ? _FusionGenerationService([sauce, cocktail])
              : null,
          howToCookRecipeService: _emptyHowToCookService(),
        );
        final session = await service.startRecommendationSession(
            input: input, finalLimit: 5);
        for (final bundle in [session.local, await session.enhanced]) {
          expect(
              bundle.finalRecommendations.map((recipe) => recipe.id), ['meal']);
        }
      });
    }

    test('legacy不能把本地餐食ID伪装成饮品通过检查', () async {
      final bundle = await V2Phase2RecommendationService(
        localRecommendationLoader: (_, __, ___) async => [meal],
        aiRecommendationLoader: ({required tags, required userProfile}) async =>
            [
          cocktail.copyWith(id: meal.id),
        ],
        howToCookRecipeService: _emptyHowToCookService(),
      ).buildRecommendations(input: input);
      expect(bundle.finalRecommendations.single.name, meal.name);
      expect(bundle.fallbackReason, 'ai_constraints_rejected');
    });

    test('fusion回库匹配新增的真实饮品类别仍被拒绝', () async {
      final bundle = await V2Phase2RecommendationService(
        localRecommendationLoader: (_, __, ___) async => [meal],
        generationService: _FusionGenerationService([
          meal.copyWith(
              id: 'ai', name: '奇异果菠菜特调', tags: [], imageUrl: 'assets/test.jpg'),
        ]),
        howToCookRecipeService: _emptyHowToCookService(),
      ).buildRecommendations(input: input);
      expect(bundle.finalRecommendations.map((recipe) => recipe.id), ['meal']);
      expect(bundle.fallbackReason, 'ai_constraints_rejected');
    });

    test('富化将餐食换成饮品时拒绝并保留另一真实餐食', () async {
      final bundle = await V2Phase2RecommendationService(
        localRecommendationLoader: (_, __, ___) async =>
            [meal.copyWith(id: 'changed', name: '家常汤'), meal],
        enableAiEnhancement: false,
        howToCookRecipeService: _NonMealChangingHowToCookService(),
      ).buildRecommendations(input: input, finalLimit: 5);
      expect(bundle.finalRecommendations.map((recipe) => recipe.id), ['meal']);
      expect(bundle.aiSummary, contains('餐食'));
    });

    test('Phase2仅显式饮品允许非酒精饮品且不放行酒', () async {
      final tea = meal.copyWith(
          id: 'tea', name: '奶茶', tags: ['饮品'], ingredients: ['牛奶', '茶']);
      final bundle = await V2Phase2RecommendationService(
        localRecommendationLoader: (_, __, ___) async => [tea, cocktail, sauce],
        enableAiEnhancement: false,
        howToCookRecipeService: _emptyHowToCookService(),
      ).buildRecommendations(input: input.copyWith(likedTagLabels: ['饮品']));
      expect(bundle.finalRecommendations.map((recipe) => recipe.id), ['tea']);
    });
  });

  group('任务171', () {
    const safe = RecipeModel(
        id: 'safe',
        name: '清炒青菜',
        description: '',
        ingredients: ['青菜'],
        source: 'unified_db');
    final restricted = _input().copyWith(
      structuredConstraints: const TasteStructuredConstraints(
        dietaryRestrictions: ['花生'],
      ),
    );

    test('零输入默认首推加两备选且本地先返回，显式数量不变', () async {
      final pending = Completer<AiRefinedRecommendations>();
      final service = V2Phase2RecommendationService(
        localRecommendationLoader: (_, __, ___) async => [
          for (var id = 1; id <= 6; id++)
            safe.copyWith(id: '$id', name: '本地菜$id'),
        ],
        recommendationRefiner: (
                {required selectedTags,
                required candidates,
                required limit,
                required customRequirement}) =>
            pending.future,
        howToCookRecipeService: _emptyHowToCookService(),
      );
      final input = _input().copyWith(
          likedTagIds: [], likedTagLabels: [], freeformRequirement: '');
      final session = await service.startRecommendationSession(input: input);
      expect(pending.isCompleted, isFalse);
      pending.complete(
          const AiRefinedRecommendations(recipeIds: ['1'], reasonsById: {}));
      expect(session.local.finalRecommendations, hasLength(3));
      expect((await session.enhanced).finalRecommendations, hasLength(3));
      expect(
          (await service.buildRecommendations(
                  input: input, skipAiEnhancement: true))
              .finalRecommendations,
          hasLength(3));
      expect(
          (await service.buildRecommendations(input: input, finalLimit: 5))
              .finalRecommendations,
          hasLength(5));
    });

    test('随包素食排除午餐肉而不信素食友好标签', () async {
      final result = await V2Phase2RecommendationService(
        enableAiEnhancement: false,
        howToCookRecipeService: _emptyHowToCookService(),
      ).buildRecommendations(
          input: _input().copyWith(
        likedTagLabels: ['家常菜'],
        freeformRequirement: '今天吃素食，不要肉',
        structuredConstraints:
            const TasteStructuredConstraints(dietaryRestrictions: ['素食']),
      ));
      expect(result.finalRecommendations, isNotEmpty);
      expect(result.finalRecommendations.expand((recipe) => recipe.ingredients),
          everyElement(isNot(contains('午餐肉'))));
    });

    test('本地候选全部被忌口排除时说明原因而非声称未命中', () async {
      final service = V2Phase2RecommendationService(
        enableAiEnhancement: false,
        localRecommendationLoader: (_, __, ___) async => [
          safe.copyWith(ingredients: ['花生']),
        ],
        howToCookRecipeService: _emptyHowToCookService(),
      );
      final result = await service.buildRecommendations(input: restricted);
      expect(result.finalRecommendations, isEmpty);
      expect(result.fallbackReason, 'candidate_constraints_rejected');
      expect(result.aiSummary, contains('忌口'));
    });

    for (final hasRows in [true, false]) {
      test('正式 Unified 已过滤空包保留原因（有召回=$hasRows）', () async {
        final rows = <Map<String, dynamic>>[
          if (hasRows)
            {
              ..._unifiedRow(),
              'ingredients': const [
                {'name': '花生油'}
              ],
            },
        ];
        var defaultCalled = false;
        var refinerCalled = false;
        final unified = UnifiedRecommendationServiceV2(
          tagCatalogService:
              V2TagCatalogService(dbTagLoader: () async => const []),
          tagRecipeLoader: (_, __) async => rows,
          searchRecipeLoader: (_, __) async => rows,
          defaultRecipeLoader: (_) async {
            defaultCalled = true;
            return rows;
          },
          tagScoreLoader: () async => const {},
          favoriteTagLoader: () async => const {},
          favoriteDishLoader: () async => const {},
          recentRecipeLoader: () async => const [],
        );
        final service = V2Phase2RecommendationService(
          recommendationService: unified,
          recommendationRefiner: ({
            required selectedTags,
            required candidates,
            required limit,
            required customRequirement,
          }) async {
            refinerCalled = true;
            return const AiRefinedRecommendations(
                recipeIds: [], reasonsById: {});
          },
          howToCookRecipeService: _emptyHowToCookService(),
        );
        final session =
            await service.startRecommendationSession(input: restricted);
        expect(defaultCalled, isTrue);
        for (final result in [session.local, await session.enhanced]) {
          expect(result.finalRecommendations, isEmpty);
          expect(result.resolutionStatus, RecommendationResolutionStatus.empty);
          expect(result.primarySource, 'unified_db');
          expect(result.fallbackReason,
              hasRows ? 'candidate_constraints_rejected' : 'local_empty');
          expect(result.aiSummary, contains('HowToCook'));
          expect(result.aiSummary, contains(hasRows ? '忌口过滤' : '没有命中'));
        }
        expect(refinerCalled, isFalse);
      });
    }

    test('legacy AI 不能用安全菜名掩盖忌口食材', () async {
      final service = V2Phase2RecommendationService(
        localRecommendationLoader: (_, __, ___) async => [safe],
        aiRecommendationLoader: ({required tags, required userProfile}) async =>
            [
          safe.copyWith(ingredients: ['花生油'], description: '放心吃'),
        ],
        howToCookRecipeService: _emptyHowToCookService(),
      );
      final result = await service.buildRecommendations(input: restricted);
      expect(result.finalRecommendations.single.ingredients, ['青菜']);
      expect(result.fallbackReason, 'ai_constraints_rejected');
      expect(result.aiSummary, contains('忌口'));
      expect(result.aiReasonsByRecipeId.values, isNot(contains('放心吃')));
    });

    for (final ingredients in <List<String>>[
      ['花生'],
      []
    ]) {
      test('fusion 食材 $ingredients 不能绕过明确忌口', () async {
        final service = V2Phase2RecommendationService(
          localRecommendationLoader: (_, __, ___) async => [safe],
          generationService: _FusionGenerationService([
            RecipeModel(
                id: 'ai',
                name: '星云特制料理',
                description: '放心吃',
                ingredients: ingredients,
                imageUrl: 'assets/test.jpg',
                source: 'ai_fusion'),
          ]),
          howToCookRecipeService: _emptyHowToCookService(),
        );
        final result = await service.buildRecommendations(input: restricted);
        expect(
            result.finalRecommendations.map((recipe) => recipe.id), ['safe']);
        expect(result.fallbackReason, 'ai_constraints_rejected');
        expect(result.aiSummary, contains(ingredients.isEmpty ? '食材缺失' : '忌口'));
        expect(result.aiSummary, isNot(contains('放心吃')));
      });
    }

    test('fusion 匹配回库后仍过滤真实配方中的忌口', () async {
      final rows = await UnifiedRecipeDatabaseService.instance
          .searchRecipes('宫保鸡丁', limit: 3);
      final row = rows.firstWhere((row) => (row['ingredients'] as List)
          .any((item) => (item['name'] as String).contains('花生')));
      final service = V2Phase2RecommendationService(
        localRecommendationLoader: (_, __, ___) async => [safe],
        generationService: _FusionGenerationService([
          RecipeModel(
              id: 'ai',
              name: row['dish_name'] as String,
              description: '融合创意',
              ingredients: ['豆腐'],
              imageUrl: 'assets/test.jpg'),
        ]),
        howToCookRecipeService: _emptyHowToCookService(),
      );
      final result = await service.buildRecommendations(input: restricted);
      expect(result.finalRecommendations.map((recipe) => recipe.id), ['safe']);
      expect(result.fallbackReason, 'ai_constraints_rejected');
      expect(result.aiSummary, contains('忌口'));
    });

    test('fusion 部分拒绝仍保留合适创意并补安全本地候选', () async {
      final service = V2Phase2RecommendationService(
        localRecommendationLoader: (_, __, ___) async => [safe],
        generationService: _FusionGenerationService([
          safe.copyWith(id: 'bad', name: '星云花生料理', ingredients: ['花生']),
          safe.copyWith(
              id: 'good', name: '星云青菜料理', imageUrl: 'assets/test.jpg'),
        ]),
        howToCookRecipeService: _emptyHowToCookService(),
      );
      final result = await service.buildRecommendations(input: restricted);
      expect(result.finalRecommendations.map((recipe) => recipe.id),
          ['good', 'safe']);
      expect(result.fallbackReason, 'ai_constraints_rejected');
      expect(result.aiSummary, contains('忌口'));
    });

    for (final keepFusion in [false, true]) {
      test('fusion 富化拒绝后按存活来源重算（部分存活=$keepFusion）', () async {
        final service = V2Phase2RecommendationService(
          localRecommendationLoader: (_, __, ___) async => [safe],
          generationService: _FusionGenerationService([
            safe.copyWith(
              id: 'changed',
              name: '星云特制饭',
              description: '被拒创意理由',
              imageUrl: 'assets/test.jpg',
              source: 'ai_fusion',
            ),
            if (keepFusion)
              safe.copyWith(
                id: 'retained',
                name: '星云时蔬饭',
                description: '青菜搭配',
                imageUrl: 'assets/test.jpg',
                source: 'ai_fusion',
              ),
          ]),
          howToCookRecipeService: _IngredientChangingHowToCookService(),
        );
        final session =
            await service.startRecommendationSession(input: restricted);
        expect(session.local.resolutionStatus,
            RecommendationResolutionStatus.dbResolved);
        final result = await session.enhanced;
        expect(result.finalRecommendations.map((recipe) => recipe.id),
            keepFusion ? ['retained', 'safe'] : ['safe']);
        expect(
            result.resolutionStatus,
            keepFusion
                ? RecommendationResolutionStatus.hybridResolved
                : RecommendationResolutionStatus.localFallback);
        expect(result.primarySource, keepFusion ? 'hybrid' : 'local_fallback');
        expect(result.fallbackReason, 'ai_constraints_rejected');
        expect(result.aiSummary, isNot(contains('星云特制饭')));
        expect(result.aiSummary, contains('忌口'));
        expect(result.aiReasonsByRecipeId.keys, isNot(contains('changed')));
        expect(result.aiReasonsByRecipeId.values.join(),
            isNot(contains('被拒创意理由')));
        if (keepFusion) {
          expect(result.aiSummary, contains('星云时蔬饭'));
        } else {
          expect(result.isEstimated, isTrue);
          expect(result.aiReasonsByRecipeId['safe'], contains('本地菜谱'));
        }
      });
    }

    test('refine 富化部分拒绝仍保留本地排序贡献但不保留拒菜文案', () async {
      final service = V2Phase2RecommendationService(
        localRecommendationLoader: (_, __, ___) async => [
          safe.copyWith(id: 'changed', name: '家常拌饭'),
          safe,
        ],
        recommendationRefiner: ({
          required selectedTags,
          required candidates,
          required limit,
          required customRequirement,
        }) async =>
            const AiRefinedRecommendations(
          recipeIds: ['safe', 'changed'],
          reasonsById: {'safe': '和家常拌饭一起享用。'},
          summary: '首选清炒青菜，搭配家常拌饭。',
        ),
        howToCookRecipeService: _IngredientChangingHowToCookService(),
      );
      final result = await service.buildRecommendations(input: restricted);
      expect(result.finalRecommendations.single.id, 'safe');
      expect(result.resolutionStatus,
          RecommendationResolutionStatus.hybridResolved);
      expect(result.primarySource, 'hybrid');
      expect(result.aiSummary, isNot(contains('家常拌饭')));
      expect(result.aiReasonsByRecipeId['safe'], isNot(contains('家常拌饭')));
    });

    test('富化替换食材后再次筛选并补足安全本地候选', () async {
      final service = V2Phase2RecommendationService(
        enableAiEnhancement: false,
        localRecommendationLoader: (_, __, ___) async => [
          safe.copyWith(id: 'changed', name: '家常拌饭'),
          safe,
        ],
        howToCookRecipeService: _IngredientChangingHowToCookService(),
      );
      final result =
          await service.buildRecommendations(input: restricted, finalLimit: 1);
      expect(result.finalRecommendations.map((recipe) => recipe.id), ['safe']);
      expect(result.aiSummary, contains('忌口'));
    });

    test('结构化忌口在本地 loader 入口同样生效且不解释未知标签', () async {
      final service = V2Phase2RecommendationService(
        enableAiEnhancement: false,
        localRecommendationLoader: (_, __, ___) async => [
          safe.copyWith(id: 'bad', name: '凉拌菜', ingredients: ['花生油']),
          safe,
        ],
        howToCookRecipeService: _emptyHowToCookService(),
      );
      expect(
          (await service.buildRecommendations(input: restricted))
              .finalRecommendations
              .map((recipe) => recipe.id),
          ['safe']);
      expect(
          (await service.buildRecommendations(
                  input: _input().copyWith(
            structuredConstraints:
                const TasteStructuredConstraints(dietaryRestrictions: ['星际轻盈']),
          )))
              .finalRecommendations,
          hasLength(2));
    });

    for (final structured in [true, false]) {
      test('预算但无时限（structured=$structured）不转述 AI 已核价断言', () async {
        final service = V2Phase2RecommendationService(
          localRecommendationLoader: (_, __, ___) async => [safe],
          recommendationRefiner: ({
            required selectedTags,
            required candidates,
            required limit,
            required customRequirement,
          }) async =>
              const AiRefinedRecommendations(
            recipeIds: ['safe'],
            reasonsById: {'safe': '青菜为主，已核实30元内。'},
            summary: '清炒青菜已核实30元内，真实采购价格已确认。',
          ),
          howToCookRecipeService: _emptyHowToCookService(),
        );
        final result = await service.buildRecommendations(
          input: _input().copyWith(
            freeformRequirement: structured ? '' : '30元内',
            structuredConstraints: TasteStructuredConstraints(
              maxBudgetYuan: structured ? 30 : null,
            ),
          ),
        );
        expect(result.resolutionStatus,
            RecommendationResolutionStatus.hybridResolved);
        for (final text in [
          result.aiSummary!,
          result.aiReasonsByRecipeId['safe']!
        ]) {
          expect(text, isNot(contains('已核实')));
          expect(text, isNot(contains('价格已确认')));
          expect(text, contains('预算为估算，以实际采购/平台价格为准'));
        }
        expect(result.aiReasonsByRecipeId['safe'], contains('本地菜谱'));
      });
    }

    test('AI 耗时缺失明确未核验而不是宣称满足时限', () async {
      final service = V2Phase2RecommendationService(
        localRecommendationLoader: (_, __, ___) async => [safe],
        generationService: _FusionGenerationService([
          safe.copyWith(id: 'ai', name: '星云时蔬饭', imageUrl: 'assets/test.jpg'),
        ]),
        howToCookRecipeService: _emptyHowToCookService(),
      );
      final result = await service.buildRecommendations(
          input: _input().copyWith(
        structuredConstraints:
            const TasteStructuredConstraints(maxTimeMinutes: 15),
      ));
      expect(result.aiReasonsByRecipeId['ai'], contains('耗时未核验'));
      expect(result.aiSummary, contains('耗时未核验'));
    });
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

    // 精排收到的食物标签只用于菜品匹配；时间/预算/人数在硬性约束里。
    expect(capturedTags, containsAll(['家常', '高蛋白']));
    expect(capturedTags, isNot(contains('15 分钟内')));
    expect(capturedTags, isNot(contains('30 元内')));
    expect(capturedTags, isNot(contains('1 人')));
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

  test('本地召回过滤占位菜名但不硬排除 skip', () async {
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

    expect(result.finalRecommendations.map((item) => item.id),
        ['blocked', 'real']);
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

  test('取消推荐会话后不采用迟到的 AI 结果并返回本地包', () async {
    final refiner = Completer<AiRefinedRecommendations>();
    final service = V2Phase2RecommendationService(
      localRecommendationLoader: (_, __, ___) async => const [
        RecipeModel(
          id: 'local_1',
          name: '番茄炒蛋',
          description: '稳定的本地候选。',
          source: 'unified_db',
        ),
      ],
      recommendationRefiner: ({
        required selectedTags,
        required candidates,
        required limit,
        required customRequirement,
      }) =>
          refiner.future,
      howToCookRecipeService: _emptyHowToCookService(),
    );
    final session = await service.startRecommendationSession(input: _input());

    session.cancel();
    refiner.complete(
      const AiRefinedRecommendations(
        recipeIds: ['local_1'],
        reasonsById: {'local_1': '迟到的 AI 理由'},
        summary: '迟到的 AI 结果',
      ),
    );
    final enhanced = await session.enhanced;

    expect(session.isCancelled, isTrue);
    expect(enhanced.aiSummary, session.local.aiSummary);
    expect(enhanced.resolutionStatus, session.local.resolutionStatus);
    expect(
      enhanced.aiReasonsByRecipeId.values,
      isNot(contains('迟到的 AI 理由')),
    );
  });

  test('取消推荐会话后不等待未完成的增强 Future', () async {
    final refiner = Completer<AiRefinedRecommendations>();
    addTearDown(() {
      if (!refiner.isCompleted) {
        refiner.complete(
          const AiRefinedRecommendations(
            recipeIds: ['local_1'],
            reasonsById: {},
          ),
        );
      }
    });
    final service = V2Phase2RecommendationService(
      localRecommendationLoader: (_, __, ___) async => const [
        RecipeModel(
          id: 'local_1',
          name: '番茄炒蛋',
          description: '稳定的本地候选。',
          source: 'unified_db',
        ),
      ],
      recommendationRefiner: ({
        required selectedTags,
        required candidates,
        required limit,
        required customRequirement,
      }) =>
          refiner.future,
      howToCookRecipeService: _emptyHowToCookService(),
    );
    final session = await service.startRecommendationSession(input: _input());

    session.cancel();

    final enhanced = await session.enhanced.timeout(
      const Duration(milliseconds: 100),
    );
    expect(enhanced.aiSummary, session.local.aiSummary);
    expect(enhanced.resolutionStatus, session.local.resolutionStatus);
  });

  test('取消推荐会话后不等待文本返回后的生图 Future', () async {
    final generation = _PendingImageGenerationService();
    addTearDown(() {
      if (!generation.image.isCompleted) generation.image.complete(null);
    });
    final service = V2Phase2RecommendationService(
      generationService: generation,
      localRecommendationLoader: (_, __, ___) async => const [
        RecipeModel(
          id: 'local_1',
          name: '番茄炒蛋',
          description: '稳定的本地候选。',
          source: 'unified_db',
        ),
      ],
      howToCookRecipeService: _emptyHowToCookService(),
    );
    final session = await service.startRecommendationSession(input: _input());
    await generation.imageStarted.future.timeout(const Duration(seconds: 1));

    session.cancel();

    final enhanced = await session.enhanced.timeout(
      const Duration(milliseconds: 100),
    );
    expect(enhanced.aiSummary, session.local.aiSummary);
    expect(enhanced.resolutionStatus, session.local.resolutionStatus);
    expect(generation.imageCancelToken?.isCancelled, isTrue);
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

  test('执行方式、位置、时间和人数不进入食物召回标签', () async {
    final captured = <String>[];
    final service = V2Phase2RecommendationService(
      enableAiEnhancement: false,
      localRecommendationLoader: (input, selectedTagLabels, limit) async {
        captured.addAll(selectedTagLabels);
        return const [
          RecipeModel(
            id: 'local_1',
            name: '番茄豆腐面',
            description: '家常快手。',
            ingredients: ['番茄', '豆腐', '面条'],
            tags: ['主食'],
          ),
        ];
      },
      howToCookRecipeService: _emptyHowToCookService(),
    );

    await service.buildRecommendations(
      input: const TasteInferenceInput(
        likedTagIds: ['f_light'],
        likedTagLabels: ['清淡'],
        dislikedTagIds: [],
        dislikedTagLabels: [],
        skippedTagIds: [],
        skippedTagLabels: [],
        freeformRequirement: '',
        historyPreferenceSummary: {},
        structuredConstraints: TasteStructuredConstraints(
          maxTimeMinutes: 15,
          partySize: 2,
          dietaryRestrictions: ['素食'],
          executionPreference: TasteExecutionPreference.cook,
          locationPreference: TasteLocationPreference.nearby,
        ),
      ),
    );

    expect(captured, contains('清淡'));
    expect(captured, contains('素食'));
    for (final nonFood in ['在家做', '叫外卖', '去店里', '附近', '15 分钟内', '2 人']) {
      expect(captured, isNot(contains(nonFood)), reason: nonFood);
    }
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

class _FusionGenerationService extends Fake implements GenerationService {
  _FusionGenerationService(this.recipes);
  final List<RecipeModel> recipes;

  @override
  bool get isConfigured => true;

  @override
  Future<List<RecipeModel>> generateFusionDishes({
    required List<String> tags,
    String? customRequirement,
    int count = 4,
    CancelToken? cancelToken,
  }) async =>
      recipes;

  @override
  Future<String?> generateRecipeImageUrl(RecipeModel recipe,
          {CancelToken? cancelToken}) async =>
      null;
}

class _NonMealChangingHowToCookService extends V2HowToCookRecipeService {
  @override
  Future<RecipeModel> enrichRecipe(RecipeModel recipe) async =>
      recipe.id == 'changed'
          ? recipe.copyWith(name: '新特调', tags: ['饮品'])
          : recipe;
}

class _IngredientChangingHowToCookService extends V2HowToCookRecipeService {
  @override
  Future<RecipeModel> enrichRecipe(RecipeModel recipe) async =>
      recipe.id == 'changed' ? recipe.copyWith(ingredients: ['花生油']) : recipe;
}

class _PendingImageGenerationService extends Fake implements GenerationService {
  final imageStarted = Completer<void>();
  final image = Completer<String?>();
  CancelToken? imageCancelToken;

  @override
  bool get isConfigured => true;

  @override
  Future<List<RecipeModel>> generateFusionDishes({
    required List<String> tags,
    String? customRequirement,
    int count = 4,
    CancelToken? cancelToken,
  }) async {
    return const [
      RecipeModel(
        id: 'ai_fusion_review',
        name: '云端量子料理',
        description: '融合创意。',
        source: 'ai_fusion',
      ),
    ];
  }

  @override
  Future<String?> generateRecipeImageUrl(
    RecipeModel recipe, {
    CancelToken? cancelToken,
  }) {
    imageCancelToken = cancelToken;
    if (!imageStarted.isCompleted) imageStarted.complete();
    return image.future;
  }
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
