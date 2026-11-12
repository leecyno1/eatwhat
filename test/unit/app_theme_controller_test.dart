import 'package:eatwhat_app/v2/core/theme/app_theme_controller.dart';
import 'package:eatwhat_app/v2/core/theme/app_tokens.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AppThemeController.mode.value = AppThemeMode.dark;
  });

  test('夜场主题色板为炭黑珊瑚', () {
    expect(AppThemeController.isCream, isFalse);
    expect(AppPalette.night.toARGB32(), 0xFF121417);
    expect(AppPalette.moonlight.toARGB32(), 0xFFF4EFE6);
    expect(AppPalette.leaf.toARGB32(), 0xFFFF9270);
  });

  test('切换米色主题后色板代理为米色值', () async {
    await AppThemeController.setMode(AppThemeMode.cream);
    expect(AppThemeController.isCream, isTrue);
    expect(AppPalette.night.toARGB32(), 0xFFF7F3EA);
    expect(AppPalette.nightSurface.toARGB32(), 0xFFFFFDF8);
    expect(AppPalette.moonlight.toARGB32(), 0xFF241F1A);
    expect(AppPalette.leaf.toARGB32(), 0xFFC25B3D);
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
