import 'package:flutter/material.dart';
import 'dart:math';
import '../models/physical_entity.dart';

/// 零重力物理引擎 - 处理实体在零重力环境下的运动和碰撞
class ZeroGravityPhysics {
  static const double _timeStep = 1.0 / 60.0; // 60 FPS for smoother movement
  static const double _maxSpeed = 0.5; // 极大降低最大速度
  static const double _boundaryDamping = 0.8; // 极大增加边界阻尼
  static const double _airResistance = 0.98; // 更强的空气阻力
  static const double _separationForce = 1.0; // 极大降低分离力强度
  static const double _minSeparationDistance = 1.02; // 微调分离距离
  
  /// 更新所有实体的物理状态
  static void updatePhysics(List<PhysicalEntity> entities, Size containerSize, {double deltaTime = _timeStep}) {
    // 1. 重置所有实体的加速度
    for (final entity in entities) {
      entity.resetAcceleration();
    }
    
    // 2. 处理实体间的碰撞
    _handleEntityCollisions(entities);
    
    // 3. 更新每个实体的物理状态
    for (final entity in entities) {
      _updateEntityPhysics(entity, deltaTime);
      _handleBoundaryCollisions(entity, containerSize);
      _limitSpeed(entity);
    }
  }

  /// 处理实体间的碰撞检测和响应
  static void _handleEntityCollisions(List<PhysicalEntity> entities) {
    for (int i = 0; i < entities.length; i++) {
      for (int j = i + 1; j < entities.length; j++) {
        final entity1 = entities[i];
        final entity2 = entities[j];
        
        if (_detectCollision(entity1, entity2)) {
          _resolveCollision(entity1, entity2);
        }
      }
    }
  }

  /// 检测两个实体是否碰撞
  static bool _detectCollision(PhysicalEntity entity1, PhysicalEntity entity2) {
    final distance = (entity1.position - entity2.position).distance;
    return distance < (entity1.radius + entity2.radius);
  }

  /// 解决碰撞 - 弹性碰撞模型
  static void _resolveCollision(PhysicalEntity entity1, PhysicalEntity entity2) {
    final distance = (entity1.position - entity2.position).distance;
    
    // 防止除零错误
    if (distance == 0) return;
    
    // 计算碰撞法向量
    final collisionNormal = (entity2.position - entity1.position) / distance;
    
    // 温和分离重叠的实体
    final minDistance = (entity1.radius + entity2.radius) * _minSeparationDistance;
    final overlap = minDistance - distance;
    if (overlap > 0) {
      // 使用温和的分离力
      final separationDistance = overlap * 0.5;
      final separation = collisionNormal * separationDistance;
      entity1.position = entity1.position - separation;
      entity2.position = entity2.position + separation;
      
      // 温和的分离速度
      final separationVelocity = collisionNormal * (overlap * 0.1);
      entity1.velocity = entity1.velocity - separationVelocity;
      entity2.velocity = entity2.velocity + separationVelocity;
    }
    
    // 计算相对速度
    final relativeVelocity = entity1.velocity - entity2.velocity;
    final velocityAlongNormal = relativeVelocity.dx * collisionNormal.dx + 
                               relativeVelocity.dy * collisionNormal.dy;
    
    // 如果物体正在分离，不需要处理碰撞
    if (velocityAlongNormal > 0) return;
    
    // 计算反弹系数 (取两个实体中较小的值) - 大幅降低反弹
    final restitution = min(entity1.bounciness, entity2.bounciness) * 0.1;
    
    // 计算碰撞冲量标量
    final impulseScalar = -(1 + restitution) * velocityAlongNormal / 
                         (1 / entity1.mass + 1 / entity2.mass);
    
    // 计算冲量向量
    final impulse = collisionNormal * impulseScalar;
    
    // 应用冲量到速度
    entity1.velocity = entity1.velocity + impulse / entity1.mass;
    entity2.velocity = entity2.velocity - impulse / entity2.mass;
    
    // 禁用旋转效果以避免混乱
    // final rotationFactor = impulseScalar * 0.001;
    // entity1.angularVelocity += (Random().nextDouble() - 0.5) * rotationFactor;
    // entity2.angularVelocity += (Random().nextDouble() - 0.5) * rotationFactor;
    
    // 更新最后交互时间
    final now = DateTime.now();
    entity1.lastInteraction = now;
    entity2.lastInteraction = now;
  }

  /// 更新单个实体的物理状态 - 稳定版本
  static void _updateEntityPhysics(PhysicalEntity entity, double deltaTime) {
    // 限制deltaTime防止突变
    deltaTime = deltaTime.clamp(0.0, 0.033); // 最外30fps
    
    // 更新速度：v = v0 + a*t （先做加速度）
    entity.velocity = Offset(
      entity.velocity.dx + entity.acceleration.dx * deltaTime,
      entity.velocity.dy + entity.acceleration.dy * deltaTime,
    );
    
    // 然后应用阻力
    entity.velocity = Offset(
      entity.velocity.dx * _airResistance,
      entity.velocity.dy * _airResistance,
    );
    
    // 更新位置：p = p0 + v*t
    entity.position = Offset(
      entity.position.dx + entity.velocity.dx * deltaTime,
      entity.position.dy + entity.velocity.dy * deltaTime,
    );
    
    // 温和的角速度减少
    entity.angularVelocity *= 0.95;
    
    // 更新旋转
    entity.rotation += entity.angularVelocity * deltaTime;
    entity.rotation = entity.rotation % (2 * pi);
  }

  /// 处理边界碰撞
  static void _handleBoundaryCollisions(PhysicalEntity entity, Size containerSize) {
    bool collided = false;
    
    // 左边界 - 极大阻尼
    if (entity.position.dx - entity.radius < 0) {
      entity.position = Offset(entity.radius, entity.position.dy);
      entity.velocity = Offset(-entity.velocity.dx * _boundaryDamping, entity.velocity.dy * 0.9);
      entity.angularVelocity *= 0.5;
      collided = true;
    }
    
    // 右边界 - 极大阻尼
    if (entity.position.dx + entity.radius > containerSize.width) {
      entity.position = Offset(containerSize.width - entity.radius, entity.position.dy);
      entity.velocity = Offset(-entity.velocity.dx * _boundaryDamping, entity.velocity.dy * 0.9);
      entity.angularVelocity *= 0.5;
      collided = true;
    }
    
    // 上边界 - 极大阻尼
    if (entity.position.dy - entity.radius < 0) {
      entity.position = Offset(entity.position.dx, entity.radius);
      entity.velocity = Offset(entity.velocity.dx * 0.9, -entity.velocity.dy * _boundaryDamping);
      entity.angularVelocity *= 0.5;
      collided = true;
    }
    
    // 下边界 - 极大阻尼
    if (entity.position.dy + entity.radius > containerSize.height) {
      entity.position = Offset(entity.position.dx, containerSize.height - entity.radius);
      entity.velocity = Offset(entity.velocity.dx * 0.9, -entity.velocity.dy * _boundaryDamping);
      entity.angularVelocity *= 0.5;
      collided = true;
    }
    
    if (collided) {
      entity.lastInteraction = DateTime.now();
    }
  }

  /// 限制实体的最大速度 - 加强版
  static void _limitSpeed(PhysicalEntity entity) {
    final speed = entity.velocity.distance;
    
    // 应急制动系统 - 如果速度太高直接停止
    if (speed > _maxSpeed * 1.5) {
      entity.velocity = entity.velocity * 0.1; // 急剧减速而不是完全停止
      entity.angularVelocity *= 0.1;
      return;
    }
    
    // 正常速度限制
    if (speed > _maxSpeed) {
      entity.velocity = (entity.velocity * _maxSpeed) / speed;
    }
    
    // 极低的角速度限制
    const maxAngularSpeed = 0.05; // 进一步降低角速度
    if (entity.angularVelocity.abs() > maxAngularSpeed) {
      entity.angularVelocity = entity.angularVelocity.sign * maxAngularSpeed;
    }
    
    // 更强的角速度衰减
    entity.angularVelocity *= 0.95;
  }

  /// 应用排斥力 - 用于用户交互
  static void applyRepulsionForce(List<PhysicalEntity> entities, Offset center, double radius, double strength) {
    for (final entity in entities) {
      final distance = (entity.position - center).distance;
      
      if (distance < radius && distance > 0) {
        // 计算排斥方向
        final direction = (entity.position - center) / distance;
        
        // 计算力的强度 (距离越近力越大)
        final forceMagnitude = strength * (1.0 - distance / radius);
        final force = direction * forceMagnitude;
        
        // 应用力
        entity.applyForce(force);
        
        // 添加一些旋转效果（减少强度）
        entity.angularVelocity += (Random().nextDouble() - 0.5) * forceMagnitude * 0.003;
        
        entity.lastInteraction = DateTime.now();
      }
    }
  }

  /// 应用吸引力 - 可用于特殊效果
  static void applyAttractionForce(List<PhysicalEntity> entities, Offset center, double radius, double strength) {
    for (final entity in entities) {
      final distance = (entity.position - center).distance;
      
      if (distance < radius && distance > 0) {
        // 计算吸引方向
        final direction = (center - entity.position) / distance;
        
        // 计算力的强度
        final forceMagnitude = strength * (distance / radius);
        final force = direction * forceMagnitude;
        
        // 应用力
        entity.applyForce(force);
        
        entity.lastInteraction = DateTime.now();
      }
    }
  }

  /// 应用涡旋力 - 创造旋转效果
  static void applyVortexForce(List<PhysicalEntity> entities, Offset center, double radius, double strength) {
    for (final entity in entities) {
      final distance = (entity.position - center).distance;
      
      if (distance < radius && distance > 0) {
        final direction = (entity.position - center) / distance;
        
        // 创建垂直于径向的切向力
        final tangent = Offset(-direction.dy, direction.dx);
        
        final forceMagnitude = strength * (1.0 - distance / radius);
        final force = tangent * forceMagnitude;
        
        entity.applyForce(force);
        // 禁用旋转效果
        // entity.angularVelocity += strength * 0.003;
        
        entity.lastInteraction = DateTime.now();
      }
    }
  }

  /// 应用随机扰动 - 防止系统过于静止（减少频率和强度）
  static void applyRandomDisturbance(List<PhysicalEntity> entities, double strength) {
    final random = Random();
    
    for (final entity in entities) {
      // 大幅增加触发时间，减少扰动强度
      final timeSinceInteraction = DateTime.now().difference(entity.lastInteraction).inSeconds;
      final speed = entity.velocity.distance;
      
      if (timeSinceInteraction > 120 && speed < 0.5) { // 120秒后才触发，速度更低
        final randomForce = Offset(
          (random.nextDouble() - 0.5) * strength * 0.005, // 进一步减少强度
          (random.nextDouble() - 0.5) * strength * 0.005,
        );
        
        entity.applyForce(randomForce);
        entity.angularVelocity += (random.nextDouble() - 0.5) * 0.001; // 大幅减少旋转
      }
    }
  }

  /// 计算系统总动能
  static double calculateTotalKineticEnergy(List<PhysicalEntity> entities) {
    double totalEnergy = 0.0;
    for (final entity in entities) {
      totalEnergy += entity.kineticEnergy;
    }
    return totalEnergy;
  }

  /// 检查系统是否接近静止状态
  static bool isSystemNearlyAtRest(List<PhysicalEntity> entities, {double threshold = 100.0}) {
    return calculateTotalKineticEnergy(entities) < threshold;
  }

  /// 重新分布实体位置 (避免重叠)
  static void redistributeEntities(List<PhysicalEntity> entities, Size containerSize) {
    const double minDistance = 80.0;
    const int maxAttempts = 100;
    final random = Random();
    
    for (int i = 0; i < entities.length; i++) {
      bool positioned = false;
      int attempts = 0;
      
      while (!positioned && attempts < maxAttempts) {
        final x = entities[i].radius + random.nextDouble() * 
                 (containerSize.width - 2 * entities[i].radius);
        final y = entities[i].radius + random.nextDouble() * 
                 (containerSize.height - 2 * entities[i].radius);
        final newPosition = Offset(x, y);
        
        // 检查与其他实体的距离
        bool tooClose = false;
        for (int j = 0; j < i; j++) {
          if ((newPosition - entities[j].position).distance < minDistance) {
            tooClose = true;
            break;
          }
        }
        
        if (!tooClose) {
          entities[i] = entities[i].copyWith(position: newPosition);
          positioned = true;
        }
        
        attempts++;
      }
      
      // 如果无法找到合适位置，强制放置
      if (!positioned) {
        final x = entities[i].radius + random.nextDouble() * 
                 (containerSize.width - 2 * entities[i].radius);
        final y = entities[i].radius + random.nextDouble() * 
                 (containerSize.height - 2 * entities[i].radius);
        entities[i] = entities[i].copyWith(position: Offset(x, y));
      }
    }
  }
}