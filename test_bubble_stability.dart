import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'lib/features/bubble/controllers/physical_entity_controller.dart';

/// 气泡稳定性测试
void main() {
  group('气泡稳定性测试', () {
    test('物理引擎应该保持禁用状态', () async {
      final controller = PhysicalEntityController();
      await controller.initialize();
      
      // 验证物理引擎已禁用
      expect(controller.isPhysicsRunning, false);
      
      // 尝试启动物理引擎 - 应该被忽略
      controller.resumePhysics();
      expect(controller.isPhysicsRunning, false);
      
      // 尝试切换物理引擎 - 应该被忽略
      controller.togglePhysics();
      expect(controller.isPhysicsRunning, false);
      
      // 尝试重启物理引擎 - 应该被忽略
      controller.restartPhysics();
      expect(controller.isPhysicsRunning, false);
      
      print('✅ 物理引擎稳定性测试通过');
    });
    
    test('气泡应该保持静止状态', () async {
      final controller = PhysicalEntityController();
      await controller.initialize();
      
      // 检查所有气泡的初始速度
      for (final entity in controller.entities) {
        expect(entity.velocity, equals(Offset.zero));
        expect(entity.angularVelocity, equals(0.0));
      }
      
      // 等待一段时间，确保气泡仍然静止
      await Future.delayed(const Duration(seconds: 1));
      
      // 再次检查气泡状态
      for (final entity in controller.entities) {
        expect(entity.velocity, equals(Offset.zero));
        expect(entity.angularVelocity, equals(0.0));
      }
      
      print('✅ 气泡静止状态测试通过');
    });
    
    test('物理力应该被禁用', () async {
      final controller = PhysicalEntityController();
      await controller.initialize();
      
      final initialPositions = controller.entities.map((e) => e.position).toList();
      
      // 尝试应用各种物理力
      controller.applyRepulsionForce(const Offset(200, 300));
      controller.applyAttractionForce(const Offset(200, 300));
      controller.applyVortexForce(const Offset(200, 300));
      controller.addRandomDisturbance();
      
      // 等待一段时间
      await Future.delayed(const Duration(milliseconds: 500));
      
      // 检查位置是否保持不变
      final currentPositions = controller.entities.map((e) => e.position).toList();
      for (int i = 0; i < initialPositions.length; i++) {
        expect(currentPositions[i], equals(initialPositions[i]));
      }
      
      print('✅ 物理力禁用测试通过');
    });
  });
}