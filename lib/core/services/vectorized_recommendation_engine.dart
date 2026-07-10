import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:ml_linalg/linalg.dart';

import '../models/food.dart';
import '../models/bubble.dart';
import '../models/user_preference.dart';
import 'collaborative_filtering_service.dart';

/// 向量化推荐引擎 - Phase 1 核心算法优化
/// 实现余弦相似度、TF-IDF和协同过滤算法
class VectorizedRecommendationEngine {
  static final VectorizedRecommendationEngine _instance =
      VectorizedRecommendationEngine._internal();
  factory VectorizedRecommendationEngine() => _instance;
  VectorizedRecommendationEngine._internal();

  // 协同过滤服务
  final CollaborativeFilteringService _cfService =
      CollaborativeFilteringService();

  // 混合推荐权重
  static const double contentWeight = 0.7;
  static const double collaborativeWeight = 0.3;

  // 特征词汇表 - 用于向量化
  static const List<String> _featureVocabulary = [
    // 口味特征
    '甜', '辣', '酸', '咸', '鲜', '香', '麻', '苦', '清淡', '浓郁',
    '微辣', '中辣', '重辣', '麻辣', '香辣', '酸甜', '咸鲜', '清香',

    // 菜系特征
    '川菜', '粤菜', '湘菜', '鲁菜', '苏菜', '浙菜', '闽菜', '徽菜',
    '京菜', '沪菜', '东北菜', '西北菜', '家常菜', '素食',

    // 食材特征
    '肉类', '蔬菜', '海鲜', '豆制品', '蛋类', '面食', '米饭',
    '鸡肉', '猪肉', '牛肉', '鱼肉', '虾', '蟹', '豆腐',

    // 场景特征
    '下饭菜', '宵夜', '聚餐', '减脂', '暖胃', '快手菜', '汤类',
    '节日菜', '儿童菜', '老人菜', '孕妇菜',

    // 烹饪特征
    '炒', '煮', '蒸', '炸', '烤', '焖', '炖', '凉拌', '烘焙',

    // 难度特征
    '简单', '中等', '困难',

    // 营养特征
    '高蛋白', '低脂', '高纤维', '维生素', '钙质', '铁质',
  ];

  static final int _vectorDimension = _featureVocabulary.length;

  /// 将食物转换为特征向量
  Vector foodToVector(Food food) {
    final features = List<double>.filled(_vectorDimension, 0.0);

    // 1. 口味特征权重
    final tasteAttributes = food.tasteAttributes ?? [];
    for (final taste in tasteAttributes) {
      final index = _featureVocabulary.indexOf(taste);
      if (index != -1) {
        features[index] = 1.0;
      }

      // 处理相似口味
      _addSimilarTasteFeatures(taste, features);
    }

    // 2. 菜系特征权重
    final cuisineIndex = _featureVocabulary.indexOf(food.cuisineType ?? '未知');
    if (cuisineIndex != -1) {
      features[cuisineIndex] = 1.0;
    }

    // 3. 食材特征权重
    final ingredients = food.ingredients ?? [];
    for (final ingredient in ingredients) {
      _addIngredientFeatures(ingredient, features);
    }

    // 4. 场景特征权重
    if (food.scenarios != null) {
      for (final scenario in food.scenarios!) {
        final index = _featureVocabulary.indexOf(scenario);
        if (index != -1) {
          features[index] = 0.8;
        }
      }
    }

    // 5. 难度特征权重
    if (food.difficulty != null) {
      final difficultyIndex = _featureVocabulary.indexOf(food.difficulty!);
      if (difficultyIndex != -1) {
        features[difficultyIndex] = 0.6;
      }
    }

    // 6. 营养特征权重
    if (food.nutritionFacts != null) {
      final nutritionMap = food.nutritionFacts!
          .map((key, value) => MapEntry(key, value is double ? value : (value as num).toDouble()));
      _addNutritionFeatures(nutritionMap, features);
    }

    // 7. 质量权重 (评分转换为特征)
    final qualityBoost = (food.rating / 5.0).clamp(0.0, 1.0);
    for (int i = 0; i < features.length; i++) {
      if (features[i] > 0) {
        features[i] *= (1.0 + qualityBoost * 0.2); // 最多20%加成
      }
    }

    return Vector.fromList(features);
  }

  /// 将用户偏好转换为特征向量
  Vector preferencesToVector(
    List<Bubble> selectedBubbles,
    UserPreference userPreference,
  ) {
    final features = List<double>.filled(_vectorDimension, 0.0);

    // 1. 从选中气泡提取特征 (权重最高)
    for (final bubble in selectedBubbles) {
      final index = _featureVocabulary.indexOf(bubble.name);
      if (index != -1) {
        // 根据气泡类型给予不同权重
        double weight = 1.0;
        switch (bubble.type) {
          case BubbleType.taste:
            weight = 1.2; // 口味权重最高
            break;
          case BubbleType.cuisine:
            weight = 1.0;
            break;
          case BubbleType.ingredient:
            weight = 0.8;
            break;
          case BubbleType.scenario:
            weight = 0.9;
            break;
          default:
            weight = 0.7;
        }
        features[index] = weight;
      }

      // 添加相似特征
      _addSimilarFeatures(bubble.name, features, 0.5);
    }

    // 2. 从历史偏好提取特征 (中等权重)
    for (final taste in userPreference.likedTastes) {
      final index = _featureVocabulary.indexOf(taste);
      if (index != -1) {
        features[index] = max(features[index], 0.8);
      }
    }

    // 3. 从菜系偏好提取特征
    userPreference.cuisinePreferences.forEach((cuisine, score) {
      final index = _featureVocabulary.indexOf(cuisine);
      if (index != -1) {
        final normalizedScore = (score / 10.0).clamp(0.0, 1.0);
        features[index] = max(features[index], normalizedScore * 0.7);
      }
    });

    // 4. 从口味偏好提取特征
    userPreference.tastePreferences.forEach((taste, score) {
      final index = _featureVocabulary.indexOf(taste);
      if (index != -1) {
        final normalizedScore = (score / 10.0).clamp(0.0, 1.0);
        features[index] = max(features[index], normalizedScore * 0.6);
      }
    });

    return Vector.fromList(features);
  }

  /// 计算余弦相似度
  double calculateCosineSimilarity(Vector userVector, Vector foodVector) {
    try {
      // 计算点积
      final dotProduct = userVector.dot(foodVector);

      // 计算向量长度
      final userMagnitude = userVector.norm();
      final foodMagnitude = foodVector.norm();

      // 避免除零
      if (userMagnitude == 0.0 || foodMagnitude == 0.0) {
        return 0.0;
      }

      // 余弦相似度 = 点积 / (向量A长度 * 向量B长度)
      final similarity = dotProduct / (userMagnitude * foodMagnitude);

      return similarity.clamp(0.0, 1.0);
    } catch (e) {
      print('计算余弦相似度时出错: $e');
      return 0.0;
    }
  }

  /// 向量化推荐主方法
  Future<List<Food>> getVectorizedRecommendations(
    List<Bubble> selectedBubbles,
    UserPreference userPreference,
    List<Food> candidateFoods, {
    int limit = 10,
  }) async {
    if (candidateFoods.isEmpty) return [];

    // 1. 构建用户偏好向量
    final userVector = preferencesToVector(selectedBubbles, userPreference);

    // 2. 计算每个食物与用户偏好的相似度
    final scoredFoods = <VectorizedScoredFood>[];

    for (final food in candidateFoods) {
      final foodVector = foodToVector(food);

      // 计算余弦相似度
      final cosineSimilarity = calculateCosineSimilarity(userVector, foodVector);

      // 计算综合分数 (相似度 + 质量权重 + 随机因子)
      double finalScore = cosineSimilarity * 0.7; // 相似度权重70%
      finalScore += (food.rating / 5.0) * 0.2; // 质量权重20%
      finalScore += _calculateDiversityBonus(food, scoredFoods) * 0.1; // 多样性权重10%

      scoredFoods.add(VectorizedScoredFood(
        food: food,
        score: finalScore,
        cosineSimilarity: cosineSimilarity,
        qualityScore: food.rating,
      ));
    }

    // 3. 排序并返回结果
    scoredFoods.sort((a, b) => b.score.compareTo(a.score));

    print('🧮 向量化推荐完成，处理了 ${candidateFoods.length} 个候选食物');
    print(
        '📊 Top 3 推荐分数: ${scoredFoods.take(3).map((f) => '${f.food.name}:${f.score.toStringAsFixed(3)}').join(', ')}');

    return scoredFoods.take(limit).map((sf) => sf.food).toList();
  }

  /// 添加相似口味特征
  void _addSimilarTasteFeatures(String taste, List<double> features) {
    const similarityMap = {
      '辣': ['麻辣', '香辣', '微辣', '中辣', '重辣'],
      '甜': ['蜜甜', '清甜', '微甜', '香甜', '酸甜'],
      '酸': ['酸甜', '酸辣', '微酸'],
      '咸': ['咸鲜', '咸香', '微咸'],
      '鲜': ['咸鲜', '清鲜', '鲜美'],
      '香': ['咸香', '清香', '浓香'],
      '清淡': ['清爽', '清香', '清甜'],
      '浓郁': ['浓香', '厚重', '重口'],
    };

    final similar = similarityMap[taste] ?? [];
    for (final similarTaste in similar) {
      final index = _featureVocabulary.indexOf(similarTaste);
      if (index != -1) {
        features[index] = max(features[index], 0.6); // 相似特征权重
      }
    }
  }

  /// 添加食材特征
  void _addIngredientFeatures(String ingredient, List<double> features) {
    // 食材分类映射
    const ingredientMap = {
      '肉类': ['肉', '鸡', '鸭', '鹅', '猪', '牛', '羊', '兔'],
      '蔬菜': ['菜', '萝卜', '白菜', '豆芽', '韭菜', '菠菜', '芹菜'],
      '海鲜': ['鱼', '虾', '蟹', '贝', '鱿鱼', '章鱼', '海带'],
      '豆制品': ['豆腐', '豆干', '腐竹', '豆皮', '豆浆'],
      '蛋类': ['蛋', '鸡蛋', '鸭蛋', '鹌鹑蛋'],
    };

    ingredientMap.forEach((category, keywords) {
      if (keywords.any((keyword) => ingredient.contains(keyword))) {
        final index = _featureVocabulary.indexOf(category);
        if (index != -1) {
          features[index] = max(features[index], 0.7);
        }
      }
    });
  }

  /// 添加营养特征
  void _addNutritionFeatures(Map<String, double> nutritionFacts, List<double> features) {
    // 蛋白质含量
    final protein = nutritionFacts['protein'] ?? 0.0;
    if (protein > 20.0) {
      // 高蛋白
      final index = _featureVocabulary.indexOf('高蛋白');
      if (index != -1) {
        features[index] = 0.8;
      }
    }

    // 脂肪含量
    final fat = nutritionFacts['fat'] ?? 0.0;
    if (fat < 5.0) {
      // 低脂
      final index = _featureVocabulary.indexOf('低脂');
      if (index != -1) {
        features[index] = 0.7;
      }
    }

    // 纤维含量
    final fiber = nutritionFacts['fiber'] ?? 0.0;
    if (fiber > 3.0) {
      // 高纤维
      final index = _featureVocabulary.indexOf('高纤维');
      if (index != -1) {
        features[index] = 0.6;
      }
    }
  }

  /// 添加相似特征
  void _addSimilarFeatures(String feature, List<double> features, double weight) {
    // 场景相似性映射
    if (feature.contains('辣')) {
      _setSimilarFeatures(features, ['川菜', '湘菜', '麻辣'], weight);
    }
    if (feature.contains('清淡')) {
      _setSimilarFeatures(features, ['粤菜', '苏菜', '蒸'], weight);
    }
    if (feature.contains('下饭')) {
      _setSimilarFeatures(features, ['咸', '香', '重口', '炒'], weight);
    }
  }

  /// 设置相似特征权重
  void _setSimilarFeatures(List<double> features, List<String> similarFeatures, double weight) {
    for (final similar in similarFeatures) {
      final index = _featureVocabulary.indexOf(similar);
      if (index != -1) {
        features[index] = max(features[index], weight);
      }
    }
  }

  /// 计算多样性加分 (避免推荐过于单一)
  double _calculateDiversityBonus(Food food, List<VectorizedScoredFood> existingFoods) {
    if (existingFoods.isEmpty) return 0.0;

    // 检查菜系多样性
    final existingCuisines = existingFoods.map((f) => f.food.cuisineType).toSet();
    if (!existingCuisines.contains(food.cuisineType)) {
      return 0.3; // 新菜系加分
    }

    // 检查口味多样性
    final existingTastes = existingFoods.expand((f) => f.food.tasteAttributes ?? []).toSet();
    final newTastes =
        (food.tasteAttributes ?? []).where((taste) => !existingTastes.contains(taste));
    if (newTastes.isNotEmpty) {
      return 0.1; // 新口味加分
    }

    return 0.0; // 无多样性加分
  }
}

/// 向量化评分食物
class VectorizedScoredFood {
  final Food food;
  final double score;
  final double cosineSimilarity;
  final double qualityScore;

  VectorizedScoredFood({
    required this.food,
    required this.score,
    required this.cosineSimilarity,
    required this.qualityScore,
  });

  @override
  String toString() {
    return 'VectorizedScoredFood(${food.name}, score: ${score.toStringAsFixed(3)}, similarity: ${cosineSimilarity.toStringAsFixed(3)})';
  }
}

// ============ 混合推荐方法 ============

/// 混合推荐主方法
/// 结合内容过滤和协同过滤生成推荐
Future<List<Food>> getHybridRecommendations({
  required String userId,
  required List<String> bubbleIds,
  required List<Food> candidateFoods,
  int limit = 10,
}) async {
  final engine = VectorizedRecommendationEngine();

  // 冷启动检查：如果用户交互记录少于3条，不使用协同过滤
  final hasEnoughData = engine._cfService.hasEnoughDataForCF(userId);

  if (!hasEnoughData) {
    debugPrint('⚠️ 用户交互数据不足，回退到纯内容过滤');
    return engine.getVectorizedRecommendations(
      [], // 不需要气泡
      UserPreference(userId: userId),
      candidateFoods,
      limit: limit,
    );
  }

  // 1. 内容过滤推荐（原有逻辑）
  final contentRecs = await engine.getVectorizedRecommendations(
    [], // 不需要气泡
    UserPreference(userId: userId),
    candidateFoods,
    limit: limit * 2,
  );

  // 2. 协同过滤推荐
  final cfRecipeIds = await engine._cfService.recommendForUser(
    userId,
    limit: limit,
    excludeRecipeIds: contentRecs.map((f) => f.id).toSet(),
  );

  // 3. 获取 CF 推荐的具体菜品
  final cfFoods = candidateFoods
      .where((f) => cfRecipeIds.contains(f.id))
      .toList();

  // 4. 混合排序
  final hybridList = <Food>[];
  int contentIdx = 0;
  int cfIdx = 0;

  while (hybridList.length < limit &&
      (contentIdx < contentRecs.length || cfIdx < cfFoods.length)) {
    if (contentIdx < contentRecs.length &&
        (cfIdx >= cfFoods.length ||
            contentIdx * VectorizedRecommendationEngine.contentWeight <=
                cfIdx * VectorizedRecommendationEngine.collaborativeWeight)) {
      hybridList.add(contentRecs[contentIdx++]);
    } else if (cfIdx < cfFoods.length) {
      hybridList.add(cfFoods[cfIdx++]);
    }
  }

  debugPrint('🎯 混合推荐完成: ${hybridList.length} 个推荐 (内容:${contentRecs.length}, CF:${cfFoods.length})');
  return hybridList;
}
