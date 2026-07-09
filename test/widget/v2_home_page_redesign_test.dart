import 'package:eatwhat_app/v2/core/data/models/taste_inference_input.dart';
import 'package:eatwhat_app/v2/core/data/models/taste_selection_models.dart';
import 'package:eatwhat_app/v2/core/services/v2_speech_input_service.dart';
import 'package:eatwhat_app/v2/features/home/home_page.dart';
import 'package:eatwhat_app/v2/features/home/widgets/taste_card_deck.dart';
import 'package:eatwhat_app/v2/features/home/widgets/taste_signature_panel.dart';
import 'package:flutter/gestures.dart';
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

  group('V2 首页九宫格首屏', () {
    testWidgets('首页首屏压缩为牌桌、底部入口和底部输入', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HomePage(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 180));

      expect(find.text('EDITORIAL TASTE BOARD'), findsNothing);
      expect(find.text('SWIPE TO CURATE'), findsNothing);
      expect(find.text('DEAL'), findsNothing);
      expect(find.text('TASTE'), findsNothing);
      expect(find.text('今日口味板'), findsNothing);
      expect(find.text('少想一点，先吃一口'), findsNothing);
      expect(find.text('今晚先看这口'), findsNothing);
      expect(find.text('番茄肥牛锅'), findsNothing);
      expect(find.text('上次吃得很爽'), findsNothing);
      expect(find.text('再来一口'), findsNothing);
      expect(
        find.byKey(const ValueKey('home-appetite-preview-card')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('home-recent-success-entry')),
        findsNothing,
      );
      expect(find.text('开吃'), findsNothing);
      expect(find.text('偏好'), findsNothing);
      expect(find.text('收藏'), findsOneWidget);
      expect(find.text('吃过'), findsOneWidget);
      expect(find.text('限制'), findsOneWidget);
      expect(find.text('签名'), findsWidgets);
      expect(
        find.byKey(const ValueKey('home-requirement-input')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('taste-stage-corner-metrics')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('taste-signature-button')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('taste-stage-gesture-legend')),
        findsNothing,
      );
      expect(
        find.byKey(const ValueKey('taste-gesture-control-tray')),
        findsNothing,
      );
    });

    testWidgets('底部吃过入口在存在历史记录时直达推荐链路', (tester) async {
      SharedPreferences.setMockInitialValues({
        'v2_home_generation_guide_seen': true,
        'v2_home_flip_hint_seen': true,
        'v2_recent_recipe_ids': ['dish_88'],
      });

      await tester.pumpWidget(
        MaterialApp(
          home: HomePage(
            speechInputService: _FakeSpeechInputService(''),
            decisionPageBuilder: (input) {
              return _InputCapturePage(input: input);
            },
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 180));
      await _pumpTasteBoardFrames(tester);

      await tester.tap(find.text('吃过'));
      await _pumpTasteBoardFrames(tester);

      expect(find.textContaining('freeform=复用上次吃得很爽的选择'), findsOneWidget);
      expect(find.textContaining('labels=最近成功'), findsOneWidget);
    });

    testWidgets('底部限制入口会快速写入时间约束', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: HomePage(
            speechInputService: _FakeSpeechInputService(''),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 180));

      await tester.tap(find.text('限制'));
      await tester.pump();

      final field = tester.widget<TextField>(
        find.byKey(const ValueKey('home-requirement-input')),
      );
      expect(field.controller?.text, contains('15 分钟内'));
    });

    testWidgets('窄屏设备下首页不应出现卡片溢出异常', (tester) async {
      tester.view.physicalSize = const Size(1179, 2556);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          home: HomePage(
            speechInputService: _FakeSpeechInputService(''),
          ),
        ),
      );
      await _pumpTasteBoardFrames(tester);

      expect(tester.takeException(), isNull);
    });

    testWidgets('首页以九宫格卡牌为核心，不再展示单张堆叠卡组', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HomePage(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 180));
      await _pumpUntilFound(
          tester, find.byKey(const ValueKey('taste-grid-board')));

      expect(
        find.byKey(const ValueKey('taste-card-stage-shell')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('home-requirement-mode-pill')),
        findsOneWidget,
      );
      expect(find.byKey(const ValueKey('taste-grid-board')), findsOneWidget);
      expect(
        find.byKey(const ValueKey('taste-board-corner-markers')),
        findsOneWidget,
      );
      expect(find.textContaining('1/'), findsOneWidget);
      expect(_gridCardFinder(), findsNWidgets(TasteDeckSessionState.pageSize));
      expect(_gridSlotFinder(), findsNWidgets(TasteDeckSessionState.pageSize));
      expect(_dealEntryFinder(), findsNWidgets(TasteDeckSessionState.pageSize));
      expect(find.byKey(const ValueKey('taste-board-progress-dots')),
          findsOneWidget);
      expect(find.byKey(const ValueKey('taste-stage-gesture-legend')),
          findsNothing);
      expect(
        find.byKey(const ValueKey('taste-gesture-control-tray')),
        findsNothing,
      );
      expect(find.byKey(const ValueKey('taste-deck-top-card')), findsNothing);
    });

    testWidgets('首页常用限制胶囊会写入本轮需求', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: HomePage(
            speechInputService: _FakeSpeechInputService(''),
            decisionPageBuilder: (input) {
              return _InputCapturePage(input: input);
            },
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 180));
      await _pumpUntilFound(tester, _gridCardFinder());

      expect(
        find.byKey(const ValueKey('home-constraint-chip-30 元内')),
        findsOneWidget,
      );

      await tester
          .tap(find.byKey(const ValueKey('home-constraint-chip-30 元内')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('home-constraint-chip-1 人')));
      await tester.pump();

      final field = tester.widget<TextField>(
        find.byKey(const ValueKey('home-requirement-input')),
      );
      expect(field.controller?.text, contains('30 元内'));
      expect(field.controller?.text, contains('1 人'));

      await _pumpUntilFound(
        tester,
        find.byKey(const ValueKey('taste-signature-button')),
      );
      await tester.tap(find.byKey(const ValueKey('taste-signature-button')));
      await _pumpTasteBoardFrames(tester);
      await tester.tap(find.byKey(const ValueKey('start-inference-button')));
      await _pumpTasteBoardFrames(tester);

      expect(find.textContaining('budget=30'), findsOneWidget);
      expect(find.textContaining('party=1'), findsOneWidget);
    });

    testWidgets('首页执行方式胶囊会写入结构化约束', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: HomePage(
            speechInputService: _FakeSpeechInputService(''),
            decisionPageBuilder: (input) {
              return _InputCapturePage(input: input);
            },
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 180));
      await _pumpUntilFound(tester, _gridCardFinder());

      await tester.tap(find.byKey(const ValueKey('home-constraint-chip-叫外卖')));
      await tester.pump();

      final field = tester.widget<TextField>(
        find.byKey(const ValueKey('home-requirement-input')),
      );
      expect(field.controller?.text, contains('叫外卖'));

      await tester.tap(find.byKey(const ValueKey('taste-signature-button')));
      await _pumpTasteBoardFrames(tester);
      await tester.tap(find.byKey(const ValueKey('start-inference-button')));
      await _pumpTasteBoardFrames(tester);

      expect(find.textContaining('execution=delivery'), findsOneWidget);
    });

    testWidgets('首页附近胶囊会写入位置约束', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: HomePage(
            speechInputService: _FakeSpeechInputService(''),
            decisionPageBuilder: (input) {
              return _InputCapturePage(input: input);
            },
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 180));
      await _pumpUntilFound(tester, _gridCardFinder());

      await tester.tap(find.byKey(const ValueKey('home-constraint-chip-附近')));
      await tester.pump();

      final field = tester.widget<TextField>(
        find.byKey(const ValueKey('home-requirement-input')),
      );
      expect(field.controller?.text, contains('附近'));

      await tester.tap(find.byKey(const ValueKey('taste-signature-button')));
      await _pumpTasteBoardFrames(tester);
      await tester.tap(find.byKey(const ValueKey('start-inference-button')));
      await _pumpTasteBoardFrames(tester);

      expect(find.textContaining('location=nearby'), findsOneWidget);
    });

    testWidgets('单卡上滑后可以进入口味签名 Face 2', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HomePage(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 180));

      await tester.drag(
        _gridCardFinder().first,
        const Offset(0, -220),
      );
      await _pumpTasteBoardFrames(tester);

      await tester.tap(find.byKey(const ValueKey('taste-signature-button')));
      await _pumpTasteBoardFrames(tester);

      expect(
        find.byKey(const ValueKey('taste-signature-face')),
        findsOneWidget,
      );
      expect(find.text('你的口味签名'), findsOneWidget);
      expect(find.textContaining('喜欢'), findsWidgets);
    });

    testWidgets('单卡上滑提交后会补进新卡，不会在九宫格留下空位', (tester) async {
      final cards = List.generate(
        17,
        (index) => _sampleCard('c$index', '标签$index', 'flavor'),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox.expand(
              child: _DeckHarness(cards: cards),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byKey(const ValueKey('taste-grid-card-c0')), findsOneWidget);
      expect(find.byKey(const ValueKey('taste-grid-card-c16')), findsNothing);
      expect(_gridCardFinder(), findsNWidgets(TasteDeckSessionState.pageSize));

      await tester.drag(
        find.byKey(const ValueKey('taste-grid-card-c0')),
        const Offset(0, -220),
      );
      await _pumpTasteBoardFrames(tester);

      expect(find.byKey(const ValueKey('taste-grid-card-c0')), findsNothing);
      expect(find.byKey(const ValueKey('taste-grid-card-c16')), findsOneWidget);
      expect(_gridCardFinder(), findsNWidgets(TasteDeckSessionState.pageSize));
    });

    testWidgets('单卡补牌时只替换当前卡位，其余卡位位置保持不动', (tester) async {
      final cards = List.generate(
        20,
        (index) => _sampleCard('c$index', '标签$index', 'flavor'),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox.expand(
              child: _DeckHarness(cards: cards),
            ),
          ),
        ),
      );
      await tester.pump();

      final unaffectedBefore = <int, Rect>{
        1: tester.getRect(find.byKey(const ValueKey('taste-grid-slot-1'))),
        4: tester.getRect(find.byKey(const ValueKey('taste-grid-slot-4'))),
        8: tester.getRect(find.byKey(const ValueKey('taste-grid-slot-8'))),
      };

      await tester.drag(
        find.byKey(const ValueKey('taste-grid-card-c0')),
        const Offset(0, -220),
      );
      await _pumpTasteBoardFrames(tester);

      expect(find.byKey(const ValueKey('taste-grid-card-c16')), findsOneWidget);
      expect(
        tester.getRect(find.byKey(const ValueKey('taste-grid-slot-1'))),
        unaffectedBefore[1],
      );
      expect(
        tester.getRect(find.byKey(const ValueKey('taste-grid-slot-4'))),
        unaffectedBefore[4],
      );
      expect(
        tester.getRect(find.byKey(const ValueKey('taste-grid-slot-8'))),
        unaffectedBefore[8],
      );
    });

    testWidgets('单卡下滑提交后会记入口味签名的排除项', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HomePage(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 180));

      await tester.drag(
        _gridCardFinder().first,
        const Offset(0, 220),
      );
      await _pumpTasteBoardFrames(tester);

      await tester.tap(find.byKey(const ValueKey('taste-signature-button')));
      await _pumpTasteBoardFrames(tester);

      expect(
          find.byKey(const ValueKey('taste-signature-face')), findsOneWidget);
      expect(find.textContaining('不要'), findsWidgets);
    });

    testWidgets('点按卡牌后会翻到背面展示说明', (tester) async {
      final cards = [
        _sampleCard('f1', '辣', 'flavor'),
        for (var index = 1; index < TasteDeckSessionState.pageSize; index++)
          _sampleCard(
              'c$index', '标签$index', index.isEven ? 'scene' : 'ingredient'),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox.expand(
              child: TasteCardDeck(
                cards: cards,
                session: TasteDeckSessionState.initial(
                  deck: cards,
                  cardDeckSeed: 1,
                ),
                onReact: (_, __) {},
                onAdvancePage: () {},
                onVoiceStart: () {},
                onVoiceEnd: () {},
                isListening: false,
                showFlipHint: false,
                onFirstFlip: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(
        find.byKey(const ValueKey('taste-card-front-flavor-f1')),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const ValueKey('taste-grid-card-f1')));
      await _pumpTasteBoardFrames(tester);

      expect(
        find.byKey(const ValueKey('taste-card-back-flavor-f1')),
        findsOneWidget,
      );
      expect(find.text('辣度轮廓'), findsOneWidget);
    });

    testWidgets('首页会展示翻面提示且首次翻卡后消失', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HomePage(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 180));

      expect(
        find.byKey(const ValueKey('taste-flip-hint-pill')),
        findsOneWidget,
      );

      await tester.tap(_gridCardFinder().first);
      await _pumpTasteBoardFrames(tester);

      expect(
        find.byKey(const ValueKey('taste-flip-hint-pill')),
        findsNothing,
      );
    });

    testWidgets('首页点按第二张卡翻面后不应出现溢出异常', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HomePage(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 180));

      await tester.tap(_gridCardFinder().at(1));
      await _pumpTasteBoardFrames(tester);

      expect(tester.takeException(), isNull);
    });

    testWidgets('核心卡可以加载专属 pattern layer', (tester) async {
      final cards = [
        const TasteDeckCard(
          id: 'f_spicy',
          label: '辣',
          category: 'flavor',
          accentHexes: ['0xFFF46B40', '0xFFFF8A65'],
          iconName: 'local_fire_department',
          surfacePattern: 'ember',
          symbolLayout: 'crest',
          headlineStyle: 'poster',
          artKey: 'pepper-flare',
        ),
        for (var index = 1; index < TasteDeckSessionState.pageSize; index++)
          _sampleCard(
            'c$index',
            '标签$index',
            index.isEven ? 'scene' : 'ingredient',
          ),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox.expand(
              child: TasteCardDeck(
                cards: cards,
                session: TasteDeckSessionState.initial(
                  deck: cards,
                  cardDeckSeed: 1,
                ),
                onReact: (_, __) {},
                onAdvancePage: () {},
                onVoiceStart: () {},
                onVoiceEnd: () {},
                isListening: false,
                showFlipHint: false,
                onFirstFlip: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(
        find.byKey(const ValueKey('taste-card-pattern-f_spicy-ember')),
        findsOneWidget,
      );
    });

    testWidgets('再次点按已翻面的卡牌会回到正面', (tester) async {
      final cards = [
        _sampleCard('f1', '辣', 'flavor'),
        for (var index = 1; index < TasteDeckSessionState.pageSize; index++)
          _sampleCard(
              'c$index', '标签$index', index.isEven ? 'scene' : 'ingredient'),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox.expand(
              child: TasteCardDeck(
                cards: cards,
                session: TasteDeckSessionState.initial(
                  deck: cards,
                  cardDeckSeed: 1,
                ),
                onReact: (_, __) {},
                onAdvancePage: () {},
                onVoiceStart: () {},
                onVoiceEnd: () {},
                isListening: false,
                showFlipHint: false,
                onFirstFlip: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      final cardFinder = find.byKey(const ValueKey('taste-grid-card-f1'));
      await tester.tap(cardFinder);
      await _pumpTasteBoardFrames(tester);
      expect(
        find.byKey(const ValueKey('taste-card-back-flavor-f1')),
        findsOneWidget,
      );

      await tester.tap(cardFinder);
      await _pumpTasteBoardFrames(tester);

      expect(
        find.byKey(const ValueKey('taste-card-front-flavor-f1')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('taste-card-back-flavor-f1')),
        findsNothing,
      );
    });

    testWidgets('单卡超过阈值后会先进入吸附提交态', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HomePage(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 180));

      await tester.drag(
        _gridCardFinder().first,
        const Offset(0, -220),
      );
      await tester.pump(const Duration(milliseconds: 40));

      expect(_commitIndicatorFinder(), findsOneWidget);
    });

    testWidgets('滑卡后顶部状态条会更新已选数量', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HomePage(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 180));

      expect(find.text('选 0'), findsOneWidget);

      await tester.drag(
        _gridCardFinder().first,
        const Offset(0, -220),
      );
      await _pumpTasteBoardFrames(tester);

      expect(find.text('选 1'), findsOneWidget);
    });

    testWidgets('左右滑整版卡片后进入下一组九宫格', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HomePage(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 180));

      await tester.drag(
        find.byKey(const ValueKey('taste-grid-board')),
        const Offset(-420, 0),
      );
      await _pumpTasteBoardFrames(tester);

      expect(find.textContaining('2/'), findsOneWidget);
      expect(_gridCardFinder(), findsNWidgets(TasteDeckSessionState.pageSize));
      expect(_gridSlotFinder(), findsNWidgets(TasteDeckSessionState.pageSize));
    });

    testWidgets('翻页后下一组仍应完整显示 16 张卡', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HomePage(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 180));

      await tester.drag(
        _gridCardFinder().first,
        const Offset(0, -220),
      );
      await _pumpTasteBoardFrames(tester);

      await tester.drag(
        _gridCardFinder().at(1),
        const Offset(0, -220),
      );
      await _pumpTasteBoardFrames(tester);

      await tester.drag(
        find.byKey(const ValueKey('taste-grid-board')),
        const Offset(-420, 0),
      );
      await _pumpTasteBoardFrames(tester);

      expect(find.textContaining('2/'), findsOneWidget);
      expect(_gridCardFinder(), findsNWidgets(TasteDeckSessionState.pageSize));
      expect(_gridSlotFinder(), findsNWidgets(TasteDeckSessionState.pageSize));
    });

    testWidgets('4x4 使用固定 16 个卡位且每张卡都有有效尺寸', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HomePage(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 180));

      final slotRects = List.generate(
        TasteDeckSessionState.pageSize,
        (index) =>
            tester.getRect(find.byKey(ValueKey('taste-grid-slot-$index'))),
      );

      for (final rect in slotRects) {
        expect(rect.width, greaterThan(56));
        expect(rect.height, greaterThan(70));
      }
    });

    testWidgets('左右滑超过阈值后会先进入整版换牌吸附态', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HomePage(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 180));

      await tester.drag(
        find.byKey(const ValueKey('taste-grid-board')),
        const Offset(-420, 0),
      );
      await tester.pump(const Duration(milliseconds: 40));

      expect(
        find.byKey(const ValueKey('taste-page-commit-indicator')),
        findsOneWidget,
      );
    });

    testWidgets('整版换牌吸附态会出现发牌扇形过渡', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HomePage(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 180));

      await tester.drag(
        find.byKey(const ValueKey('taste-grid-board')),
        const Offset(-420, 0),
      );
      await tester.pump(const Duration(milliseconds: 40));

      expect(
        find.byKey(const ValueKey('taste-page-deal-fan')),
        findsOneWidget,
      );
    });

    testWidgets('长按卡牌舞台后语音转写会写回输入框', (tester) async {
      final speech = _FakeSpeechInputService('来点热的辣的，最好带锅气');

      await tester.pumpWidget(
        MaterialApp(
          home: HomePage(speechInputService: speech),
        ),
      );
      await tester.pump(const Duration(milliseconds: 180));

      await tester.longPress(find.byKey(const ValueKey('taste-grid-board')));
      await _pumpTasteBoardFrames(tester);

      expect(find.text('来点热的辣的，最好带锅气'), findsOneWidget);
      expect(speech.startCount, 1);
      expect(speech.stopCount, 1);
    });

    testWidgets('长按时会出现语音舞台反馈层', (tester) async {
      final speech = _FakeSpeechInputService('想吃热的面，别太腻');

      await tester.pumpWidget(
        MaterialApp(
          home: HomePage(speechInputService: speech),
        ),
      );
      await tester.pump(const Duration(milliseconds: 180));

      final gesture = await tester.startGesture(
        tester.getCenter(find.byKey(const ValueKey('taste-grid-board'))),
      );
      await tester.pump(kLongPressTimeout + const Duration(milliseconds: 50));

      expect(find.byKey(const ValueKey('taste-voice-stage-overlay')),
          findsOneWidget);
      expect(
        find.descendant(
          of: find.byKey(const ValueKey('taste-voice-stage-overlay')),
          matching: find.text('想吃热的面，别太腻'),
        ),
        findsOneWidget,
      );

      await gesture.up();
      await _pumpTasteBoardFrames(tester);
    });

    testWidgets('从 Face 2 进入生成阶段时展示过渡层', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HomePage(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 180));

      await tester.enterText(
        find.byKey(const ValueKey('home-requirement-input')),
        '今晚想吃热的，带锅气，别太甜',
      );
      await tester.pump();

      await tester.tap(find.byKey(const ValueKey('taste-signature-button')));
      await _pumpTasteBoardFrames(tester);

      await tester.tap(find.byKey(const ValueKey('start-inference-button')));
      await tester.pump();

      expect(
        find.byKey(const ValueKey('generation-transition-overlay')),
        findsOneWidget,
      );
    });

    testWidgets('首页 Face 1 也提供直接进入第二环节的按钮', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: HomePage(),
        ),
      );
      await tester.pump(const Duration(milliseconds: 180));

      await tester.drag(
        _gridCardFinder().first,
        const Offset(0, -220),
      );
      await _pumpTasteBoardFrames(tester);

      expect(find.byKey(const ValueKey('home-start-inference-button')),
          findsOneWidget);

      await tester
          .tap(find.byKey(const ValueKey('home-start-inference-button')));
      await tester.pump();
      expect(
        find.byKey(const ValueKey('generation-transition-overlay')),
        findsOneWidget,
      );
      expect(find.text('下一步：查看今日推荐'), findsOneWidget);
    });
  });

  group('V2 九宫格主题卡', () {
    testWidgets('4x4 四行会带有不同的桌游式错位边距', (tester) async {
      final cards = List.generate(
        TasteDeckSessionState.pageSize,
        (index) => _sampleCard(
            'c$index', '标签$index', index.isEven ? 'flavor' : 'ingredient'),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox.expand(
              child: TasteCardDeck(
                cards: cards,
                session: TasteDeckSessionState.initial(
                  deck: cards,
                  cardDeckSeed: 1,
                ),
                onReact: (_, __) {},
                onAdvancePage: () {},
                onVoiceStart: () {},
                onVoiceEnd: () {},
                isListening: false,
                showFlipHint: false,
                onFirstFlip: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      final row0Left =
          tester.getTopLeft(find.byKey(const ValueKey('taste-grid-slot-0'))).dx;
      final row1Left =
          tester.getTopLeft(find.byKey(const ValueKey('taste-grid-slot-4'))).dx;
      final row3Right = tester
          .getTopRight(find.byKey(const ValueKey('taste-grid-slot-15')))
          .dx;
      final row1Right = tester
          .getTopRight(find.byKey(const ValueKey('taste-grid-slot-7')))
          .dx;

      expect(row0Left, greaterThan(row1Left));
      expect(row3Right, lessThan(row1Right));
    });

    testWidgets('不同类别卡片会渲染不同主题装饰', (tester) async {
      final cards = [
        _sampleCard('f1', '辣', 'flavor'),
        _sampleCard('i1', '牛肉', 'ingredient'),
        _sampleCard('s1', '夜宵', 'scene'),
        _sampleCard('c1', '川菜', 'cuisine'),
        _sampleCard('ft1', '财运', 'fortune'),
        _sampleCard('f2', '鲜', 'flavor'),
        _sampleCard('i2', '海鲜', 'ingredient'),
        _sampleCard('s2', '聚餐', 'scene'),
        _sampleCard('c2', '日料', 'cuisine'),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox.expand(
              child: TasteCardDeck(
                cards: cards,
                session: TasteDeckSessionState.initial(
                  deck: cards,
                  cardDeckSeed: 1,
                ),
                onReact: (_, __) {},
                onAdvancePage: () {},
                onVoiceStart: () {},
                onVoiceEnd: () {},
                isListening: false,
                showFlipHint: false,
                onFirstFlip: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(
        find.byKey(const ValueKey('taste-card-game-frame-flavor-f1')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('taste-card-game-art-flavor-f1')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('taste-card-signature-flavor-f1')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('taste-card-title-block-flavor-f1')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('taste-card-footer-flavor-f1')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('taste-card-game-frame-ingredient-i1')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('taste-card-game-art-ingredient-i1')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('taste-card-signature-ingredient-i1')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('taste-card-footer-ingredient-i1')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('taste-card-game-frame-scene-s1')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('taste-card-game-art-scene-s1')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('taste-card-signature-scene-s1')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('taste-card-footer-scene-s1')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('taste-card-game-frame-cuisine-c1')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('taste-card-game-art-cuisine-c1')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('taste-card-title-block-cuisine-c1')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('taste-card-game-frame-fortune-ft1')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('taste-card-game-art-fortune-ft1')),
        findsOneWidget,
      );
    });

    testWidgets('卡牌正面会突出偏好主视觉、类型和规则', (tester) async {
      final cards = [
        _sampleCard('f1', '辣', 'flavor'),
        _sampleCard('i1', '牛肉', 'ingredient'),
        _sampleCard('s1', '夜宵', 'scene'),
        _sampleCard('c1', '川菜', 'cuisine'),
        _sampleCard('ft1', '财运', 'fortune'),
        _sampleCard('f2', '鲜', 'flavor'),
        _sampleCard('i2', '海鲜', 'ingredient'),
        _sampleCard('s2', '聚餐', 'scene'),
        _sampleCard('c2', '日料', 'cuisine'),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox.expand(
              child: TasteCardDeck(
                cards: cards,
                session: TasteDeckSessionState.initial(
                  deck: cards,
                  cardDeckSeed: 1,
                ),
                onReact: (_, __) {},
                onAdvancePage: () {},
                onVoiceStart: () {},
                onVoiceEnd: () {},
                isListening: false,
                showFlipHint: false,
                onFirstFlip: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(
        find.byKey(const ValueKey('taste-card-hero-flavor-f1')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('taste-card-rarity-flavor-f1')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('taste-card-affixes-flavor-f1')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('taste-card-effect-flavor-f1')),
        findsOneWidget,
      );
      expect(find.text('口味'), findsWidgets);
      expect(find.text('辣'), findsWidgets);
      expect(find.textContaining('锁定味型'), findsWidgets);
    });

    testWidgets('翻面后不同类别卡片会渲染不同背页结构', (tester) async {
      final cards = [
        _sampleCard('f1', '辣', 'flavor'),
        _sampleCard('i1', '牛肉', 'ingredient'),
        _sampleCard('s1', '夜宵', 'scene'),
        _sampleCard('c1', '川菜', 'cuisine'),
        _sampleCard('ft1', '财运', 'fortune'),
        _sampleCard('f2', '鲜', 'flavor'),
        _sampleCard('i2', '海鲜', 'ingredient'),
        _sampleCard('s2', '聚餐', 'scene'),
        _sampleCard('c2', '日料', 'cuisine'),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox.expand(
              child: TasteCardDeck(
                cards: cards,
                session: TasteDeckSessionState.initial(
                  deck: cards,
                  cardDeckSeed: 1,
                ),
                onReact: (_, __) {},
                onAdvancePage: () {},
                onVoiceStart: () {},
                onVoiceEnd: () {},
                isListening: false,
                showFlipHint: false,
                onFirstFlip: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.byKey(const ValueKey('taste-grid-card-f1')));
      await _pumpTasteBoardFrames(tester);
      expect(
        find.byKey(const ValueKey('taste-card-back-layout-flavor-f1')),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const ValueKey('taste-grid-card-i1')));
      await _pumpTasteBoardFrames(tester);
      expect(
        find.byKey(const ValueKey('taste-card-back-layout-ingredient-i1')),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const ValueKey('taste-grid-card-c1')));
      await _pumpTasteBoardFrames(tester);
      expect(
        find.byKey(const ValueKey('taste-card-back-layout-cuisine-c1')),
        findsOneWidget,
      );

      await tester.tap(find.byKey(const ValueKey('taste-grid-card-ft1')));
      await _pumpTasteBoardFrames(tester);
      expect(
        find.byKey(const ValueKey('taste-card-back-layout-fortune-ft1')),
        findsOneWidget,
      );
    });

    testWidgets('翻面后的背页会显示签卡印章与编号', (tester) async {
      final cards = [
        _sampleCard('f1', '辣', 'flavor'),
        _sampleCard('i1', '牛肉', 'ingredient'),
        _sampleCard('s1', '夜宵', 'scene'),
        _sampleCard('c1', '川菜', 'cuisine'),
        _sampleCard('ft1', '财运', 'fortune'),
        _sampleCard('f2', '鲜', 'flavor'),
        _sampleCard('i2', '海鲜', 'ingredient'),
        _sampleCard('s2', '聚餐', 'scene'),
        _sampleCard('c2', '日料', 'cuisine'),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox.expand(
              child: TasteCardDeck(
                cards: cards,
                session: TasteDeckSessionState.initial(
                  deck: cards,
                  cardDeckSeed: 1,
                ),
                onReact: (_, __) {},
                onAdvancePage: () {},
                onVoiceStart: () {},
                onVoiceEnd: () {},
                isListening: false,
                showFlipHint: false,
                onFirstFlip: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.byKey(const ValueKey('taste-grid-card-f1')));
      await _pumpTasteBoardFrames(tester);

      expect(
        find.byKey(const ValueKey('taste-card-back-seal-flavor-f1')),
        findsOneWidget,
      );
      expect(
        find.byKey(const ValueKey('taste-card-back-serial-f1')),
        findsOneWidget,
      );
    });

    testWidgets('紧凑卡位翻到背面后不应出现溢出异常', (tester) async {
      tester.view.physicalSize = const Size(1179, 2556);
      tester.view.devicePixelRatio = 3;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      final cards = [
        _sampleCard('f1', '辣', 'flavor'),
        _sampleCard('i1', '牛肉', 'ingredient'),
        _sampleCard('s1', '夜宵', 'scene'),
        _sampleCard('c1', '川菜', 'cuisine'),
        _sampleCard('ft1', '财运', 'fortune'),
        _sampleCard('f2', '鲜', 'flavor'),
        _sampleCard('i2', '海鲜', 'ingredient'),
        _sampleCard('s2', '聚餐', 'scene'),
        _sampleCard('c2', '日料', 'cuisine'),
      ];

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox.expand(
              child: TasteCardDeck(
                cards: cards,
                session: TasteDeckSessionState.initial(
                  deck: cards,
                  cardDeckSeed: 1,
                ),
                onReact: (_, __) {},
                onAdvancePage: () {},
                onVoiceStart: () {},
                onVoiceEnd: () {},
                isListening: false,
                showFlipHint: false,
                onFirstFlip: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      await tester.tap(find.byKey(const ValueKey('taste-grid-card-c2')));
      await _pumpTasteBoardFrames(tester);

      expect(
        find.byKey(const ValueKey('taste-card-back-cuisine-c2')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    });
  });

  group('V2 口味签名页', () {
    testWidgets('口味签名页会展示与首页一致的摘要状态带', (tester) async {
      final cards = [
        _sampleCard('f1', '辣', 'flavor'),
        _sampleCard('i1', '牛肉', 'ingredient'),
        _sampleCard('s1', '夜宵', 'scene'),
      ];
      final session = TasteDeckSessionState.initial(
        deck: cards,
        cardDeckSeed: 1,
      ).copyWith(
        likedTagIds: const ['f1'],
        dislikedTagIds: const ['i1'],
        skippedTagIds: const ['s1'],
        freeformRequirement: '想吃热的，别太甜',
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: TasteSignaturePanel(
              session: session,
              onBack: () {},
              onStartInference: () {},
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.byKey(const ValueKey('taste-signature-summary-band')),
          findsOneWidget);
      expect(find.text('喜欢 1'), findsOneWidget);
      expect(find.text('排除 1'), findsOneWidget);
      expect(find.text('补充 1'), findsOneWidget);
    });
  });
}

Finder _gridCardFinder() {
  return find.byWidgetPredicate((widget) {
    final key = widget.key;
    return key is ValueKey<String> && key.value.startsWith('taste-grid-card-');
  });
}

Future<void> _pumpUntilFound(
  WidgetTester tester,
  Finder finder, {
  Duration step = const Duration(milliseconds: 120),
  int maxPumps = 20,
}) async {
  for (var i = 0; i < maxPumps; i += 1) {
    await tester.pump(step);
    if (finder.evaluate().isNotEmpty) return;
  }
  expect(finder, findsOneWidget);
}

Future<void> _pumpTasteBoardFrames(
  WidgetTester tester, {
  int frameCount = 8,
  Duration frame = const Duration(milliseconds: 80),
}) async {
  for (var i = 0; i < frameCount; i += 1) {
    await tester.pump(frame);
  }
}

Finder _gridSlotFinder() {
  return find.byWidgetPredicate((widget) {
    final key = widget.key;
    return key is ValueKey<String> && key.value.startsWith('taste-grid-slot-');
  });
}

Finder _commitIndicatorFinder() {
  return find.byWidgetPredicate((widget) {
    final key = widget.key;
    return key is ValueKey<String> &&
        key.value.startsWith('taste-card-commit-indicator-');
  });
}

Finder _dealEntryFinder() {
  return find.byWidgetPredicate((widget) {
    final key = widget.key;
    return key is ValueKey<String> &&
        key.value.startsWith('taste-card-deal-entry-');
  });
}

class _FakeSpeechInputService implements V2SpeechInputService {
  _FakeSpeechInputService(this.transcript);

  final String transcript;
  int startCount = 0;
  int stopCount = 0;
  bool _isListening = false;
  void Function(String transcript, bool isFinal)? _onResult;

  @override
  bool get isListening => _isListening;

  @override
  Future<bool> initialize() async => true;

  @override
  Future<void> startListening({
    required void Function(String transcript, bool isFinal) onResult,
  }) async {
    startCount += 1;
    _isListening = true;
    _onResult = onResult;
    _onResult?.call(transcript, true);
  }

  @override
  Future<String> stopListening() async {
    stopCount += 1;
    _isListening = false;
    return transcript;
  }
}

class _InputCapturePage extends StatelessWidget {
  const _InputCapturePage({required this.input});

  final TasteInferenceInput input;

  @override
  Widget build(BuildContext context) {
    final constraints = input.structuredConstraints;
    return Scaffold(
      body: Text(
        'budget=${constraints.maxBudgetYuan} '
        'party=${constraints.partySize} '
        'execution=${constraints.executionPreference.name} '
        'location=${constraints.locationPreference.name} '
        'freeform=${input.freeformRequirement} '
        'labels=${input.likedTagLabels.join(',')}',
      ),
    );
  }
}

TasteDeckCard _sampleCard(String id, String label, String category) {
  return TasteDeckCard(
    id: id,
    label: label,
    category: category,
    accentHexes: const ['0xFFF46B40', '0xFFFFC7B8'],
    iconName: 'spa',
    backTitle: switch (category) {
      'flavor' => '辣度轮廓',
      'ingredient' => '食材角色',
      'scene' => '场景脚本',
      'cuisine' => '菜系方向',
      'fortune' => '趣味线索',
      _ => '偏好注释',
    },
    examples: [label, '示例A', '示例B'],
  );
}

class _DeckHarness extends StatefulWidget {
  const _DeckHarness({
    required this.cards,
  });

  final List<TasteDeckCard> cards;

  @override
  State<_DeckHarness> createState() => _DeckHarnessState();
}

class _DeckHarnessState extends State<_DeckHarness> {
  late TasteDeckSessionState _session;

  @override
  void initState() {
    super.initState();
    _session = TasteDeckSessionState.initial(
      deck: widget.cards,
      cardDeckSeed: 1,
    );
  }

  @override
  Widget build(BuildContext context) {
    return TasteCardDeck(
      cards: _session.currentPageCards,
      session: _session,
      onReact: (card, reaction) {
        setState(() {
          _session = _session.recordReaction(card, reaction);
        });
      },
      onAdvancePage: () {},
      onVoiceStart: () {},
      onVoiceEnd: () {},
      isListening: false,
      showFlipHint: false,
      onFirstFlip: () {},
    );
  }
}
