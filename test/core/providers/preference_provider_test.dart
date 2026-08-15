import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:eatwhat_app/core/providers/preference_provider.dart';

void main() {
  group('PreferenceProvider', () {
    late ProviderContainer container;

    setUp(() {
      container = ProviderContainer();
    });

    tearDown(() {
      container.dispose();
    });

    test('初始状态应该是空偏好', () {
      final state = container.read(preferenceProvider);
      expect(state.preferences, isEmpty);
      expect(state.isLoading, false);
      expect(state.error, isNull);
    });

    test('应该能设置偏好', () async {
      final notifier = container.read(preferenceProvider.notifier);

      await notifier.setPreference('theme', 'dark');

      final state = container.read(preferenceProvider);
      expect(state.preferences['theme'], 'dark');
      expect(state.isLoading, false);
    });

    test('应该能获取偏好', () async {
      final notifier = container.read(preferenceProvider.notifier);

      await notifier.setPreference('language', 'en');

      final language = notifier.getPreference<String>('language');
      expect(language, 'en');
    });

    test('应该能删除偏好', () async {
      final notifier = container.read(preferenceProvider.notifier);

      await notifier.setPreference('key1', 'value1');
      expect(container.read(preferenceProvider).preferences['key1'], 'value1');

      notifier.removePreference('key1');

      final state = container.read(preferenceProvider);
      expect(state.preferences.containsKey('key1'), false);
    });

    test('应该能清空所有偏好', () async {
      final notifier = container.read(preferenceProvider.notifier);

      await notifier.setPreference('key1', 'value1');
      await notifier.setPreference('key2', 'value2');
      expect(container.read(preferenceProvider).preferences.length, 2);

      notifier.clearAll();

      final state = container.read(preferenceProvider);
      expect(state.preferences, isEmpty);
    });

    test('应该能批量设置偏好', () async {
      final notifier = container.read(preferenceProvider.notifier);

      await notifier.setPreferences({
        'theme': 'dark',
        'language': 'zh',
        'notifications': true,
      });

      final state = container.read(preferenceProvider);
      expect(state.preferences['theme'], 'dark');
      expect(state.preferences['language'], 'zh');
      expect(state.preferences['notifications'], true);
    });

    test('themeModeProvider应该返回正确的主题模式', () async {
      expect(container.read(themeModeProvider), 'system');

      final notifier = container.read(preferenceProvider.notifier);
      await notifier.setPreference('theme_mode', 'dark');

      expect(container.read(themeModeProvider), 'dark');
    });

    test('languageProvider应该返回正确的语言', () async {
      expect(container.read(languageProvider), 'zh');

      final notifier = container.read(preferenceProvider.notifier);
      await notifier.setPreference('language', 'en');

      expect(container.read(languageProvider), 'en');
    });

    test('notificationEnabledProvider应该返回正确的通知状态', () async {
      expect(container.read(notificationEnabledProvider), true);

      final notifier = container.read(preferenceProvider.notifier);
      await notifier.setPreference('notification_enabled', false);

      expect(container.read(notificationEnabledProvider), false);
    });

    test('PreferenceState.copyWith应该正确复制状态', () {
      const state = PreferenceState(
        preferences: {'key': 'value'},
        isLoading: true,
      );

      final newState = state.copyWith(isLoading: false);

      expect(newState.preferences['key'], 'value');
      expect(newState.isLoading, false);
    });
  });
}
