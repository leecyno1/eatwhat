import 'dart:io';

import 'package:eatwhat_app/core/services/auth_service.dart';
import 'package:eatwhat_app/core/services/howtocook_database_service.dart';
import 'package:eatwhat_app/v2/app_v2.dart';
import 'package:eatwhat_app/v2/core/theme/app_theme_controller.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

/// Screen-recording walkthrough for App Review.
///
/// Runs the real UI against the bundled recipe database with human-paced
/// pauses so the simulator recording shows each screen clearly.
Future<void> _hold(WidgetTester tester, int milliseconds) async {
  final steps = (milliseconds / 100).ceil();
  for (var i = 0; i < steps; i++) {
    await tester.pump(const Duration(milliseconds: 100));
    await Future<void>.delayed(const Duration(milliseconds: 100));
  }
}

Future<void> _waitFor(WidgetTester tester, Finder finder,
    {int attempts = 120}) async {
  for (var i = 0; i < attempts; i++) {
    if (finder.evaluate().isNotEmpty) return;
    await tester.pump(const Duration(milliseconds: 100));
  }
  expect(finder, findsWidgets);
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  late Directory testDirectory;
  late String originalDatabasePath;

  setUpAll(() async {
    testDirectory = await Directory.systemTemp.createTemp('eatwhat_demo_');
    Hive.init(testDirectory.path);
    originalDatabasePath = await getDatabasesPath();
    await databaseFactory.setDatabasesPath(testDirectory.path);
  });

  tearDownAll(() async {
    await Hive.close();
    await HowToCookDatabaseService().close();
    final unifiedPath = path.join(testDirectory.path, 'unified_recipes.db');
    if (await databaseExists(unifiedPath)) {
      final database = await openReadOnlyDatabase(unifiedPath);
      await database.close();
    }
    await databaseFactory.setDatabasesPath(originalDatabasePath);
    await testDirectory.delete(recursive: true);
  });

  testWidgets('App Review walkthrough', (tester) async {
    SharedPreferences.setMockInitialValues({
      'cold_start_questionnaire_completed': true,
      'has_seen_onboarding_v2': true,
      'v2_home_generation_guide_seen': true,
      'v2_home_flip_hint_seen': true,
    });
    AppThemeController.mode.value = AppThemeMode.dark;
    await AuthService.initialize();

    await tester.pumpWidget(const ProviderScope(child: AppV2()));
    await _hold(tester, 3000);

    // 冰箱找菜：选两样现有食材，反查可做的菜。
    await tester.tap(find.byKey(const ValueKey('home-pantry-entry')));
    await _waitFor(tester, find.text('冰箱找菜'));
    await _hold(tester, 1500);
    await tester.tap(find.byKey(const ValueKey('pantry-chip-鸡蛋')));
    await _hold(tester, 700);
    await tester.tap(find.byKey(const ValueKey('pantry-chip-番茄')));
    await _hold(tester, 900);
    await tester.tap(find.byKey(const ValueKey('pantry-ingredient-confirm')));
    await _waitFor(
        tester, find.byKey(const ValueKey('result-primary-confirm-bar')));
    await _hold(tester, 3000);

    // 进入菜谱详情与做菜模式。
    await tester.tap(find.text('就吃这个'));
    await _waitFor(tester, find.byKey(const ValueKey('recipe-cooking-mode-page')));
    await _hold(tester, 2500);
    final nextStep =
        find.byKey(const ValueKey('recipe-cooking-next-step-button'));
    if (nextStep.evaluate().isNotEmpty) {
      await tester.tap(nextStep);
      await _hold(tester, 2000);
    }
    final close =
        find.byKey(const ValueKey('recipe-cooking-close-button'));
    if (close.evaluate().isNotEmpty) {
      await tester.tap(close);
      await _hold(tester, 1200);
    }
    final navigator = Navigator.of(tester.element(find.byType(Scaffold).first));
    navigator.popUntil((route) => route.isFirst);
    await _hold(tester, 2000);

    // 登录演示账号。
    await tester.tap(find.byKey(const ValueKey('home-account-button')));
    await _waitFor(tester, find.byKey(const ValueKey('eatwhat-auth-sheet')));
    await _hold(tester, 1200);
    await tester.enterText(
        find.byKey(const ValueKey('auth-login-username')), '17600806220');
    await _hold(tester, 600);
    await tester.enterText(
        find.byKey(const ValueKey('auth-login-password')), 'Iv19whot@123');
    await _hold(tester, 600);
    await tester.tap(find.byKey(const ValueKey('auth-login-submit')));
    await _hold(tester, 2500);
    if (!AuthService.isLoggedIn) {
      final result = await AuthService.login(
        usernameOrEmail: '17600806220',
        password: 'Iv19whot@123',
      );
      debugPrint('demo login fallback: ${result.success} ${result.message}');
      await _hold(tester, 800);
    }

    // 账号面板与注销入口（展示确认弹窗后取消）。
    for (var i = 0; i < 4; i++) {
      if (find.byKey(const ValueKey('eatwhat-account-sheet')).evaluate().isNotEmpty) {
        break;
      }
      await tester.tap(find.byKey(const ValueKey('home-account-button')),
          warnIfMissed: false);
      await _hold(tester, 900);
    }
    await _waitFor(tester, find.byKey(const ValueKey('eatwhat-account-sheet')));
    await _hold(tester, 1500);
    final deleteButton =
        find.byKey(const ValueKey('auth-delete-account-button'));
    if (deleteButton.evaluate().isNotEmpty) {
      await tester.tap(deleteButton);
      await _hold(tester, 2200);
      final cancel = find.text('取消');
      if (cancel.evaluate().isNotEmpty) {
        await tester.tap(cancel.last);
        await _hold(tester, 1200);
      }
    }
    await tester.tapAt(const Offset(20, 80));
    await _hold(tester, 1500);
  });
}
