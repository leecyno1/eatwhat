import 'package:eatwhat_app/v2/core/data/models/taste_inference_input.dart';
import 'package:eatwhat_app/v2/core/data/models/taste_selection_models.dart';
import 'package:eatwhat_app/v2/core/services/v2_speech_input_service.dart';
import 'package:eatwhat_app/v2/features/home/editorial_home_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('正式首页呈现暖食编辑部品牌与清晰决策结构', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: EditorialHomePage(initialCards: _cards),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('editorial-home-page')), findsOneWidget);
    expect(find.text('吃什么'), findsOneWidget);
    expect(find.text('今晚，\n吃点真的想吃的'), findsOneWidget);
    expect(find.byKey(const ValueKey('editorial-hero-card')), findsOneWidget);
    expect(
      find.byKey(const ValueKey('editorial-requirement-input')),
      findsOneWidget,
    );
    expect(
      find.byKey(const ValueKey('editorial-generate-button')),
      findsOneWidget,
    );
    expect(find.text('麻婆豆腐'), findsOneWidget);
  });

  testWidgets('点击喜欢、长按排除并合并结构化约束', (tester) async {
    TasteInferenceInput? captured;

    await tester.pumpWidget(
      MaterialApp(
        home: EditorialHomePage(
          initialCards: _cards,
          decisionPageBuilder: (input) {
            captured = input;
            return const Scaffold(body: Text('已进入生成流程'));
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(
      find.byKey(const ValueKey('editorial-taste-chip-spicy')),
    );
    await tester.pump();
    await tester.longPress(
      find.byKey(const ValueKey('editorial-taste-chip-sweet')),
    );
    await tester.pump();
    await _tapVisible(
      tester,
      find.byKey(const ValueKey('editorial-constraint-chip-30 元内')),
    );
    await _tapVisible(
      tester,
      find.byKey(const ValueKey('editorial-constraint-chip-叫外卖')),
    );
    await tester.enterText(
      find.byKey(const ValueKey('editorial-requirement-input')),
      '一个人，想吃热的',
    );

    expect(find.text('喜欢 1 · 排除 1'), findsOneWidget);

    await _tapVisible(
      tester,
      find.byKey(const ValueKey('editorial-generate-button')),
    );
    await tester.pumpAndSettle();

    expect(find.text('已进入生成流程'), findsOneWidget);
    expect(captured, isNotNull);
    expect(captured!.likedTagIds, contains('spicy'));
    expect(captured!.dislikedTagIds, contains('sweet'));
    expect(captured!.freeformRequirement, contains('想吃热的'));
    expect(captured!.structuredConstraints.maxBudgetYuan, 30);
    expect(
      captured!.structuredConstraints.executionPreference,
      TasteExecutionPreference.delivery,
    );
  });

  testWidgets('没有口味或文字时不会误启动生成', (tester) async {
    var opened = false;

    await tester.pumpWidget(
      MaterialApp(
        home: EditorialHomePage(
          initialCards: _cards,
          decisionPageBuilder: (_) {
            opened = true;
            return const SizedBox.shrink();
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    await _tapVisible(
      tester,
      find.byKey(const ValueKey('editorial-generate-button')),
    );
    await tester.pump();

    expect(opened, isFalse);
    expect(find.text('先选一个口味，或者说说今天想吃什么'), findsOneWidget);
  });

  testWidgets('语音输入不可用时给出文字输入兜底', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: EditorialHomePage(
          initialCards: _cards,
          speechInputService: _UnavailableSpeechService(),
        ),
      ),
    );
    await tester.pumpAndSettle();

    await _tapVisible(
      tester,
      find.byKey(const ValueKey('editorial-voice-button')),
    );
    await tester.pump();

    expect(find.text('语音暂时不可用，可以直接输入文字'), findsOneWidget);
  });

  testWidgets('窄屏设备下正式首页无布局溢出', (tester) async {
    tester.view.physicalSize = const Size(320, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        home: EditorialHomePage(initialCards: _cards),
      ),
    );
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
  });
}

Future<void> _tapVisible(WidgetTester tester, Finder finder) async {
  await tester.ensureVisible(finder);
  await tester.pump();
  await tester.tap(finder);
  await tester.pump();
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
    id: 'sweet',
    label: '甜口',
    category: 'flavor',
    accentHexes: ['0xFFE6A44A'],
    iconName: 'bakery_dining',
  ),
  TasteDeckCard(
    id: 'soup',
    label: '汤汤水水',
    category: 'scene',
    accentHexes: ['0xFF59745D'],
    iconName: 'soup_kitchen',
  ),
  TasteDeckCard(
    id: 'meat',
    label: '有肉',
    category: 'ingredient',
    accentHexes: ['0xFF8B695F'],
    iconName: 'restaurant',
  ),
  TasteDeckCard(
    id: 'light',
    label: '清淡',
    category: 'flavor',
    accentHexes: ['0xFF8DA38B'],
    iconName: 'eco',
  ),
  TasteDeckCard(
    id: 'crispy',
    label: '酥脆',
    category: 'texture',
    accentHexes: ['0xFFE6A44A'],
    iconName: 'restaurant_menu',
  ),
];

class _UnavailableSpeechService implements V2SpeechInputService {
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
