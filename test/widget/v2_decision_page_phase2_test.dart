import 'package:eatwhat_app/v2/core/data/models/recipe_model.dart';
import 'package:eatwhat_app/v2/core/data/models/taste_inference_input.dart';
import 'package:eatwhat_app/v2/core/services/v2_howtocook_recipe_service.dart';
import 'package:eatwhat_app/v2/core/services/v2_phase2_recommendation_service.dart';
import 'package:eatwhat_app/v2/features/decision/decision_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../test_bootstrap.dart';

void main() {
  setUpAll(() async {
    await bootstrapTestEnvironment();
  });

  testWidgets('DecisionPage 在第二环节展示 AI 生成与资料补全状态', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: DecisionPage(
          autoNavigateToResult: false,
          input: const TasteInferenceInput(
            likedTagIds: ['flavor_spicy', 'scene_night'],
            likedTagLabels: ['辣', '夜宵'],
            dislikedTagIds: ['flavor_sweet'],
            dislikedTagLabels: ['甜'],
            skippedTagIds: ['scene_party'],
            skippedTagLabels: ['聚会'],
            freeformRequirement: '想吃热一点，带锅气',
            historyPreferenceSummary: {'flavor_spicy': 4},
          ),
          recommendationFlowService: V2Phase2RecommendationService(
            aiRecommendationLoader: _fakeAiRecommendations,
            howToCookRecipeService: _fakeHowToCookService(),
          ),
        ),
      ),
    );

    await _pumpUntilFound(tester, find.text('口味推理完成'));

    expect(find.text('口味推理完成'), findsOneWidget);
    expect(find.text('AI 生成 3 道候选'), findsOneWidget);
    expect(find.text('资料补全 3 道正式结果'), findsOneWidget);
    expect(find.text('正式结果已完成收束'), findsOneWidget);
    expect(find.textContaining('AI 已根据口味签名生成'), findsOneWidget);
    expect(find.text('正在确认本轮正式推荐结果'), findsOneWidget);
  });

  testWidgets('DecisionPage 可以通过 Phase2 服务注入结果', (tester) async {
    final service = V2Phase2RecommendationService(
      aiRecommendationLoader: ({
        required tags,
        required userProfile,
      }) async {
        return const [
          RecipeModel(
            id: 'dish_service_1',
            name: '炭火辣子鸡',
            description: '锅气足，收束更直接。',
            ingredients: ['鸡肉', '辣椒'],
            tags: ['辣', '锅气'],
          ),
        ];
      },
      howToCookRecipeService: _fakeHowToCookService(),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: DecisionPage(
          autoNavigateToResult: false,
          input: const TasteInferenceInput(
            likedTagIds: ['flavor_spicy'],
            likedTagLabels: ['辣'],
            dislikedTagIds: [],
            dislikedTagLabels: [],
            skippedTagIds: [],
            skippedTagLabels: [],
            freeformRequirement: '要有锅气',
            historyPreferenceSummary: {},
          ),
          recommendationFlowService: service,
        ),
      ),
    );

    await _pumpUntilFound(tester, find.text('AI 生成 1 道候选'));

    expect(find.text('AI 生成 1 道候选'), findsOneWidget);
    expect(find.text('资料补全 1 道正式结果'), findsOneWidget);
    expect(find.textContaining('AI 已根据口味签名生成'), findsOneWidget);
  });
}

Future<void> _pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  Duration step = const Duration(milliseconds: 100),
  int maxPumps = 30,
}) async {
  for (var i = 0; i < maxPumps; i += 1) {
    await tester.pump(step);
    if (finder.evaluate().isNotEmpty) return;
  }
}

V2HowToCookRecipeService _fakeHowToCookService() {
  return V2HowToCookRecipeService(
    searchLoader: (query, limit) async => [
      {
        'id': 'htc_1',
        'name': '番茄肥牛锅',
        'description': '热一点，有锅气。',
        'difficulty': 3,
        'category': '热菜',
        'cooking_time': 30,
        'servings': 2,
      },
      {
        'id': 'htc_2',
        'name': '香辣干锅鸡',
        'description': '辣味更猛，适合夜里。',
        'difficulty': 3,
        'category': '热菜',
        'cooking_time': 28,
        'servings': 2,
      },
      {
        'id': 'htc_3',
        'name': '麻辣冒菜',
        'description': '口味直接，适合今天这口。',
        'difficulty': 2,
        'category': '热菜',
        'cooking_time': 18,
        'servings': 1,
      },
    ],
    completeLoader: (recipeId) async => {
      'id': recipeId,
      'name': recipeId == 'htc_1'
          ? '番茄肥牛锅'
          : recipeId == 'htc_2'
              ? '香辣干锅鸡'
              : '麻辣冒菜',
      'description': '测试补全菜谱。',
      'difficulty': 3,
      'category': '热菜',
      'cooking_time': 30,
      'servings': 2,
      'ingredients': [
        {'name': '番茄', 'amount': '2', 'unit': '个'},
      ],
      'steps': [
        {'description': '先把食材准备好。'},
      ],
    },
    assetIndexLoader: () async => '{"items":[]}',
  );
}

Future<List<RecipeModel>> _fakeAiRecommendations({
  required List<String> tags,
  required String userProfile,
}) async {
  return const [
    RecipeModel(
      id: 'dish_1',
      name: '香辣干锅鸡',
      description: '锅气足，夜里吃更过瘾。',
      ingredients: ['鸡肉', '辣椒'],
      tags: ['辣', '夜宵'],
      source: 'AI Recommendation',
    ),
    RecipeModel(
      id: 'dish_2',
      name: '番茄肥牛锅',
      description: '热一点，汤底浓，适合收口。',
      ingredients: ['番茄', '肥牛'],
      tags: ['热菜', '夜宵'],
      source: 'AI Recommendation',
    ),
    RecipeModel(
      id: 'dish_3',
      name: '麻辣冒菜',
      description: '口味直接，适合今天这口。',
      ingredients: ['牛肉', '蔬菜'],
      tags: ['辣', '锅气'],
      source: 'AI Recommendation',
    ),
  ];
}
