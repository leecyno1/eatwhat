import 'dart:io';

import 'package:eatwhat_app/core/config/env_config.dart';
import 'package:eatwhat_app/core/services/howtocook_database_service.dart';
import 'package:eatwhat_app/core/services/unified_recipe_database_service.dart';
import 'package:eatwhat_app/v2/app_v2.dart';
import 'package:eatwhat_app/v2/core/data/models/recipe_model.dart';
import 'package:eatwhat_app/v2/core/navigation/app_v2_router.dart';
import 'package:eatwhat_app/v2/core/services/v2_recipe_execution_progress_service.dart';
import 'package:eatwhat_app/v2/core/theme/app_theme_controller.dart';
import 'package:eatwhat_app/v2/features/home/home_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:integration_test/integration_test.dart';
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

Future<void> pumpUntilVisible(WidgetTester tester, Finder finder) async {
  bool isReady() => finder.hitTestable().evaluate().any(
        (element) => ModalRoute.of(element)?.animation?.isCompleted ?? true,
      );

  for (var attempt = 0; attempt < 100 && !isReady(); attempt++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  expect(isReady(), isTrue, reason: '$finder must be visible after navigation');
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();
  late Directory testDirectory;
  late String originalDatabasePath;

  setUpAll(() async {
    testDirectory = await Directory.systemTemp.createTemp('eatwhat_smoke_');
    Hive.init(testDirectory.path);
    originalDatabasePath = await getDatabasesPath();
    await databaseFactory.setDatabasesPath(testDirectory.path);
  });

  tearDownAll(() async {
    await Hive.close();
    await HowToCookDatabaseService().close();
    final unifiedPath = path.join(testDirectory.path, 'unified_recipes.db');
    if (await databaseExists(unifiedPath)) {
      // Reuse sqflite's cached handle to close it before deleting test files.
      final database = await openReadOnlyDatabase(unifiedPath);
      await database.close();
    }
    await databaseFactory.setDatabasesPath(originalDatabasePath);
    await testDirectory.delete(recursive: true);
  });

  setUp(() {
    expect(EnvConfig.minimaxApiKey.trim().isEmpty, isTrue,
        reason: 'UI smoke tests must run without live AI credentials');
    SharedPreferences.setMockInitialValues({
      'cold_start_questionnaire_completed': true,
      'has_seen_onboarding_v2': true,
      'v2_home_generation_guide_seen': true,
      'v2_home_flip_hint_seen': true,
    });
    AppThemeController.mode.value = AppThemeMode.dark;
  });

  testWidgets('V2 首页、主题、收藏与做菜链路可交互', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: AppV2(),
      ),
    );
    await tester.pump(const Duration(seconds: 2));

    expect(find.byType(MaterialApp), findsOneWidget);
    expect(
        find.byKey(const ValueKey('taste-card-stage-shell')), findsOneWidget);
    expect(
        find.byKey(const ValueKey('home-requirement-input')), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('home-start-inference-button')));
    await pumpUntilVisible(tester, find.text('先收下几个口味气泡，或写一句今天想吃的'));

    await tester.tap(find.byKey(const ValueKey('home-theme-toggle')));
    await tester.pump(const Duration(milliseconds: 400));
    expect(AppThemeController.mode.value, AppThemeMode.cream);
    expect(tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
        ThemeMode.light);

    await tester.tap(find.byKey(const ValueKey('home-favorites-button')));
    await pumpUntilVisible(tester, find.text('还没有收藏偏好'));
    await tester.tap(find.text('菜品'));
    await pumpUntilVisible(tester, find.text('还没有收藏菜品'));
    expect(find.byType(CircularProgressIndicator), findsNothing);
    await tester.pageBack();
    await tester.pump(const Duration(milliseconds: 400));

    final router = GoRouter.of(tester.element(find.byType(HomePage)))
      ..go(AppV2Routes.resultDemo);
    await pumpUntilVisible(tester, find.text('就吃这个'));
    await tester.tap(find.byKey(const ValueKey('result-candidate-3')));
    await pumpUntilVisible(tester, find.text('N°02 / 03'));
    await tester.tap(find.text('就吃这个'));
    await pumpUntilVisible(tester, find.text('这道菜暂时没有可执行步骤。'));
    expect(find.text('红烧肉'), findsOneWidget);
    expect(find.byKey(const ValueKey('recipe-cooking-next-step-button')),
        findsNothing);
    await tester.tap(find.byKey(const ValueKey('recipe-cooking-close-button')));
    await tester.pump(const Duration(milliseconds: 400));
    expect(
        find.byKey(const ValueKey('recipe-cooking-mode-page')), findsNothing);

    final recipes = <RecipeModel>[];
    for (final name in const ['麻婆豆腐', '湖南家常红烧肉', '宫保鸡丁']) {
      final rows =
          await UnifiedRecipeDatabaseService.instance.searchRecipes(name);
      final row = rows.singleWhere((row) => row['dish_name'] == name);
      final recipe = RecipeModel.fromUnifiedDbRow(row);
      expect(recipe.ingredients, isNotEmpty, reason: name);
      expect(recipe.steps, isNotEmpty, reason: name);
      recipes.add(recipe);
    }
    final selectedRecipe = recipes[1];
    router.go(
      AppV2Routes.result,
      extra: AppV2ResultRouteData(
        recommendations: recipes,
        inferenceInput: demoInferenceInput,
        primarySource: 'unified_db',
        recalledCount: recipes.length,
      ),
    );
    await pumpUntilVisible(tester, find.text('就吃这个'));
    await tester
        .tap(find.byKey(ValueKey('result-candidate-${selectedRecipe.id}')));
    await pumpUntilVisible(tester, find.text('N°02 / 03'));
    await tester.tap(find.text('就吃这个'));
    await pumpUntilVisible(
      tester,
      find.byKey(const ValueKey('recipe-cooking-step-text-0')),
    );
    expect(find.text('做菜模式'), findsOneWidget);
    expect(find.text(selectedRecipe.name), findsOneWidget);
    expect(find.text(selectedRecipe.steps.first), findsOneWidget);
    expect(find.text('这道菜暂时没有可执行步骤。'), findsNothing);

    await tester
        .tap(find.byKey(const ValueKey('recipe-cooking-next-step-button')));
    await pumpUntilVisible(
      tester,
      find.text('第 2 / ${selectedRecipe.steps.length} 步 · '
          '完成 1/${selectedRecipe.steps.length}'),
    );
    expect(find.text(selectedRecipe.steps[1]), findsOneWidget);
    expect(
      await V2RecipeExecutionProgressService.instance
          .getCompletedStepIndexes(selectedRecipe.id),
      {0},
    );
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('冰箱找菜：真实数据库反查可做菜品', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: AppV2(),
      ),
    );
    await tester.pump(const Duration(seconds: 2));

    await pumpUntilVisible(
      tester,
      find.byKey(const ValueKey('home-pantry-entry')),
    );
    await tester.tap(find.byKey(const ValueKey('home-pantry-entry')));
    await pumpUntilVisible(tester, find.text('冰箱找菜'));

    await pumpUntilVisible(
      tester,
      find.byKey(const ValueKey('pantry-chip-鸡蛋')).hitTestable(),
    );
    await tester.tap(find.byKey(const ValueKey('pantry-chip-鸡蛋')));
    await tester.tap(find.byKey(const ValueKey('pantry-chip-番茄')));
    await tester.pump();
    await pumpUntilVisible(
      tester,
      find.byKey(const ValueKey('pantry-ingredient-confirm')).hitTestable(),
    );
    await tester.tap(find.byKey(const ValueKey('pantry-ingredient-confirm')));

    // 真实反查：结果页出现主操作条，且榜首菜与 DB 反查一致。
    await pumpUntilVisible(
      tester,
      find.byKey(const ValueKey('result-primary-confirm-bar')),
    );

    final rows = await UnifiedRecipeDatabaseService.instance
        .searchByPantryIngredients(['鸡蛋', '番茄']);
    expect(rows, isNotEmpty, reason: '真实库应能按鸡蛋+番茄反查到菜');
    final topName = rows.first['dish_name'].toString();
    expect(
      find.text(topName),
      findsWidgets,
      reason: '结果页应展示反查榜首菜：$topName',
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}
