import 'package:flutter/services.dart';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';
import 'dart:io';
import 'dart:typed_data';

class HowToCookDatabaseService {
  static const String _databaseName = 'howtocook_enhanced_recipes.db';
  Database? _database;

  static final HowToCookDatabaseService _instance = HowToCookDatabaseService._internal();
  factory HowToCookDatabaseService() => _instance;
  HowToCookDatabaseService._internal();

  Future<Database> get database async {
    _database ??= await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    String databasesPath = await getDatabasesPath();
    String path = join(databasesPath, _databaseName);

    // 检查数据库是否存在，如果不存在则从assets复制
    bool exists = await databaseExists(path);
    if (!exists) {
      await _copyDatabaseFromAssets(path);
    }

    return await openDatabase(
      path,
      version: 1,
      readOnly: false, // 允许写入以便SQLite可以设置版本信息
    );
  }

  Future<void> _copyDatabaseFromAssets(String path) async {
    try {
      // 确保路径目录存在
      await Directory(dirname(path)).create(recursive: true);

      // 从assets复制数据库文件
      ByteData data = await rootBundle.load('assets/data/$_databaseName');
      List<int> bytes = data.buffer.asUint8List(data.offsetInBytes, data.lengthInBytes);
      await File(path).writeAsBytes(bytes);

      print('数据库已从assets复制到: $path');
    } catch (e) {
      print('从assets复制数据库失败: $e');
      // 创建空数据库作为备用
      await _createEmptyDatabase(path);
    }
  }

  Future<void> _createEmptyDatabase(String path) async {
    Database db = await openDatabase(path, version: 1, onCreate: (db, version) async {
      // 创建基础表结构（备用方案）
      await db.execute('''
        CREATE TABLE howtocook_recipes (
          id TEXT PRIMARY KEY,
          name TEXT NOT NULL,
          description TEXT,
          difficulty INTEGER DEFAULT 3,
          category TEXT NOT NULL,
          subcategory TEXT,
          cooking_time INTEGER,
          servings INTEGER DEFAULT 1,
          github_url TEXT,
          markdown_content TEXT,
          created_at TEXT DEFAULT CURRENT_TIMESTAMP,
          updated_at TEXT DEFAULT CURRENT_TIMESTAMP,
          scraped_at TEXT DEFAULT CURRENT_TIMESTAMP
        )
      ''');

      await db.execute('''
        CREATE TABLE howtocook_ingredients (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          recipe_id TEXT,
          name TEXT NOT NULL,
          amount TEXT,
          unit TEXT,
          is_main BOOLEAN DEFAULT 1,
          order_index INTEGER DEFAULT 0,
          FOREIGN KEY (recipe_id) REFERENCES howtocook_recipes (id)
        )
      ''');

      await db.execute('''
        CREATE TABLE howtocook_steps (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          recipe_id TEXT,
          step_number INTEGER,
          description TEXT NOT NULL,
          image_url TEXT,
          notes TEXT,
          FOREIGN KEY (recipe_id) REFERENCES howtocook_recipes (id)
        )
      ''');
    });

    await db.close();
    print('已创建空数据库作为备用方案');
  }

  // 获取所有菜谱
  Future<List<Map<String, dynamic>>> getAllRecipes() async {
    final db = await database;
    return await db.query('howtocook_recipes', orderBy: 'name ASC');
  }

  // 根据分类获取菜谱
  Future<List<Map<String, dynamic>>> getRecipesByCategory(String category) async {
    final db = await database;
    return await db.query(
      'howtocook_recipes',
      where: 'category = ?',
      whereArgs: [category],
      orderBy: 'name ASC',
    );
  }

  // 根据难度获取菜谱
  Future<List<Map<String, dynamic>>> getRecipesByDifficulty(int difficulty) async {
    final db = await database;
    return await db.query(
      'howtocook_recipes',
      where: 'difficulty = ?',
      whereArgs: [difficulty],
      orderBy: 'name ASC',
    );
  }

  // 搜索菜谱
  Future<List<Map<String, dynamic>>> searchRecipes(String query) async {
    final db = await database;
    return await db.query(
      'howtocook_recipes',
      where: 'name LIKE ? OR description LIKE ?',
      whereArgs: ['%$query%', '%$query%'],
      orderBy: 'name ASC',
    );
  }

  // 获取所有分类
  Future<List<String>> getAllCategories() async {
    final db = await database;
    final result =
        await db.rawQuery('SELECT DISTINCT category FROM howtocook_recipes ORDER BY category');
    return result.map((row) => row['category'] as String).toList();
  }

  // 获取菜谱的食材
  Future<List<Map<String, dynamic>>> getRecipeIngredients(String recipeId) async {
    final db = await database;
    return await db.query(
      'howtocook_ingredients',
      where: 'recipe_id = ?',
      whereArgs: [recipeId],
      orderBy: 'order_index ASC',
    );
  }

  // 获取菜谱的制作步骤
  Future<List<Map<String, dynamic>>> getRecipeSteps(String recipeId) async {
    final db = await database;
    return await db.query(
      'howtocook_steps',
      where: 'recipe_id = ?',
      whereArgs: [recipeId],
      orderBy: 'step_number ASC',
    );
  }

  // 获取完整菜谱信息（包含食材和步骤）
  Future<Map<String, dynamic>?> getCompleteRecipe(String recipeId) async {
    final db = await database;

    // 获取基本信息
    final recipeResult = await db.query(
      'howtocook_recipes',
      where: 'id = ?',
      whereArgs: [recipeId],
      limit: 1,
    );

    if (recipeResult.isEmpty) return null;

    Map<String, dynamic> recipe = Map.from(recipeResult.first);

    // 获取食材
    recipe['ingredients'] = await getRecipeIngredients(recipeId);

    // 获取制作步骤
    recipe['steps'] = await getRecipeSteps(recipeId);

    return recipe;
  }

  // 获取数据库统计信息
  Future<Map<String, int>> getDatabaseStats() async {
    final db = await database;

    final totalRecipesResult = await db.rawQuery('SELECT COUNT(*) as count FROM howtocook_recipes');
    final totalCategoriesResult =
        await db.rawQuery('SELECT COUNT(DISTINCT category) as count FROM howtocook_recipes');

    return {
      'totalRecipes': totalRecipesResult.first['count'] as int,
      'totalCategories': totalCategoriesResult.first['count'] as int,
    };
  }

  // 复合搜索：支持分类、难度、搜索关键词的组合查询
  Future<List<Map<String, dynamic>>> searchRecipesAdvanced({
    String? category,
    int? difficulty,
    String? searchQuery,
  }) async {
    final db = await database;

    List<String> whereClauses = [];
    List<dynamic> whereArgs = [];

    if (category != null && category != 'all') {
      whereClauses.add('category = ?');
      whereArgs.add(category);
    }

    if (difficulty != null && difficulty > 0) {
      whereClauses.add('difficulty = ?');
      whereArgs.add(difficulty);
    }

    if (searchQuery != null && searchQuery.isNotEmpty) {
      whereClauses.add('(name LIKE ? OR description LIKE ?)');
      whereArgs.add('%$searchQuery%');
      whereArgs.add('%$searchQuery%');
    }

    String whereClause = whereClauses.isNotEmpty ? whereClauses.join(' AND ') : '';

    return await db.query(
      'howtocook_recipes',
      where: whereClause.isNotEmpty ? whereClause : null,
      whereArgs: whereArgs.isNotEmpty ? whereArgs : null,
      orderBy: 'name ASC',
    );
  }

  // 关闭数据库连接
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
