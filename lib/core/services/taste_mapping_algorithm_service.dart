import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:ml_linalg/vector.dart';

import '../models/recipe.dart';
import '../models/user_preference.dart';
import '../models/bubble.dart';

/// 口味映射算法服务
/// Phase 3: 实现用户口味偏好到菜谱的智能映射算法
class TasteMappingAlgorithmService {
  static final TasteMappingAlgorithmService _instance = TasteMappingAlgorithmService._internal();
  factory TasteMappingAlgorithmService() => _instance;
  TasteMappingAlgorithmService._internal();

  // 口味特征维度定义（对齐下厨房标准）
  static const List<String> tasteFeatures = [
    '甜', '酸', '苦', '辣', '咸', '鲜', '香', '麻', // 基础口味 8维
    '清淡', '浓郁', '爽脆', '嫩滑', '弹牙', '软糯', // 口感特征 6维
    '温热', '清凉', '滋补', '开胃', '解腻', '下饭', // 功效特征 6维
    '川菜', '粤菜', '湘菜', '鲁菜', '苏菜', '浙菜', '闽菜', '徽菜', // 菜系特征 8维
    '家常', '宴客', '快手', '精致', '素食', '荤菜', // 类型特征 6维
    '早餐', '午餐', '晚餐', '夜宵', '下午茶', '聚餐', // 场景特征 6维
    '春', '夏', '秋', '冬', '节日', '日常', // 时令特征 6维
  ];

  static const int featureDimension = 46; // 总特征维度

  final Map<String, Vector> _recipeVectors = {};
  final Map<String, TasteProfile> _tasteProfiles = {};
  bool _isInitialized = false;

  /// 初始化口味映射服务
  Future<void> initialize() async {
    if (_isInitialized) return;

    debugPrint('🧠 初始化口味映射算法服务...');

    // 初始化基础口味特征库
    await _initializeTasteProfiles();

    _isInitialized = true;
    debugPrint('✅ 口味映射算法服务初始化完成');
  }

  /// 将菜谱转换为口味特征向量
  Vector convertRecipeToVector(Recipe recipe) {
    final features = List<double>.filled(featureDimension, 0.0);

    // 1. 基础口味特征 (0-7)
    for (int i = 0; i < 8; i++) {
      final taste = tasteFeatures[i];
      if (recipe.tasteProfile.contains(taste)) {
        features[i] = recipe.tasteIntensity[taste] ?? 0.7;
      }
    }

    // 2. 口感特征 (8-13)
    final textureMapping = {
      '清淡': ['清淡', '清爽', '淡雅'],
      '浓郁': ['浓郁', '厚重', '醇厚'],
      '爽脆': ['爽脆', '脆嫩', '清脆'],
      '嫩滑': ['嫩滑', '顺滑', '柔嫩'],
      '弹牙': ['弹牙', '劲道', 'Q弹'],
      '软糯': ['软糯', '绵软', '糯香'],
    };

    for (int i = 8; i < 14; i++) {
      final textureType = tasteFeatures[i];
      final keywords = textureMapping[textureType] ?? [textureType];

      for (final keyword in keywords) {
        if (recipe.description.contains(keyword) ||
            recipe.tags.any((tag) => tag.contains(keyword))) {
          features[i] = 0.8;
          break;
        }
      }
    }

    // 3. 功效特征 (14-19)
    final effectMapping = {
      '温热': recipe.seasonalInfo.bestSeasons.contains('冬') ? 0.8 : 0.2,
      '清凉': recipe.seasonalInfo.bestSeasons.contains('夏') ? 0.8 : 0.2,
      '滋补': recipe.healthBenefits.contains('滋补') ? 0.9 : 0.0,
      '开胃': recipe.tasteProfile.contains('酸') ? 0.7 : 0.0,
      '解腻': recipe.tasteProfile.contains('清淡') ? 0.6 : 0.0,
      '下饭': recipe.scenarioTags.contains('下饭菜') ? 0.9 : 0.0,
    };

    for (int i = 14; i < 20; i++) {
      final effectType = tasteFeatures[i];
      features[i] = effectMapping[effectType] ?? 0.0;
    }

    // 4. 菜系特征 (20-27)
    for (int i = 20; i < 28; i++) {
      final cuisineType = tasteFeatures[i];
      if (recipe.cuisine == cuisineType) {
        features[i] = 1.0;
      }
    }

    // 5. 类型特征 (28-33)
    final typeMapping = {
      '家常': recipe.tags.contains('家常菜') ? 1.0 : 0.0,
      '宴客': recipe.tags.contains('宴客菜') ? 1.0 : 0.0,
      '快手': recipe.isQuickDish ? 1.0 : 0.0,
      '精致': recipe.difficulty == RecipeDifficulty.hard ? 0.8 : 0.0,
      '素食': recipe.isVegetarian ? 1.0 : 0.0,
      '荤菜': !recipe.isVegetarian ? 1.0 : 0.0,
    };

    for (int i = 28; i < 34; i++) {
      final typeFeature = tasteFeatures[i];
      features[i] = typeMapping[typeFeature] ?? 0.0;
    }

    // 6. 场景特征 (34-39)
    for (int i = 34; i < 40; i++) {
      final sceneType = tasteFeatures[i];
      if (recipe.mealTypes.contains(sceneType) || recipe.scenarioTags.contains(sceneType)) {
        features[i] = 0.8;
      }
    }

    // 7. 时令特征 (40-45)
    for (int i = 40; i < 46; i++) {
      final seasonType = tasteFeatures[i];
      if (recipe.seasonalInfo.bestSeasons.contains(seasonType)) {
        features[i] = recipe.seasonalInfo.seasonalScore;
      } else if (['节日', '日常'].contains(seasonType)) {
        features[i] = seasonType == '日常' ? 0.7 : 0.3;
      }
    }

    final vector = Vector.fromList(features);
    _recipeVectors[recipe.id] = vector;

    return vector;
  }

  /// 将用户偏好转换为口味特征向量
  Vector convertUserPreferenceToVector(
    List<Bubble> selectedBubbles,
    UserPreference userPreference,
  ) {
    final features = List<double>.filled(featureDimension, 0.0);

    // 1. 从选中的气泡提取口味偏好
    for (final bubble in selectedBubbles) {
      final bubbleWeight = _getBubbleWeight(bubble);

      switch (bubble.type) {
        case BubbleType.taste:
          _applyTastePreference(features, bubble.name, bubbleWeight);
          break;
        case BubbleType.cuisine:
          _applyCuisinePreference(features, bubble.name, bubbleWeight);
          break;
        case BubbleType.scenario:
          _applyScenarioPreference(features, bubble.name, bubbleWeight);
          break;
        case BubbleType.ingredient:
          _applyIngredientPreference(features, bubble.name, bubbleWeight);
          break;
        case BubbleType.nutrition:
          // 营养类型的处理（暂时不实现）
          break;
        default:
          break;
      }
    }

    // 2. 从用户历史偏好加权
    for (final taste in userPreference.likedTastes) {
      final index = tasteFeatures.indexOf(taste);
      if (index >= 0) {
        features[index] = (features[index] + 0.6).clamp(0.0, 1.0);
      }
    }

    // 3. 应用负面偏好（降权）
    for (final dislikedFood in userPreference.dislikedFoods) {
      // 根据不喜欢的食物推断口味偏好
      _applyNegativePreference(features, dislikedFood);
    }

    // 4. 标准化向量
    final vector = Vector.fromList(features);
    return _normalizeVector(vector);
  }

  /// 计算菜谱与用户偏好的匹配度
  double calculateTasteMatchScore(
    Recipe recipe,
    List<Bubble> selectedBubbles,
    UserPreference userPreference,
  ) {
    final recipeVector = convertRecipeToVector(recipe);
    final userVector = convertUserPreferenceToVector(selectedBubbles, userPreference);

    // 使用多种相似度算法的加权组合
    final cosineSim = _calculateCosineSimilarity(recipeVector, userVector);
    final euclideanSim = _calculateEuclideanSimilarity(recipeVector, userVector);
    final manhattanSim = _calculateManhattanSimilarity(recipeVector, userVector);

    // 加权计算最终匹配度
    final finalScore = cosineSim * 0.5 + euclideanSim * 0.3 + manhattanSim * 0.2;

    return finalScore.clamp(0.0, 1.0);
  }

  /// 智能推荐菜谱
  Future<List<Recipe>> getIntelligentRecommendations(
    List<Recipe> candidateRecipes,
    List<Bubble> selectedBubbles,
    UserPreference userPreference, {
    int limit = 10,
    double minMatchScore = 0.3,
  }) async {
    if (!_isInitialized) await initialize();

    debugPrint('🎯 开始智能口味匹配推荐...');
    debugPrint('📊 候选菜谱: ${candidateRecipes.length}个, 选中气泡: ${selectedBubbles.length}个');

    final scoredRecipes = <ScoredRecipe>[];

    for (final recipe in candidateRecipes) {
      final matchScore = calculateTasteMatchScore(recipe, selectedBubbles, userPreference);

      if (matchScore >= minMatchScore) {
        scoredRecipes.add(ScoredRecipe(
          recipe: recipe,
          matchScore: matchScore,
          tasteVector: _recipeVectors[recipe.id],
        ));
      }
    }

    // 按匹配度排序
    scoredRecipes.sort((a, b) => b.matchScore.compareTo(a.matchScore));

    // 应用多样性算法，避免推荐结果过于相似
    final diversifiedResults = _applyDiversification(scoredRecipes, limit);

    debugPrint('🎉 智能推荐完成: ${diversifiedResults.length}个菜谱');
    return diversifiedResults.map((sr) => sr.recipe).toList();
  }

  /// 分析用户口味偏好趋势
  TasteAnalysisResult analyzeTastePreference(
    List<Bubble> selectedBubbles,
    UserPreference userPreference,
  ) {
    final userVector = convertUserPreferenceToVector(selectedBubbles, userPreference);

    // 提取主要口味特征
    final dominantTastes = <String, double>{};
    final preferredCuisines = <String, double>{};
    final preferredScenarios = <String, double>{};

    for (int i = 0; i < tasteFeatures.length; i++) {
      final feature = tasteFeatures[i];
      final intensity = userVector[i];

      if (intensity > 0.5) {
        if (i < 8) {
          // 基础口味
          dominantTastes[feature] = intensity;
        } else if (i >= 20 && i < 28) {
          // 菜系
          preferredCuisines[feature] = intensity;
        } else if (i >= 34 && i < 40) {
          // 场景
          preferredScenarios[feature] = intensity;
        }
      }
    }

    return TasteAnalysisResult(
      dominantTastes: dominantTastes,
      preferredCuisines: preferredCuisines,
      preferredScenarios: preferredScenarios,
      tasteVector: userVector,
      diversity: _calculateTasteDiversity(userVector),
      confidence: _calculateConfidence(selectedBubbles, userPreference),
    );
  }

  // 私有方法

  /// 初始化口味特征库
  Future<void> _initializeTasteProfiles() async {
    // 建立基础口味特征库
    final baseProfiles = {
      '甜': TasteProfile(name: '甜', intensity: 1.0, keywords: ['甜', '蜜', '糖', '甘']),
      '酸': TasteProfile(name: '酸', intensity: 1.0, keywords: ['酸', '醋', '柠檬', '山楂']),
      '苦': TasteProfile(name: '苦', intensity: 1.0, keywords: ['苦', '苦瓜', '茶']),
      '辣': TasteProfile(name: '辣', intensity: 1.0, keywords: ['辣', '椒', '姜', '蒜']),
      '咸': TasteProfile(name: '咸', intensity: 1.0, keywords: ['咸', '盐', '酱']),
      '鲜': TasteProfile(name: '鲜', intensity: 1.0, keywords: ['鲜', '海鲜', '蘑菇', '鸡汤']),
      '香': TasteProfile(name: '香', intensity: 1.0, keywords: ['香', '芳', '芬芳']),
      '麻': TasteProfile(name: '麻', intensity: 1.0, keywords: ['麻', '花椒', '胡椒']),
    };

    _tasteProfiles.addAll(baseProfiles);
  }

  /// 获取气泡权重
  double _getBubbleWeight(Bubble bubble) {
    // 根据气泡类型和用户选择强度确定权重
    switch (bubble.type) {
      case BubbleType.taste:
        return 1.0; // 口味类型权重最高
      case BubbleType.cuisine:
        return 0.8;
      case BubbleType.scenario:
        return 0.6;
      case BubbleType.ingredient:
        return 0.5;
      default:
        return 0.4;
    }
  }

  /// 应用口味偏好
  void _applyTastePreference(List<double> features, String tasteName, double weight) {
    final index = tasteFeatures.indexOf(tasteName);
    if (index >= 0 && index < 8) {
      // 基础口味范围
      features[index] = (features[index] + weight).clamp(0.0, 1.0);
    }
  }

  /// 应用菜系偏好
  void _applyCuisinePreference(List<double> features, String cuisineName, double weight) {
    final index = tasteFeatures.indexOf(cuisineName);
    if (index >= 20 && index < 28) {
      // 菜系特征范围
      features[index] = weight;
    }
  }

  /// 应用场景偏好
  void _applyScenarioPreference(List<double> features, String scenarioName, double weight) {
    final scenarioMapping = {
      '下饭': 19, // 下饭功效
      '宵夜': 37, // 夜宵场景
      '聚餐': 39, // 聚餐场景
      '减脂': 14, // 清凉功效
      '暖胃': 14, // 温热功效
    };

    final index = scenarioMapping[scenarioName];
    if (index != null) {
      features[index] = (features[index] + weight * 0.8).clamp(0.0, 1.0);
    }
  }

  /// 应用食材偏好
  void _applyIngredientPreference(List<double> features, String ingredientName, double weight) {
    // 根据食材推断口味偏好
    final ingredientTasteMapping = {
      '肉类': [4, 5], // 咸、鲜
      '海鲜': [5], // 鲜
      '蔬菜': [8], // 清淡
      '豆腐': [5, 8], // 鲜、清淡
      '面条': [4], // 咸
    };

    for (final entry in ingredientTasteMapping.entries) {
      if (ingredientName.contains(entry.key)) {
        for (final index in entry.value) {
          features[index] = (features[index] + weight * 0.6).clamp(0.0, 1.0);
        }
        break;
      }
    }
  }

  /// 应用负面偏好
  void _applyNegativePreference(List<double> features, String dislikedFood) {
    // 根据不喜欢的食物降低相关特征权重
    // 这里可以根据具体的不喜欢食物进行特征调整
  }

  /// 标准化向量
  Vector _normalizeVector(Vector vector) {
    final norm = vector.norm();
    if (norm > 0) {
      return vector / norm;
    }
    return vector;
  }

  /// 计算余弦相似度
  double _calculateCosineSimilarity(Vector v1, Vector v2) {
    final dotProduct = v1.dot(v2);
    final norm1 = v1.norm();
    final norm2 = v2.norm();

    if (norm1 > 0 && norm2 > 0) {
      return dotProduct / (norm1 * norm2);
    }
    return 0.0;
  }

  /// 计算欧氏距离相似度
  double _calculateEuclideanSimilarity(Vector v1, Vector v2) {
    final distance = (v1 - v2).norm();
    // 转换为相似度分数 (0-1)
    return 1.0 / (1.0 + distance);
  }

  /// 计算曼哈顿距离相似度
  double _calculateManhattanSimilarity(Vector v1, Vector v2) {
    double distance = 0.0;
    for (int i = 0; i < v1.length; i++) {
      distance += (v1[i] - v2[i]).abs();
    }
    return 1.0 / (1.0 + distance);
  }

  /// 应用多样性算法
  List<ScoredRecipe> _applyDiversification(List<ScoredRecipe> scoredRecipes, int limit) {
    if (scoredRecipes.length <= limit) return scoredRecipes;

    final diversified = <ScoredRecipe>[];
    final remaining = List<ScoredRecipe>.from(scoredRecipes);

    // 选择最高分的作为第一个
    diversified.add(remaining.removeAt(0));

    while (diversified.length < limit && remaining.isNotEmpty) {
      double maxDiversityScore = -1;
      int bestIndex = 0;

      for (int i = 0; i < remaining.length; i++) {
        final candidate = remaining[i];
        double minSimilarity = 1.0;

        // 计算与已选菜谱的最小相似度
        for (final selected in diversified) {
          if (candidate.tasteVector != null && selected.tasteVector != null) {
            final similarity = _calculateCosineSimilarity(
              candidate.tasteVector!,
              selected.tasteVector!,
            );
            minSimilarity = min(minSimilarity, similarity);
          }
        }

        // 多样性分数 = 匹配度 * (1 - 相似度)
        final diversityScore = candidate.matchScore * (1.0 - minSimilarity);

        if (diversityScore > maxDiversityScore) {
          maxDiversityScore = diversityScore;
          bestIndex = i;
        }
      }

      diversified.add(remaining.removeAt(bestIndex));
    }

    return diversified;
  }

  /// 计算口味多样性
  double _calculateTasteDiversity(Vector tasteVector) {
    int activeDimensions = 0;
    double entropy = 0.0;

    for (int i = 0; i < tasteVector.length; i++) {
      if (tasteVector[i] > 0.1) {
        activeDimensions++;
        entropy += tasteVector[i] * log(tasteVector[i] + 1e-10);
      }
    }

    return activeDimensions / tasteFeatures.length;
  }

  /// 计算偏好置信度
  double _calculateConfidence(List<Bubble> selectedBubbles, UserPreference userPreference) {
    final bubbleConfidence = selectedBubbles.length / 10.0; // 假设10个气泡为满分
    final historyConfidence =
        (userPreference.favoriteFoods.length + userPreference.dislikedFoods.length) /
            20.0; // 假设20个历史记录为满分

    return ((bubbleConfidence + historyConfidence) / 2.0).clamp(0.0, 1.0);
  }
}

/// 口味特征模型
class TasteProfile {
  final String name;
  final double intensity;
  final List<String> keywords;

  TasteProfile({
    required this.name,
    required this.intensity,
    required this.keywords,
  });
}

/// 评分菜谱模型
class ScoredRecipe {
  final Recipe recipe;
  final double matchScore;
  final Vector? tasteVector;

  ScoredRecipe({
    required this.recipe,
    required this.matchScore,
    this.tasteVector,
  });
}

/// 口味分析结果
class TasteAnalysisResult {
  final Map<String, double> dominantTastes;
  final Map<String, double> preferredCuisines;
  final Map<String, double> preferredScenarios;
  final Vector tasteVector;
  final double diversity;
  final double confidence;

  TasteAnalysisResult({
    required this.dominantTastes,
    required this.preferredCuisines,
    required this.preferredScenarios,
    required this.tasteVector,
    required this.diversity,
    required this.confidence,
  });

  @override
  String toString() => 'TasteAnalysis(dominant: $dominantTastes, confidence: $confidence)';
}
