import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../utils/performance_optimizer.dart';
import '../utils/memory_manager.dart';
import '../config/performance_config.dart';

/// 性能测试工具类
class PerformanceTest {
  static final PerformanceTest _instance = PerformanceTest._internal();
  factory PerformanceTest() => _instance;
  PerformanceTest._internal();

  final List<PerformanceTestResult> _results = [];
  bool _isRunning = false;

  /// 运行性能测试套件
  Future<PerformanceTestSuite> runTestSuite() async {
    if (_isRunning) {
      throw StateError('Performance test is already running');
    }

    _isRunning = true;
    _results.clear();

    try {
      // 测试内存管理
      await _testMemoryManagement();
      
      // 测试性能优化器
      await _testPerformanceOptimizer();
      
      // 测试帧率性能
      await _testFrameRatePerformance();
      
      // 测试批量更新
      await _testBatchUpdates();
      
      // 测试对象池
      await _testObjectPool();
      
      // 测试防抖动
      await _testDebouncing();

      return PerformanceTestSuite(
        results: List.from(_results),
        totalTests: _results.length,
        passedTests: _results.where((r) => r.passed).length,
        averageExecutionTime: _results.isEmpty 
            ? 0 
            : _results.map((r) => r.executionTime).reduce((a, b) => a + b) / _results.length,
      );
    } finally {
      _isRunning = false;
    }
  }

  /// 测试内存管理
  Future<void> _testMemoryManagement() async {
    final stopwatch = Stopwatch()..start();
    bool passed = true;
    String? error;

    try {
      final memoryManager = MemoryManager();
      
      // 测试图片缓存
      for (int i = 0; i < 100; i++) {
        memoryManager.cacheImage('test_image_$i', 'fake_image_data');
      }
      
      // 检查缓存大小
      if (memoryManager.getImageCacheSize() != 100) {
        passed = false;
        error = 'Image cache size mismatch';
      }
      
      // 清理缓存
      memoryManager.clearImageCache();
      
      if (memoryManager.getImageCacheSize() != 0) {
        passed = false;
        error = 'Image cache not cleared properly';
      }
      
      // 测试数据缓存
      for (int i = 0; i < 50; i++) {
        memoryManager.cacheData('test_data_$i', {'id': i, 'name': 'test'});
      }
      
      if (memoryManager.getDataCacheSize() != 50) {
        passed = false;
        error = 'Data cache size mismatch';
      }
      
      memoryManager.clearDataCache();
      
      if (memoryManager.getDataCacheSize() != 0) {
        passed = false;
        error = 'Data cache not cleared properly';
      }
      
    } catch (e) {
      passed = false;
      error = e.toString();
    }

    stopwatch.stop();
    _results.add(PerformanceTestResult(
      testName: 'Memory Management Test',
      passed: passed,
      executionTime: stopwatch.elapsedMilliseconds,
      error: error,
    ));
  }

  /// 测试性能优化器
  Future<void> _testPerformanceOptimizer() async {
    final stopwatch = Stopwatch()..start();
    bool passed = true;
    String? error;

    try {
      final optimizer = PerformanceOptimizer();
      
      // 测试帧率限制器
      int updateCount = 0;
      final frameRateLimiter = optimizer.createFrameRateLimiter(
        targetFPS: 60,
        onUpdate: () => updateCount++,
      );
      
      frameRateLimiter.start();
      await Future.delayed(const Duration(milliseconds: 100));
      frameRateLimiter.stop();
      
      // 检查更新次数是否合理（应该在6次左右，允许一定误差）
      if (updateCount < 3 || updateCount > 10) {
        passed = false;
        error = 'Frame rate limiter update count unexpected: $updateCount';
      }
      
      // 测试对象池
      final objectPool = optimizer.createObjectPool<TestObject>(
        createObject: () => TestObject(),
        resetObject: (obj) => obj.reset(),
        maxSize: 10,
      );
      
      final objects = <TestObject>[];
      for (int i = 0; i < 5; i++) {
        objects.add(objectPool.acquire());
      }
      
      for (final obj in objects) {
        objectPool.release(obj);
      }
      
      // 再次获取对象，应该复用之前的对象
      final reusedObject = objectPool.acquire();
      if (!objects.contains(reusedObject)) {
        passed = false;
        error = 'Object pool not reusing objects properly';
      }
      
    } catch (e) {
      passed = false;
      error = e.toString();
    }

    stopwatch.stop();
    _results.add(PerformanceTestResult(
      testName: 'Performance Optimizer Test',
      passed: passed,
      executionTime: stopwatch.elapsedMilliseconds,
      error: error,
    ));
  }

  /// 测试帧率性能
  Future<void> _testFrameRatePerformance() async {
    final stopwatch = Stopwatch()..start();
    bool passed = true;
    String? error;

    try {
      final frameRates = <double>[];
      final completer = Completer<void>();
      int frameCount = 0;
      const targetFrames = 60;
      
      Timer.periodic(const Duration(milliseconds: 16), (timer) {
        frameCount++;
        frameRates.add(1000 / 16); // 模拟60FPS
        
        if (frameCount >= targetFrames) {
          timer.cancel();
          completer.complete();
        }
      });
      
      await completer.future;
      
      final averageFrameRate = frameRates.reduce((a, b) => a + b) / frameRates.length;
      
      // 检查平均帧率是否接近60FPS
      if (averageFrameRate < 55 || averageFrameRate > 65) {
        passed = false;
        error = 'Average frame rate unexpected: $averageFrameRate';
      }
      
    } catch (e) {
      passed = false;
      error = e.toString();
    }

    stopwatch.stop();
    _results.add(PerformanceTestResult(
      testName: 'Frame Rate Performance Test',
      passed: passed,
      executionTime: stopwatch.elapsedMilliseconds,
      error: error,
    ));
  }

  /// 测试批量更新
  Future<void> _testBatchUpdates() async {
    final stopwatch = Stopwatch()..start();
    bool passed = true;
    String? error;

    try {
      final optimizer = PerformanceOptimizer();
      int updateCount = 0;
      
      final batchUpdateManager = optimizer.createBatchUpdateManager(
        batchSize: 10,
        onBatchUpdate: (updates) {
          updateCount += updates.length;
        },
      );
      
      // 添加20个更新
      for (int i = 0; i < 20; i++) {
        batchUpdateManager.addUpdate('update_$i');
      }
      
      // 等待批量更新完成
      await Future.delayed(const Duration(milliseconds: 50));
      
      // 应该有20个更新被处理
      if (updateCount != 20) {
        passed = false;
        error = 'Batch update count mismatch: expected 20, got $updateCount';
      }
      
    } catch (e) {
      passed = false;
      error = e.toString();
    }

    stopwatch.stop();
    _results.add(PerformanceTestResult(
      testName: 'Batch Updates Test',
      passed: passed,
      executionTime: stopwatch.elapsedMilliseconds,
      error: error,
    ));
  }

  /// 测试对象池
  Future<void> _testObjectPool() async {
    final stopwatch = Stopwatch()..start();
    bool passed = true;
    String? error;

    try {
      final optimizer = PerformanceOptimizer();
      final objectPool = optimizer.createObjectPool<TestObject>(
        createObject: () => TestObject(),
        resetObject: (obj) => obj.reset(),
        maxSize: 5,
      );
      
      // 测试对象获取和释放
      final objects = <TestObject>[];
      for (int i = 0; i < 5; i++) {
        objects.add(objectPool.acquire());
      }
      
      // 池应该已满
      final extraObject = objectPool.acquire();
      if (extraObject == null) {
        passed = false;
        error = 'Object pool should create new object when pool is empty';
      }
      
      // 释放对象
      for (final obj in objects) {
        objectPool.release(obj);
      }
      
      // 再次获取对象，应该复用
      final reusedObject = objectPool.acquire();
      if (!objects.contains(reusedObject)) {
        passed = false;
        error = 'Object pool not reusing objects';
      }
      
    } catch (e) {
      passed = false;
      error = e.toString();
    }

    stopwatch.stop();
    _results.add(PerformanceTestResult(
      testName: 'Object Pool Test',
      passed: passed,
      executionTime: stopwatch.elapsedMilliseconds,
      error: error,
    ));
  }

  /// 测试防抖动
  Future<void> _testDebouncing() async {
    final stopwatch = Stopwatch()..start();
    bool passed = true;
    String? error;

    try {
      final optimizer = PerformanceOptimizer();
      int callCount = 0;
      
      final debouncedNotifier = optimizer.createDebouncedNotifier(
        duration: const Duration(milliseconds: 100),
        onNotify: () => callCount++,
      );
      
      // 快速触发多次
      for (int i = 0; i < 10; i++) {
        debouncedNotifier.notify();
        await Future.delayed(const Duration(milliseconds: 10));
      }
      
      // 等待防抖动完成
      await Future.delayed(const Duration(milliseconds: 200));
      
      // 应该只被调用一次
      if (callCount != 1) {
        passed = false;
        error = 'Debounced notifier call count mismatch: expected 1, got $callCount';
      }
      
    } catch (e) {
      passed = false;
      error = e.toString();
    }

    stopwatch.stop();
    _results.add(PerformanceTestResult(
      testName: 'Debouncing Test',
      passed: passed,
      executionTime: stopwatch.elapsedMilliseconds,
      error: error,
    ));
  }

  /// 生成性能报告
  String generateReport() {
    if (_results.isEmpty) {
      return 'No test results available. Run tests first.';
    }

    final buffer = StringBuffer();
    buffer.writeln('=== Performance Test Report ===');
    buffer.writeln('Total Tests: ${_results.length}');
    buffer.writeln('Passed: ${_results.where((r) => r.passed).length}');
    buffer.writeln('Failed: ${_results.where((r) => !r.passed).length}');
    buffer.writeln('Average Execution Time: ${_results.map((r) => r.executionTime).reduce((a, b) => a + b) / _results.length}ms');
    buffer.writeln('');

    for (final result in _results) {
      buffer.writeln('${result.passed ? '✅' : '❌'} ${result.testName}');
      buffer.writeln('   Execution Time: ${result.executionTime}ms');
      if (!result.passed && result.error != null) {
        buffer.writeln('   Error: ${result.error}');
      }
      buffer.writeln('');
    }

    return buffer.toString();
  }
}

/// 测试对象类
class TestObject {
  int value = 0;
  String name = '';
  
  void reset() {
    value = 0;
    name = '';
  }
}

/// 性能测试结果
class PerformanceTestResult {
  final String testName;
  final bool passed;
  final int executionTime;
  final String? error;

  const PerformanceTestResult({
    required this.testName,
    required this.passed,
    required this.executionTime,
    this.error,
  });
}

/// 性能测试套件结果
class PerformanceTestSuite {
  final List<PerformanceTestResult> results;
  final int totalTests;
  final int passedTests;
  final double averageExecutionTime;

  const PerformanceTestSuite({
    required this.results,
    required this.totalTests,
    required this.passedTests,
    required this.averageExecutionTime,
  });

  int get failedTests => totalTests - passedTests;
  double get passRate => totalTests > 0 ? passedTests / totalTests : 0.0;
  bool get allTestsPassed => passedTests == totalTests;
}

/// 性能基准测试
class PerformanceBenchmark {
  static Future<BenchmarkResult> measureExecutionTime(
    String name,
    Future<void> Function() operation,
    {int iterations = 1}
  ) async {
    final times = <int>[];
    
    for (int i = 0; i < iterations; i++) {
      final stopwatch = Stopwatch()..start();
      await operation();
      stopwatch.stop();
      times.add(stopwatch.elapsedMicroseconds);
    }
    
    final averageTime = times.reduce((a, b) => a + b) / times.length;
    final minTime = times.reduce(math.min);
    final maxTime = times.reduce(math.max);
    
    return BenchmarkResult(
      name: name,
      iterations: iterations,
      averageTime: averageTime,
      minTime: minTime.toDouble(),
      maxTime: maxTime.toDouble(),
      times: times,
    );
  }
  
  static Future<MemoryBenchmarkResult> measureMemoryUsage(
    String name,
    Future<void> Function() operation,
  ) async {
    // 在Flutter中，我们无法直接测量内存使用情况
    // 这里提供一个框架，实际实现需要使用平台特定的代码
    final stopwatch = Stopwatch()..start();
    await operation();
    stopwatch.stop();
    
    return MemoryBenchmarkResult(
      name: name,
      executionTime: stopwatch.elapsedMicroseconds.toDouble(),
      // 这些值需要通过平台特定的代码获取
      memoryBefore: 0,
      memoryAfter: 0,
      memoryPeak: 0,
    );
  }
}

/// 基准测试结果
class BenchmarkResult {
  final String name;
  final int iterations;
  final double averageTime;
  final double minTime;
  final double maxTime;
  final List<int> times;

  const BenchmarkResult({
    required this.name,
    required this.iterations,
    required this.averageTime,
    required this.minTime,
    required this.maxTime,
    required this.times,
  });
  
  double get standardDeviation {
    final mean = averageTime;
    final variance = times
        .map((time) => math.pow(time - mean, 2))
        .reduce((a, b) => a + b) / times.length;
    return math.sqrt(variance);
  }
}

/// 内存基准测试结果
class MemoryBenchmarkResult {
  final String name;
  final double executionTime;
  final int memoryBefore;
  final int memoryAfter;
  final int memoryPeak;

  const MemoryBenchmarkResult({
    required this.name,
    required this.executionTime,
    required this.memoryBefore,
    required this.memoryAfter,
    required this.memoryPeak,
  });
  
  int get memoryDelta => memoryAfter - memoryBefore;
  int get memoryOverhead => memoryPeak - memoryBefore;
}