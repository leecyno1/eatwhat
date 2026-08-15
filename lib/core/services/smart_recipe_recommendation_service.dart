import 'dart:math';
import 'package:flutter/foundation.dart';

import '../models/recipe.dart';
import 'real_xiachufang_crawler_service.dart';

/// 智能菜谱推荐服务 - Phase 2 集成真实数据
/// 基于用户偏好和下厨房真实数据进行智能推荐
class SmartRecipeRecommendationService {
  static final SmartRecipeRecommendationService _instance =
      SmartRecipeRecommendationService._internal();
  factory SmartRecipeRecommendationService() => _instance;
  SmartRecipeRecommendationService._internal();

  final RealXiachufangCrawlerService _crawlerService = RealXiachufangCrawlerService();
  final Random _random = Random();

  bool _isInitialized = false;
  List<Recipe> _cachedRecipes = [];
  Map<String, double> _userPreferences = {};
  List<String> _userFavoriteIngredients = [];
  List<String> _userDislikedIngredients = [];
  Map<String, int> _cuisineHistory = {};

  /// 初始化推荐服务
  Future<void> initialize() async {
    if (_isInitialized) return;

    debugPrint('🎯 初始化智能菜谱推荐服务...');

    // 初始化爬虫服务
    await _crawlerService.initialize();

    // 加载用户偏好
    await _loadUserPreferences();

    _isInitialized = true;
    debugPrint('✅ 智能推荐服务初始化完成');
  }

  /// 获取个性化推荐菜谱
  Future<List<Recipe>> getPersonalizedRecommendations({
    int count = 20,
    List<String>? excludeIds,
    String? mealType,
    String? cuisine,
    String? difficulty,
    int? maxCookingTime,
    List<String>? dietaryRestrictions,
    bool refreshData = false,
  }) async {
    await _ensureInitialized();

    // 如果需要刷新数据或缓存为空，重新爬取
    if (refreshData || _cachedRecipes.isEmpty) {
      await _refreshRecipeData();
    }

    // 获取候选菜谱
    List<Recipe> candidates = _getCandidateRecipes(
      mealType: mealType,
      cuisine: cuisine,
      difficulty: difficulty,
      maxCookingTime: maxCookingTime,
      dietaryRestrictions: dietaryRestrictions,
      excludeIds: excludeIds,
    );

    // 计算推荐分数并排序
    List<RecipeRecommendation> scored = candidates.map((recipe) {
      return RecipeRecommendation(
        recipe: recipe,
        score: _calculateRecommendationScore(recipe),
        reasons: _generateRecommendationReasons(recipe),
      );
    }).toList();

    // 按分数排序
    scored.sort((a, b) => b.score.compareTo(a.score));

    // 添加一些随机性避免结果过于固化
    List<RecipeRecommendation> finalRecommendations = _addRandomization(scored, count);

    return finalRecommendations.map((r) => r.recipe).toList();
  }

  /// 获取基于用餐场景的推荐
  Future<List<Recipe>> getScenarioBasedRecommendations({
    required String scenario, // '早餐', '午餐', '晚餐', '夜宵', '聚餐', '减脂', '儿童餐'
    int count = 15,
    String? seasonPreference,
  }) async {
    await _ensureInitialized();

    final scenarioConfig = _getScenarioConfiguration(scenario);

    return await getPersonalizedRecommendations(
      count: count,
      mealType: scenarioConfig['mealType'],
      maxCookingTime: scenarioConfig['maxCookingTime'],
      dietaryRestrictions: scenarioConfig['dietaryRestrictions'],
    );
  }

  /// 获取相似菜谱推荐
  Future<List<Recipe>> getSimilarRecipes(
    Recipe baseRecipe, {
    int count = 10,
  }) async {
    await _ensureInitialized();

    if (_cachedRecipes.isEmpty) {
      await _refreshRecipeData();
    }

    List<Recipe> candidates = _cachedRecipes.where((recipe) => recipe.id != baseRecipe.id).toList();

    // 计算相似度分数
    List<RecipeSimilarity> similarities = candidates.map((recipe) {
      return RecipeSimilarity(
        recipe: recipe,
        similarity: _calculateSimilarityScore(baseRecipe, recipe),
      );
    }).toList();

    // 按相似度排序
    similarities.sort((a, b) => b.similarity.compareTo(a.similarity));

    return similarities.take(count).map((s) => s.recipe).toList();
  }

  /// 更新用户偏好
  void updateUserPreferences({
    String? likedRecipeId,
    String? dislikedRecipeId,
    List<String>? favoriteIngredients,
    List<String>? dislikedIngredients,
    Map<String, double>? tastePreferences,
  }) {
    if (likedRecipeId != null) {
      _updatePreferencesFromRecipe(likedRecipeId, positive: true);
    }

    if (dislikedRecipeId != null) {
      _updatePreferencesFromRecipe(dislikedRecipeId, positive: false);
    }

    if (favoriteIngredients != null) {
      _userFavoriteIngredients.addAll(favoriteIngredients);
      _userFavoriteIngredients = _userFavoriteIngredients.toSet().toList();
    }

    if (dislikedIngredients != null) {
      _userDislikedIngredients.addAll(dislikedIngredients);
      _userDislikedIngredients = _userDislikedIngredients.toSet().toList();
    }

    if (tastePreferences != null) {
      _userPreferences.addAll(tastePreferences);
    }

    _saveUserPreferences();
  }

  /// 获取用户偏好分析报告
  Map<String, dynamic> getUserPreferenceReport() {
    return {
      'favoriteIngredients': List.from(_userFavoriteIngredients),
      'dislikedIngredients': List.from(_userDislikedIngredients),
      'tastePreferences': Map.from(_userPreferences),
      'topCuisines': _getTopCuisines(),
      'cookingTimePreference': _analyzeCookingTimePreference(),
      'difficultyPreference': _analyzeDifficultyPreference(),
    };
  }

  /// 确保服务已初始化
  Future<void> _ensureInitialized() async {
    if (!_isInitialized) {
      await initialize();
    }
  }

  /// 刷新菜谱数据
  Future<void> _refreshRecipeData() async {
    debugPrint('🔄 刷新菜谱数据...');

    try {
      // 基于用户偏好选择爬取分类
      List<String> categories = _getPreferredCategories();

      final result = await _crawlerService.crawlRecipes(
        categories: categories,
        targetCount: 200,
        onProgress: (message) => debugPrint('爬取进度: $message'),
      );

      if (result.success) {
        _cachedRecipes = _crawlerService.crawledRecipes;
        debugPrint('✅ 成功获取 ${_cachedRecipes.length} 个菜谱');
      } else {
        debugPrint('❌ 爬取失败: ${result.message}');
      }
    } catch (e) {
      debugPrint('❌ 刷新数据异常: $e');
    }
  }

  /// 获取候选菜谱
  List<Recipe> _getCandidateRecipes({
    String? mealType,
    String? cuisine,
    String? difficulty,
    int? maxCookingTime,
    List<String>? dietaryRestrictions,
    List<String>? excludeIds,
  }) {
    return _cachedRecipes.where((recipe) {
      // 排除指定菜谱
      if (excludeIds?.contains(recipe.id) ?? false) return false;

      // 菜系筛选
      if (cuisine != null && !recipe.cuisine.contains(cuisine)) return false;

      // 难度筛选
      if (difficulty != null) {
        final difficultyMap = {
          '简单': RecipeDifficulty.easy,
          '中等': RecipeDifficulty.medium,
          '困难': RecipeDifficulty.hard,
        };
        if (recipe.difficulty != difficultyMap[difficulty]) return false;
      }

      // 时间筛选
      if (maxCookingTime != null && recipe.cookingTime > maxCookingTime) return false;

      // 饮食限制筛选
      if (dietaryRestrictions != null) {
        for (String restriction in dietaryRestrictions) {
          if (restriction == '素食' && !_isVegetarian(recipe)) return false;
          if (restriction == '无辣' && _isSpicy(recipe)) return false;
          if (restriction == '低脂' && !_isLowFat(recipe)) return false;
        }
      }

      // 用餐类型筛选
      if (mealType != null) {
        if (!recipe.mealTypes.contains(mealType)) return false;
      }

      return true;
    }).toList();
  }

  /// 计算推荐分数
  double _calculateRecommendationScore(Recipe recipe) {
    double score = 0.0;

    // 基础分数：评分和评论数
    score += recipe.rating * 10; // 0-50分
    score += (recipe.reviewCount / 100).clamp(0, 10); // 0-10分

    // 用户偏好分数
    score += _calculatePreferenceScore(recipe) * 20; // 0-20分

    // 食材偏好分数
    score += _calculateIngredientScore(recipe) * 15; // 0-15分

    // 菜系偏好分数
    score += _calculateCuisineScore(recipe) * 10; // 0-10分

    // 新鲜度分数（避免总是推荐同样的菜谱）
    score += _calculateFreshnessScore(recipe) * 5; // 0-5分

    return score;
  }

  /// 计算口味偏好分数
  double _calculatePreferenceScore(Recipe recipe) {
    if (_userPreferences.isEmpty) return 0.5;

    double totalScore = 0.0;
    int matchCount = 0;

    for (String taste in recipe.tasteProfile) {
      if (_userPreferences.containsKey(taste)) {
        totalScore += _userPreferences[taste]!;
        matchCount++;
      }
    }

    return matchCount > 0 ? totalScore / matchCount : 0.3;
  }

  /// 计算食材偏好分数
  double _calculateIngredientScore(Recipe recipe) {
    double score = 0.5; // 基础分

    for (var ingredient in recipe.ingredients) {
      if (_userFavoriteIngredients.contains(ingredient.name)) {
        score += 0.2;
      }
      if (_userDislikedIngredients.contains(ingredient.name)) {
        score -= 0.3;
      }
    }

    return score.clamp(0.0, 1.0);
  }

  /// 计算菜系偏好分数
  double _calculateCuisineScore(Recipe recipe) {
    final cuisineCount = _cuisineHistory[recipe.cuisine] ?? 0;
    final totalHistory = _cuisineHistory.values.fold(0, (a, b) => a + b);

    if (totalHistory == 0) return 0.5;

    return (cuisineCount / totalHistory).clamp(0.0, 1.0);
  }

  /// 计算新鲜度分数
  double _calculateFreshnessScore(Recipe recipe) {
    // 简单的随机性，实际可以考虑用户查看历史
    return _random.nextDouble();
  }

  /// 生成推荐理由
  List<String> _generateRecommendationReasons(Recipe recipe) {
    List<String> reasons = [];

    // 高评分
    if (recipe.rating >= 4.5) {
      reasons.add('高评分菜谱 (${recipe.rating.toStringAsFixed(1)}⭐)');
    }

    // 口味匹配
    for (String taste in recipe.tasteProfile) {
      if (_userPreferences.containsKey(taste) && _userPreferences[taste]! > 0.7) {
        reasons.add('符合您的${taste}口味偏好');
        break;
      }
    }

    // 食材偏好
    final favoriteIngredients = recipe.ingredients
        .where((ingredient) => _userFavoriteIngredients.contains(ingredient.name))
        .toList();
    if (favoriteIngredients.isNotEmpty) {
      reasons.add('包含您喜欢的${favoriteIngredients.first.name}');
    }

    // 制作时间
    if (recipe.cookingTime <= 30) {
      reasons.add('制作简单快手');
    }

    // 营养健康
    if (recipe.healthBenefits.isNotEmpty) {
      reasons.add('营养丰富健康');
    }

    return reasons.take(3).toList();
  }

  /// 计算菜谱相似度
  double _calculateSimilarityScore(Recipe recipe1, Recipe recipe2) {
    double similarity = 0.0;

    // 菜系相似度
    if (recipe1.cuisine == recipe2.cuisine) similarity += 0.3;

    // 烹饪方法相似度
    if (recipe1.cookingMethod == recipe2.cookingMethod) similarity += 0.2;

    // 口味相似度
    final commonTastes =
        recipe1.tasteProfile.where((taste) => recipe2.tasteProfile.contains(taste)).length;
    similarity += (commonTastes /
            (recipe1.tasteProfile.length + recipe2.tasteProfile.length - commonTastes)) *
        0.3;

    // 食材相似度
    final recipe1Ingredients = recipe1.ingredients.map((i) => i.name).toSet();
    final recipe2Ingredients = recipe2.ingredients.map((i) => i.name).toSet();
    final commonIngredients = recipe1Ingredients.intersection(recipe2Ingredients).length;
    similarity += (commonIngredients / recipe1Ingredients.union(recipe2Ingredients).length) * 0.2;

    return similarity;
  }

  /// 添加随机性
  List<RecipeRecommendation> _addRandomization(List<RecipeRecommendation> scored, int count) {
    if (scored.length <= count) return scored;

    // 取前80%的高分菜谱
    final topCount = (count * 0.8).round();
    final randomCount = count - topCount;

    List<RecipeRecommendation> result = scored.take(topCount).toList();

    // 从剩余菜谱中随机选择一些
    final remaining = scored.skip(topCount).toList();
    remaining.shuffle(_random);
    result.addAll(remaining.take(randomCount));

    return result;
  }

  /// 其他辅助方法...
  Map<String, dynamic> _getScenarioConfiguration(String scenario) {
    switch (scenario) {
      case '早餐':
        return {
          'mealType': '早餐',
          'maxCookingTime': 20,
          'dietaryRestrictions': <String>[],
        };
      case '午餐':
        return {
          'mealType': '午餐',
          'maxCookingTime': 45,
          'dietaryRestrictions': <String>[],
        };
      case '晚餐':
        return {
          'mealType': '晚餐',
          'maxCookingTime': 60,
          'dietaryRestrictions': <String>[],
        };
      case '减脂':
        return {
          'mealType': null,
          'maxCookingTime': null,
          'dietaryRestrictions': ['低脂', '低卡'],
        };
      default:
        return {
          'mealType': null,
          'maxCookingTime': null,
          'dietaryRestrictions': <String>[],
        };
    }
  }

  List<String> _getPreferredCategories() {
    final topCuisines = _getTopCuisines();
    if (topCuisines.isNotEmpty) {
      return topCuisines.take(5).toList();
    }
    return ['家常菜', '川菜', '粤菜', '湘菜', '素食'];
  }

  List<String> _getTopCuisines() {
    final entries = _cuisineHistory.entries.toList();
    entries.sort((a, b) => b.value.compareTo(a.value));
    return entries.take(5).map((e) => e.key).toList();
  }

  bool _isVegetarian(Recipe recipe) {
    return recipe.tags.any((tag) => tag.contains('素')) || recipe.cuisine.contains('素食');
  }

  bool _isSpicy(Recipe recipe) {
    return recipe.tasteProfile.any((taste) => ['辣', '麻'].contains(taste)) ||
        recipe.spiceLevel != '不辣';
  }

  bool _isLowFat(Recipe recipe) {
    return recipe.nutrition.fat < 10.0 || recipe.tags.any((tag) => tag.contains('低脂'));
  }

  String _analyzeCookingTimePreference() {
    // 基于历史数据分析用户偏好的制作时间
    return '中等'; // 简化实现
  }

  String _analyzeDifficultyPreference() {
    // 基于历史数据分析用户偏好的难度
    return '简单'; // 简化实现
  }

  void _updatePreferencesFromRecipe(String recipeId, {required bool positive}) {
    final recipe = _cachedRecipes.firstWhere(
      (r) => r.id == recipeId,
      orElse: () => throw Exception('Recipe not found'),
    );

    // 更新菜系偏好
    _cuisineHistory[recipe.cuisine] = (_cuisineHistory[recipe.cuisine] ?? 0) + (positive ? 1 : -1);

    // 更新口味偏好
    for (String taste in recipe.tasteProfile) {
      _userPreferences[taste] = (_userPreferences[taste] ?? 0.5) + (positive ? 0.1 : -0.1);
      _userPreferences[taste] = _userPreferences[taste]!.clamp(0.0, 1.0);
    }

    // 更新食材偏好
    for (var ingredient in recipe.ingredients) {
      if (positive) {
        if (!_userFavoriteIngredients.contains(ingredient.name)) {
          _userFavoriteIngredients.add(ingredient.name);
        }
        _userDislikedIngredients.remove(ingredient.name);
      } else {
        if (!_userDislikedIngredients.contains(ingredient.name)) {
          _userDislikedIngredients.add(ingredient.name);
        }
        _userFavoriteIngredients.remove(ingredient.name);
      }
    }
  }

  Future<void> _loadUserPreferences() async {
    // TODO: 从本地存储加载用户偏好
    _userPreferences = {
      '鲜': 0.8,
      '香': 0.7,
      '嫩': 0.6,
    };
    _userFavoriteIngredients = ['鸡蛋', '西红柿', '土豆'];
    _cuisineHistory = {'家常菜': 5, '川菜': 3};
  }

  void _saveUserPreferences() async {
    // TODO: 保存用户偏好到本地存储
    debugPrint('💾 保存用户偏好');
  }
}

/// 菜谱推荐结果
class RecipeRecommendation {
  final Recipe recipe;
  final double score;
  final List<String> reasons;

  RecipeRecommendation({
    required this.recipe,
    required this.score,
    required this.reasons,
  });
}

/// 菜谱相似度结果
class RecipeSimilarity {
  final Recipe recipe;
  final double similarity;

  RecipeSimilarity({
    required this.recipe,
    required this.similarity,
  });
}
