import 'package:flutter/foundation.dart';
import '../utils/performance_optimizer.dart';
import '../services/analytics_service.dart';
import '../models/analytics_event.dart';

/// 性能监控服务
/// 提供应用级别的性能监控和报告功能
class PerformanceMonitor {
  static final PerformanceMonitor _instance = PerformanceMonitor._internal();
  factory PerformanceMonitor() => _instance;
  PerformanceMonitor._internal();

  final PerformanceOptimizer _optimizer = PerformanceOptimizer();
  AnalyticsService? _mockAnalytics;
  late final AnalyticsService _defaultAnalytics = AnalyticsService();

  AnalyticsService get _analytics => _mockAnalytics ?? _defaultAnalytics;

  /// 设置模拟的分析服务（用于测试）
  void setMockAnalytics(AnalyticsService? mock) {
    _mockAnalytics = mock;
  }

  bool _isInitialized = false;
  DateTime? _sessionStartTime;
  int _totalInteractions = 0;
  final Map<String, int> _pageViewCounts = {};
  final Map<String, double> _pageLoadTimes = {};

  /// 初始化性能监控
  void initialize() {
    if (_isInitialized) return;

    _sessionStartTime = DateTime.now();
    _optimizer.initialize(
      onPerformanceIssue: _handlePerformanceIssue,
    );

    _isInitialized = true;
    debugPrint('[PerformanceMonitor] Initialized');
  }

  /// 处理性能问题
  void _handlePerformanceIssue() {
    final stats = _optimizer.getPerformanceStats();
    _analytics.trackEvent(
      'performance_issue',
      properties: {
        'avg_frame_time': stats['avgFrameTime'],
        'dropped_frame_rate': stats['droppedFrameRate'],
        'animated_widget_count': _optimizer.animatedWidgetCount,
      },
    );
  }

  /// 记录页面加载时间
  void recordPageLoad(String pageName, Duration loadTime) {
    _pageLoadTimes[pageName] = loadTime.inMilliseconds.toDouble();
    _pageViewCounts[pageName] = (_pageViewCounts[pageName] ?? 0) + 1;

    _analytics.trackEvent(
      'page_load',
      properties: {
        'page_name': pageName,
        'load_time_ms': loadTime.inMilliseconds,
      },
    );
  }

  /// 记录用户交互
  void recordInteraction(String interactionType) {
    _totalInteractions++;
    _optimizer.recordInteraction();

    if (_totalInteractions % 50 == 0) {
      // 每50次交互报告一次
      _reportInteractionMetrics();
    }
  }

  /// 报告交互指标
  void _reportInteractionMetrics() {
    final sessionDuration = _sessionStartTime != null
        ? DateTime.now().difference(_sessionStartTime!).inSeconds
        : 0;

    _analytics.trackEvent(
      'interaction_metrics',
      properties: {
        'total_interactions': _totalInteractions,
        'session_duration_seconds': sessionDuration,
        'interactions_per_minute':
            sessionDuration > 0 ? (_totalInteractions / sessionDuration * 60) : 0,
      },
    );
  }

  /// 开始性能追踪
  PerformanceTracker startTracking(String operationName) {
    return PerformanceTracker(operationName, this);
  }

  /// 记录操作完成
  void _recordOperation(String operationName, Duration duration) {
    _analytics.trackEvent(
      'operation_performance',
      properties: {
        'operation': operationName,
        'duration_ms': duration.inMilliseconds,
      },
    );
  }

  /// 获取性能报告
  PerformanceReport getReport() {
    final stats = _optimizer.getPerformanceStats();
    final sessionDuration = _sessionStartTime != null
        ? DateTime.now().difference(_sessionStartTime!)
        : Duration.zero;

    return PerformanceReport(
      sessionDuration: sessionDuration,
      totalInteractions: _totalInteractions,
      avgFrameTime: stats['avgFrameTime'] ?? 0,
      droppedFrameRate: stats['droppedFrameRate'] ?? 0,
      pageViewCounts: Map.from(_pageViewCounts),
      pageLoadTimes: Map.from(_pageLoadTimes),
      animatedWidgetCount: _optimizer.animatedWidgetCount,
      suggestions: _optimizer.getOptimizationSuggestions(),
    );
  }

  /// 发送性能报告
  Future<void> sendReport() async {
    final report = getReport();

    await _analytics.trackEvent(
      'performance_report',
      properties: report.toMap(),
    );

    debugPrint('[PerformanceMonitor] Report sent: ${report.toMap()}');
  }

  /// 重置监控数据
  void reset() {
    _sessionStartTime = DateTime.now();
    _totalInteractions = 0;
    _pageViewCounts.clear();
    _pageLoadTimes.clear();
  }

  /// 清理资源
  void dispose() {
    _optimizer.dispose();
    _isInitialized = false;
  }
}

/// 性能追踪器
class PerformanceTracker {
  final String operationName;
  final PerformanceMonitor monitor;
  final DateTime startTime;

  PerformanceTracker(this.operationName, this.monitor)
      : startTime = DateTime.now();

  /// 结束追踪
  void end() {
    final duration = DateTime.now().difference(startTime);
    monitor._recordOperation(operationName, duration);
  }
}

/// 性能报告
class PerformanceReport {
  final Duration sessionDuration;
  final int totalInteractions;
  final double avgFrameTime;
  final double droppedFrameRate;
  final Map<String, int> pageViewCounts;
  final Map<String, double> pageLoadTimes;
  final int animatedWidgetCount;
  final List<String> suggestions;

  PerformanceReport({
    required this.sessionDuration,
    required this.totalInteractions,
    required this.avgFrameTime,
    required this.droppedFrameRate,
    required this.pageViewCounts,
    required this.pageLoadTimes,
    required this.animatedWidgetCount,
    required this.suggestions,
  });

  /// 转换为Map
  Map<String, dynamic> toMap() {
    return {
      'session_duration_seconds': sessionDuration.inSeconds,
      'total_interactions': totalInteractions,
      'avg_frame_time': avgFrameTime,
      'dropped_frame_rate': droppedFrameRate,
      'page_view_counts': pageViewCounts,
      'page_load_times': pageLoadTimes,
      'animated_widget_count': animatedWidgetCount,
      'suggestions': suggestions,
      'interactions_per_minute': sessionDuration.inSeconds > 0
          ? (totalInteractions / sessionDuration.inSeconds * 60)
          : 0,
    };
  }

  /// 从Map创建
  factory PerformanceReport.fromMap(Map<String, dynamic> map) {
    return PerformanceReport(
      sessionDuration: Duration(seconds: map['session_duration_seconds'] as int),
      totalInteractions: map['total_interactions'] as int,
      avgFrameTime: (map['avg_frame_time'] as num).toDouble(),
      droppedFrameRate: (map['dropped_frame_rate'] as num).toDouble(),
      pageViewCounts: Map<String, int>.from(map['page_view_counts'] as Map),
      pageLoadTimes: Map<String, double>.from(map['page_load_times'] as Map),
      animatedWidgetCount: map['animated_widget_count'] as int,
      suggestions: List<String>.from(map['suggestions'] as List),
    );
  }

  @override
  String toString() {
    return 'PerformanceReport('
        'sessionDuration: ${sessionDuration.inSeconds}s, '
        'totalInteractions: $totalInteractions, '
        'avgFrameTime: ${avgFrameTime.toStringAsFixed(2)}ms, '
        'droppedFrameRate: ${(droppedFrameRate * 100).toStringAsFixed(1)}%'
        ')';
  }
}
