import 'package:eatwhat_app/v2/features/style_lab/food_style_lab_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Widget buildApp(Widget home) {
    return MaterialApp(
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'PingFang SC',
      ),
      home: home,
    );
  }

  testWidgets('三套美食 UI 模板均可在手机视口正常渲染', (tester) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    for (final concept in FoodStyleConcept.values) {
      await tester.pumpWidget(
        buildApp(FoodHomeConceptPage(concept: concept)),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull, reason: concept.title);
    }
  });

  testWidgets('视觉实验室可以在三套模板之间切换', (tester) async {
    await tester.pumpWidget(buildApp(const FoodStyleLabPage()));
    await tester.pumpAndSettle();

    expect(
      find.byKey(const ValueKey('warm-editorial-template')),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const ValueKey('style-concept-streetCanteen')),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('street-canteen-template')),
      findsOneWidget,
    );

    await tester.tap(
      find.byKey(const ValueKey('style-concept-seasonalFresh')),
    );
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('seasonal-fresh-template')),
      findsOneWidget,
    );
  });

  testWidgets('口味卡可选择，生成按钮会给出明确反馈', (tester) async {
    await tester.pumpWidget(
      buildApp(
        const FoodHomeConceptPage(
          concept: FoodStyleConcept.warmEditorial,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('editorial-taste-清淡')));
    await tester.pump();
    expect(find.text('已选 3'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('warm-editorial-generate')));
    await tester.pump();
    expect(find.textContaining('先为你推荐：麻婆豆腐'), findsOneWidget);
  });
}
