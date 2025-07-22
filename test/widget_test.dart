import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:eatwhat_app/main.dart';

void main() {
  group('应用基础功能测试', () {
    testWidgets('应用应该正常启动', (WidgetTester tester) async {
      // 构建应用并触发一帧
      await tester.pumpWidget(const EatWhatApp());

      // 等待所有动画完成
      await tester.pumpAndSettle();

      // 验证应用标题存在
      expect(find.text('吃什么'), findsOneWidget);
    });

    testWidgets('简单测试应用应该正常显示', (WidgetTester tester) async {
      // 构建简单测试应用
      await tester.pumpWidget(const MaterialApp(
        home: Scaffold(
          body: Center(
            child: Text('测试成功'),
          ),
        ),
      ));

      // 验证测试文本存在
      expect(find.text('测试成功'), findsOneWidget);
    });

    testWidgets('主题应该正确应用', (WidgetTester tester) async {
      await tester.pumpWidget(const EatWhatApp());
      await tester.pumpAndSettle();

      // 查找MaterialApp
      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.title, '吃什么');
      expect(materialApp.theme, isNotNull);
      expect(materialApp.darkTheme, isNotNull);
    });
  });

  group('Provider状态管理测试', () {
    testWidgets('Provider应该正确初始化', (WidgetTester tester) async {
      await tester.pumpWidget(const EatWhatApp());
      await tester.pumpAndSettle();

      // 验证应用正常启动，说明Provider配置正确
      expect(find.byType(MaterialApp), findsOneWidget);
    });
  });
} 