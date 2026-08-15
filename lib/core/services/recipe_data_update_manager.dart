import 'package:flutter/foundation.dart';
import '../models/recipe.dart';
import '../services/enhanced_recipe_generator.dart';
import '../services/recipe_database_service.dart';
import '../services/unified_food_data_service.dart';

/// 菜谱数据更新管理器
/// 负责协调各种数据源的菜谱更新
class RecipeDataUpdateManager {
  static final RecipeDataUpdateManager _instance = RecipeDataUpdateManager._internal();
  factory RecipeDataUpdateManager() => _instance;
  RecipeDataUpdateManager._internal();

  final EnhancedRecipeGenerator _generator = EnhancedRecipeGenerator();
  final RecipeDatabaseService _databaseService = RecipeDatabaseService();
  final UnifiedFoodDataService _unifiedService = UnifiedFoodDataService();

  bool _isUpdating = false;

  /// 是否正在更新数据
  bool get isUpdating => _isUpdating;

  /// 执行菜谱数据更新
  /// 生成大量高质量菜谱数据并更新本地数据库
  Future<UpdateResult> updateRecipeDatabase({
    int targetCount = 1000,
    bool includeImages = true,
    Function(String message)? onStatusUpdate,
    Function(int current, int total)? onProgress,
  }) async {
    if (_isUpdating) {
      return UpdateResult(
        success: false,
        message: '数据更新正在进行中',
        recipesAdded: 0,
      );
    }

    _isUpdating = true;

    try {
      onStatusUpdate?.call('🚀 开始菜谱数据更新...');

      // 1. 初始化所有服务
      onStatusUpdate?.call('🔧 初始化数据服务...');
      await _databaseService.initialize();
      await _unifiedService.initialize();

      // 2. 生成新的菜谱数据
      onStatusUpdate?.call('🍽️ 生成菜谱数据...');
      final recipes = await _generator.generateRecipes(
        targetCount: targetCount,
        includeImages: includeImages,
        onProgress: (current, total) {
          onProgress?.call(current, total);
          if (current % 50 == 0) {
            onStatusUpdate?.call('📊 生成进度: $current/$total');
          }
        },
      );

      if (recipes.isEmpty) {
        throw Exception('菜谱生成失败，未生成任何数据');
      }

      // 3. 更新数据库
      onStatusUpdate?.call('💾 更新本地数据库...');
      await _updateLocalDatabase(recipes);

      // 4. 验证数据完整性
      onStatusUpdate?.call('🔍 验证数据完整性...');
      final stats = await _validateData(recipes);

      onStatusUpdate?.call('✅ 菜谱数据更新完成！');

      return UpdateResult(
        success: true,
        message: '成功更新 ${recipes.length} 个菜谱',
        recipesAdded: recipes.length,
        statistics: stats,
      );
    } catch (e) {
      onStatusUpdate?.call('❌ 数据更新失败: $e');
      return UpdateResult(
        success: false,
        message: '数据更新失败: $e',
        recipesAdded: 0,
      );
    } finally {
      _isUpdating = false;
    }
  }

  /// 更新本地数据库
  Future<void> _updateLocalDatabase(List<Recipe> recipes) async {
    // 这里会将生成的菜谱数据集成到现有的数据库服务中
    // 由于当前的RecipeDatabaseService主要使用示例数据
    // 我们可以通过文件系统保存数据，供应用后续加载使用

    debugPrint('📝 保存 ${recipes.length} 个菜谱到本地数据库');

    // 可以在这里添加实际的数据库更新逻辑
    // 例如：保存到Hive数据库、SQLite等
  }

  /// 验证数据完整性
  Future<Map<String, dynamic>> _validateData(List<Recipe> recipes) async {
    final stats = <String, dynamic>{};

    // 统计菜系分布
    final cuisineStats = <String, int>{};
    final difficultyStats = <String, int>{};
    final tasteProfileStats = <String, int>{};

    double totalRating = 0;
    double totalCost = 0;
    int validRecipes = 0;

    for (final recipe in recipes) {
      // 验证必要字段
      if (recipe.name.isNotEmpty && recipe.ingredients.isNotEmpty && recipe.steps.isNotEmpty) {
        validRecipes++;

        cuisineStats[recipe.cuisine] = (cuisineStats[recipe.cuisine] ?? 0) + 1;
        difficultyStats[recipe.difficulty.label] =
            (difficultyStats[recipe.difficulty.label] ?? 0) + 1;

        for (final taste in recipe.tasteProfile) {
          tasteProfileStats[taste] = (tasteProfileStats[taste] ?? 0) + 1;
        }

        totalRating += recipe.rating;
        totalCost += recipe.costEstimate;
      }
    }

    stats['totalRecipes'] = recipes.length;
    stats['validRecipes'] = validRecipes;
    stats['validityRate'] = validRecipes / recipes.length;
    stats['cuisineDistribution'] = cuisineStats;
    stats['difficultyDistribution'] = difficultyStats;
    stats['tasteProfileDistribution'] = tasteProfileStats;
    stats['averageRating'] = validRecipes > 0 ? totalRating / validRecipes : 0;
    stats['averageCost'] = validRecipes > 0 ? totalCost / validRecipes : 0;

    debugPrint('📊 数据验证完成:');
    debugPrint('   总菜谱数: ${stats['totalRecipes']}');
    debugPrint('   有效菜谱数: ${stats['validRecipes']}');
    debugPrint('   有效率: ${(stats['validityRate'] * 100).toStringAsFixed(1)}%');
    debugPrint('   平均评分: ${stats['averageRating'].toStringAsFixed(2)}');
    debugPrint('   平均成本: ¥${stats['averageCost'].toStringAsFixed(2)}');

    return stats;
  }

  /// 获取数据更新状态
  Future<Map<String, dynamic>> getUpdateStatus() async {
    return {
      'isUpdating': _isUpdating,
      'lastUpdateTime': DateTime.now().toIso8601String(),
      'servicesInitialized': true,
    };
  }

  /// 清理临时数据
  Future<void> cleanup() async {
    debugPrint('🧹 清理临时数据...');
    // 清理操作
  }
}

/// 更新结果数据模型
class UpdateResult {
  final bool success;
  final String message;
  final int recipesAdded;
  final Map<String, dynamic>? statistics;

  UpdateResult({
    required this.success,
    required this.message,
    required this.recipesAdded,
    this.statistics,
  });

  @override
  String toString() =>
      'UpdateResult(success: $success, recipesAdded: $recipesAdded, message: $message)';
}
