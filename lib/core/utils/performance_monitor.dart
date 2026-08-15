import 'package:flutter/foundation.dart';
import 'performance_optimizer.dart';

/// 性能监控助手 - 提供便捷的性能监控接口
class PerformanceMonitor {
  static final PerformanceOptimizer _optimizer = PerformanceOptimizer();
  static bool _isInitialized = false;

  /// 初始化性能监控
  static void initialize({VoidCallback? onPerformanceIssue}) {
    if (_isInitialized) return;
    _optimizer.initialize(onPerformanceIssue: onPerformanceIssue);
    _isInitialized = true;
    debugPrint('[PerformanceMonitor] Initialized');
  }

  /// 记录帧时间
  static void recordFrame(double frameTime) {
    _optimizer.recordFrameTime(frameTime);
  }

  /// 记录用户交互
  static void recordInteraction() {
    _optimizer.recordInteraction();
  }

  /// 注册动画Widget
  static void registerAnimation() {
    _optimizer.registerAnimatedWidget();
  }

  /// 注销动画Widget
  static void unregisterAnimation() {
    _optimizer.unregisterAnimatedWidget();
  }

  /// 获取性能统计
  static Map<String, dynamic> getStats() {
    return _optimizer.getPerformanceStats();
  }

  /// 获取优化建议
  static List<String> getSuggestions() {
    return _optimizer.getOptimizationSuggestions();
  }

  /// 应用优化
  static void applyOptimizations() {
    _optimizer.applyOptimizations();
  }

  /// 获取当前FPS
  static double getCurrentFPS() {
    final stats = _optimizer.getPerformanceStats();
    if (stats['status'] == 'no_data') return 0.0;

    final avgFrameTime = stats['avgFrameTime'] as double? ?? 16.67;
    if (avgFrameTime == 0) return 60.0;

    return 1000.0 / avgFrameTime;
  }

  /// 获取掉帧率
  static double getDroppedFrameRate() {
    final stats = _optimizer.getPerformanceStats();
    if (stats['status'] == 'no_data') return 0.0;

    return stats['droppedFrameRate'] as double? ?? 0.0;
  }

  /// 是否有性能问题
  static bool hasPerformanceIssue() {
    final droppedRate = getDroppedFrameRate();
    return droppedRate > 0.15; // 掉帧率超过15%
  }

  /// 获取性能等级 (A/B/C/D/F)
  static String getPerformanceGrade() {
    final fps = getCurrentFPS();

    if (fps >= 55) return 'A'; // 优秀
    if (fps >= 45) return 'B'; // 良好
    if (fps >= 35) return 'C'; // 一般
    if (fps >= 25) return 'D'; // 较差
    return 'F'; // 很差
  }

  /// 获取性能报告
  static Map<String, dynamic> getPerformanceReport() {
    final stats = getStats();
    final fps = getCurrentFPS();
    final grade = getPerformanceGrade();
    final suggestions = getSuggestions();

    return {
      'fps': fps,
      'grade': grade,
      'droppedFrameRate': getDroppedFrameRate(),
      'hasIssue': hasPerformanceIssue(),
      'suggestions': suggestions,
      'stats': stats,
    };
  }

  /// 停止监控
  static void stop() {
    _optimizer.stopMonitoring();
  }

  /// 清理资源
  static void dispose() {
    _optimizer.dispose();
    _isInitialized = false;
  }
}

/// 性能监控Widget Mixin
mixin PerformanceMonitorMixin {
  /// 在Widget挂载时注册
  void registerPerformanceMonitoring() {
    PerformanceMonitor.registerAnimation();
  }

  /// 在Widget卸载时注销
  void unregisterPerformanceMonitoring() {
    PerformanceMonitor.unregisterAnimation();
  }

  /// 记录交互
  void recordUserInteraction() {
    PerformanceMonitor.recordInteraction();
  }
}
