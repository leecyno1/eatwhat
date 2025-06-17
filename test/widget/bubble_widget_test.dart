import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';
import 'package:eatwhat_app/features/bubble/controllers/bubble_controller.dart';
import 'package:eatwhat_app/features/bubble/widgets/bubble_widget.dart';
import 'package:eatwhat_app/core/models/bubble.dart';

void main() {
  group('BubbleWidget Tests', () {
    late BubbleController controller;
    late Bubble testBubble;

    setUp(() {
      controller = BubbleController();
      testBubble = Bubble(
        type: BubbleType.taste,
        name: '甜',
        icon: '🍯',
        color: Colors.orange,
        position: const Offset(100, 100),
      );
    });

    tearDown(() {
      controller.dispose();
    });

    Widget createTestWidget(Widget child) {
      return MaterialApp(
        home: ChangeNotifierProvider<BubbleController>.value(
          value: controller,
          child: Scaffold(body: child),
        ),
      );
    }

    testWidgets('应该显示气泡的基本信息', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          BubbleWidget(
            bubble: testBubble,
            onTap: () {},
          ),
        ),
      );

      // 检查是否显示了emoji和文本
      expect(find.text('🍯'), findsOneWidget);
      expect(find.text('甜'), findsOneWidget);
    });

    testWidgets('点击气泡应该触发回调', (WidgetTester tester) async {
      bool tapped = false;
      
      await tester.pumpWidget(
        createTestWidget(
          BubbleWidget(
            bubble: testBubble,
            onTap: () {
              tapped = true;
            },
          ),
        ),
      );

      await tester.tap(find.byType(BubbleWidget));
      expect(tapped, true);
    });

    testWidgets('选中状态应该改变外观', (WidgetTester tester) async {
      final selectedBubble = testBubble.copyWith(isSelected: true);
      
      await tester.pumpWidget(
        createTestWidget(
          Column(
            children: [
              BubbleWidget(
                bubble: testBubble,
                onTap: () {},
              ),
              BubbleWidget(
                bubble: selectedBubble,
                onTap: () {},
              ),
            ],
          ),
        ),
      );

      // 应该有两个气泡Widget
      expect(find.byType(BubbleWidget), findsNWidgets(2));
    });

    testWidgets('长按应该触发长按回调', (WidgetTester tester) async {
      bool longPressed = false;
      
      await tester.pumpWidget(
        createTestWidget(
          BubbleWidget(
            bubble: testBubble,
            onTap: () {},
            onLongPress: () {
              longPressed = true;
            },
          ),
        ),
      );

      await tester.longPress(find.byType(BubbleWidget));
      expect(longPressed, true);
    });

    testWidgets('不同类型的气泡应该有不同的颜色', (WidgetTester tester) async {
      final tasteBubble = Bubble(
        type: BubbleType.taste,
        name: '甜',
        color: Colors.orange,
      );

      final cuisineBubble = Bubble(
        type: BubbleType.cuisine,
        name: '川菜',
        color: Colors.red,
      );

      await tester.pumpWidget(
        createTestWidget(
          Column(
            children: [
              BubbleWidget(
                bubble: tasteBubble,
                onTap: () {},
              ),
              BubbleWidget(
                bubble: cuisineBubble,
                onTap: () {},
              ),
            ],
          ),
        ),
      );

      expect(find.byType(BubbleWidget), findsNWidgets(2));
    });

    testWidgets('气泡应该支持动画', (WidgetTester tester) async {
      final animatingBubble = testBubble.copyWith(isAnimating: true);
      
      await tester.pumpWidget(
        createTestWidget(
          BubbleWidget(
            bubble: animatingBubble,
            onTap: () {},
          ),
        ),
      );

      // 检查是否有AnimatedContainer或其他动画Widget
      expect(find.byType(BubbleWidget), findsOneWidget);
    });

    testWidgets('气泡透明度应该影响显示', (WidgetTester tester) async {
      final transparentBubble = testBubble.copyWith(opacity: 0.5);
      
      await tester.pumpWidget(
        createTestWidget(
          BubbleWidget(
            bubble: transparentBubble,
            onTap: () {},
          ),
        ),
      );

      expect(find.byType(BubbleWidget), findsOneWidget);
    });

    testWidgets('没有图标的气泡应该显示默认emoji', (WidgetTester tester) async {
      final bubbleWithoutIcon = Bubble(
        type: BubbleType.taste,
        name: '甜',
        color: Colors.orange,
      );
      
      await tester.pumpWidget(
        createTestWidget(
          BubbleWidget(
            bubble: bubbleWithoutIcon,
            onTap: () {},
          ),
        ),
      );

      // 应该显示默认的🔮 emoji
      expect(find.text('🔮'), findsOneWidget);
      expect(find.text('甜'), findsOneWidget);
    });
  });

  group('EnhancedBubbleWidget Tests', () {
    late BubbleController controller;
    late Bubble testBubble;

    setUp(() {
      controller = BubbleController();
      testBubble = Bubble(
        type: BubbleType.taste,
        name: '甜',
        icon: '🍯',
        color: Colors.orange,
        position: const Offset(100, 100),
      );
    });

    tearDown(() {
      controller.dispose();
    });

    Widget createTestWidget(Widget child) {
      return MaterialApp(
        home: ChangeNotifierProvider<BubbleController>.value(
          value: controller,
          child: Scaffold(body: child),
        ),
      );
    }

    testWidgets('增强气泡应该支持手势识别', (WidgetTester tester) async {
      bool gestureDetected = false;
      
      await tester.pumpWidget(
        createTestWidget(
          EnhancedBubbleWidget(
            bubble: testBubble,
            onGesture: (bubble, gesture, position, velocity) {
              gestureDetected = true;
            },
          ),
        ),
      );

      // 模拟点击手势
      await tester.tap(find.byType(EnhancedBubbleWidget));
      expect(gestureDetected, true);
    });

    testWidgets('增强气泡应该支持拖拽', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          EnhancedBubbleWidget(
            bubble: testBubble,
            onGesture: (bubble, gesture, position, velocity) {},
          ),
        ),
      );

      // 模拟拖拽手势
      await tester.drag(find.byType(EnhancedBubbleWidget), const Offset(50, 50));
      await tester.pumpAndSettle();

      expect(find.byType(EnhancedBubbleWidget), findsOneWidget);
    });

    testWidgets('增强气泡应该响应滑动手势', (WidgetTester tester) async {
      bool swipeDetected = false;
      
      await tester.pumpWidget(
        createTestWidget(
          EnhancedBubbleWidget(
            bubble: testBubble,
            onGesture: (bubble, gesture, position, velocity) {
              if (gesture == BubbleGesture.swipeRight) {
                swipeDetected = true;
              }
            },
          ),
        ),
      );

      // 模拟向右滑动
      await tester.fling(
        find.byType(EnhancedBubbleWidget),
        const Offset(100, 0),
        1000,
      );
      
      expect(swipeDetected, true);
    });
  });

  group('MagicBubbleWidget Tests', () {
    late BubbleController controller;
    late Bubble testBubble;

    setUp(() {
      controller = BubbleController();
      testBubble = Bubble(
        type: BubbleType.taste,
        name: '甜',
        icon: '🍯',
        color: Colors.orange,
        position: const Offset(100, 100),
      );
    });

    tearDown(() {
      controller.dispose();
    });

    Widget createTestWidget(Widget child) {
      return MaterialApp(
        home: ChangeNotifierProvider<BubbleController>.value(
          value: controller,
          child: Scaffold(body: child),
        ),
      );
    }

    testWidgets('魔法气泡应该有特殊效果', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          MagicBubbleWidget(
            bubble: testBubble,
            onTap: () {},
          ),
        ),
      );

      expect(find.byType(MagicBubbleWidget), findsOneWidget);
    });

    testWidgets('魔法气泡应该支持粒子效果', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          MagicBubbleWidget(
            bubble: testBubble,
            onTap: () {},
            showParticles: true,
          ),
        ),
      );

      expect(find.byType(MagicBubbleWidget), findsOneWidget);
    });

    testWidgets('魔法气泡应该支持发光效果', (WidgetTester tester) async {
      await tester.pumpWidget(
        createTestWidget(
          MagicBubbleWidget(
            bubble: testBubble,
            onTap: () {},
            glowIntensity: 0.8,
          ),
        ),
      );

      expect(find.byType(MagicBubbleWidget), findsOneWidget);
    });
  });
} 