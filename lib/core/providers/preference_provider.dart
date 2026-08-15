import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 用户偏好状态
class PreferenceState {
  final Map<String, dynamic> preferences;
  final bool isLoading;
  final String? error;

  const PreferenceState({
    this.preferences = const {},
    this.isLoading = false,
    this.error,
  });

  PreferenceState copyWith({
    Map<String, dynamic>? preferences,
    bool? isLoading,
    String? error,
  }) {
    return PreferenceState(
      preferences: preferences ?? this.preferences,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// 偏好设置Provider
class PreferenceNotifier extends StateNotifier<PreferenceState> {
  PreferenceNotifier() : super(const PreferenceState());

  /// 设置偏好
  Future<void> setPreference(String key, dynamic value) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final newPreferences = Map<String, dynamic>.from(state.preferences);
      newPreferences[key] = value;

      state = state.copyWith(
        preferences: newPreferences,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// 获取偏好
  T? getPreference<T>(String key) {
    return state.preferences[key] as T?;
  }

  /// 删除偏好
  void removePreference(String key) {
    final newPreferences = Map<String, dynamic>.from(state.preferences);
    newPreferences.remove(key);

    state = state.copyWith(preferences: newPreferences);
  }

  /// 清空所有偏好
  void clearAll() {
    state = const PreferenceState();
  }

  /// 批量设置偏好
  Future<void> setPreferences(Map<String, dynamic> preferences) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final newPreferences = Map<String, dynamic>.from(state.preferences);
      newPreferences.addAll(preferences);

      state = state.copyWith(
        preferences: newPreferences,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }
}

/// Preference Provider定义
final preferenceProvider = StateNotifierProvider<PreferenceNotifier, PreferenceState>((ref) {
  return PreferenceNotifier();
});

/// 主题模式Provider
final themeModeProvider = Provider<String>((ref) {
  return ref.watch(preferenceProvider).preferences['theme_mode'] as String? ?? 'system';
});

/// 语言Provider
final languageProvider = Provider<String>((ref) {
  return ref.watch(preferenceProvider).preferences['language'] as String? ?? 'zh';
});

/// 通知开关Provider
final notificationEnabledProvider = Provider<bool>((ref) {
  return ref.watch(preferenceProvider).preferences['notification_enabled'] as bool? ?? true;
});
