import 'package:eatwhat_app/v2/app_v2.dart';
import 'package:eatwhat_app/v2/features/onboarding/cold_start_questionnaire_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({
      'cold_start_questionnaire_completed': false,
      'has_seen_onboarding_v2': true,
      'v2_home_generation_guide_seen': true,
      'v2_home_flip_hint_seen': true,
    });
  });

  Widget buildTestApp() {
    return const ProviderScope(
      child: AppV2(),
    );
  }

  testWidgets('AppV2 closes the cold-start questionnaire after skipping',
      (tester) async {
    await tester.pumpWidget(buildTestApp());
    await tester.pumpAndSettle();

    expect(find.text('你更喜欢什么菜系？'), findsWidgets);

    await tester.tap(find.text('跳过'));
    await tester.pumpAndSettle();
    expect(find.text('跳过问卷'), findsOneWidget);

    await tester.tap(find.text('确定跳过'));
    await tester.pumpAndSettle();

    expect(find.text('你更喜欢什么菜系？'), findsNothing);
    expect(find.byType(MaterialApp), findsOneWidget);
  });

  testWidgets('ColdStartQuestionnairePage renders the V2 constraint flow',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(390, 844));
    addTearDown(() => tester.binding.setSurfaceSize(null));

    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(375, 812),
        builder: (context, child) => MaterialApp(
          home: ColdStartQuestionnairePage(
            onCompleted: () {},
            onSkipped: () {},
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('1 / 8'), findsOneWidget);
    expect(find.text('你更喜欢什么菜系？'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
