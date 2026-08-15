import 'package:eatwhat_app/v2/core/data/models/meal_planning_direction.dart';
import 'package:eatwhat_app/v2/core/data/models/taste_inference_input.dart';
import 'package:eatwhat_app/v2/core/data/models/taste_selection_models.dart';
import 'package:eatwhat_app/v2/core/services/v2_speech_input_service.dart';
import 'package:eatwhat_app/v2/features/home/home_page.dart';
import 'package:eatwhat_app/v2/features/home/widgets/taste_signature_panel.dart';
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

  group('方案 4 物理偏好首页', () {
    testWidgets('首屏展示规划方向、分类、透明实体容器和生成入口', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: HomePage(
            initialCards: _cards,
            speechInputService: _FakeSpeechInputService(''),
          ),
        ),
      );
      await _pumpFrames(tester);

      expect(find.text('吃什么'), findsOneWidget);
      expect(find.text('把今天想吃的，放进餐盘'), findsNothing);
      expect(
        find.byKey(const ValueKey('meal-planning-direction-selector')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('filter-budget')), findsOneWidget);
      expect(find.byKey(const ValueKey('filter-party')), findsOneWidget);
      expect(find.byKey(const ValueKey('filter-execution')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('taste-entity-category-tabs')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('filter-strip-scroll-hint')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('taste-physical-habitat')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('taste-physics-ocean')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('taste-entity-selection-summary')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('home-requirement-input')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('home-start-inference-button')),
        findsOneWidget,
      );
      expect(
        tester
            .widget<AnimatedOpacity>(
              find.byKey(const ValueKey('taste-gesture-hint')),
            )
            .opacity,
        1,
      );
      await tester.tap(find.byKey(const ValueKey('taste-physical-habitat')));
      await tester.pump(const Duration(milliseconds: 300));
      expect(
        tester
            .widget<AnimatedOpacity>(
              find.byKey(const ValueKey('taste-gesture-hint')),
            )
            .opacity,
        0,
      );
      expect(find.byKey(const ValueKey('taste-grid-board')), findsNothing);
      expect(tester.takeException(), isNull);
    });

    testWidgets('切换体验向后会进入真实推荐输入', (tester) async {
      TasteInferenceInput? captured;
      await tester.pumpWidget(
        MaterialApp(
          home: HomePage(
            initialCards: _cards,
            speechInputService: _FakeSpeechInputService(''),
            decisionPageBuilder: (input) {
              captured = input;
              return _InputCapturePage(input: input);
            },
          ),
        ),
      );
      await _pumpFrames(tester);

      final directionMenu =
          tester.widget<PopupMenuButton<MealPlanningDirection>>(
        find.descendant(
          of: find.byKey(
            const ValueKey('meal-planning-direction-selector'),
          ),
          matching: find.byType(PopupMenuButton<MealPlanningDirection>),
        ),
      );
      directionMenu.onSelected?.call(MealPlanningDirection.experience);
      await tester.pump();
      await tester.enterText(
        find.byKey(const ValueKey('home-requirement-input')),
        '今晚想吃有新鲜感的菜',
      );
      await tester.pump();
      await tester.tap(
        find.byKey(const ValueKey('home-start-inference-button')),
      );
      await _pumpFrames(tester);

      expect(captured?.planningDirection, MealPlanningDirection.experience);
      expect(captured?.primarySignals, contains('浓郁'));
      expect(find.textContaining('direction=experience'), findsOneWidget);
    });

    testWidgets('历史健康偏好会成为默认规划方向', (tester) async {
      SharedPreferences.setMockInitialValues({
        'v2_home_generation_guide_seen': true,
        'v2_tag_scores_json': '{"i_vegetable":6,"f_light":4}',
      });
      TasteInferenceInput? captured;

      await tester.pumpWidget(
        MaterialApp(
          home: HomePage(
            initialCards: _cards,
            speechInputService: _FakeSpeechInputService(''),
            decisionPageBuilder: (input) {
              captured = input;
              return _InputCapturePage(input: input);
            },
          ),
        ),
      );
      await _pumpFrames(tester, count: 12);

      expect(find.text('习惯 · 健康向'), findsOneWidget);

      await tester.enterText(
        find.byKey(const ValueKey('home-requirement-input')),
        '一人晚餐',
      );
      await tester.pump();
      await tester.tap(
        find.byKey(const ValueKey('home-start-inference-button')),
      );
      await _pumpFrames(tester);

      expect(captured?.planningDirection, MealPlanningDirection.health);
    });

    testWidgets('快捷条件仍会写入结构化约束', (tester) async {
      TasteInferenceInput? captured;
      await tester.pumpWidget(
        MaterialApp(
          home: HomePage(
            initialCards: _cards,
            speechInputService: _FakeSpeechInputService(''),
            decisionPageBuilder: (input) {
              captured = input;
              return _InputCapturePage(input: input);
            },
          ),
        ),
      );
      await _pumpFrames(tester);

      tester
          .widget<PopupMenuButton<int>>(
            find.descendant(
              of: find.byKey(const ValueKey('filter-budget')),
              matching: find.byType(PopupMenuButton<int>),
            ),
          )
          .onSelected
          ?.call(30);
      await tester.pump();
      expect(find.text('预算 · 30元'), findsOneWidget);
      tester
          .widget<PopupMenuButton<int>>(
            find.descendant(
              of: find.byKey(const ValueKey('filter-party')),
              matching: find.byType(PopupMenuButton<int>),
            ),
          )
          .onSelected
          ?.call(1);
      await tester.pump();
      expect(find.text('预算 · 30元'), findsOneWidget);
      expect(find.text('人数 · 1人'), findsOneWidget);
      tester
          .widget<PopupMenuButton<TasteExecutionPreference>>(
            find.descendant(
              of: find.byKey(const ValueKey('filter-execution')),
              matching: find.byType(PopupMenuButton<TasteExecutionPreference>),
            ),
          )
          .onSelected
          ?.call(TasteExecutionPreference.delivery);
      await tester.pump();
      expect(find.text('预算 · 30元'), findsOneWidget);
      expect(find.text('人数 · 1人'), findsOneWidget);
      await tester.tap(
        find.byKey(const ValueKey('home-start-inference-button')),
      );
      await _pumpFrames(tester);

      expect(captured?.structuredConstraints.maxBudgetYuan, 30);
      expect(captured?.structuredConstraints.partySize, 1);
      expect(
        captured?.structuredConstraints.executionPreference,
        TasteExecutionPreference.delivery,
      );
    });

    testWidgets('选择摘要可以进入口味签名审核页', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: HomePage(
            initialCards: _cards,
            speechInputService: _FakeSpeechInputService(''),
          ),
        ),
      );
      await _pumpFrames(tester);

      await tester.tap(find.byKey(const ValueKey('taste-signature-button')));
      await _pumpFrames(tester);

      expect(
        find.byKey(const ValueKey('taste-signature-face')),
        findsOneWidget,
      );
      expect(find.text('你的口味签名'), findsOneWidget);
    });

    testWidgets('口味签名可以直接删除喜欢项', (tester) async {
      String? removedId;
      final session = TasteDeckSessionState.initial(
        deck: _cards,
        cardDeckSeed: 1,
      ).copyWith(likedTagIds: const ['f_spicy']);

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TasteSignaturePanel(
              session: session,
              onBack: () {},
              onStartInference: () {},
              onRemoveLiked: (id) => removedId = id,
              onRemoveDisliked: (_) {},
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(const ValueKey('remove-taste-f_spicy')));

      expect(removedId, 'f_spicy');
    });

    testWidgets('窄屏下物理首页不出现布局异常', (tester) async {
      tester.view.physicalSize = const Size(1179, 2556);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: HomePage(
            initialCards: _cards,
            speechInputService: _FakeSpeechInputService(''),
          ),
        ),
      );
      await _pumpFrames(tester, count: 14);

      expect(
        find.byKey(const ValueKey('taste-physical-habitat')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  });
}

Future<void> _pumpFrames(
  WidgetTester tester, {
  int count = 8,
  Duration duration = const Duration(milliseconds: 80),
}) async {
  for (var index = 0; index < count; index++) {
    await tester.pump(duration);
  }
}

class _FakeSpeechInputService implements V2SpeechInputService {
  _FakeSpeechInputService(this.transcript);

  final String transcript;
  bool _isListening = false;

  @override
  bool get isListening => _isListening;

  @override
  Future<bool> initialize() async => true;

  @override
  Future<void> startListening({
    required void Function(String transcript, bool isFinal) onResult,
  }) async {
    _isListening = true;
    onResult(transcript, true);
  }

  @override
  Future<String> stopListening() async {
    _isListening = false;
    return transcript;
  }
}

class _InputCapturePage extends StatelessWidget {
  const _InputCapturePage({required this.input});

  final TasteInferenceInput input;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Text(
        'direction=${input.planningDirection.name} '
        'freeform=${input.freeformRequirement}',
      ),
    );
  }
}

const _cards = <TasteDeckCard>[
  TasteDeckCard(
    id: 'f_spicy',
    label: '辣',
    category: 'flavor',
    accentHexes: ['0xFFF45B33', '0xFFFFB545'],
    iconName: 'local_fire_department',
  ),
  TasteDeckCard(
    id: 'i_vegetable',
    label: '蔬菜',
    category: 'ingredient',
    accentHexes: ['0xFF2F9B4F', '0xFF7ABF88'],
    iconName: 'eco',
  ),
  TasteDeckCard(
    id: 'i_egg',
    label: '鸡蛋',
    category: 'ingredient',
    accentHexes: ['0xFFFFB545', '0xFFFFE082'],
    iconName: 'egg_alt',
  ),
  TasteDeckCard(
    id: 'd_low_carb',
    label: '低碳',
    category: 'dietary',
    accentHexes: ['0xFF2F9B4F', '0xFFD3E7D5'],
    iconName: 'health_and_safety',
  ),
  TasteDeckCard(
    id: 'c_sichuan',
    label: '川菜',
    category: 'cuisine',
    accentHexes: ['0xFFE4513F', '0xFFF45B33'],
    iconName: 'ramen_dining',
  ),
  TasteDeckCard(
    id: 'scene_dinner',
    label: '晚餐',
    category: 'scene',
    accentHexes: ['0xFF2F9B4F', '0xFF45A6D8'],
    iconName: 'dinner_dining',
  ),
  TasteDeckCard(
    id: 'f_light',
    label: '清淡',
    category: 'flavor',
    accentHexes: ['0xFF7ABF88', '0xFFE7F5E8'],
    iconName: 'spa',
  ),
  TasteDeckCard(
    id: 'd_high_protein',
    label: '高蛋白',
    category: 'dietary',
    accentHexes: ['0xFFFFB545', '0xFF2F9B4F'],
    iconName: 'fitness_center',
  ),
];
