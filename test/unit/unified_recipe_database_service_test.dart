import 'dart:io';

import 'package:eatwhat_app/core/services/unified_recipe_database_service.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../test_bootstrap.dart';

void main() {
  setUpAll(() async {
    await bootstrapTestEnvironment();
  });

  group('UnifiedRecipeDatabaseService', () {
    test('fts search SQL matches against the real FTS table name', () {
      const sql = UnifiedRecipeDatabaseService.ftsSearchSql;

      expect(sql, contains('JOIN dish_fts ON dish_fts.rowid = d.id'));
      expect(sql, contains('WHERE dish_fts MATCH ?'));
      expect(sql, isNot(contains('WHERE fts MATCH ?')));
    });

    test('tag recipe search SQL uses the dish_tag relation', () {
      const sql = UnifiedRecipeDatabaseService.tagRecipeSearchSql;

      expect(sql, contains('JOIN dish_tag dt ON dt.dish_id = d.id'));
      expect(sql, contains('WHERE dt.tag_id IN (__TAG_ID_PLACEHOLDERS__)'));
      expect(sql, contains('ORDER BY COUNT(dt.tag_id) DESC'));
    });

    test('pairing search SQL reads rule pairings by dish id', () {
      const sql = UnifiedRecipeDatabaseService.pairingSearchSql;

      expect(sql, contains('FROM pairing'));
      expect(sql, contains('WHERE dish_id = ?'));
      expect(sql, contains('ORDER BY strength DESC'));
    });

    test('can fetch corpus pairings from the bundled unified database',
        () async {
      final pairings = await UnifiedRecipeDatabaseService.instance
          .fetchPairingsForDishId('dish-1');

      expect(pairings, isNotEmpty);
      expect(pairings.first.dishId, '1');
      expect(pairings.first.name, isNotEmpty);
      expect(pairings.first.source, 'rule');
    });

    test('runtime database copy stays byte-identical to the bundled asset',
        () async {
      await UnifiedRecipeDatabaseService.instance.ensureInitialized();
      final assetData = await rootBundle.load('assets/data/unified_recipes.db');
      final assetBytes = assetData.buffer.asUint8List(
        assetData.offsetInBytes,
        assetData.lengthInBytes,
      );
      final installedPath =
          join(await getDatabasesPath(), 'unified_recipes.db');
      final installedBytes = await File(installedPath).readAsBytes();

      expect(installedBytes, orderedEquals(assetBytes));
    });

    test('can fetch deterministic default recipes from the bundled database',
        () async {
      final recipes = await UnifiedRecipeDatabaseService.instance
          .fetchDefaultRecipes(limit: 12);

      expect(recipes, isNotEmpty);
      expect(recipes.length, lessThanOrEqualTo(12));
      expect(recipes.every((row) => '${row['dish_name']}'.trim().isNotEmpty),
          isTrue);
      expect(
        recipes.every(
          (row) =>
              row['tags'] is List<String> &&
              row['ingredients'] is List<Map<String, dynamic>> &&
              row['steps'] is List<Map<String, dynamic>> &&
              row['nutrition'] is Map<String, dynamic>,
        ),
        isTrue,
      );
      expect(
        recipes.any(
          (row) =>
              (row['ingredients'] as List).isNotEmpty &&
              (row['steps'] as List).isNotEmpty,
        ),
        isTrue,
      );
    });

    test('batch hydration keeps an 80-recipe local pool within latency budget',
        () async {
      final stopwatch = Stopwatch()..start();
      final recipes =
          await UnifiedRecipeDatabaseService.instance.fetchDefaultRecipes();
      stopwatch.stop();

      expect(recipes, hasLength(80));
      expect(
        stopwatch.elapsed,
        lessThan(const Duration(seconds: 2)),
        reason: '80 道菜批量富化耗时 ${stopwatch.elapsedMilliseconds}ms',
      );
    });

    group('searchByPantryIngredients', () {
      test('pantry search SQL joins ingredients and ranks by match count',
          () {
        const sql = UnifiedRecipeDatabaseService.pantrySearchSql;

        expect(sql, contains('FROM recipe_ingredient ri'));
        expect(sql, contains('LEFT JOIN ingredient ing ON ing.id = ri.ingredient_id'));
        expect(sql, contains('__PANTRY_MATCHES__'));
        expect(sql, contains('__PANTRY_WHERE__'));
        expect(sql, contains('ORDER BY pantry_matched DESC, pantry_total ASC'));
      });

      test('按冰箱食材反查可做菜品并带完整行水合', () async {
        final rows = await UnifiedRecipeDatabaseService.instance
            .searchByPantryIngredients(['鸡蛋', '番茄'], limit: 10);

        expect(rows, isNotEmpty);
        expect(
          rows.every(
            (row) => row['ingredients'] is List<Map<String, dynamic>>,
          ),
          isTrue,
        );
        final topIngredients = (rows.first['ingredients'] as List)
            .map((e) => (e as Map)['name']?.toString() ?? '')
            .toSet();
        expect(
          topIngredients.any((name) => name.contains('蛋') || name.contains('番茄')),
          isTrue,
          reason: '榜首菜应命中冰箱食材，实际食材：$topIngredients',
        );
      });

      test('空食材列表返回空结果', () async {
        final rows = await UnifiedRecipeDatabaseService.instance
            .searchByPantryIngredients([], limit: 10);

        expect(rows, isEmpty);
      });
    });
  });
}
