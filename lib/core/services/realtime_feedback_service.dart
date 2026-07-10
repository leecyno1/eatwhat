import 'dart:async';
import 'dart:collection';
import 'package:flutter/foundation.dart';

import 'user_preference_manager.dart';
import 'unified_food_data_service.dart';

/// 实时反馈服务 - Phase 2 核心优化
/// 实现用户行为的即时反馈和同步机制
class RealtimeFeedbackService {
  static final RealtimeFeedbackService _instance = RealtimeFeedbackService._internal();
  factory RealtimeFeedbackService() => _instance;
  RealtimeFeedbackService._internal();

  final UserPreferenceManager _preferenceManager = UserPreferenceManager();
  final UnifiedFoodDataService _unifiedService = UnifiedFoodDataService();

  // 实时反馈队列
  final Queue<UserAction> _actionQueue = Queue<UserAction>();
  final StreamController<UserFeedbackEvent> _feedbackController = StreamController.broadcast();

  // 反馈处理状态
  bool _isProcessingQueue = false;
  Timer? _batchProcessTimer;

  // 配置参数
  static const int _maxQueueSize = 100;
  static const Duration _batchProcessInterval = Duration(milliseconds: 500);
  static const Duration _immediateActionThreshold = Duration(milliseconds: 100);

  /// 反馈事件流
  Stream<UserFeedbackEvent> get feedbackStream => _feedbackController.stream;

  /// 初始化服务
  Future<void> initialize() async {
    await _preferenceManager.initialize();
    await _unifiedService.initialize();
    _startBatchProcessor();
    debugPrint('🔄 实时反馈服务初始化完成');
  }

  /// 记录用户行为 - 主要接口
  Future<void> recordUserAction(
    String itemId,
    UserActionType actionType, {
    Map<String, dynamic>? metadata,
    bool immediate = false,
  }) async {
    final action = UserAction(
      itemId: itemId,
      actionType: actionType,
      timestamp: DateTime.now(),
      metadata: metadata ?? {},
    );

    // 高优先级行为立即处理
    if (immediate || _isHighPriorityAction(actionType)) {
      await _processActionImmediately(action);
    } else {
      _enqueueAction(action);
    }

    // 发送反馈事件
    _feedbackController.add(UserFeedbackEvent(
      type: FeedbackEventType.actionRecorded,
      action: action,
      message: '已记录用户行为: ${actionType.name}',
    ));
  }

  /// 批量记录用户行为
  Future<void> recordBatchActions(List<UserAction> actions) async {
    for (final action in actions) {
      _enqueueAction(action);
    }

    // 如果队列较满，立即处理
    if (_actionQueue.length > _maxQueueSize * 0.8) {
      _processBatch();
    }

    _feedbackController.add(UserFeedbackEvent(
      type: FeedbackEventType.batchActionsRecorded,
      message: '批量记录了 ${actions.length} 个用户行为',
    ));
  }

  /// 获取实时偏好更新
  Future<UserPreferenceUpdate> getRealtimePreferenceUpdate() async {
    // 分析最近的用户行为模式
    final recentActions = _getRecentActions(Duration(minutes: 5));
    final preferenceChanges = await _analyzePreferenceChanges(recentActions);

    return UserPreferenceUpdate(
      changes: preferenceChanges,
      confidence: _calculateConfidence(recentActions),
      recommendations: await _generateAdaptiveRecommendations(preferenceChanges),
      timestamp: DateTime.now(),
    );
  }

  /// 启动推荐刷新
  Future<void> triggerRecommendationRefresh() async {
    _feedbackController.add(UserFeedbackEvent(
      type: FeedbackEventType.recommendationRefreshTriggered,
      message: '触发推荐系统刷新',
    ));

    // 异步刷新推荐（不阻塞UI）
    _refreshRecommendationsAsync();
  }

  /// 处理用户即时反馈
  void handleInstantFeedback(
    String itemId,
    InstantFeedbackType feedbackType,
    double intensity,
  ) {
    final metadata = {
      'feedbackType': feedbackType.name,
      'intensity': intensity,
      'timestamp': DateTime.now().toIso8601String(),
    };

    // 即时反馈总是立即处理
    recordUserAction(
      itemId,
      _mapFeedbackToActionType(feedbackType),
      metadata: metadata,
      immediate: true,
    );
  }

  /// 获取用户行为统计
  Map<String, dynamic> getUserActionStatistics() {
    final actionCounts = <UserActionType, int>{};
    final timeDistribution = <String, int>{};

    for (final action in _actionQueue) {
      actionCounts[action.actionType] = (actionCounts[action.actionType] ?? 0) + 1;

      final hour = action.timestamp.hour;
      final timeSlot = '${hour}:00-${hour + 1}:00';
      timeDistribution[timeSlot] = (timeDistribution[timeSlot] ?? 0) + 1;
    }

    return {
      'totalActions': _actionQueue.length,
      'actionCounts': actionCounts.map((k, v) => MapEntry(k.name, v)),
      'timeDistribution': timeDistribution,
      'queueSize': _actionQueue.length,
      'isProcessing': _isProcessingQueue,
    };
  }

  // 私有方法

  /// 判断是否为高优先级行为
  bool _isHighPriorityAction(UserActionType actionType) {
    return [
      UserActionType.favorite,
      UserActionType.dislike,
      UserActionType.share,
    ].contains(actionType);
  }

  /// 将行为加入队列
  void _enqueueAction(UserAction action) {
    if (_actionQueue.length >= _maxQueueSize) {
      _actionQueue.removeFirst(); // 移除最旧的行为
    }
    _actionQueue.addLast(action);
  }

  /// 立即处理行为
  Future<void> _processActionImmediately(UserAction action) async {
    try {
      await _preferenceManager.recordUserAction(action.itemId, action.actionType);

      // 发送处理完成事件
      _feedbackController.add(UserFeedbackEvent(
        type: FeedbackEventType.actionProcessed,
        action: action,
        message: '立即处理完成: ${action.actionType.name}',
      ));
    } catch (e) {
      debugPrint('立即处理用户行为失败: $e');
      _feedbackController.add(UserFeedbackEvent(
        type: FeedbackEventType.error,
        action: action,
        message: '处理失败: $e',
      ));
    }
  }

  /// 启动批处理器
  void _startBatchProcessor() {
    _batchProcessTimer = Timer.periodic(_batchProcessInterval, (timer) {
      if (_actionQueue.isNotEmpty && !_isProcessingQueue) {
        _processBatch();
      }
    });
  }

  /// 批处理行为队列
  Future<void> _processBatch() async {
    if (_isProcessingQueue || _actionQueue.isEmpty) return;

    _isProcessingQueue = true;
    final batchSize = (_actionQueue.length / 3).ceil().clamp(1, 20);
    final batch = <UserAction>[];

    // 提取批次
    for (int i = 0; i < batchSize && _actionQueue.isNotEmpty; i++) {
      batch.add(_actionQueue.removeFirst());
    }

    try {
      // 批量处理
      for (final action in batch) {
        await _preferenceManager.recordUserAction(action.itemId, action.actionType);
      }

      _feedbackController.add(UserFeedbackEvent(
        type: FeedbackEventType.batchProcessed,
        message: '批处理完成: ${batch.length} 个行为',
      ));

      debugPrint('📊 批处理完成: ${batch.length} 个用户行为');
    } catch (e) {
      debugPrint('批处理用户行为失败: $e');
      // 处理失败的行为重新加入队列
      for (final action in batch.reversed) {
        _actionQueue.addFirst(action);
      }
    } finally {
      _isProcessingQueue = false;
    }
  }

  /// 获取最近的行为
  List<UserAction> _getRecentActions(Duration timeWindow) {
    final cutoff = DateTime.now().subtract(timeWindow);
    return _actionQueue.where((action) => action.timestamp.isAfter(cutoff)).toList();
  }

  /// 分析偏好变化
  Future<Map<String, PreferenceChange>> _analyzePreferenceChanges(
    List<UserAction> recentActions,
  ) async {
    final changes = <String, PreferenceChange>{};

    // 分析口味偏好变化
    final tasteActions = recentActions
        .where((a) => a.actionType == UserActionType.like || a.actionType == UserActionType.dislike)
        .toList();

    for (final action in tasteActions) {
      final itemId = action.itemId;
      final isPositive = action.actionType == UserActionType.like;

      changes[itemId] = PreferenceChange(
        itemId: itemId,
        changeType: isPositive ? ChangeType.positive : ChangeType.negative,
        magnitude: _calculateChangeMagnitude(action),
        timestamp: action.timestamp,
      );
    }

    return changes;
  }

  /// 计算置信度
  double _calculateConfidence(List<UserAction> actions) {
    if (actions.isEmpty) return 0.0;

    // 基于行为数量和一致性计算置信度
    final actionCount = actions.length;
    final consistencyScore = _calculateConsistencyScore(actions);

    return (actionCount / 10.0 * 0.6 + consistencyScore * 0.4).clamp(0.0, 1.0);
  }

  /// 计算一致性分数
  double _calculateConsistencyScore(List<UserAction> actions) {
    final positiveActions = actions
        .where((a) => [UserActionType.like, UserActionType.favorite, UserActionType.share]
            .contains(a.actionType))
        .length;

    final negativeActions = actions.where((a) => a.actionType == UserActionType.dislike).length;

    if (actions.isEmpty) return 0.0;

    final dominantDirection = positiveActions > negativeActions ? positiveActions : negativeActions;
    return dominantDirection / actions.length;
  }

  /// 生成自适应推荐
  Future<List<String>> _generateAdaptiveRecommendations(
    Map<String, PreferenceChange> changes,
  ) async {
    // 基于偏好变化生成推荐
    final recommendations = <String>[];

    for (final change in changes.values) {
      if (change.changeType == ChangeType.positive && change.magnitude > 0.5) {
        recommendations.add(change.itemId);
      }
    }

    return recommendations.take(5).toList();
  }

  /// 异步刷新推荐
  void _refreshRecommendationsAsync() async {
    try {
      // 这里可以调用推荐系统进行刷新
      await Future.delayed(Duration(milliseconds: 100));

      _feedbackController.add(UserFeedbackEvent(
        type: FeedbackEventType.recommendationRefreshCompleted,
        message: '推荐系统刷新完成',
      ));
    } catch (e) {
      debugPrint('推荐刷新失败: $e');
    }
  }

  /// 将即时反馈映射到行为类型
  UserActionType _mapFeedbackToActionType(InstantFeedbackType feedbackType) {
    switch (feedbackType) {
      case InstantFeedbackType.love:
        return UserActionType.favorite;
      case InstantFeedbackType.like:
        return UserActionType.like;
      case InstantFeedbackType.dislike:
        return UserActionType.dislike;
      case InstantFeedbackType.interested:
        return UserActionType.view;
      case InstantFeedbackType.share:
        return UserActionType.share;
    }
  }

  /// 计算变化幅度
  double _calculateChangeMagnitude(UserAction action) {
    // 基于行为类型和元数据计算变化幅度
    switch (action.actionType) {
      case UserActionType.favorite:
        return 1.0;
      case UserActionType.like:
        return 0.7;
      case UserActionType.dislike:
        return -0.8;
      case UserActionType.share:
        return 0.9;
      default:
        return 0.3;
    }
  }

  /// 清理资源
  void dispose() {
    _batchProcessTimer?.cancel();
    _feedbackController.close();
    _actionQueue.clear();
  }
}

/// 用户行为数据模型
class UserAction {
  final String itemId;
  final UserActionType actionType;
  final DateTime timestamp;
  final Map<String, dynamic> metadata;

  UserAction({
    required this.itemId,
    required this.actionType,
    required this.timestamp,
    required this.metadata,
  });

  Map<String, dynamic> toJson() => {
        'itemId': itemId,
        'actionType': actionType.name,
        'timestamp': timestamp.toIso8601String(),
        'metadata': metadata,
      };

  factory UserAction.fromJson(Map<String, dynamic> json) => UserAction(
        itemId: json['itemId'] ?? '',
        actionType: UserActionType.values.firstWhere(
          (type) => type.name == json['actionType'],
          orElse: () => UserActionType.view,
        ),
        timestamp: DateTime.tryParse(json['timestamp'] ?? '') ?? DateTime.now(),
        metadata: Map<String, dynamic>.from(json['metadata'] ?? {}),
      );
}

/// 反馈事件数据模型
class UserFeedbackEvent {
  final FeedbackEventType type;
  final String message;
  final UserAction? action;
  final DateTime timestamp;

  UserFeedbackEvent({
    required this.type,
    required this.message,
    this.action,
  }) : timestamp = DateTime.now();
}

/// 用户偏好更新数据模型
class UserPreferenceUpdate {
  final Map<String, PreferenceChange> changes;
  final double confidence;
  final List<String> recommendations;
  final DateTime timestamp;

  UserPreferenceUpdate({
    required this.changes,
    required this.confidence,
    required this.recommendations,
    required this.timestamp,
  });
}

/// 偏好变化数据模型
class PreferenceChange {
  final String itemId;
  final ChangeType changeType;
  final double magnitude;
  final DateTime timestamp;

  PreferenceChange({
    required this.itemId,
    required this.changeType,
    required this.magnitude,
    required this.timestamp,
  });
}

/// 枚举定义
enum FeedbackEventType {
  actionRecorded,
  actionProcessed,
  batchActionsRecorded,
  batchProcessed,
  recommendationRefreshTriggered,
  recommendationRefreshCompleted,
  error,
}

enum InstantFeedbackType {
  love,
  like,
  dislike,
  interested,
  share,
}

enum ChangeType {
  positive,
  negative,
  neutral,
}
