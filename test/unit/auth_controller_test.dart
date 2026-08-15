import 'package:flutter_test/flutter_test.dart';
import 'package:eatwhat_app/features/auth/controllers/auth_controller.dart';

void main() {
  group('AuthController Tests', () {
    late AuthController authController;

    setUp(() {
      authController = AuthController();
    });

    tearDown(() {
      authController.dispose();
    });

    test('初始状态应该未认证', () {
      expect(authController.isAuthenticated, false);
      expect(authController.isLoading, false);
      expect(authController.currentUser, null);
    });

    test('邮箱验证应该正确工作', () async {
      // 测试无效邮箱
      final result1 = await authController.login('invalid-email', 'password123');
      expect(result1, false);
      expect(authController.loginError, '请输入有效的邮箱地址');

      // 清除错误
      authController.clearErrors();
      expect(authController.loginError, null);
    });

    test('密码长度验证应该正确工作', () async {
      final result = await authController.login('test@example.com', '123');
      expect(result, false);
      expect(authController.loginError, '密码长度不能少于6位');
    });

    test('注册时密码确认应该工作', () async {
      final result = await authController.register(
          'test@example.com', 'Password123', 'Different456', 'testuser');
      expect(result, false);
      expect(authController.registerError, '两次输入的密码不一致');
    });

    test('清除错误信息应该工作', () async {
      // 先产生错误
      await authController.login('invalid', 'short');
      expect(authController.loginError, isNotNull);

      // 清除错误
      authController.clearErrors();
      expect(authController.loginError, null);
      expect(authController.registerError, null);
      expect(authController.resetPasswordError, null);
    });
  });
}
