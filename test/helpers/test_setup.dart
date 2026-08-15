import 'package:flutter_test/flutter_test.dart';
import 'package:get_it/get_it.dart';

/// 通用测试设置
class TestSetup {
  static void setupAll() {
    TestWidgetsFlutterBinding.ensureInitialized();
    _setupServiceLocator();
  }

  static void tearDownAll() {
    GetIt.instance.reset();
  }

  static void _setupServiceLocator() {
    // TODO: 注册测试用的Service
    // 例如：GetIt.instance.registerSingleton<AuthService>(FakeAuthService());
  }
}

/// 测试基础Matcher
class TestMatchers {
  // 添加常用的自定义matcher
}

/// 测试数据工厂
class TestDataFactory {
  // 生成测试数据的工厂方法
}
