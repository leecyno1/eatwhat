import 'package:eatwhat_app/v2/core/data/models/recipe_model.dart';
import 'package:eatwhat_app/v2/core/data/models/taste_inference_input.dart';
import 'package:eatwhat_app/v2/core/data/models/taste_selection_models.dart';
import 'package:eatwhat_app/v2/core/services/unified_recommendation_service_v2.dart';
import 'package:eatwhat_app/v2/core/services/v2_howtocook_recipe_service.dart';
import 'package:eatwhat_app/v2/core/services/v2_phase2_recommendation_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../test_bootstrap.dart';

const _sichuanTerms = [
  '水煮',
  '回锅',
  '宫保',
  '麻婆',
  '鱼香',
  '小炒',
  '香辣',
  '麻辣',
  '辣子',
  '川味',
];

const _westernTerms = [
  '意面',
  '意大利面',
  '披萨',
  '牛排',
  '奶油',
  '罗宋',
  '法式',
  '焗',
];

Future<Phase2RecommendationBundle> _recommend(
  TasteInferenceInput input, {
  required int hour,
  Map<String, int> tagScores = const {},
}) {
  final service = V2Phase2RecommendationService(
    enableAiEnhancement: false,
    recommendationService: UnifiedRecommendationServiceV2(
      tagScoreLoader: () async => tagScores,
      mealPeriodClock: () => DateTime(2026, 11, 8, hour),
    ),
    howToCookRecipeService: _emptyHowToCookService(),
  );
  return service.buildRecommendations(input: input);
}

TasteInferenceInput _input({
  List<String> liked = const [],
  String freeform = '',
  Map<String, int> history = const {},
}) {
  return TasteInferenceInput(
    likedTagIds: const [],
    likedTagLabels: liked,
    dislikedTagIds: const [],
    dislikedTagLabels: const [],
    skippedTagIds: const [],
    skippedTagLabels: const [],
    freeformRequirement: freeform,
    historyPreferenceSummary: history,
  );
}

String _recipeText(RecipeModel recipe) =>
    [recipe.name, ...recipe.tags, ...recipe.ingredients].join('|');

void main() {
  setUpAll(() async {
    await bootstrapTestEnvironment();
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('川菜偏好命中具体川味菜，而不是无差别默认池', () async {
    final bundle = await _recommend(_input(liked: ['川菜']), hour: 19);
    debugPrint('KERNEL 川菜: ${bundle.finalRecommendations.map((r) => r.name)}');

    final hits = bundle.finalRecommendations
        .where((recipe) => _sichuanTerms.any(_recipeText(recipe).contains))
        .length;
    expect(hits, greaterThanOrEqualTo(2), reason: bundle.aiSummary);
    expect(
      bundle.finalRecommendations.map((recipe) => recipe.name),
      isNot(contains('空气炸锅面包片')),
    );
  });

  test('西餐偏好命中西式菜，而不是早餐面包片', () async {
    final bundle = await _recommend(_input(liked: ['西餐']), hour: 19);
    debugPrint('KERNEL 西餐: ${bundle.finalRecommendations.map((r) => r.name)}');

    expect(
      bundle.finalRecommendations
          .any((recipe) => _westernTerms.any(_recipeText(recipe).contains)),
      isTrue,
      reason: bundle.aiSummary,
    );
    expect(
      bundle.finalRecommendations.first.name,
      isNot('空气炸锅面包片'),
    );
  });

  test('早餐默认首推不让红烧肉占据前三', () async {
    final bundle = await _recommend(_input(), hour: 8);
    debugPrint('KERNEL 早餐: ${bundle.finalRecommendations.map((r) => r.name)}');

    final names = bundle.finalRecommendations.map((recipe) => recipe.name);
    expect(names, isNot(contains('湖南家常红烧肉')));
    final first = bundle.finalRecommendations.first;
    expect(
      first.tags.contains('早餐') ||
          ['粥', '面', '蛋', '奶', '燕麦', '吐司', '面包', '包', '馒头', '豆浆', '馄饨', '饼']
              .any(first.name.contains),
      isTrue,
      reason: '首推 ${first.name} 不像早餐',
    );
    expect(
      bundle.aiReasonsByRecipeId[first.id],
      contains('早餐时段'),
    );
  });

  test('晚餐默认不把早餐菜挤进前三', () async {
    final bundle = await _recommend(_input(), hour: 19);
    debugPrint('KERNEL 晚餐: ${bundle.finalRecommendations.map((r) => r.name)}');

    expect(
      bundle.finalRecommendations.any((recipe) => recipe.tags.contains('早餐')),
      isFalse,
      reason: bundle.aiSummary,
    );
  });

  test('23 点外卖不主推早餐面包和红烧肉', () async {
    const intent = TasteInferenceInput(
      likedTagIds: [],
      likedTagLabels: [],
      dislikedTagIds: [],
      dislikedTagLabels: [],
      skippedTagIds: [],
      skippedTagLabels: [],
      freeformRequirement: '',
      structuredConstraints: TasteStructuredConstraints(
        executionPreference: TasteExecutionPreference.delivery,
      ),
      historyPreferenceSummary: {},
    );
    final bundle = await _recommend(intent, hour: 23);
    debugPrint(
        'KERNEL 夜宵外卖: ${bundle.finalRecommendations.map((r) => r.name)}');

    final names = bundle.finalRecommendations.map((recipe) => recipe.name);
    expect(names, isNot(contains('空气炸锅面包片')));
    expect(names, isNot(contains('湖南家常红烧肉')));
    final first = bundle.finalRecommendations.first;
    expect(bundle.aiReasonsByRecipeId[first.id], contains('夜宵时段'));
  });

  test('没选当轮偏好时，长期口味仍会改变首推', () async {
    final bundle = await _recommend(
      _input(history: const {'辣': 200}),
      hour: 19,
      tagScores: const {'辣': 200},
    );
    debugPrint(
        'KERNEL 长期吃辣: ${bundle.finalRecommendations.map((r) => r.name)}');

    expect(
      bundle.finalRecommendations.first.tags
              .any((tag) => ['辣', '麻辣', '香辣', '微辣'].contains(tag)) ||
          ['辣', '麻', '水煮', '小炒']
              .any(bundle.finalRecommendations.first.name.contains),
      isTrue,
    );
    expect(
      bundle.aiReasonsByRecipeId[bundle.finalRecommendations.first.id],
      contains('历史偏好'),
    );
  });

  test('素食偏好前三不推肉类主料', () async {
    final bundle = await _recommend(_input(liked: ['素食']), hour: 19);
    debugPrint('KERNEL 素食: ${bundle.finalRecommendations.map((r) => r.name)}');

    const meatTerms = [
      '猪肉',
      '五花肉',
      '排骨',
      '培根',
      '火腿',
      '鸡肉',
      '鸡腿',
      '鸡翅',
      '牛肉',
      '羊肉',
      '鱼',
      '虾',
      '蟹',
      '海鲜',
      '肉末',
      '肉丝',
      '肉馅',
      '荤菜',
    ];
    for (final recipe in bundle.finalRecommendations) {
      final text = _recipeText(recipe);
      expect(
        meatTerms.where(text.contains),
        isEmpty,
        reason: '${recipe.name}: $text',
      );
    }
  });

  test('清真偏好前三不推猪肉', () async {
    final bundle = await _recommend(_input(liked: ['清真']), hour: 19);
    debugPrint('KERNEL 清真: ${bundle.finalRecommendations.map((r) => r.name)}');

    const porkTerms = [
      '猪肉',
      '五花肉',
      '排骨',
      '培根',
      '火腿',
      '腊肉',
      '肥肉',
      '猪蹄',
      '里脊',
    ];
    for (final recipe in bundle.finalRecommendations) {
      final text = _recipeText(recipe);
      expect(
        porkTerms.where(text.contains),
        isEmpty,
        reason: '${recipe.name}: $text',
      );
    }
  });

  test('下午茶场景能返回甜品或饮品', () async {
    final bundle = await _recommend(_input(liked: ['下午茶']), hour: 15);
    debugPrint('KERNEL 下午茶: ${bundle.finalRecommendations.map((r) => r.name)}');

    expect(bundle.finalRecommendations, isNotEmpty);
    expect(
      bundle.finalRecommendations.take(2).any((recipe) {
        final text = _recipeText(recipe);
        return ['甜品', '饮品', '蛋糕', '奶茶', '咖啡'].any(text.contains);
      }),
      isTrue,
      reason: bundle.aiSummary,
    );
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
