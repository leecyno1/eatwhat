import 'package:eatwhat_app/v2/core/data/models/recipe_model.dart';
import 'package:eatwhat_app/v2/core/data/models/taste_inference_input.dart';
import 'package:eatwhat_app/v2/core/data/models/taste_selection_models.dart';
import 'package:eatwhat_app/v2/core/services/v2_howtocook_recipe_service.dart';
import 'package:eatwhat_app/v2/core/services/v2_phase2_recommendation_service.dart';
import 'package:eatwhat_app/v2/features/decision/decision_page.dart';
import 'package:eatwhat_app/v2/features/home/editorial_home_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('暖食编辑部首页可以完成推荐并抵达结果页', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: EditorialHomePage(
          initialCards: _cards,
          decisionPageBuilder: (input) => DecisionPage(
            input: input,
            recommendationFlowService: _fakeRecommendationService(input),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('editorial-taste-chip-spicy')),
    );
    await tester.enterText(
      find.byKey(const ValueKey('editorial-requirement-input')),
      '今晚想吃热一点，最好很下饭',
    );
    final generate = find.byKey(const ValueKey('editorial-generate-button'));
    await tester.ensureVisible(generate);
    await tester.pump();
    await tester.tap(generate);

    await _pumpUntilFound(
      tester,
      find.byKey(const ValueKey('result-candidate-rail')),
      maxPumps: 42,
    );

    expect(find.byKey(const ValueKey('result-candidate-rail')), findsOneWidget);
    expect(find.text('番茄肥牛锅'), findsWidgets);
  });
}

Future<void> _pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  required int maxPumps,
}) async {
  for (var index = 0; index < maxPumps; index += 1) {
    await tester.pump(const Duration(milliseconds: 250));
    if (finder.evaluate().isNotEmpty) return;
  }
}

V2Phase2RecommendationService _fakeRecommendationService(
  TasteInferenceInput input,
) {
  expect(input.likedTagLabels, contains('热辣'));
  expect(input.freeformRequirement, contains('下饭'));

  return V2Phase2RecommendationService(
    enableAiEnhancement: false,
    localRecommendationLoader: (input, tags, limit) async {
      return const [
        RecipeModel(
          id: 'editorial_result_1',
          name: '番茄肥牛锅',
          description: '热、香、带汤感，适合今晚直接收口。',
          ingredients: ['番茄', '肥牛'],
          tags: ['热菜', '下饭'],
          source: 'unified_db',
        ),
        RecipeModel(
          id: 'editorial_result_2',
          name: '香辣干锅鸡',
          description: '锅气更足，适合想吃更刺激的时候。',
          ingredients: ['鸡肉', '辣椒'],
          tags: ['热辣', '下饭'],
          source: 'unified_db',
        ),
        RecipeModel(
          id: 'editorial_result_3',
          name: '麻辣冒菜',
          description: '口味直接，也适合今晚。',
          ingredients: ['牛肉', '蔬菜'],
          tags: ['麻辣'],
          source: 'unified_db',
        ),
      ];
    },
    howToCookRecipeService: V2HowToCookRecipeService(
      searchLoader: (_, __) async => const [],
      completeLoader: (_) async => null,
      assetIndexLoader: () async => '{"items":[]}',
    ),
  );
}

const _cards = <TasteDeckCard>[
  TasteDeckCard(
    id: 'spicy',
    label: '热辣',
    category: 'flavor',
    accentHexes: ['0xFFC94B2C'],
    iconName: 'local_fire_department',
  ),
  TasteDeckCard(
    id: 'savory',
    label: '下饭',
    category: 'flavor',
    accentHexes: ['0xFF8B695F'],
    iconName: 'restaurant',
  ),
];
