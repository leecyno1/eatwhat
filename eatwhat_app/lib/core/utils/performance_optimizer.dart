import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

/// 性能优化工具类
class PerformanceOptimizer {
  static const int _targetFPS = 60;
  static const Duration _frameInterval = Duration(microseconds: 16667); // ~60 FPS
  
  /// 防抖动通知器
  /// 用于减少频繁的 notifyListeners 调用
  static class DebouncedNotifier extends ChangeNotifier {
    Timer? _debounceTimer;
    final Duration _debounceDuration;
    bool _hasPendingNotification = false;
    
    DebouncedNotifier({Duration debounceDuration = const Duration(milliseconds: 16)})
        : _debounceDuration = debounceDuration;
    
    /// 防抖动通知
    void debouncedNotify() {
      if (_debounceTimer?.isActive ?? false) {
        _hasPendingNotification = true;
        return;
      }
      
      _debounceTimer = Timer(_debounceDuration, () {
        if (_hasPendingNotification) {
          _hasPendingNotification = false;
          notifyListeners();
        }
      });
      
      notifyListeners();
    }
    
    /// 立即通知（用于重要更新）
    void immediateNotify() {
      _debounceTimer?.cancel();
      _hasPendingNotification = false;
      notifyListeners();
    }
    
    @override
    void dispose() {
      _debounceTimer?.cancel();
      super.dispose();
    }
  }
  
  /// 帧率限制器
  /// 用于控制动画和物理更新的频率
  static class FrameRateLimiter {
    DateTime _lastUpdate = DateTime.now();
    final Duration _minInterval;
    
    FrameRateLimiter({Duration? minInterval}) 
        : _minInterval = minInterval ?? _frameInterval;
    
    /// 检查是否应该执行更新
    bool shouldUpdate() {
      final now = DateTime.now();
      if (now.difference(_lastUpdate) >= _minInterval) {
        _lastUpdate = now;
        return true;
      }
      return false;
    }
    
    /// 重置计时器
    void reset() {
      _lastUpdate = DateTime.now();
    }
  }
  
  /// 对象池管理器
  /// 用于重用对象，减少GC压力
  static class ObjectPool<T> {
    final List<T> _pool = [];
    final T Function() _factory;
    final void Function(T)? _reset;
    final int _maxSize;
    
    ObjectPool({
      required T Function() factory,
      void Function(T)? reset,
      int maxSize = 50,
    }) : _factory = factory, _reset = reset, _maxSize = maxSize;
    
    /// 获取对象
    T acquire() {
      if (_pool.isNotEmpty) {
        final obj = _pool.removeLast();
        _reset?.call(obj);
        return obj;
      }
      return _factory();
    }
    
    /// 释放对象
    void release(T obj) {
      if (_pool.length < _maxSize) {
        _pool.add(obj);
      }
    }
    
    /// 清空池
    void clear() {
      _pool.clear();
    }
  }
  
  /// 批量更新管理器
  /// 用于批量处理多个更新操作
  static class BatchUpdateManager {
    final List<VoidCallback> _pendingUpdates = [];
    Timer? _batchTimer;
    final Duration _batchInterval;
    
    BatchUpdateManager({Duration batchInterval = const Duration(milliseconds: 16)})
        : _batchInterval = batchInterval;
    
    /// 添加更新操作
    void addUpdate(VoidCallback update) {
      _pendingUpdates.add(update);
      
      if (_batchTimer?.isActive != true) {
        _batchTimer = Timer(_batchInterval, _processBatch);
      }
    }
    
    /// 处理批量更新
    void _processBatch() {
      if (_pendingUpdates.isEmpty) return;
      
      // 执行所有待处理的更新
      for (final update in _pendingUpdates) {
        try {
          update();
        } catch (e) {
          if (kDebugMode) {
            print('Error in batch update: $e');
          }
        }
      }
      
      _pendingUpdates.clear();
    }
    
    /// 立即处理所有待处理的更新
    void flush() {
      _batchTimer?.cancel();
      _processBatch();
    }
    
    void dispose() {
      _batchTimer?.cancel();
      _pendingUpdates.clear();
    }
  }
  
  /// 内存使用监控器
  static class MemoryMonitor {
    static Timer? _monitorTimer;
    static int _lastUsedMemory = 0;
    
    /// 开始监控内存使用
    static void startMonitoring({Duration interval = const Duration(seconds: 5)}) {
      if (!kDebugMode) return;
      
      _monitorTimer?.cancel();
      _monitorTimer = Timer.periodic(interval, (timer) {
        // 在debug模式下监控内存使用
        final currentMemory = _getCurrentMemoryUsage();
        if (currentMemory > _lastUsedMemory * 1.2) {
          print('Memory usage increased significantly: ${currentMemory}MB');
        }
        _lastUsedMemory = currentMemory;
      });
    }
    
    /// 停止监控
    static void stopMonitoring() {
      _monitorTimer?.cancel();
      _monitorTimer = null;
    }
    
    /// 获取当前内存使用量（简化版本）
    static int _getCurrentMemoryUsage() {
      // 这里可以使用更精确的内存监控方法
      // 目前返回一个模拟值
      return DateTime.now().millisecondsSinceEpoch % 1000;
    }
  }
  
  /// 性能分析器
  static class PerformanceProfiler {
    static final Map<String, DateTime> _startTimes = {};
    static final Map<String, List<Duration>> _durations = {};
    
    static void startTiming(String key) {
      _startTimes[key] = DateTime.now();
    }
    
    static void endTiming(String key) {
      final startTime = _startTimes[key];
      if (startTime != null) {
        final duration = DateTime.now().difference(startTime);
        _durations.putIfAbsent(key, () => []).add(duration);
        _startTimes.remove(key);
      }
    }
    
    static Map<String, double> getAverageTimings() {
      final result = <String, double>{};
      _durations.forEach((key, durations) {
        final totalMs = durations.fold<int>(0, (sum, d) => sum + d.inMicroseconds) / 1000.0;
        result[key] = totalMs / durations.length;
      });
      return result;
    }
    
    static void clearTimings() {
      _startTimes.clear();
      _durations.clear();
    }
  }
  
  /// 优化的构建器组件
  static class OptimizedBuilder extends StatefulWidget {
    final Widget Function(BuildContext context) builder;
    final bool Function(Widget? oldWidget, Widget? newWidget)? shouldRebuild;
    
    const OptimizedBuilder({
      Key? key,
      required this.builder,
      this.shouldRebuild,
    }) : super(key: key);
    
    @override
    State<OptimizedBuilder> createState() => _OptimizedBuilderState();
  }
  
  static class _OptimizedBuilderState extends State<OptimizedBuilder> {
    Widget? _cachedWidget;
    Widget? _previousWidget;
    
    @override
    Widget build(BuildContext context) {
      final currentWidget = widget;
      
      // 检查是否需要重建
      bool shouldRebuild = true;
      if (widget.shouldRebuild != null && _previousWidget != null) {
        shouldRebuild = widget.shouldRebuild!(_previousWidget, currentWidget);
      }
      
      if (shouldRebuild || _cachedWidget == null) {
        _cachedWidget = widget.builder(context);
        _previousWidget = currentWidget;
      }
      
      return _cachedWidget!;
    }
  }
}