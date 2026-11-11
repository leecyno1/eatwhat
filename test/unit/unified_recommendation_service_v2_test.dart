import 'package:eatwhat_app/v2/core/data/models/meal_planning_direction.dart';
import 'package:eatwhat_app/v2/core/data/models/taste_inference_input.dart';
import 'package:eatwhat_app/v2/core/data/models/taste_selection_models.dart';
import 'package:eatwhat_app/v2/core/data/schema/unified_tag_model.dart';
import 'package:eatwhat_app/v2/core/services/unified_recommendation_service_v2.dart';
import 'package:eatwhat_app/v2/core/services/v2_recommendation_canary_service.dart';
import 'package:eatwhat_app/v2/core/services/v2_recommendation_shadow_scoring_service.dart';
import 'package:eatwhat_app/v2/core/services/v2_tag_catalog_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('UnifiedRecommendationServiceV2', () {
    group('餐食候选边界', () {
      test('仅非餐或占位的直召回会进入默认池，默认池再次过滤且不凑数', () async {
        var defaultCalls = 0;
        final service = UnifiedRecommendationServiceV2(
          tagCatalogService: _StaticCatalogService(const []),
          tagRecipeLoader: (_, __) async => const [],
          searchRecipeLoader: (_, __) async => [
            {
              ..._row(
                  dishId: 1, recipeId: 1, name: '新酱料配方', tags: ['主食', '夜宵']),
              'cuisine': '调料',
            },
            _row(dishId: 2, recipeId: 2, name: 'soup_example', tags: ['汤羹']),
          ],
          defaultRecipeLoader: (_) async {
            defaultCalls++;
            return [
              _row(dishId: 3, recipeId: 3, name: 'B52轰炸机', tags: ['饮品']),
              _row(dishId: 4, recipeId: 4, name: '番茄红酱', tags: ['荤菜']),
              _row(dishId: 5, recipeId: 5, name: '酱牛肉', tags: ['荤菜', '调味蘸料']),
            ];
          },
          tagScoreLoader: () async => const {},
          favoriteTagLoader: () async => const {},
          favoriteDishLoader: () async => const {},
          recentRecipeLoader: () async => const [],
        );
        final bundle = await service.buildRecommendationBundle(
          input: _input().copyWith(likedTagLabels: []),
          recallLabels: [],
          limit: 5,
        );
        expect(defaultCalls, 1);
        expect(bundle.recipes.map((recipe) => recipe.id), ['5']);
        expect(bundle.summary, contains('餐食'));
      });

      test('直召回和默认池都是非餐时返回可解释空包', () async {
        final bundle = await _serviceWithRows([
          _row(dishId: 1, recipeId: 1, name: '炸串酱料', tags: ['调料']),
        ]).buildRecommendationBundle(input: _input(), recallLabels: []);
        expect(bundle.recipes, isEmpty);
        expect(bundle.fallbackReason, 'candidate_constraints_rejected');
        expect(bundle.summary, contains('餐食'));
      });

      test('显式甜品饮品标签才开放对应种类，召回标签不代表用户授权', () async {
        final service = _serviceWithRows([
          _row(dishId: 1, recipeId: 1, name: '提拉米苏', tags: ['甜品']),
          _row(dishId: 2, recipeId: 2, name: '奶茶', tags: ['饮品']),
          _row(dishId: 3, recipeId: 3, name: 'B52轰炸机', tags: ['饮品']),
        ]);
        for (final (labels, expected) in <(List<String>, List<String>)>[
          ([], []),
          (['甜品'], ['1']),
          (['饮品'], ['2']),
        ]) {
          final bundle = await service.buildRecommendationBundle(
            input: _input().copyWith(likedTagLabels: labels),
            recallLabels: ['甜品', '饮品'],
            limit: 5,
          );
          expect(bundle.recipes.map((recipe) => recipe.id), expected);
        }
      });
    });

    group('任务171', () {
      test('skip 不排除候选也不推导时间或忌口约束', () async {
        final bundle = await _serviceWithRows([
          _row(
              dishId: 1,
              recipeId: 1,
              name: '虾仁蒸蛋',
              tags: ['聚会'],
              ingredients: ['虾仁', '鸡蛋']),
        ]).buildRecommendationBundle(
          input: _input().copyWith(
            skippedTagLabels: ['聚会', '海鲜过敏', '素食', '15分钟'],
          ),
          recallLabels: const [],
        );
        expect(bundle.recipes.map((recipe) => recipe.id), ['1']);
      });

      for (final entry in <String, String>{
        '海鲜': '蚝油',
        '坚果': '腰果',
        '花生': '花生油',
        '奶': '芝士',
        '鸡蛋': '蛋黄',
        '猪肉': '培根',
        '素食': '鸡腿',
        '纯素': '牛奶',
      }.entries) {
        test('structured ${entry.key} 排除常见同义食材', () async {
          final bundle = await _serviceWithRows([
            _row(
                dishId: 1,
                recipeId: 1,
                name: '创意炒饭',
                tags: [],
                ingredients: [entry.value]),
            _row(
                dishId: 2,
                recipeId: 2,
                name: '清炒青菜',
                tags: [],
                ingredients: ['青菜']),
          ]).buildRecommendationBundle(
            input: _input().copyWith(
              structuredConstraints: TasteStructuredConstraints(
                dietaryRestrictions: [entry.key],
              ),
            ),
            recallLabels: const [],
          );
          expect(bundle.recipes.map((recipe) => recipe.id), ['2']);
          expect(bundle.summary, contains('忌口'));
        });
      }

      test('普通素食允许蛋奶和非肉类同字食材', () async {
        final bundle = await _serviceWithRows([
          _row(
              dishId: 1,
              recipeId: 1,
              name: '牛奶蒸鸡蛋',
              tags: [],
              ingredients: ['鸡蛋', '牛奶']),
          _row(
              dishId: 2,
              recipeId: 2,
              name: '菌菇炒饭',
              tags: [],
              ingredients: ['鸡腿菇', '牛肝菌', '羊肚菌']),
        ]).buildRecommendationBundle(
          input: _input().copyWith(
            structuredConstraints: const TasteStructuredConstraints(
              dietaryRestrictions: ['素食'],
            ),
          ),
          recallLabels: const [],
        );
        expect(bundle.recipes, hasLength(2));
      });

      test('正向喜欢素食不成为硬性禁肉', () async {
        final bundle = await _serviceWithRows([
          _row(dishId: 1, recipeId: 1, name: '鸡腿饭', tags: []),
        ]).buildRecommendationBundle(
          input: _input().copyWith(likedTagLabels: ['素食']),
          recallLabels: const [],
        );
        expect(bundle.recipes, hasLength(1));
      });

      test('自由文本不要不吃常见项但保留正向喜欢', () async {
        final bundle = await _serviceWithRows([
          _row(
              dishId: 1,
              recipeId: 1,
              name: '蒸蛋',
              tags: [],
              ingredients: ['鸡蛋']),
          _row(
              dishId: 2,
              recipeId: 2,
              name: '花生拌菜',
              tags: [],
              ingredients: ['花生']),
          _row(
              dishId: 3,
              recipeId: 3,
              name: '牛奶燕麦',
              tags: [],
              ingredients: ['牛奶', '燕麦']),
        ]).buildRecommendationBundle(
          input: _input().copyWith(
            freeformRequirement: '不吃花生、鸡蛋，喜欢牛奶',
          ),
          recallLabels: const [],
        );
        expect(bundle.recipes.map((recipe) => recipe.id), ['3']);
      });

      test('未知限制按字面排除并回默认池，dislike 行为保持一致', () async {
        final service = UnifiedRecommendationServiceV2(
          tagCatalogService: _StaticCatalogService(const []),
          tagRecipeLoader: (_, __) async => const [],
          searchRecipeLoader: (_, __) async => [
            _row(dishId: 1, recipeId: 1, name: '家常饭', tags: ['星际轻盈']),
          ],
          defaultRecipeLoader: (_) async => [
            _row(dishId: 2, recipeId: 2, name: '备用饭', tags: []),
          ],
          tagScoreLoader: () async => const {},
          favoriteTagLoader: () async => const {},
          favoriteDishLoader: () async => const {},
          recentRecipeLoader: () async => const [],
        );
        final input = _input().copyWith(
          structuredConstraints: const TasteStructuredConstraints(
            dietaryRestrictions: ['星际轻盈'],
          ),
        );
        final unknown = await service.buildRecommendationBundle(
          input: input,
          recallLabels: const [],
        );
        expect(unknown.recipes.single.id, '2');
        final disliked = await service.buildRecommendationBundle(
          input: input.copyWith(dislikedTagLabels: ['星际轻盈']),
          recallLabels: const [],
        );
        expect(disliked.recipes.single.id, '2');
        expect(disliked.summary, contains('过滤'));
      });

      test('耗时缺失允许保留但明确未核验而非满足时限', () async {
        final bundle = await _serviceWithRows([
          {
            ..._row(dishId: 1, recipeId: 1, name: '家常饭', tags: []),
            'total_time_minutes': null
          },
          _row(
              dishId: 2,
              recipeId: 2,
              name: '慢炖锅',
              tags: [],
              totalTimeMinutes: 60),
        ]).buildRecommendationBundle(
          input: _input().copyWith(
            structuredConstraints: const TasteStructuredConstraints(
              maxTimeMinutes: 15,
            ),
          ),
          recallLabels: const [],
        );
        expect(bundle.recipes.single.id, '1');
        expect(bundle.reasonsByRecipeId['1'], contains('耗时未核验'));
        expect(bundle.reasonsByRecipeId['1'], isNot(contains('分钟内可完成')));
      });

      test('食材列表超过展示上限也不能隐藏忌口', () async {
        final result = await _serviceWithRows([
          _row(
              dishId: 1,
              recipeId: 1,
              name: '杂蔬饭',
              tags: [],
              ingredients: [...List.filled(10, '青菜'), '花生']),
          _row(
              dishId: 2,
              recipeId: 2,
              name: '青菜饭',
              tags: [],
              ingredients: ['青菜']),
        ]).recommendRecipes(
          input: _input().copyWith(
              structuredConstraints: const TasteStructuredConstraints(
                  dietaryRestrictions: ['花生'])),
          recallLabels: [],
        );
        expect(result.map((recipe) => recipe.id), ['2']);
      });

      for (final hasRows in [true, false]) {
        test('空包区分约束拒绝与未召回（有召回=$hasRows）', () async {
          final bundle = await _serviceWithRows([
            if (hasRows)
              _row(
                  dishId: 1,
                  recipeId: 1,
                  name: '拌饭',
                  tags: [],
                  ingredients: ['花生油']),
          ]).buildRecommendationBundle(
            input: _input().copyWith(
              structuredConstraints: const TasteStructuredConstraints(
                dietaryRestrictions: ['花生'],
              ),
            ),
            recallLabels: [],
          );
          expect(bundle.recipes, isEmpty);
          expect(bundle.fallbackReason,
              hasRows ? 'candidate_constraints_rejected' : 'local_empty');
          expect(bundle.summary, contains(hasRows ? '忌口过滤' : '没有命中'));
        });
      }

      test('预算解释仍是估算而非真实报价', () async {
        final result = await _serviceWithRows([
          _row(
              dishId: 1,
              recipeId: 1,
              name: '青菜豆腐汤',
              tags: [],
              ingredients: ['豆腐']),
        ]).buildRecommendationBundle(
          input: _input().copyWith(
              structuredConstraints:
                  const TasteStructuredConstraints(maxBudgetYuan: 30)),
          recallLabels: [],
        );
        expect(result.reasonsByRecipeId['1'], contains('估算'));
      });

      test('零输入从默认池返回三候选且显式 limit 保留', () async {
        final service = UnifiedRecommendationServiceV2(
          tagCatalogService: _StaticCatalogService(const []),
          tagRecipeLoader: (_, __) async => const [],
          searchRecipeLoader: (_, __) async => const [],
          defaultRecipeLoader: (_) async => [
            for (var id = 1; id <= 6; id++)
              _row(dishId: id, recipeId: id, name: '本地菜$id', tags: []),
          ],
          tagScoreLoader: () async => const {},
          favoriteTagLoader: () async => const {},
          favoriteDishLoader: () async => const {},
          recentRecipeLoader: () async => const [],
        );
        final input = _input().copyWith(likedTagLabels: []);
        expect(await service.recommendRecipes(input: input, recallLabels: []),
            hasLength(3));
        expect(
            await service.recommendRecipes(
                input: input, recallLabels: [], limit: 5),
            hasLength(5));
      });
    });

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

    test('单个 FTS 查询异常不会丢弃已召回的标签候选', () async {
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
        tagRecipeLoader: (_, __) async => [
          _row(
            dishId: 101,
            recipeId: 201,
            name: '黄焖鸡',
            tags: const ['荤菜', '家常菜'],
          ),
        ],
        searchRecipeLoader: (_, __) async => throw StateError('fts failed'),
        defaultRecipeLoader: (_) async => throw StateError(
          '标签候选存在时不应进入默认池',
        ),
        tagScoreLoader: () async => const {},
        favoriteTagLoader: () async => const {},
        favoriteDishLoader: () async => const {},
        recentRecipeLoader: () async => const [],
      );

      final recipes = await service.recommendRecipes(
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

      expect(recipes.map((recipe) => recipe.name), ['黄焖鸡']);
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

    test('影子排序即使完全反转也不会改变正式推荐及候选身份', () async {
      final summaries = <V2RecommendationShadowSummary>[];
      final rows = [
        _row(
          dishId: 101,
          recipeId: 201,
          name: '正式第一名',
          tags: const ['家常菜', '快手'],
          popularity: 90,
          rating: 4.9,
        ),
        _row(
          dishId: 102,
          recipeId: 202,
          name: '正式第二名',
          tags: const ['素菜', '清爽'],
          popularity: 60,
        ),
        _row(
          dishId: 103,
          recipeId: 203,
          name: '正式第三名',
          tags: const ['汤羹', '暖胃'],
          popularity: 20,
          rating: 4.0,
        ),
        _row(
          dishId: 104,
          recipeId: 204,
          name: '高分海鲜候选',
          tags: const ['海鲜'],
          ingredients: const ['虾仁'],
          popularity: 100,
          rating: 5.0,
        ),
      ];
      final service = _serviceWithRows(
        rows,
        shadowScoringService: V2RecommendationShadowScoringService(
          experimentalScorer: (candidate) => candidate.baselinePosition * 1.0,
          reporter: summaries.add,
        ),
      );

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

      expect(bundle.recipes.map((recipe) => recipe.id), ['101', '102', '103']);
      expect(bundle.recipes.map((recipe) => recipe.name), [
        '正式第一名',
        '正式第二名',
        '正式第三名',
      ]);
      expect(summaries, hasLength(1));
      expect(summaries.single.recallPath, V2RecommendationRecallPath.direct);
      expect(summaries.single.top1Changed, isTrue);
      expect(summaries.single.candidateCount, 3);
    });

    test('影子评分器或报告器异常都不会中断正式推荐', () async {
      final failingServices = [
        V2RecommendationShadowScoringService(
          experimentalScorer: (_) => throw StateError('scorer failed'),
          reporter: (_) {},
        ),
        V2RecommendationShadowScoringService(
          experimentalScorer: (candidate) => candidate.baselineScore,
          reporter: (_) => throw StateError('reporter failed'),
        ),
      ];

      for (final shadowService in failingServices) {
        final service = _serviceWithRows(
          [
            _row(
              dishId: 101,
              recipeId: 201,
              name: '稳定候选',
              tags: const ['家常菜'],
            ),
          ],
          shadowScoringService: shadowService,
        );

        final bundle = await service.buildRecommendationBundle(
          input: _input(),
          recallLabels: const ['家常菜'],
        );

        expect(bundle.recipes.map((recipe) => recipe.id), ['101']);
      }
    });

    test('灰度默认关闭或未命中时保持生产顺序和版本', () async {
      for (final decision in [
        const RecommendationCanaryDecision(
          useExperiment: false,
          rankingVersion: 'local_rank_v2',
          algorithmVersion: 'hybrid_v3_0',
        ),
        const RecommendationCanaryDecision(
          useExperiment: false,
          rankingVersion: 'local_rank_v2',
          algorithmVersion: 'hybrid_v3_0',
        ),
      ]) {
        final bundle = await _serviceWithRows(
          _canaryRows(),
          canaryDecisionLoader: () async => decision,
          experimentalRanker: V2RecommendationExperimentalRanker(
            scorer: (candidate) => candidate.baselinePosition * 1.0,
          ),
        ).buildRecommendationBundle(
          input: _input(),
          recallLabels: const ['家常菜'],
        );

        expect(
            bundle.recipes.map((recipe) => recipe.id), ['101', '102', '103']);
        expect(bundle.rankingVersion, 'local_rank_v2');
        expect(bundle.algorithmVersion, 'hybrid_v3_0');
      }
    });

    test('灰度命中才服务实验顺序并携带独立算法版本', () async {
      final bundle = await _serviceWithRows(
        _canaryRows(),
        canaryDecisionLoader: () async => const RecommendationCanaryDecision(
          useExperiment: true,
          rankingVersion: 'local_rank_v3_quality_shadow',
          algorithmVersion: 'hybrid_v3_0_rank_v3_canary',
        ),
        experimentalRanker: V2RecommendationExperimentalRanker(
          scorer: (candidate) => candidate.baselinePosition * 1.0,
        ),
      ).buildRecommendationBundle(
        input: _input(),
        recallLabels: const ['家常菜'],
      );

      expect(bundle.recipes.map((recipe) => recipe.id), ['103', '102', '101']);
      expect(bundle.rankingVersion, 'local_rank_v3_quality_shadow');
      expect(bundle.algorithmVersion, 'hybrid_v3_0_rank_v3_canary');
    });

    test('灰度决策或实验打分异常时顺序和版本一起回滚', () async {
      final services = [
        _serviceWithRows(
          _canaryRows(),
          canaryDecisionLoader: () async => throw StateError('config failed'),
        ),
        _serviceWithRows(
          _canaryRows(),
          canaryDecisionLoader: () async => const RecommendationCanaryDecision(
            useExperiment: true,
            rankingVersion: 'local_rank_v3_quality_shadow',
            algorithmVersion: 'hybrid_v3_0_rank_v3_canary',
          ),
          experimentalRanker: V2RecommendationExperimentalRanker(
            scorer: (_) => throw StateError('ranker failed'),
          ),
        ),
      ];

      for (final service in services) {
        final bundle = await service.buildRecommendationBundle(
          input: _input(),
          recallLabels: const ['家常菜'],
        );
        expect(
            bundle.recipes.map((recipe) => recipe.id), ['101', '102', '103']);
        expect(bundle.rankingVersion, 'local_rank_v2');
        expect(bundle.algorithmVersion, 'hybrid_v3_0');
      }
    });

    test('灰度在直达和默认池使用相同的排序与异常回退规则', () async {
      for (final useDefaultPool in [false, true]) {
        for (final rankerFails in [false, true]) {
          final summaries = <V2RecommendationShadowSummary>[];
          final rows = _canaryRows();
          final service = UnifiedRecommendationServiceV2(
            tagCatalogService: _StaticCatalogService(const []),
            tagRecipeLoader: (_, __) async => const [],
            searchRecipeLoader: (_, __) async =>
                useDefaultPool ? const [] : rows,
            defaultRecipeLoader: (_) async => useDefaultPool ? rows : const [],
            tagScoreLoader: () async => const {},
            favoriteTagLoader: () async => const {},
            favoriteDishLoader: () async => const {},
            recentRecipeLoader: () async => const [],
            shadowScoringService: V2RecommendationShadowScoringService(
              reporter: summaries.add,
            ),
            canaryDecisionLoader: () async =>
                const RecommendationCanaryDecision(
              useExperiment: true,
              rankingVersion: 'local_rank_v3_quality_shadow',
              algorithmVersion: 'hybrid_v3_0_rank_v3_canary',
            ),
            experimentalRanker: V2RecommendationExperimentalRanker(
              scorer: rankerFails
                  ? (_) => throw StateError('ranker failed')
                  : (candidate) => candidate.baselinePosition * 1.0,
            ),
          );

          final bundle = await service.buildRecommendationBundle(
            input: _input(),
            recallLabels: const ['家常菜'],
          );

          expect(
            bundle.recipes.map((recipe) => recipe.id),
            rankerFails ? ['101', '102', '103'] : ['103', '102', '101'],
          );
          expect(
            bundle.rankingVersion,
            rankerFails ? 'local_rank_v2' : 'local_rank_v3_quality_shadow',
          );
          expect(
            bundle.algorithmVersion,
            rankerFails ? 'hybrid_v3_0' : 'hybrid_v3_0_rank_v3_canary',
          );
          expect(summaries, hasLength(1));
          expect(
            summaries.single.recallPath,
            useDefaultPool
                ? V2RecommendationRecallPath.defaultPool
                : V2RecommendationRecallPath.direct,
          );
        }
      }
    });

    test('未命中决策不能把实验版本归因给基线结果', () async {
      final bundle = await _serviceWithRows(
        _canaryRows(),
        canaryDecisionLoader: () async => const RecommendationCanaryDecision(
          useExperiment: false,
          rankingVersion: 'unexpected_experiment_version',
          algorithmVersion: 'unexpected_experiment_algorithm',
        ),
      ).buildRecommendationBundle(
        input: _input(),
        recallLabels: const ['家常菜'],
      );

      expect(bundle.recipes.map((recipe) => recipe.id), ['101', '102', '103']);
      expect(bundle.rankingVersion, 'local_rank_v2');
      expect(bundle.algorithmVersion, 'hybrid_v3_0');
    });

    test('自由文本不会被拼成 FTS AND 查询，并会展开召回提示词', () async {
      final searchedLabels = <String>[];
      var defaultPoolCalled = false;
      final service = UnifiedRecommendationServiceV2(
        tagCatalogService: _StaticCatalogService([
          const UnifiedTagModel(
            id: 'scene_night',
            label: '夜宵',
            category: 'scene',
            iconAsset: 'schedule',
            visual: VisualConfig(
              shapeType: 'circle',
              colors: ['0xFF45A6D8', '0xFF8A7CF7'],
            ),
          ),
        ]),
        tagRecipeLoader: (_, __) async => const [],
        searchRecipeLoader: (query, limit) async {
          searchedLabels.add(query);
          if (query != '快手') return const [];
          return [
            _row(
              dishId: 101,
              recipeId: 201,
              name: '快手番茄面',
              tags: const ['快手', '主食'],
            ),
          ];
        },
        defaultRecipeLoader: (_) async {
          defaultPoolCalled = true;
          return const [];
        },
        tagScoreLoader: () async => const {},
        favoriteTagLoader: () async => const {},
        favoriteDishLoader: () async => const {},
        recentRecipeLoader: () async => const [],
      );

      final bundle = await service.buildRecommendationBundle(
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
        recallLabels: const ['夜宵', '今晚想吃热一点'],
      );

      expect(
        searchedLabels,
        containsAll(['夜宵', '快手', '热菜', '汤羹', '主食']),
      );
      expect(searchedLabels.every((label) => !label.contains(' ')), isTrue);
      expect(searchedLabels.any((label) => label.contains('想吃')), isFalse);
      expect(defaultPoolCalled, isFalse);
      expect(bundle.recipes.map((recipe) => recipe.name), ['快手番茄面']);
    });

    test('清淡意图会展开为统一库已有的清爽、蒸和素菜标签', () async {
      final searchedLabels = <String>[];
      final service = UnifiedRecommendationServiceV2(
        tagCatalogService: _StaticCatalogService([
          _tag(id: 171, label: '清爽', category: 'taste'),
          _tag(id: 58, label: '蒸', category: 'method'),
          _tag(id: 14, label: '素菜', category: 'howtocook_category'),
          _tag(id: 13, label: '汤羹', category: 'howtocook_category'),
        ]),
        tagRecipeLoader: (_, __) async => const [],
        searchRecipeLoader: (query, limit) async {
          searchedLabels.add(query);
          if (query != '清爽') return const [];
          return [
            _row(
              dishId: 304,
              recipeId: 404,
              name: '清蒸南瓜',
              tags: const ['清爽', '蒸', '素菜'],
              ingredients: const ['南瓜'],
            ),
          ];
        },
        tagScoreLoader: () async => const {},
        favoriteTagLoader: () async => const {},
        favoriteDishLoader: () async => const {},
        recentRecipeLoader: () async => const [],
      );

      final bundle = await service.buildRecommendationBundle(
        input: const TasteInferenceInput(
          likedTagIds: [],
          likedTagLabels: ['清淡'],
          dislikedTagIds: [],
          dislikedTagLabels: [],
          skippedTagIds: [],
          skippedTagLabels: [],
          freeformRequirement: '少油一点',
          historyPreferenceSummary: {},
        ),
        recallLabels: const ['清淡'],
      );

      expect(
        searchedLabels,
        containsAll(['清爽', '蒸', '素菜', '汤羹', '清淡']),
      );
      expect(bundle.recipes.map((recipe) => recipe.name), ['清蒸南瓜']);
      expect(bundle.reasonsByRecipeId['304'], contains('清爽'));
    });

    test('精确召回全被硬约束过滤时使用默认池并再次应用约束', () async {
      var defaultPoolCalled = false;
      final summaries = <V2RecommendationShadowSummary>[];
      final service = UnifiedRecommendationServiceV2(
        tagCatalogService: _StaticCatalogService(const []),
        tagRecipeLoader: (_, __) async => const [],
        searchRecipeLoader: (_, __) async => [
          _row(
            dishId: 101,
            recipeId: 201,
            name: '蒜蓉虾仁',
            tags: const ['海鲜'],
            ingredients: const ['虾仁'],
          ),
        ],
        defaultRecipeLoader: (_) async {
          defaultPoolCalled = true;
          return [
            _row(
              dishId: 102,
              recipeId: 202,
              name: '清蒸鲈鱼',
              tags: const ['海鲜'],
              ingredients: const ['鲈鱼'],
            ),
            _row(
              dishId: 103,
              recipeId: 203,
              name: '番茄豆腐煲',
              tags: const ['素菜', '家常菜'],
              ingredients: const ['番茄', '豆腐'],
            ),
          ];
        },
        tagScoreLoader: () async => const {},
        favoriteTagLoader: () async => const {},
        favoriteDishLoader: () async => const {},
        recentRecipeLoader: () async => const [],
        shadowScoringService: V2RecommendationShadowScoringService(
          reporter: summaries.add,
        ),
      );

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

      expect(defaultPoolCalled, isTrue);
      expect(bundle.recipes.map((recipe) => recipe.name), ['番茄豆腐煲']);
      expect(bundle.summary, contains('本地正式菜谱池'));
      expect(bundle.summary, contains('忌口'));
      expect(summaries, hasLength(1));
      expect(
        summaries.single.recallPath,
        V2RecommendationRecallPath.defaultPool,
      );
      expect(summaries.single.candidateCount, 1);
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

    test('2 人场景不把 1 人份菜谱谎称为适合 2 人', () async {
      final bundle = await _serviceWithRows([
        _row(
          dishId: 101,
          recipeId: 201,
          name: '一人份番茄豆腐面',
          tags: const ['家常菜'],
          ingredients: const ['番茄', '豆腐', '面'],
          servings: 1,
        ),
      ]).buildRecommendationBundle(
        input: const TasteInferenceInput(
          likedTagIds: [],
          likedTagLabels: ['家常菜'],
          dislikedTagIds: [],
          dislikedTagLabels: [],
          skippedTagIds: [],
          skippedTagLabels: [],
          freeformRequirement: '',
          structuredConstraints: TasteStructuredConstraints(partySize: 2),
          historyPreferenceSummary: {},
        ),
        recallLabels: const ['家常菜'],
        limit: 1,
      );

      final reason = bundle.reasonsByRecipeId['101']!;
      expect(reason, contains('1 人份'));
      expect(reason, contains('2 人建议加量'));
      expect(reason, isNot(contains('适合 2 人')));
    });

    test('4 人场景按标注份量提示加量', () async {
      final bundle = await _serviceWithRows([
        _row(
          dishId: 101,
          recipeId: 201,
          name: '一人份番茄豆腐面',
          tags: const ['家常菜'],
          ingredients: const ['番茄', '豆腐', '面'],
          servings: 1,
        ),
      ]).buildRecommendationBundle(
        input: const TasteInferenceInput(
          likedTagIds: [],
          likedTagLabels: ['家常菜'],
          dislikedTagIds: [],
          dislikedTagLabels: [],
          skippedTagIds: [],
          skippedTagLabels: [],
          freeformRequirement: '',
          structuredConstraints: TasteStructuredConstraints(partySize: 4),
          historyPreferenceSummary: {},
        ),
        recallLabels: const ['家常菜'],
        limit: 1,
      );

      final reason = bundle.reasonsByRecipeId['101']!;
      expect(reason, contains('1 人份'));
      expect(reason, contains('4 人需加量'));
      expect(reason, isNot(contains('适合 4 人')));
    });

    test('偏好分只提升命中该口味的候选', () async {
      final service = _serviceWithRows(
        [
          _row(
            dishId: 101,
            recipeId: 201,
            name: '家常豆腐',
            tags: const [],
          ),
          _row(
            dishId: 102,
            recipeId: 202,
            name: '辣子鸡',
            tags: const [],
          ),
        ],
        tagCatalogService: _StaticCatalogService([
          _tag(id: 1, label: '辣', category: 'taste'),
          _tag(id: 2, label: '家常', category: 'cuisine'),
        ]),
        tagScores: const {'db_taste_1': 20},
      );

      final bundle = await service.buildRecommendationBundle(
        input: const TasteInferenceInput(
          likedTagIds: [],
          likedTagLabels: ['辣', '家常'],
          dislikedTagIds: [],
          dislikedTagLabels: [],
          skippedTagIds: [],
          skippedTagLabels: [],
          freeformRequirement: '',
          historyPreferenceSummary: {},
        ),
        recallLabels: const ['辣', '家常'],
        limit: 2,
      );

      expect(bundle.recipes.first.name, '辣子鸡');
      expect(bundle.reasonsByRecipeId['102'], contains('贴合你的历史偏好'));
    });

    test('收藏标签只提升命中该标签的候选', () async {
      final service = _serviceWithRows(
        [
          _row(
            dishId: 101,
            recipeId: 201,
            name: '家常豆腐',
            tags: const [],
          ),
          _row(
            dishId: 102,
            recipeId: 202,
            name: '辣子鸡',
            tags: const [],
          ),
        ],
        tagCatalogService: _StaticCatalogService([
          _tag(id: 1, label: '辣', category: 'taste'),
          _tag(id: 2, label: '家常', category: 'cuisine'),
        ]),
        favoriteTagIds: const {'db_taste_1'},
      );

      final bundle = await service.buildRecommendationBundle(
        input: const TasteInferenceInput(
          likedTagIds: [],
          likedTagLabels: ['辣', '家常'],
          dislikedTagIds: [],
          dislikedTagLabels: [],
          skippedTagIds: [],
          skippedTagLabels: [],
          freeformRequirement: '',
          historyPreferenceSummary: {},
        ),
        recallLabels: const ['辣', '家常'],
        limit: 2,
      );

      expect(bundle.recipes.first.name, '辣子鸡');
      expect(bundle.reasonsByRecipeId['102'], contains('包含收藏口味'));
    });

    test('高频反馈有上限，不会压过明显更优的候选', () async {
      final service = _serviceWithRows(
        [
          _row(
            dishId: 101,
            recipeId: 201,
            name: '辣子鸡',
            tags: const [],
            popularity: 20,
          ),
          _row(
            dishId: 102,
            recipeId: 202,
            name: '家常豆腐',
            tags: const [],
            popularity: 700,
          ),
        ],
        tagCatalogService: _StaticCatalogService([
          _tag(id: 1, label: '辣', category: 'taste'),
          _tag(id: 2, label: '家常', category: 'cuisine'),
        ]),
        tagScores: const {'db_taste_1': 200},
      );

      final bundle = await service.buildRecommendationBundle(
        input: const TasteInferenceInput(
          likedTagIds: [],
          likedTagLabels: ['辣', '家常'],
          dislikedTagIds: [],
          dislikedTagLabels: [],
          skippedTagIds: [],
          skippedTagLabels: [],
          freeformRequirement: '',
          historyPreferenceSummary: {},
        ),
        recallLabels: const ['辣', '家常'],
        limit: 2,
      );

      expect(bundle.recipes.first.name, '家常豆腐');
    });

    test('健康向与体验向会改变本地候选顺序', () async {
      final rows = [
        _row(
          dishId: 101,
          recipeId: 201,
          name: '清蒸鸡胸西兰花',
          tags: const ['家常菜', '清淡', '高蛋白', '蔬菜'],
          ingredients: const ['鸡胸', '西兰花'],
        ),
        _row(
          dishId: 102,
          recipeId: 202,
          name: '麻辣芝士火锅',
          tags: const ['家常菜', '麻辣', '浓郁', '火锅'],
          ingredients: const ['辣椒', '芝士'],
        ),
      ];
      final service = _serviceWithRows(
        rows,
        mealPeriodClock: () => DateTime(2026, 9, 30, 15),
      );

      final healthBundle = await service.buildRecommendationBundle(
        input: _input().copyWith(
          planningDirection: MealPlanningDirection.health,
        ),
        recallLabels: const ['家常菜'],
        limit: 2,
      );
      final experienceBundle = await service.buildRecommendationBundle(
        input: _input().copyWith(
          planningDirection: MealPlanningDirection.experience,
        ),
        recallLabels: const ['家常菜'],
        limit: 2,
      );

      expect(healthBundle.recipes.first.name, '清蒸鸡胸西兰花');
      expect(experienceBundle.recipes.first.name, '麻辣芝士火锅');
      expect(
        healthBundle.reasonsByRecipeId['101'],
        contains('符合健康向规划'),
      );
      expect(
        experienceBundle.reasonsByRecipeId['102'],
        contains('符合体验向规划'),
      );
    });

    test('健康向会按真实营养数据调整排序', () async {
      final light = {
        ..._row(
          dishId: 101,
          recipeId: 201,
          name: '京酱肉丝',
          tags: const ['家常菜'],
          ingredients: const ['猪肉'],
          popularity: 10,
        ),
        'nutrition': const {
          'calories': 380,
          'protein': 26,
          'fat': 8,
          'carbs': 12,
          'fiber': 4,
          'sugar': 3,
          'sodium': 600,
        },
      };
      final heavy = {
        ..._row(
          dishId: 102,
          recipeId: 202,
          name: '铁板牛柳',
          tags: const ['家常菜'],
          ingredients: const ['牛肉'],
          popularity: 90,
        ),
        'nutrition': const {
          'calories': 920,
          'protein': 9,
          'fat': 66,
          'carbs': 14,
          'fiber': 1,
          'sugar': 6,
          'sodium': 1900,
        },
      };

      final healthBundle =
          await _serviceWithRows([light, heavy]).buildRecommendationBundle(
        input:
            _input().copyWith(planningDirection: MealPlanningDirection.health),
        recallLabels: const ['家常菜'],
        limit: 2,
      );
      final balancedBundle =
          await _serviceWithRows([light, heavy]).buildRecommendationBundle(
        input: _input(),
        recallLabels: const ['家常菜'],
        limit: 2,
      );

      expect(healthBundle.recipes.first.name, '京酱肉丝');
      // 均衡向不受营养数据影响，人气占优的重口菜排前
      expect(balancedBundle.recipes.first.name, '铁板牛柳');
    });

    group('做饭实用性排序', () {
      for (final mode in [
        TasteExecutionPreference.cook,
        TasteExecutionPreference.any,
      ]) {
        test('$mode：同等相关性按数值难度优先简单菜且重复结果确定', () async {
          final service = _serviceWithRows(
            [
              for (final difficulty in [5, 4, 3, 2, 1])
                _row(
                  dishId: difficulty,
                  recipeId: difficulty,
                  name: '家常炒菜$difficulty',
                  tags: const ['家常菜'],
                  difficulty: difficulty,
                  totalTimeMinutes: null,
                ),
            ],
            mealPeriodClock: () => DateTime(2026, 9, 30, 15),
          );
          for (var attempt = 0; attempt < 3; attempt++) {
            final recipes = await service.recommendRecipes(
              input: _input().copyWith(
                structuredConstraints:
                    TasteStructuredConstraints(executionPreference: mode),
              ),
              recallLabels: const ['家常菜'],
              limit: 5,
            );
            expect(
                recipes.map((recipe) => recipe.id), ['1', '2', '3', '4', '5']);
          }
        });

        test('$mode：23点简单面条优先于同等相关性的复杂小龙虾', () async {
          final service = _serviceWithRows(
            [
              _row(
                dishId: 1,
                recipeId: 1,
                name: '蒜蓉小龙虾',
                tags: const ['家常菜', '夜宵'],
                ingredients: const ['小龙虾'],
                difficulty: 5,
                totalTimeMinutes: null,
              ),
              _row(
                dishId: 2,
                recipeId: 2,
                name: '番茄鸡蛋面',
                tags: const ['家常菜'],
                ingredients: const ['番茄', '鸡蛋', '面条'],
                difficulty: 1,
                totalTimeMinutes: null,
              ),
            ],
            mealPeriodClock: () => DateTime(2026, 9, 30, 23),
          );
          final bundle = await service.buildRecommendationBundle(
            input: _input().copyWith(
              structuredConstraints:
                  TasteStructuredConstraints(executionPreference: mode),
            ),
            recallLabels: const ['家常菜'],
            limit: 2,
          );
          expect(bundle.recipes.map((recipe) => recipe.id), ['2', '1']);
          expect(bundle.reasonsByRecipeId.values.join(), isNot(contains('分钟')));
        });
      }

      for (final mode in [
        TasteExecutionPreference.delivery,
        TasteExecutionPreference.dineIn,
      ]) {
        test('$mode：难度和耗时不改变原有人气排序', () async {
          for (final swapEffort in [false, true]) {
            final recipes = await _serviceWithRows(
              [
                _row(
                  dishId: 1,
                  recipeId: 1,
                  name: '清炒时蔬',
                  tags: const ['家常菜'],
                  difficulty: swapEffort ? 5 : 1,
                  totalTimeMinutes: swapEffort ? 120 : 10,
                ),
                _row(
                  dishId: 2,
                  recipeId: 2,
                  name: '蒜苔炒肉',
                  tags: const ['家常菜'],
                  popularity: 60,
                  difficulty: swapEffort ? 1 : 5,
                  totalTimeMinutes: swapEffort ? 10 : 120,
                ),
              ],
              mealPeriodClock: () => DateTime(2026, 9, 30, 23),
            ).recommendRecipes(
              input: _input().copyWith(
                structuredConstraints:
                    TasteStructuredConstraints(executionPreference: mode),
              ),
              recallLabels: const ['家常菜'],
            );
            expect(recipes.map((recipe) => recipe.id), ['2', '1']);
          }
        });
      }

      test('已知正耗时小幅参与排序，未知耗时不视为最快', () async {
        final recipes = await _serviceWithRows(
          [
            for (final (id, time) in <(int, int?)>[(1, 90), (2, null), (3, 10)])
              _row(
                dishId: id,
                recipeId: id,
                name: '清炒时蔬',
                tags: const ['家常菜'],
                popularity: 54 - id,
                difficulty: 3,
                totalTimeMinutes: time,
              ),
          ],
          mealPeriodClock: () => DateTime(2026, 9, 30, 15),
        ).recommendRecipes(input: _input(), recallLabels: const ['家常菜']);
        expect(recipes.map((recipe) => recipe.id), ['3', '2', '1']);
      });

      test('缺失和非正耗时保持中性，不从菜名或快手标签虚构分钟', () async {
        for (final time in <int?>[null, 0, -5]) {
          final recipes = await _serviceWithRows(
            [
              for (final id in [1, 2, 3])
                _row(
                  dishId: id,
                  recipeId: id,
                  name: '快手小米粥',
                  tags: const ['家常菜', '快手', '10分钟'],
                  popularity: 54 - id,
                  totalTimeMinutes: id == 2 ? 30 : time,
                ),
            ],
            mealPeriodClock: () => DateTime(2026, 9, 30, 15),
          ).recommendRecipes(input: _input(), recallLabels: const ['家常菜']);
          expect(recipes.map((recipe) => recipe.id), ['1', '2', '3']);
        }
      });

      test('缺失或超出1到5的难度不推断为简单或复杂', () async {
        for (final difficulty in <int?>[null, 0, -1, 6]) {
          final recipes = await _serviceWithRows(
            [
              for (final id in [1, 2, 3])
                _row(
                  dishId: id,
                  recipeId: id,
                  name: '家常炒菜',
                  tags: const ['家常菜'],
                  popularity: 54 - id,
                  difficulty: id == 2 ? 3 : difficulty,
                  totalTimeMinutes: null,
                ),
            ],
            mealPeriodClock: () => DateTime(2026, 9, 30, 15),
          ).recommendRecipes(input: _input(), recallLabels: const ['家常菜']);
          expect(recipes.map((recipe) => recipe.id), ['1', '2', '3']);
        }
      });

      for (final name in ['番茄鸡蛋面', '小米粥', '蒸蛋']) {
        test('23点按真实菜名偏好$name，无关夜宵标签不能堆分', () async {
          final recipes = await _serviceWithRows(
            [
              _row(
                dishId: 1,
                recipeId: 1,
                name: '红烧排骨',
                tags: const [
                  '家常菜',
                  '夜宵',
                  '烧烤',
                  '小龙虾',
                  '串',
                  '炸鸡',
                  '泡面',
                  '卤味',
                  '啤酒',
                  '烤鱼',
                  '面',
                  '粥',
                  '蒸蛋',
                ],
                totalTimeMinutes: null,
              ),
              _row(
                dishId: 2,
                recipeId: 2,
                name: name,
                tags: const ['家常菜'],
                totalTimeMinutes: null,
              ),
            ],
            mealPeriodClock: () => DateTime(2026, 9, 30, 23),
          ).recommendRecipes(input: _input(), recallLabels: const ['家常菜']);
          expect(recipes.map((recipe) => recipe.id), ['2', '1']);
        });
      }

      test('否定自由文本不会变成正向做饭偏好', () async {
        final service = _serviceWithRows(
          [
            _row(
              dishId: 1,
              recipeId: 1,
              name: '番茄鸡蛋面',
              tags: const ['家常菜'],
              difficulty: 1,
              totalTimeMinutes: null,
            ),
            _row(
              dishId: 2,
              recipeId: 2,
              name: '蒜蓉小龙虾',
              tags: const ['家常菜'],
              difficulty: 5,
              totalTimeMinutes: null,
            ),
          ],
          mealPeriodClock: () => DateTime(2026, 9, 30, 23),
        );
        final recipes = await service.recommendRecipes(
          input: _input().copyWith(freeformRequirement: '今晚不想吃小龙虾'),
          recallLabels: const ['家常菜'],
        );
        expect(recipes.first.id, '1');
      });

      test('外卖和堂食不增加新的自由文本做饭加分', () async {
        for (final mode in [
          TasteExecutionPreference.delivery,
          TasteExecutionPreference.dineIn,
        ]) {
          final recipes = await _serviceWithRows(
            [
              _row(
                dishId: 1,
                recipeId: 1,
                name: '番茄鸡蛋面',
                tags: const ['家常菜'],
                popularity: 60,
              ),
              _row(
                dishId: 2,
                recipeId: 2,
                name: '蒜蓉小龙虾',
                tags: const ['家常菜'],
              ),
            ],
            mealPeriodClock: () => DateTime(2026, 9, 30, 15),
          ).recommendRecipes(
            input: _input().copyWith(
              freeformRequirement: '今晚想吃小龙虾',
              structuredConstraints:
                  TasteStructuredConstraints(executionPreference: mode),
            ),
            recallLabels: const ['家常菜'],
          );
          expect(recipes.map((recipe) => recipe.id), ['1', '2']);
        }
      });

      test('明确喜欢和自由文本请求仍不能越过忌口过滤', () async {
        final bundle = await _serviceWithRows(
          [
            _row(
              dishId: 1,
              recipeId: 1,
              name: '蒜蓉小龙虾',
              tags: const ['家常菜'],
              ingredients: const ['小龙虾'],
              totalTimeMinutes: null,
            ),
            _row(
              dishId: 2,
              recipeId: 2,
              name: '番茄鸡蛋面',
              tags: const ['家常菜'],
              ingredients: const ['番茄', '鸡蛋', '面条'],
              totalTimeMinutes: null,
            ),
          ],
          mealPeriodClock: () => DateTime(2026, 9, 30, 23),
        ).buildRecommendationBundle(
          input: _input().copyWith(
            likedTagLabels: ['小龙虾'],
            freeformRequirement: '今晚想吃小龙虾',
            structuredConstraints: const TasteStructuredConstraints(
              dietaryRestrictions: ['海鲜'],
            ),
          ),
          recallLabels: const ['家常菜'],
        );
        expect(bundle.recipes.map((recipe) => recipe.id), ['2']);
        expect(bundle.summary, contains('忌口'));
      });

      for (final choice in ['小龙虾', '烧烤']) {
        for (final useFreeform in [false, true]) {
          test('23点明确${useFreeform ? '自由文本' : '喜欢'}$choice仍可胜过省事菜', () async {
            final recipes = await _serviceWithRows(
              [
                _row(
                  dishId: 1,
                  recipeId: 1,
                  name: '番茄鸡蛋面',
                  tags: const ['家常菜'],
                  difficulty: 1,
                  totalTimeMinutes: 10,
                ),
                _row(
                  dishId: 2,
                  recipeId: 2,
                  name: choice == '小龙虾' ? '蒜蓉小龙虾' : '炭火烧烤拼盘',
                  tags: const ['家常菜'],
                  ingredients: [choice == '小龙虾' ? '小龙虾' : '羊肉'],
                  difficulty: 5,
                  totalTimeMinutes: 120,
                ),
              ],
              mealPeriodClock: () => DateTime(2026, 9, 30, 23),
            ).recommendRecipes(
              input: _input().copyWith(
                likedTagLabels: ['家常菜', if (!useFreeform) choice],
                freeformRequirement: useFreeform ? '今晚想吃$choice' : '',
                structuredConstraints: const TasteStructuredConstraints(
                  executionPreference: TasteExecutionPreference.cook,
                ),
              ),
              recallLabels: const ['家常菜'],
            );
            expect(recipes.map((recipe) => recipe.id), ['2', '1']);
          });
        }
      }
    });

    group('偏好学习键一致性', () {
      test('历史分数按口味文本写入时仍提升同名标签的候选', () async {
        final service = _serviceWithRows(
          [
            _row(
              dishId: 1,
              recipeId: 1,
              name: '清炒时蔬',
              tags: const ['家常菜'],
            ),
            _row(
              dishId: 2,
              recipeId: 2,
              name: '香辣鸡腿',
              tags: const ['家常菜', '辣'],
              popularity: 20,
            ),
          ],
          tagCatalogService: _StaticCatalogService([
            _tag(id: 1, label: '辣', category: 'taste'),
          ]),
          tagScores: const {'辣': 200},
        );

        final recipes = await service.recommendRecipes(
          input: _input(),
          recallLabels: const ['家常菜'],
          limit: 2,
        );

        expect(recipes.map((recipe) => recipe.name), ['香辣鸡腿', '清炒时蔬']);
      });

      test('产品收藏 ID 通过同名标签提升本地候选', () async {
        final service = _serviceWithRows(
          [
            _row(
              dishId: 1,
              recipeId: 1,
              name: '清炒时蔬',
              tags: const ['家常菜'],
              popularity: 60,
            ),
            _row(
              dishId: 2,
              recipeId: 2,
              name: '香辣鸡腿',
              tags: const ['家常菜', '辣'],
              popularity: 20,
            ),
          ],
          tagCatalogService: _StaticCatalogService([
            _tag(id: 1, label: '辣', category: 'taste'),
          ]),
          favoriteTagIds: const {'f_spicy'},
        );

        final recipes = await service.recommendRecipes(
          input: _input(),
          recallLabels: const ['家常菜'],
          limit: 2,
        );

        expect(recipes.map((recipe) => recipe.name), ['香辣鸡腿', '清炒时蔬']);
      });

      test('没选当轮偏好时，长期口味仍能改变首推', () async {
        final service = _serviceWithRows(
          [
            _row(
              dishId: 1,
              recipeId: 1,
              name: '清炒时蔬',
              tags: const ['家常菜'],
              popularity: 500,
            ),
            _row(
              dishId: 2,
              recipeId: 2,
              name: '香辣鸡腿',
              tags: const ['家常菜', '辣'],
              popularity: 20,
            ),
          ],
          tagCatalogService: _StaticCatalogService([
            _tag(id: 1, label: '辣', category: 'taste'),
          ]),
          tagScores: const {'辣': 200},
        );

        final bundle = await service.buildRecommendationBundle(
          input: _input().copyWith(
            likedTagLabels: const [],
            historyPreferenceSummary: const {'辣': 200},
          ),
          recallLabels: const ['家常菜'],
          limit: 2,
        );

        expect(
          bundle.recipes.map((recipe) => recipe.name),
          ['香辣鸡腿', '清炒时蔬'],
        );
        expect(
          bundle.reasonsByRecipeId['2'],
          contains('贴合你的历史偏好'),
        );
      });
    });

    test('早餐时段：清淡早食排到重口火锅前', () async {
      final rows = [
        _row(
          dishId: 101,
          recipeId: 201,
          name: '小米南瓜粥',
          tags: const ['家常菜', '早餐'],
          ingredients: const ['小米', '南瓜'],
        ),
        _row(
          dishId: 102,
          recipeId: 202,
          name: '麻辣火锅',
          tags: const ['家常菜', '麻辣', '火锅'],
          ingredients: const ['辣椒', '牛油'],
        ),
      ];
      final service = _serviceWithRows(
        rows,
        mealPeriodClock: () => DateTime(2026, 9, 30, 8),
      );

      final bundle = await service.buildRecommendationBundle(
        input: _input(),
        recallLabels: const ['家常菜'],
        limit: 2,
      );

      expect(bundle.recipes.first.name, '小米南瓜粥');
      expect(bundle.recipes.last.name, '麻辣火锅');
    });

    test('夜宵时段：外卖和堂食烧烤串串仍获得加成', () async {
      final rows = [
        _row(
          dishId: 101,
          recipeId: 201,
          name: '清蒸鲈鱼',
          tags: const ['家常菜', '清淡'],
          ingredients: const ['鲈鱼'],
        ),
        _row(
          dishId: 102,
          recipeId: 202,
          name: '炭火羊肉串',
          tags: const ['家常菜', '夜宵'],
          ingredients: const ['羊肉'],
        ),
      ];
      final service = _serviceWithRows(
        rows,
        mealPeriodClock: () => DateTime(2026, 9, 30, 23),
      );

      for (final mode in [
        TasteExecutionPreference.delivery,
        TasteExecutionPreference.dineIn,
      ]) {
        final bundle = await service.buildRecommendationBundle(
          input: _input().copyWith(
            structuredConstraints:
                TasteStructuredConstraints(executionPreference: mode),
          ),
          recallLabels: const ['家常菜'],
          limit: 2,
        );

        expect(bundle.recipes.first.name, '炭火羊肉串');
      }
    });

    test('非敏感时段不干预排序', () async {
      final rows = [
        _row(
          dishId: 101,
          recipeId: 201,
          name: '小米南瓜粥',
          tags: const ['家常菜', '早餐'],
          ingredients: const ['小米'],
        ),
        _row(
          dishId: 102,
          recipeId: 202,
          name: '麻辣火锅',
          tags: const ['家常菜', '麻辣'],
          ingredients: const ['辣椒'],
          popularity: 90,
        ),
      ];
      final afternoon = _serviceWithRows(
        rows,
        mealPeriodClock: () => DateTime(2026, 9, 30, 15),
      );
      final baselineService = _serviceWithRows(
        rows,
        mealPeriodClock: () => DateTime(2026, 9, 30, 15),
      );

      final afternoonBundle = await afternoon.buildRecommendationBundle(
        input: _input(),
        recallLabels: const ['家常菜'],
        limit: 2,
      );
      final baselineBundle = await baselineService.buildRecommendationBundle(
        input: _input(),
        recallLabels: const ['家常菜'],
        limit: 2,
      );

      expect(afternoonBundle.recipes.map((r) => r.name),
          baselineBundle.recipes.map((r) => r.name));
      expect(afternoonBundle.recipes.first.name, '麻辣火锅');
    });
  });
}

UnifiedRecommendationServiceV2 _serviceWithRows(
  List<Map<String, dynamic>> rows, {
  V2RecommendationShadowScoringService? shadowScoringService,
  V2RecommendationCanaryDecisionLoader? canaryDecisionLoader,
  V2RecommendationExperimentalRanker? experimentalRanker,
  V2TagCatalogService? tagCatalogService,
  Map<String, int> tagScores = const {},
  Set<String> favoriteTagIds = const {},
  DateTime Function()? mealPeriodClock,
}) {
  return UnifiedRecommendationServiceV2(
    tagCatalogService: tagCatalogService ?? _StaticCatalogService(const []),
    tagRecipeLoader: (tagIds, limit) async => rows,
    searchRecipeLoader: (query, limit) async => rows,
    defaultRecipeLoader: (_) async => const [],
    tagScoreLoader: () async => tagScores,
    favoriteTagLoader: () async => favoriteTagIds,
    favoriteDishLoader: () async => const {},
    recentRecipeLoader: () async => const [],
    shadowScoringService: shadowScoringService,
    canaryDecisionLoader: canaryDecisionLoader,
    experimentalRanker: experimentalRanker,
    // Keep ranking tests independent of the wall clock; tests that exercise a
    // specific meal period inject their own clock explicitly.
    mealPeriodClock: mealPeriodClock ?? () => DateTime(2026, 9, 30, 15),
  );
}

List<Map<String, dynamic>> _canaryRows() {
  return [
    _row(
      dishId: 101,
      recipeId: 201,
      name: '正式第一名',
      tags: const ['家常菜'],
      popularity: 90,
      rating: 5,
    ),
    _row(
      dishId: 102,
      recipeId: 202,
      name: '正式第二名',
      tags: const ['家常菜'],
      popularity: 60,
    ),
    _row(
      dishId: 103,
      recipeId: 203,
      name: '正式第三名',
      tags: const ['家常菜'],
      popularity: 20,
      rating: 4,
    ),
  ];
}

TasteInferenceInput _input() {
  return const TasteInferenceInput(
    likedTagIds: [],
    likedTagLabels: ['家常菜'],
    dislikedTagIds: [],
    dislikedTagLabels: [],
    skippedTagIds: [],
    skippedTagLabels: [],
    freeformRequirement: '',
    historyPreferenceSummary: {},
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
  int? totalTimeMinutes = 30,
  int? difficulty = 2,
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
    'difficulty': difficulty,
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

UnifiedTagModel _tag({
  required int id,
  required String label,
  required String category,
}) {
  return UnifiedTagModel(
    id: 'db_${category}_$id',
    label: label,
    category: category,
    iconAsset: 'restaurant',
    visual: const VisualConfig(
      shapeType: 'circle',
      colors: ['0xFF4F9D69', '0xFF7ABF88'],
    ),
  );
}
