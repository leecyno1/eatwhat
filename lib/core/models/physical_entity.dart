import 'package:flutter/material.dart';
import 'dart:math';

/// 物理实体类型
enum PhysicalEntityType {
  taste, // 口味类
  cuisine, // 菜系类
  ingredient, // 食材类
  scenario, // 场景类
  nutrition, // 营养类
}

/// 物理实体模型 - 用于替代气泡，具有真实的物理属性
class PhysicalEntity {
  final String id;
  final String name;
  final String description;
  final PhysicalEntityType type;
  final String emoji; // 实体表情符号
  final String? icon; // 可选图标
  final Color primaryColor; // 主色调
  final Color secondaryColor; // 辅助色调

  // 物理属性
  final double mass; // 质量 (影响碰撞反应)
  final double radius; // 半径 (碰撞检测范围)
  final double width; // 宽度 (四边形实体)
  final double height; // 高度 (四边形实体)
  final double bounciness; // 弹性系数 (0-1)
  final double friction; // 摩擦系数 (0-1)

  // 运动状态
  Offset position; // 当前位置
  Offset velocity; // 速度向量
  Offset acceleration; // 加速度向量
  double rotation; // 旋转角度
  double angularVelocity; // 角速度

  // 交互状态
  bool isSelected;
  bool isHighlighted;
  double opacity;
  DateTime lastInteraction;

  PhysicalEntity({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.emoji,
    this.icon,
    required this.primaryColor,
    required this.secondaryColor,
    this.mass = 1.0,
    this.radius = 30.0,
    this.width = 60.0,
    this.height = 40.0,
    this.bounciness = 0.8,
    this.friction = 0.02,
    this.position = Offset.zero,
    this.velocity = Offset.zero,
    this.acceleration = Offset.zero,
    this.rotation = 0.0,
    this.angularVelocity = 0.0,
    this.isSelected = false,
    this.isHighlighted = false,
    this.opacity = 1.0,
    DateTime? lastInteraction,
  }) : lastInteraction = lastInteraction ?? DateTime.now();

  /// 复制实体并修改指定属性
  PhysicalEntity copyWith({
    String? id,
    String? name,
    String? description,
    PhysicalEntityType? type,
    String? emoji,
    String? icon,
    Color? primaryColor,
    Color? secondaryColor,
    double? mass,
    double? radius,
    double? width,
    double? height,
    double? bounciness,
    double? friction,
    Offset? position,
    Offset? velocity,
    Offset? acceleration,
    double? rotation,
    double? angularVelocity,
    bool? isSelected,
    bool? isHighlighted,
    double? opacity,
    DateTime? lastInteraction,
  }) {
    return PhysicalEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      type: type ?? this.type,
      emoji: emoji ?? this.emoji,
      icon: icon ?? this.icon,
      primaryColor: primaryColor ?? this.primaryColor,
      secondaryColor: secondaryColor ?? this.secondaryColor,
      mass: mass ?? this.mass,
      radius: radius ?? this.radius,
      width: width ?? this.width,
      height: height ?? this.height,
      bounciness: bounciness ?? this.bounciness,
      friction: friction ?? this.friction,
      position: position ?? this.position,
      velocity: velocity ?? this.velocity,
      acceleration: acceleration ?? this.acceleration,
      rotation: rotation ?? this.rotation,
      angularVelocity: angularVelocity ?? this.angularVelocity,
      isSelected: isSelected ?? this.isSelected,
      isHighlighted: isHighlighted ?? this.isHighlighted,
      opacity: opacity ?? this.opacity,
      lastInteraction: lastInteraction ?? this.lastInteraction,
    );
  }

  /// 更新物理状态
  void updatePhysics(double deltaTime) {
    // 更新速度 (v = v0 + a*t)
    velocity = Offset(
      velocity.dx + acceleration.dx * deltaTime,
      velocity.dy + acceleration.dy * deltaTime,
    );

    // 应用摩擦力
    velocity = Offset(
      velocity.dx * (1.0 - friction),
      velocity.dy * (1.0 - friction),
    );

    // 更新位置 (p = p0 + v*t)
    position = Offset(
      position.dx + velocity.dx * deltaTime,
      position.dy + velocity.dy * deltaTime,
    );

    // 更新旋转
    angularVelocity *= (1.0 - friction); // 角摩擦
    rotation += angularVelocity * deltaTime;
  }

  /// 检测与另一个实体的碰撞
  bool detectCollision(PhysicalEntity other) {
    final distance = (position - other.position).distance;
    return distance < (radius + other.radius);
  }

  /// 处理与另一个实体的碰撞
  void handleCollision(PhysicalEntity other) {
    final distance = (position - other.position).distance;
    if (distance < (radius + other.radius)) {
      // 计算碰撞向量
      final collisionVector = other.position - position;
      final normalizedCollision = collisionVector / distance;

      // 分离重叠的实体
      final overlap = (radius + other.radius) - distance;
      final separation = normalizedCollision * (overlap / 2);
      position = position - separation;
      other.position = other.position + separation;

      // 计算相对速度
      final relativeVelocity = velocity - other.velocity;
      final velocityAlongNormal = relativeVelocity.dx * normalizedCollision.dx +
          relativeVelocity.dy * normalizedCollision.dy;

      // 如果物体正在分离，不需要处理碰撞
      if (velocityAlongNormal > 0) return;

      // 计算反弹系数
      final restitution = min(bounciness, other.bounciness);

      // 计算碰撞冲量
      final impulse = -(1 + restitution) * velocityAlongNormal / (1 / mass + 1 / other.mass);

      // 应用冲量
      final impulseVector = normalizedCollision * impulse;
      velocity = velocity + impulseVector / mass;
      other.velocity = other.velocity - impulseVector / other.mass;

      // 添加一些旋转效果
      angularVelocity += (Random().nextDouble() - 0.5) * 5;
      other.angularVelocity += (Random().nextDouble() - 0.5) * 5;
    }
  }

  /// 检测与边界的碰撞并反弹
  void handleBoundaryCollision(Size containerSize) {
    // 左边界
    if (position.dx - radius < 0) {
      position = Offset(radius, position.dy);
      velocity = Offset(-velocity.dx * bounciness, velocity.dy);
      angularVelocity = -angularVelocity * 0.8;
    }

    // 右边界
    if (position.dx + radius > containerSize.width) {
      position = Offset(containerSize.width - radius, position.dy);
      velocity = Offset(-velocity.dx * bounciness, velocity.dy);
      angularVelocity = -angularVelocity * 0.8;
    }

    // 上边界
    if (position.dy - radius < 0) {
      position = Offset(position.dx, radius);
      velocity = Offset(velocity.dx, -velocity.dy * bounciness);
      angularVelocity = -angularVelocity * 0.8;
    }

    // 下边界
    if (position.dy + radius > containerSize.height) {
      position = Offset(position.dx, containerSize.height - radius);
      velocity = Offset(velocity.dx, -velocity.dy * bounciness);
      angularVelocity = -angularVelocity * 0.8;
    }
  }

  /// 应用外力
  void applyForce(Offset force) {
    acceleration = Offset(
      acceleration.dx + force.dx / mass,
      acceleration.dy + force.dy / mass,
    );
  }

  /// 应用冲量 (瞬时力)
  void applyImpulse(Offset impulse) {
    velocity = Offset(
      velocity.dx + impulse.dx / mass,
      velocity.dy + impulse.dy / mass,
    );
  }

  /// 获取动能
  double get kineticEnergy {
    final linearEnergy = 0.5 * mass * velocity.distanceSquared;
    final rotationalEnergy = 0.5 * (mass * radius * radius) * angularVelocity * angularVelocity;
    return linearEnergy + rotationalEnergy;
  }

  /// 重置加速度 (每帧调用)
  void resetAcceleration() {
    acceleration = Offset.zero;
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PhysicalEntity && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'PhysicalEntity(id: $id, name: $name, position: $position, velocity: $velocity)';
  }
}
