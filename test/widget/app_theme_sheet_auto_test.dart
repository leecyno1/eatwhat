import 'package:eatwhat_app/v2/core/theme/app_theme_controller.dart';
import 'package:eatwhat_app/v2/features/home/widgets/theme_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 外观面板「自动 · 跟随昼夜」卡片行为。
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AppThemeController.autoEnabled.value = false;
    AppThemeController.dayPreference.value = AppThemeMode.cream;
    AppThemeController.nightPreference.value = AppThemeMode.dark;
    AppThemeController.applyBrightness(Brightness.light);
    AppThemeController.mode.value = AppThemeMode.cream;
  });

  Future<void> openSheet(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showAppThemeSheet(context),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  testWidgets('自动卡片展示昼夜偏好与当前时段', (tester) async {
    await openSheet(tester);

    expect(find.byKey(const ValueKey('theme-option-auto')), findsOneWidget);
    expect(find.text('自动 · 跟随昼夜'), findsOneWidget);
    expect(find.textContaining('白天 米白 · 日间'), findsOneWidget);
    expect(find.textContaining('夜晚 墨夜 · 夜间'), findsOneWidget);
    expect(find.text('当前：白天'), findsOneWidget);
  });

  testWidgets('点按自动卡片开启自动并记忆当前主题', (tester) async {
    await openSheet(tester);

    await tester.tap(find.byKey(const ValueKey('theme-option-auto')));
    await tester.pumpAndSettle();

    expect(AppThemeController.autoEnabled.value, isTrue);
    expect(AppThemeController.dayPreference.value, AppThemeMode.cream);
    expect(find.text('当前：白天'), findsOneWidget);
  });

  testWidgets('自动开启时点选美学主题记为白天偏好', (tester) async {
    AppThemeController.autoEnabled.value = true;
    await openSheet(tester);

    await tester.tap(find.byKey(const ValueKey('theme-option-celadon')));
    await tester.pumpAndSettle();

    expect(AppThemeController.autoEnabled.value, isTrue);
    expect(AppThemeController.dayPreference.value, AppThemeMode.celadon);
    expect(AppThemeController.mode.value, AppThemeMode.celadon);
    expect(find.textContaining('白天 青瓷宋韵'), findsOneWidget);
  });

  testWidgets('夜间自动模式下点选主题记为夜晚偏好', (tester) async {
    AppThemeController.autoEnabled.value = true;
    AppThemeController.applyBrightness(Brightness.dark);
    await openSheet(tester);

    expect(find.text('当前：夜晚'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('theme-option-neon')));
    await tester.pumpAndSettle();

    expect(AppThemeController.nightPreference.value, AppThemeMode.neon);
    expect(AppThemeController.mode.value, AppThemeMode.neon);
    expect(find.textContaining('夜晚 霓虹夜市'), findsOneWidget);
  });
}