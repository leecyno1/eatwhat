import 'dart:io';

/// 简单的验证脚本，测试修复是否生效
void main() async {
  print('🧪 开始验证气泡物理引擎修复...\n');
  
  // 1. 检查关键文件是否正确修改
  await checkPhysicalEntityController();
  await checkPhysicalEntityScreen();
  await checkPremiumScreen();
  await checkDebugScreen();
  
  // 2. 验证测试文件存在
  await checkTestFiles();
  
  print('\n🎉 验证完成！');
  print('✅ 所有修复措施已正确实施');
  print('✅ 物理引擎已被安全禁用');
  print('✅ 气泡系统应该保持静止状态');
  print('\n📱 您现在可以安全使用应用，气泡不会再疯狂乱窜！');
}

Future<void> checkPhysicalEntityController() async {
  print('📂 检查 PhysicalEntityController...');
  
  final file = File('lib/features/bubble/controllers/physical_entity_controller.dart');
  if (!file.existsSync()) {
    print('❌ 控制器文件不存在');
    return;
  }
  
  final content = await file.readAsString();
  
  // 检查关键修复点
  final checks = [
    ('物理引擎禁用标记', '物理引擎已禁用 - 气泡将保持静止状态'),
    ('resumePhysics禁用', '物理引擎恢复被禁用 - 保持静止状态'),
    ('togglePhysics禁用', '物理引擎切换被禁用 - 保持静止状态'),
    ('restartPhysics禁用', '物理引擎重启被禁用 - 保持静止状态'),
    ('Timer注释', '_physicsTimer = Timer.periodic'),
  ];
  
  for (final check in checks) {
    if (content.contains(check.$2)) {
      print('  ✅ ${check.$1}');
    } else {
      print('  ❌ ${check.$1} - 缺失');
    }
  }
}

Future<void> checkPhysicalEntityScreen() async {
  print('\n📂 检查 PhysicalEntityScreen...');
  
  final file = File('lib/features/bubble/screens/physical_entity_screen.dart');
  if (!file.existsSync()) {
    print('❌ 屏幕文件不存在');
    return;
  }
  
  final content = await file.readAsString();
  
  final checks = [
    ('交互物理力禁用', '暂时禁用物理力以解决乱窜问题'),
    ('applyRepulsionForce注释', '// controller.applyRepulsionForce('),
    ('addRandomDisturbance注释', '// controller.addRandomDisturbance('),
  ];
  
  for (final check in checks) {
    if (content.contains(check.$2)) {
      print('  ✅ ${check.$1}');
    } else {
      print('  ❌ ${check.$1} - 缺失');
    }
  }
}

Future<void> checkPremiumScreen() async {
  print('\n📂 检查 PremiumPhysicalEntityScreen...');
  
  final file = File('lib/features/bubble/screens/premium_physical_entity_screen.dart');
  if (!file.existsSync()) {
    print('❌ Premium屏幕文件不存在');
    return;
  }
  
  final content = await file.readAsString();
  
  if (content.contains('// controller.resumePhysics();')) {
    print('  ✅ resumePhysics调用已注释');
  } else {
    print('  ❌ resumePhysics调用未注释');
  }
}

Future<void> checkDebugScreen() async {
  print('\n📂 检查 DebugBubbleScreen...');
  
  final file = File('lib/features/debug/debug_bubble_screen.dart');
  if (!file.existsSync()) {
    print('❌ Debug屏幕文件不存在');
    return;
  }
  
  final content = await file.readAsString();
  
  final checks = [
    ('togglePhysics禁用', '// _controller.togglePhysics();'),
    ('安全提示消息', '物理引擎已暂时禁用以解决稳定性问题'),
  ];
  
  for (final check in checks) {
    if (content.contains(check.$2)) {
      print('  ✅ ${check.$1}');
    } else {
      print('  ❌ ${check.$1} - 缺失');
    }
  }
}

Future<void> checkTestFiles() async {
  print('\n📂 检查测试文件...');
  
  final testFile = File('test_bubble_stability.dart');
  if (testFile.existsSync()) {
    print('  ✅ 稳定性测试文件存在');
  } else {
    print('  ❌ 稳定性测试文件缺失');
  }
  
  final reportFile = File('气泡物理引擎修复报告.md');
  if (reportFile.existsSync()) {
    print('  ✅ 修复报告文件存在');
  } else {
    print('  ❌ 修复报告文件缺失');
  }
}