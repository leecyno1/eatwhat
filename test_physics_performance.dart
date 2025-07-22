import 'dart:io';
import 'package:flutter/material.dart';
import 'lib/core/physics/zero_gravity_physics.dart';
import 'lib/core/models/physical_entity_factory.dart';

/// 性能测试脚本 - 验证气泡物理系统修复效果
void main() async {
  print('🧪 开始气泡物理系统性能测试...\n');
  
  // 创建测试环境
  final containerSize = Size(400, 600);
  final entities = PhysicalEntityFactory.createDefaultEntities();
  PhysicalEntityFactory.distributeEntities(entities, containerSize);
  PhysicalEntityFactory.addRandomVelocity(entities);
  
  print('📊 初始状态:');
  print('实体数量: ${entities.length}');
  print('容器尺寸: ${containerSize.width}x${containerSize.height}');
  
  // 验证初始速度是否在合理范围内
  var totalSpeed = 0.0;
  var maxSpeed = 0.0;
  var maxAngularSpeed = 0.0;
  
  for (final entity in entities) {
    final speed = entity.velocity.distance;
    totalSpeed += speed;
    if (speed > maxSpeed) maxSpeed = speed;
    if (entity.angularVelocity.abs() > maxAngularSpeed) {
      maxAngularSpeed = entity.angularVelocity.abs();
    }
  }
  
  print('\n🎯 初始速度分析:');
  print('平均速度: ${(totalSpeed / entities.length).toStringAsFixed(2)}');
  print('最大速度: ${maxSpeed.toStringAsFixed(2)} (应该 ≤ 5.0)');
  print('最大角速度: ${maxAngularSpeed.toStringAsFixed(3)} (应该 ≤ 0.1)');
  
  // 模拟物理更新
  print('\n⚡ 开始物理模拟...');
  final stopwatch = Stopwatch()..start();
  
  var frameCount = 0;
  final targetFrames = 300; // 模拟5秒 (60fps)
  
  while (frameCount < targetFrames) {
    ZeroGravityPhysics.updatePhysics(entities, containerSize);
    frameCount++;
    
    // 每60帧（1秒）输出一次状态
    if (frameCount % 60 == 0) {
      final energy = ZeroGravityPhysics.calculateTotalKineticEnergy(entities);
      final isAtRest = ZeroGravityPhysics.isSystemNearlyAtRest(entities);
      print('第${frameCount~/60}秒: 系统能量=${energy.toStringAsFixed(1)}, 近似静止=$isAtRest');
    }
  }
  
  stopwatch.stop();
  
  // 最终分析
  final finalEnergy = ZeroGravityPhysics.calculateTotalKineticEnergy(entities);
  final isSystemAtRest = ZeroGravityPhysics.isSystemNearlyAtRest(entities);
  
  print('\n📈 性能测试结果:');
  print('模拟帧数: $frameCount 帧');
  print('执行时间: ${stopwatch.elapsedMilliseconds}ms');
  print('平均帧率: ${(frameCount * 1000 / stopwatch.elapsedMilliseconds).toStringAsFixed(1)} fps');
  print('最终能量: ${finalEnergy.toStringAsFixed(1)}');
  print('系统静止: $isSystemAtRest');
  
  // 验证最大速度限制
  var currentMaxSpeed = 0.0;
  var currentMaxAngularSpeed = 0.0;
  
  for (final entity in entities) {
    final speed = entity.velocity.distance;
    if (speed > currentMaxSpeed) currentMaxSpeed = speed;
    if (entity.angularVelocity.abs() > currentMaxAngularSpeed) {
      currentMaxAngularSpeed = entity.angularVelocity.abs();
    }
  }
  
  print('\n✅ 物理约束验证:');
  print('当前最大速度: ${currentMaxSpeed.toStringAsFixed(2)} (限制: 25.0)');
  print('当前最大角速度: ${currentMaxAngularSpeed.toStringAsFixed(3)} (限制: 0.5)');
  
  final speedOK = currentMaxSpeed <= 25.0;
  final angularSpeedOK = currentMaxAngularSpeed <= 0.5;
  
  print('\n🎉 修复验证结果:');
  print('速度限制: ${speedOK ? "✅ 通过" : "❌ 失败"}');
  print('角速度限制: ${angularSpeedOK ? "✅ 通过" : "❌ 失败"}');
  print('性能: ${stopwatch.elapsedMilliseconds < 100 ? "✅ 优秀" : "⚠️  需优化"}');
  
  if (speedOK && angularSpeedOK) {
    print('\n🌟 气泡物理系统修复成功！混乱运动问题已解决。');
  } else {
    print('\n⚠️  还需要进一步调整物理参数。');
  }
  
  exit(0);
}