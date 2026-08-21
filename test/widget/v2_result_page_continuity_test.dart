import 'package:eatwhat_app/v2/core/data/models/recipe_model.dart';
import 'package:eatwhat_app/v2/core/data/models/taste_inference_input.dart';
import 'package:eatwhat_app/v2/features/result/result_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('ResultPage 延续暖色编辑场景并提供中文化执行入口', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ResultPage(
          recommendations: [
            RecipeModel(
              id: 'r1',
              name: '番茄肥牛锅',
              description: '热一点，有锅气，适合夜里吃。',
            ),
          ],
          inferenceInput: TasteInferenceInput(
            likedTagIds: ['f_spicy'],
            likedTagLabels: ['辣'],
            dislikedTagIds: ['f_sweet'],
            dislikedTagLabels: ['甜'],
            skippedTagIds: ['scene_party'],
            skippedTagLabels: ['聚会'],
            freeformRequirement: '今晚想吃热一点，有锅气',
            historyPreferenceSummary: {'f_spicy': 3},
          ),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 700));

    // The gold single-screen stage: no editorial header, no mode tabs,
    // no scrolling chrome — just the hero, the reason line, three gold
    // action cards, and the confirm bar.
    expect(find.text('TASTE BOARD'), findsNothing);
    expect(find.text('RECOMMENDED DISH'), findsNothing);
    expect(find.text('NOW'), findsNothing);
    expect(find.text('今日推荐板'), findsNothing);
    expect(find.byKey(const ValueKey('result-stage-shell')), findsNothing);
    expect(find.text('今晚这口，替你收好了'), findsNothing);
    expect(find.byKey(const ValueKey('result-mode-single')), findsNothing);
    expect(find.byKey(const ValueKey('result-mode-meal')), findsNothing);
    expect(find.text('暖食编辑部'), findsNothing);
    expect(find.byKey(const ValueKey('result-gold-reason-line')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('result-favorite-toggle')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('result-execution-shortcuts')),
        findsOneWidget);
    expect(find.byKey(const ValueKey('result-execution-cook')), findsOneWidget);
    expect(find.byKey(const ValueKey('result-execution-delivery')),
        findsOneWidget);
    expect(
        find.byKey(const ValueKey('result-execution-dine-in')), findsOneWidget);
    expect(find.text('就吃这个'), findsOneWidget);
  });
}
