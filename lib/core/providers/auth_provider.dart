import 'package:flutter_riverpod/flutter_riverpod.dart';

/// 用户认证状态
class AuthState {
  final String? userId;
  final String? username;
  final bool isAuthenticated;
  final bool isLoading;
  final String? error;

  const AuthState({
    this.userId,
    this.username,
    this.isAuthenticated = false,
    this.isLoading = false,
    this.error,
  });

  AuthState copyWith({
    String? userId,
    String? username,
    bool? isAuthenticated,
    bool? isLoading,
    String? error,
  }) {
    return AuthState(
      userId: userId ?? this.userId,
      username: username ?? this.username,
      isAuthenticated: isAuthenticated ?? this.isAuthenticated,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// 认证Provider
class AuthNotifier extends StateNotifier<AuthState> {
  AuthNotifier() : super(const AuthState());

  /// 登录
  Future<void> login(String username, String password) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // 模拟登录逻辑
      await Future.delayed(const Duration(seconds: 1));

      // 简单验证
      if (username.isNotEmpty && password.isNotEmpty) {
        state = AuthState(
          userId: 'user_${username.hashCode}',
          username: username,
          isAuthenticated: true,
          isLoading: false,
        );
      } else {
        throw Exception('用户名或密码不能为空');
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// 注册
  Future<void> register(String username, String password) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      // 模拟注册逻辑
      await Future.delayed(const Duration(seconds: 1));

      if (username.isNotEmpty && password.length >= 6) {
        state = AuthState(
          userId: 'user_${username.hashCode}',
          username: username,
          isAuthenticated: true,
          isLoading: false,
        );
      } else {
        throw Exception('用户名不能为空且密码至少6位');
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }

  /// 登出
  Future<void> logout() async {
    state = const AuthState();
  }

  /// 清空错误
  void clearError() {
    state = state.copyWith(error: null);
  }
}

/// Auth Provider定义
final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  return AuthNotifier();
});

/// 是否已登录Provider
final isAuthenticatedProvider = Provider<bool>((ref) {
  return ref.watch(authProvider).isAuthenticated;
});

/// 当前用户ID Provider
final currentUserIdProvider = Provider<String?>((ref) {
  return ref.watch(authProvider).userId;
});
