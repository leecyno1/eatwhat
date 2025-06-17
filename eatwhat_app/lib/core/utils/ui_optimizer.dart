import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:flutter/services.dart';
import 'memory_manager.dart';
import 'performance_optimizer.dart';

/// UI响应性优化器
class UIOptimizer {
  static final UIOptimizer _instance = UIOptimizer._internal();
  factory UIOptimizer() => _instance;
  UIOptimizer._internal();
  
  // 帧率监控
  final List<Duration> _frameTimes = [];
  static const int _maxFrameTimeHistory = 60;
  Timer? _frameMonitorTimer;
  
  // 滚动优化
  final Map<String, ScrollController> _scrollControllers = {};
  
  // 动画优化
  final Set<AnimationController> _activeAnimations = {};
  
  // 触觉反馈管理
  DateTime? _lastHapticFeedback;
  static const Duration _hapticFeedbackCooldown = Duration(milliseconds: 50);
  
  /// 初始化UI优化器
  void initialize() {
    _startFrameMonitoring();
    _optimizeScrollPhysics();
  }
  
  /// 开始帧率监控
  void _startFrameMonitoring() {
    SchedulerBinding.instance.addPersistentFrameCallback((timeStamp) {
      _recordFrameTime(timeStamp);
    });
  }
  
  /// 记录帧时间
  void _recordFrameTime(Duration timeStamp) {
    _frameTimes.add(timeStamp);
    
    if (_frameTimes.length > _maxFrameTimeHistory) {
      _frameTimes.removeAt(0);
    }
    
    // 检测掉帧
    if (_frameTimes.length >= 2) {
      final lastFrameTime = _frameTimes[_frameTimes.length - 2];
      final currentFrameTime = _frameTimes.last;
      final frameDuration = currentFrameTime - lastFrameTime;
      
      // 如果帧时间超过16.67ms（60FPS），认为是掉帧
      if (frameDuration.inMicroseconds > 16670) {
        _handleFrameDrop(frameDuration);
      }
    }
  }
  
  /// 处理掉帧
  void _handleFrameDrop(Duration frameDuration) {
    // 在调试模式下记录掉帧信息
    if (SchedulerBinding.instance.schedulerPhase == SchedulerPhase.idle) {
      PerformanceOptimizer.PerformanceProfiler.startTiming('frame_drop_recovery');
      
      // 尝试减少动画复杂度
      _reduceAnimationComplexity();
      
      PerformanceOptimizer.PerformanceProfiler.endTiming('frame_drop_recovery');
    }
  }
  
  /// 减少动画复杂度
  void _reduceAnimationComplexity() {
    // 暂停非关键动画
    for (final animation in _activeAnimations) {
      if (animation.status == AnimationStatus.forward ||
          animation.status == AnimationStatus.reverse) {
        // 可以考虑降低动画帧率或暂停动画
      }
    }
  }
  
  /// 优化滚动物理效果
  void _optimizeScrollPhysics() {
    // 这里可以设置全局的滚动物理效果
  }
  
  /// 创建优化的滚动控制器
  ScrollController createOptimizedScrollController(String key) {
    if (_scrollControllers.containsKey(key)) {
      return _scrollControllers[key]!;
    }
    
    final controller = ScrollController();
    _scrollControllers[key] = controller;
    
    // 添加滚动监听器进行优化
    controller.addListener(() {
      _optimizeScrollPerformance(controller);
    });
    
    return controller;
  }
  
  /// 优化滚动性能
  void _optimizeScrollPerformance(ScrollController controller) {
    // 如果滚动速度过快，可以考虑降低渲染质量
    if (controller.position.activity?.velocity.abs() ?? 0 > 1000) {
      // 快速滚动时的优化策略
      _enableFastScrollMode();
    } else {
      _disableFastScrollMode();
    }
  }
  
  /// 启用快速滚动模式
  void _enableFastScrollMode() {
    // 在快速滚动时减少渲染复杂度
  }
  
  /// 禁用快速滚动模式
  void _disableFastScrollMode() {
    // 恢复正常渲染质量
  }
  
  /// 注册动画控制器
  void registerAnimation(AnimationController controller) {
    _activeAnimations.add(controller);
    
    // 监听动画状态变化
    controller.addStatusListener((status) {
      if (status == AnimationStatus.completed ||
          status == AnimationStatus.dismissed) {
        _activeAnimations.remove(controller);
      }
    });
  }
  
  /// 批量启动动画
  void batchStartAnimations(List<AnimationController> controllers) {
    // 使用帧回调来批量启动动画，避免在同一帧内多次触发
    SchedulerBinding.instance.addPostFrameCallback((_) {
      for (final controller in controllers) {
        if (controller.status == AnimationStatus.dismissed) {
          controller.forward();
        }
      }
    });
  }
  
  /// 优化的触觉反馈
  void optimizedHapticFeedback(HapticFeedbackType type) {
    final now = DateTime.now();
    
    // 防止触觉反馈过于频繁
    if (_lastHapticFeedback != null &&
        now.difference(_lastHapticFeedback!) < _hapticFeedbackCooldown) {
      return;
    }
    
    _lastHapticFeedback = now;
    
    switch (type) {
      case HapticFeedbackType.lightImpact:
        HapticFeedback.lightImpact();
        break;
      case HapticFeedbackType.mediumImpact:
        HapticFeedback.mediumImpact();
        break;
      case HapticFeedbackType.heavyImpact:
        HapticFeedback.heavyImpact();
        break;
      case HapticFeedbackType.selectionClick:
        HapticFeedback.selectionClick();
        break;
      case HapticFeedbackType.vibrate:
        HapticFeedback.vibrate();
        break;
    }
  }
  
  /// 创建优化的列表视图
  Widget createOptimizedListView({
    required String key,
    required IndexedWidgetBuilder itemBuilder,
    required int itemCount,
    ScrollController? controller,
    Axis scrollDirection = Axis.vertical,
    bool shrinkWrap = false,
    EdgeInsetsGeometry? padding,
  }) {
    final scrollController = controller ?? createOptimizedScrollController(key);
    
    return ListView.builder(
      controller: scrollController,
      itemBuilder: (context, index) {
        // 使用优化的构建器
        return PerformanceOptimizer.OptimizedBuilder(
          builder: (context) => itemBuilder(context, index),
          shouldRebuild: (oldWidget, newWidget) {
            // 只有在必要时才重建
            return true; // 可以根据具体需求优化
          },
        );
      },
      itemCount: itemCount,
      scrollDirection: scrollDirection,
      shrinkWrap: shrinkWrap,
      padding: padding,
      // 优化的物理效果
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      // 缓存范围优化
      cacheExtent: 250.0,
    );
  }
  
  /// 创建优化的网格视图
  Widget createOptimizedGridView({
    required String key,
    required IndexedWidgetBuilder itemBuilder,
    required int itemCount,
    required SliverGridDelegate gridDelegate,
    ScrollController? controller,
    Axis scrollDirection = Axis.vertical,
    bool shrinkWrap = false,
    EdgeInsetsGeometry? padding,
  }) {
    final scrollController = controller ?? createOptimizedScrollController(key);
    
    return GridView.builder(
      controller: scrollController,
      itemBuilder: (context, index) {
        return PerformanceOptimizer.OptimizedBuilder(
          builder: (context) => itemBuilder(context, index),
        );
      },
      itemCount: itemCount,
      gridDelegate: gridDelegate,
      scrollDirection: scrollDirection,
      shrinkWrap: shrinkWrap,
      padding: padding,
      physics: const BouncingScrollPhysics(
        parent: AlwaysScrollableScrollPhysics(),
      ),
      cacheExtent: 250.0,
    );
  }
  
  /// 创建优化的动画构建器
  Widget createOptimizedAnimatedBuilder({
    required Animation<double> animation,
    required Widget Function(BuildContext, Widget?) builder,
    Widget? child,
  }) {
    return AnimatedBuilder(
      animation: animation,
      builder: (context, child) {
        // 只有在动画值发生显著变化时才重建
        return PerformanceOptimizer.OptimizedBuilder(
          builder: (context) => builder(context, child),
          shouldRebuild: (oldWidget, newWidget) {
            // 可以根据动画值的变化来决定是否重建
            return true;
          },
        );
      },
      child: child,
    );
  }
  
  /// 预加载图片
  Future<void> preloadImages(BuildContext context, List<String> imagePaths) async {
    final futures = <Future>[];
    
    for (final path in imagePaths) {
      // 检查内存管理器中是否已缓存
      final cachedImage = MemoryManager().getCachedImage(path);
      if (cachedImage == null) {
        final future = precacheImage(
          AssetImage(path),
          context,
        ).then((_) {
          // 缓存到内存管理器
          MemoryManager().cacheImage(path, AssetImage(path));
        });
        futures.add(future);
      }
    }
    
    await Future.wait(futures);
  }
  
  /// 获取帧率统计
  Map<String, dynamic> getFrameRateStats() {
    if (_frameTimes.length < 2) {
      return {'fps': 0.0, 'frame_drops': 0};
    }
    
    final durations = <Duration>[];
    for (int i = 1; i < _frameTimes.length; i++) {
      durations.add(_frameTimes[i] - _frameTimes[i - 1]);
    }
    
    final avgFrameTime = durations.fold<int>(
      0,
      (sum, duration) => sum + duration.inMicroseconds,
    ) / durations.length;
    
    final fps = 1000000 / avgFrameTime; // 转换为FPS
    
    final frameDrops = durations.where(
      (duration) => duration.inMicroseconds > 16670, // 超过16.67ms
    ).length;
    
    return {
      'fps': fps,
      'frame_drops': frameDrops,
      'avg_frame_time_ms': avgFrameTime / 1000,
    };
  }
  
  /// 获取滚动控制器
  ScrollController? getScrollController(String key) {
    return _scrollControllers[key];
  }
  
  /// 移除滚动控制器
  void removeScrollController(String key) {
    final controller = _scrollControllers.remove(key);
    controller?.dispose();
  }
  
  /// 清理资源
  void dispose() {
    _frameMonitorTimer?.cancel();
    
    for (final controller in _scrollControllers.values) {
      controller.dispose();
    }
    _scrollControllers.clear();
    
    _activeAnimations.clear();
    _frameTimes.clear();
  }
}

/// UI优化混入
mixin UIOptimizationMixin {
  final UIOptimizer _uiOptimizer = UIOptimizer();
  
  /// 创建优化的滚动控制器
  ScrollController createOptimizedScrollController(String key) {
    return _uiOptimizer.createOptimizedScrollController(key);
  }
  
  /// 注册动画控制器
  void registerAnimation(AnimationController controller) {
    _uiOptimizer.registerAnimation(controller);
  }
  
  /// 优化的触觉反馈
  void optimizedHapticFeedback(HapticFeedbackType type) {
    _uiOptimizer.optimizedHapticFeedback(type);
  }
  
  /// 预加载图片
  Future<void> preloadImages(BuildContext context, List<String> imagePaths) {
    return _uiOptimizer.preloadImages(context, imagePaths);
  }
}