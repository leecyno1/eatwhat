import 'package:eatwhat_app/v2/core/theme/app_theme_controller.dart';
import 'package:eatwhat_app/v2/core/theme/app_tokens.dart';
import 'package:eatwhat_app/v2/features/home/home_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../test_bootstrap.dart';

/// 主题在页面展示期间变化（手动选择或昼夜自动翻转）时，页面必须实时重建。
void main() {
  setUpAll(() async {
    await bootstrapTestEnvironment();
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({
      'v2_home_generation_guide_seen': true,
      'handfeel_tutorial_v1_seen': true,
    });
    AppThemeController.autoEnabled.value = false;
    AppThemeController.mode.value = AppThemeMode.cream;
  });

  testWidgets('首页在展示中随主题切换实时换色', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: HomePage(initialCards: []),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    Scaffold scaffold() =>
        tester.widget<Scaffold>(find.byType(Scaffold).first);
    expect(scaffold().backgroundColor, AppPalette.night);

    // 展示中切到霓虹夜场：不重启、不重新 pumpWidget。
    AppThemeController.mode.value = AppThemeMode.neon;
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    expect(AppThemeController.isCream, isFalse);
    expect(scaffold().backgroundColor, AppPalette.night);
  });
}