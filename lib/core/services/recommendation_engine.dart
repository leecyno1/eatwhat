import 'dart:math' as math;
import 'dart:collection';
import 'package:flutter/foundation.dart';
import '../models/food.dart';
import '../models/user_preference.dart';
import '../data/food_database.dart';
import '../models/bubble.dart';

/// 推荐引擎（增强版 - 可配置权重 + 多样性 + 详细打分）
class RecommendationEngine {
  static final math.Random _random = math.Random();

  // 缓存: key -> 列表
  final Map<String, List<ScoredFood>> _recommendationCache = LinkedHashMap();
  static const int _maxCacheEntries = 50;

  // 默认权重（可被 RecommendationConfig 覆盖）
  static const double _wHistory = 0.40; // 历史行为 (收藏/不喜欢)
  static const double _wCuisine = 0.20; // 菜系偏好
  static const double _wTaste = 0.20; // 口味偏好 + 语义相似度
  static const double _wBubble = 0.10; // 气泡交互权重
  static const double _wQuality = 0.07; // 食物质量 (rating)
  static const double _wNovelty = 0.03; // 新颖度 (鼓励探索)

  // 多样性相关 (MMR)
  static const double _diversityLambda = 0.30; // λ 越大多样性越强

  void initialize() {}

  // 旧接口兼容: 仅返回 Food 列表
  Future<List<Food>> getPersonalizedRecommendations(UserPreference userPreference,
      {int limit = 10, RecommendationConfig? config}) async {
    final scored = getPersonalizedScoredRecommendations(
      userPreference,
      limit: limit,
      config: config,
    );
    return scored.map((e) => e.food).toList();
  }

  // 新接口: 返回带详细打分的推荐结果
  List<ScoredFood> getPersonalizedScoredRecommendations(
    UserPreference userPreference, {
    int limit = 10,
    RecommendationConfig? config,
    bool ensureDiversity = true,
  }) {
    final cfg = config ?? const RecommendationConfig();
    final cacheKey = _buildCacheKey(userPreference, limit, cfg, ensureDiversity);
    if (_recommendationCache.containsKey(cacheKey)) {
      debugPrint('🔁 使用推荐缓存: key=$cacheKey');
      return _recommendationCache[cacheKey]!;
    }

    final allFoods = FoodDatabase.getAllFoods();
    final List<ScoredFood> scoredFoods = [];
    for (final food in allFoods) {
      final breakdown = _calculatePersonalizedScoreBreakdown(food, userPreference, cfg);
      final total = breakdown.totalScore;
      // 不过滤负向或零分，保留用于测试场景对比（例如不喜欢惩罚后应分数下降）
      scoredFoods.add(ScoredFood(
        food: food,
        score: total,
        reason: 'Personalized recommendation',
        scoreBreakdown: breakdown.toMap(),
      ));
    }

    scoredFoods.sort((a, b) => b.score.compareTo(a.score));
    final diversified =
        ensureDiversity ? _applyMMRDiversity(scoredFoods, limit) : scoredFoods.take(limit).toList();

    _cacheResult(cacheKey, diversified);
    return diversified;
  }

  // 基础推荐（随机抽样）
  List<Food> getBasicRecommendations({int limit = 10}) {
    final allFoods = FoodDatabase.getAllFoods();
    final shuffled = List<Food>.from(allFoods)..shuffle(_random);
    return shuffled.take(limit).toList();
  }

  // 基于菜系获取推荐
  List<Food> getRecommendationsByCuisine(String cuisineType, {int limit = 10}) {
    final allFoods = FoodDatabase.getAllFoods();
    final filteredFoods = allFoods.where((food) => food.cuisineType == cuisineType).toList();
    if (filteredFoods.length <= limit) return filteredFoods;
    filteredFoods.shuffle(_random);
    return filteredFoods.take(limit).toList();
  }

  // 基于口味获取推荐（简单匹配）
  List<Food> getRecommendationsByTaste(List<String> tastes, {int limit = 10}) {
    final allFoods = FoodDatabase.getAllFoods();
    final scoredFoods = <ScoredFood>[];
    for (final food in allFoods) {
      double score = 0.0;
      for (final taste in tastes) {
        if ((food.tasteAttributes ?? const []).contains(taste)) score += 1.0;
      }
      if (score > 0) {
        scoredFoods.add(ScoredFood(
          food: food,
          score: score,
          reason: 'Taste match',
          scoreBreakdown: {'tasteMatch': score},
        ));
      }
    }
    scoredFoods.sort((a, b) => b.score.compareTo(a.score));
    return scoredFoods.take(limit).map((sf) => sf.food).toList();
  }

  // 新版：计算个性化评分各组件
  _ScoreBreakdown _calculatePersonalizedScoreBreakdown(
    Food food,
    UserPreference pref,
    RecommendationConfig cfg,
  ) {
    double history = 0.0;
    if (pref.favoriteFoods.contains(food.name)) history += 1.0; // 0~1
    if (pref.dislikedFoods.contains(food.name)) history -= 1.2; // 惩罚

    double cuisine = 0.0;
    if (food.cuisineType != null) {
      cuisine = (pref.cuisinePreferences[food.cuisineType] ?? 0) / 10.0; // -1~1
    }

    double taste = 0.0;
    final tastes = food.tasteAttributes ?? const [];
    for (final t in tastes) {
      final base = (pref.tastePreferences[t] ?? 0) / 10.0; // -1~1
      final semantic = _calculateTasteSimilarity(t, pref.likedTastes) * 0.6; // 0~0.6
      taste += base * 0.7 + semantic * 0.3;
    }
    if (tastes.isNotEmpty) taste /= tastes.length;

    double bubble = 0.0;
    for (final t in tastes) {
      bubble += pref.getBubblePreference(t) / 10.0; // -1~1
    }
    if (tastes.isNotEmpty) bubble /= tastes.length;

    final quality = (food.rating / 5.0).clamp(0.0, 1.0);

    double novelty = 0.0;
    if (!pref.favoriteFoods.contains(food.name) && !pref.dislikedFoods.contains(food.name)) {
      final cuisineAbs = food.cuisineType == null
          ? 0.0
          : (pref.cuisinePreferences[food.cuisineType] ?? 0).abs() / 10.0;
      novelty = (1.0 - cuisineAbs).clamp(0.0, 1.0);
    }

    double total = 0.0;
    total += history * cfg.weightHistory;
    total += cuisine * cfg.weightCuisine;
    total += taste * cfg.weightTaste;
    total += bubble * cfg.weightBubble;
    total += quality * cfg.weightQuality;
    total += novelty * cfg.weightNovelty;

    return _ScoreBreakdown(
      history: history,
      cuisine: cuisine,
      taste: taste,
      bubble: bubble,
      quality: quality,
      novelty: novelty,
      totalScore: total,
    );
  }

  double _calculateTasteSimilarity(String taste, List<String> likedTastes) {
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
    for (final liked in likedTastes) {
      if (taste == liked) {
        similarity += 1.0;
      } else {
        final similar = similarityMap[liked] ?? [];
        if (similar.contains(taste)) similarity += 0.6;
      }
    }
    return similarity;
  }

  // 计算食物分数（旧接口兼容）
  double _calculateFoodScore(Food food, UserPreference pref) {
    return _calculatePersonalizedScoreBreakdown(food, pref, const RecommendationConfig())
        .totalScore;
  }

  // 获取推荐（兼容方法）
  Future<List<Food>> getRecommendations({
    required List<Food> availableFoods,
    required int count,
    UserPreference? userPreference,
  }) async {
    if (userPreference != null) {
      final scoredFoods = <ScoredFood>[];
      for (final food in availableFoods) {
        final score = _calculateFoodScore(food, userPreference);
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
    }
    final shuffled = List<Food>.from(availableFoods)..shuffle(_random);
    return shuffled.take(count).toList();
  }

  // 根据用户偏好推荐食物（旧接口，返回 Food 列表）
  List<Food> recommendBasedOnPreferences(UserPreference preference) {
    final allFoods = FoodDatabase.getAllFoods();
    final scoredFoods =
        allFoods.map((food) => MapEntry(food, _calculateFoodScore(food, preference))).toList();
    scoredFoods.sort((a, b) => b.value.compareTo(a.value));
    return scoredFoods.take(10).map((e) => e.key).toList();
  }

  // 根据选中的气泡推荐食物（简单匹配 + 排序）
  List<Food> recommendBasedOnBubbles(List<Bubble> selectedBubbles) {
    if (selectedBubbles.isEmpty) return [];
    final allFoods = FoodDatabase.getAllFoods();
    final selectedTastes = selectedBubbles.map((b) => b.name).toSet();
    final matchedFoods = allFoods.where((food) {
      return (food.tasteAttributes ?? const []).any((t) => selectedTastes.contains(t)) ||
          food.cuisineType == selectedBubbles.first.name ||
          food.name.contains(selectedBubbles.first.name);
    }).toList();
    matchedFoods.sort((a, b) {
      final aMatches =
          (a.tasteAttributes ?? const []).where((t) => selectedTastes.contains(t)).length;
      final bMatches =
          (b.tasteAttributes ?? const []).where((t) => selectedTastes.contains(t)).length;
      return bMatches.compareTo(aMatches);
    });
    return matchedFoods.take(10).toList();
  }

  // 获取热门推荐（评分 * 评价数量 排序）
  List<Food> getPopularRecommendations() {
    final allFoods = FoodDatabase.getAllFoods();
    final popularFoods = allFoods.where((f) => f.rating > 4.0).toList();
    popularFoods.sort((a, b) {
      final aScore = a.rating * ((a.ratingCount ?? 0) + 1);
      final bScore = b.rating * ((b.ratingCount ?? 0) + 1);
      return bScore.compareTo(aScore);
    });
    return popularFoods.take(10).toList();
  }

  // ---------- 多样性 & 相似度 ----------
  List<ScoredFood> _applyMMRDiversity(List<ScoredFood> ranked, int limit) {
    if (ranked.length <= 2) return ranked.take(limit).toList();
    final selected = <ScoredFood>[];
    final candidates = List<ScoredFood>.from(ranked);
    while (selected.length < limit && candidates.isNotEmpty) {
      ScoredFood? best;
      double bestMMR = -1e9;
      for (final c in candidates) {
        double diversityPenalty = 0.0;
        for (final s in selected) {
          diversityPenalty = math.max(diversityPenalty, _foodSimilarity(c.food, s.food));
        }
        final mmr =
            (1 - _diversityLambda) * c.score - _diversityLambda * diversityPenalty * c.score;
        if (mmr > bestMMR) {
          bestMMR = mmr;
          best = c;
        }
      }
      if (best == null) break;
      selected.add(best);
      candidates.remove(best);
    }
    return selected;
  }

  double _foodSimilarity(Food a, Food b) {
    double sim = 0.0;
    if (a.cuisineType != null && a.cuisineType == b.cuisineType) sim += 0.4;
    final at = a.tasteAttributes ?? const [];
    final bt = b.tasteAttributes ?? const [];
    if (at.isNotEmpty && bt.isNotEmpty) {
      final inter = at.toSet().intersection(bt.toSet()).length;
      final union = at.toSet().union(bt.toSet()).length;
      if (union > 0) sim += 0.6 * (inter / union);
    }
    return sim.clamp(0.0, 1.0);
  }

  // ---------- 缓存 ----------
  String _buildCacheKey(UserPreference pref, int limit, RecommendationConfig cfg, bool diversity) {
    return '${pref.id}|$limit|${cfg.weightHistory},${cfg.weightCuisine},${cfg.weightTaste},${cfg.weightBubble},${cfg.weightQuality},${cfg.weightNovelty}|$diversity|${pref.lastUpdated.millisecondsSinceEpoch}';
  }

  void _cacheResult(String key, List<ScoredFood> value) {
    _recommendationCache[key] = value;
    if (_recommendationCache.length > _maxCacheEntries) {
      _recommendationCache.remove(_recommendationCache.keys.first);
    }
    debugPrint('✅ 缓存推荐结果: key=$key, size=${value.length}');
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

/// 推荐配置 - 控制权重
class RecommendationConfig {
  final double weightHistory;
  final double weightCuisine;
  final double weightTaste;
  final double weightBubble;
  final double weightQuality;
  final double weightNovelty;
  const RecommendationConfig({
    this.weightHistory = RecommendationEngine._wHistory,
    this.weightCuisine = RecommendationEngine._wCuisine,
    this.weightTaste = RecommendationEngine._wTaste,
    this.weightBubble = RecommendationEngine._wBubble,
    this.weightQuality = RecommendationEngine._wQuality,
    this.weightNovelty = RecommendationEngine._wNovelty,
  });
}

/// 分数明细
class _ScoreBreakdown {
  final double history;
  final double cuisine;
  final double taste;
  final double bubble;
  final double quality;
  final double novelty;
  final double totalScore;
  _ScoreBreakdown({
    required this.history,
    required this.cuisine,
    required this.taste,
    required this.bubble,
    required this.quality,
    required this.novelty,
    required this.totalScore,
  });
  Map<String, double> toMap() => {
        'history': history,
        'cuisine': cuisine,
        'taste': taste,
        'bubble': bubble,
        'quality': quality,
        'novelty': novelty,
        'total': totalScore,
      };
}
