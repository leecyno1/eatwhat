import 'package:eatwhat_app/v2/core/theme/app_theme_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 自动主题（昼夜偏好记忆）控制器行为。
void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
    AppThemeController.autoEnabled.value = false;
    AppThemeController.dayPreference.value = AppThemeMode.cream;
    AppThemeController.nightPreference.value = AppThemeMode.dark;
    AppThemeController.applyBrightness(Brightness.light);
    AppThemeController.mode.value = AppThemeMode.cream;
  });

  test('新用户默认开启自动并落在白天偏好', () async {
    await AppThemeController.loadStored();
    expect(AppThemeController.autoEnabled.value, isTrue);
    expect(AppThemeController.mode.value, AppThemeMode.cream);
  });

  test('老用户保留手动主题且不开自动', () async {
    SharedPreferences.setMockInitialValues({'v2_app_theme_mode': 'neon'});
    await AppThemeController.loadStored();
    expect(AppThemeController.autoEnabled.value, isFalse);
    expect(AppThemeController.mode.value, AppThemeMode.neon);
  });

  test('自动模式按系统亮度解析昼夜偏好并记忆手动选择', () async {
    await AppThemeController.setAuto(true);

    // 白天选青瓷 → 记为白天偏好并立即生效。
    await AppThemeController.setMode(AppThemeMode.celadon);
    expect(AppThemeController.dayPreference.value, AppThemeMode.celadon);
    expect(AppThemeController.mode.value, AppThemeMode.celadon);

    // 入夜 → 解析到夜晚偏好（默认墨夜）。
    AppThemeController.applyBrightness(Brightness.dark);
    expect(AppThemeController.mode.value, AppThemeMode.dark);

    // 夜里选霓虹 → 记为夜晚偏好。
    await AppThemeController.setMode(AppThemeMode.neon);
    expect(AppThemeController.nightPreference.value, AppThemeMode.neon);
    expect(AppThemeController.mode.value, AppThemeMode.neon);

    // 回到白天 → 青瓷；再入夜 → 霓虹。
    AppThemeController.applyBrightness(Brightness.light);
    expect(AppThemeController.mode.value, AppThemeMode.celadon);
    AppThemeController.applyBrightness(Brightness.dark);
    expect(AppThemeController.mode.value, AppThemeMode.neon);
  });

  test('开启自动时把当前手动主题记入当前时段', () async {
    await AppThemeController.setMode(AppThemeMode.dunhuang);
    await AppThemeController.setAuto(true);
    expect(AppThemeController.dayPreference.value, AppThemeMode.dunhuang);
    expect(AppThemeController.mode.value, AppThemeMode.dunhuang);
  });

  test('关闭自动保留当前皮肤且不再随亮度变化', () async {
    await AppThemeController.setAuto(true);
    AppThemeController.applyBrightness(Brightness.dark);
    await AppThemeController.setMode(AppThemeMode.neon);

    await AppThemeController.setAuto(false);
    expect(AppThemeController.autoEnabled.value, isFalse);
    expect(AppThemeController.mode.value, AppThemeMode.neon);

    AppThemeController.applyBrightness(Brightness.light);
    expect(AppThemeController.mode.value, AppThemeMode.neon);
  });

  test('自动状态与昼夜偏好持久化往返', () async {
    await AppThemeController.setAuto(true);
    await AppThemeController.setMode(AppThemeMode.celadon);
    AppThemeController.applyBrightness(Brightness.dark);
    await AppThemeController.setMode(AppThemeMode.neon);

    // 模拟新进程：重置内存态，仅保留持久化值。
    AppThemeController.autoEnabled.value = false;
    AppThemeController.dayPreference.value = AppThemeMode.cream;
    AppThemeController.nightPreference.value = AppThemeMode.dark;
    AppThemeController.mode.value = AppThemeMode.cream;
    AppThemeController.applyBrightness(Brightness.dark);

    await AppThemeController.loadStored();
    expect(AppThemeController.autoEnabled.value, isTrue);
    expect(AppThemeController.dayPreference.value, AppThemeMode.celadon);
    expect(AppThemeController.nightPreference.value, AppThemeMode.neon);
    expect(AppThemeController.mode.value, AppThemeMode.neon);
  });

  test('重复施加相同亮度不触发重建通知', () async {
    await AppThemeController.setAuto(true);
    var notifications = 0;
    void listener() => notifications++;
    AppThemeController.mode.addListener(listener);
    addTearDown(() => AppThemeController.mode.removeListener(listener));

    AppThemeController.applyBrightness(Brightness.light);
    AppThemeController.applyBrightness(Brightness.light);
    expect(notifications, 0);

    AppThemeController.applyBrightness(Brightness.dark);
    expect(notifications, 1);
  });
}