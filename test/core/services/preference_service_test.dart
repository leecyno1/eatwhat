import 'package:flutter_test/flutter_test.dart';
import '../../helpers/fake_repositories.dart';

void main() {
  group('PreferenceService', () {
    late FakePreferenceRepository fakePreferenceRepository;

    setUp(() {
      fakePreferenceRepository = FakePreferenceRepository();
    });

    test('应该能保存用户偏好', () async {
      // Arrange
      const userId = 'user123';
      final preference = {'spicy': 5, 'sweet': 2};

      // Act
      await fakePreferenceRepository.saveTastePreference(userId, preference);

      // Assert
      final saved = await fakePreferenceRepository.getTastePreference(userId);
      expect(saved, isNotNull);
      expect(saved?['spicy'], equals(5));
      expect(saved?['sweet'], equals(2));
    });

    test('应该能覆盖旧的偏好', () async {
      // Arrange
      const userId = 'user123';
      final oldPreference = {'spicy': 5};
      final newPreference = {'spicy': 3, 'sweet': 4};

      // Act
      await fakePreferenceRepository.saveTastePreference(userId, oldPreference);
      await fakePreferenceRepository.saveTastePreference(userId, newPreference);

      // Assert
      final saved = await fakePreferenceRepository.getTastePreference(userId);
      expect(saved?['spicy'], equals(3));
      expect(saved?['sweet'], equals(4));
    });

    test('获取不存在用户的偏好应该返回空', () async {
      // Arrange
      const nonExistentUserId = 'user999';

      // Act
      final preference = await fakePreferenceRepository.getTastePreference(nonExistentUserId);

      // Assert
      expect(preference, isNull);
    });
  });
}
