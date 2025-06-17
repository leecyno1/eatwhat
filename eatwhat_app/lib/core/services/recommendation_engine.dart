import 'dart:math';
import '../models/bubble.dart';
import '../models/food.dart';
import '../models/user_preference.dart';
import '../data/food_database.dart';

/// 推荐引擎
/// 基于气泡选择和用户偏好生成个性化食物推荐
class RecommendationEngine {
  static final Random _random = Random();

  /// 基于气泡生成推荐
  static List<Food> getRecommendationsByBubbles(List<Bubble> selectedBubbles, {UserPreference? userPreference}) {
    if (selectedBubbles.isEmpty) {
      return getRandomRecommendations(limit: 10, userPreference: userPreference);
    }

    final analysis = _analyzeBubbles(selectedBubbles);
    final allFoods = FoodDatabase.getAllFoods();
    final scoredFoods = <ScoredFood>[];

    for (final food in allFoods) {
      double score = _calculateFoodScore(food, analysis);
      
      // 用户偏好调整
      if (userPreference != null) {
        score += _calculatePersonalizedScore(food, userPreference);
      }
      
      scoredFoods.add(ScoredFood(food, score));
    }

    // 排序并返回前10个推荐
    scoredFoods.sort((a, b) => b.score.compareTo(a.score));
    return scoredFoods.take(10).map((sf) => sf.food).toList();
  }

  /// 获取随机推荐
  static List<Food> getRandomRecommendations({int limit = 10, UserPreference? userPreference}) {
    if (userPreference != null) {
      return _getPersonalizedRandomFoods(userPreference).take(limit).toList();
    }
    
    final allFoods = FoodDatabase.getAllFoods();
    final shuffled = List<Food>.from(allFoods)..shuffle(_random);
    return shuffled.take(limit).toList();
  }

  /// 基于菜系获取推荐
  static List<Food> getRecommendationsByCuisine(String cuisineType, {int limit = 10}) {
    final allFoods = FoodDatabase.getAllFoods();
    final filteredFoods = allFoods.where((food) => food.cuisineType == cuisineType).toList();
    
    if (filteredFoods.length <= limit) {
      return filteredFoods;
    }
    
    filteredFoods.shuffle(_random);
    return filteredFoods.take(limit).toList();
  }

  /// 基于口味获取推荐
  static List<Food> getRecommendationsByTaste(List<String> tastes, {int limit = 10}) {
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
        scoredFoods.add(ScoredFood(food, score));
      }
    }

    scoredFoods.sort((a, b) => b.score.compareTo(a.score));
    return scoredFoods.take(limit).map((sf) => sf.food).toList();
  }

  /// 基于价格范围获取推荐
  static List<Food> getRecommendationsByPriceRange(double minPrice, double maxPrice, {int limit = 10}) {
    final allFoods = FoodDatabase.getAllFoods();
    final filteredFoods = allFoods.where((food) {
      final price = food.price;
      return price != null && price >= minPrice && price <= maxPrice;
    }).toList();
    
    filteredFoods.shuffle(_random);
    return filteredFoods.take(limit).toList();
  }

  /// 基于热量范围获取推荐
  static List<Food> getRecommendationsByCalories(int maxCalories, {int limit = 10}) {
    final allFoods = FoodDatabase.getAllFoods();
    final filteredFoods = allFoods.where((food) {
      final calories = food.calories;
      return calories != null && calories <= maxCalories;
    }).toList();
    
    filteredFoods.shuffle(_random);
    return filteredFoods.take(limit).toList();
  }

  /// 基于用餐场景获取推荐
  static List<Food> getRecommendationsByScenario(String scenario, {int limit = 10}) {
    final allFoods = FoodDatabase.getAllFoods();
    final filteredFoods = allFoods.where((food) {
      return food.scenarios?.contains(scenario) ?? false;
    }).toList();
    
    filteredFoods.shuffle(_random);
    return filteredFoods.take(limit).toList();
  }

  /// 获取高评分推荐
  static List<Food> getHighRatedRecommendations({int limit = 10, double minRating = 4.0}) {
    final allFoods = FoodDatabase.getAllFoods();
    final highRatedFoods = allFoods.where((food) => food.rating >= minRating).toList();
    
    // 按评分排序
    highRatedFoods.sort((a, b) => b.rating.compareTo(a.rating));
    return highRatedFoods.take(limit).toList();
  }

  /// 获取新品推荐（基于ID随机性，模拟新菜品）
  static List<Food> getNewDishRecommendations({int limit = 10}) {
    final allFoods = FoodDatabase.getAllFoods();
    
    // 模拟新品：选择ID较大的食物
    final sortedByIdDesc = List<Food>.from(allFoods)
      ..sort((a, b) => b.id.compareTo(a.id));
    
    return sortedByIdDesc.take(limit).toList();
  }

  /// 分析气泡选择
  static BubbleAnalysis _analyzeBubbles(List<Bubble> bubbles) {
    final analysis = BubbleAnalysis();
    
    for (final bubble in bubbles) {
      switch (bubble.type) {
        case BubbleType.taste:
          analysis.tastes.add(bubble.name);
          break;
        case BubbleType.cuisine:
          analysis.cuisines.add(bubble.name);
          break;
        case BubbleType.ingredient:
          analysis.ingredients.add(bubble.name);
          break;
        case BubbleType.scenario:
          analysis.scenarios.add(bubble.name);
          break;
        case BubbleType.nutrition:
          analysis.nutritions.add(bubble.name);
          break;
        default:
          break;
      }
    }
    
    return analysis;
  }

  /// 计算食物分数
  static double _calculateFoodScore(Food food, BubbleAnalysis analysis) {
    double score = 0.0;

    // 菜系匹配 (权重: 5.0)
    if (analysis.cuisines.contains(food.cuisineType)) {
      score += 5.0;
    }

    // 口味匹配 (权重: 3.0)
    for (final taste in analysis.tastes) {
      if (food.tasteAttributes.contains(taste)) {
        score += 3.0;
      }
    }

    // 食材匹配 (权重: 2.0)
    for (final ingredient in analysis.ingredients) {
      if (food.ingredients.contains(ingredient)) {
        score += 2.0;
      }
    }

    // 场景匹配 (权重: 2.5)
    for (final scenario in analysis.scenarios) {
      if (food.scenarios?.contains(scenario) ?? false) {
        score += 2.5;
      }
    }

    // 营养匹配 (权重: 1.5)
    for (final nutrition in analysis.nutritions) {
      if (food.nutritionFacts?.containsKey(nutrition) ?? false) {
        score += 1.5;
      }
    }

    // 评分加成
    score += food.rating * 0.5;

    return score;
  }

  /// 计算个性化分数
  static double _calculatePersonalizedScore(Food food, UserPreference userPreference) {
    double score = 0.0;

    // 收藏食物加分
    if (userPreference.favoriteFoods.contains(food.name)) {
      score += 2.0;
    }

    // 不喜欢的食物减分
    if (userPreference.dislikedFoods.contains(food.name)) {
      score -= 2.0;
    }

    // 菜系偏好
    final cuisineScore = userPreference.cuisinePreferences[food.cuisineType] ?? 0;
    score += cuisineScore * 0.1;

    // 口味偏好
    for (final taste in food.tasteAttributes) {
      final tasteScore = userPreference.tastePreferences[taste] ?? 0;
      score += tasteScore * 0.05;
    }

    return score;
  }

  /// 获取个性化随机食物
  static List<Food> _getPersonalizedRandomFoods(UserPreference userPreference) {
    final allFoods = FoodDatabase.getAllFoods();
    
    // 过滤掉不喜欢的食物
    final filteredFoods = allFoods.where((food) => 
      !userPreference.dislikedFoods.contains(food.name)
    ).toList();
    
    // 优先推荐收藏的食物
    final favoriteFoods = filteredFoods.where((food) => 
      userPreference.favoriteFoods.contains(food.name)
    ).toList();
    
    final recommendations = <Food>[];
    
    // 添加收藏食物
    recommendations.addAll(favoriteFoods.take(5));
    
    // 随机添加其他食物
    final remainingFoods = filteredFoods.where((food) => 
      !userPreference.favoriteFoods.contains(food.name)
    ).toList();
    remainingFoods.shuffle(_random);
    
    final needed = 10 - recommendations.length;
    recommendations.addAll(remainingFoods.take(needed));
    
    // 设置收藏状态
    return recommendations.map((food) {
      final isFavorite = userPreference.favoriteFoods.contains(food.name);
      return food.copyWith(isFavorite: isFavorite);
    }).toList();
  }
}

/// 带分数的食物
class ScoredFood {
  final Food food;
  final double score;

  ScoredFood(this.food, this.score);
}

/// 气泡分析结果
class BubbleAnalysis {
  final Set<String> tastes = {};
  final Set<String> cuisines = {};
  final Set<String> ingredients = {};
  final Set<String> scenarios = {};
  final Set<String> nutritions = {};
}