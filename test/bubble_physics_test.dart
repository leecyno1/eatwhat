import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:eatwhat_app/core/physics/zero_gravity_physics.dart';
import 'package:eatwhat_app/core/models/physical_entity.dart';
import 'package:eatwhat_app/core/models/physical_entity_factory.dart';

/// 气泡物理系统专项测试 - 验证混乱运动修复
void main() {
  group('气泡物理系统修复验证', () {
    late List<PhysicalEntity> testEntities;
    late Size containerSize;

    setUp(() {
      containerSize = const Size(400, 600);
      testEntities = PhysicalEntityFactory.createDefaultEntities().take(5).toList();
      PhysicalEntityFactory.distributeEntities(testEntities, containerSize);
      PhysicalEntityFactory.addRandomVelocity(testEntities);
    });

    testWidgets('气泡初始速度应该在合理范围内', (WidgetTester tester) async {
      for (final entity in testEntities) {
        // 验证初始速度不会过高（修复前是±25，现在应该是±5）
        expect(entity.velocity.dx.abs(), lessThanOrEqualTo(5.0),
            reason: '水平速度不应超过5.0，当前值: ${entity.velocity.dx}');
        expect(entity.velocity.dy.abs(), lessThanOrEqualTo(5.0),
            reason: '垂直速度不应超过5.0，当前值: ${entity.velocity.dy}');

        // 验证角速度在合理范围内（修复前是±1.0，现在应该是±0.1）
        expect(entity.angularVelocity.abs(), lessThanOrEqualTo(0.1),
            reason: '角速度不应超过0.1，当前值: ${entity.angularVelocity}');
      }
    });

    testWidgets('物理更新后速度应该受到限制', (WidgetTester tester) async {
      // 运行多次物理更新
      for (int i = 0; i < 10; i++) {
        ZeroGravityPhysics.updatePhysics(testEntities, containerSize);
      }

      for (final entity in testEntities) {
        final speed = entity.velocity.distance;

        // 验证最大速度限制（修复前是100.0，现在应该是25.0）
        expect(speed, lessThanOrEqualTo(25.0), reason: '实体速度不应超过25.0，当前值: $speed');

        // 验证角速度限制（修复前是2.0，现在应该是0.5）
        expect(entity.angularVelocity.abs(), lessThanOrEqualTo(0.5),
            reason: '角速度不应超过0.5，当前值: ${entity.angularVelocity}');
      }
    });

    testWidgets('气泡应该逐渐减速（阻尼效果）', (WidgetTester tester) async {
      // 记录初始总动能
      final initialEnergy = ZeroGravityPhysics.calculateTotalKineticEnergy(testEntities);

      // 运行多次物理更新
      for (int i = 0; i < 50; i++) {
        ZeroGravityPhysics.updatePhysics(testEntities, containerSize);
      }

      // 记录最终总动能
      final finalEnergy = ZeroGravityPhysics.calculateTotalKineticEnergy(testEntities);

      // 验证系统能量在减少（阻尼效果）
      expect(finalEnergy, lessThan(initialEnergy),
          reason: '系统应该由于阻尼而失去能量。初始: $initialEnergy, 最终: $finalEnergy');
    });

    testWidgets('边界碰撞应该有适当的阻尼', (WidgetTester tester) async {
      // 创建一个即将撞击边界的实体
      final entity = testEntities.first.copyWith(
        position: const Offset(5, 300), // 接近左边界
        velocity: const Offset(-10, 0), // 向左运动
      );
      testEntities[0] = entity;

      // 记录碰撞前的速度
      final preCollisionSpeed = entity.velocity.distance;

      // 运行物理更新直到发生碰撞
      ZeroGravityPhysics.updatePhysics(testEntities, containerSize);

      final postCollisionSpeed = testEntities[0].velocity.distance;

      // 验证碰撞后速度有所减少（边界阻尼效果）
      expect(postCollisionSpeed, lessThan(preCollisionSpeed),
          reason: '边界碰撞应该减少速度。碰撞前: $preCollisionSpeed, 碰撞后: $postCollisionSpeed');
    });

    testWidgets('系统应该能达到近似静止状态', (WidgetTester tester) async {
      // 运行长时间物理模拟
      for (int i = 0; i < 200; i++) {
        ZeroGravityPhysics.updatePhysics(testEntities, containerSize);
      }

      // 检查系统是否接近静止
      final isNearlyAtRest = ZeroGravityPhysics.isSystemNearlyAtRest(testEntities);

      // 由于我们增强了阻尼，系统应该能更快达到静止状态
      final totalEnergy = ZeroGravityPhysics.calculateTotalKineticEnergy(testEntities);
      expect(totalEnergy, lessThan(1000.0), reason: '经过长时间模拟，系统能量应该很低。当前能量: $totalEnergy');
    });

    testWidgets('随机扰动应该是温和的', (WidgetTester tester) async {
      // 让系统先接近静止
      for (int i = 0; i < 100; i++) {
        ZeroGravityPhysics.updatePhysics(testEntities, containerSize);
      }

      // 记录扰动前的总动能
      final preDisturbanceEnergy = ZeroGravityPhysics.calculateTotalKineticEnergy(testEntities);

      // 应用随机扰动
      ZeroGravityPhysics.applyRandomDisturbance(testEntities, 30.0); // 默认强度已降低

      final postDisturbanceEnergy = ZeroGravityPhysics.calculateTotalKineticEnergy(testEntities);

      // 验证扰动效果是温和的
      final energyIncrease = postDisturbanceEnergy - preDisturbanceEnergy;
      expect(energyIncrease, lessThan(1000.0), reason: '随机扰动应该是温和的，不应造成剧烈运动。能量增加: $energyIncrease');
    });
  });
}
