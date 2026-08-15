import 'package:flutter_test/flutter_test.dart';
import 'package:eatwhat_app/core/services/performance_monitor.dart';
import '../../../test/core/services/mock_analytics_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PerformanceMonitor', () {
    late PerformanceMonitor monitor;
    late MockAnalyticsService mockAnalytics;

    setUp(() {
      monitor = PerformanceMonitor();
      mockAnalytics = MockAnalyticsService();
      monitor.setMockAnalytics(mockAnalytics);
      monitor.initialize();
    });

    tearDown(() {
      monitor.setMockAnalytics(null);
      monitor.dispose();
      monitor.reset();
    });

    test('应该是单例模式', () {
      final instance1 = PerformanceMonitor();
      final instance2 = PerformanceMonitor();
      expect(instance1, equals(instance2));
    });

    test('应该能记录页面加载时间', () {
      monitor.recordPageLoad('home_page', Duration(milliseconds: 500));
      monitor.recordPageLoad('detail_page', Duration(milliseconds: 300));

      final report = monitor.getReport();
      expect(report.pageLoadTimes['home_page'], equals(500.0));
      expect(report.pageLoadTimes['detail_page'], equals(300.0));
    });

    test('应该能记录页面访问次数', () {
      monitor.recordPageLoad('home_page', Duration(milliseconds: 100));
      monitor.recordPageLoad('home_page', Duration(milliseconds: 100));
      monitor.recordPageLoad('home_page', Duration(milliseconds: 100));

      final report = monitor.getReport();
      expect(report.pageViewCounts['home_page'], equals(3));
    });

    test('应该能记录用户交互', () {
      monitor.recordInteraction('button_click');
      monitor.recordInteraction('swipe');
      monitor.recordInteraction('tap');

      final report = monitor.getReport();
      expect(report.totalInteractions, equals(3));
    });

    test('应该能开始和结束性能追踪', () async {
      final tracker = monitor.startTracking('data_fetch');
      await Future.delayed(Duration(milliseconds: 10));
      tracker.end();

      // 追踪应该完成
      expect(tracker.operationName, equals('data_fetch'));
    });

    test('应该能生成性能报告', () {
      monitor.recordPageLoad('page1', Duration(milliseconds: 200));
      monitor.recordInteraction('click');

      final report = monitor.getReport();
      expect(report, isNotNull);
      expect(report.totalInteractions, equals(1));
      expect(report.pageViewCounts['page1'], equals(1));
    });

    test('应该能重置监控数据', () {
      monitor.recordPageLoad('page1', Duration(milliseconds: 200));
      monitor.recordInteraction('click');

      monitor.reset();

      final report = monitor.getReport();
      expect(report.totalInteractions, equals(0));
      expect(report.pageViewCounts.isEmpty, true);
      expect(report.pageLoadTimes.isEmpty, true);
    });

    test('应该能计算每分钟交互次数', () async {
      // 记录一些交互
      for (int i = 0; i < 10; i++) {
        monitor.recordInteraction('test');
      }

      // 等待至少1秒以确保sessionDuration > 0
      await Future.delayed(Duration(seconds: 1, milliseconds: 100));

      final report = monitor.getReport();
      final interactionsPerMinute = report.toMap()['interactions_per_minute'];
      // 应该大于0（10次交互在1秒内，约等于600次/分钟）
      expect(interactionsPerMinute, greaterThan(0));
    });
  });

  group('PerformanceTracker', () {
    late PerformanceMonitor monitor;
    late MockAnalyticsService mockAnalytics;

    setUp(() {
      monitor = PerformanceMonitor();
      mockAnalytics = MockAnalyticsService();
      monitor.setMockAnalytics(mockAnalytics);
      monitor.initialize();
    });

    tearDown(() {
      monitor.setMockAnalytics(null);
      monitor.dispose();
    });

    test('应该能追踪操作时长', () async {
      final tracker = monitor.startTracking('test_operation');
      expect(tracker.operationName, equals('test_operation'));

      await Future.delayed(Duration(milliseconds: 50));
      tracker.end();

      // 操作应该被记录
    });

    test('应该能追踪多个操作', () async {
      final tracker1 = monitor.startTracking('operation1');
      final tracker2 = monitor.startTracking('operation2');

      await Future.delayed(Duration(milliseconds: 10));

      tracker1.end();
      tracker2.end();

      // 两个操作都应该被记录
    });
  });

  group('PerformanceReport', () {
    test('应该能创建性能报告', () {
      final report = PerformanceReport(
        sessionDuration: Duration(seconds: 60),
        totalInteractions: 10,
        avgFrameTime: 15.5,
        droppedFrameRate: 0.05,
        pageViewCounts: {'home': 5, 'detail': 3},
        pageLoadTimes: {'home': 200.0, 'detail': 150.0},
        animatedWidgetCount: 2,
        suggestions: ['优化建议1', '优化建议2'],
      );

      expect(report.sessionDuration.inSeconds, equals(60));
      expect(report.totalInteractions, equals(10));
      expect(report.avgFrameTime, equals(15.5));
    });

    test('应该能转换为Map', () {
      final report = PerformanceReport(
        sessionDuration: Duration(seconds: 30),
        totalInteractions: 5,
        avgFrameTime: 16.0,
        droppedFrameRate: 0.1,
        pageViewCounts: {'home': 2},
        pageLoadTimes: {'home': 100.0},
        animatedWidgetCount: 1,
        suggestions: ['建议1'],
      );

      final map = report.toMap();
      expect(map['session_duration_seconds'], equals(30));
      expect(map['total_interactions'], equals(5));
      expect(map['avg_frame_time'], equals(16.0));
      expect(map['dropped_frame_rate'], equals(0.1));
    });

    test('应该能从Map创建', () {
      final map = {
        'session_duration_seconds': 45,
        'total_interactions': 8,
        'avg_frame_time': 17.5,
        'dropped_frame_rate': 0.08,
        'page_view_counts': {'home': 3, 'detail': 2},
        'page_load_times': {'home': 180.0, 'detail': 120.0},
        'animated_widget_count': 3,
        'suggestions': ['建议A', '建议B'],
      };

      final report = PerformanceReport.fromMap(map);
      expect(report.sessionDuration.inSeconds, equals(45));
      expect(report.totalInteractions, equals(8));
      expect(report.avgFrameTime, equals(17.5));
      expect(report.pageViewCounts['home'], equals(3));
    });

    test('应该能计算每分钟交互次数', () {
      final report = PerformanceReport(
        sessionDuration: Duration(seconds: 60),
        totalInteractions: 30,
        avgFrameTime: 16.0,
        droppedFrameRate: 0.05,
        pageViewCounts: {},
        pageLoadTimes: {},
        animatedWidgetCount: 0,
        suggestions: [],
      );

      final map = report.toMap();
      expect(map['interactions_per_minute'], equals(30.0));
    });

    test('应该能处理零时长会话', () {
      final report = PerformanceReport(
        sessionDuration: Duration.zero,
        totalInteractions: 5,
        avgFrameTime: 16.0,
        droppedFrameRate: 0.05,
        pageViewCounts: {},
        pageLoadTimes: {},
        animatedWidgetCount: 0,
        suggestions: [],
      );

      final map = report.toMap();
      expect(map['interactions_per_minute'], equals(0));
    });

    test('应该能转换为字符串', () {
      final report = PerformanceReport(
        sessionDuration: Duration(seconds: 120),
        totalInteractions: 20,
        avgFrameTime: 15.75,
        droppedFrameRate: 0.12,
        pageViewCounts: {},
        pageLoadTimes: {},
        animatedWidgetCount: 0,
        suggestions: [],
      );

      final str = report.toString();
      expect(str, contains('120s'));
      expect(str, contains('20'));
      expect(str, contains('15.75'));
      expect(str, contains('12.0%'));
    });
  });
}
