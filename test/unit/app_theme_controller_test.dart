import 'package:eatwhat_app/v2/core/theme/app_theme_controller.dart';
import 'package:eatwhat_app/v2/core/theme/app_tokens.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AppThemeController.mode.value = AppThemeMode.dark;
  });

  test('默认黑色主题，色板为夜色值', () {
    expect(AppThemeController.isCream, isFalse);
    expect(AppPalette.night.value, 0xFF1C1C1E);
    expect(AppPalette.moonlight.value, 0xFFEDEBE8);
    expect(AppPalette.leaf.value, 0xFF7ABF88);
  });

  test('切换米色主题后色板代理为米色值', () async {
    await AppThemeController.setMode(AppThemeMode.cream);
    expect(AppThemeController.isCream, isTrue);
    expect(AppPalette.night.value, 0xFFF5EFE3);
    expect(AppPalette.nightSurface.value, 0xFFFCF8EF);
    expect(AppPalette.moonlight.value, 0xFF2E2924);
    expect(AppPalette.leaf.value, 0xFF4A5D4E);
  });

  test('主题持久化并可读回', () async {
    await AppThemeController.setMode(AppThemeMode.cream);
    AppThemeController.mode.value = AppThemeMode.dark; // 模拟新进程
    await AppThemeController.loadStored();
    expect(AppThemeController.isCream, isTrue);
  });

  test('toggle 在两主题间往返', () async {
    expect(AppThemeController.isCream, isFalse);
    await AppThemeController.toggle();
    expect(AppThemeController.isCream, isTrue);
    await AppThemeController.toggle();
    expect(AppThemeController.isCream, isFalse);
  });
}
