import 'package:flutter/foundation.dart';
import 'dart:math' as math;

/// 用户偏好评分模型
class UserPreferenceScore {
  final String entityId;
  final String entityName;
  final double score;
  final int likeCount;
  final int dislikeCount;
  final DateTime lastUpdated;
  final DateTime firstEncountered;

  const UserPreferenceScore({
    required this.entityId,
    required this.entityName,
    required this.score,
    required this.likeCount,
    required this.dislikeCount,
    required this.lastUpdated,
    required this.firstEncountered,
  });

  /// 默认分数（中性）
  static const double defaultScore = 0.0;
  static const double maxScore = 100.0;
  static const double minScore = -100.0;

  /// 创建新的偏好记录
  factory UserPreferenceScore.create(String entityId, String entityName) {
    final now = DateTime.now();
    return UserPreferenceScore(
      entityId: entityId,
      entityName: entityName,
      score: defaultScore,
      likeCount: 0,
      dislikeCount: 0,
      lastUpdated: now,
      firstEncountered: now,
    );
  }

  /// 点赞操作
  UserPreferenceScore like() {
    final newScore = (score + 10.0).clamp(minScore, maxScore);
    return copyWith(
      score: newScore,
      likeCount: likeCount + 1,
      lastUpdated: DateTime.now(),
    );
  }

  /// 点踩操作
  UserPreferenceScore dislike() {
    final newScore = (score - 15.0).clamp(minScore, maxScore);
    return copyWith(
      score: newScore,
      dislikeCount: dislikeCount + 1,
      lastUpdated: DateTime.now(),
    );
  }

  /// 选择操作（较温和的正向反馈）
  UserPreferenceScore select() {
    final newScore = (score + 5.0).clamp(minScore, maxScore);
    return copyWith(
      score: newScore,
      lastUpdated: DateTime.now(),
    );
  }

  /// 忽略操作（轻微负向反馈）
  UserPreferenceScore ignore() {
    final newScore = (score - 2.0).clamp(minScore, maxScore);
    return copyWith(
      score: newScore,
      lastUpdated: DateTime.now(),
    );
  }

  /// 向下滑动删除（明确的负向反馈）
  UserPreferenceScore swipeDown() {
    final newScore = (score - 8.0).clamp(minScore, maxScore);
    return copyWith(
      score: newScore,
      dislikeCount: dislikeCount + 1,
      lastUpdated: DateTime.now(),
    );
  }

  /// 计算基于分数的气泡半径
  double calculateRadius({
    double baseRadius = 34.0,
    double minRadius = 20.0,
    double maxRadius = 50.0,
  }) {
    // 将分数标准化到0-1之间
    final normalizedScore = (score - minScore) / (maxScore - minScore);
    
    // 使用S曲线让变化更明显
    final curvedScore = _sigmoid(normalizedScore * 6 - 3);
    
    // 映射到半径范围
    return minRadius + (maxRadius - minRadius) * curvedScore;
  }

  /// 计算基于分数的出现概率权重
  double calculateProbabilityWeight() {
    // 负分数降低出现概率，正分数提高出现概率
    final normalizedScore = (score + 20.0) / 120.0; // 将-100到100映射到约0.17到1.17
    return (normalizedScore * normalizedScore).clamp(0.05, 2.0); // 最低5%，最高200%
  }

  /// S形曲线函数，让变化更自然
  double _sigmoid(double x) {
    return 1.0 / (1.0 + math.exp(-x));
  }

  /// 获取用户偏好程度描述
  String getPreferenceLevel() {
    if (score >= 50) return '非常喜欢';
    if (score >= 20) return '比较喜欢';
    if (score >= 5) return '稍微喜欢';
    if (score >= -5) return '中性';
    if (score >= -20) return '不太喜欢';
    if (score >= -50) return '比较讨厌';
    return '非常讨厌';
  }

  /// 复制并修改
  UserPreferenceScore copyWith({
    String? entityId,
    String? entityName,
    double? score,
    int? likeCount,
    int? dislikeCount,
    DateTime? lastUpdated,
    DateTime? firstEncountered,
  }) {
    return UserPreferenceScore(
      entityId: entityId ?? this.entityId,
      entityName: entityName ?? this.entityName,
      score: score ?? this.score,
      likeCount: likeCount ?? this.likeCount,
      dislikeCount: dislikeCount ?? this.dislikeCount,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      firstEncountered: firstEncountered ?? this.firstEncountered,
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'entityId': entityId,
      'entityName': entityName,
      'score': score,
      'likeCount': likeCount,
      'dislikeCount': dislikeCount,
      'lastUpdated': lastUpdated.toIso8601String(),
      'firstEncountered': firstEncountered.toIso8601String(),
    };
  }

  /// 从JSON创建
  factory UserPreferenceScore.fromJson(Map<String, dynamic> json) {
    return UserPreferenceScore(
      entityId: json['entityId'] as String,
      entityName: json['entityName'] as String,
      score: (json['score'] as num).toDouble(),
      likeCount: json['likeCount'] as int,
      dislikeCount: json['dislikeCount'] as int,
      lastUpdated: DateTime.parse(json['lastUpdated'] as String),
      firstEncountered: DateTime.parse(json['firstEncountered'] as String),
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is UserPreferenceScore &&
        other.entityId == entityId &&
        other.entityName == entityName &&
        other.score == score &&
        other.likeCount == likeCount &&
        other.dislikeCount == dislikeCount;
  }

  @override
  int get hashCode {
    return Object.hash(
      entityId,
      entityName,
      score,
      likeCount,
      dislikeCount,
    );
  }

  @override
  String toString() {
    return 'UserPreferenceScore(id: $entityId, name: $entityName, score: $score, '
           'likes: $likeCount, dislikes: $dislikeCount, level: ${getPreferenceLevel()})';
  }
}