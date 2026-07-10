import 'package:flutter/foundation.dart' show debugPrint;
import '../models/food.dart';
import '../models/user_preference.dart';
import '../models/bubble.dart';
import '../data/food_database.dart';
import '../ai/ai_service.dart';
import 'recommendation_engine.dart';

/// AI增强推荐引擎
/// 结合传统推荐算法和AI大模型智能分析
class EnhancedRecommendationEngine extends RecommendationEngine {
  static final EnhancedRecommendationEngine _instance = EnhancedRecommendationEngine._internal();
  factory EnhancedRecommendationEngine() => _instance;
  EnhancedRecommendationEngine._internal();

  final AiService _aiService = AiService();
  final Map<String, EnhancedRecommendationResult> _resultCache = {};
  DateTime? _lastAnalysis;
  UserPreferenceAnalysis? _cachedAnalysis;

  /// 初始化增强推荐引擎
  @override
  Future<void> initialize() async {
    super.initialize();
    await _aiService.init();
    debugPrint('AI增强推荐引擎初始化完成');
  }

  /// AI增强的气泡推荐
  /// 结合传统算法和AI智能分析
  Future<EnhancedRecommendationResult> getAiEnhancedBubbleRecommendations({
    required List<Bubble> selectedBubbles,
    UserPreference? userPreference,
    String? context,
    int limit = 10,
  }) async {
    try {
      // 1. 获取基础数据
      final allFoods = FoodDatabase.getAllFoods();
      final bubbleNames = selectedBubbles.map((b) => b.name).toList();
      final foodNames = allFoods.map((f) => f.name).toList();

      // 2. 并行执行传统推荐和AI推荐
      final futures = await Future.wait([
        _getTraditionalRecommendations(selectedBubbles, userPreference, limit),
        _getAiRecommendations(bubbleNames, foodNames, userPreference, context),
      ]);

      final traditionalResults = futures[0] as List<Food>;
      final aiResult = futures[1] as AiRecommendationResult;

      // 3. 融合推荐结果
      final fusedResults = _fuseRecommendationResults(
        traditionalResults,
        aiResult,
        allFoods,
        limit,
      );

      // 4. 生成增强解释
      final enhancedExplanations = await _generateEnhancedExplanations(
        fusedResults,
        bubbleNames,
        aiResult,
      );

      // 5. 构建最终结果
      final result = EnhancedRecommendationResult(
        recommendations: fusedResults,
        aiInsights: aiResult,
        explanations: enhancedExplanations,
        traditionalScore: _calculateAverageScore(traditionalResults, userPreference),
        aiScore: aiResult.score,
        fusionScore: _calculateFusionScore(traditionalResults, aiResult, fusedResults),
        selectedBubbles: selectedBubbles,
        timestamp: DateTime.now(),
        recommendationStrategy: _determineStrategy(traditionalResults, aiResult),
      );

      // 6. 缓存结果
      _cacheResult(_buildCacheKey(selectedBubbles), result);

      return result;
    } catch (e) {
      debugPrint('AI增强推荐失败，回退到传统推荐: $e');
      return _getFallbackEnhancedResult(selectedBubbles, userPreference, limit);
    }
  }

  /// 用户偏好智能分析
  Future<UserPreferenceAnalysis> analyzeUserPreferences(UserPreference userPreference) async {
    // 检查缓存
    if (_cachedAnalysis != null && _lastAnalysis != null) {
      final timeDiff = DateTime.now().difference(_lastAnalysis!).inMinutes;
      if (timeDiff < 30) {
        // 30分钟内使用缓存
        return _cachedAnalysis!;
      }
    }

    try {
      final analysis = await _aiService.analyzeUserPreferences(
        favoriteHistory: userPreference.favoriteFoods,
        dislikedHistory: userPreference.dislikedFoods,
        bubbleInteractions: _getBubbleInteractionStats(userPreference),
      );

      _cachedAnalysis = analysis;
      _lastAnalysis = DateTime.now();

      return analysis;
    } catch (e) {
      debugPrint('用户偏好分析失败: $e');
      return _getFallbackAnalysis();
    }
  }

  /// 智能推荐解释生成
  Future<String> generateIntelligentExplanation({
    required Food food,
    required List<String> matchedBubbles,
    required double score,
    String? context,
  }) async {
    try {
      return await _aiService.generateFoodExplanation(
        foodName: food.name,
        matchedBubbles: matchedBubbles,
        score: score,
      );
    } catch (e) {
      debugPrint('智能解释生成失败: $e');
      return _generateFallbackExplanation(food, matchedBubbles, score);
    }
  }

  /// 获取传统推荐结果
  Future<List<Food>> _getTraditionalRecommendations(
    List<Bubble> selectedBubbles,
    UserPreference? userPreference,
    int limit,
  ) async {
    if (userPreference != null) {
      return getPersonalizedRecommendations(userPreference);
    } else {
      return recommendBasedOnBubbles(selectedBubbles);
    }
  }

  /// 获取AI推荐结果
  Future<AiRecommendationResult> _getAiRecommendations(
    List<String> bubbleNames,
    List<String> foodNames,
    UserPreference? userPreference,
    String? context,
  ) async {
    return await _aiService.getBubbleRecommendations(
      selectedBubbles: bubbleNames,
      availableFoods: foodNames,
      userPreferences: userPreference?.toString(),
      timeOfDay: _getCurrentTimeOfDay(),
      weather: context,
    );
  }

  /// 融合推荐结果
  List<Food> _fuseRecommendationResults(
    List<Food> traditionalResults,
    AiRecommendationResult aiResult,
    List<Food> allFoods,
    int limit,
  ) {
    final Set<String> aiRecommendedNames = aiResult.recommendations.toSet();
    final Set<String> traditionalNames = traditionalResults.map((f) => f.name).toSet();

    // 优先选择AI和传统算法都推荐的食物
    final bothRecommended = <Food>[];
    final aiOnly = <Food>[];
    final traditionalOnly = <Food>[];

    for (final food in allFoods) {
      if (aiRecommendedNames.contains(food.name) && traditionalNames.contains(food.name)) {
        bothRecommended.add(food);
      } else if (aiRecommendedNames.contains(food.name)) {
        aiOnly.add(food);
      } else if (traditionalNames.contains(food.name)) {
        traditionalOnly.add(food);
      }
    }

    // 构建最终推荐列表
    final result = <Food>[];

    // 1. 优先添加双重推荐
    result.addAll(bothRecommended.take((limit * 0.4).round()));

    // 2. 添加AI独有推荐
    final remainingSlots = limit - result.length;
    if (remainingSlots > 0) {
      result.addAll(aiOnly.take((remainingSlots * 0.6).round()));
    }

    // 3. 补充传统推荐
    final finalSlots = limit - result.length;
    if (finalSlots > 0) {
      result.addAll(traditionalOnly.take(finalSlots));
    }

    return result.take(limit).toList();
  }

  /// 生成增强解释
  Future<Map<String, String>> _generateEnhancedExplanations(
    List<Food> foods,
    List<String> bubbleNames,
    AiRecommendationResult aiResult,
  ) async {
    final explanations = <String, String>{};

    for (final food in foods) {
      try {
        final explanation = await _aiService.generateFoodExplanation(
          foodName: food.name,
          matchedBubbles: bubbleNames,
          score: food.rating,
        );
        explanations[food.name] = explanation;
      } catch (e) {
        explanations[food.name] = _generateFallbackExplanation(food, bubbleNames, food.rating);
      }
    }

    return explanations;
  }

  /// 计算融合评分
  double _calculateFusionScore(
    List<Food> traditionalResults,
    AiRecommendationResult aiResult,
    List<Food> fusedResults,
  ) {
    final traditionalScore = traditionalResults.isEmpty
        ? 0.0
        : traditionalResults.map((f) => f.rating).reduce((a, b) => a + b) /
            traditionalResults.length;

    final aiScore = aiResult.score;
    final fusionBonus = fusedResults.isNotEmpty ? 1.0 : 0.0;

    return (traditionalScore * 0.4 + aiScore * 0.5 + fusionBonus * 0.1).clamp(0.0, 10.0);
  }

  /// 确定推荐策略
  RecommendationStrategy _determineStrategy(
    List<Food> traditionalResults,
    AiRecommendationResult aiResult,
  ) {
    if (aiResult.score > 8.0 && traditionalResults.length > 2) {
      return RecommendationStrategy.aiFused;
    } else if (aiResult.score > 7.0) {
      return RecommendationStrategy.aiPrimary;
    } else if (traditionalResults.length > 3) {
      return RecommendationStrategy.traditionalPrimary;
    } else {
      return RecommendationStrategy.balanced;
    }
  }

  /// 计算平均评分
  double _calculateAverageScore(List<Food> foods, UserPreference? preference) {
    if (foods.isEmpty) return 0.0;

    double totalScore = 0.0;
    for (final food in foods) {
      totalScore +=
          preference != null ? _calculatePersonalizedScore(food, preference) : food.rating;
    }

    return totalScore / foods.length;
  }

  /// 计算个性化评分
  double _calculatePersonalizedScore(Food food, UserPreference preference) {
    double score = food.rating;

    // 根据用户偏好调整评分
    if (preference.favoriteCuisines.contains(food.cuisineType)) {
      score += 1.0;
    }

    // 根据口味偏好调整
    // 这里可以根据实际需求添加更多逻辑

    return score;
  }

  /// 获取气泡交互统计
  Map<String, int> _getBubbleInteractionStats(UserPreference preference) {
    // 这里可以根据实际的气泡交互历史来统计
    // 暂时返回模拟数据
    return {
      '口味': 10,
      '菜系': 8,
      '食材': 6,
      '营养': 4,
    };
  }

  /// 获取当前时段
  String _getCurrentTimeOfDay() {
    final hour = DateTime.now().hour;
    if (hour < 6) return '深夜';
    if (hour < 9) return '早餐';
    if (hour < 12) return '上午';
    if (hour < 14) return '午餐';
    if (hour < 18) return '下午';
    if (hour < 21) return '晚餐';
    return '夜晚';
  }

  /// 缓存管理
  String _buildCacheKey(List<Bubble> bubbles) {
    return bubbles.map((b) => '${b.name}_${b.type}').join('|');
  }

  void _cacheResult(String key, EnhancedRecommendationResult result) {
    _resultCache[key] = result;
    // 简单的缓存清理
    if (_resultCache.length > 50) {
      final keys = _resultCache.keys.toList();
      for (int i = 0; i < 10; i++) {
        _resultCache.remove(keys[i]);
      }
    }
  }

  /// 备用方法
  EnhancedRecommendationResult _getFallbackEnhancedResult(
    List<Bubble> selectedBubbles,
    UserPreference? userPreference,
    int limit,
  ) {
    final traditionalResults = userPreference != null
        ? recommendBasedOnPreferences(userPreference).take(limit).toList()
        : recommendBasedOnBubbles(selectedBubbles).take(limit).toList();

    return EnhancedRecommendationResult(
      recommendations: traditionalResults,
      aiInsights: _getFallbackAiResult(selectedBubbles),
      explanations: _generateFallbackExplanations(traditionalResults, selectedBubbles),
      traditionalScore: _calculateAverageScore(traditionalResults, userPreference),
      aiScore: 7.0,
      fusionScore: 7.5,
      selectedBubbles: selectedBubbles,
      timestamp: DateTime.now(),
      recommendationStrategy: RecommendationStrategy.traditionalPrimary,
    );
  }

  AiRecommendationResult _getFallbackAiResult(List<Bubble> bubbles) {
    return AiRecommendationResult(
      recommendations: bubbles.take(2).map((b) => b.name).toList(),
      reasons: '基于您的选择为您推荐',
      score: 7.0,
      suggestions: '建议尝试不同搭配',
      matchedBubbles: bubbles.map((b) => b.name).toList(),
      rawResponse: '备用推荐',
      timestamp: DateTime.now(),
    );
  }

  Map<String, String> _generateFallbackExplanations(
    List<Food> foods,
    List<Bubble> bubbles,
  ) {
    final explanations = <String, String>{};
    final bubbleText = bubbles.map((b) => b.name).join('、');

    for (final food in foods) {
      explanations[food.name] = '${food.name}符合您的$bubbleText偏好，是不错的选择';
    }

    return explanations;
  }

  String _generateFallbackExplanation(Food food, List<String> bubbles, double score) {
    final bubbleText = bubbles.isEmpty ? '' : '，符合您的${bubbles.join('、')}偏好';
    return '${food.name}是一道经典美食$bubbleText，推荐指数${score.toStringAsFixed(1)}分';
  }

  UserPreferenceAnalysis _getFallbackAnalysis() {
    return UserPreferenceAnalysis(
      tasteCharacteristics: '偏好均衡口味',
      cuisinePreferences: '中式菜系为主',
      ingredientPreferences: '荤素搭配',
      avoidTypes: '暂无明显偏好',
      weightSuggestions: '建议均衡权重',
      rawResponse: '基础分析',
      timestamp: DateTime.now(),
    );
  }
}

/// 增强推荐结果类
class EnhancedRecommendationResult {
  final List<Food> recommendations;
  final AiRecommendationResult aiInsights;
  final Map<String, String> explanations;
  final double traditionalScore;
  final double aiScore;
  final double fusionScore;
  final List<Bubble> selectedBubbles;
  final DateTime timestamp;
  final RecommendationStrategy recommendationStrategy;

  EnhancedRecommendationResult({
    required this.recommendations,
    required this.aiInsights,
    required this.explanations,
    required this.traditionalScore,
    required this.aiScore,
    required this.fusionScore,
    required this.selectedBubbles,
    required this.timestamp,
    required this.recommendationStrategy,
  });

  /// 获取推荐质量评级
  String get qualityRating {
    if (fusionScore >= 9.0) return '优秀';
    if (fusionScore >= 8.0) return '良好';
    if (fusionScore >= 7.0) return '一般';
    return '待改进';
  }

  /// 获取推荐解释
  String getExplanationFor(String foodName) {
    return explanations[foodName] ?? '为您推荐的美食选择';
  }
}

/// 推荐策略枚举
enum RecommendationStrategy {
  aiFused, // AI融合策略
  aiPrimary, // AI主导策略
  traditionalPrimary, // 传统主导策略
  balanced, // 平衡策略
}
