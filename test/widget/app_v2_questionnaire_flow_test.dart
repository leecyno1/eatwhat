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

  Future<void> pumpQuestionnaireFrames(WidgetTester tester) async {
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 120));
    await tester.pump(const Duration(milliseconds: 240));
  }

  testWidgets('AppV2 skips the retired questionnaire and lands on home',
      (tester) async {
    await tester.pumpWidget(buildTestApp());
    await pumpQuestionnaireFrames(tester);

    // The cold-start questionnaire is retired: even with the completed flag
    // unset, the app goes straight to the home stage — preference collection
    // happens through the physical pot, not a form flow.
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
    await pumpQuestionnaireFrames(tester);

    expect(find.text('1 / 8'), findsOneWidget);
    expect(find.text('你更喜欢什么菜系？'), findsWidgets);
    expect(tester.takeException(), isNull);
  });
}
