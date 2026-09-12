import 'package:flutter_test/flutter_test.dart';

/// 通用测试设置
class TestSetup {
  static void setupAll() {
    TestWidgetsFlutterBinding.ensureInitialized();
  }

  static void tearDownAll() {}
}

/// 测试基础Matcher
class TestMatchers {
  // 添加常用的自定义matcher
}

/// 测试数据工厂
class TestDataFactory {
  // 生成测试数据的工厂方法
}
