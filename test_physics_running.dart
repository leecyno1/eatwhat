import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'lib/features/bubble/controllers/physical_entity_controller.dart';

/// 测试物理引擎是否正在运行
void main() {
  group('物理引擎运行状态测试', () {
    test('物理引擎应该正确启动', () async {
      final controller = PhysicalEntityController();
      await controller.initialize();
      
      // 验证物理引擎状态
      expect(controller.isPhysicsRunning, true, reason: '物理引擎应该正在运行');
      
      // 验证实体有初始速度
      bool hasMovingEntities = false;
      for (final entity in controller.entities) {
        if (entity.velocity.distance > 0) {
          hasMovingEntities = true;
          break;
        }
      }
      
      expect(hasMovingEntities, true, reason: '至少有一些实体应该有初始速度');
      
      print('✅ 物理引擎正在运行');
      print('✅ 实体数量: ${controller.entities.length}');
      print('✅ 有运动的实体: $hasMovingEntities');
    });
    
    test('物理引擎控制方法应该正常工作', () async {
      final controller = PhysicalEntityController();
      await controller.initialize();
      
      // 测试暂停
      controller.pausePhysics();
      expect(controller.isPhysicsRunning, false, reason: '暂停后物理引擎应该停止');
      
      // 测试恢复
      controller.resumePhysics();
      expect(controller.isPhysicsRunning, true, reason: '恢复后物理引擎应该运行');
      
      // 测试切换
      controller.togglePhysics(); // 应该暂停
      expect(controller.isPhysicsRunning, false, reason: '切换后应该暂停');
      
      controller.togglePhysics(); // 应该恢复
      expect(controller.isPhysicsRunning, true, reason: '再次切换后应该恢复');
      
      print('✅ 物理引擎控制方法测试通过');
    });
    
    test('物理引擎定时器应该工作', () async {
      final controller = PhysicalEntityController();
      await controller.initialize();
      
      // 记录初始位置
      final initialPositions = controller.entities.map((e) => e.position).toList();
      
      // 等待一段时间让物理引擎更新
      await Future.delayed(Duration(milliseconds: 500));
      
      // 检查是否有位置变化
      bool positionsChanged = false;
      for (int i = 0; i < controller.entities.length; i++) {
        final currentPos = controller.entities[i].position;
        final initialPos = initialPositions[i];
        if ((currentPos - initialPos).distance > 1.0) {
          positionsChanged = true;
          break;
        }
      }
      
      expect(positionsChanged, true, reason: '一段时间后实体位置应该发生变化');
      
      print('✅ 物理引擎定时器正常工作');
    });
  });
}