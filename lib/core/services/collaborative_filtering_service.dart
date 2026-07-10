import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

/// 协同过滤推荐服务
/// 实现基于用户-物品交互矩阵的协同过滤算法
class CollaborativeFilteringService {
  static final CollaborativeFilteringService _instance =
      CollaborativeFilteringService._internal();
  factory CollaborativeFilteringService() => _instance;
  CollaborativeFilteringService._internal();

  // Box 名称
  static const String _boxName = 'collaborative_filtering_box';
  static const String _matrixKey = 'user_item_matrix';

  // 用户-物品交互矩阵（稀疏存储）
  // key: userId, value: Map<recipeId, rating>
  final Map<String, Map<String, double>> _userItemMatrix = {};

  // 用户相似度缓存
  final Map<String, Map<String, double>> _userSimilarityCache = {};

  // 持久化相关
  Box? _box;
  bool _isInitialized = false;
  Timer? _saveTimer;
  int _interactionCount = 0;
  static const int _saveInterval = 10; // 每 N 次交互后保存

  /// 初始化服务
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      _box = await Hive.openBox(_boxName);
      await _loadFromStorage();
      _isInitialized = true;
      debugPrint('✅ CollaborativeFilteringService 初始化完成');
    } catch (e) {
      debugPrint('❌ CollaborativeFilteringService 初始化失败: $e');
    }
  }

  /// 从存储加载数据
  Future<void> _loadFromStorage() async {
    if (_box == null) return;

    try {
      final data = _box!.get(_matrixKey);
      if (data != null) {
        final Map<String, dynamic> matrixData =
            Map<String, dynamic>.from(data as Map);
        _userItemMatrix.clear();
        matrixData.forEach((userId, items) {
          if (items is Map) {
            final itemsMap = Map<String, double>.from(
              items.map((k, v) => MapEntry(k.toString(), (v as num).toDouble())),
            );
            _userItemMatrix[userId] = itemsMap;
          }
        });
        debugPrint('📊 从存储加载了 ${_userItemMatrix.length} 个用户的交互数据');
      }
    } catch (e) {
      debugPrint('❌ 从存储加载交互数据失败: $e');
    }
  }

  /// 保存到存储
  Future<void> _persistToStorage() async {
    if (_box == null) return;

    try {
      final matrixData = _userItemMatrix.map(
        (userId, items) => MapEntry(userId, items),
      );
      await _box!.put(_matrixKey, matrixData);
    } catch (e) {
      debugPrint('❌ 保存交互数据到存储失败: $e');
    }
  }

  /// 定时保存（防止频繁写入）
  void _scheduleSave() {
    _interactionCount++;
    if (_interactionCount >= _saveInterval) {
      _persistToStorage();
      _interactionCount = 0;
    }
  }

  /// 记录用户交互
  /// [userId] 用户ID
  /// [recipeId] 食谱/食物ID
  /// [rating] 评分: 1.0=不喜欢, 2.0=一般, 3.0=喜欢
  Future<void> recordInteraction({
    required String userId,
    required String recipeId,
    required double rating,
  }) async {
    _userItemMatrix[userId] ??= {};
    _userItemMatrix[userId]![recipeId] = rating;

    // 清除相似度缓存
    _userSimilarityCache.clear();

    _scheduleSave();

    debugPrint('📝 记录交互: userId=$userId, recipeId=$recipeId, rating=$rating');
  }

  /// 计算用户相似度（余弦相似度）
  double calculateUserSimilarity(String userId1, String userId2) {
    // 检查缓存
    if (_userSimilarityCache.containsKey(userId1) &&
        _userSimilarityCache[userId1]!.containsKey(userId2)) {
      return _userSimilarityCache[userId1]![userId2]!;
    }

    // 获取两个用户的交互物品
    final items1 = _userItemMatrix[userId1] ?? {};
    final items2 = _userItemMatrix[userId2] ?? {};

    // 找到共同交互的物品
    final commonItems = items1.keys.toSet().intersection(items2.keys.toSet());
    if (commonItems.isEmpty) return 0.0;

    // 计算余弦相似度
    double dotProduct = 0.0;
    double norm1 = 0.0;
    double norm2 = 0.0;

    for (final item in commonItems) {
      dotProduct += items1[item]! * items2[item]!;
    }
    for (final item in items1.values) {
      norm1 += item * item;
    }
    for (final item in items2.values) {
      norm2 += item * item;
    }

    if (norm1 == 0 || norm2 == 0) return 0.0;

    final similarity = dotProduct / (sqrt(norm1) * sqrt(norm2));

    // 缓存结果
    _userSimilarityCache[userId1] ??= {};
    _userSimilarityCache[userId1]![userId2] = similarity;

    return similarity;
  }

  /// 找到相似用户
  List<MapEntry<String, double>> findSimilarUsers(
    String userId, {
    int topN = 20,
  }) {
    final similarities = <String, double>{};

    for (final otherUserId in _userItemMatrix.keys) {
      if (otherUserId == userId) continue;
      similarities[otherUserId] = calculateUserSimilarity(userId, otherUserId);
    }

    final sorted = similarities.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    return sorted.take(topN).toList();
  }

  /// 获取用户交互数量（用于冷启动判断）
  int getUserInteractionCount(String userId) {
    return _userItemMatrix[userId]?.length ?? 0;
  }

  /// 检查是否有足够的交互数据进行协同过滤
  bool hasEnoughDataForCF(String userId, {int minInteractions = 3}) {
    return getUserInteractionCount(userId) >= minInteractions;
  }

  /// 生成协同过滤推荐
  Future<List<String>> recommendForUser(
    String userId, {
    int limit = 10,
    Set<String>? excludeRecipeIds,
  }) async {
    // 1. 找到相似用户
    final similarUsers = findSimilarUsers(userId);

    if (similarUsers.isEmpty) {
      debugPrint('⚠️ 未找到相似用户');
      return [];
    }

    // 2. 收集相似用户喜欢的物品
    final recommendations = <String, double>{};
    for (final userEntry in similarUsers) {
      final similarUserId = userEntry.key;
      final similarity = userEntry.value;

      if (similarity <= 0) continue;

      final items = _userItemMatrix[similarUserId] ?? {};

      for (final entry in items.entries) {
        if (excludeRecipeIds?.contains(entry.key) == true) continue;

        // 只考虑正面评价的物品（rating >= 2.5）
        if (entry.value >= 2.5) {
          final weightedScore = entry.value * similarity;
          recommendations[entry.key] =
              (recommendations[entry.key] ?? 0) + weightedScore;
        }
      }
    }

    // 3. 排序返回
    final sorted = recommendations.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    final result = sorted.take(limit).map((e) => e.key).toList();
    debugPrint('🎯 协同过滤推荐: 生成 ${result.length} 个推荐');

    return result;
  }

  /// 同步保存（立即保存）
  Future<void> saveNow() async {
    await _persistToStorage();
  }

  /// 获取统计信息
  Map<String, dynamic> getStatistics() {
    return {
      'userCount': _userItemMatrix.length,
      'totalInteractions': _userItemMatrix.values
          .fold<int>(0, (sum, items) => sum + items.length),
      'cacheSize': _userSimilarityCache.length,
    };
  }

  /// 清除所有数据
  Future<void> clearAll() async {
    _userItemMatrix.clear();
    _userSimilarityCache.clear();
    await _box?.clear();
  }

  /// 销毁服务
  void dispose() {
    _saveTimer?.cancel();
    _persistToStorage();
  }
}

/// 简单定时器（避免引入dart:async的复杂依赖）
class Timer {
  final Duration duration;
  final VoidCallback callback;
  bool _cancelled = false;

  Timer(this.duration, this.callback) {
    Future.delayed(duration, () {
      if (!_cancelled) {
        callback();
      }
    });
  }

  void cancel() {
    _cancelled = true;
  }
}
