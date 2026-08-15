import 'dart:convert';
import 'dart:io';

import 'package:eatwhat_app/v2/core/data/models/recipe_pairing_model.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

/// Provides read-only access to the unified recipes SQLite database.
class UnifiedRecipeDatabaseService {
  UnifiedRecipeDatabaseService._internal();
  static final UnifiedRecipeDatabaseService instance =
      UnifiedRecipeDatabaseService._internal();

  static const String _databaseName = 'unified_recipes.db';
  Future<Database>? _databaseFuture;

  Future<Database> get _db async {
    return _databaseFuture ??= _initDatabase();
  }

  Future<void> ensureInitialized() async {
    await _db;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _databaseName);
    await _syncDatabaseFromAssets(path);
    return openDatabase(path, readOnly: true);
  }

  Future<void> _syncDatabaseFromAssets(String path) async {
    final assetBytes = await _loadDatabaseAssetBytes();
    final databaseFile = File(path);
    if (!await _needsAssetRefresh(databaseFile, assetBytes)) return;

    await Directory(dirname(path)).create(recursive: true);
    await databaseFile.writeAsBytes(assetBytes, flush: true);
  }

  Future<Uint8List> _loadDatabaseAssetBytes() async {
    final data = await rootBundle.load('assets/data/$_databaseName');
    return data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
  }

  Future<bool> _needsAssetRefresh(
    File databaseFile,
    Uint8List assetBytes,
  ) async {
    try {
      if (!databaseFile.existsSync()) return true;
      if (databaseFile.lengthSync() != assetBytes.length) return true;
      final installedBytes = await databaseFile.readAsBytes();
      return !listEquals(installedBytes, assetBytes);
    } catch (_) {
      return true;
    }
  }

  Future<List<Map<String, dynamic>>> fetchTopRecipes(
      {int limit = 40, int offset = 0}) async {
    final db = await _db;
    final rows = await db.rawQuery(
      '''
      SELECT d.id            AS dish_id,
             d.name_cn       AS dish_name,
             d.cuisine       AS cuisine,
             d.taste_profile AS taste_profile,
             d.cooking_methods AS cooking_methods,
             d.scenes        AS scenes,
             d.health_tags   AS health_tags,
             d.main_ingredients AS main_ingredients,
             d.popularity_score AS popularity_score,
             d.average_rating   AS average_rating,
             rv.id           AS recipe_id,
             rv.source       AS source,
             rv.source_recipe_id AS source_recipe_id,
             rv.title        AS recipe_title,
             rv.description  AS recipe_description,
             rv.difficulty   AS difficulty,
             rv.total_time_minutes AS total_time_minutes,
             rv.servings     AS servings,
             rv.cover_image_url AS cover_image_url
      FROM dish d
      JOIN recipe_variant rv ON rv.dish_id = d.id
      ORDER BY d.popularity_score DESC, d.id ASC
      LIMIT ? OFFSET ?
      ''',
      [limit, offset],
    );
    return _hydrateRows(rows);
  }

  /// Returns a deterministic pool of canonical, structured local recipes.
  ///
  /// This is the final local fallback when tag and text recall cannot produce
  /// a candidate set. It deliberately ranks by data completeness and stable
  /// ids instead of inventing popularity or rating values that the bundled
  /// database does not contain.
  Future<List<Map<String, dynamic>>> fetchDefaultRecipes({
    int limit = 80,
  }) async {
    final db = await _db;
    final rows = await db.rawQuery(defaultRecipeSearchSql, [limit]);
    return _hydrateRows(rows);
  }

  Future<List<Map<String, dynamic>>> fetchRecipesByCuisine(
    String cuisine, {
    int limit = 30,
  }) async {
    final db = await _db;
    final rows = await db.rawQuery(
      '''
      SELECT d.id AS dish_id,
             d.name_cn AS dish_name,
             d.cuisine,
             d.taste_profile,
             d.cooking_methods,
             d.scenes,
             d.health_tags,
             d.main_ingredients,
             d.popularity_score,
             d.average_rating,
             rv.id AS recipe_id,
             rv.source,
             rv.source_recipe_id,
             rv.title AS recipe_title,
             rv.description AS recipe_description,
             rv.difficulty,
             rv.total_time_minutes,
             rv.servings,
             rv.cover_image_url
      FROM dish d
      JOIN recipe_variant rv ON rv.dish_id = d.id
      WHERE LOWER(d.cuisine) = LOWER(?)
      ORDER BY d.popularity_score DESC
      LIMIT ?
      ''',
      [cuisine, limit],
    );
    return _hydrateRows(rows);
  }

  Future<List<Map<String, dynamic>>> fetchRecipesByDishIds(
    List<String> dishIds, {
    int limit = 50,
  }) async {
    final ids = dishIds.map(int.tryParse).whereType<int>().toSet().toList();
    if (ids.isEmpty) return [];

    final db = await _db;
    final placeholders = List.filled(ids.length, '?').join(',');

    final rows = await db.rawQuery(
      '''
      SELECT d.id            AS dish_id,
             d.name_cn       AS dish_name,
             d.cuisine       AS cuisine,
             d.taste_profile AS taste_profile,
             d.cooking_methods AS cooking_methods,
             d.scenes        AS scenes,
             d.health_tags   AS health_tags,
             d.main_ingredients AS main_ingredients,
             d.popularity_score AS popularity_score,
             d.average_rating   AS average_rating,
             rv.id           AS recipe_id,
             rv.source       AS source,
             rv.source_recipe_id AS source_recipe_id,
             rv.title        AS recipe_title,
             rv.description  AS recipe_description,
             rv.difficulty   AS difficulty,
             rv.total_time_minutes AS total_time_minutes,
             rv.servings     AS servings,
             rv.cover_image_url AS cover_image_url
      FROM dish d
      JOIN recipe_variant rv
        ON rv.id = (
          SELECT id
          FROM recipe_variant
          WHERE dish_id = d.id
          ORDER BY id ASC
          LIMIT 1
        )
      WHERE d.id IN ($placeholders)
      ORDER BY d.popularity_score DESC, d.id ASC
      LIMIT ?
      ''',
      [...ids, limit],
    );

    return _hydrateRows(rows);
  }

  Future<List<Map<String, dynamic>>> searchRecipes(String query,
      {int limit = 40}) async {
    final db = await _db;
    final normalized = _buildFtsQuery(query);
    final rows = await db.rawQuery(ftsSearchSql, [normalized, limit]);
    if (rows.isNotEmpty) {
      return _hydrateRows(rows);
    }

    // Fallback to LIKE search
    final likeRows = await db.rawQuery(
      '''
      SELECT d.id AS dish_id,
             d.name_cn AS dish_name,
             d.cuisine,
             d.taste_profile,
             d.cooking_methods,
             d.scenes,
             d.health_tags,
             d.main_ingredients,
             d.popularity_score,
             d.average_rating,
             rv.id AS recipe_id,
             rv.source,
             rv.source_recipe_id,
             rv.title AS recipe_title,
             rv.description AS recipe_description,
             rv.difficulty,
             rv.total_time_minutes,
             rv.servings,
             rv.cover_image_url
      FROM dish d
      JOIN recipe_variant rv ON rv.dish_id = d.id
      WHERE d.name_cn LIKE ? OR rv.title LIKE ?
      ORDER BY d.popularity_score DESC
      LIMIT ?
      ''',
      ['%$query%', '%$query%', limit],
    );
    return _hydrateRows(likeRows);
  }

  Future<List<Map<String, dynamic>>> fetchRecipesByTagIds(
    List<String> tagIds, {
    int limit = 80,
  }) async {
    final ids = tagIds.map(int.tryParse).whereType<int>().toSet().toList();
    if (ids.isEmpty) return [];

    final db = await _db;
    final placeholders = List.filled(ids.length, '?').join(',');
    final rows = await db.rawQuery(
      tagRecipeSearchSql.replaceAll('__TAG_ID_PLACEHOLDERS__', placeholders),
      [...ids, limit],
    );
    return _hydrateRows(rows);
  }

  Future<List<Map<String, dynamic>>> fetchTagCatalog({
    int limit = 120,
  }) async {
    final db = await _db;
    final rows = await db.rawQuery(
      tagCatalogSql,
      [limit],
    );
    return rows
        .map(
          (row) => <String, dynamic>{
            'id': row['id'],
            'category': row['category'],
            'key': row['key'],
            'name_cn': row['name_cn'],
            'icon_key': row['icon_key'],
            'dish_count': row['dish_count'],
          },
        )
        .toList();
  }

  Future<List<RecipePairingModel>> fetchPairingsForDishId(
    String dishId, {
    int limit = 6,
  }) async {
    final normalizedDishId = _normalizeDishId(dishId);
    if (normalizedDishId == null) return const [];

    final db = await _db;
    final result = await db.rawQuery(
      pairingSearchSql,
      [normalizedDishId, limit],
    );
    return result.map(RecipePairingModel.fromDbRow).toList();
  }

  @visibleForTesting
  static const String ftsSearchSql = '''
      SELECT d.id AS dish_id,
             d.name_cn AS dish_name,
             d.cuisine,
             d.taste_profile,
             d.cooking_methods,
             d.scenes,
             d.health_tags,
             d.main_ingredients,
             d.popularity_score,
             d.average_rating,
             rv.id AS recipe_id,
             rv.source,
             rv.source_recipe_id,
             rv.title AS recipe_title,
             rv.description AS recipe_description,
             rv.difficulty,
             rv.total_time_minutes,
             rv.servings,
             rv.cover_image_url
      FROM dish d
      JOIN recipe_variant rv ON rv.dish_id = d.id
      JOIN dish_fts ON dish_fts.rowid = d.id
      WHERE dish_fts MATCH ?
      ORDER BY d.popularity_score DESC
      LIMIT ?
      ''';

  @visibleForTesting
  static const String defaultRecipeSearchSql = '''
      SELECT d.id               AS dish_id,
             d.name_cn          AS dish_name,
             d.cuisine          AS cuisine,
             d.taste_profile    AS taste_profile,
             d.cooking_methods  AS cooking_methods,
             d.scenes           AS scenes,
             d.health_tags      AS health_tags,
             d.main_ingredients AS main_ingredients,
             d.popularity_score AS popularity_score,
             d.average_rating   AS average_rating,
             rv.id              AS recipe_id,
             rv.source          AS source,
             rv.source_recipe_id AS source_recipe_id,
             rv.title           AS recipe_title,
             rv.description     AS recipe_description,
             rv.difficulty      AS difficulty,
             rv.total_time_minutes AS total_time_minutes,
             rv.servings        AS servings,
             rv.cover_image_url AS cover_image_url
      FROM dish d
      JOIN recipe_variant rv
        ON rv.id = (
          SELECT rv2.id
          FROM recipe_variant rv2
          WHERE rv2.dish_id = d.id
            AND rv2.is_structured = 1
          ORDER BY
            CASE
              WHEN TRIM(COALESCE(rv2.description, '')) <> '' THEN 1
              ELSE 0
            END DESC,
            CASE
              WHEN EXISTS (
                SELECT 1
                FROM recipe_ingredient ri2
                WHERE ri2.recipe_id = rv2.id
              ) THEN 1
              ELSE 0
            END DESC,
            CASE
              WHEN EXISTS (
                SELECT 1
                FROM recipe_step rs2
                WHERE rs2.recipe_id = rv2.id
              ) THEN 1
              ELSE 0
            END DESC,
            rv2.id ASC
          LIMIT 1
        )
      WHERE TRIM(d.name_cn) <> ''
      ORDER BY
        (
          CASE
            WHEN TRIM(COALESCE(rv.description, '')) <> '' THEN 1
            ELSE 0
          END
          + CASE
              WHEN EXISTS (
                SELECT 1
                FROM recipe_ingredient ri
                WHERE ri.recipe_id = rv.id
              ) THEN 1
              ELSE 0
            END
          + CASE
              WHEN EXISTS (
                SELECT 1
                FROM recipe_step rs
                WHERE rs.recipe_id = rv.id
              ) THEN 1
              ELSE 0
            END
        ) DESC,
        d.id ASC
      LIMIT ?
      ''';

  @visibleForTesting
  static const String tagCatalogSql = '''
      SELECT t.id AS id,
             t.category AS category,
             t.key AS key,
             t.name_cn AS name_cn,
             t.icon_key AS icon_key,
             COUNT(dt.dish_id) AS dish_count
      FROM tag t
      LEFT JOIN dish_tag dt ON dt.tag_id = t.id
      GROUP BY t.id, t.category, t.key, t.name_cn, t.icon_key
      ORDER BY dish_count DESC, t.id ASC
      LIMIT ?
      ''';

  @visibleForTesting
  static const String tagRecipeSearchSql = '''
      SELECT d.id AS dish_id,
             d.name_cn AS dish_name,
             d.cuisine,
             d.taste_profile,
             d.cooking_methods,
             d.scenes,
             d.health_tags,
             d.main_ingredients,
             d.popularity_score,
             d.average_rating,
             rv.id AS recipe_id,
             rv.source,
             rv.source_recipe_id,
             rv.title AS recipe_title,
             rv.description AS recipe_description,
             rv.difficulty,
             rv.total_time_minutes,
             rv.servings,
             rv.cover_image_url
      FROM dish d
      JOIN recipe_variant rv ON rv.dish_id = d.id
      JOIN dish_tag dt ON dt.dish_id = d.id
      WHERE dt.tag_id IN (__TAG_ID_PLACEHOLDERS__)
      GROUP BY d.id, rv.id
      ORDER BY COUNT(dt.tag_id) DESC, d.popularity_score DESC, d.id ASC
      LIMIT ?
      ''';

  @visibleForTesting
  static const String pairingSearchSql = '''
      SELECT id,
             dish_id,
             type,
             name,
             description,
             strength,
             source
      FROM pairing
      WHERE dish_id = ?
      ORDER BY strength DESC, id ASC
      LIMIT ?
      ''';

  Future<List<Map<String, dynamic>>> _hydrateRows(
      List<Map<String, Object?>> rows) async {
    if (rows.isEmpty) return const [];

    final db = await _db;
    final mutableRows = rows.map(Map<String, dynamic>.from).toList();
    final dishIds = mutableRows
        .map((row) => row['dish_id'])
        .whereType<int>()
        .toSet()
        .toList();
    final recipeIds = mutableRows
        .map((row) => row['recipe_id'])
        .whereType<int>()
        .toSet()
        .toList();

    // Start the four relation lookups together. Each lookup uses an IN query
    // per SQLite-safe chunk, replacing the previous four queries per recipe.
    final tagsFuture = _fetchDishTagsByDishIds(db, dishIds);
    final ingredientsFuture = _fetchIngredientsByRecipeIds(db, recipeIds);
    final stepsFuture = _fetchStepsByRecipeIds(db, recipeIds);
    final nutritionFuture = _fetchNutritionByDishIds(db, dishIds);
    final tagsByDishId = await tagsFuture;
    final ingredientsByRecipeId = await ingredientsFuture;
    final stepsByRecipeId = await stepsFuture;
    final nutritionByDishId = await nutritionFuture;

    final hydratedRows = <Map<String, dynamic>>[];
    for (final row in mutableRows) {
      final dishId = row['dish_id'] as int;
      final recipeId = row['recipe_id'] as int;
      row['tags'] = tagsByDishId[dishId] ?? const <String>[];
      row['ingredients'] =
          ingredientsByRecipeId[recipeId] ?? const <Map<String, dynamic>>[];
      row['steps'] =
          stepsByRecipeId[recipeId] ?? const <Map<String, dynamic>>[];
      row['nutrition'] = nutritionByDishId[dishId] ?? const <String, dynamic>{};
      row['taste_profile_map'] =
          _decodeJsonMap(row['taste_profile'] as String?);
      row['cooking_methods'] =
          _decodeJsonList(row['cooking_methods'] as String?);
      row['scenes'] = _decodeJsonList(row['scenes'] as String?);
      row['health_tags'] = _decodeJsonList(row['health_tags'] as String?);
      row['main_ingredients_list'] =
          _decodeJsonList(row['main_ingredients'] as String?);
      hydratedRows.add(row);
    }
    return hydratedRows;
  }

  Future<Map<int, List<String>>> _fetchDishTagsByDishIds(
    Database db,
    List<int> dishIds,
  ) async {
    final tagsByDishId = <int, List<String>>{};
    for (final ids in _sqliteChunks(dishIds)) {
      final placeholders = List.filled(ids.length, '?').join(',');
      final result = await db.rawQuery(
        '''
        SELECT dt.dish_id AS dish_id,
               t.name_cn AS name
        FROM dish_tag dt
        JOIN tag t ON t.id = dt.tag_id
        WHERE dt.dish_id IN ($placeholders)
        ORDER BY dt.dish_id ASC, t.category ASC, t.id ASC
        ''',
        ids,
      );
      for (final row in result) {
        final dishId = row['dish_id'] as int;
        final name = row['name']?.toString().trim() ?? '';
        if (name.isEmpty) continue;
        tagsByDishId.putIfAbsent(dishId, () => <String>[]).add(name);
      }
    }
    return tagsByDishId;
  }

  Future<Map<int, List<Map<String, dynamic>>>> _fetchIngredientsByRecipeIds(
    Database db,
    List<int> recipeIds,
  ) async {
    final ingredientsByRecipeId = <int, List<Map<String, dynamic>>>{};
    for (final ids in _sqliteChunks(recipeIds)) {
      final placeholders = List.filled(ids.length, '?').join(',');
      final result = await db.rawQuery(
        '''
        SELECT ri.recipe_id AS recipe_id,
               COALESCE(i.name_cn, ri.name_override) AS name,
               ri.quantity AS quantity,
               ri.unit AS unit,
               ri.is_main AS is_main
        FROM recipe_ingredient ri
        LEFT JOIN ingredient i ON i.id = ri.ingredient_id
        WHERE ri.recipe_id IN ($placeholders)
        ORDER BY ri.recipe_id ASC, ri.display_order ASC
        ''',
        ids,
      );
      for (final row in result) {
        final recipeId = row['recipe_id'] as int;
        ingredientsByRecipeId
            .putIfAbsent(recipeId, () => <Map<String, dynamic>>[])
            .add(_ingredientFromRow(row));
      }
    }
    return ingredientsByRecipeId;
  }

  Future<Map<int, List<Map<String, dynamic>>>> _fetchStepsByRecipeIds(
    Database db,
    List<int> recipeIds,
  ) async {
    final stepsByRecipeId = <int, List<Map<String, dynamic>>>{};
    for (final ids in _sqliteChunks(recipeIds)) {
      final placeholders = List.filled(ids.length, '?').join(',');
      final result = await db.rawQuery(
        '''
        SELECT recipe_id,
               step_index,
               instruction,
               image_url,
               duration_seconds,
               tips
        FROM recipe_step
        WHERE recipe_id IN ($placeholders)
        ORDER BY recipe_id ASC, step_index ASC
        ''',
        ids,
      );
      for (final row in result) {
        final recipeId = row['recipe_id'] as int;
        final durationSeconds = row['duration_seconds'] as int?;
        stepsByRecipeId
            .putIfAbsent(recipeId, () => <Map<String, dynamic>>[])
            .add({
          'order': row['step_index'] ?? 0,
          'description': row['instruction'] ?? '',
          'duration':
              durationSeconds != null ? (durationSeconds / 60).round() : null,
          'image': row['image_url'],
          'tips': row['tips'] != null ? [row['tips']] : null,
        });
      }
    }
    return stepsByRecipeId;
  }

  Future<Map<int, Map<String, dynamic>>> _fetchNutritionByDishIds(
    Database db,
    List<int> dishIds,
  ) async {
    final nutritionByDishId = <int, Map<String, dynamic>>{};
    for (final ids in _sqliteChunks(dishIds)) {
      final placeholders = List.filled(ids.length, '?').join(',');
      final result = await db.rawQuery(
        '''
        SELECT target_id AS dish_id,
               calories,
               protein,
               fat,
               carbs,
               fiber,
               sugar,
               sodium
        FROM nutrition_profile
        WHERE target_type = 'dish'
          AND target_id IN ($placeholders)
        ORDER BY target_id ASC, id ASC
        ''',
        ids,
      );
      for (final row in result) {
        final dishId = row['dish_id'] is int
            ? row['dish_id'] as int
            : int.tryParse('${row['dish_id']}');
        if (dishId == null || nutritionByDishId.containsKey(dishId)) continue;
        nutritionByDishId[dishId] = {
          'calories': row['calories'] ?? 0,
          'protein': row['protein'] ?? 0,
          'fat': row['fat'] ?? 0,
          'carbs': row['carbs'] ?? 0,
          'fiber': row['fiber'] ?? 0,
          'sugar': row['sugar'] ?? 0,
          'sodium': row['sodium'] ?? 0,
        };
      }
    }
    return nutritionByDishId;
  }

  Map<String, dynamic> _ingredientFromRow(Map<String, Object?> row) {
    final quantity = row['quantity'];
    String? amount;
    if (quantity != null) {
      final doubleValue = quantity is num
          ? quantity.toDouble()
          : double.tryParse(quantity.toString());
      amount = doubleValue != null
          ? (doubleValue % 1 == 0
              ? doubleValue.toInt().toString()
              : doubleValue.toStringAsFixed(1))
          : quantity.toString();
    }
    return {
      'name': (row['name'] ?? '').toString(),
      'amount': amount,
      'unit': row['unit']?.toString(),
      'is_main': (row['is_main'] ?? 1) == 1,
    };
  }

  Iterable<List<T>> _sqliteChunks<T>(List<T> values) sync* {
    const chunkSize = 400;
    for (var start = 0; start < values.length; start += chunkSize) {
      final end = (start + chunkSize).clamp(0, values.length);
      yield values.sublist(start, end);
    }
  }

  Map<String, dynamic> _decodeJsonMap(String? value) {
    if (value == null || value.isEmpty) return {};
    try {
      final decoded = jsonDecode(value);
      return decoded is Map<String, dynamic> ? decoded : {};
    } catch (_) {
      return {};
    }
  }

  List<String> _decodeJsonList(String? value) {
    if (value == null || value.isEmpty) return const [];
    try {
      final decoded = jsonDecode(value);
      if (decoded is List) {
        return decoded.map((e) => e.toString()).toList();
      }
    } catch (_) {
      return const [];
    }
    return const [];
  }

  String _buildFtsQuery(String input) {
    final sanitized =
        input.replaceAll(RegExp(r'[\p{P}]', unicode: true), ' ').trim();
    if (sanitized.isEmpty) {
      return '*';
    }
    return sanitized.split(RegExp(r'\s+')).map((term) => '$term*').join(' ');
  }

  int? _normalizeDishId(String dishId) {
    final direct = int.tryParse(dishId.trim());
    if (direct != null) return direct;
    final match = RegExp(r'\d+').firstMatch(dishId);
    if (match == null) return null;
    return int.tryParse(match.group(0)!);
  }
}
