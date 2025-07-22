import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/user_preference_score.dart';
import '../models/physical_entity.dart';
import '../data/taste_preference_database.dart';

/// 用户偏好管理器 - 处理评分、气泡大小和显示概率
class UserPreferenceManager {
  static const String _preferencesKey = 'user_preference_scores';
  static const String _lastDisplayedKey = 'last_displayed_entities';
  
  final Map<String, UserPreferenceScore> _scores = {};
  final Set<String> _displayedEntityIds = {};
  final Random _random = Random();

  /// 单例模式
  static final UserPreferenceManager _instance = UserPreferenceManager._internal();
  factory UserPreferenceManager() => _instance;
  UserPreferenceManager._internal();

  /// 初始化偏好管理器
  Future<void> initialize() async {
    await _loadPreferences();
    debugPrint('用户偏好管理器初始化完成，已加载 ${_scores.length} 个偏好记录');
  }

  /// 加载用户偏好
  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final preferencesJson = prefs.getString(_preferencesKey);
      final displayedJson = prefs.getString(_lastDisplayedKey);
      
      if (preferencesJson != null) {
        final Map<String, dynamic> preferencesMap = jsonDecode(preferencesJson);
        _scores.clear();
        
        preferencesMap.forEach((key, value) {
          _scores[key] = UserPreferenceScore.fromJson(value);
        });
      }
      
      if (displayedJson != null) {
        final List<dynamic> displayedList = jsonDecode(displayedJson);
        _displayedEntityIds.clear();
        _displayedEntityIds.addAll(displayedList.cast<String>());
      }
      
    } catch (e) {
      debugPrint('加载用户偏好时出错: $e');
    }
  }

  /// 保存用户偏好
  Future<void> _savePreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      
      final preferencesMap = <String, dynamic>{};
      _scores.forEach((key, value) {
        preferencesMap[key] = value.toJson();
      });
      
      await prefs.setString(_preferencesKey, jsonEncode(preferencesMap));
      await prefs.setString(_lastDisplayedKey, jsonEncode(_displayedEntityIds.toList()));
      
    } catch (e) {
      debugPrint('保存用户偏好时出错: $e');
    }
  }

  /// 获取或创建用户偏好记录
  UserPreferenceScore _getOrCreateScore(String entityId, String entityName) {
    return _scores[entityId] ?? UserPreferenceScore.create(entityId, entityName);
  }

  /// 点赞实体
  Future<void> likeEntity(String entityId, String entityName) async {
    final score = _getOrCreateScore(entityId, entityName);
    _scores[entityId] = score.like();
    await _savePreferences();
    
    debugPrint('👍 用户喜欢: $entityName (分数: ${_scores[entityId]!.score})');
  }

  /// 点踩实体
  Future<void> dislikeEntity(String entityId, String entityName) async {
    final score = _getOrCreateScore(entityId, entityName);
    _scores[entityId] = score.dislike();
    await _savePreferences();
    
    debugPrint('👎 用户不喜欢: $entityName (分数: ${_scores[entityId]!.score})');
  }

  /// 选择实体
  Future<void> selectEntity(String entityId, String entityName) async {
    final score = _getOrCreateScore(entityId, entityName);
    _scores[entityId] = score.select();
    await _savePreferences();
    
    debugPrint('✅ 用户选择: $entityName (分数: ${_scores[entityId]!.score})');
  }

  /// 忽略实体
  Future<void> ignoreEntity(String entityId, String entityName) async {
    final score = _getOrCreateScore(entityId, entityName);
    _scores[entityId] = score.ignore();
    await _savePreferences();
    
    debugPrint('⏭️ 用户忽略: $entityName (分数: ${_scores[entityId]!.score})');
  }

  /// 向下滑动删除实体
  Future<void> swipeDownEntity(String entityId, String entityName) async {
    final score = _getOrCreateScore(entityId, entityName);
    _scores[entityId] = score.swipeDown();
    await _savePreferences();
    
    debugPrint('⬇️ 用户滑走: $entityName (分数: ${_scores[entityId]!.score})');
  }

  /// 获取实体的当前分数
  double getEntityScore(String entityId) {
    return _scores[entityId]?.score ?? UserPreferenceScore.defaultScore;
  }

  /// 计算实体的气泡半径
  double calculateEntityRadius(String entityId, {
    double baseRadius = 34.0,
    double minRadius = 20.0,
    double maxRadius = 50.0,
  }) {
    final score = _scores[entityId];
    if (score == null) return baseRadius;
    
    return score.calculateRadius(
      baseRadius: baseRadius,
      minRadius: minRadius,
      maxRadius: maxRadius,
    );
  }

  /// 获取实体的概率权重
  double getEntityProbabilityWeight(String entityId) {
    final score = _scores[entityId];
    if (score == null) return 1.0;
    
    return score.calculateProbabilityWeight();
  }

  /// 基于概率权重随机选择30个实体
  List<PhysicalEntity> selectRandomEntities({
    int count = 30,
    List<PhysicalEntity>? excludeEntities,
  }) {
    final allEntities = TastePreferenceDatabase.getAllTasteEntities();
    final excludeIds = excludeEntities?.map((e) => e.id).toSet() ?? <String>{};
    
    // 过滤掉已排除的实体
    final availableEntities = allEntities
        .where((entity) => !excludeIds.contains(entity.id))
        .toList();
    
    if (availableEntities.length <= count) {
      return availableEntities;
    }

    // 创建权重列表
    final weightedEntities = <_WeightedEntity>[];
    double totalWeight = 0.0;

    for (final entity in availableEntities) {
      final weight = getEntityProbabilityWeight(entity.id);
      weightedEntities.add(_WeightedEntity(entity, weight));
      totalWeight += weight;
    }

    // 基于权重随机选择
    final selectedEntities = <PhysicalEntity>[];
    final selectedIds = <String>{};

    for (int i = 0; i < count && weightedEntities.isNotEmpty; i++) {
      final randomValue = _random.nextDouble() * totalWeight;
      double currentWeight = 0.0;
      
      int selectedIndex = -1;
      for (int j = 0; j < weightedEntities.length; j++) {
        currentWeight += weightedEntities[j].weight;
        if (randomValue <= currentWeight) {
          selectedIndex = j;
          break;
        }
      }
      
      // 如果没有找到，选择最后一个
      if (selectedIndex == -1) {
        selectedIndex = weightedEntities.length - 1;
      }
      
      final selectedWeighted = weightedEntities[selectedIndex];
      final selectedEntity = selectedWeighted.entity;
      
      // 避免重复选择
      if (!selectedIds.contains(selectedEntity.id)) {
        selectedEntities.add(selectedEntity);
        selectedIds.add(selectedEntity.id);
      }
      
      // 从列表中移除已选择的实体
      totalWeight -= selectedWeighted.weight;
      weightedEntities.removeAt(selectedIndex);
    }

    debugPrint('🎲 基于概率权重选择了 ${selectedEntities.length} 个实体');
    return selectedEntities;
  }

  /// 应用用户偏好到实体（设置半径和透明度）
  PhysicalEntity applyPreferencesToEntity(PhysicalEntity entity) {
    final radius = calculateEntityRadius(entity.id);
    final score = getEntityScore(entity.id);
    
    // 根据分数调整透明度（负分数的实体更透明）
    double opacity = 1.0;
    if (score < 0) {
      opacity = (0.3 + (score + 100.0) / 100.0 * 0.7).clamp(0.3, 1.0);
    }
    
    return entity.copyWith(
      radius: radius,
      opacity: opacity,
    );
  }

  /// 批量应用偏好到实体列表
  List<PhysicalEntity> applyPreferencesToEntities(List<PhysicalEntity> entities) {
    return entities.map((entity) => applyPreferencesToEntity(entity)).toList();
  }

  /// 记录已显示的实体ID
  void recordDisplayedEntities(List<PhysicalEntity> entities) {
    _displayedEntityIds.clear();
    _displayedEntityIds.addAll(entities.map((e) => e.id));
    _savePreferences();
  }

  /// 获取新的替换实体（不重复）
  PhysicalEntity? getReplacementEntity() {
    final allEntities = TastePreferenceDatabase.getAllTasteEntities();
    final availableEntities = allEntities
        .where((entity) => !_displayedEntityIds.contains(entity.id))
        .toList();
    
    if (availableEntities.isEmpty) {
      // 如果所有实体都显示过了，重置显示记录
      _displayedEntityIds.clear();
      debugPrint('🔄 所有实体都显示过了，重置显示记录');
      return getReplacementEntity();
    }

    // 基于概率权重选择一个替换实体
    final selectedEntities = selectRandomEntities(
      count: 1,
      excludeEntities: allEntities
          .where((e) => _displayedEntityIds.contains(e.id))
          .toList(),
    );

    if (selectedEntities.isNotEmpty) {
      final replacement = selectedEntities.first;
      _displayedEntityIds.add(replacement.id);
      _savePreferences();
      
      debugPrint('🔄 选择替换实体: ${replacement.name}');
      return applyPreferencesToEntity(replacement);
    }

    return null;
  }

  /// 获取用户偏好统计
  Map<String, dynamic> getPreferenceStats() {
    final totalEntities = _scores.length;
    final likedEntities = _scores.values.where((s) => s.score > 5).length;
    final dislikedEntities = _scores.values.where((s) => s.score < -5).length;
    final averageScore = totalEntities > 0 
        ? _scores.values.map((s) => s.score).reduce((a, b) => a + b) / totalEntities
        : 0.0;

    return {
      'totalEntities': totalEntities,
      'likedEntities': likedEntities,
      'dislikedEntities': dislikedEntities,
      'neutralEntities': totalEntities - likedEntities - dislikedEntities,
      'averageScore': averageScore,
      'topPreferences': _getTopPreferences(),
      'worstPreferences': _getWorstPreferences(),
    };
  }

  /// 获取最喜欢的偏好
  List<UserPreferenceScore> _getTopPreferences() {
    final sorted = _scores.values.toList()
      ..sort((a, b) => b.score.compareTo(a.score));
    return sorted.take(5).toList();
  }

  /// 获取最不喜欢的偏好
  List<UserPreferenceScore> _getWorstPreferences() {
    final sorted = _scores.values.toList()
      ..sort((a, b) => a.score.compareTo(b.score));
    return sorted.take(5).toList();
  }

  /// 清除所有偏好数据
  Future<void> clearAllPreferences() async {
    _scores.clear();
    _displayedEntityIds.clear();
    await _savePreferences();
    debugPrint('🗑️ 已清除所有用户偏好数据');
  }
}

/// 内部辅助类：带权重的实体
class _WeightedEntity {
  final PhysicalEntity entity;
  final double weight;

  _WeightedEntity(this.entity, this.weight);
}