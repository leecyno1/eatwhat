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
  static const double _viscosity = 0.10; // 液体粘滞系数（0-1，越大越粘）
  static const double _edgeViscosityBoost = 0.15; // 边缘额外粘滞，形成缓冲
  static const double _springStiffness = 0.20; // 边界弹簧刚度
  static const double _springDamping = 0.65; // 边界弹簧阻尼系数

  /// 更新所有实体的物理状态
  static void updatePhysics(List<PhysicalEntity> entities, Size containerSize,
      {double deltaTime = _timeStep}) {
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
    final velocityAlongNormal =
        relativeVelocity.dx * collisionNormal.dx + relativeVelocity.dy * collisionNormal.dy;

    // 如果物体正在分离，不需要处理碰撞
    if (velocityAlongNormal > 0) return;

    // 弹簧-阻尼模型：柔和碰撞
    final restitution = min(entity1.bounciness, entity2.bounciness) * 0.08; // 更柔和
    final springForce = overlap * 0.5; // 重叠越大，弹力越大
    final dampingForce = velocityAlongNormal * 0.6; // 阻尼，减少反弹
    final impulseScalar = (-(1 + restitution) * velocityAlongNormal - springForce + dampingForce) /
        (1 / entity1.mass + 1 / entity2.mass);

    final impulse = collisionNormal * impulseScalar;
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

    // 然后应用阻力（基础空气阻力 + 液体粘滞）
    final base = _airResistance;
    double viscous = 1.0 - _viscosity;
    entity.velocity = Offset(
      entity.velocity.dx * base * viscous,
      entity.velocity.dy * base * viscous,
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
      // 边界弹簧回弹 + 额外粘滞
      final penetration = entity.radius - entity.position.dx;
      final spring = _springStiffness * penetration;
      final damping = _springDamping * entity.velocity.dx;
      entity.position = Offset(entity.radius, entity.position.dy);
      entity.velocity = Offset((-entity.velocity.dx * _boundaryDamping) + spring - damping,
          entity.velocity.dy * (0.9 - _edgeViscosityBoost));
      entity.angularVelocity *= 0.5;
      collided = true;
    }

    // 右边界 - 极大阻尼
    if (entity.position.dx + entity.radius > containerSize.width) {
      final penetration = (entity.position.dx + entity.radius) - containerSize.width;
      final spring = _springStiffness * penetration;
      final damping = _springDamping * entity.velocity.dx;
      entity.position = Offset(containerSize.width - entity.radius, entity.position.dy);
      entity.velocity = Offset((-entity.velocity.dx * _boundaryDamping) - spring - damping,
          entity.velocity.dy * (0.9 - _edgeViscosityBoost));
      entity.angularVelocity *= 0.5;
      collided = true;
    }

    // 上边界 - 极大阻尼
    if (entity.position.dy - entity.radius < 0) {
      final penetration = entity.radius - entity.position.dy;
      final spring = _springStiffness * penetration;
      final damping = _springDamping * entity.velocity.dy;
      entity.position = Offset(entity.position.dx, entity.radius);
      entity.velocity = Offset(entity.velocity.dx * (0.9 - _edgeViscosityBoost),
          (-entity.velocity.dy * _boundaryDamping) + spring - damping);
      entity.angularVelocity *= 0.5;
      collided = true;
    }

    // 下边界 - 极大阻尼
    if (entity.position.dy + entity.radius > containerSize.height) {
      final penetration = (entity.position.dy + entity.radius) - containerSize.height;
      final spring = _springStiffness * penetration;
      final damping = _springDamping * entity.velocity.dy;
      entity.position = Offset(entity.position.dx, containerSize.height - entity.radius);
      entity.velocity = Offset(entity.velocity.dx * (0.9 - _edgeViscosityBoost),
          (-entity.velocity.dy * _boundaryDamping) - spring - damping);
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
  static void applyRepulsionForce(
      List<PhysicalEntity> entities, Offset center, double radius, double strength) {
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
  static void applyAttractionForce(
      List<PhysicalEntity> entities, Offset center, double radius, double strength) {
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
  static void applyVortexForce(
      List<PhysicalEntity> entities, Offset center, double radius, double strength) {
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

      if (timeSinceInteraction > 120 && speed < 0.5) {
        // 120秒后才触发，速度更低
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
    // 改为半随机泊松盘风格，半径敏感，带轻微抖动
    const int maxAttempts = 200;
    final random = Random();
    final placed = <Offset>[];

    for (int i = 0; i < entities.length; i++) {
      final r = entities[i].radius;
      final minDistance = max(70.0, r * 2.2);
      bool positioned = false;
      int attempts = 0;

      while (!positioned && attempts < maxAttempts) {
        final x = r + random.nextDouble() * (containerSize.width - 2 * r);
        final y = r + random.nextDouble() * (containerSize.height - 2 * r);
        var candidate = Offset(x, y);
        // 轻微抖动，避免规则感
        candidate = candidate +
            Offset((random.nextDouble() - 0.5) * 10.0, (random.nextDouble() - 0.5) * 10.0);

        bool tooClose = false;
        for (final p in placed) {
          if ((candidate - p).distance < minDistance) {
            tooClose = true;
            break;
          }
        }

        if (!tooClose) {
          entities[i] = entities[i].copyWith(position: candidate);
          placed.add(candidate);
          positioned = true;
        }
        attempts++;
      }

      if (!positioned) {
        final x = r + random.nextDouble() * (containerSize.width - 2 * r);
        final y = r + random.nextDouble() * (containerSize.height - 2 * r);
        final fallback = Offset(x, y);
        entities[i] = entities[i].copyWith(position: fallback);
        placed.add(fallback);
      }
    }
  }
}
