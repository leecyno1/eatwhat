import 'dart:convert';

import 'package:eatwhat_app/v2/core/external/platform/platform_types.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// V2 偏好反馈（轻量学习）
///
/// 用途：
/// - 记录 tag 的正/负反馈，用于后续气泡采样与本地推荐加权。
/// - 记录最近选择过的菜品，用于“避免重复”。
class V2PreferenceFeedbackService {
  V2PreferenceFeedbackService._internal();
  static final V2PreferenceFeedbackService instance =
      V2PreferenceFeedbackService._internal();

  static const _keyTagScoresJson = 'v2_tag_scores_json';
  static const _keyExecutionPathScoresJson = 'v2_execution_path_scores_json';
  static const _keyRecentRecipeIds = 'v2_recent_recipe_ids';
  static const _blockedFeedbackSignals = {
    'HowToCook',
    'AI',
    '美团外卖',
    '饿了么',
    '大众点评',
    'Apple 地图',
  };
  static const _learnableTasteLabels = {
    '家常',
    '热菜',
    '凉菜',
    '快手',
    '下饭',
    '夜宵',
    '聚餐',
    '早餐',
    '午餐',
    '晚餐',
    '素食',
    '清真',
    '辣',
    '麻辣',
    '香辣',
    '微辣',
    '鲜',
    '鲜香',
    '清淡',
    '酸甜',
    '甜',
    '咸',
    '香',
    '汤',
    '锅',
    '火锅',
    '面食',
    '凉面',
    '米饭',
    '粉面',
    '牛肉',
    '鸡肉',
    '猪肉',
    '鱼',
    '虾',
    '海鲜',
    '蔬菜',
    '豆腐',
    '高蛋白',
    '川菜',
    '粤菜',
    '湘菜',
    '日料',
    '西餐',
  };

  Future<Map<String, int>> getTagScores() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyTagScoresJson);
    if (raw == null || raw.trim().isEmpty) return {};

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return {};
      return decoded.map((key, value) {
        final v = value is int ? value : int.tryParse(value.toString()) ?? 0;
        return MapEntry(key.toString(), v);
      });
    } catch (_) {
      return {};
    }
  }

  Future<int> getTagScore(String tagId) async {
    final scores = await getTagScores();
    return scores[tagId] ?? 0;
  }

  Future<void> recordPositiveTag(String tagId, {int delta = 1}) async {
    await _bumpTagScore(tagId, delta.abs());
  }

  Future<void> recordNegativeTag(String tagId, {int delta = 1}) async {
    await _bumpTagScore(tagId, -delta.abs());
  }

  Future<void> _bumpTagScore(String tagId, int delta) async {
    final prefs = await SharedPreferences.getInstance();
    final scores = await getTagScores();

    final next = Map<String, int>.from(scores);
    next[tagId] = (next[tagId] ?? 0) + delta;

    // 简单限幅：避免无限增长
    if (next[tagId]! > 200) next[tagId] = 200;
    if (next[tagId]! < -200) next[tagId] = -200;

    await prefs.setString(_keyTagScoresJson, jsonEncode(next));
  }

  Future<Map<String, int>> getExecutionPathScores() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyExecutionPathScoresJson);
    if (raw == null || raw.trim().isEmpty) return {};

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return {};
      return decoded.map((key, value) {
        final v = value is int ? value : int.tryParse(value.toString()) ?? 0;
        return MapEntry(key.toString(), v);
      });
    } catch (_) {
      return {};
    }
  }

  Future<int> getExecutionPathScore(ExecutionPath path) async {
    final scores = await getExecutionPathScores();
    return scores[path.name] ?? 0;
  }

  Future<ExecutionPath> getPreferredExecutionPath() async {
    final scores = await getExecutionPathScores();
    final candidates = [
      ExecutionPath.cook,
      ExecutionPath.delivery,
      ExecutionPath.dineIn,
    ];

    ExecutionPath preferred = ExecutionPath.any;
    var bestScore = 0;
    for (final path in candidates) {
      final score = scores[path.name] ?? 0;
      if (score > bestScore) {
        preferred = path;
        bestScore = score;
      }
    }
    return preferred;
  }

  Future<void> recordExecutionPathChosen(
    ExecutionPath path, {
    int delta = 1,
  }) async {
    if (path == ExecutionPath.any) return;
    final prefs = await SharedPreferences.getInstance();
    final scores = await getExecutionPathScores();
    final next = Map<String, int>.from(scores);
    next[path.name] = (next[path.name] ?? 0) + delta.abs();
    if (next[path.name]! > 200) next[path.name] = 200;
    await prefs.setString(_keyExecutionPathScoresJson, jsonEncode(next));
  }

  Future<void> recordExecutionCompleted({
    required String recipeId,
    required ExecutionPath path,
    List<String> positiveTagIds = const [],
  }) async {
    final operations = <Future<void>>[
      recordRecipeChosen(recipeId),
      recordExecutionPathChosen(path, delta: 2),
      for (final tagId in positiveTagIds)
        if (_isLearnableTasteSignal(tagId))
          recordPositiveTag(tagId.trim(), delta: 2),
    ];
    await Future.wait(operations);
  }

  bool _isLearnableTasteSignal(String raw) {
    final value = raw.trim();
    if (value.isEmpty) return false;
    if (_blockedFeedbackSignals.contains(value)) return false;
    if (value.contains('地图') || value.contains('外卖')) return false;
    if (value.startsWith('db_')) return true;
    if (value.startsWith('f_') ||
        value.startsWith('i_') ||
        value.startsWith('s_') ||
        value.startsWith('c_') ||
        value.startsWith('scene_')) {
      return true;
    }
    return _learnableTasteLabels.contains(value);
  }

  Future<List<String>> getRecentRecipeIds({int limit = 30}) async {
    final prefs = await SharedPreferences.getInstance();
    final list = prefs.getStringList(_keyRecentRecipeIds) ?? const [];
    if (list.length <= limit) return list;
    return list.take(limit).toList();
  }

  Future<void> recordRecipeChosen(String recipeId, {int limit = 30}) async {
    final prefs = await SharedPreferences.getInstance();
    final current = (prefs.getStringList(_keyRecentRecipeIds) ?? const [])
        .where((e) => e.trim().isNotEmpty)
        .toList();

    final next = <String>[recipeId, ...current.where((e) => e != recipeId)];
    if (next.length > limit) next.removeRange(limit, next.length);
    await prefs.setStringList(_keyRecentRecipeIds, next);
  }
}
