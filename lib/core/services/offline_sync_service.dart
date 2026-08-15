import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

/// 同步状态枚举
enum SyncStatus {
  /// 空闲
  idle,

  /// 同步中
  syncing,

  /// 同步成功
  success,

  /// 同步失败
  failed,
}

/// 同步项
class SyncItem {
  /// 唯一标识
  final String id;

  /// 数据类型
  final String type;

  /// 数据内容
  final Map<String, dynamic> data;

  /// 创建时间
  final DateTime createdAt;

  /// 重试次数
  int retryCount;

  /// 最大重试次数
  static const int maxRetries = 3;

  SyncItem({
    required this.id,
    required this.type,
    required this.data,
    DateTime? createdAt,
    this.retryCount = 0,
  }) : createdAt = createdAt ?? DateTime.now();

  bool get canRetry => retryCount < maxRetries;

  Map<String, dynamic> toMap() => {
        'id': id,
        'type': type,
        'data': data,
        'created_at': createdAt.toIso8601String(),
        'retry_count': retryCount,
      };

  factory SyncItem.fromMap(Map<String, dynamic> map) => SyncItem(
        id: map['id'] as String,
        type: map['type'] as String,
        data: Map<String, dynamic>.from(map['data'] as Map),
        createdAt: DateTime.parse(map['created_at'] as String),
        retryCount: map['retry_count'] as int? ?? 0,
      );
}

/// 离线同步服务
class OfflineSyncService {
  static final OfflineSyncService _instance = OfflineSyncService._internal();

  factory OfflineSyncService() => _instance;

  OfflineSyncService._internal();

  final Connectivity _connectivity = Connectivity();
  final List<SyncItem> _syncQueue = [];
  final StreamController<SyncStatus> _statusController = StreamController<SyncStatus>.broadcast();

  SyncStatus _currentStatus = SyncStatus.idle;
  bool _isOnline = false;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  /// 获取同步状态流
  Stream<SyncStatus> get statusStream => _statusController.stream;

  /// 获取当前同步状态
  SyncStatus get currentStatus => _currentStatus;

  /// 是否在线
  bool get isOnline => _isOnline;

  /// 待同步项数量
  int get pendingCount => _syncQueue.length;

  /// 初始化服务
  Future<void> initialize() async {
    // 检查初始网络状态
    final result = await _connectivity.checkConnectivity();
    _isOnline = !result.contains(ConnectivityResult.none);

    // 监听网络状态变化
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen((results) {
      final wasOnline = _isOnline;
      _isOnline = !results.contains(ConnectivityResult.none);

      debugPrint('[OfflineSyncService] 网络状态变化: $_isOnline');

      // 从离线恢复到在线时，自动触发同步
      if (!wasOnline && _isOnline && _syncQueue.isNotEmpty) {
        syncAll();
      }
    });

    debugPrint('[OfflineSyncService] 服务已初始化，在线状态: $_isOnline');
  }

  /// 添加待同步项
  void addSyncItem(SyncItem item) {
    _syncQueue.add(item);
    debugPrint('[OfflineSyncService] 添加同步项: ${item.type} (${item.id})');

    // 如果在线，立即尝试同步
    if (_isOnline && _currentStatus == SyncStatus.idle) {
      syncAll();
    }
  }

  /// 同步所有待同步项
  Future<void> syncAll() async {
    if (_syncQueue.isEmpty) {
      debugPrint('[OfflineSyncService] 没有待同步项');
      return;
    }

    if (!_isOnline) {
      debugPrint('[OfflineSyncService] 离线状态，跳过同步');
      return;
    }

    if (_currentStatus == SyncStatus.syncing) {
      debugPrint('[OfflineSyncService] 正在同步中，跳过');
      return;
    }

    _updateStatus(SyncStatus.syncing);

    try {
      final itemsToSync = List<SyncItem>.from(_syncQueue);
      final failedItems = <SyncItem>[];

      for (final item in itemsToSync) {
        try {
          await _syncItem(item);
          _syncQueue.remove(item);
          debugPrint('[OfflineSyncService] 同步成功: ${item.type} (${item.id})');
        } catch (e) {
          debugPrint('[OfflineSyncService] 同步失败: ${item.type} (${item.id}), 错误: $e');
          item.retryCount++;

          if (item.canRetry) {
            failedItems.add(item);
          } else {
            _syncQueue.remove(item);
            debugPrint('[OfflineSyncService] 达到最大重试次数，移除: ${item.type} (${item.id})');
          }
        }
      }

      if (failedItems.isEmpty) {
        _updateStatus(SyncStatus.success);
      } else {
        _updateStatus(SyncStatus.failed);
      }
    } catch (e) {
      debugPrint('[OfflineSyncService] 同步过程出错: $e');
      _updateStatus(SyncStatus.failed);
    }
  }

  /// 同步单个项目（模拟实现）
  Future<void> _syncItem(SyncItem item) async {
    // 模拟网络请求延迟
    await Future.delayed(Duration(milliseconds: 100));

    // 这里应该实现实际的网络同步逻辑
    // 例如：调用 API 上传数据
    debugPrint('[OfflineSyncService] 正在同步: ${item.type}');
  }

  /// 清空同步队列
  void clearQueue() {
    _syncQueue.clear();
    debugPrint('[OfflineSyncService] 同步队列已清空');
  }

  /// 获取同步队列
  List<SyncItem> getSyncQueue() => List.unmodifiable(_syncQueue);

  /// 更新状态
  void _updateStatus(SyncStatus status) {
    _currentStatus = status;
    _statusController.add(status);
  }

  /// 释放资源
  void dispose() {
    _connectivitySubscription?.cancel();
    _statusController.close();
    debugPrint('[OfflineSyncService] 服务已释放');
  }
}

/// 全局离线同步服务实例
final offlineSyncService = OfflineSyncService();
