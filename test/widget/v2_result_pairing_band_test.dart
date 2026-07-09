import 'package:eatwhat_app/v2/core/data/models/recipe_model.dart';
import 'package:eatwhat_app/v2/features/result/result_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('ResultPage 展示饮品和配菜搭配带', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ResultPage(
          recommendations: [
            RecipeModel(
              id: 'r1',
              name: '番茄肥牛锅',
              description: '热一点，有锅气，适合夜里吃。',
              ingredients: ['肥牛', '番茄', '金针菇'],
            ),
          ],
          fallbackTags: ['辣', '火锅', '夜宵'],
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 900));

    expect(find.byKey(const ValueKey('result-pairing-band')), findsOneWidget);
    expect(find.text('顺手搭一套'), findsOneWidget);
    expect(find.text('饮品'), findsOneWidget);
    expect(find.text('配菜'), findsOneWidget);
  });
}
