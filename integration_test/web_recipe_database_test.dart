import 'package:crypto/crypto.dart';
import 'package:eatwhat_app/core/config/env_config.dart';
import 'package:eatwhat_app/core/services/howtocook_database_service.dart';
import 'package:eatwhat_app/core/services/unified_recipe_database_service.dart';
import 'package:eatwhat_app/core/services/web_recipe_database.dart';
import 'package:eatwhat_app/v2/core/data/models/recipe_model.dart';
import 'package:eatwhat_app/v2/core/services/v2_favorites_service.dart';
import 'package:eatwhat_app/v2/core/theme/app_theme_controller.dart';
import 'package:eatwhat_app/v2/features/favorites/favorites_page.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi_web/sqflite_ffi_web.dart';

Future<void> waitFor(WidgetTester tester, Finder finder) async {
  for (var attempt = 0;
      attempt < 200 && finder.hitTestable().evaluate().isEmpty;
      attempt++) {
    await tester.pump(const Duration(milliseconds: 100));
  }
  expect(finder.hitTestable(), findsWidgets);
}

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    expect(kIsWeb, isTrue);
    expect(EnvConfig.minimaxApiKey.trim().isEmpty, isTrue);
    SharedPreferences.setMockInitialValues({});
    AppThemeController.mode.value = AppThemeMode.cream;
  });

  testWidgets('Web 收藏支持空态、真实菜谱、做菜与取消收藏', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: FavoritesPageV2()));
    await waitFor(tester, find.text('还没有收藏偏好'));
    await tester.tap(find.text('菜品'));
    await waitFor(tester, find.text('还没有收藏菜品'));
    expect(find.byType(CircularProgressIndicator), findsNothing);
    await tester.pumpWidget(const SizedBox.shrink());

    final rows =
        await UnifiedRecipeDatabaseService.instance.searchRecipes('湖南家常红烧肉');
    final recipe = RecipeModel.fromUnifiedDbRow(
      rows.singleWhere((row) => row['dish_name'] == '湖南家常红烧肉'),
    );
    expect(recipe.steps, isNotEmpty);
    await V2FavoritesService.instance.setFavoriteDishIds({recipe.id});
    await tester.pumpWidget(const MaterialApp(home: FavoritesPageV2()));
    await waitFor(tester, find.text('还没有收藏偏好'));
    await tester.tap(find.text('菜品'));
    await waitFor(tester, find.text(recipe.name));
    await tester.tap(find.text(recipe.name));
    final startCooking =
        find.byKey(const ValueKey('recipe-start-cooking-button'));
    await waitFor(tester, startCooking);
    await tester.tap(startCooking);
    await waitFor(tester, find.text(recipe.steps.first));
    await tester
        .tap(find.byKey(const ValueKey('recipe-cooking-next-step-button')));
    await waitFor(tester, find.text(recipe.steps[1]));
    await tester.tap(find.byKey(const ValueKey('recipe-cooking-close-button')));
    final backButton = find.byIcon(Icons.arrow_back_ios_new);
    await waitFor(tester, backButton);
    await tester.tap(backButton);
    await waitFor(tester, find.byIcon(Icons.favorite));
    await tester.tap(find.byIcon(Icons.favorite));
    await waitFor(tester, find.text('还没有收藏菜品'));
    expect(await V2FavoritesService.instance.getFavoriteDishIds(), isEmpty);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  }, skip: !kIsWeb);

  testWidgets('Web 取消收藏时保留长列表与滚动位置', (tester) async {
    await V2FavoritesService.instance.setFavoriteDishIds({
      for (var id = 1; id <= 60; id++) '$id',
    });
    await tester.pumpWidget(const MaterialApp(home: FavoritesPageV2()));
    await waitFor(tester, find.text('还没有收藏偏好'));
    await tester.tap(find.text('菜品'));
    await waitFor(tester, find.byIcon(Icons.favorite));
    final list = find.byType(ListView);
    await tester.drag(list, const Offset(0, -500));
    await tester.pumpAndSettle();
    final scrollable = find.descendant(
      of: list,
      matching: find.byType(Scrollable),
    );
    final state = tester.state<ScrollableState>(scrollable);
    final offset = state.position.pixels;
    expect(offset, greaterThan(0));

    await tester.tap(find.byIcon(Icons.favorite).hitTestable().first);
    await tester.pump();
    expect(find.byType(TabBarView), findsOneWidget);
    await tester.pumpAndSettle();
    expect(
        await V2FavoritesService.instance.getFavoriteDishIds(), hasLength(59));
    expect(identical(tester.state<ScrollableState>(scrollable), state), isTrue);
    expect(state.position.pixels, offset);
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  }, skip: !kIsWeb);

  testWidgets('Web HowToCook 从打包库加载完整步骤', (tester) async {
    final service = HowToCookDatabaseService();
    final rows = await service.searchRecipesAdvanced(searchQuery: '东坡肉');
    final row = rows.singleWhere((row) => row['name'] == '东坡肉');
    final detail = await service.getCompleteRecipe(row['id'].toString());
    expect(detail, isNotNull);
    expect(detail!['ingredients'], isNotEmpty);
    expect(detail['steps'], isNotEmpty);
    await service.close();
    final reopened = await service.getCompleteRecipe(row['id'].toString());
    expect(reopened!['steps'], detail['steps']);
    await service.close();
  }, skip: !kIsWeb);

  testWidgets('Web 关闭一个连接不影响其他读连接', (tester) async {
    final first = await openWebRecipeDatabase('howtocook_enhanced_recipes.db');
    final second = await openWebRecipeDatabase('howtocook_enhanced_recipes.db');
    addTearDown(second.close);
    await first.close();
    final rows = await second
        .rawQuery('SELECT COUNT(*) AS count FROM howtocook_recipes');
    expect(rows.single['count'], greaterThan(0));
  }, skip: !kIsWeb);

  testWidgets('Web 自动恢复中断导入留下的空数据库', (tester) async {
    const assetName = 'howtocook_enhanced_recipes.db';
    final data = await rootBundle.load('assets/data/$assetName');
    final bytes =
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    final path = '/recipe_assets/${sha256.convert(bytes)}/$assetName';
    await databaseFactoryFfiWeb.writeDatabaseBytes(path, Uint8List(0));
    final database = await openWebRecipeDatabase(assetName);
    addTearDown(database.close);
    final rows = await database
        .rawQuery('SELECT COUNT(*) AS count FROM howtocook_recipes');
    expect(rows.single['count'], greaterThan(0));
  }, skip: !kIsWeb);

  testWidgets('Web 配置初始化不请求未打包的环境文件', (tester) async {
    final requestedAssets = <String>[];
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          ..setMockMessageHandler('flutter/assets', (message) async {
            requestedAssets.add(const StringCodec().decodeMessage(message)!);
            return null;
          });
    addTearDown(() => messenger.setMockMessageHandler('flutter/assets', null));
    await EnvConfig.init();
    expect(requestedAssets, isNot(contains('.env')));
  }, skip: !kIsWeb);
}
