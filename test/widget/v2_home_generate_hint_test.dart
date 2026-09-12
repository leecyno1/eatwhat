import 'package:eatwhat_app/v2/core/data/models/taste_selection_models.dart';
import 'package:eatwhat_app/v2/core/services/v2_speech_input_service.dart';
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
    });
  });

  testWidgets('零选择点「生成建议」弹出引导提示而不是静默无反应', (tester) async {
    var navigated = false;
    await tester.pumpWidget(
      MaterialApp(
        home: HomePage(
          initialCards: const [
            TasteDeckCard(
              id: 'f_spicy',
              label: '辣',
              category: 'flavor',
              accentHexes: ['0xFFF45B33', '0xFFFFB545'],
              iconName: 'local_fire_department',
            ),
          ],
          speechInputService: _FakeSpeechInputService(),
          decisionPageBuilder: (_) {
            navigated = true;
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 80));
    }

    await tester.tap(find.byKey(const ValueKey('home-start-inference-button')));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.text('先收下几个口味气泡，或写一句今天想吃的'), findsOneWidget);
    expect(navigated, isFalse);
  });
}

class _FakeSpeechInputService implements V2SpeechInputService {
  @override
  bool get isListening => false;

  @override
  Future<bool> initialize() async => false;

  @override
  Future<void> startListening({
    required void Function(String transcript, bool isFinal) onResult,
  }) async {}

  @override
  Future<String> stopListening() async => '';
}
