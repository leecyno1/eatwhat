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
  Database? _database;

  Future<Database> get _db async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<void> ensureInitialized() async {
    await _db;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _databaseName);
    final exists = await databaseExists(path);
    if (!exists) {
      await _copyDatabaseFromAssets(path);
    }
    return openDatabase(path, readOnly: true);
  }

  Future<void> _copyDatabaseFromAssets(String path) async {
    await Directory(dirname(path)).create(recursive: true);
    final data = await rootBundle.load('assets/data/$_databaseName');
    final bytes =
        data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
    await File(path).writeAsBytes(bytes, flush: true);
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
    final db = await _db;
    for (final row in rows) {
      final dishId = row['dish_id'] as int;
      final recipeId = row['recipe_id'] as int;
      row['tags'] = await _fetchDishTags(db, dishId);
      row['ingredients'] = await _fetchIngredients(db, recipeId);
      row['steps'] = await _fetchSteps(db, recipeId);
      row['nutrition'] = await _fetchNutrition(db, dishId);
      row['taste_profile_map'] =
          _decodeJsonMap(row['taste_profile'] as String?);
      row['cooking_methods'] =
          _decodeJsonList(row['cooking_methods'] as String?);
      row['scenes'] = _decodeJsonList(row['scenes'] as String?);
      row['health_tags'] = _decodeJsonList(row['health_tags'] as String?);
      row['main_ingredients_list'] =
          _decodeJsonList(row['main_ingredients'] as String?);
    }
    return rows;
  }

  Future<List<String>> _fetchDishTags(Database db, int dishId) async {
    final result = await db.rawQuery(
      '''
      SELECT t.name_cn AS name
      FROM dish_tag dt
      JOIN tag t ON t.id = dt.tag_id
      WHERE dt.dish_id = ?
      ORDER BY t.category
      ''',
      [dishId],
    );
    return result.map((row) => row['name'] as String).toList();
  }

  Future<List<Map<String, dynamic>>> _fetchIngredients(
      Database db, int recipeId) async {
    final result = await db.rawQuery(
      '''
      SELECT COALESCE(i.name_cn, ri.name_override) AS name,
             ri.quantity AS quantity,
             ri.unit     AS unit,
             ri.is_main  AS is_main
      FROM recipe_ingredient ri
      LEFT JOIN ingredient i ON i.id = ri.ingredient_id
      WHERE ri.recipe_id = ?
      ORDER BY ri.display_order ASC
      ''',
      [recipeId],
    );
    return result.map((row) {
      final quantity = row['quantity'];
      String? amount;
      if (quantity != null) {
        final doubleValue = (quantity is num)
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
    }).toList();
  }

  Future<List<Map<String, dynamic>>> _fetchSteps(
      Database db, int recipeId) async {
    final result = await db.rawQuery(
      '''
      SELECT step_index, instruction, image_url, duration_seconds, tips
      FROM recipe_step
      WHERE recipe_id = ?
      ORDER BY step_index ASC
      ''',
      [recipeId],
    );
    return result.map((row) {
      final durationSeconds = row['duration_seconds'] as int?;
      return {
        'order': row['step_index'] ?? 0,
        'description': row['instruction'] ?? '',
        'duration':
            durationSeconds != null ? (durationSeconds / 60).round() : null,
        'image': row['image_url'],
        'tips': row['tips'] != null ? [row['tips']] : null,
      };
    }).toList();
  }

  Future<Map<String, dynamic>> _fetchNutrition(Database db, int dishId) async {
    final row = await db.query(
      'nutrition_profile',
      where: 'target_type = ? AND target_id = ?',
      whereArgs: ['dish', dishId],
      limit: 1,
    );
    if (row.isEmpty) {
      return {};
    }
    final record = row.first;
    return {
      'calories': record['calories'] ?? 0,
      'protein': record['protein'] ?? 0,
      'fat': record['fat'] ?? 0,
      'carbs': record['carbs'] ?? 0,
      'fiber': record['fiber'] ?? 0,
      'sugar': record['sugar'] ?? 0,
      'sodium': record['sodium'] ?? 0,
    };
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
