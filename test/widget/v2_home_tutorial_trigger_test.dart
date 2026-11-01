import 'package:eatwhat_app/v2/core/data/models/taste_selection_models.dart';
import 'package:eatwhat_app/v2/core/services/v2_speech_input_service.dart';
import 'package:eatwhat_app/v2/features/home/home_page.dart';
import 'package:eatwhat_app/v2/features/onboarding/onboarding_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../test_bootstrap.dart';

void main() {
  setUpAll(() async {
    await bootstrapTestEnvironment();
  });

  testWidgets('首次进入显示新教学，跳过后持久化且不再出现', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      MaterialApp(
        home: HomePage(
          initialCards: _cards,
          speechInputService: _FakeSpeechInputService(),
        ),
      ),
    );
    await _pumpFrames(tester);

    expect(
      find.byKey(const ValueKey('handfeel-tutorial')),
      findsOneWidget,
    );
    expect(find.text('选出今天想吃的方向'), findsNothing);

    await tester.tap(
      find.byKey(const ValueKey('handfeel-tutorial-skip')),
    );
    // 首页物理舞台会持续调度帧，不能用 pumpAndSettle。
    await _pumpFrames(tester);

    expect(
      find.byKey(const ValueKey('handfeel-tutorial')),
      findsNothing,
    );
    final prefs = await SharedPreferences.getInstance();
    expect(
      prefs.getBool(OnboardingService.handfeelTutorialSeenKey),
      isTrue,
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.pumpWidget(
      MaterialApp(
        home: HomePage(
          initialCards: _cards,
          speechInputService: _FakeSpeechInputService(),
        ),
      ),
    );
    await _pumpFrames(tester);

    expect(
      find.byKey(const ValueKey('handfeel-tutorial')),
      findsNothing,
    );
  });
}

Future<void> _pumpFrames(WidgetTester tester, {int frames = 12}) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 80));
  }
}

const _cards = [
  TasteDeckCard(
    id: 'f_spicy',
    label: '辣',
    category: 'flavor',
    accentHexes: ['0xFFF45B33', '0xFFFFB545'],
    iconName: 'local_fire_department',
  ),
];

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
