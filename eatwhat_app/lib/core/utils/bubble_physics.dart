import 'dart:math';
import 'package:flutter/material.dart';
import '../models/bubble.dart';

/// 气泡物理引擎
class BubblePhysics {
  static const double gravity = 0.0;
  static const double friction = 0.98;
  static const double bounceReduction = 0.7;
  static const double brownianMotionStrength = 0.5;
  static const double minVelocity = 0.01;
  static const double maxVelocity = 5.0;

  final Random _random = Random();
  final Size screenSize;
  
  BubblePhysics({required this.screenSize});

  /// 更新气泡物理状态
  void updateBubble(Bubble bubble, double deltaTime) {
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

  /// 更新所有气泡
  void updateBubbles(List<Bubble> bubbles, double deltaTime) {
    for (final bubble in bubbles) {
      if (bubble.isVisible) {
        updateBubble(bubble, deltaTime);
      }
    }
    
    // 处理气泡间碰撞
    _handleBubbleCollisions(bubbles);
  }

  /// 应用重力
  void _applyGravity(Bubble bubble, double deltaTime) {
    // 重力设为0，不应用任何重力效果
    // 保留此方法以便后续需要时重新启用重力
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
    final speed = bubble.velocity.distance;
    if (speed > maxVelocity) {
      bubble.velocity = bubble.velocity / speed * maxVelocity;
    } else if (speed < minVelocity) {
      bubble.velocity = Offset.zero;
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
    
    // 左右边界
    if (bubble.position.dx - radius < 0) {
      bubble.position = Offset(radius, bubble.position.dy);
      bubble.velocity = Offset(
        -bubble.velocity.dx * bounceReduction,
        bubble.velocity.dy,
      );
    } else if (bubble.position.dx + radius > screenSize.width) {
      bubble.position = Offset(screenSize.width - radius, bubble.position.dy);
      bubble.velocity = Offset(
        -bubble.velocity.dx * bounceReduction,
        bubble.velocity.dy,
      );
    }
    
    // 上下边界
    if (bubble.position.dy - radius < 0) {
      bubble.position = Offset(bubble.position.dx, radius);
      bubble.velocity = Offset(
        bubble.velocity.dx,
        -bubble.velocity.dy * bounceReduction,
      );
    } else if (bubble.position.dy + radius > screenSize.height) {
      bubble.position = Offset(bubble.position.dx, screenSize.height - radius);
      bubble.velocity = Offset(
        bubble.velocity.dx,
        -bubble.velocity.dy * bounceReduction,
      );
    }
  }

  /// 处理气泡间碰撞
  void _handleBubbleCollisions(List<Bubble> bubbles) {
    for (int i = 0; i < bubbles.length; i++) {
      for (int j = i + 1; j < bubbles.length; j++) {
        final bubble1 = bubbles[i];
        final bubble2 = bubbles[j];
        
        if (!bubble1.isVisible || !bubble2.isVisible) continue;
        
        final distance = (bubble1.position - bubble2.position).distance;
        final minDistance = (bubble1.size + bubble2.size) / 2;
        
        if (distance < minDistance && distance > 0) {
          _resolveBubbleCollision(bubble1, bubble2, distance, minDistance);
        }
      }
    }
  }

  /// 解决气泡碰撞
  void _resolveBubbleCollision(Bubble bubble1, Bubble bubble2, double distance, double minDistance) {
    final overlap = minDistance - distance;
    final direction = (bubble2.position - bubble1.position) / distance;
    
    // 分离气泡
    final separation = direction * (overlap / 2);
    bubble1.position = bubble1.position - separation;
    bubble2.position = bubble2.position + separation;
    
    // 计算碰撞后的速度
    final relativeVelocity = bubble1.velocity - bubble2.velocity;
    final velocityAlongNormal = relativeVelocity.dx * direction.dx + relativeVelocity.dy * direction.dy;
    
    if (velocityAlongNormal > 0) return; // 气泡正在分离
    
    const restitution = 0.8; // 弹性系数
    final impulse = 2 * velocityAlongNormal / (bubble1.weight + bubble2.weight);
    
    bubble1.velocity = bubble1.velocity - Offset(
      impulse * bubble2.weight * direction.dx * restitution,
      impulse * bubble2.weight * direction.dy * restitution,
    );
    
    bubble2.velocity = bubble2.velocity + Offset(
      impulse * bubble1.weight * direction.dx * restitution,
      impulse * bubble1.weight * direction.dy * restitution,
    );
  }

  /// 随机分布气泡
  void randomDistributeBubbles(List<Bubble> bubbles) {
    for (final bubble in bubbles) {
      bubble.position = Offset(
        _random.nextDouble() * (screenSize.width - bubble.size) + bubble.size / 2,
        _random.nextDouble() * (screenSize.height - bubble.size) + bubble.size / 2,
      );
      
      bubble.velocity = Offset(
        (_random.nextDouble() - 0.5) * 2,
        (_random.nextDouble() - 0.5) * 2,
      );
    }
  }

  /// 添加力到气泡
  void addForce(Bubble bubble, Offset force) {
    bubble.velocity = bubble.velocity + force / bubble.weight;
  }

  /// 设置气泡位置
  void setBubblePosition(Bubble bubble, Offset position) {
    bubble.position = position;
  }

  /// 获取气泡在指定位置的速度
  Offset getBubbleVelocityAtPosition(Bubble bubble, Offset position) {
    return bubble.velocity;
  }
} 