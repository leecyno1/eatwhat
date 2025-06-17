import 'dart:async';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/material.dart';
import '../config/performance_config.dart';
import 'memory_manager.dart';
import 'performance_optimizer.dart';

/// 应用启动优化器
class AppStartupOptimizer {
  static bool _isInitialized = false;
  static final Completer<void> _initCompleter = Completer<void>();
  
  /// 是否已初始化
  static bool get isInitialized => _isInitialized;
  
  /// 等待初始化完成
  static Future<void> waitForInitialization() => _initCompleter.future;
  
  /// 初始化应用启动优化
  static Future<void> initialize() async {
    if (_isInitialized) return;
    
    try {
      // 1. 设置系统UI样式
      await _setupSystemUI();
      
      // 2. 检测设备性能
      await _detectDevicePerformance();
      
      // 3. 预热关键组件
      await _preWarmComponents();
      
      // 4. 初始化内存管理器
      await MemoryManager.initialize();
      
      // 5. 预加载关键资源
      await _preloadCriticalAssets();
      
      // 6. 设置性能监控
      _setupPerformanceMonitoring();
      
      _isInitialized = true;
      _initCompleter.complete();
      
      if (kDebugMode) {
        print('AppStartupOptimizer: 初始化完成');
      }
    } catch (e) {
      if (kDebugMode) {
        print('AppStartupOptimizer: 初始化失败 - $e');
      }
      _initCompleter.completeError(e);
    }
  }
  
  /// 设置系统UI样式
  static Future<void> _setupSystemUI() async {
    // 设置状态栏样式
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
        systemNavigationBarColor: Colors.white,
        systemNavigationBarIconBrightness: Brightness.dark,
      ),
    );
    
    // 设置首选方向
    await SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
    ]);
  }
  
  /// 检测设备性能
  static Future<void> _detectDevicePerformance() async {
    try {
      // 基于平台和设备信息推断性能级别
      PerformanceLevel level = PerformanceLevel.medium;
      
      if (Platform.isIOS) {
        // iOS设备通常性能较好
        level = PerformanceLevel.high;
      } else if (Platform.isAndroid) {
        // Android设备性能差异较大，默认中等
        level = PerformanceLevel.medium;
      }
      
      // 可以根据更多设备信息进行调整
      // 例如：内存大小、CPU核心数等
      
      AdaptivePerformanceConfig.setPerformanceLevel(level);
      
      if (kDebugMode) {
        print('检测到设备性能级别: $level');
      }
    } catch (e) {
      if (kDebugMode) {
        print('设备性能检测失败: $e');
      }
    }
  }
  
  /// 预热关键组件
  static Future<void> _preWarmComponents() async {
    // 预热Flutter引擎
    WidgetsFlutterBinding.ensureInitialized();
    
    // 预热常用Widget
    await _preWarmWidgets();
    
    // 预热动画系统
    await _preWarmAnimations();
  }
  
  /// 预热常用Widget
  static Future<void> _preWarmWidgets() async {
    // 创建一个临时的BuildContext来预热Widget
    final tempWidget = MaterialApp(
      home: Scaffold(
        body: Column(
          children: [
            Container(),
            Text('预热'),
            ElevatedButton(onPressed: () {}, child: Text('按钮')),
            CircularProgressIndicator(),
            Card(child: ListTile(title: Text('列表项'))),
          ],
        ),
      ),
    );
    
    // 这里可以添加更多预热逻辑
  }
  
  /// 预热动画系统
  static Future<void> _preWarmAnimations() async {
    // 创建一个临时的动画控制器来预热动画系统
    final vsync = _TempTickerProvider();
    final controller = AnimationController(
      duration: const Duration(milliseconds: 100),
      vsync: vsync,
    );
    
    await controller.forward();
    controller.dispose();
  }
  
  /// 预加载关键资源
  static Future<void> _preloadCriticalAssets() async {
    // 这里可以预加载关键图片、字体等资源
    // 例如：
    // await precacheImage(AssetImage('assets/images/logo.png'), context);
  }
  
  /// 设置性能监控
  static void _setupPerformanceMonitoring() {
    if (!PerformanceConfig.enablePerformanceMonitoring) return;
    
    // 设置定期性能检查
    Timer.periodic(PerformanceConfig.performanceLogInterval, (timer) {
      _logPerformanceMetrics();
    });
  }
  
  /// 记录性能指标
  static void _logPerformanceMetrics() {
    if (!PerformanceConfig.logPerformanceMetrics || !kDebugMode) return;
    
    // 这里可以记录各种性能指标
    // 例如：内存使用、帧率、CPU使用率等
    print('性能指标记录 - ${DateTime.now()}');
  }
  
  /// 优化应用启动
  static Future<void> optimizeAppLaunch() async {
    // 延迟非关键初始化
    Future.delayed(const Duration(seconds: 1), () {
      _initializeNonCriticalComponents();
    });
    
    // 预热网络连接
    Future.delayed(const Duration(milliseconds: 500), () {
      _preWarmNetworkConnections();
    });
  }
  
  /// 初始化非关键组件
  static void _initializeNonCriticalComponents() {
    // 初始化分析工具、崩溃报告等非关键组件
  }
  
  /// 预热网络连接
  static void _preWarmNetworkConnections() {
    // 预热网络连接，例如DNS解析等
  }
}

/// 临时的Ticker提供者，用于预热动画系统
class _TempTickerProvider implements TickerProvider {
  @override
  Ticker createTicker(TickerCallback onTick) {
    return Ticker(onTick);
  }
}

/// 启动性能监控器
class StartupPerformanceMonitor {
  static final Stopwatch _stopwatch = Stopwatch();
  static final Map<String, int> _milestones = {};
  
  /// 开始监控
  static void start() {
    _stopwatch.start();
    _recordMilestone('app_start');
  }
  
  /// 记录里程碑
  static void recordMilestone(String name) {
    _recordMilestone(name);
  }
  
  static void _recordMilestone(String name) {
    _milestones[name] = _stopwatch.elapsedMilliseconds;
    if (kDebugMode) {
      print('启动里程碑: $name - ${_stopwatch.elapsedMilliseconds}ms');
    }
  }
  
  /// 停止监控并输出报告
  static void stop() {
    _stopwatch.stop();
    _recordMilestone('app_ready');
    
    if (kDebugMode) {
      print('=== 启动性能报告 ===');
      _milestones.forEach((name, time) {
        print('$name: ${time}ms');
      });
      print('总启动时间: ${_stopwatch.elapsedMilliseconds}ms');
      print('==================');
    }
  }
  
  /// 获取启动时间
  static int get totalStartupTime => _stopwatch.elapsedMilliseconds;
  
  /// 获取里程碑时间
  static int? getMilestoneTime(String name) => _milestones[name];
}