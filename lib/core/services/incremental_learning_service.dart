import 'dart:math';
import 'package:flutter/foundation.dart';

/// 口味反馈事件
class TasteFeedbackEvent {
  /// 菜谱ID
  final String recipeId;

  /// 反馈强度（0.0-1.0）
  final double intensity;

  /// 是否为正向反馈（true=喜欢，false=不喜欢）
  final bool isPositive;

  /// 时间戳
  final DateTime timestamp;

  /// 推荐位置索引
  final int recommendationIndex;

  /// 菜谱口味特征向量（46维）
  final List<double>? tasteVector;

  TasteFeedbackEvent({
    required this.recipeId,
    required this.intensity,
    required this.isPositive,
    DateTime? timestamp,
    this.recommendationIndex = 0,
    this.tasteVector,
  }) : timestamp = timestamp ?? DateTime.now();

  @override
  String toString() {
    return 'TasteFeedbackEvent(recipeId: $recipeId, intensity: $intensity, '
        'isPositive: $isPositive, timestamp: $timestamp)';
  }
}

/// 用户味觉向量（46维口味特征）
class TasteVector {
  /// 46维口味特征向量
  /// 索引对应口味类型：
  /// 0-9: 基本口味（甜、酸、苦、辣、咸、鲜、油腻、清淡、香、涩）
  /// 10-19: 烹饪方式（炒、煮、蒸、炸、烤、炖、煎、拌、生食、卤）
  /// 20-29: 食材类别（肉类、海鲜、蔬菜、豆制品、主食、水果、蛋类、奶制品、菌类、坚果）
  /// 30-39: 菜系（中餐八大菜系、川、粤、苏、浙、闽、湘、徽、鲁、其他中餐、西餐、日韩料理、其他）
  /// 40-45: 其他特征（辣度、麻度、甜度、油腻度、清淡度、浓郁度）
  final List<double> _vector;

  TasteVector([List<double>? initialVector])
      : _vector = initialVector ?? List.filled(46, 0.0);

  /// 获取向量副本
  List<double> get values => List<double>.from(_vector);

  /// 获取特定口味维度的值
  double operator [](int index) => _vector[index.clamp(0, 45)];

  /// 设置特定口味维度的值
  void setValue(int index, double value) {
    if (index >= 0 && index < 46) {
      _vector[index] = value.clamp(-1.0, 1.0);
    }
  }

  /// 更新整个向量
  void update(List<double> newVector) {
    for (int i = 0; i < 46 && i < newVector.length; i++) {
      _vector[i] = newVector[i].clamp(-1.0, 1.0);
    }
  }

  /// 归一化向量
  void normalize() {
    final magnitude = sqrt(_vector.fold<double>(0, (sum, v) => sum + v * v));
    if (magnitude > 0) {
      for (int i = 0; i < 46; i++) {
        _vector[i] /= magnitude;
      }
    }
  }

  /// 计算与另一个向量的余弦相似度
  double cosineSimilarity(TasteVector other) {
    double dotProduct = 0;
    double magnitude1 = 0;
    double magnitude2 = 0;

    for (int i = 0; i < 46; i++) {
      dotProduct += _vector[i] * other._vector[i];
      magnitude1 += _vector[i] * _vector[i];
      magnitude2 += other._vector[i] * other._vector[i];
    }

    final mag1 = sqrt(magnitude1);
    final mag2 = sqrt(magnitude2);

    if (mag1 == 0 || mag2 == 0) return 0;
    return dotProduct / (mag1 * mag2);
  }

  /// 梯度下降更新向量
  /// [learningRate] 学习率，默认0.01
  /// [gradient] 梯度向量
  void gradientUpdate(List<double> gradient, {double learningRate = 0.01}) {
    for (int i = 0; i < 46; i++) {
      _vector[i] -= learningRate * gradient[i];
      _vector[i] = _vector[i].clamp(-1.0, 1.0);
    }
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() => {'vector': _vector};

  /// 从JSON创建
  factory TasteVector.fromJson(Map<String, dynamic> json) {
    final vector = List<double>.from(json['vector'] ?? []);
    return TasteVector(vector);
  }

  @override
  String toString() {
    return 'TasteVector(magnitude: ${sqrt(_vector.fold<double>(0, (sum, v) => sum + v * v)).toStringAsFixed(3)})';
  }
}

/// 增量学习服务
///
/// 使用梯度下降算法在线更新用户味觉向量
/// 每次反馈后增量更新，无需全量重算
class IncrementalLearningService {
  /// 单例模式
  static final IncrementalLearningService _instance = IncrementalLearningService._internal();
  factory IncrementalLearningService() => _instance;
  IncrementalLearningService._internal();

  /// 学习率
  static const double _defaultLearningRate = 0.01;

  /// 用户味觉向量
  TasteVector _userTasteVector = TasteVector();

  /// 反馈历史
  final List<TasteFeedbackEvent> _feedbackHistory = [];

  /// 学习统计
  final Map<String, dynamic> _learningStats = {
    'totalFeedbacks': 0,
    'positiveFeedbacks': 0,
    'negativeFeedbacks': 0,
    'averageIntensity': 0.0,
    'lastUpdateTime': null,
  };

  /// 获取用户味觉向量
  TasteVector get userTasteVector => _userTasteVector;

  /// 获取反馈历史
  List<TasteFeedbackEvent> get feedbackHistory => List.unmodifiable(_feedbackHistory);

  /// 获取学习统计
  Map<String, dynamic> get learningStats => Map.unmodifiable(_learningStats);

  /// 记录口味反馈并触发增量学习
  Future<void> recordFeedback(TasteFeedbackEvent event) async {
    debugPrint('📝 记录口味反馈: $event');

    // 添加到历史
    _feedbackHistory.add(event);

    // 更新统计
    _updateStats(event);

    // 执行增量学习
    await _incrementalLearn(event);

    debugPrint('✅ 增量学习完成，当前用户味觉向量: $_userTasteVector');
  }

  /// 更新学习统计
  void _updateStats(TasteFeedbackEvent event) {
    final total = _feedbackHistory.length;
    final positive = _feedbackHistory.where((e) => e.isPositive).length;
    final negative = total - positive;

    double avgIntensity = 0;
    if (total > 0) {
      avgIntensity = _feedbackHistory.map((e) => e.intensity).reduce((a, b) => a + b) / total;
    }

    _learningStats['totalFeedbacks'] = total;
    _learningStats['positiveFeedbacks'] = positive;
    _learningStats['negativeFeedbacks'] = negative;
    _learningStats['averageIntensity'] = avgIntensity;
    _learningStats['lastUpdateTime'] = DateTime.now().toIso8601String();
  }

  /// 执行增量学习
  ///
  /// 使用梯度下降算法更新用户味觉向量
  /// 正向反馈：增加对应口味维度的权重
  /// 负向反馈：减少对应口味维度的权重
  Future<void> _incrementalLearn(TasteFeedbackEvent event) async {
    // 获取或创建口味向量
    List<double> tasteVector = event.tasteVector ?? _getDefaultTasteVector(event.recipeId);

    // 计算梯度
    List<double> gradient = _computeGradient(
      tasteVector: tasteVector,
      isPositive: event.isPositive,
      intensity: event.intensity,
    );

    // 应用梯度下降更新
    _userTasteVector.gradientUpdate(gradient, learningRate: _defaultLearningRate);

    // 归一化
    _userTasteVector.normalize();

    debugPrint('🔄 梯度下降更新完成，学习率: $_defaultLearningRate');
  }

  /// 计算梯度
  ///
  /// 梯度方向：正向反馈时向口味向量靠近，负向反馈时远离
  List<double> _computeGradient({
    required List<double> tasteVector,
    required bool isPositive,
    required double intensity,
  }) {
    // 梯度 = -η * (目标向量 - 当前向量) * 强度因子
    // 正向反馈：向口味向量方向移动
    // 负向反馈：向口味向量反方向移动

    final sign = isPositive ? 1.0 : -1.0;
    final scaledLearningRate = _defaultLearningRate * intensity * sign;

    List<double> gradient = [];
    for (int i = 0; i < 46; i++) {
      final targetValue = i < tasteVector.length ? tasteVector[i] : 0.0;
      final currentValue = _userTasteVector[i];
      // 梯度 = η * (目标 - 当前) * 强度
      gradient.add(scaledLearningRate * (targetValue - currentValue));
    }

    return gradient;
  }

  /// 获取默认口味向量（用于没有详细信息的菜谱）
  List<double> _getDefaultTasteVector(String recipeId) {
    // 基于recipeId生成伪随机但稳定的口味向量
    // 实际项目中应该从数据库获取真实口味向量
    final random = Random(recipeId.hashCode);
    return List.generate(46, (i) => (random.nextDouble() - 0.5) * 0.5);
  }

  /// 设置用户味觉向量（用于初始化或外部加载）
  void setUserTasteVector(TasteVector vector) {
    _userTasteVector = vector;
    debugPrint('📥 用户味觉向量已更新: $vector');
  }

  /// 设置用户味觉向量（从列表）
  void setUserTasteVectorFromList(List<double> vector) {
    _userTasteVector = TasteVector(vector);
    debugPrint('📥 用户味觉向量已从列表更新');
  }

  /// 重置学习状态
  void reset() {
    _userTasteVector = TasteVector();
    _feedbackHistory.clear();
    _learningStats['totalFeedbacks'] = 0;
    _learningStats['positiveFeedbacks'] = 0;
    _learningStats['negativeFeedbacks'] = 0;
    _learningStats['averageIntensity'] = 0.0;
    _learningStats['lastUpdateTime'] = null;
    debugPrint('🗑️ 增量学习状态已重置');
  }

  /// 导出用户味觉向量为JSON
  Map<String, dynamic> exportTasteVector() {
    return _userTasteVector.toJson();
  }

  /// 从JSON导入用户味觉向量
  void importTasteVector(Map<String, dynamic> json) {
    _userTasteVector = TasteVector.fromJson(json);
    debugPrint('📥 用户味觉向量已导入');
  }

  /// 计算与推荐候选的相似度
  double calculateSimilarity(List<double> candidateVector) {
    final candidateTasteVector = TasteVector(candidateVector);
    return _userTasteVector.cosineSimilarity(candidateTasteVector);
  }

  /// 获取用户口味偏好摘要
  Map<String, dynamic> getTastePreferenceSummary() {
    final vector = _userTasteVector.values;
    final tasteNames = [
      '甜', '酸', '苦', '辣', '咸', '鲜', '油腻', '清淡', '香', '涩',
      '炒', '煮', '蒸', '炸', '烤', '炖', '煎', '拌', '生食', '卤',
      '肉类', '海鲜', '蔬菜', '豆制品', '主食', '水果', '蛋类', '奶制品', '菌类', '坚果',
      '川菜', '粤菜', '苏菜', '浙菜', '闽菜', '湘菜', '徽菜', '鲁菜', '西餐', '日韩',
      '辣度', '麻度', '甜度', '油腻度', '清淡度', '浓郁度',
    ];

    final preferences = <String, double>{};
    for (int i = 0; i < 46; i++) {
      if (vector[i].abs() > 0.1) {
        preferences[tasteNames[i]] = vector[i];
      }
    }

    return {
      'totalFeedbacks': _learningStats['totalFeedbacks'],
      'topPreferences': _sortByValue(preferences).take(5).toList(),
      'vector': vector,
    };
  }

  /// 按值排序
  List<MapEntry<String, double>> _sortByValue(Map<String, double> map) {
    final entries = map.entries.toList();
    entries.sort((a, b) => b.value.abs().compareTo(a.value.abs()));
    return entries;
  }
}
