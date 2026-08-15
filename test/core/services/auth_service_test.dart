import 'package:flutter_test/flutter_test.dart';
import '../../helpers/fake_repositories.dart';

void main() {
  group('AuthService', () {
    late FakeAuthRepository fakeAuthRepository;

    setUp(() {
      fakeAuthRepository = FakeAuthRepository();
    });

    tearDown(() {
      fakeAuthRepository.reset();
    });

    test('初始状态应该是未认证', () {
      expect(fakeAuthRepository.isAuthenticated, false);
      expect(fakeAuthRepository.currentUserId, isNull);
    });

    test('登录成功后应该更新认证状态', () async {
      // Arrange
      const phone = '13800138000';
      const password = 'password123';

      // Act
      await fakeAuthRepository.login(phone, password);

      // Assert
      expect(fakeAuthRepository.isAuthenticated, true);
      expect(fakeAuthRepository.currentUserId, isNotNull);
      expect(fakeAuthRepository.currentUserId, contains(phone));
    });

    test('登出后应该清除认证状态', () async {
      // Arrange
      await fakeAuthRepository.login('13800138000', 'password');
      expect(fakeAuthRepository.isAuthenticated, true);

      // Act
      await fakeAuthRepository.logout();

      // Assert
      expect(fakeAuthRepository.isAuthenticated, false);
      expect(fakeAuthRepository.currentUserId, isNull);
    });
  });
}
