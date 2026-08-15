import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eatwhat_app/core/providers/auth_provider.dart';

void main() {
  group('AuthProvider', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('初始状态应该是未认证', () {
      final authState = container.read(authProvider);
      expect(authState.isAuthenticated, false);
      expect(authState.userId, isNull);
      expect(authState.username, isNull);
      expect(authState.isLoading, false);
      expect(authState.error, isNull);
    });

    test('应该能成功登录', () async {
      final notifier = container.read(authProvider.notifier);

      await notifier.login('testuser', 'password123');

      final authState = container.read(authProvider);
      expect(authState.isAuthenticated, true);
      expect(authState.username, 'testuser');
      expect(authState.userId, isNotNull);
      expect(authState.isLoading, false);
      expect(authState.error, isNull);
    });

    test('空用户名或密码应该登录失败', () async {
      final notifier = container.read(authProvider.notifier);

      await notifier.login('', '');

      final authState = container.read(authProvider);
      expect(authState.isAuthenticated, false);
      expect(authState.error, isNotNull);
    });

    test('应该能成功注册', () async {
      final notifier = container.read(authProvider.notifier);

      await notifier.register('newuser', 'password123');

      final authState = container.read(authProvider);
      expect(authState.isAuthenticated, true);
      expect(authState.username, 'newuser');
      expect(authState.userId, isNotNull);
    });

    test('密码少于6位应该注册失败', () async {
      final notifier = container.read(authProvider.notifier);

      await notifier.register('newuser', '12345');

      final authState = container.read(authProvider);
      expect(authState.isAuthenticated, false);
      expect(authState.error, isNotNull);
    });

    test('应该能登出', () async {
      final notifier = container.read(authProvider.notifier);

      // 先登录
      await notifier.login('testuser', 'password123');
      expect(container.read(authProvider).isAuthenticated, true);

      // 再登出
      await notifier.logout();

      final authState = container.read(authProvider);
      expect(authState.isAuthenticated, false);
      expect(authState.userId, isNull);
      expect(authState.username, isNull);
    });

    test('应该能清空错误', () async {
      final notifier = container.read(authProvider.notifier);

      // 触发错误
      await notifier.login('', '');
      expect(container.read(authProvider).error, isNotNull);

      // 清空错误
      notifier.clearError();

      final authState = container.read(authProvider);
      expect(authState.error, isNull);
    });

    test('isAuthenticatedProvider应该返回正确的认证状态', () async {
      expect(container.read(isAuthenticatedProvider), false);

      final notifier = container.read(authProvider.notifier);
      await notifier.login('testuser', 'password123');

      expect(container.read(isAuthenticatedProvider), true);
    });

    test('currentUserIdProvider应该返回正确的用户ID', () async {
      expect(container.read(currentUserIdProvider), isNull);

      final notifier = container.read(authProvider.notifier);
      await notifier.login('testuser', 'password123');

      expect(container.read(currentUserIdProvider), isNotNull);
    });

    test('AuthState.copyWith应该正确复制状态', () {
      const state = AuthState(
        userId: 'user1',
        username: 'test',
        isAuthenticated: true,
      );

      final newState = state.copyWith(username: 'newtest');

      expect(newState.userId, 'user1');
      expect(newState.username, 'newtest');
      expect(newState.isAuthenticated, true);
    });
  });
}
