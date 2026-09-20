import 'dart:async';
import 'dart:io';

import 'package:eatwhat_app/core/services/unified_recipe_database_service.dart';
import 'package:eatwhat_app/v2/core/services/v2_favorites_service.dart';
import 'package:eatwhat_app/v2/features/favorites/favorites_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite/sqflite.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  const channel = MethodChannel('com.tekartik.sqflite');
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  Completer<void>? queryGate;
  var failNextQuery = false;
  late Directory directory;

  setUpAll(() async {
    directory = await Directory.systemTemp.createTemp('eatwhat_favorites_');
    databaseFactory = databaseFactorySqflitePlugin;
    messenger.setMockMethodCallHandler(channel, (call) async {
      switch (call.method) {
        case 'getDatabasesPath':
          return directory.path;
        case 'openDatabase':
          return {'id': 1};
        case 'closeDatabase':
          return null;
        case 'query':
          if (queryGate != null) await queryGate!.future;
          if (failNextQuery) {
            failNextQuery = false;
            throw PlatformException(
                code: 'sqlite_error', message: 'query failed');
          }
          final sql = call.arguments['sql'] as String;
          if (!sql.contains('FROM dish d')) return <Map<String, Object?>>[];
          final arguments = call.arguments['arguments'] as List;
          return [
            for (final id in arguments.take(arguments.length - 1))
              {'dish_id': id, 'dish_name': '收藏菜品 $id', 'recipe_id': id},
          ];
        default:
          throw UnsupportedError('Unexpected sqflite method: ${call.method}');
      }
    });
    await UnifiedRecipeDatabaseService.instance.ensureInitialized();
  });

  tearDownAll(() async {
    final database = await openDatabase(
      '${directory.path}/unified_recipes.db',
      readOnly: true,
    );
    await database.close();
    messenger.setMockMethodCallHandler(channel, null);
    databaseFactory = null;
    await directory.delete(recursive: true);
  });

  testWidgets('取消收藏刷新较慢时仍保留列表与滚动位置', (tester) async {
    SharedPreferences.setMockInitialValues({
      'v2_favorite_recipe_ids': [for (var id = 1; id <= 60; id++) '$id'],
    });
    await tester.pumpWidget(const MaterialApp(home: FavoritesPageV2()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('菜品'));
    await tester.pumpAndSettle();
    final list = find.byType(ListView);
    await tester.drag(list, const Offset(0, -500));
    await tester.pumpAndSettle();
    final scrollable =
        find.descendant(of: list, matching: find.byType(Scrollable));
    final state = tester.state<ScrollableState>(scrollable);
    final offset = state.position.pixels;
    expect(offset, greaterThan(0));

    final gate = Completer<void>();
    queryGate = gate;
    addTearDown(() {
      if (!gate.isCompleted) gate.complete();
      queryGate = null;
    });
    await tester.tap(find.byIcon(Icons.favorite).hitTestable().first);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 200));
    expect(find.byType(TabBarView), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
    expect(identical(tester.state<ScrollableState>(scrollable), state), isTrue);

    gate.complete();
    await tester.pumpAndSettle();
    expect(identical(tester.state<ScrollableState>(scrollable), state), isTrue);
    expect(state.position.pixels, offset);
    expect(
        await V2FavoritesService.instance.getFavoriteDishIds(), hasLength(59));
    expect(find.text('收藏加载失败'), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets('并发收藏刷新中后续成功会清除先前的错误状态', (tester) async {
    SharedPreferences.setMockInitialValues({
      'v2_favorite_recipe_ids': ['1', '2', '3'],
    });
    await tester.pumpWidget(const MaterialApp(home: FavoritesPageV2()));
    await tester.pumpAndSettle();
    await tester.tap(find.text('菜品'));
    await tester.pumpAndSettle();

    final gate = Completer<void>();
    queryGate = gate;
    failNextQuery = true;
    addTearDown(() {
      if (!gate.isCompleted) gate.complete();
      queryGate = null;
      failNextQuery = false;
    });
    await tester.tap(find.byIcon(Icons.favorite).hitTestable().first);
    await tester.pump();
    await tester.tap(find.byIcon(Icons.favorite).hitTestable().at(1));
    await tester.pump();
    expect(await V2FavoritesService.instance.getFavoriteDishIds(), {'3'});

    gate.complete();
    await tester.pumpAndSettle();
    expect(find.text('收藏加载失败'), findsNothing);
    expect(find.text('收藏菜品 3'), findsOneWidget);
    expect(find.byIcon(Icons.favorite), findsOneWidget);
    expect(failNextQuery, isFalse);
    expect(tester.takeException(), isNull);
  });
}
