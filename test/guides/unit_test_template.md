# 单元测试编写指南

## 基本结构

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:eatwhat_app/your_module.dart';
import '../helpers/test_setup.dart';

void main() {
  group('YourClass', () {
    setUp(() {
      // 每个测试前的初始化
    });

    tearDown(() {
      // 每个测试后的清理
    });

    test('应该做什么的描述', () {
      // Arrange（准备）
      // Act（执行）
      // Assert（断言）
    });
  });
}
```

## 示例1：Service测试

```dart
void main() {
  group('AuthService', () {
    late FakeAuthRepository fakeAuthRepository;
    late AuthService authService;

    setUp(() {
      fakeAuthRepository = FakeAuthRepository();
      authService = AuthService(fakeAuthRepository);
    });

    test('登录成功后应该返回用户信息', () async {
      // Arrange
      const phone = '13800138000';
      const password = 'password123';

      // Act
      final result = await authService.login(phone, password);

      // Assert
      expect(result, isNotNull);
      expect(result?.phone, equals(phone));
    });

    test('登录失败应该抛出异常', () async {
      // Arrange
      const invalidPhone = '123';

      // Act & Assert
      expect(
        () => authService.login(invalidPhone, 'password'),
        throwsException,
      );
    });
  });
}
```

## 示例2：Model测试

```dart
void main() {
  group('Food Model', () {
    test('应该能正确解析JSON', () {
      // Arrange
      final json = {
        'id': '1',
        'name': '宫保鸡丁',
        'price': 28.0,
      };

      // Act
      final food = Food.fromJson(json);

      // Assert
      expect(food.id, equals('1'));
      expect(food.name, equals('宫保鸡丁'));
      expect(food.price, equals(28.0));
    });

    test('应该能正确转换为JSON', () {
      // Arrange
      final food = Food(id: '1', name: '宫保鸡丁', price: 28.0);

      // Act
      final json = food.toJson();

      // Assert
      expect(json['id'], equals('1'));
      expect(json['name'], equals('宫保鸡丁'));
    });
  });
}
```

## 示例3：Provider测试（Riverpod）

```dart
void main() {
  group('AuthProvider', () {
    test('初始状态应该是未认证', () {
      final container = ProviderContainer();
      final authState = container.read(authProvider);
      
      expect(authState.isAuthenticated, false);
    });

    test('登录后应该更新状态', () async {
      final container = ProviderContainer();
      
      // 执行登录
      await container.read(authProvider.notifier).login('phone', 'password');
      
      final authState = container.read(authProvider);
      expect(authState.isAuthenticated, true);
    });
  });
}
```

## 最佳实践

1. **命名规范**: 测试文件名应该是 `*_test.dart`
2. **描述清晰**: 使用具体的测试描述，说明期望行为
3. **遵循AAA模式**: Arrange (准备) → Act (执行) → Assert (断言)
4. **一个测试只测一个场景**: 避免一个测试验证多个功能
5. **使用fixtures**: 抽取重复的初始化代码到setUp
6. **Mock外部依赖**: 使用Fake实现替代真实的Repository或Service

## 运行测试

```bash
# 运行所有测试
flutter test

# 运行特定文件
flutter test test/core/services/auth_service_test.dart

# 运行并生成覆盖率报告
flutter test --coverage

# 查看覆盖率
lcov --list coverage/lcov.info
```
