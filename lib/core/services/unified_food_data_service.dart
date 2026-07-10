import 'dart:math';
import 'package:flutter/foundation.dart';

import '../models/bubble.dart';
import '../models/food.dart';
import '../models/recipe.dart';
import '../models/user_preference.dart';
import 'recipe_database_service.dart';
import 'user_preference_manager.dart' show UserPreferenceManager, UserActionType;
import 'vectorized_recommendation_engine.dart';

/// 统一食物数据服务 - Phase 1 核心架构
/// 将推荐系统完全切换到菜谱数据库作为单一数据源
class UnifiedFoodDataService {
  static final UnifiedFoodDataService _instance = UnifiedFoodDataService._internal();
  factory UnifiedFoodDataService() => _instance;
  UnifiedFoodDataService._internal();

  final RecipeDatabaseService _recipeService = RecipeDatabaseService();
  final UserPreferenceManager _preferenceManager = UserPreferenceManager();
  final VectorizedRecommendationEngine _vectorEngine = VectorizedRecommendationEngine();

  bool _initialized = false;

  /// 初始化服务
  Future<void> initialize() async {
    if (_initialized) return;

    debugPrint('🚀 初始化统一食物数据服务...');

    await _recipeService.initialize();
    debugPrint('✅ 菜谱数据库初始化完成');

    _initialized = true;
    debugPrint('🎉 统一食物数据服务初始化完成');
  }

  /// 核心推荐方法 - 基于气泡偏好和用户历史
  /// 流程：用户偏好 -> 菜谱筛选 -> 推荐列表
  Future<List<Food>> getRecommendations(
    List<Bubble> selectedBubbles,
    UserPreference userPreference, {
    int limit = 10,
  }) async {
    if (!_initialized) await initialize();

    debugPrint('🔍 开始生成推荐，选中气泡: ${selectedBubbles.length}个');

    // 1. 解析用户偏好
    final preferences = _parseUserPreferences(selectedBubbles, userPreference);
    debugPrint('📊 解析得到偏好: ${preferences.toString()}');

    // 2. 从菜谱数据库获取候选菜品
    final recipes = await _getCandidateRecipes(preferences, limit * 2);
    debugPrint('📋 获取到候选菜谱: ${recipes.length}个');

    // 3. 转换为Food模型
    final foods = await _convertRecipesToFoods(recipes);

    // 4. 使用向量化推荐引擎排序 (Phase 1 核心优化)
    final vectorizedResults = await _vectorEngine.getVectorizedRecommendations(
      selectedBubbles,
      userPreference,
      foods,
      limit: limit,
    );

    // 5. 返回推荐结果
    final result = vectorizedResults.take(limit).toList();
    debugPrint('🎯 最终推荐: ${result.length}个菜品 (向量化算法)');

    return result;
  }

  /// 解析用户偏好
  UserPreferenceData _parseUserPreferences(
    List<Bubble> selectedBubbles,
    UserPreference userPreference,
  ) {
    final tasteTags = <String>[];
    final cuisineTags = <String>[];
    final ingredientTags = <String>[];

    // 从选中的气泡中提取偏好
    for (final bubble in selectedBubbles) {
      switch (bubble.type) {
        case BubbleType.taste:
          tasteTags.add(bubble.name);
          break;
        case BubbleType.cuisine:
          cuisineTags.add(bubble.name);
          break;
        case BubbleType.ingredient:
          ingredientTags.add(bubble.name);
          break;
        case BubbleType.scenario:
          // 场景标签可以映射到特定的菜品类型
          _mapScenarioToTags(bubble.name, tasteTags, cuisineTags);
          break;
        default:
          tasteTags.add(bubble.name);
      }
    }

    return UserPreferenceData(
      tasteTags: tasteTags,
      cuisineTags: cuisineTags.isNotEmpty ? cuisineTags : null,
      ingredientTags: ingredientTags,
      favoriteRecipeIds: userPreference.favoriteFoods,
      dislikedRecipeIds: userPreference.dislikedFoods,
      difficultyPreference: _mapUserDifficultyPreference(userPreference),
    );
  }

  /// 场景到标签的映射
  void _mapScenarioToTags(String scenario, List<String> tasteTags, List<String> cuisineTags) {
    switch (scenario) {
      case '下饭':
      case '下饭菜':
        tasteTags.addAll(['咸', '香', '重口']);
        break;
      case '宵夜':
        tasteTags.addAll(['香', '辣']);
        cuisineTags.add('川菜');
        break;
      case '聚餐':
        cuisineTags.addAll(['川菜', '粤菜']);
        break;
      case '减脂':
        tasteTags.addAll(['清淡', '清爽']);
        break;
      case '暖胃':
        tasteTags.addAll(['温润', '清淡']);
        break;
    }
  }

  /// 映射用户难度偏好
  RecipeDifficulty? _mapUserDifficultyPreference(UserPreference userPreference) {
    // 基于用户历史行为判断难度偏好
    // 这里可以根据用户的收藏菜谱难度分布来推断
    return null; // 默认不限制难度
  }

  /// 获取候选菜谱
  Future<List<Recipe>> _getCandidateRecipes(
    UserPreferenceData preferences,
    int limit,
  ) async {
    // 使用菜谱数据库的搜索功能
    final recipes = await _recipeService.searchRecipes(
      tags: preferences.tasteTags.isNotEmpty ? preferences.tasteTags : null,
      cuisine: preferences.cuisineTags?.isNotEmpty == true ? preferences.cuisineTags!.first : null,
      difficulty: preferences.difficultyPreference,
      limit: limit,
    );

    // 如果结果不足，获取热门菜谱补充
    if (recipes.length < limit ~/ 2) {
      final popularRecipes = await _recipeService.getPopularRecipes(
        limit: limit - recipes.length,
      );
      recipes.addAll(popularRecipes);
    }

    return recipes;
  }

  /// 将菜谱转换为Food模型
  Future<List<Food>> _convertRecipesToFoods(List<Recipe> recipes) async {
    return recipes.map((recipe) {
      // 从菜谱提取口味属性
      final tasteAttributes = <String>[];

      // 从标签中提取口味信息
      for (final tag in recipe.tags) {
        if (_isTasteTag(tag)) {
          tasteAttributes.add(tag);
        }
      }

      // 从菜系推断口味
      tasteAttributes.addAll(_inferTasteFromCuisine(recipe.cuisine));

      return Food(
        id: recipe.id,
        name: recipe.name,
        description: recipe.description,
        cuisineType: recipe.cuisine,
        tasteAttributes: tasteAttributes,
        ingredients: recipe.ingredients.map((i) => i.name).toList(),
        scenarios: _extractScenarios(recipe.tags),
        calories: recipe.nutrition.calories.toDouble(),
        rating: recipe.rating,
        ratingCount: recipe.reviewCount,
        imageUrl: recipe.imageUrl,
        nutritionFacts: {
          'protein': recipe.nutrition.protein,
          'carbs': recipe.nutrition.carbs,
          'fat': recipe.nutrition.fat,
          'fiber': recipe.nutrition.fiber,
        },
        preparationTime: recipe.totalTime,
        difficulty: recipe.difficulty.label,
        tags: recipe.tags,
      );
    }).toList();
  }

  /// 判断是否为口味标签
  bool _isTasteTag(String tag) {
    const tasteKeywords = [
      '甜',
      '辣',
      '酸',
      '咸',
      '鲜',
      '香',
      '麻',
      '清淡',
      '浓郁',
      '微辣',
      '中辣',
      '重辣',
      '麻辣',
      '香辣',
      '酸甜',
      '咸鲜'
    ];
    return tasteKeywords.any((keyword) => tag.contains(keyword));
  }

  /// 从菜系推断口味
  List<String> _inferTasteFromCuisine(String cuisine) {
    switch (cuisine) {
      case '川菜':
        return ['辣', '麻', '香'];
      case '粤菜':
        return ['鲜', '清淡'];
      case '湘菜':
        return ['辣', '咸', '香'];
      case '鲁菜':
        return ['咸', '鲜'];
      case '苏菜':
        return ['甜', '鲜'];
      case '浙菜':
        return ['清淡', '鲜'];
      case '闽菜':
        return ['鲜', '清淡'];
      case '徽菜':
        return ['咸', '鲜'];
      case '家常菜':
        return ['香', '咸'];
      default:
        return ['香'];
    }
  }

  /// 提取场景标签
  List<String>? _extractScenarios(List<String> tags) {
    const scenarioKeywords = ['下饭菜', '宵夜', '聚餐', '减脂', '暖胃', '快手菜', '汤类', '素食', '家常菜', '节日菜'];

    final scenarios =
        tags.where((tag) => scenarioKeywords.any((keyword) => tag.contains(keyword))).toList();

    return scenarios.isNotEmpty ? scenarios : null;
  }

  /// 基于相关性排序
  List<Food> _rankByRelevance(
    List<Food> foods,
    UserPreferenceData preferences,
  ) {
    final scoredFoods = foods.map((food) {
      final score = _calculateRelevanceScore(food, preferences);
      return ScoredFood(food: food, score: score);
    }).toList();

    // 按分数排序
    scoredFoods.sort((a, b) => b.score.compareTo(a.score));

    return scoredFoods.map((sf) => sf.food).toList();
  }

  /// 计算相关性分数
  double _calculateRelevanceScore(Food food, UserPreferenceData preferences) {
    double score = 1.0; // 基础分数

    // 1. 口味匹配 (40%)
    double tasteScore = 0.0;
    final tasteAttributes = food.tasteAttributes ?? [];
    for (final taste in preferences.tasteTags) {
      if (tasteAttributes.contains(taste)) {
        tasteScore += 2.0; // 完全匹配
      } else if (tasteAttributes.any((attr) => _isSimilarTaste(taste, attr))) {
        tasteScore += 1.0; // 相似匹配
      }
    }
    score += tasteScore * 0.4;

    // 2. 菜系匹配 (25%)
    if (preferences.cuisineTags != null) {
      for (final cuisine in preferences.cuisineTags!) {
        if (food.cuisineType == cuisine) {
          score += 3.0 * 0.25;
          break;
        }
      }
    }

    // 3. 食材匹配 (15%)
    double ingredientScore = 0.0;
    final ingredients = food.ingredients ?? [];
    for (final ingredient in preferences.ingredientTags) {
      if (ingredients.any((i) => i.contains(ingredient))) {
        ingredientScore += 1.5;
      }
    }
    score += ingredientScore * 0.15;

    // 4. 历史偏好 (15%)
    if (preferences.favoriteRecipeIds.contains(food.id)) {
      score += 5.0 * 0.15;
    }
    if (preferences.dislikedRecipeIds.contains(food.id)) {
      score -= 10.0; // 重度惩罚
    }

    // 5. 质量权重 (5%)
    score += food.rating * 0.1 * 0.05;

    // 6. 随机因子，增加多样性
    final random = Random();
    score += random.nextDouble() * 0.5;

    return score;
  }

  /// 判断口味相似性
  bool _isSimilarTaste(String taste1, String taste2) {
    const similarityMap = {
      '辣': ['麻辣', '香辣', '微辣', '中辣', '重辣'],
      '甜': ['蜜甜', '清甜', '微甜', '香甜', '酸甜'],
      '酸': ['酸甜', '酸辣', '微酸'],
      '咸': ['咸鲜', '咸香', '微咸'],
      '鲜': ['咸鲜', '清鲜', '鲜美'],
      '香': ['咸香', '清香', '浓香'],
    };

    final similar = similarityMap[taste1] ?? [];
    return similar.contains(taste2);
  }

  /// 获取菜谱详情 (通过Food ID)
  Future<Recipe?> getRecipeByFoodId(String foodId) async {
    if (!_initialized) await initialize();

    try {
      return await _recipeService.getRecipeById(foodId);
    } catch (e) {
      debugPrint('获取菜谱详情失败: $e');
      return null;
    }
  }

  /// 切换收藏状态
  Future<void> toggleFoodFavorite(String foodId) async {
    if (!_initialized) await initialize();

    await _recipeService.toggleFavorite(foodId);
  }

  /// 记录用户行为 (用于后续AI推荐优化)
  Future<void> recordUserAction(
    String foodId,
    UserActionType actionType,
  ) async {
    // 记录用户行为，用于优化推荐算法
    debugPrint('记录用户行为: $foodId - $actionType');

    // 直接调用用户偏好管理器
    await _preferenceManager.recordUserAction(foodId, actionType);
  }

  /// 获取个性化推荐 (无气泡选择时的推荐)
  Future<List<Food>> getPersonalizedRecommendations(
    UserPreference userPreference, {
    int limit = 10,
  }) async {
    if (!_initialized) await initialize();

    // 基于用户历史偏好获取推荐
    final recipes = await _recipeService.getRecommendedRecipes(
      limit: limit * 2,
    );

    final foods = await _convertRecipesToFoods(recipes);

    // 基于用户偏好排序
    final preferences = UserPreferenceData(
      tasteTags: userPreference.likedTastes,
      cuisineTags: userPreference.cuisinePreferences.keys.toList(),
      ingredientTags: [],
      favoriteRecipeIds: userPreference.favoriteFoods,
      dislikedRecipeIds: userPreference.dislikedFoods,
    );

    final rankedFoods = _rankByRelevance(foods, preferences);
    return rankedFoods.take(limit).toList();
  }
}

/// 用户偏好数据结构
class UserPreferenceData {
  final List<String> tasteTags;
  final List<String>? cuisineTags;
  final List<String> ingredientTags;
  final List<String> favoriteRecipeIds;
  final List<String> dislikedRecipeIds;
  final RecipeDifficulty? difficultyPreference;

  UserPreferenceData({
    required this.tasteTags,
    this.cuisineTags,
    required this.ingredientTags,
    required this.favoriteRecipeIds,
    required this.dislikedRecipeIds,
    this.difficultyPreference,
  });

  @override
  String toString() {
    return 'UserPreferenceData(口味: $tasteTags, 菜系: $cuisineTags, 食材: $ingredientTags)';
  }
}

/// 评分食物
class ScoredFood {
  final Food food;
  final double score;

  ScoredFood({required this.food, required this.score});
}
