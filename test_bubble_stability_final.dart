import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'lib/features/bubble/controllers/physical_entity_controller.dart';

/// 最终气泡稳定性测试 - 基于Cursor分析的修复
void main() {
  group('气泡乱窜问题修复验证', () {
    test('容器尺寸更新应该有智能检测', () async {
      final controller = PhysicalEntityController();
      await controller.initialize();
      
      final initialSize = const Size(400, 600);
      final sameSize = const Size(400, 600);
      final slightlyDifferentSize = const Size(405, 605); // 5像素差异
      final significantlyDifferentSize = const Size(420, 620); // 20像素差异
      
      // 测试初始设置
      controller.updateContainerSize(initialSize);
      final entitiesCount = controller.entities.length;
      
      // 记录初始位置
      final initialPositions = controller.entities.map((e) => e.position).toList();
      
      // 测试相同尺寸 - 不应该重新分布
      controller.updateContainerSize(sameSize);
      final positionsAfterSameSize = controller.entities.map((e) => e.position).toList();
      
      for (int i = 0; i < initialPositions.length; i++) {
        expect(positionsAfterSameSize[i], equals(initialPositions[i]),
            reason: '相同尺寸不应该改变气泡位置');
      }
      
      // 测试微小差异 - 不应该重新分布（小于10像素阈值）
      controller.updateContainerSize(slightlyDifferentSize);
      final positionsAfterSlightChange = controller.entities.map((e) => e.position).toList();
      
      for (int i = 0; i < initialPositions.length; i++) {
        expect(positionsAfterSlightChange[i], equals(initialPositions[i]),
            reason: '微小尺寸变化不应该改变气泡位置');
      }
      
      print('✅ 智能尺寸检测测试通过');
    });
    
    test('物理引擎应该保持完全禁用', () async {
      final controller = PhysicalEntityController();
      await controller.initialize();
      
      // 验证物理引擎状态
      expect(controller.isPhysicsRunning, false);
      
      // 尝试各种启动方法
      controller.resumePhysics();
      expect(controller.isPhysicsRunning, false);
      
      controller.togglePhysics();
      expect(controller.isPhysicsRunning, false);
      
      controller.restartPhysics();
      expect(controller.isPhysicsRunning, false);
      
      // 验证气泡速度保持为零
      for (final entity in controller.entities) {
        expect(entity.velocity, equals(Offset.zero));
        expect(entity.angularVelocity, equals(0.0));
      }
      
      print('✅ 物理引擎禁用状态测试通过');
    });
    
    test('气泡位置应该在选择后保持稳定', () async {
      final controller = PhysicalEntityController();
      await controller.initialize();
      
      if (controller.entities.isNotEmpty) {
        final testEntity = controller.entities.first;
        final initialPosition = testEntity.position;
        
        // 选择气泡
        controller.toggleEntity(testEntity);
        
        // 等待可能的异步操作
        await Future.delayed(const Duration(milliseconds: 100));
        
        // 检查位置是否保持稳定
        final positionAfterSelection = controller.entities.first.position;
        expect(positionAfterSelection, equals(initialPosition),
            reason: '选择气泡后位置应该保持稳定');
        
        // 再次选择（取消选择）
        controller.toggleEntity(testEntity);
        await Future.delayed(const Duration(milliseconds: 100));
        
        final positionAfterDeselection = controller.entities.first.position;
        expect(positionAfterDeselection, equals(initialPosition),
            reason: '取消选择后位置应该保持稳定');
      }
      
      print('✅ 气泡选择稳定性测试通过');
    });
  });
}