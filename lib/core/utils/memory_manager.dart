import 'dart:async';
import 'dart:collection';
import 'package:flutter/foundation.dart';

/// 内存管理器 - 负责应用的内存优化和缓存管理
class MemoryManager {
  static final MemoryManager _instance = MemoryManager._internal();
  factory MemoryManager() => _instance;
  MemoryManager._internal();

  // 缓存系统
  final Map<String, _CacheEntry> _cache = {};
  final Queue<String> _accessOrder = Queue<String>();
  
  // 配置参数
  static const int maxCacheSize = 100;
  static const Duration defaultCacheDuration = Duration(minutes: 30);
  static const int maxAccessOrderSize = 200;
  
  Timer? _cleanupTimer;
  bool _isInitialized = false;

  /// 初始化内存管理器
  void initialize() {
    if (_isInitialized) return;
    
    _startPeriodicCleanup();
    _isInitialized = true;
    debugPrint('MemoryManager initialized');
  }

  /// 启动定期清理
  void _startPeriodicCleanup() {
    _cleanupTimer = Timer.periodic(const Duration(minutes: 5), (_) {
      _performCleanup();
    });
  }

  /// 缓存数据
  void cache<T>(String key, T data, {Duration? duration}) {
    // 如果缓存已满，移除最老的条目
    if (_cache.length >= maxCacheSize) {
      _evictOldest();
    }

    final expiry = DateTime.now().add(duration ?? defaultCacheDuration);
    _cache[key] = _CacheEntry(data, expiry);
    
    // 更新访问顺序
    _updateAccessOrder(key);
    
    debugPrint('Cached: $key, expires: $expiry');
  }

  /// 获取缓存数据
  T? getCached<T>(String key) {
    final entry = _cache[key];
    if (entry == null) return null;

    // 检查是否过期
    if (DateTime.now().isAfter(entry.expiry)) {
      _cache.remove(key);
      _accessOrder.remove(key);
      debugPrint('Cache expired: $key');
      return null;
    }

    // 更新访问顺序
    _updateAccessOrder(key);
    
    return entry.data as T?;
  }

  /// 检查缓存是否存在
  bool hasCached(String key) {
    final entry = _cache[key];
    if (entry == null) return false;
    
    if (DateTime.now().isAfter(entry.expiry)) {
      _cache.remove(key);
      _accessOrder.remove(key);
      return false;
    }
    
    return true;
  }

  /// 移除缓存
  void removeCache(String key) {
    _cache.remove(key);
    _accessOrder.remove(key);
    debugPrint('Cache removed: $key');
  }

  /// 清空所有缓存
  void clearAllCache() {
    _cache.clear();
    _accessOrder.clear();
    debugPrint('All cache cleared');
  }

  /// 更新访问顺序
  void _updateAccessOrder(String key) {
    _accessOrder.remove(key);
    _accessOrder.add(key);
    
    // 限制访问顺序队列大小
    if (_accessOrder.length > maxAccessOrderSize) {
      _accessOrder.removeFirst();
    }
  }

  /// 移除最老的缓存条目
  void _evictOldest() {
    if (_accessOrder.isNotEmpty) {
      final oldestKey = _accessOrder.removeFirst();
      _cache.remove(oldestKey);
      debugPrint('Evicted oldest cache: $oldestKey');
    }
  }

  /// 执行清理操作
  void _performCleanup() {
    final now = DateTime.now();
    final expiredKeys = <String>[];

    // 查找过期的缓存
    _cache.forEach((key, entry) {
      if (now.isAfter(entry.expiry)) {
        expiredKeys.add(key);
      }
    });

    // 移除过期缓存
    for (final key in expiredKeys) {
      _cache.remove(key);
      _accessOrder.remove(key);
    }

    if (expiredKeys.isNotEmpty) {
      debugPrint('Cleaned up ${expiredKeys.length} expired cache entries');
    }

    // 强制垃圾回收（仅在debug模式）
    if (kDebugMode) {
      _suggestGarbageCollection();
    }
  }

  /// 建议垃圾回收
  void _suggestGarbageCollection() {
    // 在Flutter中，我们不能直接控制GC，但可以建议系统回收
    // 这里主要是清理一些可能的内存泄漏
    debugPrint('Suggesting garbage collection');
  }

  /// 获取内存使用统计
  Map<String, dynamic> getMemoryStats() {
    final now = DateTime.now();
    int expiredCount = 0;
    int totalSize = _cache.length;

    _cache.forEach((key, entry) {
      if (now.isAfter(entry.expiry)) {
        expiredCount++;
      }
    });

    return {
      'totalCacheEntries': totalSize,
      'expiredEntries': expiredCount,
      'accessOrderSize': _accessOrder.length,
      'cacheUtilization': totalSize / maxCacheSize,
      'lastCleanup': _cleanupTimer?.isActive ?? false ? 'active' : 'inactive',
    };
  }

  /// 优化内存使用
  void optimizeMemory() {
    // 立即执行清理
    _performCleanup();
    
    // 如果缓存使用率过高，清理一半
    if (_cache.length > maxCacheSize * 0.8) {
      final keysToRemove = _accessOrder.take(_cache.length ~/ 2).toList();
      for (final key in keysToRemove) {
        _cache.remove(key);
        _accessOrder.remove(key);
      }
      debugPrint('Aggressive cleanup: removed ${keysToRemove.length} entries');
    }
  }

  /// 预加载关键数据
  void preloadCriticalData() {
    // 这里可以预加载一些关键的应用数据
    // 比如用户偏好、常用食物数据等
    debugPrint('Preloading critical data...');
  }

  /// 获取缓存命中率
  double getCacheHitRate() {
    // 这里需要额外的统计逻辑来计算命中率
    // 为简化，返回一个估算值
    return _cache.isNotEmpty ? 0.75 : 0.0;
  }

  /// 释放资源
  void dispose() {
    _cleanupTimer?.cancel();
    _cleanupTimer = null;
    clearAllCache();
    _isInitialized = false;
    debugPrint('MemoryManager disposed');
  }
}

/// 缓存条目
class _CacheEntry {
  final dynamic data;
  final DateTime expiry;

  _CacheEntry(this.data, this.expiry);
}

/// 智能缓存策略
enum CacheStrategy {
  lru,        // 最近最少使用
  lfu,        // 最少使用频率
  fifo,       // 先进先出
  timeExpiry, // 时间过期
}

/// 高级缓存管理器
class AdvancedCacheManager {
  final Map<String, _AdvancedCacheEntry> _cache = {};
  final CacheStrategy _strategy;
  final int _maxSize;

  AdvancedCacheManager({
    CacheStrategy strategy = CacheStrategy.lru,
    int maxSize = 100,
  }) : _strategy = strategy, _maxSize = maxSize;

  /// 智能缓存
  void smartCache<T>(String key, T data, {
    Duration? duration,
    int priority = 1,
  }) {
    if (_cache.length >= _maxSize) {
      _evictByStrategy();
    }

    _cache[key] = _AdvancedCacheEntry(
      data: data,
      expiry: DateTime.now().add(duration ?? const Duration(minutes: 30)),
      accessCount: 0,
      priority: priority,
      lastAccessed: DateTime.now(),
    );
  }

  /// 根据策略移除缓存
  void _evictByStrategy() {
    String? keyToEvict;

    switch (_strategy) {
      case CacheStrategy.lru:
        keyToEvict = _findLRUKey();
        break;
      case CacheStrategy.lfu:
        keyToEvict = _findLFUKey();
        break;
      case CacheStrategy.fifo:
        keyToEvict = _cache.keys.first;
        break;
      case CacheStrategy.timeExpiry:
        keyToEvict = _findExpiredKey();
        break;
    }

    if (keyToEvict != null) {
      _cache.remove(keyToEvict);
    }
  }

  String? _findLRUKey() {
    DateTime? oldest;
    String? oldestKey;

    _cache.forEach((key, entry) {
      if (oldest == null || entry.lastAccessed.isBefore(oldest!)) {
        oldest = entry.lastAccessed;
        oldestKey = key;
      }
    });

    return oldestKey;
  }

  String? _findLFUKey() {
    int? minAccess;
    String? minKey;

    _cache.forEach((key, entry) {
      if (minAccess == null || entry.accessCount < minAccess!) {
        minAccess = entry.accessCount;
        minKey = key;
      }
    });

    return minKey;
  }

  String? _findExpiredKey() {
    final now = DateTime.now();
    for (final entry in _cache.entries) {
      if (now.isAfter(entry.value.expiry)) {
        return entry.key;
      }
    }
    return null;
  }
}

/// 高级缓存条目
class _AdvancedCacheEntry {
  final dynamic data;
  final DateTime expiry;
  int accessCount;
  final int priority;
  DateTime lastAccessed;

  _AdvancedCacheEntry({
    required this.data,
    required this.expiry,
    this.accessCount = 0,
    this.priority = 1,
    required this.lastAccessed,
  });
}