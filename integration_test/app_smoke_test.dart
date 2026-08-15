import 'package:eatwhat_app/v2/app_v2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'cold_start_questionnaire_completed': true,
      'has_seen_onboarding_v2': true,
      'v2_home_generation_guide_seen': true,
      'v2_home_flip_hint_seen': true,
    });
  });

  testWidgets('V2 app launches to the taste board', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: AppV2(),
      ),
    );
    await tester.pump(const Duration(seconds: 2));

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(
        find.byKey(const ValueKey('taste-card-stage-shell')), findsOneWidget);
    expect(
        find.byKey(const ValueKey('home-requirement-input')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
