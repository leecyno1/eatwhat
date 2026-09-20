import 'dart:async';

import 'package:eatwhat_app/core/config/env_config.dart';
import 'package:eatwhat_app/core/services/unified_recipe_database_service.dart';
import 'package:eatwhat_app/v2/core/services/v2_favorites_service.dart';
import 'package:eatwhat_app/v2/core/theme/app_theme_controller.dart';
import 'package:eatwhat_app/v2/features/favorites/favorites_page.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

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

  testWidgets('Web 收藏加载失败可重复重试且保留已存收藏', (tester) async {
    await V2FavoritesService.instance.setFavoriteDishIds({'144'});
    var failedLoads = 0;
    final messenger =
        TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
          ..setMockMessageHandler('flutter/assets', (message) async {
            if (const StringCodec().decodeMessage(message) ==
                'assets/data/unified_recipes.db') {
              failedLoads++;
            }
            return null;
          });
    addTearDown(() => messenger.setMockMessageHandler('flutter/assets', null));

    await tester.pumpWidget(const MaterialApp(home: FavoritesPageV2()));
    await waitFor(tester, find.text('收藏加载失败'));
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(find.text('还没有收藏菜品'), findsNothing);
    expect(await V2FavoritesService.instance.getFavoriteDishIds(), {'144'});
    await tester.tap(find.text('重试'));
    await waitFor(tester, find.text('收藏加载失败'));
    expect(failedLoads, 2);
    expect(tester.takeException(), isNull);

    final delayedAsset = Completer<ByteData?>();
    messenger.setMockMessageHandler(
        'flutter/assets', (_) => delayedAsset.future);
    await tester.tap(find.text('重试'));
    await tester.pump();
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.text('重试'), findsNothing);
    final pendingFailure = expectLater(
      UnifiedRecipeDatabaseService.instance.ensureInitialized(),
      throwsA(isA<FlutterError>()),
    );
    await tester.pumpWidget(const SizedBox.shrink());
    delayedAsset.complete(null);
    await pendingFailure;
    await tester.pump();
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const MaterialApp(home: FavoritesPageV2()));
    await waitFor(tester, find.text('收藏加载失败'));
    messenger.setMockMessageHandler('flutter/assets', null);
    await tester.tap(find.text('重试'));
    await waitFor(tester, find.text('还没有收藏偏好'));
    await tester.tap(find.text('菜品'));
    await waitFor(tester, find.text('湖南家常红烧肉'));
    expect(find.text('收藏加载失败'), findsNothing);
    expect(await V2FavoritesService.instance.getFavoriteDishIds(), {'144'});
    expect(tester.takeException(), isNull);
    await tester.pumpWidget(const SizedBox.shrink());
  }, skip: !kIsWeb);
}
