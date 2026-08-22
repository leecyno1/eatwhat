import 'package:eatwhat_app/v2/core/data/models/recipe_model.dart';
import 'package:eatwhat_app/v2/core/data/models/taste_inference_input.dart';
import 'package:eatwhat_app/v2/core/services/v2_howtocook_recipe_service.dart';
import 'package:eatwhat_app/v2/core/services/v2_phase2_recommendation_service.dart';
import 'package:eatwhat_app/v2/features/decision/decision_page.dart';
import 'package:eatwhat_app/v2/features/home/home_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../test_bootstrap.dart';

void main() {
  setUpAll(() async {
    await bootstrapTestEnvironment();
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'v2_home_generation_guide_seen': true,
      'v2_home_flip_hint_seen': true,
    });
  });

  testWidgets('HomePage 可以进入 DecisionPage 并自动抵达 ResultPage', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: HomePage(
          decisionPageBuilder: (input) => DecisionPage(
            input: input,
            recommendationFlowService: _fakeRecommendationFlowService(input),
          ),
        ),
      ),
    );

    await _pumpUntilFound(
      tester,
      find.byKey(const ValueKey('taste-physical-habitat')),
      step: const Duration(milliseconds: 120),
      maxPumps: 20,
    );

    await tester.enterText(
      find.byKey(const ValueKey('home-requirement-input')),
      '今晚想吃热一点，最好有锅气，别太甜',
    );
    await tester.pump();

    await tester.tap(find.byKey(const ValueKey('home-start-inference-button')));
    await _pumpUntilFound(
      tester,
      find.byKey(const ValueKey('result-dish-carousel')),
      step: const Duration(milliseconds: 250),
      maxPumps: 36,
    );

    expect(find.byKey(const ValueKey('result-dish-carousel')), findsOneWidget);
    expect(find.text('番茄肥牛锅'), findsWidgets);

    // The gold stage has no in-app back button; a system back returns to
    // the home stage.
    await tester.binding.handlePopRoute();
    await tester.pump(const Duration(milliseconds: 400));

    expect(find.text('正在准备推荐'), findsNothing);
    expect(
      find.byKey(const ValueKey('home-start-inference-button')),
      findsOneWidget,
    );
  });
}

Future<void> _pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  required Duration step,
  required int maxPumps,
}) async {
  for (var i = 0; i < maxPumps; i += 1) {
    await tester.pump(step);
    if (finder.evaluate().isNotEmpty) return;
  }
}

V2Phase2RecommendationService _fakeRecommendationFlowService(
  TasteInferenceInput input,
) {
  expect(input.freeformRequirement, contains('锅气'));

  return V2Phase2RecommendationService(
    enableAiEnhancement: false,
    localRecommendationLoader: (input, tags, limit) async {
      return const [
        RecipeModel(
          id: 'dish_2',
          name: '番茄肥牛锅',
          description: '热菜、带汤感，适合今晚直接收口。',
          ingredients: ['番茄', '肥牛'],
          tags: ['热菜', '夜宵'],
          source: 'unified_db',
        ),
        RecipeModel(
          id: 'dish_1',
          name: '香辣干锅鸡',
          description: '锅气和辣味更冲，适合想吃更刺激一点的时候。',
          ingredients: ['鸡肉', '辣椒'],
          tags: ['辣', '夜宵'],
          source: 'unified_db',
        ),
        RecipeModel(
          id: 'dish_3',
          name: '麻辣冒菜',
          description: '口味直接，适合今天这口。',
          ingredients: ['牛肉', '蔬菜'],
          tags: ['辣', '锅气'],
          source: 'unified_db',
        ),
      ];
    },
    howToCookRecipeService: _fakeHowToCookService(),
  );
}

V2HowToCookRecipeService _fakeHowToCookService() {
  return V2HowToCookRecipeService(
    searchLoader: (query, limit) async => const [],
    completeLoader: (recipeId) async => null,
    assetIndexLoader: () async => '{"items":[]}',
  );
}
