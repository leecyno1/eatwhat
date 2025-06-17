import 'dart:math';
import '../models/bubble.dart';
import '../models/food.dart';
import '../models/user_preference.dart';

/// 推荐引擎，根据选中的气泡生成食物推荐
class RecommendationEngine {
  static final Random _random = Random();

  /// 根据选中的气泡生成推荐食物
  static List<Food> generateRecommendations(List<Bubble> selectedBubbles) {
    if (selectedBubbles.isEmpty) {
      return _getRandomFoods();
    }

    // 分析选中的气泡
    final analysis = _analyzeBubbles(selectedBubbles);
    
    // 获取所有可能的食物
    final allFoods = _getAllFoods();
    
    // 计算每个食物的匹配分数
    final scoredFoods = allFoods.map((food) {
      final score = _calculateMatchScore(food, analysis);
      return MapEntry(food, score);
    }).toList();
    
    // 按分数排序
    scoredFoods.sort((a, b) => b.value.compareTo(a.value));
    
    // 返回前10个推荐
    return scoredFoods.take(10).map((entry) => entry.key).toList();
  }

  /// 根据选中的气泡和用户偏好生成推荐食物
  static List<Food> generatePersonalizedRecommendations(
    List<Bubble> selectedBubbles,
    UserPreference userPreference,
  ) {
    if (selectedBubbles.isEmpty) {
      return _getPersonalizedRandomFoods(userPreference);
    }

    // 分析选中的气泡
    final analysis = _analyzeBubbles(selectedBubbles);
    
    // 获取所有可能的食物
    final allFoods = _getAllFoods();
    
    // 计算每个食物的匹配分数（包含用户偏好）
    final scoredFoods = allFoods.map((food) {
      final baseScore = _calculateMatchScore(food, analysis);
      final personalizedScore = _calculatePersonalizedScore(food, userPreference);
      final finalScore = baseScore * 0.7 + personalizedScore * 0.3; // 70%基础匹配 + 30%个人偏好
      return MapEntry(food, finalScore);
    }).toList();
    
    // 按分数排序
    scoredFoods.sort((a, b) => b.value.compareTo(a.value));
    
    // 设置收藏状态
    final recommendations = scoredFoods.take(10).map((entry) {
      final food = entry.key;
      final isFavorite = userPreference.favoriteFoods.contains(food.name);
      return food.copyWith(isFavorite: isFavorite);
    }).toList();
    
    return recommendations;
  }

  /// 分析选中的气泡
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
      }
    }
    
    return analysis;
  }

  /// 计算食物与气泡分析的匹配分数
  static double _calculateMatchScore(Food food, BubbleAnalysis analysis) {
    double score = 0.0;
    
    // 口味匹配
    for (final taste in analysis.tastes) {
      if (food.tasteAttributes.contains(taste)) {
        score += 3.0;
      }
    }
    
    // 菜系匹配
    for (final cuisine in analysis.cuisines) {
      if (food.cuisineType == cuisine) {
        score += 5.0;
      }
    }
    
    // 食材匹配
    for (final ingredient in analysis.ingredients) {
      if (food.ingredients.contains(ingredient)) {
        score += 2.0;
      }
    }
    
    // 情境匹配
    for (final scenario in analysis.scenarios) {
      if (food.scenarios?.contains(scenario) == true) {
        score += 2.5;
      }
    }
    
    // 营养匹配
    for (final nutrition in analysis.nutritions) {
      if (food.nutritionFacts?.containsKey(nutrition) == true) {
        score += 1.5;
      }
    }
    
    // 添加随机因子，增加推荐的多样性
    score += _random.nextDouble() * 0.5;
    
    return score;
  }

  /// 获取随机食物（当没有选中气泡时）
  static List<Food> _getRandomFoods() {
    final allFoods = _getAllFoods();
    allFoods.shuffle(_random);
    return allFoods.take(10).toList();
  }

  /// 获取所有食物数据
  static List<Food> _getAllFoods() {
    return [
      // 川菜
      Food(
        name: '麻婆豆腐',
        description: '经典川菜，麻辣鲜香',
        cuisineType: '川菜',
        imageUrl: 'assets/images/foods/mapo_tofu.jpg',
        rating: 4.5,
        calories: 180,
        ingredients: ['豆腐', '猪肉', '豆瓣酱'],
        tasteAttributes: ['辣', '麻', '鲜'],
        scenarios: ['午餐', '晚餐'],
        nutritionFacts: {
          '蛋白质': 12.5,
          '碳水化合物': 8.2,
          '脂肪': 11.3,
          '纤维': 2.1,
        },
      ),
      Food(
        name: '宫保鸡丁',
        description: '川菜经典，酸甜微辣',
        cuisineType: '川菜',
        imageUrl: 'assets/images/foods/gongbao_chicken.jpg',
        rating: 4.3,
        calories: 220,
        ingredients: ['鸡肉', '花生', '青椒'],
        tasteAttributes: ['辣', '甜', '酸'],
        scenarios: ['午餐', '晚餐', '聚餐'],
        nutritionFacts: {
          '蛋白质': 18.5,
          '碳水化合物': 12.1,
          '脂肪': 13.2,
          '纤维': 2.8,
        },
      ),
      
      // 粤菜
      Food(
        name: '白切鸡',
        description: '粤菜经典，清淡鲜美',
        cuisineType: '粤菜',
        imageUrl: 'assets/images/foods/white_cut_chicken.jpg',
        rating: 4.2,
        calories: 165,
        ingredients: ['鸡肉', '姜', '葱'],
        tasteAttributes: ['鲜', '清淡'],
        scenarios: ['午餐', '晚餐'],
        nutritionFacts: {
          '蛋白质': 25.2,
          '碳水化合物': 0.5,
          '脂肪': 6.8,
          '纤维': 0.1,
        },
      ),
      Food(
        name: '蒸蛋羹',
        description: '嫩滑香甜的蒸蛋',
        cuisineType: '粤菜',
        imageUrl: 'assets/images/foods/steamed_egg.jpg',
        rating: 4.0,
        calories: 120,
        ingredients: ['蛋', '牛奶'],
        tasteAttributes: ['嫩', '甜'],
        scenarios: ['早餐', '夜宵'],
        nutritionFacts: {
          '蛋白质': 8.5,
          '碳水化合物': 2.1,
          '脂肪': 8.2,
        },
      ),
      
      // 湘菜
      Food(
        name: '剁椒鱼头',
        description: '湘菜招牌，鲜辣开胃',
        cuisineType: '湘菜',
        imageUrl: 'assets/images/foods/fish_head.jpg',
        rating: 4.4,
        calories: 200,
        ingredients: ['鱼头', '剁椒', '蒸鱼豉油'],
        tasteAttributes: ['辣', '鲜', '香'],
        scenarios: ['午餐', '晚餐', '聚餐'],
        nutritionFacts: {
          '蛋白质': 20.1,
          '碳水化合物': 5.2,
          '脂肪': 12.8,
        },
      ),
      Food(
        name: '口味虾',
        description: '湘菜特色，麻辣鲜香',
        cuisineType: '湘菜',
        imageUrl: 'assets/images/foods/spicy_shrimp.jpg',
        rating: 4.6,
        calories: 180,
        ingredients: ['小龙虾', '干辣椒', '花椒'],
        tasteAttributes: ['辣', '麻', '鲜'],
        scenarios: ['夜宵', '聚餐'],
        nutritionFacts: {
          '蛋白质': 18.9,
          '碳水化合物': 2.1,
          '脂肪': 8.5,
        },
      ),
      
      // 鲁菜
      Food(
        name: '糖醋里脊',
        description: '鲁菜经典，酸甜可口',
        cuisineType: '鲁菜',
        imageUrl: 'assets/images/foods/sweet_sour_pork.jpg',
        rating: 4.1,
        calories: 250,
        ingredients: ['猪里脊', '番茄酱', '醋'],
        tasteAttributes: ['甜', '酸', '香'],
        scenarios: ['午餐', '晚餐'],
        nutritionFacts: {
          '蛋白质': 22.3,
          '碳水化合物': 15.6,
          '脂肪': 14.2,
        },
      ),
      Food(
        name: '九转大肠',
        description: '鲁菜名菜，口感丰富',
        cuisineType: '鲁菜',
        imageUrl: 'assets/images/foods/braised_intestines.jpg',
        rating: 3.8,
        calories: 280,
        ingredients: ['猪大肠', '冰糖', '生抽'],
        tasteAttributes: ['甜', '咸', '香'],
        scenarios: ['午餐', '晚餐'],
        nutritionFacts: {
          '蛋白质': 16.8,
          '碳水化合物': 8.9,
          '脂肪': 20.5,
        },
      ),
      
      // 苏菜
      Food(
        name: '松鼠桂鱼',
        description: '苏菜代表，造型精美',
        cuisineType: '苏菜',
        imageUrl: 'assets/images/foods/squirrel_fish.jpg',
        rating: 4.7,
        calories: 220,
        ingredients: ['桂鱼', '番茄酱', '松子'],
        tasteAttributes: ['甜', '酸', '鲜'],
        scenarios: ['午餐', '晚餐', '聚餐'],
        nutritionFacts: {
          '蛋白质': 24.5,
          '碳水化合物': 12.3,
          '脂肪': 9.8,
        },
      ),
      Food(
        name: '蟹粉小笼包',
        description: '苏菜精品，汤汁鲜美',
        cuisineType: '苏菜',
        imageUrl: 'assets/images/foods/crab_dumpling.jpg',
        rating: 4.8,
        calories: 160,
        ingredients: ['面粉', '蟹粉', '猪肉'],
        tasteAttributes: ['鲜', '香', '嫩'],
        scenarios: ['早餐', '午餐', '下午茶'],
        nutritionFacts: {
          '蛋白质': 12.6,
          '碳水化合物': 18.9,
          '脂肪': 6.2,
        },
      ),
    ];
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
    final allFoods = _getAllFoods();
    
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

/// 气泡分析结果
class BubbleAnalysis {
  final Set<String> tastes = {};
  final Set<String> cuisines = {};
  final Set<String> ingredients = {};
  final Set<String> scenarios = {};
  final Set<String> nutritions = {};
}