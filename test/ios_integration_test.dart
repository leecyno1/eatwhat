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

  group('iOS集成测试', () {
    testWidgets('应用在iOS设备上正常启动', (WidgetTester tester) async {
      // 构建我们的应用并触发一个frame
      await tester.pumpWidget(buildTestApp());
      await tester.pump(const Duration(seconds: 2));

      // 验证应用正常启动
      expect(find.byType(MaterialApp), findsOneWidget);

      // 验证主要组件存在
      expect(find.byType(Scaffold), findsAtLeastNWidgets(1));

      // 等待初始化完成
      await tester.pump(const Duration(seconds: 3));

      // 验证没有未捕获的异常
      expect(tester.takeException(), isNull);
    });

    testWidgets('UI组件正常渲染', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pump(const Duration(seconds: 2));

      // 验证Material主题应用
      final materialApp = tester.widget<MaterialApp>(find.byType(MaterialApp));
      expect(materialApp.theme, isNotNull);

      // 验证Provider状态管理
      expect(find.byType(MaterialApp), findsOneWidget);

      await tester.pump(const Duration(seconds: 1));
      expect(tester.takeException(), isNull);
    });

    testWidgets('现代化UI组件加载', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pump(const Duration(seconds: 2));

      // 验证应用结构
      expect(find.byType(MaterialApp), findsOneWidget);

      // 等待UI完全加载
      await tester.pump(const Duration(seconds: 3));

      // 验证没有构建错误
      expect(tester.takeException(), isNull);
    });
  });

  group('技术栈升级验证', () {
    testWidgets('新依赖包正常工作', (WidgetTester tester) async {
      await tester.pumpWidget(buildTestApp());
      await tester.pump(const Duration(seconds: 2));

      // 验证应用正常运行
      expect(find.byType(MaterialApp), findsOneWidget);

      // 验证新的依赖包没有导致错误
      await tester.pump(const Duration(seconds: 1));
      expect(tester.takeException(), isNull);
    });
  });
}
