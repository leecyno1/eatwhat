import 'package:flutter/material.dart';
import 'dart:math';
import 'physical_entity.dart';
import '../data/taste_preference_database.dart';

/// 物理实体工厂 - 创建各种口味偏好的形象化实体
class PhysicalEntityFactory {
  static final Random _random = Random();

  /// 创建默认的物理实体集合 - 使用完整的口味偏好数据库
  static List<PhysicalEntity> createDefaultEntities() {
    return TastePreferenceDatabase.getAllTasteEntities();
  }

  /// 获取指定数量的随机实体（用于渐进出现效果）
  static List<PhysicalEntity> getRandomEntities(int count) {
    final allEntities = TastePreferenceDatabase.getAllTasteEntities();
    final shuffled = List<PhysicalEntity>.from(allEntities)..shuffle(_random);
    return shuffled.take(count).toList();
  }

  /// 按类型获取实体
  static List<PhysicalEntity> getEntitiesByType(PhysicalEntityType type) {
    final allEntities = TastePreferenceDatabase.getAllTasteEntities();
    return allEntities.where((entity) => entity.type == type).toList();
  }

  /// 获取平衡的实体集合（每个类型都有代表）
  static List<PhysicalEntity> getBalancedEntities(int totalCount) {
    final allEntities = TastePreferenceDatabase.getAllTasteEntities();
    final entitiesByType = <PhysicalEntityType, List<PhysicalEntity>>{};

    // 按类型分组
    for (final entity in allEntities) {
      entitiesByType.putIfAbsent(entity.type, () => []).add(entity);
    }

    final result = <PhysicalEntity>[];
    final types = entitiesByType.keys.toList()..shuffle(_random);

    // 轮流从每个类型中选择实体
    for (int i = 0; i < totalCount; i++) {
      final typeIndex = i % types.length;
      final type = types[typeIndex];
      final entitiesOfType = entitiesByType[type]!;

      if (entitiesOfType.isNotEmpty) {
        final entity = entitiesOfType.removeAt(_random.nextInt(entitiesOfType.length));
        result.add(entity);
      }
    }

    return result;
  }

  /// 为实体分配随机位置 (避免重叠)
  static void distributeEntities(List<PhysicalEntity> entities, Size containerSize) {
    const double minDistance = 120.0; // 增加最小间距，防止重叠
    const int maxAttempts = 100; // 增加尝试次数

    final placedPositions = <Offset>[];

    for (int i = 0; i < entities.length; i++) {
      bool positioned = false;
      int attempts = 0;

      while (!positioned && attempts < maxAttempts) {
        final x = entities[i].radius +
            _random.nextDouble() * (containerSize.width - 2 * entities[i].radius);
        final y = entities[i].radius +
            _random.nextDouble() * (containerSize.height - 2 * entities[i].radius);
        final newPosition = Offset(x, y);

        // 检查是否与已放置的实体重叠
        bool overlapping = false;
        for (final placedPos in placedPositions) {
          if ((newPosition - placedPos).distance < minDistance) {
            overlapping = true;
            break;
          }
        }

        if (!overlapping) {
          entities[i] = entities[i].copyWith(position: newPosition);
          placedPositions.add(newPosition);
          positioned = true;
        }

        attempts++;
      }

      // 如果尝试次数超限，随机放置
      if (!positioned) {
        final x = entities[i].radius +
            _random.nextDouble() * (containerSize.width - 2 * entities[i].radius);
        final y = entities[i].radius +
            _random.nextDouble() * (containerSize.height - 2 * entities[i].radius);
        entities[i] = entities[i].copyWith(position: Offset(x, y));
      }
    }
  }

  /// 为实体添加随机初始速度
  static void addRandomVelocity(List<PhysicalEntity> entities) {
    for (int i = 0; i < entities.length; i++) {
      final velocity = Offset(
        (_random.nextDouble() - 0.5) * 0.1, // 极小的初始速度，几乎静止
        (_random.nextDouble() - 0.5) * 0.1,
      );
      final angularVelocity = (_random.nextDouble() - 0.5) * 0.005; // 极小的角速度

      entities[i] = entities[i].copyWith(
        velocity: velocity,
        angularVelocity: angularVelocity,
      );
    }
  }

  /// 创建特定类型的实体
  static PhysicalEntity createEntity({
    required String id,
    required String name,
    required String description,
    required PhysicalEntityType type,
    required String emoji,
    String? icon,
    required Color primaryColor,
    required Color secondaryColor,
    double mass = 1.0,
    double radius = 50.0,
    double bounciness = 0.8,
    double friction = 0.02,
  }) {
    return PhysicalEntity(
      id: id,
      name: name,
      description: description,
      type: type,
      emoji: emoji,
      icon: icon,
      primaryColor: primaryColor,
      secondaryColor: secondaryColor,
      mass: mass,
      radius: radius,
      bounciness: bounciness,
      friction: friction,
    );
  }
}
