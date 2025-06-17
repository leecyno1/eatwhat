/// 性能优化配置
class PerformanceConfig {
  // 物理引擎配置
  static const double physicsUpdateInterval = 16.67; // 60 FPS
  static const int maxBubbleCount = 50;
  static const double spatialGridSize = 100.0;
  
  // 动画配置
  static const int maxAnimationControllers = 10;
  static const Duration defaultAnimationDuration = Duration(milliseconds: 300);
  static const Duration longAnimationDuration = Duration(milliseconds: 800);
  
  // UI优化配置
  static const int frameRateLimit = 60;
  static const Duration debounceDelay = Duration(milliseconds: 16);
  static const int maxCachedWidgets = 100;
  
  // 内存管理配置
  static const int maxImageCacheSize = 50;
  static const int maxDataCacheSize = 100;
  static const Duration cacheCleanupInterval = Duration(minutes: 5);
  static const Duration memoryCheckInterval = Duration(seconds: 30);
  
  // 批量更新配置
  static const Duration batchUpdateDelay = Duration(milliseconds: 16);
  static const int maxBatchSize = 50;
  
  // 触觉反馈配置
  static const Duration hapticFeedbackCooldown = Duration(milliseconds: 100);
  
  // 滚动优化配置
  static const double scrollPhysicsSpring = 0.8;
  static const double scrollPhysicsDamping = 0.9;
  
  // 图片预加载配置
  static const int preloadImageCount = 5;
  static const Duration preloadDelay = Duration(milliseconds: 500);
  
  // 性能监控配置
  static const bool enablePerformanceMonitoring = true;
  static const Duration performanceLogInterval = Duration(seconds: 10);
  static const double memoryWarningThreshold = 0.8; // 80% 内存使用率
  static const double frameDropWarningThreshold = 0.1; // 10% 丢帧率
  
  // 开发模式配置
  static const bool enableDebugMode = false;
  static const bool showPerformanceOverlay = false;
  static const bool logPerformanceMetrics = false;
}

/// 性能级别枚举
enum PerformanceLevel {
  low,
  medium,
  high,
  ultra,
}

/// 根据设备性能调整配置
class AdaptivePerformanceConfig {
  static PerformanceLevel _currentLevel = PerformanceLevel.medium;
  
  static PerformanceLevel get currentLevel => _currentLevel;
  
  static void setPerformanceLevel(PerformanceLevel level) {
    _currentLevel = level;
  }
  
  /// 获取适应性物理更新间隔
  static double get adaptivePhysicsUpdateInterval {
    switch (_currentLevel) {
      case PerformanceLevel.low:
        return 33.33; // 30 FPS
      case PerformanceLevel.medium:
        return 16.67; // 60 FPS
      case PerformanceLevel.high:
        return 11.11; // 90 FPS
      case PerformanceLevel.ultra:
        return 8.33; // 120 FPS
    }
  }
  
  /// 获取适应性最大气泡数量
  static int get adaptiveMaxBubbleCount {
    switch (_currentLevel) {
      case PerformanceLevel.low:
        return 20;
      case PerformanceLevel.medium:
        return 50;
      case PerformanceLevel.high:
        return 80;
      case PerformanceLevel.ultra:
        return 100;
    }
  }
  
  /// 获取适应性空间网格大小
  static double get adaptiveSpatialGridSize {
    switch (_currentLevel) {
      case PerformanceLevel.low:
        return 150.0;
      case PerformanceLevel.medium:
        return 100.0;
      case PerformanceLevel.high:
        return 75.0;
      case PerformanceLevel.ultra:
        return 50.0;
    }
  }
  
  /// 获取适应性帧率限制
  static int get adaptiveFrameRateLimit {
    switch (_currentLevel) {
      case PerformanceLevel.low:
        return 30;
      case PerformanceLevel.medium:
        return 60;
      case PerformanceLevel.high:
        return 90;
      case PerformanceLevel.ultra:
        return 120;
    }
  }
  
  /// 获取适应性缓存大小
  static int get adaptiveImageCacheSize {
    switch (_currentLevel) {
      case PerformanceLevel.low:
        return 20;
      case PerformanceLevel.medium:
        return 50;
      case PerformanceLevel.high:
        return 80;
      case PerformanceLevel.ultra:
        return 100;
    }
  }
}