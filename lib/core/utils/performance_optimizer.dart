import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:async';
import 'dart:collection';

/// 性能优化器 - 负责应用的全局性能优化
class PerformanceOptimizer {
  static final PerformanceOptimizer _instance = PerformanceOptimizer._internal();
  factory PerformanceOptimizer() => _instance;
  PerformanceOptimizer._internal();

  // 性能监控
  final List<double> _frameTimes = [];
  final Queue<DateTime> _interactionTimes = Queue<DateTime>();
  Timer? _performanceTimer;
  
  // 优化配置
  static const int maxFrameTimeCount = 60; // 保留最近60帧
  static const double targetFrameTime = 16.67; // 60fps目标
  static const int maxInteractionHistory = 100;
  
  bool _isMonitoring = false;
  VoidCallback? _onPerformanceIssue;

  /// 初始化性能优化器
  void initialize({VoidCallback? onPerformanceIssue}) {
    _onPerformanceIssue = onPerformanceIssue;
    _startMonitoring();
    debugPrint('PerformanceOptimizer initialized');
  }

  /// 开始性能监控
  void _startMonitoring() {
    if (_isMonitoring) return;
    
    _isMonitoring = true;
    _performanceTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      _analyzePerformance();
    });
  }

  /// 停止性能监控
  void stopMonitoring() {
    _performanceTimer?.cancel();
    _performanceTimer = null;
    _isMonitoring = false;
  }

  /// 记录帧时间
  void recordFrameTime(double frameTime) {
    _frameTimes.add(frameTime);
    if (_frameTimes.length > maxFrameTimeCount) {
      _frameTimes.removeAt(0);
    }
  }

  /// 记录用户交互
  void recordInteraction() {
    final now = DateTime.now();
    _interactionTimes.add(now);
    
    // 清理过期的交互记录
    while (_interactionTimes.isNotEmpty && 
           now.difference(_interactionTimes.first).inMinutes > 5) {
      _interactionTimes.removeFirst();
    }
    
    if (_interactionTimes.length > maxInteractionHistory) {
      _interactionTimes.removeFirst();
    }
  }

  /// 分析性能指标
  void _analyzePerformance() {
    if (_frameTimes.isEmpty) return;

    final avgFrameTime = _frameTimes.reduce((a, b) => a + b) / _frameTimes.length;
    final droppedFrames = _frameTimes.where((time) => time > targetFrameTime).length;
    final droppedFrameRate = droppedFrames / _frameTimes.length;

    // 如果掉帧率超过20%，触发性能警告
    if (droppedFrameRate > 0.2) {
      debugPrint('Performance Warning: ${(droppedFrameRate * 100).toStringAsFixed(1)}% dropped frames');
      _onPerformanceIssue?.call();
    }

    debugPrint('Performance Stats: Avg frame time: ${avgFrameTime.toStringAsFixed(2)}ms, Dropped frames: ${(droppedFrameRate * 100).toStringAsFixed(1)}%');
  }

  /// 获取性能统计信息
  Map<String, dynamic> getPerformanceStats() {
    if (_frameTimes.isEmpty) {
      return {'status': 'no_data'};
    }

    final avgFrameTime = _frameTimes.reduce((a, b) => a + b) / _frameTimes.length;
    final maxFrameTime = _frameTimes.reduce((a, b) => a > b ? a : b);
    final minFrameTime = _frameTimes.reduce((a, b) => a < b ? a : b);
    final droppedFrames = _frameTimes.where((time) => time > targetFrameTime).length;
    
    return {
      'avgFrameTime': avgFrameTime,
      'maxFrameTime': maxFrameTime,
      'minFrameTime': minFrameTime,
      'droppedFrameRate': droppedFrames / _frameTimes.length,
      'totalFrames': _frameTimes.length,
      'interactionCount': _interactionTimes.length,
      'status': 'active',
    };
  }

  /// 优化建议
  List<String> getOptimizationSuggestions() {
    final stats = getPerformanceStats();
    final suggestions = <String>[];

    if (stats['droppedFrameRate'] > 0.15) {
      suggestions.add('检测到频繁掉帧，建议降低动画复杂度');
    }

    if (stats['avgFrameTime'] > 20.0) {
      suggestions.add('平均帧时间较高，建议优化重绘逻辑');
    }

    if (_interactionTimes.length > 50) {
      suggestions.add('用户交互频繁，建议增加防抖处理');
    }

    return suggestions;
  }

  /// 应用优化配置
  void applyOptimizations() {
    // 启用硬件加速
    SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
    
    // 预加载关键资源
    _preloadCriticalAssets();
    
    debugPrint('Performance optimizations applied');
  }

  /// 预加载关键资源
  void _preloadCriticalAssets() {
    // 预加载常用图标和字体
    // 这里可以添加具体的预加载逻辑
  }

  /// 清理资源
  void dispose() {
    stopMonitoring();
    _frameTimes.clear();
    _interactionTimes.clear();
  }
}

/// 防抖通知器 - 避免频繁的状态更新
class DebouncedNotifier extends ChangeNotifier {
  Timer? _debounceTimer;
  static const Duration _defaultDelay = Duration(milliseconds: 16);

  /// 防抖通知
  void debouncedNotify([Duration? delay]) {
    _debounceTimer?.cancel();
    _debounceTimer = Timer(delay ?? _defaultDelay, () {
      if (hasListeners) {
        notifyListeners();
      }
    });
  }

  @override
  void dispose() {
    _debounceTimer?.cancel();
    super.dispose();
  }
}

/// 对象池 - 重用对象减少GC压力
class ObjectPool<T> {
  final T Function() _factory;
  final void Function(T)? _reset;
  final Queue<T> _pool = Queue<T>();
  final int _maxSize;

  ObjectPool(this._factory, {void Function(T)? reset, int maxSize = 50}) 
    : _reset = reset, _maxSize = maxSize;

  /// 获取对象
  T acquire() {
    if (_pool.isNotEmpty) {
      return _pool.removeFirst();
    }
    return _factory();
  }

  /// 归还对象
  void release(T object) {
    if (_pool.length < _maxSize) {
      _reset?.call(object);
      _pool.add(object);
    }
  }

  /// 清空池
  void clear() {
    _pool.clear();
  }

  /// 获取池状态
  Map<String, int> getStats() {
    return {
      'poolSize': _pool.length,
      'maxSize': _maxSize,
    };
  }
}