import 'dart:math';
import 'package:flutter/foundation.dart';

import '../models/user_behavior_models.dart';
import '../../models/recipe.dart';
import '../../services/real_xiachufang_crawler_service.dart';

/// AI偏好学习引擎 - Phase 3 核心AI组件
/// 基于机器学习算法实现用户偏好的智能学习与预测
class AIPreferenceLearningEngine {
  static final AIPreferenceLearningEngine _instance = AIPreferenceLearningEngine._internal();
  factory AIPreferenceLearningEngine() => _instance;
  AIPreferenceLearningEngine._internal();

  // 用户偏好档案存储
  final Map<String, UserPreferenceProfile> _userProfiles = {};

  // 行为数据缓存
  final List<UserBehaviorData> _behaviorCache = [];

  // 学习配置参数
  final AILearningConfig _config = AILearningConfig();

  // 全局统计数据
  final GlobalPreferenceStats _globalStats = GlobalPreferenceStats();

  bool _isInitialized = false;

  /// 初始化AI学习引擎
  Future<void> initialize() async {
    if (_isInitialized) return;

    debugPrint('🤖 初始化AI偏好学习引擎...');

    // 加载历史用户数据
    await _loadUserProfiles();

    // 初始化全局统计
    await _initializeGlobalStats();
    _globalStats.updateStats();

    // 启动后台学习任务
    _startBackgroundLearning();

    _isInitialized = true;
    debugPrint('✅ AI偏好学习引擎初始化完成');
  }

  /// 记录用户行为
  Future<void> recordUserBehavior(UserBehaviorData behavior) async {
    await _ensureInitialized();

    // 添加到缓存
    _behaviorCache.add(behavior);

    // 更新用户档案
    await _updateUserProfile(behavior);

    // 触发实时学习
    if (_behaviorCache.length >= _config.batchLearningSize) {
      await _performBatchLearning();
    }

    debugPrint('📊 记录用户行为: ${behavior.actionType.label}');
  }

  /// 获取用户偏好向量
  PreferenceVector getUserPreferenceVector(String userId) {
    final profile = _userProfiles[userId];
    return profile?.preferenceVector ?? PreferenceVector.defaultVector();
  }

  /// 预测用户对菜谱的偏好分数
  Future<double> predictRecipePreference(String userId, Recipe recipe) async {
    await _ensureInitialized();

    final userVector = getUserPreferenceVector(userId);
    final recipeVector = _extractRecipeFeatureVector(recipe);

    // 计算多维度匹配分数
    final scores = _calculateDimensionScores(userVector, recipeVector);

    // 应用动态权重
    final weightedScore = _applyDynamicWeights(scores, userVector.dimensionWeights);

    // 考虑全局热度和新颖性
    final globalScore = _calculateGlobalScore(recipe);
    final noveltyScore = _calculateNoveltyScore(userId, recipe);

    // 综合评分
    final finalScore = _combineScores({
      'preference': weightedScore,
      'global': globalScore,
      'novelty': noveltyScore,
    });

    return finalScore.clamp(0.0, 1.0);
  }

  /// 智能推荐菜谱
  Future<List<RecipeRecommendation>> getIntelligentRecommendations({
    required String userId,
    int count = 20,
    String? contextHint, // 当前上下文提示
    Map<String, dynamic>? constraints, // 约束条件
  }) async {
    await _ensureInitialized();

    // 获取候选菜谱
    final crawler = RealXiachufangCrawlerService();
    final crawlResult = await crawler.crawlRecipes(
      categories: _getPreferredCategories(userId),
      targetCount: count * 3, // 获取更多候选
    );

    if (!crawlResult.success) {
      return [];
    }

    final candidates = crawler.crawledRecipes;

    // 为每个候选菜谱计算AI预测分数
    final recommendations = <RecipeRecommendation>[];

    for (final recipe in candidates) {
      // 应用约束筛选
      if (!_meetConstraints(recipe, constraints)) continue;

      final preferenceScore = await predictRecipePreference(userId, recipe);
      final contextScore = _calculateContextScore(recipe, contextHint);
      final diversityScore = _calculateDiversityScore(recipe, recommendations);

      // 综合评分
      final finalScore = preferenceScore * 0.6 + contextScore * 0.25 + diversityScore * 0.15;

      final reasons = await _generateAIReasons(userId, recipe, preferenceScore);

      recommendations.add(RecipeRecommendation(
        recipe: recipe,
        score: finalScore,
        reasons: reasons,
      ));
    }

    // 排序并返回
    recommendations.sort((a, b) => b.score.compareTo(a.score));
    return recommendations.take(count).toList();
  }

  /// 学习用户反馈
  Future<void> learnFromFeedback({
    required String userId,
    required String recipeId,
    required FeedbackType feedbackType,
    double? explicitRating,
    String? comment,
  }) async {
    await _ensureInitialized();

    // 创建反馈行为数据
    final behavior = UserBehaviorData(
      userId: userId,
      sessionId: _generateSessionId(),
      timestamp: DateTime.now(),
      actionType: _feedbackToActionType(feedbackType),
      targetId: recipeId,
      targetType: 'recipe',
      actionDetails: {
        'feedbackType': feedbackType.name,
        'explicitRating': explicitRating,
        'comment': comment,
      },
      actionIntensity: _calculateFeedbackIntensity(feedbackType, explicitRating),
    );

    await recordUserBehavior(behavior);

    // 强化学习更新
    await _performReinforcementLearning(userId, recipeId, feedbackType);

    debugPrint('🎯 学习用户反馈: ${feedbackType.name}');
  }

  /// 获取用户偏好分析报告
  Map<String, dynamic> getUserInsights(String userId) {
    final profile = _userProfiles[userId];
    if (profile == null) return {};

    final vector = profile.preferenceVector;
    final topPrefs = vector.getTopPreferences();

    return {
      'userId': userId,
      'profileCreated': profile.createdAt.toIso8601String(),
      'lastActive': profile.lastActiveAt.toIso8601String(),
      'totalInteractions': profile.totalInteractions,
      'activityScore': profile.getActivityScore(),
      'confidenceScore': vector.confidenceScore,
      'topPreferences': topPrefs,
      'behaviorPatterns': _analyzeBehaviorPatterns(profile.recentBehaviors),
      'learningProgress': _calculateLearningProgress(profile),
      'recommendations': {
        'personalizedScore': vector.confidenceScore,
        'diversityPreference': _calculateDiversityPreference(profile),
        'explorationTendency': _calculateExplorationTendency(profile),
      },
    };
  }

  /// 更新偏好权重
  Future<void> updatePreferenceWeights(String userId, Map<String, double> newWeights) async {
    final profile = _userProfiles[userId];
    if (profile == null) return;

    final updatedVector = profile.preferenceVector.updateWith(
      weightUpdate: newWeights,
      newConfidenceScore: profile.preferenceVector.confidenceScore * 0.9, // 手动调整降低置信度
    );

    _userProfiles[userId] = profile.updateProfile(newPreferenceVector: updatedVector);

    await _saveUserProfile(userId);
    debugPrint('⚖️ 更新用户偏好权重');
  }

  // ===== 私有方法 =====

  Future<void> _ensureInitialized() async {
    if (!_isInitialized) await initialize();
  }

  /// 更新用户档案
  Future<void> _updateUserProfile(UserBehaviorData behavior) async {
    final userId = behavior.userId;
    var profile = _userProfiles[userId] ??
        UserPreferenceProfile(
          userId: userId,
          preferenceVector: PreferenceVector.defaultVector(),
        );

    // 基于行为更新偏好向量
    final vectorUpdate = _behaviorToVectorUpdate(behavior);
    final updatedVector = profile.preferenceVector.updateWith(
      tasteUpdate: vectorUpdate['taste'],
      cuisineUpdate: vectorUpdate['cuisine'],
      ingredientUpdate: vectorUpdate['ingredient'],
      scenarioUpdate: vectorUpdate['scenario'],
      nutritionUpdate: vectorUpdate['nutrition'],
      difficultyUpdate: vectorUpdate['difficulty'],
      timeUpdate: vectorUpdate['time'],
      emotionalUpdate: vectorUpdate['emotional'],
      seasonalUpdate: vectorUpdate['seasonal'],
      newConfidenceScore:
          _updateConfidenceScore(profile.preferenceVector.confidenceScore, behavior),
    );

    // 更新档案
    _userProfiles[userId] = profile.updateProfile(
      newPreferenceVector: updatedVector,
      newBehavior: behavior,
    );
  }

  /// 将行为转换为偏好向量更新
  Map<String, Map<String, double>> _behaviorToVectorUpdate(UserBehaviorData behavior) {
    final update = <String, Map<String, double>>{};

    // 基于行为类型确定更新强度
    final intensity = behavior.actionIntensity;
    final isPositive = _isPositiveBehavior(behavior.actionType);
    final updateValue = isPositive ? intensity : -intensity * 0.5;

    // 从行为详情中提取特征
    final details = behavior.actionDetails;

    // 更新各维度偏好
    if (details.containsKey('taste')) {
      update['taste'] = {details['taste'].toString(): updateValue};
    }

    if (details.containsKey('cuisine')) {
      update['cuisine'] = {details['cuisine'].toString(): updateValue};
    }

    if (details.containsKey('ingredients')) {
      final ingredients = details['ingredients'] as List<String>? ?? [];
      update['ingredient'] = {for (final ing in ingredients) ing: updateValue};
    }

    return update;
  }

  /// 提取菜谱特征向量
  Map<String, Map<String, double>> _extractRecipeFeatureVector(Recipe recipe) {
    return {
      'taste': {for (final taste in recipe.tasteProfile) taste: 1.0},
      'cuisine': {recipe.cuisine: 1.0},
      'ingredient': {for (final ing in recipe.ingredients) ing.name: 1.0},
      'scenario': {for (final scenario in recipe.scenarioTags) scenario: 1.0},
      'nutrition': {
        'calories': recipe.nutrition.calories / 1000.0,
        'protein': recipe.nutrition.protein / 50.0,
        'fat': recipe.nutrition.fat / 30.0,
        'carbs': recipe.nutrition.carbs / 100.0,
      },
      'difficulty': {recipe.difficulty.label: 1.0},
      'time': {_timeToCategory(recipe.cookingTime): 1.0},
      'emotional': {for (final benefit in recipe.healthBenefits) benefit: 0.5},
      'seasonal': {for (final season in recipe.seasonalInfo.bestSeasons) season: 1.0},
    };
  }

  /// 计算各维度匹配分数
  Map<String, double> _calculateDimensionScores(
      PreferenceVector userVector, Map<String, Map<String, double>> recipeVector) {
    final scores = <String, double>{};

    final dimensions = [
      ('taste', userVector.tastePreferences),
      ('cuisine', userVector.cuisinePreferences),
      ('ingredient', userVector.ingredientPreferences),
      ('scenario', userVector.scenarioPreferences),
      ('nutrition', userVector.nutritionPreferences),
      ('difficulty', userVector.difficultyPreferences),
      ('time', userVector.timePreferences),
      ('emotional', userVector.emotionalPreferences),
      ('seasonal', userVector.seasonalPreferences),
    ];

    for (final (dimension, userPrefs) in dimensions) {
      final recipeFeatures = recipeVector[dimension] ?? {};
      scores[dimension] = _calculateFeatureMatchScore(userPrefs, recipeFeatures);
    }

    return scores;
  }

  /// 计算特征匹配分数
  double _calculateFeatureMatchScore(
      Map<String, double> userPrefs, Map<String, double> recipeFeatures) {
    if (userPrefs.isEmpty || recipeFeatures.isEmpty) return 0.5;

    double totalScore = 0.0;
    int matchCount = 0;

    for (final entry in recipeFeatures.entries) {
      final feature = entry.key;
      final recipeValue = entry.value;
      final userPref = userPrefs[feature];

      if (userPref != null) {
        totalScore += userPref * recipeValue;
        matchCount++;
      }
    }

    return matchCount > 0 ? totalScore / matchCount : 0.5;
  }

  /// 应用动态权重
  double _applyDynamicWeights(Map<String, double> scores, Map<String, double> weights) {
    double weightedSum = 0.0;
    double totalWeight = 0.0;

    for (final entry in scores.entries) {
      final dimension = entry.key;
      final score = entry.value;
      final weight = weights[dimension] ?? 1.0;

      weightedSum += score * weight;
      totalWeight += weight;
    }

    return totalWeight > 0 ? weightedSum / totalWeight : 0.5;
  }

  /// 计算全局分数
  double _calculateGlobalScore(Recipe recipe) {
    // 基于评分和评论数计算热度
    final ratingScore = recipe.rating / 5.0;
    final popularityScore = (recipe.reviewCount / 1000.0).clamp(0.0, 1.0);

    return ratingScore * 0.7 + popularityScore * 0.3;
  }

  /// 计算新颖性分数
  double _calculateNoveltyScore(String userId, Recipe recipe) {
    final profile = _userProfiles[userId];
    if (profile == null) return 1.0;

    // 检查用户是否接触过相似菜谱
    final viewedCuisines = profile.actionCounts.keys
        .where((key) => key.startsWith('view_'))
        .map((key) => key.substring(5))
        .toSet();

    final isNovelCuisine = !viewedCuisines.contains(recipe.cuisine);
    final isNovelStyle = recipe.cookingMethod.name != 'stirFry'; // 假设炒菜是常见的

    double noveltyScore = 0.5;
    if (isNovelCuisine) noveltyScore += 0.3;
    if (isNovelStyle) noveltyScore += 0.2;

    return noveltyScore.clamp(0.0, 1.0);
  }

  /// 组合多个分数
  double _combineScores(Map<String, double> scores) {
    final weights = {
      'preference': 0.6,
      'global': 0.25,
      'novelty': 0.15,
    };

    double totalScore = 0.0;
    for (final entry in scores.entries) {
      final score = entry.value;
      final weight = weights[entry.key] ?? 0.0;
      totalScore += score * weight;
    }

    return totalScore;
  }

  /// 生成AI推荐理由
  Future<List<String>> _generateAIReasons(
      String userId, Recipe recipe, double preferenceScore) async {
    final reasons = <String>[];
    final vector = getUserPreferenceVector(userId);

    // 分析匹配的偏好维度
    if (preferenceScore > 0.8) {
      reasons.add('🎯 高度符合您的个人偏好');
    }

    // 检查口味匹配
    for (final taste in recipe.tasteProfile) {
      final userPref = vector.tastePreferences[taste];
      if (userPref != null && userPref > 0.7) {
        reasons.add('👅 符合您对${taste}口味的偏好');
        break;
      }
    }

    // 检查菜系偏好
    final cuisinePref = vector.cuisinePreferences[recipe.cuisine];
    if (cuisinePref != null && cuisinePref > 0.6) {
      reasons.add('🍽️ 推荐您喜欢的${recipe.cuisine}');
    }

    // 检查营养偏好
    if (recipe.nutrition.protein > 20 && vector.nutritionPreferences['高蛋白'] != null) {
      reasons.add('💪 富含蛋白质，符合您的营养需求');
    }

    // 检查场景匹配
    for (final scenario in recipe.scenarioTags) {
      final scenarioPref = vector.scenarioPreferences[scenario];
      if (scenarioPref != null && scenarioPref > 0.6) {
        reasons.add('🎭 适合${scenario}场景');
        break;
      }
    }

    // AI个性化理由
    if (vector.confidenceScore > 0.7) {
      reasons.add('🤖 基于AI深度学习您的偏好推荐');
    }

    return reasons.take(3).toList();
  }

  // 辅助方法
  bool _isPositiveBehavior(UserActionType actionType) {
    return [
      UserActionType.like,
      UserActionType.favorite,
      UserActionType.cook,
      UserActionType.share,
      UserActionType.accept,
    ].contains(actionType);
  }

  String _timeToCategory(int minutes) {
    if (minutes <= 15) return '快手';
    if (minutes <= 30) return '简单';
    if (minutes <= 60) return '中等';
    return '复杂';
  }

  double _updateConfidenceScore(double currentScore, UserBehaviorData behavior) {
    final increment = behavior.actionIntensity * 0.01;
    return (currentScore + increment).clamp(0.0, 1.0);
  }

  UserActionType _feedbackToActionType(FeedbackType feedbackType) {
    switch (feedbackType) {
      case FeedbackType.like:
        return UserActionType.like;
      case FeedbackType.dislike:
        return UserActionType.dislike;
      case FeedbackType.love:
        return UserActionType.favorite;
      case FeedbackType.neutral:
        return UserActionType.view;
    }
  }

  double _calculateFeedbackIntensity(FeedbackType feedbackType, double? explicitRating) {
    if (explicitRating != null) return explicitRating / 5.0;

    switch (feedbackType) {
      case FeedbackType.love:
        return 1.0;
      case FeedbackType.like:
        return 0.8;
      case FeedbackType.neutral:
        return 0.5;
      case FeedbackType.dislike:
        return 0.2;
    }
  }

  // 占位实现的方法
  Future<void> _loadUserProfiles() async {
    // TODO: 从本地存储加载用户档案
  }

  Future<void> _initializeGlobalStats() async {
    // TODO: 初始化全局统计数据
  }

  void _startBackgroundLearning() {
    // TODO: 启动后台学习任务
  }

  Future<void> _performBatchLearning() async {
    // TODO: 执行批量学习
    _behaviorCache.clear();
  }

  List<String> _getPreferredCategories(String userId) {
    final vector = getUserPreferenceVector(userId);
    final topCuisines = vector.cuisinePreferences.entries
        .where((e) => e.value > 0.5)
        .map((e) => e.key)
        .take(5)
        .toList();

    return topCuisines.isNotEmpty ? topCuisines : ['家常菜', '川菜', '粤菜'];
  }

  bool _meetConstraints(Recipe recipe, Map<String, dynamic>? constraints) {
    if (constraints == null) return true;

    // 实现约束检查逻辑
    return true;
  }

  double _calculateContextScore(Recipe recipe, String? contextHint) {
    if (contextHint == null) return 0.5;

    // 基于上下文提示计算分数
    return 0.5;
  }

  double _calculateDiversityScore(Recipe recipe, List<RecipeRecommendation> existing) {
    // 计算多样性分数，避免推荐过于相似的菜谱
    return 0.5;
  }

  Future<void> _performReinforcementLearning(
      String userId, String recipeId, FeedbackType feedbackType) async {
    // TODO: 实现强化学习逻辑
  }

  Map<String, dynamic> _analyzeBehaviorPatterns(List<UserBehaviorData> behaviors) {
    // TODO: 分析用户行为模式
    return {};
  }

  double _calculateLearningProgress(UserPreferenceProfile profile) {
    return profile.preferenceVector.confidenceScore;
  }

  double _calculateDiversityPreference(UserPreferenceProfile profile) {
    // 分析用户对多样性的偏好
    return 0.5;
  }

  double _calculateExplorationTendency(UserPreferenceProfile profile) {
    // 分析用户的探索倾向
    return 0.5;
  }

  String _generateSessionId() {
    return 'session_${DateTime.now().millisecondsSinceEpoch}_${Random().nextInt(10000)}';
  }

  Future<void> _saveUserProfile(String userId) async {
    // TODO: 保存用户档案到本地存储
  }
}

/// AI学习配置
class AILearningConfig {
  final int batchLearningSize;
  final double learningRate;
  final double decayRate;
  final int maxBehaviorHistory;

  AILearningConfig({
    this.batchLearningSize = 10,
    this.learningRate = 0.1,
    this.decayRate = 0.95,
    this.maxBehaviorHistory = 1000,
  });
}

/// 全局偏好统计
class GlobalPreferenceStats {
  final Map<String, int> popularCuisines = {};
  final Map<String, int> popularIngredients = {};
  final Map<String, int> popularTastes = {};

  void updateStats() {
    // TODO: 更新全局统计
  }
}

/// 反馈类型
enum FeedbackType {
  like('喜欢'),
  dislike('不喜欢'),
  love('超爱'),
  neutral('一般');

  const FeedbackType(this.label);
  final String label;
}

/// 推荐结果
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
