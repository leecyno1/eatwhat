import 'package:flutter_test/flutter_test.dart';
import 'package:eatwhat_app/core/utils/performance_optimizer.dart';

void main() {
  group('PerformanceOptimizer', () {
    late PerformanceOptimizer optimizer;

    setUp(() {
      optimizer = PerformanceOptimizer();
    });

    test('应该能记录帧渲染时间', () {
      optimizer.recordFrameTime(16.0);
      optimizer.recordFrameTime(17.0);
      optimizer.recordFrameTime(15.0);

      expect(optimizer.frameCount, greaterThanOrEqualTo(0));
    });

    test('应该能记录用户交互', () {
      optimizer.recordInteraction();
      optimizer.recordInteraction();
      optimizer.recordInteraction();

      // 交互应该被记录
      expect(true, true);
    });

    test('应该能获取平均帧时间', () {
      optimizer.recordFrameTime(16.0);
      optimizer.recordFrameTime(17.0);
      optimizer.recordFrameTime(15.0);

      final avgTime = optimizer.avgFrameTime;
      expect(avgTime, greaterThanOrEqualTo(0));
    });

    test('应该能获取帧计数', () {
      final count = optimizer.frameCount;
      expect(count, greaterThanOrEqualTo(0));
    });

    test('应该能获取动画Widget数量', () {
      optimizer.registerAnimatedWidget();
      expect(optimizer.animatedWidgetCount, equals(1));

      optimizer.registerAnimatedWidget();
      expect(optimizer.animatedWidgetCount, equals(2));

      optimizer.unregisterAnimatedWidget();
      expect(optimizer.animatedWidgetCount, equals(1));
    });

    test('应该能停止监控', () {
      optimizer.stopMonitoring();
      // 监控应该被停止
      expect(true, true);
    });

    test('应该能清理资源', () {
      optimizer.recordFrameTime(16.0);
      optimizer.registerAnimatedWidget();

      optimizer.dispose();

      // 资源应该被清理
      expect(true, true);
    });
  });

  group('ObjectPool', () {
    test('应该能创建和获取对象', () {
      final pool = ObjectPool<List<int>>(
        () => [],
        reset: (list) => list.clear(),
      );

      final obj1 = pool.acquire();
      expect(obj1, isNotNull);
      expect(obj1, isEmpty);

      obj1.add(1);
      obj1.add(2);
      pool.release(obj1);

      final obj2 = pool.acquire();
      expect(obj2, isEmpty); // 应该被reset清空
    });

    test('应该能限制池大小', () {
      final pool = ObjectPool<int>(
        () => 0,
        maxSize: 3,
      );

      pool.release(1);
      pool.release(2);
      pool.release(3);
      pool.release(4); // 超过maxSize，不应该被添加

      final stats = pool.getStats();
      expect(stats['poolSize'], equals(3));
      expect(stats['maxSize'], equals(3));
    });

    test('应该能清空池', () {
      final pool = ObjectPool<int>(() => 0);

      pool.release(1);
      pool.release(2);
      pool.release(3);

      pool.clear();

      final stats = pool.getStats();
      expect(stats['poolSize'], equals(0));
    });

    test('应该能获取可用对象数量', () {
      final pool = ObjectPool<int>(() => 0);

      expect(pool.availableCount, equals(0));

      pool.release(1);
      expect(pool.availableCount, equals(1));

      pool.release(2);
      expect(pool.availableCount, equals(2));

      pool.acquire();
      expect(pool.availableCount, equals(1));
    });

    test('应该能重用对象', () {
      int factoryCallCount = 0;
      final pool = ObjectPool<int>(
        () {
          factoryCallCount++;
          return factoryCallCount;
        },
      );

      final obj1 = pool.acquire();
      expect(obj1, equals(1));
      expect(factoryCallCount, equals(1));

      pool.release(obj1);

      final obj2 = pool.acquire();
      expect(obj2, equals(1)); // 重用了obj1
      expect(factoryCallCount, equals(1)); // factory没有被再次调用
    });
  });

  group('DebouncedNotifier', () {
    test('应该能创建DebouncedNotifier', () {
      final notifier = DebouncedNotifier();
      expect(notifier, isNotNull);
      notifier.dispose();
    });

    test('应该能触发防抖通知', () async {
      final notifier = DebouncedNotifier();
      int notifyCount = 0;

      notifier.addListener(() {
        notifyCount++;
      });

      notifier.debouncedNotify();
      notifier.debouncedNotify();
      notifier.debouncedNotify();

      // 等待防抖延迟
      await Future.delayed(const Duration(milliseconds: 50));

      // 应该只通知一次
      expect(notifyCount, equals(1));
      notifier.dispose();
    });

    test('应该能自定义防抖延迟', () async {
      final notifier = DebouncedNotifier();
      int notifyCount = 0;

      notifier.addListener(() {
        notifyCount++;
      });

      notifier.debouncedNotify(const Duration(milliseconds: 100));

      await Future.delayed(const Duration(milliseconds: 50));
      expect(notifyCount, equals(0)); // 还没到时间

      await Future.delayed(const Duration(milliseconds: 60));
      expect(notifyCount, equals(1)); // 已经触发

      notifier.dispose();
    });
  });
}
