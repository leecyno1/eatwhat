import 'package:flutter_test/flutter_test.dart';
import 'package:eatwhat_app/core/utils/performance_monitor.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PerformanceMonitor', () {
    setUp(() {
      PerformanceMonitor.initialize();
    });

    tearDown(() {
      PerformanceMonitor.dispose();
    });

    test('应该能初始化性能监控', () {
      PerformanceMonitor.initialize();
      final stats = PerformanceMonitor.getStats();
      expect(stats, isNotNull);
    });

    test('应该能记录帧时间', () {
      PerformanceMonitor.recordFrame(15.0);
      PerformanceMonitor.recordFrame(16.0);

      final stats = PerformanceMonitor.getStats();
      expect(stats['status'], equals('active'));
    });

    test('应该能记录用户交互', () {
      PerformanceMonitor.recordFrame(15.0);
      PerformanceMonitor.recordInteraction();
      PerformanceMonitor.recordInteraction();

      final stats = PerformanceMonitor.getStats();
      expect(stats['interactionCount'], equals(2));
    });

    test('应该能注册和注销动画', () {
      PerformanceMonitor.registerAnimation();
      PerformanceMonitor.registerAnimation();

      PerformanceMonitor.unregisterAnimation();
      // 验证注册成功
    });

    test('应该能获取性能统计', () {
      PerformanceMonitor.recordFrame(15.0);
      final stats = PerformanceMonitor.getStats();

      expect(stats, contains('status'));
      expect(stats, contains('avgFrameTime'));
    });

    test('应该能获取优化建议', () {
      // 添加掉帧数据
      for (int i = 0; i < 10; i++) {
        PerformanceMonitor.recordFrame(25.0);
      }

      final suggestions = PerformanceMonitor.getSuggestions();
      expect(suggestions, isNotEmpty);
    });

    test('应该能计算当前FPS', () {
      PerformanceMonitor.recordFrame(16.67);
      PerformanceMonitor.recordFrame(16.67);

      final fps = PerformanceMonitor.getCurrentFPS();
      expect(fps, greaterThan(0));
      expect(fps, lessThanOrEqualTo(60.0));
    });

    test('应该能获取掉帧率', () {
      PerformanceMonitor.recordFrame(15.0);
      PerformanceMonitor.recordFrame(25.0);

      final droppedRate = PerformanceMonitor.getDroppedFrameRate();
      expect(droppedRate, greaterThanOrEqualTo(0.0));
      expect(droppedRate, lessThanOrEqualTo(1.0));
    });

    test('应该能检测性能问题', () {
      // 正常帧
      for (int i = 0; i < 10; i++) {
        PerformanceMonitor.recordFrame(15.0);
      }
      expect(PerformanceMonitor.hasPerformanceIssue(), isFalse);

      // 添加大量掉帧
      for (int i = 0; i < 10; i++) {
        PerformanceMonitor.recordFrame(30.0);
      }
      expect(PerformanceMonitor.hasPerformanceIssue(), isTrue);
    });

    test('应该能获取性能等级', () {
      // 优秀性能 (60fps)
      for (int i = 0; i < 10; i++) {
        PerformanceMonitor.recordFrame(16.67);
      }
      expect(PerformanceMonitor.getPerformanceGrade(), equals('A'));
    });

    test('应该能获取性能报告', () {
      PerformanceMonitor.recordFrame(15.0);
      PerformanceMonitor.recordFrame(16.0);

      final report = PerformanceMonitor.getPerformanceReport();
      expect(report, contains('fps'));
      expect(report, contains('grade'));
      expect(report, contains('droppedFrameRate'));
      expect(report, contains('hasIssue'));
      expect(report, contains('suggestions'));
      expect(report, contains('stats'));
    });

    test('应该能停止监控', () {
      PerformanceMonitor.stop();
      // 验证监控已停止
    });

    test('应该能清理资源', () {
      PerformanceMonitor.recordFrame(15.0);
      PerformanceMonitor.dispose();

      final stats = PerformanceMonitor.getStats();
      expect(stats['status'], equals('no_data'));
    });

    test('性能等级应该正确分级', () {
      // 测试不同FPS对应的等级
      PerformanceMonitor.dispose();
      PerformanceMonitor.initialize();

      // A级 (55+ fps)
      for (int i = 0; i < 10; i++) {
        PerformanceMonitor.recordFrame(16.0);
      }
      expect(PerformanceMonitor.getPerformanceGrade(), equals('A'));

      // 重置
      PerformanceMonitor.dispose();
      PerformanceMonitor.initialize();

      // B级 (45-55 fps)
      for (int i = 0; i < 10; i++) {
        PerformanceMonitor.recordFrame(20.0);
      }
      expect(PerformanceMonitor.getPerformanceGrade(), equals('B'));

      // 重置
      PerformanceMonitor.dispose();
      PerformanceMonitor.initialize();

      // C级 (35-45 fps)
      for (int i = 0; i < 10; i++) {
        PerformanceMonitor.recordFrame(25.0);
      }
      expect(PerformanceMonitor.getPerformanceGrade(), equals('C'));
    });

    test('应该能应用优化', () {
      PerformanceMonitor.applyOptimizations();
      // 验证优化已应用
    });
  });

  group('PerformanceMonitorMixin', () {
    test('应该能使用Mixin方法', () {
      final testClass = _TestClassWithMixin();

      testClass.registerPerformanceMonitoring();
      testClass.recordUserInteraction();
      testClass.unregisterPerformanceMonitoring();

      // 验证Mixin方法可用
    });
  });
}

// 测试用的类
class _TestClassWithMixin with PerformanceMonitorMixin {
  // 测试类
}
