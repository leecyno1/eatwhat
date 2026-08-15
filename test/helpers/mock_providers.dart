import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';

/// Mock Provider工具
class MockProviders {
  /// 创建Mock Provider用于测试
  static ProviderContainer createContainer({
    List<Override> overrides = const [],
  }) {
    return ProviderContainer(overrides: overrides);
  }

  /// 为Riverpod Provider创建Mock
  static Override mockProvider<T>(
    Provider<T> provider,
    T mockValue,
  ) {
    return provider.overrideWith((ref) => mockValue);
  }

  /// 为Riverpod Provider创建错误Mock
  static Override mockProviderError<T>(
    Provider<AsyncValue<T>> provider,
    Object error,
    StackTrace stackTrace,
  ) {
    return provider.overrideWith((ref) => AsyncValue.error(error, stackTrace));
  }

  /// 为Riverpod StateNotifier创建Mock
  static Override mockStateNotifier<NotifierT extends StateNotifier<T>, T>(
    StateNotifierProvider<NotifierT, T> provider,
    NotifierT notifier,
  ) {
    return provider.overrideWith((ref) => notifier);
  }
}

/// Mock基类
class MockService extends Mock {}
