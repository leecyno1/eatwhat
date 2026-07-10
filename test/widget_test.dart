import 'package:eatwhat_app/v2/app_v2.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({
      'cold_start_questionnaire_completed': true,
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

  group('应用基础功能测试', () {
    testWidgets('应用应该正常启动', (WidgetTester tester) async {
      // 构建应用并触发一帧
      await tester.pumpWidget(buildTestApp());

      // 避免无限动画导致阻塞，使用有限时长的pump
      await tester.pump(const Duration(milliseconds: 200));

      // 验证应用启动（存在 MaterialApp）
      expect(find.byType(MaterialApp), findsOneWidget);
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
      await tester.pumpWidget(buildTestApp());
      await tester.pump(const Duration(milliseconds: 200));

      // 查找MaterialApp
      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.title, 'EatWhat V2');
      expect(materialApp.theme, isNotNull);
      expect(materialApp.darkTheme, isNotNull);
    });
  });

  group('Provider状态管理测试', () {
    testWidgets('Provider应该正确初始化', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pump(const Duration(milliseconds: 200));

      // 验证应用正常启动，说明Provider配置正确
      expect(find.byType(MaterialApp), findsOneWidget);
    });
  });
}
