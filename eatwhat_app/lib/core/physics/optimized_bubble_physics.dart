import 'dart:math';
import 'dart:ui'; // Import dart:ui for clampDouble
import 'package:flutter/material.dart';
import '../models/bubble.dart';
import '../utils/performance_optimizer.dart';

/// 优化的气泡物理引擎
class OptimizedBubblePhysics {
  static const double gravity = 0.0;
  static const double friction = 0.98;
  static const double bounceReduction = 0.7;
  static const double brownianMotionStrength = 0.5;
  static const double minVelocity = 0.01;
  static const double maxVelocity = 5.0;
  static const double collisionDamping = 0.8;
  
  // 空间分区相关
  static const int gridSize = 100; // 网格大小
  late final int _gridCols;
  late final int _gridRows;
  late final List<List<List<Bubble>>> _spatialGrid;
  
  final Random _random = Random();
  final Size screenSize;
  
  // 性能优化组件
  late final PerformanceOptimizer.FrameRateLimiter _collisionLimiter;
  late final PerformanceOptimizer.ObjectPool<Offset> _offsetPool;
  
  // 缓存计算结果
  final Map<String, double> _distanceCache = {};
  int _cacheFrameCount = 0;
  static const int _cacheResetInterval = 60; // 每60帧清理一次缓存
  
  OptimizedBubblePhysics({required this.screenSize}) {
    // 初始化空间分区网格
    _gridCols = (screenSize.width / gridSize).ceil();
    _gridRows = (screenSize.height / gridSize).ceil();
    _spatialGrid = List.generate(
      _gridRows,
      (i) => List.generate(_gridCols, (j) => <Bubble>[]),
    );
    
    // 初始化性能优化组件
    _collisionLimiter = PerformanceOptimizer.FrameRateLimiter(
      minInterval: const Duration(milliseconds: 33), // 30 FPS for collision detection
    );
    
    _offsetPool = PerformanceOptimizer.ObjectPool<Offset>(
      factory: () => Offset.zero,
      reset: (offset) => offset = Offset.zero,
      maxSize: 100,
    );
  }
  
  /// 更新所有气泡的物理状态（优化版本）
  void updateBubbles(List<Bubble> bubbles, double deltaTime) {
    PerformanceOptimizer.PerformanceProfiler.startTiming('physics_total');
    
    // 清理空间分区网格
    _clearSpatialGrid();
    
    // 更新每个气泡的物理状态
    PerformanceOptimizer.PerformanceProfiler.startTiming('physics_individual');
    for (var bubble in bubbles) {
      if (!bubble.isVisible || bubble.isBeingDragged) continue;
    
      _updateBubblePhysics(bubble, deltaTime);
      _addToSpatialGrid(bubble);
    }
    PerformanceOptimizer.PerformanceProfiler.endTiming('physics_individual');
    
    // 处理碰撞检测（降低频率）
    if (_collisionLimiter.shouldUpdate()) {
      PerformanceOptimizer.PerformanceProfiler.startTiming('collision_detection');
      _handleOptimizedCollisions(bubbles);
      PerformanceOptimizer.PerformanceProfiler.endTiming('collision_detection');
    }
    
    // 定期清理缓存
    _cacheFrameCount++;
    if (_cacheFrameCount >= _cacheResetInterval) {
      _distanceCache.clear();
      _cacheFrameCount = 0;
    }
    
    PerformanceOptimizer.PerformanceProfiler.endTiming('physics_total');
  }
  
  /// 更新单个气泡的物理状态
  void _updateBubblePhysics(Bubble bubble, double deltaTime) {
    // 应用重力
    _applyGravity(bubble, deltaTime);
    
    // 应用布朗运动
    _applyBrownianMotion(bubble, deltaTime);
    
    // 应用摩擦力
    _applyFriction(bubble);
    
    // 限制速度
    _limitVelocity(bubble);
    
    // 更新位置
    _updatePosition(bubble, deltaTime);
    
    // 处理边界碰撞
    _handleBoundaryCollision(bubble);
  }
  
  /// 清理空间分区网格
  void _clearSpatialGrid() {
    for (var row in _spatialGrid) {
      for (var cell in row) {
        cell.clear();
      }
    }
  }
  
  /// 将气泡添加到空间分区网格
  void _addToSpatialGrid(Bubble bubble) {
    final gridX = (bubble.position.dx / gridSize).floor().clamp(0, _gridCols - 1);
    final gridY = (bubble.position.dy / gridSize).floor().clamp(0, _gridRows - 1);
    
    _spatialGrid[gridY][gridX].add(bubble);
  }
  
  /// 优化的碰撞检测
  void _handleOptimizedCollisions(List<Bubble> bubbles) {
    // 使用空间分区减少碰撞检测的复杂度
    for (int row = 0; row < _gridRows; row++) {
      for (int col = 0; col < _gridCols; col++) {
        final cellBubbles = _spatialGrid[row][col];
        if (cellBubbles.length < 2) continue;
        
        // 检测同一网格内的碰撞
        _checkCellCollisions(cellBubbles);
        
        // 检测相邻网格的碰撞
        _checkAdjacentCellCollisions(row, col, cellBubbles);
      }
    }
  }
  
  /// 检测同一网格内的碰撞
  void _checkCellCollisions(List<Bubble> bubbles) {
    for (int i = 0; i < bubbles.length - 1; i++) {
      for (int j = i + 1; j < bubbles.length; j++) {
        _checkBubbleCollision(bubbles[i], bubbles[j]);
      }
    }
  }
  
  /// 检测相邻网格的碰撞
  void _checkAdjacentCellCollisions(int row, int col, List<Bubble> cellBubbles) {
    // 检测右侧和下方的相邻网格（避免重复检测）
    final adjacentCells = [
      [row, col + 1], // 右
      [row + 1, col], // 下
      [row + 1, col + 1], // 右下
      [row + 1, col - 1], // 左下
    ];
    
    for (final adjacent in adjacentCells) {
      final adjRow = adjacent[0];
      final adjCol = adjacent[1];
      
      if (adjRow >= 0 && adjRow < _gridRows && adjCol >= 0 && adjCol < _gridCols) {
        final adjBubbles = _spatialGrid[adjRow][adjCol];
        
        for (final bubble1 in cellBubbles) {
          for (final bubble2 in adjBubbles) {
            _checkBubbleCollision(bubble1, bubble2);
          }
        }
      }
    }
  }
  
  /// 检测两个气泡之间的碰撞
  void _checkBubbleCollision(Bubble bubble1, Bubble bubble2) {
    if (bubble1.isBeingDragged || bubble2.isBeingDragged) return;
    
    final distance = _getCachedDistance(bubble1, bubble2);
    final minDistance = (bubble1.size + bubble2.size) / 2;
    
    if (distance < minDistance && distance > 0) {
      _resolveBubbleCollision(bubble1, bubble2, distance, minDistance);
    }
  }
  
  /// 获取缓存的距离计算
  double _getCachedDistance(Bubble bubble1, Bubble bubble2) {
    final key = '${bubble1.id}_${bubble2.id}';
    final reverseKey = '${bubble2.id}_${bubble1.id}';
    
    if (_distanceCache.containsKey(key)) {
      return _distanceCache[key]!;
    }
    if (_distanceCache.containsKey(reverseKey)) {
      return _distanceCache[reverseKey]!;
    }
    
    final distance = _calculateDistance(bubble1.position, bubble2.position);
    _distanceCache[key] = distance;
    return distance;
  }
  
  /// 计算两点之间的距离
  double _calculateDistance(Offset pos1, Offset pos2) {
    final dx = pos1.dx - pos2.dx;
    final dy = pos1.dy - pos2.dy;
    return sqrt(dx * dx + dy * dy);
  }
  
  /// 解决气泡碰撞
  void _resolveBubbleCollision(Bubble bubble1, Bubble bubble2, double distance, double minDistance) {
    // 计算碰撞方向
    final dx = bubble2.position.dx - bubble1.position.dx;
    final dy = bubble2.position.dy - bubble1.position.dy;
    
    // 归一化方向向量
    final normalX = dx / distance;
    final normalY = dy / distance;
    
    // 分离气泡
    final overlap = minDistance - distance;
    final separationX = normalX * overlap * 0.5;
    final separationY = normalY * overlap * 0.5;
    
    bubble1.position = Offset(
      bubble1.position.dx - separationX,
      bubble1.position.dy - separationY,
    );
    bubble2.position = Offset(
      bubble2.position.dx + separationX,
      bubble2.position.dy + separationY,
    );
    
    // 计算相对速度
    final relativeVelocityX = bubble2.velocity.dx - bubble1.velocity.dx;
    final relativeVelocityY = bubble2.velocity.dy - bubble1.velocity.dy;
    
    // 计算沿法线方向的相对速度
    final relativeVelocityInNormal = relativeVelocityX * normalX + relativeVelocityY * normalY;
    
    // 如果气泡正在分离，不需要处理碰撞
    if (relativeVelocityInNormal > 0) return;
    
    // 计算冲量
    final impulse = 2 * relativeVelocityInNormal / (bubble1.weight + bubble2.weight);
    
    // 应用冲量
    bubble1.velocity = Offset(
      bubble1.velocity.dx + impulse * bubble2.weight * normalX * collisionDamping,
      bubble1.velocity.dy + impulse * bubble2.weight * normalY * collisionDamping,
    );
    bubble2.velocity = Offset(
      bubble2.velocity.dx - impulse * bubble1.weight * normalX * collisionDamping,
      bubble2.velocity.dy - impulse * bubble1.weight * normalY * collisionDamping,
    );
  }
  
  /// 应用重力
  void _applyGravity(Bubble bubble, double deltaTime) {
    bubble.velocity = Offset(
      bubble.velocity.dx,
      bubble.velocity.dy + gravity * bubble.weight * deltaTime * 60,
    );
  }
  
  /// 应用布朗运动
  void _applyBrownianMotion(Bubble bubble, double deltaTime) {
    final randomX = (_random.nextDouble() - 0.5) * brownianMotionStrength;
    final randomY = (_random.nextDouble() - 0.5) * brownianMotionStrength;
    
    bubble.velocity = Offset(
      bubble.velocity.dx + randomX * deltaTime * 60,
      bubble.velocity.dy + randomY * deltaTime * 60,
    );
  }
  
  /// 应用摩擦力
  void _applyFriction(Bubble bubble) {
    bubble.velocity = Offset(
      bubble.velocity.dx * friction,
      bubble.velocity.dy * friction,
    );
  }
  
  /// 限制速度
  void _limitVelocity(Bubble bubble) {
    final speed = sqrt(bubble.velocity.dx * bubble.velocity.dx + bubble.velocity.dy * bubble.velocity.dy);
    
    if (speed < minVelocity) {
      bubble.velocity = Offset.zero;
    } else if (speed > maxVelocity) {
      final scale = maxVelocity / speed;
      bubble.velocity = Offset(
        bubble.velocity.dx * scale,
        bubble.velocity.dy * scale,
      );
    }
  }
  
  /// 更新位置
  void _updatePosition(Bubble bubble, double deltaTime) {
    bubble.position = Offset(
      bubble.position.dx + bubble.velocity.dx * deltaTime * 60,
      bubble.position.dy + bubble.velocity.dy * deltaTime * 60,
    );
  }
  
  /// 处理边界碰撞
  void _handleBoundaryCollision(Bubble bubble) {
    final radius = bubble.size / 2;
    var newX = bubble.position.dx;
    var newY = bubble.position.dy;
    var velocity = bubble.velocity;
    
    // 左边界
    if (bubble.position.dx - radius < 0) {
      newX = radius;
      velocity = Offset(-velocity.dx * bounceReduction, velocity.dy);
    }
    // 右边界
    else if (bubble.position.dx + radius > screenSize.width) {
      newX = screenSize.width - radius;
      velocity = Offset(-velocity.dx * bounceReduction, velocity.dy);
    }
    
    // 上边界
    if (bubble.position.dy - radius < 0) {
      newY = radius;
      velocity = Offset(velocity.dx, -velocity.dy * bounceReduction);
    }
    // 下边界
    else if (bubble.position.dy + radius > screenSize.height) {
      newY = screenSize.height - radius;
      velocity = Offset(velocity.dx, -velocity.dy * bounceReduction);
    }
    
    bubble.position = Offset(newX, newY);
    bubble.velocity = velocity;
  }
  
  /// 随机分布气泡（优化版本）
  void randomDistributeBubbles(List<Bubble> bubbles) {
    final usedPositions = <Offset>[];
    const minDistance = 80.0; // 最小间距
    const maxAttempts = 50; // 最大尝试次数
    
    for (var bubble in bubbles) {
      var attempts = 0;
      bool positionFound = false;
      
      while (attempts < maxAttempts && !positionFound) {
        final x = _random.nextDouble() * (screenSize.width - bubble.size) + bubble.size / 2;
        final y = _random.nextDouble() * (screenSize.height - bubble.size) + bubble.size / 2;
        final newPosition = Offset(x, y);
        
        // 检查与已有气泡的距离
        bool tooClose = false;
        for (final usedPos in usedPositions) {
          if (_calculateDistance(newPosition, usedPos) < minDistance) {
            tooClose = true;
            break;
          }
        }
        
        if (!tooClose) {
          bubble.position = newPosition;
          usedPositions.add(newPosition);
          positionFound = true;
        }
        
        attempts++;
      }
      
      // 如果找不到合适位置，使用随机位置
      if (!positionFound) {
        final x = _random.nextDouble() * (screenSize.width - bubble.size) + bubble.size / 2;
        final y = _random.nextDouble() * (screenSize.height - bubble.size) + bubble.size / 2;
        bubble.position = Offset(x, y);
      }
      
      // 初始化速度
      bubble.velocity = Offset(
        (_random.nextDouble() - 0.5) * 2,
        (_random.nextDouble() - 0.5) * 2,
      );
    }
  }
  
  /// 获取性能统计信息
  Map<String, dynamic> getPerformanceStats() {
    return {
      'grid_size': '$_gridCols x $_gridRows',
      'cache_size': _distanceCache.length,
      'cache_frame_count': _cacheFrameCount,
    };
  }
  
  /// 清理资源
  void dispose() {
    _distanceCache.clear();
    _clearSpatialGrid();
  }
}

  @override
  double applyPhysicsToUserOffset(ScrollMetrics position, double offset) {
    PerformanceOptimizer.PerformanceProfiler.startTiming('physics_total');
    final double delta = offset;
    final double newPosition = position.pixels - delta;

    // Apply boundary constraints
    final double newPixels = clampDouble(
      newPosition,
      position.minScrollExtent,
      position.maxScrollExtent,
    );

    PerformanceOptimizer.PerformanceProfiler.startTiming('physics_individual');
    // Apply custom physics logic here if needed
    // For now, it's a simple clamping physics
    PerformanceOptimizer.PerformanceProfiler.endTiming('physics_individual');

    // Collision detection and response (simplified example)
    if (newPixels != position.pixels) {
      // Check for collisions and adjust newPixels if necessary
      // This is a placeholder for actual collision logic
      PerformanceOptimizer.PerformanceProfiler.startTiming('collision_detection');
      // Example: if (collides(newPixels)) newPixels = adjustForCollision(newPixels);
      PerformanceOptimizer.PerformanceProfiler.endTiming('collision_detection');
    }

    PerformanceOptimizer.PerformanceProfiler.endTiming('physics_total');
    return position.pixels - newPixels;
  }
}