import 'package:eatwhat_app/v2/features/style_lab/young_food_style_lab_page.dart';
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

  testWidgets('三套年轻品牌模板均可在手机视口正常渲染', (tester) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    for (final concept in YoungFoodStyleConcept.values) {
      await tester.pumpWidget(
        buildApp(YoungFoodHomeConceptPage(concept: concept)),
      );
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull, reason: concept.title);
    }
  });

  testWidgets('年轻品牌实验室可以在 D E F 三套模板之间切换', (tester) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(buildApp(const YoungFoodStyleLabPage()));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('meal-fm-template')), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('young-style-concept-biteLab')),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('bite-lab-template')), findsOneWidget);

    await tester.tap(
      find.byKey(const ValueKey('young-style-concept-biteClub')),
    );
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('bite-club-template')), findsOneWidget);
  });

  testWidgets('年轻模板支持口味选择与生成反馈', (tester) async {
    await tester.pumpWidget(
      buildApp(
        const YoungFoodHomeConceptPage(
          concept: YoungFoodStyleConcept.mealFm,
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.byKey(const ValueKey('fm-taste-碳水')));
    await tester.pump();
    expect(find.text('3 个信号已接收'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('meal-fm-generate')));
    await tester.pump();
    expect(find.textContaining('今天先锁定：热辣炸酱面'), findsOneWidget);
  });
}
