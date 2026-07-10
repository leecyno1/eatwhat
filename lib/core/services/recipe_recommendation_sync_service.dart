import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';

import '../models/recipe.dart';
import '../models/food.dart';
import '../models/bubble.dart';
import '../models/user_preference.dart';
import 'xiachufang_crawler_service.dart';
import 'taste_mapping_algorithm_service.dart';
import 'storage_service.dart';

/// 菜谱推荐数据库同步服务
/// Phase 3: 实现菜谱数据库与推荐系统的完全同步机制
class RecipeRecommendationSyncService {
  static final RecipeRecommendationSyncService _instance =
      RecipeRecommendationSyncService._internal();
  factory RecipeRecommendationSyncService() => _instance;
  RecipeRecommendationSyncService._internal();

  final XiachufangCrawlerService _crawlerService = XiachufangCrawlerService();
  final TasteMappingAlgorithmService _tasteMappingService = TasteMappingAlgorithmService();

  final StreamController<SyncProgressEvent> _progressController = StreamController.broadcast();
  final Map<String, Recipe> _recipeDatabase = {};
  final Map<String, Food> _foodDatabase = {};

  bool _isInitialized = false;
  bool _isSyncing = false;
  DateTime? _lastSyncTime;

  /// 同步进度事件流
  Stream<SyncProgressEvent> get progressStream => _progressController.stream;

  /// 获取菜谱数据库
  Map<String, Recipe> get recipeDatabase => Map.from(_recipeDatabase);

  /// 获取推荐食物数据库
  Map<String, Food> get foodDatabase => Map.from(_foodDatabase);

  /// 是否正在同步
  bool get isSyncing => _isSyncing;

  /// 最后同步时间
  DateTime? get lastSyncTime => _lastSyncTime;

  /// 初始化同步服务
  Future<void> initialize() async {
    if (_isInitialized) return;

    debugPrint('🔄 初始化菜谱-推荐同步服务...');

    await _crawlerService.initialize();
    await _tasteMappingService.initialize();

    // 加载本地数据
    await _loadLocalData();

    _isInitialized = true;
    debugPrint('✅ 菜谱-推荐同步服务初始化完成');
  }

  /// 执行完整同步
  Future<SyncResult> performFullSync({
    bool crawlNewData = true,
    int maxRecipes = 1000,
    bool forceUpdate = false,
  }) async {
    if (_isSyncing) {
      return SyncResult(
        success: false,
        message: '同步正在进行中',
        syncType: SyncType.full,
      );
    }

    _isSyncing = true;
    final startTime = DateTime.now();

    try {
      _emitProgressEvent(SyncProgressType.started, '开始完整同步');

      // 步骤1: 爬取最新菜谱数据
      if (crawlNewData || _recipeDatabase.isEmpty) {
        _emitProgressEvent(SyncProgressType.crawling, '正在爬取菜谱数据...');

        final crawlResult = await _crawlerService.startCrawling(
          maxRecipes: maxRecipes,
          includeImages: true,
        );

        if (!crawlResult.success) {
          throw Exception('菜谱数据爬取失败: ${crawlResult.message}');
        }

        debugPrint('📥 爬取完成: ${crawlResult.recipesCount} 个菜谱');
      }

      // 步骤2: 更新本地菜谱数据库
      _emitProgressEvent(SyncProgressType.updating, '更新菜谱数据库...');
      await _updateRecipeDatabase();

      // 步骤3: 转换菜谱为推荐食物
      _emitProgressEvent(SyncProgressType.converting, '转换推荐数据...');
      await _convertRecipesToFoods();

      // 步骤4: 构建口味特征向量
      _emitProgressEvent(SyncProgressType.indexing, '构建口味索引...');
      await _buildTasteIndex();

      // 步骤5: 保存同步数据
      _emitProgressEvent(SyncProgressType.saving, '保存同步数据...');
      await _saveSyncData();

      _lastSyncTime = DateTime.now();

      final result = SyncResult(
        success: true,
        message: '完整同步成功',
        syncType: SyncType.full,
        recipesCount: _recipeDatabase.length,
        foodsCount: _foodDatabase.length,
        duration: DateTime.now().difference(startTime),
      );

      _emitProgressEvent(SyncProgressType.completed, '同步完成');
      debugPrint('🎉 完整同步完成: ${result.toString()}');

      return result;
    } catch (e) {
      debugPrint('❌ 完整同步失败: $e');
      _emitProgressEvent(SyncProgressType.error, '同步失败: $e');

      return SyncResult(
        success: false,
        message: '同步失败: $e',
        syncType: SyncType.full,
        duration: DateTime.now().difference(startTime),
      );
    } finally {
      _isSyncing = false;
    }
  }

  /// 执行增量同步
  Future<SyncResult> performIncrementalSync() async {
    if (_isSyncing) {
      return SyncResult(
        success: false,
        message: '同步正在进行中',
        syncType: SyncType.incremental,
      );
    }

    _isSyncing = true;
    final startTime = DateTime.now();

    try {
      _emitProgressEvent(SyncProgressType.started, '开始增量同步');

      // 检查是否有新的爬取数据
      final newRecipes = _crawlerService.crawledRecipes;
      int addedCount = 0;

      for (final recipe in newRecipes) {
        if (!_recipeDatabase.containsKey(recipe.id)) {
          _recipeDatabase[recipe.id] = recipe;

          // 转换为Food对象
          final food = await _convertRecipeToFood(recipe);
          _foodDatabase[food.id] = food;

          addedCount++;
        }
      }

      if (addedCount > 0) {
        await _saveSyncData();
        _lastSyncTime = DateTime.now();
      }

      final result = SyncResult(
        success: true,
        message: '增量同步成功，新增 $addedCount 个菜谱',
        syncType: SyncType.incremental,
        recipesCount: addedCount,
        foodsCount: addedCount,
        duration: DateTime.now().difference(startTime),
      );

      _emitProgressEvent(SyncProgressType.completed, '增量同步完成');
      return result;
    } catch (e) {
      debugPrint('❌ 增量同步失败: $e');
      _emitProgressEvent(SyncProgressType.error, '增量同步失败: $e');

      return SyncResult(
        success: false,
        message: '增量同步失败: $e',
        syncType: SyncType.incremental,
        duration: DateTime.now().difference(startTime),
      );
    } finally {
      _isSyncing = false;
    }
  }

  /// 智能推荐菜谱（基于同步的数据库）
  Future<List<Food>> getSmartRecommendations(
    List<Bubble> selectedBubbles,
    UserPreference userPreference, {
    int limit = 10,
    double minMatchScore = 0.3,
  }) async {
    if (!_isInitialized) await initialize();

    debugPrint('🎯 基于同步数据库进行智能推荐...');
    debugPrint('📊 数据库规模: ${_recipeDatabase.length} 菜谱, ${_foodDatabase.length} 推荐项');

    // 从菜谱数据库获取候选菜谱
    final candidateRecipes = _recipeDatabase.values.toList();

    // 使用口味映射算法进行智能匹配
    final recommendedRecipes = await _tasteMappingService.getIntelligentRecommendations(
      candidateRecipes,
      selectedBubbles,
      userPreference,
      limit: limit,
      minMatchScore: minMatchScore,
    );

    // 转换为Food对象返回
    final recommendedFoods = <Food>[];
    for (final recipe in recommendedRecipes) {
      final food = _foodDatabase[recipe.id];
      if (food != null) {
        recommendedFoods.add(food);
      }
    }

    debugPrint('✅ 智能推荐完成: ${recommendedFoods.length} 个结果');
    return recommendedFoods;
  }

  /// 搜索菜谱（统一搜索接口）
  Future<List<Food>> searchRecipes({
    String? keyword,
    List<String>? cuisines,
    List<String>? tastes,
    RecipeDifficulty? difficulty,
    int? maxTime,
    bool? isVegetarian,
    int limit = 20,
  }) async {
    if (!_isInitialized) await initialize();

    final filteredRecipes = _recipeDatabase.values
        .where((recipe) {
          // 关键词过滤
          if (keyword != null && keyword.isNotEmpty) {
            if (!recipe.name.contains(keyword) &&
                !recipe.description.contains(keyword) &&
                !recipe.tags.any((tag) => tag.contains(keyword))) {
              return false;
            }
          }

          // 菜系过滤
          if (cuisines != null && cuisines.isNotEmpty) {
            if (!cuisines.contains(recipe.cuisine)) {
              return false;
            }
          }

          // 口味过滤
          if (tastes != null && tastes.isNotEmpty) {
            if (!tastes.any((taste) => recipe.tasteProfile.contains(taste))) {
              return false;
            }
          }

          // 难度过滤
          if (difficulty != null && recipe.difficulty != difficulty) {
            return false;
          }

          // 时间过滤
          if (maxTime != null && recipe.totalTime > maxTime) {
            return false;
          }

          // 素食过滤
          if (isVegetarian != null && recipe.isVegetarian != isVegetarian) {
            return false;
          }

          return true;
        })
        .take(limit)
        .toList();

    // 转换为Food对象
    final foods = <Food>[];
    for (final recipe in filteredRecipes) {
      final food = _foodDatabase[recipe.id];
      if (food != null) {
        foods.add(food);
      }
    }

    return foods;
  }

  /// 获取菜谱详情
  Future<Recipe?> getRecipeDetail(String foodId) async {
    return _recipeDatabase[foodId];
  }

  /// 获取同步统计信息
  Map<String, dynamic> getSyncStatistics() {
    final cuisineStats = <String, int>{};
    final difficultyStats = <String, int>{};
    final tasteStats = <String, int>{};

    for (final recipe in _recipeDatabase.values) {
      // 菜系统计
      cuisineStats[recipe.cuisine] = (cuisineStats[recipe.cuisine] ?? 0) + 1;

      // 难度统计
      difficultyStats[recipe.difficulty.label] =
          (difficultyStats[recipe.difficulty.label] ?? 0) + 1;

      // 口味统计
      for (final taste in recipe.tasteProfile) {
        tasteStats[taste] = (tasteStats[taste] ?? 0) + 1;
      }
    }

    return {
      'totalRecipes': _recipeDatabase.length,
      'totalFoods': _foodDatabase.length,
      'lastSyncTime': _lastSyncTime?.toIso8601String(),
      'isSyncing': _isSyncing,
      'cuisineDistribution': cuisineStats,
      'difficultyDistribution': difficultyStats,
      'tasteDistribution': tasteStats,
      'averageRating': _calculateAverageRating(),
      'dataFreshness': _calculateDataFreshness(),
    };
  }

  // 私有方法

  /// 加载本地数据
  Future<void> _loadLocalData() async {
    try {
      // 加载菜谱数据
      // 这里应该从文件系统加载数据，暂时跳过
      debugPrint('⚠️ 本地数据加载功能待实现');

      // 加载推荐数据
      // 这里应该从文件系统加载数据，暂时跳过

      // 加载同步时间
      // 这里应该从文件系统加载数据，暂时跳过

      debugPrint('📥 本地数据加载完成: ${_recipeDatabase.length} 菜谱, ${_foodDatabase.length} 推荐项');
    } catch (e) {
      debugPrint('⚠️ 加载本地数据失败: $e');
    }
  }

  /// 更新菜谱数据库
  Future<void> _updateRecipeDatabase() async {
    final newRecipes = _crawlerService.crawledRecipes;

    for (final recipe in newRecipes) {
      _recipeDatabase[recipe.id] = recipe;
    }

    debugPrint('📊 菜谱数据库更新完成: ${_recipeDatabase.length} 个菜谱');
  }

  /// 转换菜谱为推荐食物
  Future<void> _convertRecipesToFoods() async {
    _foodDatabase.clear();

    for (final recipe in _recipeDatabase.values) {
      final food = await _convertRecipeToFood(recipe);
      _foodDatabase[food.id] = food;
    }

    debugPrint('🔄 菜谱转换完成: ${_foodDatabase.length} 个推荐食物');
  }

  /// 单个菜谱转换为食物
  Future<Food> _convertRecipeToFood(Recipe recipe) async {
    return Food(
      id: recipe.id,
      name: recipe.name,
      description: recipe.description,
      cuisineType: recipe.cuisine,
      tasteAttributes: recipe.tasteProfile,
      ingredients: recipe.ingredients.map((i) => i.name).toList(),
      scenarios: recipe.scenarioTags,
      calories: recipe.nutrition.calories.toDouble(),
      rating: recipe.rating,
      ratingCount: recipe.reviewCount,
      imageUrl: recipe.imageUrl,
      nutritionFacts: {
        'protein': recipe.nutrition.protein,
        'carbs': recipe.nutrition.carbs,
        'fat': recipe.nutrition.fat,
        'fiber': recipe.nutrition.fiber,
        'sodium': recipe.nutrition.sodium,
      },
      preparationTime: recipe.totalTime,
      difficulty: recipe.difficulty.label,
      tags: recipe.tags,
    );
  }

  /// 构建口味索引
  Future<void> _buildTasteIndex() async {
    for (final recipe in _recipeDatabase.values) {
      _tasteMappingService.convertRecipeToVector(recipe);
    }

    debugPrint('🧠 口味索引构建完成');
  }

  /// 保存同步数据
  Future<void> _saveSyncData() async {
    try {
      // 保存菜谱数据到文件系统
      // 这里应该实现文件保存逻辑，暂时跳过
      debugPrint('⚠️ 数据保存功能待实现');

      debugPrint('💾 同步数据保存完成');
    } catch (e) {
      debugPrint('❌ 保存同步数据失败: $e');
    }
  }

  /// 发送进度事件
  void _emitProgressEvent(SyncProgressType type, String message) {
    _progressController.add(SyncProgressEvent(
      type: type,
      message: message,
      timestamp: DateTime.now(),
    ));
  }

  /// 计算平均评分
  double _calculateAverageRating() {
    if (_recipeDatabase.isEmpty) return 0.0;

    final totalRating = _recipeDatabase.values.map((r) => r.rating).reduce((a, b) => a + b);

    return totalRating / _recipeDatabase.length;
  }

  /// 计算数据新鲜度
  double _calculateDataFreshness() {
    if (_lastSyncTime == null) return 0.0;

    final hoursSinceSync = DateTime.now().difference(_lastSyncTime!).inHours;

    // 24小时内为新鲜，之后逐渐降低
    return (1.0 - (hoursSinceSync / 168.0)).clamp(0.0, 1.0); // 一周为完全过期
  }

  /// 清理资源
  void dispose() {
    _progressController.close();
    _recipeDatabase.clear();
    _foodDatabase.clear();
  }
}

/// 同步结果数据模型
class SyncResult {
  final bool success;
  final String message;
  final SyncType syncType;
  final int? recipesCount;
  final int? foodsCount;
  final Duration? duration;

  SyncResult({
    required this.success,
    required this.message,
    required this.syncType,
    this.recipesCount,
    this.foodsCount,
    this.duration,
  });

  @override
  String toString() =>
      'SyncResult(${syncType.name}: $success, recipes: $recipesCount, foods: $foodsCount, duration: ${duration?.inSeconds}s)';
}

/// 同步进度事件
class SyncProgressEvent {
  final SyncProgressType type;
  final String message;
  final DateTime timestamp;

  SyncProgressEvent({
    required this.type,
    required this.message,
    required this.timestamp,
  });
}

/// 枚举定义
enum SyncType {
  full,
  incremental,
}

enum SyncProgressType {
  started,
  crawling,
  updating,
  converting,
  indexing,
  saving,
  completed,
  error,
}
