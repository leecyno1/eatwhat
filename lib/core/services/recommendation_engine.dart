import 'dart:math';
import '../models/food.dart';
import '../models/user_preference.dart';
import '../data/food_database.dart';
import '../models/bubble.dart';

/// 推荐引擎
class RecommendationEngine {
  static final Random _random = Random();

  /// 初始化推荐引擎
  void initialize() {
    // 基本初始化
  }

  /// 获取个性化推荐
  Future<List<Food>> getPersonalizedRecommendations(
      UserPreference userPreference) async {
    final allFoods = FoodDatabase.getAllFoods();
    final scoredFoods = <ScoredFood>[];

    for (final food in allFoods) {
      double score = _calculatePersonalizedScore(food, userPreference);

      if (score > 0) {
        scoredFoods.add(ScoredFood(
          food: food,
          score: score,
          reason: 'Personalized recommendation',
          scoreBreakdown: {},
        ));
      }
    }

    // 排序并返回前10个推荐
    scoredFoods.sort((a, b) => b.score.compareTo(a.score));
    return scoredFoods.take(10).map((sf) => sf.food).toList();
  }

  /// 获取基础推荐
  List<Food> getBasicRecommendations({int limit = 10}) {
    final allFoods = FoodDatabase.getAllFoods();
    final shuffled = List<Food>.from(allFoods)..shuffle(_random);
    return shuffled.take(limit).toList();
  }

  /// 基于菜系获取推荐
  List<Food> getRecommendationsByCuisine(String cuisineType, {int limit = 10}) {
    final allFoods = FoodDatabase.getAllFoods();
    final filteredFoods =
        allFoods.where((food) => food.cuisineType == cuisineType).toList();

    if (filteredFoods.length <= limit) {
      return filteredFoods;
    }

    filteredFoods.shuffle(_random);
    return filteredFoods.take(limit).toList();
  }

  /// 基于口味获取推荐
  List<Food> getRecommendationsByTaste(List<String> tastes, {int limit = 10}) {
    final allFoods = FoodDatabase.getAllFoods();
    final scoredFoods = <ScoredFood>[];

    for (final food in allFoods) {
      double score = 0.0;
      for (final taste in tastes) {
        if (food.tasteAttributes.contains(taste)) {
          score += 1.0;
        }
      }
      if (score > 0) {
        scoredFoods.add(ScoredFood(
          food: food,
          score: score,
          reason: 'Taste match',
          scoreBreakdown: {},
        ));
      }
    }

    scoredFoods.sort((a, b) => b.score.compareTo(a.score));
    return scoredFoods.take(limit).map((sf) => sf.food).toList();
  }

  /// 计算个性化分数 - 优化版本
  double _calculatePersonalizedScore(Food food, UserPreference userPreference) {
    double score = 1.0; // 基础分数

    // 1. 历史偏好权重 (40%)
    // 收藏食物高权重加分
    if (userPreference.favoriteFoods.contains(food.name)) {
      score += 8.0;
    }

    // 不喜欢的食物重度减分
    if (userPreference.dislikedFoods.contains(food.name)) {
      score -= 10.0;
    }

    // 2. 菜系偏好匹配 (25%)
    final cuisineScore =
        userPreference.cuisinePreferences[food.cuisineType] ?? 0.0;
    score += cuisineScore * 0.5; // 增加菜系权重

    // 3. 口味偏好匹配 (25%) - 增强匹配算法
    double tasteMatchScore = 0.0;
    for (final taste in food.tasteAttributes) {
      final tasteScore = userPreference.tastePreferences[taste] ?? 0.0;
      tasteMatchScore += tasteScore * 0.3;

      // 语义相似度匹配
      tasteMatchScore +=
          _calculateTasteSimilarity(taste, userPreference.likedTastes) * 0.2;
    }
    score += tasteMatchScore;

    // 4. 气泡权重匹配 (10%)
    for (final taste in food.tasteAttributes) {
      final bubbleWeight = userPreference.getBubblePreference(taste);
      score += bubbleWeight * 0.1;
    }

    // 5. 质量评分加权
    score += food.rating * 0.3;

    // 6. 时间衰减因子 - 优先推荐最近没有推荐过的食物
    final daysSinceUpdate =
        DateTime.now().difference(userPreference.lastUpdated).inDays;
    final timeDecay = 1.0 / (1.0 + daysSinceUpdate * 0.1);
    score *= timeDecay;

    return score;
  }

  /// 计算口味相似度
  double _calculateTasteSimilarity(String taste, List<String> likedTastes) {
    // 口味相似度映射
    const similarityMap = {
      '甜': ['蜜甜', '清甜', '微甜', '香甜'],
      '辣': ['微辣', '中辣', '重辣', '麻辣', '香辣'],
      '酸': ['微酸', '酸甜', '酸辣', '清酸'],
      '咸': ['微咸', '咸鲜', '咸香'],
      '鲜': ['清鲜', '咸鲜', '鲜美'],
      '香': ['清香', '浓香', '咸香'],
      '清淡': ['清爽', '清香', '清甜'],
      '浓郁': ['浓香', '厚重', '重口'],
    };

    double similarity = 0.0;
    for (final likedTaste in likedTastes) {
      if (taste == likedTaste) {
        similarity += 1.0; // 完全匹配
      } else {
        // 检查相似度
        final similar = similarityMap[likedTaste] ?? [];
        if (similar.contains(taste)) {
          similarity += 0.6; // 相似匹配
        }
      }
    }

    return similarity;
  }

  /// 计算食物分数（用于recommendBasedOnPreferences方法）
  double _calculateFoodScore(Food food, UserPreference preference) {
    return _calculatePersonalizedScore(food, preference);
  }

  /// 获取推荐（兼容方法）
  Future<List<Food>> getRecommendations({
    required List<Food> availableFoods,
    required int count,
    UserPreference? userPreference,
  }) async {
    if (userPreference != null) {
      // 使用个性化推荐
      final scoredFoods = <ScoredFood>[];

      for (final food in availableFoods) {
        double score = _calculatePersonalizedScore(food, userPreference);
        if (score > 0) {
          scoredFoods.add(ScoredFood(
            food: food,
            score: score,
            reason: 'Personalized recommendation',
            scoreBreakdown: {},
          ));
        }
      }

      scoredFoods.sort((a, b) => b.score.compareTo(a.score));
      return scoredFoods.take(count).map((sf) => sf.food).toList();
    } else {
      // 使用基础推荐
      final shuffled = List<Food>.from(availableFoods)..shuffle(_random);
      return shuffled.take(count).toList();
    }
  }

  /// 根据用户偏好推荐食物
  List<Food> recommendBasedOnPreferences(UserPreference preference) {
    final allFoods = FoodDatabase.getAllFoods();

    // 基于用户偏好计算推荐分数
    final scoredFoods = allFoods.map((food) {
      double score = _calculateFoodScore(food, preference);
      return MapEntry(food, score);
    }).toList();

    // 按分数排序并返回前10个
    scoredFoods.sort((a, b) => b.value.compareTo(a.value));
    return scoredFoods.take(10).map((entry) => entry.key).toList();
  }

  /// 根据选中的气泡推荐食物
  List<Food> recommendBasedOnBubbles(List<Bubble> selectedBubbles) {
    if (selectedBubbles.isEmpty) return [];

    final allFoods = FoodDatabase.getAllFoods();

    // 提取选中气泡的名称作为口味属性
    final selectedTastes = selectedBubbles.map((bubble) => bubble.name).toSet();

    // 计算匹配度
    final matchedFoods = allFoods.where((food) {
      return food.tasteAttributes
              .any((taste) => selectedTastes.contains(taste)) ||
          food.cuisineType == selectedBubbles.first.name ||
          food.name.contains(selectedBubbles.first.name);
    }).toList();

    // 按匹配度排序
    matchedFoods.sort((a, b) {
      final aMatches = a.tasteAttributes
          .where((taste) => selectedTastes.contains(taste))
          .length;
      final bMatches = b.tasteAttributes
          .where((taste) => selectedTastes.contains(taste))
          .length;
      return bMatches.compareTo(aMatches);
    });

    return matchedFoods.take(10).toList();
  }

  /// 获取热门推荐
  List<Food> getPopularRecommendations() {
    final allFoods = FoodDatabase.getAllFoods();

    // 按评分和评价数量排序
    final popularFoods = allFoods.where((food) => food.rating > 4.0).toList();
    popularFoods.sort((a, b) {
      final aScore = a.rating * (a.ratingCount + 1);
      final bScore = b.rating * (b.ratingCount + 1);
      return bScore.compareTo(aScore);
    });

    return popularFoods.take(10).toList();
  }
}

/// 评分食物
class ScoredFood {
  final Food food;
  final double score;
  final String reason;
  final Map<String, double> scoreBreakdown;

  ScoredFood({
    required this.food,
    required this.score,
    required this.reason,
    required this.scoreBreakdown,
  });
}
