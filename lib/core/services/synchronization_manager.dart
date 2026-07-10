import 'dart:async';
import 'package:flutter/foundation.dart';

import 'realtime_feedback_service.dart';
import 'unified_food_data_service.dart';
import 'user_preference_manager.dart';

/// 同步管理器 - Phase 2 实时同步核心
/// 协调各个服务之间的数据同步和状态管理
class SynchronizationManager {
  static final SynchronizationManager _instance = SynchronizationManager._internal();
  factory SynchronizationManager() => _instance;
  SynchronizationManager._internal();

  final RealtimeFeedbackService _feedbackService = RealtimeFeedbackService();
  final UnifiedFoodDataService _unifiedService = UnifiedFoodDataService();
  final UserPreferenceManager _preferenceManager = UserPreferenceManager();

  // 同步状态管理
  final StreamController<SyncEvent> _syncController = StreamController.broadcast();
  final Map<String, SyncStatus> _serviceStatus = {};

  // 同步配置
  static const Duration _syncInterval = Duration(seconds: 30);
  static const Duration _immediateSync0utTime = Duration(seconds: 5);

  Timer? _periodicSyncTimer;
  bool _isInitialized = false;
  bool _isSyncing = false;

  /// 同步事件流
  Stream<SyncEvent> get syncStream => _syncController.stream;

  /// 获取同步状态
  Map<String, SyncStatus> get serviceStatus => Map.from(_serviceStatus);

  /// 是否正在同步
  bool get isSyncing => _isSyncing;

  /// 初始化同步管理器
  Future<void> initialize() async {
    if (_isInitialized) return;

    try {
      debugPrint('🔄 开始初始化同步管理器...');

      // 初始化各个服务
      await _initializeServices();

      // 设置服务状态监听
      await _setupServiceMonitoring();

      // 启动定期同步
      _startPeriodicSync();

      _isInitialized = true;

      _emitSyncEvent(SyncEventType.initialized, '同步管理器初始化完成');
      debugPrint('✅ 同步管理器初始化完成');
    } catch (e) {
      debugPrint('❌ 同步管理器初始化失败: $e');
      _emitSyncEvent(SyncEventType.error, '初始化失败: $e');
      rethrow;
    }
  }

  /// 执行完整同步
  Future<SyncResult> performFullSync() async {
    if (_isSyncing) {
      return SyncResult(
        success: false,
        message: '同步正在进行中',
        timestamp: DateTime.now(),
      );
    }

    _isSyncing = true;
    final startTime = DateTime.now();

    try {
      _emitSyncEvent(SyncEventType.syncStarted, '开始完整同步');

      final result = SyncResult(
        success: true,
        message: '同步成功',
        timestamp: DateTime.now(),
        duration: DateTime.now().difference(startTime),
        details: {},
      );

      // 1. 同步用户偏好数据
      final preferenceResult = await _syncUserPreferences();
      result.details['userPreferences'] = preferenceResult;

      // 2. 同步推荐数据
      final recommendationResult = await _syncRecommendations();
      result.details['recommendations'] = recommendationResult;

      // 3. 同步用户行为数据
      final behaviorResult = await _syncUserBehavior();
      result.details['userBehavior'] = behaviorResult;

      // 4. 验证数据一致性
      final consistencyResult = await _verifyDataConsistency();
      result.details['dataConsistency'] = consistencyResult;

      result.message = '同步成功';
      result.duration = DateTime.now().difference(startTime);

      _emitSyncEvent(
        SyncEventType.syncCompleted,
        '完整同步完成，耗时: ${result.duration?.inMilliseconds ?? 0}ms',
      );

      return result;
    } catch (e) {
      final errorResult = SyncResult(
        success: false,
        message: '同步失败: $e',
        timestamp: DateTime.now(),
        duration: DateTime.now().difference(startTime),
      );

      _emitSyncEvent(SyncEventType.error, errorResult.message);
      return errorResult;
    } finally {
      _isSyncing = false;
    }
  }

  /// 执行增量同步
  Future<SyncResult> performIncrementalSync() async {
    if (_isSyncing) {
      return SyncResult(
        success: false,
        message: '同步正在进行中',
        timestamp: DateTime.now(),
      );
    }

    _isSyncing = true;
    final startTime = DateTime.now();

    try {
      _emitSyncEvent(SyncEventType.incrementalSyncStarted, '开始增量同步');

      // 获取实时偏好更新
      final preferenceUpdate = await _feedbackService.getRealtimePreferenceUpdate();

      // 应用偏好变化
      await _applyPreferenceChanges(preferenceUpdate.changes);

      // 触发推荐刷新
      if (preferenceUpdate.confidence > 0.7) {
        await _feedbackService.triggerRecommendationRefresh();
      }

      final result = SyncResult(
        success: true,
        message: '增量同步完成',
        timestamp: DateTime.now(),
        duration: DateTime.now().difference(startTime),
        details: {
          'changesApplied': preferenceUpdate.changes.length,
          'confidence': preferenceUpdate.confidence,
          'recommendationsUpdated': preferenceUpdate.confidence > 0.7,
        },
      );

      _emitSyncEvent(SyncEventType.incrementalSyncCompleted, result.message);
      return result;
    } catch (e) {
      final errorResult = SyncResult(
        success: false,
        message: '增量同步失败: $e',
        timestamp: DateTime.now(),
        duration: DateTime.now().difference(startTime),
      );

      _emitSyncEvent(SyncEventType.error, errorResult.message);
      return errorResult;
    } finally {
      _isSyncing = false;
    }
  }

  /// 强制同步特定服务
  Future<bool> forceSyncService(String serviceName) async {
    try {
      _emitSyncEvent(SyncEventType.serviceSyncStarted, '强制同步服务: $serviceName');

      bool success = false;
      switch (serviceName) {
        case 'userPreferences':
          success = await _syncUserPreferences();
          break;
        case 'recommendations':
          success = await _syncRecommendations();
          break;
        case 'userBehavior':
          success = await _syncUserBehavior();
          break;
        default:
          throw Exception('未知服务: $serviceName');
      }

      if (success) {
        _serviceStatus[serviceName] = SyncStatus.synced;
        _emitSyncEvent(SyncEventType.serviceSyncCompleted, '$serviceName 同步完成');
      } else {
        _serviceStatus[serviceName] = SyncStatus.error;
        _emitSyncEvent(SyncEventType.error, '$serviceName 同步失败');
      }

      return success;
    } catch (e) {
      _serviceStatus[serviceName] = SyncStatus.error;
      _emitSyncEvent(SyncEventType.error, '$serviceName 同步异常: $e');
      return false;
    }
  }

  /// 获取同步统计信息
  Map<String, dynamic> getSyncStatistics() {
    final stats = {
      'isInitialized': _isInitialized,
      'isSyncing': _isSyncing,
      'serviceStatus': _serviceStatus.map((k, v) => MapEntry(k, v.name)),
      'lastSyncTime': _getLastSyncTime(),
      'syncCount': _getSyncCount(),
      'errorCount': _getErrorCount(),
    };

    return stats;
  }

  // 私有方法

  /// 初始化各个服务
  Future<void> _initializeServices() async {
    // 初始化反馈服务
    await _feedbackService.initialize();
    _serviceStatus['feedbackService'] = SyncStatus.synced;

    // 初始化统一数据服务
    await _unifiedService.initialize();
    _serviceStatus['unifiedService'] = SyncStatus.synced;

    // 初始化偏好管理器
    await _preferenceManager.initialize();
    _serviceStatus['preferenceManager'] = SyncStatus.synced;
  }

  /// 设置服务监控
  Future<void> _setupServiceMonitoring() async {
    // 监听反馈服务事件
    _feedbackService.feedbackStream.listen((event) {
      _handleFeedbackEvent(event);
    });
  }

  /// 启动定期同步
  void _startPeriodicSync() {
    _periodicSyncTimer = Timer.periodic(_syncInterval, (timer) {
      if (!_isSyncing) {
        performIncrementalSync();
      }
    });
  }

  /// 处理反馈事件
  void _handleFeedbackEvent(UserFeedbackEvent event) {
    switch (event.type) {
      case FeedbackEventType.actionRecorded:
      case FeedbackEventType.batchActionsRecorded:
        // 用户行为记录后触发增量同步
        _scheduleIncrementalSync();
        break;
      case FeedbackEventType.error:
        _serviceStatus['feedbackService'] = SyncStatus.error;
        break;
      default:
        break;
    }
  }

  /// 安排增量同步
  void _scheduleIncrementalSync() {
    Timer(_immediateSync0utTime, () {
      if (!_isSyncing) {
        performIncrementalSync();
      }
    });
  }

  /// 同步用户偏好
  Future<bool> _syncUserPreferences() async {
    try {
      // 这里实现用户偏好的同步逻辑
      debugPrint('📊 同步用户偏好数据...');

      // 模拟同步过程
      await Future.delayed(Duration(milliseconds: 200));

      return true;
    } catch (e) {
      debugPrint('❌ 同步用户偏好失败: $e');
      return false;
    }
  }

  /// 同步推荐数据
  Future<bool> _syncRecommendations() async {
    try {
      debugPrint('🎯 同步推荐数据...');

      // 模拟同步过程
      await Future.delayed(Duration(milliseconds: 300));

      return true;
    } catch (e) {
      debugPrint('❌ 同步推荐数据失败: $e');
      return false;
    }
  }

  /// 同步用户行为数据
  Future<bool> _syncUserBehavior() async {
    try {
      debugPrint('👤 同步用户行为数据...');

      // 获取用户行为统计
      final stats = _feedbackService.getUserActionStatistics();
      debugPrint('行为统计: $stats');

      // 模拟同步过程
      await Future.delayed(Duration(milliseconds: 150));

      return true;
    } catch (e) {
      debugPrint('❌ 同步用户行为数据失败: $e');
      return false;
    }
  }

  /// 验证数据一致性
  Future<bool> _verifyDataConsistency() async {
    try {
      debugPrint('🔍 验证数据一致性...');

      // 这里实现数据一致性检查逻辑
      await Future.delayed(Duration(milliseconds: 100));

      return true;
    } catch (e) {
      debugPrint('❌ 数据一致性验证失败: $e');
      return false;
    }
  }

  /// 应用偏好变化
  Future<void> _applyPreferenceChanges(Map<String, PreferenceChange> changes) async {
    for (final change in changes.values) {
      try {
        await _preferenceManager.recordUserAction(
          change.itemId,
          change.changeType == ChangeType.positive ? UserActionType.like : UserActionType.dislike,
        );
      } catch (e) {
        debugPrint('应用偏好变化失败: $e');
      }
    }
  }

  /// 发送同步事件
  void _emitSyncEvent(SyncEventType type, String message) {
    _syncController.add(SyncEvent(
      type: type,
      message: message,
      timestamp: DateTime.now(),
    ));
  }

  /// 获取最后同步时间
  DateTime? _getLastSyncTime() {
    // 这里应该从持久化存储中获取
    return DateTime.now().subtract(Duration(minutes: 1));
  }

  /// 获取同步次数
  int _getSyncCount() {
    // 这里应该从持久化存储中获取
    return 42;
  }

  /// 获取错误次数
  int _getErrorCount() {
    // 这里应该从持久化存储中获取
    return 2;
  }

  /// 清理资源
  void dispose() {
    _periodicSyncTimer?.cancel();
    _syncController.close();
    _feedbackService.dispose();
    _serviceStatus.clear();
  }
}

/// 同步结果数据模型
class SyncResult {
  final bool success;
  String message;
  final DateTime timestamp;
  Duration? duration;
  final Map<String, dynamic> details;

  SyncResult({
    required this.success,
    required this.message,
    required this.timestamp,
    this.duration,
    this.details = const {},
  });

  @override
  String toString() =>
      'SyncResult(success: $success, message: $message, duration: ${duration?.inMilliseconds}ms)';
}

/// 同步事件数据模型
class SyncEvent {
  final SyncEventType type;
  final String message;
  final DateTime timestamp;

  SyncEvent({
    required this.type,
    required this.message,
    required this.timestamp,
  });
}

/// 枚举定义
enum SyncStatus {
  pending,
  syncing,
  synced,
  error,
}

enum SyncEventType {
  initialized,
  syncStarted,
  syncCompleted,
  incrementalSyncStarted,
  incrementalSyncCompleted,
  serviceSyncStarted,
  serviceSyncCompleted,
  error,
}
