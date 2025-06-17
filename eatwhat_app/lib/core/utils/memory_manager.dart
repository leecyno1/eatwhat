import 'dart:async';
import 'dart:collection';
import 'dart:developer' as developer;
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

/// 内存管理器
class MemoryManager {
  static final MemoryManager _instance = MemoryManager._internal();
  factory MemoryManager() => _instance;
  MemoryManager._internal();
  
  // 图片缓存管理
  final Map<String, ImageProvider> _imageCache = {};
  final Queue<String> _imageCacheOrder = Queue<String>();
  static const int _maxImageCacheSize = 50;
  
  // 数据缓存管理
  final Map<String, dynamic> _dataCache = {};
  final Map<String, DateTime> _dataCacheTimestamps = {};
  final Queue<String> _dataCacheOrder = Queue<String>();
  static const int _maxDataCacheSize = 100;
  static const Duration _dataCacheExpiry = Duration(minutes: 10);
  
  // 定时器管理
  final Set<Timer> _activeTimers = {};
  
  // 监听器管理
  final Map<String, List<VoidCallback>> _listeners = {};
  
  // 内存监控
  Timer? _memoryMonitorTimer;
  final List<int> _memoryUsageHistory = [];
  static const int _maxMemoryHistorySize = 60; // 保存60个采样点
  
  /// 初始化内存管理器
  void initialize() {
    if (kDebugMode) {
      _startMemoryMonitoring();
    }
    
    // 定期清理过期缓存
    _schedulePeriodicCleanup();
  }
  
  /// 开始内存监控
  void _startMemoryMonitoring() {
    _memoryMonitorTimer = Timer.periodic(
      const Duration(seconds: 5),
      (timer) => _recordMemoryUsage(),
    );
  }
  
  /// 记录内存使用情况
  void _recordMemoryUsage() {
    if (!kDebugMode) return;
    
    try {
      final info = developer.Service.getIsolateMemoryUsage();
      info.then((usage) {
        if (usage != null) {
          final memoryMB = (usage['heapUsage'] as int?) ?? 0;
          _memoryUsageHistory.add(memoryMB);
          
          // 保持历史记录大小
          if (_memoryUsageHistory.length > _maxMemoryHistorySize) {
            _memoryUsageHistory.removeAt(0);
          }
          
          // 如果内存使用过高，触发清理
          if (memoryMB > 100 * 1024 * 1024) { // 100MB
            _performEmergencyCleanup();
          }
        }
      }).catchError((error) {
        // 忽略内存监控错误
      });
    } catch (e) {
      // 忽略内存监控错误
    }
  }
  
  /// 缓存图片
  void cacheImage(String key, ImageProvider image) {
    // 如果缓存已满，移除最旧的项
    if (_imageCache.length >= _maxImageCacheSize) {
      final oldestKey = _imageCacheOrder.removeFirst();
      _imageCache.remove(oldestKey);
    }
    
    _imageCache[key] = image;
    _imageCacheOrder.add(key);
  }
  
  /// 获取缓存的图片
  ImageProvider? getCachedImage(String key) {
    final image = _imageCache[key];
    if (image != null) {
      // 更新访问顺序
      _imageCacheOrder.remove(key);
      _imageCacheOrder.add(key);
    }
    return image;
  }
  
  /// 缓存数据
  void cacheData(String key, dynamic data, {Duration? expiry}) {
    // 如果缓存已满，移除最旧的项
    if (_dataCache.length >= _maxDataCacheSize) {
      final oldestKey = _dataCacheOrder.removeFirst();
      _dataCache.remove(oldestKey);
      _dataCacheTimestamps.remove(oldestKey);
    }
    
    _dataCache[key] = data;
    _dataCacheTimestamps[key] = DateTime.now();
    _dataCacheOrder.add(key);
  }
  
  /// 获取缓存的数据
  T? getCachedData<T>(String key) {
    final timestamp = _dataCacheTimestamps[key];
    if (timestamp == null) return null;
    
    // 检查是否过期
    if (DateTime.now().difference(timestamp) > _dataCacheExpiry) {
      _dataCache.remove(key);
      _dataCacheTimestamps.remove(key);
      _dataCacheOrder.remove(key);
      return null;
    }
    
    final data = _dataCache[key];
    if (data != null) {
      // 更新访问顺序
      _dataCacheOrder.remove(key);
      _dataCacheOrder.add(key);
    }
    
    return data as T?;
  }
  
  /// 注册定时器
  void registerTimer(Timer timer) {
    _activeTimers.add(timer);
  }
  
  /// 取消定时器
  void cancelTimer(Timer timer) {
    timer.cancel();
    _activeTimers.remove(timer);
  }
  
  /// 取消所有定时器
  void cancelAllTimers() {
    for (final timer in _activeTimers) {
      timer.cancel();
    }
    _activeTimers.clear();
  }
  
  /// 添加监听器
  void addListener(String key, VoidCallback listener) {
    _listeners.putIfAbsent(key, () => []).add(listener);
  }
  
  /// 移除监听器
  void removeListener(String key, VoidCallback listener) {
    _listeners[key]?.remove(listener);
    if (_listeners[key]?.isEmpty == true) {
      _listeners.remove(key);
    }
  }
  
  /// 移除所有监听器
  void removeAllListeners(String key) {
    _listeners.remove(key);
  }
  
  /// 通知监听器
  void notifyListeners(String key) {
    final listeners = _listeners[key];
    if (listeners != null) {
      for (final listener in List.from(listeners)) {
        try {
          listener();
        } catch (e) {
          // 忽略监听器错误
        }
      }
    }
  }
  
  /// 定期清理
  void _schedulePeriodicCleanup() {
    final timer = Timer.periodic(
      const Duration(minutes: 5),
      (timer) => _performRoutineCleanup(),
    );
    registerTimer(timer);
  }
  
  /// 常规清理
  void _performRoutineCleanup() {
    _cleanupExpiredData();
    _cleanupUnusedImages();
    
    if (kDebugMode) {
      _logMemoryUsage();
    }
  }
  
  /// 紧急清理
  void _performEmergencyCleanup() {
    if (kDebugMode) {
      print('MemoryManager: Performing emergency cleanup due to high memory usage');
    }
    
    // 清理所有缓存
    clearAllCaches();
    
    // 强制垃圾回收
    _forceGarbageCollection();
  }
  
  /// 清理过期数据
  void _cleanupExpiredData() {
    final now = DateTime.now();
    final expiredKeys = <String>[];
    
    _dataCacheTimestamps.forEach((key, timestamp) {
      if (now.difference(timestamp) > _dataCacheExpiry) {
        expiredKeys.add(key);
      }
    });
    
    for (final key in expiredKeys) {
      _dataCache.remove(key);
      _dataCacheTimestamps.remove(key);
      _dataCacheOrder.remove(key);
    }
  }
  
  /// 清理未使用的图片
  void _cleanupUnusedImages() {
    // 如果图片缓存使用率超过80%，清理最旧的20%
    if (_imageCache.length > _maxImageCacheSize * 0.8) {
      final cleanupCount = (_maxImageCacheSize * 0.2).round();
      for (int i = 0; i < cleanupCount && _imageCacheOrder.isNotEmpty; i++) {
        final oldestKey = _imageCacheOrder.removeFirst();
        _imageCache.remove(oldestKey);
      }
    }
  }
  
  /// 强制垃圾回收
  void _forceGarbageCollection() {
    // 在Flutter中，我们无法直接触发GC，但可以清理引用
    // 这有助于减少内存压力
  }
  
  /// 记录内存使用情况
  void _logMemoryUsage() {
    if (_memoryUsageHistory.isNotEmpty) {
      final currentUsage = _memoryUsageHistory.last;
      final avgUsage = _memoryUsageHistory.reduce((a, b) => a + b) / _memoryUsageHistory.length;
      
      print('MemoryManager: Current: ${(currentUsage / 1024 / 1024).toStringAsFixed(1)}MB, '
            'Average: ${(avgUsage / 1024 / 1024).toStringAsFixed(1)}MB, '
            'Image Cache: ${_imageCache.length}/${_maxImageCacheSize}, '
            'Data Cache: ${_dataCache.length}/${_maxDataCacheSize}');
    }
  }
  
  /// 清理所有缓存
  void clearAllCaches() {
    _imageCache.clear();
    _imageCacheOrder.clear();
    _dataCache.clear();
    _dataCacheTimestamps.clear();
    _dataCacheOrder.clear();
  }
  
  /// 清理图片缓存
  void clearImageCache() {
    _imageCache.clear();
    _imageCacheOrder.clear();
  }
  
  /// 清理数据缓存
  void clearDataCache() {
    _dataCache.clear();
    _dataCacheTimestamps.clear();
    _dataCacheOrder.clear();
  }
  
  /// 获取内存统计信息
  Map<String, dynamic> getMemoryStats() {
    return {
      'image_cache_size': _imageCache.length,
      'image_cache_max': _maxImageCacheSize,
      'data_cache_size': _dataCache.length,
      'data_cache_max': _maxDataCacheSize,
      'active_timers': _activeTimers.length,
      'listeners_count': _listeners.values.fold<int>(0, (sum, list) => sum + list.length),
      'memory_history_size': _memoryUsageHistory.length,
      'current_memory_mb': _memoryUsageHistory.isNotEmpty 
          ? (_memoryUsageHistory.last / 1024 / 1024).toStringAsFixed(1)
          : 'N/A',
    };
  }
  
  /// 释放资源
  void dispose() {
    _memoryMonitorTimer?.cancel();
    cancelAllTimers();
    clearAllCaches();
    _listeners.clear();
    _memoryUsageHistory.clear();
  }
}

/// 内存管理混入
mixin MemoryManagementMixin {
  final MemoryManager _memoryManager = MemoryManager();
  
  /// 缓存数据
  void cacheData(String key, dynamic data) {
    _memoryManager.cacheData(key, data);
  }
  
  /// 获取缓存数据
  T? getCachedData<T>(String key) {
    return _memoryManager.getCachedData<T>(key);
  }
  
  /// 注册定时器
  void registerTimer(Timer timer) {
    _memoryManager.registerTimer(timer);
  }
  
  /// 取消定时器
  void cancelTimer(Timer timer) {
    _memoryManager.cancelTimer(timer);
  }
  
  /// 添加监听器
  void addManagedListener(String key, VoidCallback listener) {
    _memoryManager.addListener(key, listener);
  }
  
  /// 移除监听器
  void removeManagedListener(String key, VoidCallback listener) {
    _memoryManager.removeListener(key, listener);
  }
  
  /// 清理资源
  void cleanupMemory() {
    // 子类可以重写此方法来清理特定资源
  }
}