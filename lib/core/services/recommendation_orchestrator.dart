import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/food.dart';
import '../models/user_taste_action.dart';
import '../models/user_preference.dart';
import '../repositories/user_preference_repository.dart';
import 'preference_event_service.dart';
import 'recommendation_engine.dart';

/// 推荐编排器 - 协调推荐引擎和偏好事件服务
class RecommendationOrchestrator {
  final PreferenceEventService preferenceEventService;
  final RecommendationEngine recommendationEngine;
  final UserPreferenceRepository userPreferenceRepository;

  final StreamController<List<Food>> _recommendationController = StreamController.broadcast();
  StreamSubscription<UserTasteAction>? _eventSubscription;

  // 兜底策略阈值：有效反馈少于3次时使用热门推荐
  static const int _preferenceFallbackThreshold = 3;

  RecommendationOrchestrator({
    required this.preferenceEventService,
    required this.recommendationEngine,
    required this.userPreferenceRepository,
  });

  Stream<List<Food>> get recommendationStream => _recommendationController.stream;

  Future<void> initialize() async {
    await preferenceEventService.init();
    recommendationEngine.initialize();
    await _refreshRecommendations();
    _eventSubscription = preferenceEventService.eventStream.listen((_) {
      _refreshRecommendations();
    });
  }

  Future<void> dispose() async {
    await _eventSubscription?.cancel();
    await preferenceEventService.dispose();
    await _recommendationController.close();
  }

  Future<List<Food>> forceRefresh() async {
    return _refreshRecommendations(force: true);
  }

  /// 检查用户偏好是否不足，需要使用热门推荐兜底
  bool _needsFallbackStrategy(UserPreference preference) {
    // 计算有效反馈次数
    final likedCount = preference.likedBubbles.length;
    final dislikedCount = preference.dislikedBubbles.length;
    final interactionCount = preference.bubbleInteractionCount.values.fold(0, (a, b) => a + b);
    final totalFeedback = likedCount + dislikedCount + interactionCount;

    debugPrint('偏好反馈统计: liked=$likedCount, disliked=$dislikedCount, '
        'interactions=$interactionCount, total=$totalFeedback');

    return totalFeedback < _preferenceFallbackThreshold;
  }

  /// 获取热门推荐（基于全局点击率统计）
  List<Food> _getHotRecommendations({int limit = 6}) {
    // 使用评分和评价数量计算热门度
    final hotRecommendations = recommendationEngine.getPopularRecommendations();
    debugPrint('使用热门推荐兜底，返回 ${hotRecommendations.length} 个');
    return hotRecommendations.take(limit).toList();
  }

  Future<List<Food>> _refreshRecommendations({bool force = false}) async {
    try {
      final preference = await userPreferenceRepository.get();

      // 检查是否需要使用兜底策略
      if (_needsFallbackStrategy(preference)) {
        debugPrint('用户偏好不足(${preference.likedBubbles.length + preference.dislikedBubbles.length + preference.bubbleInteractionCount.values.fold(0, (a, b) => a + b)}个)，使用热门推荐');
        final fallback = _getHotRecommendations(limit: 6);
        _recommendationController.add(fallback);
        return fallback;
      }

      final recommendations = await recommendationEngine.getPersonalizedRecommendations(preference);
      if (recommendations.isEmpty && !force) {
        final fallback = _getHotRecommendations(limit: 6);
        _recommendationController.add(fallback);
        return fallback;
      }
      _recommendationController.add(recommendations);
      return recommendations;
    } catch (e, s) {
      debugPrint('刷新推荐失败: $e\n$s');
      final fallback = _getHotRecommendations(limit: 6);
      _recommendationController.add(fallback);
      return fallback;
    }
  }
}
