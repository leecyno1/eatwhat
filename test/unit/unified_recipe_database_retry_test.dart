import 'dart:io';

import 'package:eatwhat_app/core/services/unified_recipe_database_service.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';

import '../test_bootstrap.dart';

void main() {
  late Directory directory;

  setUpAll(() async {
    await bootstrapTestEnvironment();
    directory =
        await Directory.systemTemp.createTemp('eatwhat_database_retry_');
    await databaseFactory.setDatabasesPath(directory.path);
  });

  tearDownAll(() async {
    final database = await openReadOnlyDatabase(
      '${directory.path}/unified_recipes.db',
    );
    await database.close();
    await directory.delete(recursive: true);
  });

  test('initialization can retry after a database asset load failure',
      () async {
    final messenger = TestDefaultBinaryMessengerBinding
        .instance.defaultBinaryMessenger
      ..setMockMessageHandler('flutter/assets', (_) async => null);
    addTearDown(() => messenger.setMockMessageHandler('flutter/assets', null));
    final service = UnifiedRecipeDatabaseService.instance;

    await expectLater(
        service.ensureInitialized(), throwsA(isA<FlutterError>()));
    messenger.setMockMessageHandler('flutter/assets', null);

    await service.ensureInitialized();
    expect(await service.fetchDefaultRecipes(limit: 1), hasLength(1));
  });
}
