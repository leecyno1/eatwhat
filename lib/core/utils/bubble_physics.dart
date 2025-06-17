import 'dart:math';
import 'package:flutter/material.dart';
import '../models/bubble.dart';

/// 气泡物理引擎
class BubblePhysics {
  static const double _gravity = 0.0;          // 重力设为0
  static const double _damping = 0.98;         // 更强阻尼
  static const double _bounceForce = 0.8;      // 适中弹性
  static const double _brownianForce = 0.15;   // 增加布朗运动
  static const double _minVelocity = 0.01;     // 降低最小速度阈值
  static const double _repulsionForce = 20.0;  // 适中气泡间斥力
  static const double _maxVelocity = 5.0;      // 添加最大速度限制
  
  final Random _random = Random();
  final Size screenSize;
  
  BubblePhysics({required this.screenSize});

  /// 更新气泡物理状态
  void updateBubbles(List<Bubble> bubbles, double deltaTime) {
    // 先计算所有气泡间的相互作用力
    for (int i = 0; i < bubbles.length; i++) {
      final bubble = bubbles[i];
      
      // 应用气泡间斥力
      for (int j = 0; j < bubbles.length; j++) {
        if (i != j) {
          _applyRepulsionForce(bubble, bubbles[j]);
        }
      }
    }
    
    // 然后更新每个气泡的物理状态
    for (int i = 0; i < bubbles.length; i++) {
      final bubble = bubbles[i];
      
      // 应用布朗运动（仅当气泡未被选中时）
      if (!bubble.isSelected) {
        _applyBrownianMotion(bubble);
      }
      
      // 应用重力（现在为0）
      _applyGravity(bubble);
      
      // 更新位置
      _updatePosition(bubble, deltaTime);
      
      // 边界碰撞检测
      _handleBoundaryCollision(bubble);
      
      // 气泡间精确碰撞检测
      for (int j = i + 1; j < bubbles.length; j++) {
        _handleBubbleCollision(bubble, bubbles[j]);
      }
      
      // 应用阻尼
      _applyDamping(bubble);
    }
  }

  /// 应用布朗运动
  void _applyBrownianMotion(Bubble bubble) {
    if (!bubble.isAnimating) {
      final randomX = (_random.nextDouble() - 0.5) * _brownianForce;
      final randomY = (_random.nextDouble() - 0.5) * _brownianForce;
      
      bubble.velocity = Offset(
        bubble.velocity.dx + randomX,
        bubble.velocity.dy + randomY,
      );
    }
  }

  /// 应用气泡间斥力
  void _applyRepulsionForce(Bubble bubble1, Bubble bubble2) {
    final distance = _calculateDistance(bubble1.position, bubble2.position);
    final influenceRadius = (bubble1.size + bubble2.size) / 2 + 40; // 斥力影响范围
    
    if (distance < influenceRadius && distance > 0) {
      // 计算斥力方向
      final dx = bubble1.position.dx - bubble2.position.dx;
      final dy = bubble1.position.dy - bubble2.position.dy;
      
      // 归一化方向向量
      final normalX = dx / distance;
      final normalY = dy / distance;
      
      // 计算斥力大小（距离越近力越大）
      final forceStrength = _repulsionForce * (1 - distance / influenceRadius);
      
      // 应用斥力到bubble1
      bubble1.velocity = Offset(
        bubble1.velocity.dx + normalX * forceStrength * 0.01,
        bubble1.velocity.dy + normalY * forceStrength * 0.01,
      );
    }
  }

  /// 应用重力
  void _applyGravity(Bubble bubble) {
    // 重力完全设为0，不应用任何重力效果
    // 保留此方法以便后续需要时重新启用重力
  }

  /// 更新位置
  void _updatePosition(Bubble bubble, double deltaTime) {
    // 限制最大速度
    final speed = bubble.velocity.distance;
    if (speed > _maxVelocity) {
      bubble.velocity = Offset(
        bubble.velocity.dx / speed * _maxVelocity,
        bubble.velocity.dy / speed * _maxVelocity,
      );
    }
    
    bubble.position = Offset(
      bubble.position.dx + bubble.velocity.dx * deltaTime * 60,
      bubble.position.dy + bubble.velocity.dy * deltaTime * 60,
    );
  }

  /// 处理边界碰撞
  void _handleBoundaryCollision(Bubble bubble) {
    final radius = bubble.size / 2;
    bool collided = false;
    
    // 左边界
    if (bubble.position.dx - radius <= 0) {
      bubble.position = Offset(radius, bubble.position.dy);
      if (bubble.velocity.dx < 0) {
        bubble.velocity = Offset(
          -bubble.velocity.dx * _bounceForce,
          bubble.velocity.dy,
        );
        collided = true;
      }
    }
    
    // 右边界
    if (bubble.position.dx + radius >= screenSize.width) {
      bubble.position = Offset(screenSize.width - radius, bubble.position.dy);
      if (bubble.velocity.dx > 0) {
        bubble.velocity = Offset(
          -bubble.velocity.dx * _bounceForce,
          bubble.velocity.dy,
        );
        collided = true;
      }
    }
    
    // 上边界
    if (bubble.position.dy - radius <= 0) {
      bubble.position = Offset(bubble.position.dx, radius);
      if (bubble.velocity.dy < 0) {
        bubble.velocity = Offset(
          bubble.velocity.dx,
          -bubble.velocity.dy * _bounceForce,
        );
        collided = true;
      }
    }
    
    // 下边界
    if (bubble.position.dy + radius >= screenSize.height) {
      bubble.position = Offset(bubble.position.dx, screenSize.height - radius);
      if (bubble.velocity.dy > 0) {
        bubble.velocity = Offset(
          bubble.velocity.dx,
          -bubble.velocity.dy * _bounceForce,
        );
        collided = true;
      }
    }
    
    // 如果发生碰撞，添加一些随机性避免气泡卡在边界
    if (collided) {
      bubble.velocity = Offset(
        bubble.velocity.dx + (_random.nextDouble() - 0.5) * 0.2,
        bubble.velocity.dy + (_random.nextDouble() - 0.5) * 0.2,
      );
    }
  }

  /// 处理气泡间碰撞
  void _handleBubbleCollision(Bubble bubble1, Bubble bubble2) {
    final distance = _calculateDistance(bubble1.position, bubble2.position);
    final minDistance = (bubble1.size + bubble2.size) / 2;
    
    if (distance < minDistance && distance > 0) {
      // 计算碰撞向量
      final dx = bubble2.position.dx - bubble1.position.dx;
      final dy = bubble2.position.dy - bubble1.position.dy;
      
      // 归一化
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
      
      // 计算相对速度在法线方向的分量
      final velocityAlongNormal = relativeVelocityX * normalX + relativeVelocityY * normalY;
      
      // 如果气泡正在分离，不处理碰撞
      if (velocityAlongNormal > 0) return;
      
      // 计算反弹速度
      final restitution = _bounceForce;
      final impulse = -(1 + restitution) * velocityAlongNormal;
      
      // 应用冲量
      bubble1.velocity = Offset(
        bubble1.velocity.dx - impulse * normalX * 0.5,
        bubble1.velocity.dy - impulse * normalY * 0.5,
      );
      
      bubble2.velocity = Offset(
        bubble2.velocity.dx + impulse * normalX * 0.5,
        bubble2.velocity.dy + impulse * normalY * 0.5,
      );
    }
  }

  /// 应用阻尼
  void _applyDamping(Bubble bubble) {
    bubble.velocity = Offset(
      bubble.velocity.dx * _damping,
      bubble.velocity.dy * _damping,
    );
    
    // 如果速度太小，设为0
    if (bubble.velocity.distance < _minVelocity) {
      bubble.velocity = Offset.zero;
    }
  }

  /// 计算两点间距离
  double _calculateDistance(Offset point1, Offset point2) {
    final dx = point2.dx - point1.dx;
    final dy = point2.dy - point1.dy;
    return sqrt(dx * dx + dy * dy);
  }

  /// 添加爆炸效果
  void addExplosion(Offset center, List<Bubble> bubbles, double force) {
    for (final bubble in bubbles) {
      final distance = _calculateDistance(center, bubble.position);
      if (distance < 200) { // 爆炸影响范围
        final dx = bubble.position.dx - center.dx;
        final dy = bubble.position.dy - center.dy;
        
        if (distance > 0) {
          final normalX = dx / distance;
          final normalY = dy / distance;
          
          // 根据距离计算力的大小
          final actualForce = force * (1 - distance / 200);
          
          bubble.velocity = Offset(
            bubble.velocity.dx + normalX * actualForce,
            bubble.velocity.dy + normalY * actualForce,
          );
        }
      }
    }
  }

  /// 添加吸引效果
  void addAttraction(Offset center, List<Bubble> bubbles, double force) {
    for (final bubble in bubbles) {
      final distance = _calculateDistance(center, bubble.position);
      if (distance < 150 && distance > 20) { // 吸引范围，避免太近
        final dx = center.dx - bubble.position.dx;
        final dy = center.dy - bubble.position.dy;
        
        final normalX = dx / distance;
        final normalY = dy / distance;
        
        // 根据距离计算力的大小
        final actualForce = force * (1 - distance / 150);
        
        bubble.velocity = Offset(
          bubble.velocity.dx + normalX * actualForce,
          bubble.velocity.dy + normalY * actualForce,
        );
      }
    }
  }

  /// 随机分布气泡
  void randomDistributeBubbles(List<Bubble> bubbles) {
    for (final bubble in bubbles) {
      final radius = bubble.size / 2;
      bubble.position = Offset(
        radius + _random.nextDouble() * (screenSize.width - bubble.size),
        radius + _random.nextDouble() * (screenSize.height - bubble.size),
      );
      
      // 给予更小的随机初始速度
      bubble.velocity = Offset(
        (_random.nextDouble() - 0.5) * 1.0,
        (_random.nextDouble() - 0.5) * 1.0,
      );
    }
  }

  /// 圆形分布气泡
  void circularDistributeBubbles(List<Bubble> bubbles, Offset center, double radius) {
    for (int i = 0; i < bubbles.length; i++) {
      final angle = (i / bubbles.length) * 2 * pi;
      final bubbleRadius = bubbles[i].size / 2;
      
      // 确保气泡位置在屏幕边界内
      final x = (center.dx + cos(angle) * radius).clamp(
        bubbleRadius, 
        screenSize.width - bubbleRadius
      );
      final y = (center.dy + sin(angle) * radius).clamp(
        bubbleRadius, 
        screenSize.height - bubbleRadius
      );
      
      bubbles[i].position = Offset(x, y);
      
      // 给予更小的随机初始速度
      bubbles[i].velocity = Offset(
        (_random.nextDouble() - 0.5) * 0.8,
        (_random.nextDouble() - 0.5) * 0.8,
      );
    }
  }

  /// 应用手势力
  void applyGestureForce(Bubble bubble, Offset gestureVelocity) {
    bubble.velocity = Offset(
      bubble.velocity.dx + gestureVelocity.dx * 0.01,
      bubble.velocity.dy + gestureVelocity.dy * 0.01,
    );
  }

  /// 检查气泡是否静止
  bool isBubbleAtRest(Bubble bubble) {
    return bubble.velocity.distance < _minVelocity;
  }

  /// 获取气泡动能
  double getBubbleKineticEnergy(Bubble bubble) {
    return 0.5 * bubble.velocity.distance * bubble.velocity.distance;
  }
} 