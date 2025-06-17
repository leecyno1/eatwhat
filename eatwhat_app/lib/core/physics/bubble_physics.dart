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

  void updateBubbles(List<Bubble> bubbles, double deltaTime) {
    for (var bubble in bubbles) {
      if (!bubble.isVisible || bubble.isBeingDragged) continue; // 如果气泡不可见或正在被拖拽，则跳过物理计算

      _applyGravity(bubble, deltaTime);
      _applyFriction(bubble); // 修正：移除deltaTime参数
      bubble.position += bubble.velocity * deltaTime; // 直接更新位置
      _handleBoundaryCollision(bubble);
    }
    _handleBubbleCollisions(bubbles);
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

  void _handleBoundaryCollision(Bubble bubble) {
    double newX = bubble.position.dx;
    double newY = bubble.position.dy;
    Offset velocity = bubble.velocity;

    final radius = bubble.size / 2;
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
    
    bubble.position = Offset(newX, newY);
    bubble.velocity = velocity;
  }

  /// 处理气泡间碰撞
  void _handleBubbleCollisions(List<Bubble> bubbles) {
    for (int i = 0; i < bubbles.length; i++) {
      for (int j = i + 1; j < bubbles.length; j++) {
        final bubble1 = bubbles[i];
        final bubble2 = bubbles[j];
        
        if (!bubble1.isVisible || !bubble2.isVisible) continue;
        
        final distance = (bubble1.position - bubble2.position).distance;
        final minDistance = (bubble1.currentDisplaySize + bubble2.currentDisplaySize) / 2;
        
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

  /// 限制气泡位置在屏幕边界内
  Offset clampBubblePosition(Bubble bubble, Offset targetPosition) {
    final radius = bubble.size / 2;
    double x = targetPosition.dx;
    double y = targetPosition.dy;

    if (x - radius < 0) {
      x = radius;
    } else if (x + radius > screenSize.width) {
      x = screenSize.width - radius;
    }

    if (y - radius < 0) {
      y = radius;
    } else if (y + radius > screenSize.height) {
      y = screenSize.height - radius;
    }
    return Offset(x, y);
  }

  /// 设置气泡位置
  void setBubblePosition(Bubble bubble, Offset position) {
    bubble.position = position;
  }

  /// 获取气泡在指定位置的速度
  Offset getBubbleVelocityAtPosition(Bubble bubble, Offset position) {
    return bubble.velocity;
  }

  /// 从指定位置排斥气泡
  void repelBubblesFromPosition(List<Bubble> bubbles, Offset position, {double strength = 1.0}) {
    for (final bubble in bubbles) {
      if (!bubble.isVisible) continue;

      final direction = bubble.position - position;
      final distance = direction.distance;

      if (distance < 100 && distance > 0) { // 只影响近距离的气泡
        final forceMagnitude = strength * 500 / (distance * distance + 1); // 反比于距离平方的力
        final force = direction / distance * forceMagnitude;
        bubble.velocity = bubble.velocity + force / bubble.weight;
      }
    }
  }

  /// 在指定位置施加力
  void addForceAtPosition(List<Bubble> bubbles, Offset position, Offset force, {double radius = 50.0}) {
    for (final bubble in bubbles) {
      if (!bubble.isVisible) continue;

      final distance = (bubble.position - position).distance;
      if (distance < radius) {
        // 根据距离衰减力的大小
        final falloff = 1.0 - (distance / radius);
        bubble.velocity = bubble.velocity + force * falloff / bubble.weight;
      }
    }
  }
}