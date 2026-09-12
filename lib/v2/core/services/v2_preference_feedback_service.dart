import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

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

    final entries = _decodeRawTagScores(raw);
    if (entries.migrated) {
      // 旧格式（无时间戳）在首次读取时按"升级当刻的新鲜分数"写回新格式，
      // 把迁移时间点钉死——否则每次读取都会重新打成新鲜时间，永不衰减。
      unawaited(prefs.setString(_keyTagScoresJson, _serialize(entries.map)));
    }
    final now = _now();
    final result = <String, int>{};
    for (final entry in entries.map.entries) {
      final effective = _decayedScore(entry.value, now);
      final rounded = effective.round();
      if (rounded != 0) result[entry.key] = rounded;
    }
    return result;
  }

  /// 偏好分数的半衰期：30 天。一个月前的口味信号权重减半，
  /// 三个月（≈3 个半衰期）后只剩约 1/8，让"最近想吃的"赢过"旧口味"。
  static const double halfLifeDays = 30;

  /// 测试用时钟注入；为 null 时使用系统时间。
  static DateTime Function()? debugClock;

  static DateTime _now() => debugClock?.call() ?? DateTime.now();

  /// 存储格式 v2：{tagId: {"score": <num>, "updatedAt": <毫秒时间戳>}}。
  /// 旧格式（tagId -> int）按升级当刻的新鲜分数解码，并标记 migrated
  /// 让读取方立刻写回新格式，钉住迁移时间点。
  ({Map<String, _TagScoreEntry> map, bool migrated}) _decodeRawTagScores(
    String raw,
  ) {
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map)
        return (map: <String, _TagScoreEntry>{}, migrated: false);
      final result = <String, _TagScoreEntry>{};
      var migrated = false;
      for (final entry in decoded.entries) {
        final key = entry.key.toString();
        final value = entry.value;
        if (value is Map) {
          final score = double.tryParse(value['score']?.toString() ?? '') ?? 0;
          final millis =
              int.tryParse(value['updatedAt']?.toString() ?? '') ?? 0;
          result[key] = _TagScoreEntry(
            score,
            millis > 0 ? DateTime.fromMillisecondsSinceEpoch(millis) : _now(),
          );
        } else {
          final v = value is int ? value : int.tryParse(value.toString()) ?? 0;
          result[key] = _TagScoreEntry(v.toDouble(), _now());
          migrated = true;
        }
      }
      return (map: result, migrated: migrated);
    } catch (_) {
      return (map: <String, _TagScoreEntry>{}, migrated: false);
    }
  }

  String _serialize(Map<String, _TagScoreEntry> entries) {
    return jsonEncode(
      entries.map(
        (key, entry) => MapEntry(key, {
          'score': entry.score,
          'updatedAt': entry.updatedAt.millisecondsSinceEpoch,
        }),
      ),
    );
  }

  double _decayedScore(_TagScoreEntry entry, DateTime now) {
    final elapsedDays = now.difference(entry.updatedAt).inHours / 24.0;
    if (elapsedDays <= 0) return entry.score;
    return entry.score * math.pow(0.5, elapsedDays / halfLifeDays);
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
    final raw = prefs.getString(_keyTagScoresJson);
    final entries = raw == null || raw.trim().isEmpty
        ? <String, _TagScoreEntry>{}
        : _decodeRawTagScores(raw).map;

    final now = _now();
    // 先把被触达的标签折算到当前时刻，再累加 delta——新增量永远以全值入账。
    final current = entries[tagId];
    final decayed = current == null ? 0.0 : _decayedScore(current, now);
    var next = decayed + delta;

    // 简单限幅：避免无限增长
    if (next > 200) next = 200;
    if (next < -200) next = -200;
    entries[tagId] = _TagScoreEntry(next, now);

    // 压实：衰减到近零的条目等价于遗忘，直接移除，避免存储无限膨胀。
    entries.removeWhere(
      (key, entry) => _decayedScore(entry, now).abs() < 0.5,
    );

    await prefs.setString(_keyTagScoresJson, _serialize(entries));
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

/// 一条带时间戳的原始偏好分数（未折算），时间衰减在读取时计算。
class _TagScoreEntry {
  const _TagScoreEntry(this.score, this.updatedAt);

  final double score;
  final DateTime updatedAt;
}
