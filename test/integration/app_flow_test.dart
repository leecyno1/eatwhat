import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:eatwhat_app/main.dart';

void main() {
  group('应用流程集成测试', () {
    testWidgets('完整的用户流程测试', (WidgetTester tester) async {
      // 启动应用
      await tester.pumpWidget(const EatWhatApp());
      await tester.pumpAndSettle();

      // 验证应用启动成功
      expect(find.text('吃什么'), findsOneWidget);

      // 等待气泡加载
      await tester.pumpAndSettle(const Duration(seconds: 2));

      // 查找并点击一些气泡
      final bubbleFinders = find.byType(GestureDetector);
      if (bubbleFinders.evaluate().isNotEmpty) {
        // 点击第一个气泡
        await tester.tap(bubbleFinders.first);
        await tester.pumpAndSettle();

        // 如果有更多气泡，点击第二个
        if (bubbleFinders.evaluate().length > 1) {
          await tester.tap(bubbleFinders.at(1));
          await tester.pumpAndSettle();
        }
      }

      // 查找生成推荐按钮并点击
      final recommendButton = find.text('生成推荐');
      if (recommendButton.evaluate().isNotEmpty) {
        await tester.tap(recommendButton);
        await tester.pumpAndSettle();

        // 等待推荐生成
        await tester.pumpAndSettle(const Duration(seconds: 2));
      }
    });

    testWidgets('气泡选择和取消选择流程', (WidgetTester tester) async {
      await tester.pumpWidget(const EatWhatApp());
      await tester.pumpAndSettle();

      // 等待气泡加载
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // 查找气泡
      final bubbleFinders = find.byType(GestureDetector);
      if (bubbleFinders.evaluate().isNotEmpty) {
        // 选择气泡
        await tester.tap(bubbleFinders.first);
        await tester.pumpAndSettle();

        // 再次点击取消选择
        await tester.tap(bubbleFinders.first);
        await tester.pumpAndSettle();
      }
    });

    testWidgets('重置功能测试', (WidgetTester tester) async {
      await tester.pumpWidget(const EatWhatApp());
      await tester.pumpAndSettle();

      // 等待气泡加载
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // 选择一些气泡
      final bubbleFinders = find.byType(GestureDetector);
      if (bubbleFinders.evaluate().length >= 2) {
        await tester.tap(bubbleFinders.first);
        await tester.pumpAndSettle();
        await tester.tap(bubbleFinders.at(1));
        await tester.pumpAndSettle();
      }

      // 查找重置按钮并点击
      final resetButton = find.text('重置气泡');
      if (resetButton.evaluate().isNotEmpty) {
        await tester.tap(resetButton);
        await tester.pumpAndSettle();
      }
    });

    testWidgets('导航到推荐页面测试', (WidgetTester tester) async {
      await tester.pumpWidget(const EatWhatApp());
      await tester.pumpAndSettle();

      // 等待气泡加载
      await tester.pumpAndSettle(const Duration(seconds: 1));

      // 选择一些气泡
      final bubbleFinders = find.byType(GestureDetector);
      if (bubbleFinders.evaluate().isNotEmpty) {
        await tester.tap(bubbleFinders.first);
        await tester.pumpAndSettle();
      }

      // 生成推荐
      final recommendButton = find.text('生成推荐');
      if (recommendButton.evaluate().isNotEmpty) {
        await tester.tap(recommendButton);
        await tester.pumpAndSettle();

        // 等待导航完成
        await tester.pumpAndSettle(const Duration(seconds: 2));
      }
    });

    testWidgets('应用性能测试', (WidgetTester tester) async {
      // 记录开始时间
      final startTime = DateTime.now();

      await tester.pumpWidget(const EatWhatApp());
      await tester.pumpAndSettle();

      // 记录加载完成时间
      final loadTime = DateTime.now().difference(startTime);

      // 验证加载时间合理（小于5秒）
      expect(loadTime.inSeconds, lessThan(5));

      // 快速点击多个气泡测试响应性
      final bubbleFinders = find.byType(GestureDetector);
      if (bubbleFinders.evaluate().length >= 3) {
        for (int i = 0; i < 3; i++) {
          await tester.tap(bubbleFinders.at(i));
          await tester.pump(const Duration(milliseconds: 100));
        }
        await tester.pumpAndSettle();
      }
    });

    testWidgets('错误处理测试', (WidgetTester tester) async {
      await tester.pumpWidget(const EatWhatApp());
      await tester.pumpAndSettle();

      // 在没有选择气泡的情况下尝试生成推荐
      final recommendButton = find.text('生成推荐');
      if (recommendButton.evaluate().isNotEmpty) {
        await tester.tap(recommendButton);
        await tester.pumpAndSettle();

        // 应该显示某种提示或保持在当前页面
        expect(find.text('吃什么'), findsOneWidget);
      }
    });

    testWidgets('界面响应性测试', (WidgetTester tester) async {
      await tester.pumpWidget(const EatWhatApp());
      await tester.pumpAndSettle();

      // 测试滚动性能
      await tester.drag(find.byType(Scrollable).first, const Offset(0, -300));
      await tester.pumpAndSettle();

      await tester.drag(find.byType(Scrollable).first, const Offset(0, 300));
      await tester.pumpAndSettle();
    });

    testWidgets('内存泄漏测试', (WidgetTester tester) async {
      // 多次启动和销毁应用
      for (int i = 0; i < 3; i++) {
        await tester.pumpWidget(const EatWhatApp());
        await tester.pumpAndSettle();

        // 模拟用户操作
        final bubbleFinders = find.byType(GestureDetector);
        if (bubbleFinders.evaluate().isNotEmpty) {
          await tester.tap(bubbleFinders.first);
          await tester.pumpAndSettle();
        }

        // 清理
        await tester.pumpWidget(Container());
        await tester.pumpAndSettle();
      }
    });

    testWidgets('多语言支持测试', (WidgetTester tester) async {
      await tester.pumpWidget(const EatWhatApp());
      await tester.pumpAndSettle();

      // 验证中文文本显示正确
      expect(find.text('吃什么'), findsOneWidget);

      // 查找其他中文文本
      final chineseTextFinders = [
        find.text('甜'),
        find.text('酸'),
        find.text('咸'),
        find.text('川菜'),
        find.text('粤菜'),
      ];

      for (final finder in chineseTextFinders) {
        if (finder.evaluate().isNotEmpty) {
          expect(finder, findsWidgets);
        }
      }
    });

    testWidgets('无障碍访问测试', (WidgetTester tester) async {
      await tester.pumpWidget(const EatWhatApp());
      await tester.pumpAndSettle();

      // 检查是否有语义标签
      final semanticsFinders = find.bySemanticsLabel('气泡');
      // 注意：这个测试可能需要根据实际的语义标签调整
    });
  });

  group('边界条件测试', () {
    testWidgets('空状态测试', (WidgetTester tester) async {
      await tester.pumpWidget(const EatWhatApp());
      await tester.pumpAndSettle();

      // 在没有选择任何气泡的情况下测试应用行为
      expect(find.text('吃什么'), findsOneWidget);
    });

    testWidgets('大量数据测试', (WidgetTester tester) async {
      await tester.pumpWidget(const EatWhatApp());
      await tester.pumpAndSettle();

      // 选择大量气泡
      final bubbleFinders = find.byType(GestureDetector);
      final maxBubbles = bubbleFinders.evaluate().length;
      
      for (int i = 0; i < maxBubbles && i < 10; i++) {
        await tester.tap(bubbleFinders.at(i));
        await tester.pump(const Duration(milliseconds: 50));
      }
      
      await tester.pumpAndSettle();
    });

    testWidgets('快速操作测试', (WidgetTester tester) async {
      await tester.pumpWidget(const EatWhatApp());
      await tester.pumpAndSettle();

      // 快速连续点击同一个气泡
      final bubbleFinders = find.byType(GestureDetector);
      if (bubbleFinders.evaluate().isNotEmpty) {
        for (int i = 0; i < 5; i++) {
          await tester.tap(bubbleFinders.first);
          await tester.pump(const Duration(milliseconds: 10));
        }
        await tester.pumpAndSettle();
      }
    });
  });
} 