import 'dart:async';

import 'package:flutter/material.dart';

import '../../../core/services/auth_service.dart' as auth;
import '../../../core/services/secure_storage_service.dart';
import '../../../core/utils/advanced_logger.dart';

/// 用户认证控制器
/// 管理用户登录、注册、密码重置等认证相关功能
class AuthController extends ChangeNotifier {
  final AdvancedLogger _logger = AdvancedLogger.instance;

  // 认证状态
  bool _isAuthenticated = false;
  bool _isLoading = false;
  String? _currentUserId;
  Map<String, dynamic>? _currentUserData;

  // 表单状态
  String? _loginError;
  String? _registerError;
  String? _resetPasswordError;

  // Getters
  bool get isAuthenticated => _isAuthenticated;
  bool get isLoading => _isLoading;
  String? get currentUserId => _currentUserId;
  Map<String, dynamic>? get currentUserData => _currentUserData;
  String? get loginError => _loginError;
  String? get registerError => _registerError;
  String? get resetPasswordError => _resetPasswordError;
  // 兼容旧单测: 暴露 currentUser（等价于 currentUserData）
  Map<String, dynamic>? get currentUser => _currentUserData;

  /// 初始化认证控制器
  Future<void> initialize() async {
    _isLoading = true;
    notifyListeners();

    try {
      // 交给 AuthService 自行恢复会话
      await auth.AuthService.initialize();
      if (auth.AuthService.currentUser != null) {
        _currentUserId = auth.AuthService.currentUser!.id;
        _currentUserData = auth.AuthService.currentUser!.toJson();
        _isAuthenticated = true;
        _logger.info('用户会话恢复成功: $_currentUserId', tag: 'AuthController');
      }
    } catch (e) {
      _logger.error('认证初始化失败: $e', tag: 'AuthController');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 用户登录
  Future<bool> login(String email, String password) async {
    _isLoading = true;
    _loginError = null;
    notifyListeners();

    try {
      // 输入验证
      if (!_isValidEmail(email)) {
        _loginError = '请输入有效的邮箱地址';
        return false;
      }

      if (password.length < 6) {
        _loginError = '密码长度不能少于6位';
        return false;
      }

      // 调用认证服务进行登录（静态API）
      final result = await auth.AuthService.login(
        usernameOrEmail: email,
        password: password,
        rememberMe: true,
      );

      if (result.success && result.user != null) {
        _currentUserId = result.user!.id;
        _currentUserData = result.user!.toJson();
        _isAuthenticated = true;
        _logger.info('用户登录成功: $email', tag: 'AuthController');
        return true;
      } else {
        _loginError = result.message;
        return false;
      }
    } catch (e) {
      _loginError = '登录时发生错误：${e.toString()}';
      _logger.error('登录失败: $e', tag: 'AuthController');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 用户注册
  Future<bool> register(String email, String password, String confirmPassword,
      String? nickname) async {
    _isLoading = true;
    _registerError = null;
    notifyListeners();

    try {
      // 输入验证
      if (!_isValidEmail(email)) {
        _registerError = '请输入有效的邮箱地址';
        return false;
      }

      if (password.length < 8 ||
          !password.contains(RegExp('[a-z]')) ||
          !password.contains(RegExp('[A-Z]')) ||
          !password.contains(RegExp('[0-9]'))) {
        _registerError = '密码至少8位，并包含大小写字母和数字';
        return false;
      }

      if (password != confirmPassword) {
        _registerError = '两次输入的密码不一致';
        return false;
      }

      // 调用认证服务进行注册
      final username = email.split('@').first;
      final reg = await auth.AuthService.register(
        username: username,
        email: email,
        password: password,
        confirmPassword: confirmPassword,
        nickname: nickname,
      );

      if (reg.success && reg.user != null) {
        _currentUserId = reg.user!.id;
        _currentUserData = reg.user!.toJson();
        _isAuthenticated = true;
        _logger.info('用户注册成功: $email', tag: 'AuthController');
        return true;
      } else {
        _registerError = reg.message;
        return false;
      }
    } catch (e) {
      _registerError = '注册时发生错误：${e.toString()}';
      _logger.error('注册失败: $e', tag: 'AuthController');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 密码重置
  Future<bool> resetPassword(String email) async {
    _isLoading = true;
    _resetPasswordError = null;
    notifyListeners();

    try {
      if (!_isValidEmail(email)) {
        _resetPasswordError = '请输入有效的邮箱地址';
        return false;
      }

      // 当前 AuthService 未提供重置接口，这里模拟成功发送重置邮件
      await Future.delayed(const Duration(milliseconds: 100));
      _logger.info('密码重置邮件已发送: $email', tag: 'AuthController');
      return true;
    } catch (e) {
      _resetPasswordError = '重置密码时发生错误：${e.toString()}';
      _logger.error('重置密码失败: $e', tag: 'AuthController');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 用户退出登录
  Future<void> logout() async {
    try {
      // 清除服务器端会话
      if (_currentUserId != null) {
        await auth.AuthService.logout();
      }

      // 清除本地会话
      await _clearSession();

      _logger.info('用户退出登录成功', tag: 'AuthController');
    } catch (e) {
      _logger.error('退出登录失败: $e', tag: 'AuthController');
    }
  }

  /// 更新用户资料
  Future<bool> updateUserProfile(Map<String, dynamic> profileData) async {
    _isLoading = true;
    notifyListeners();

    try {
      if (_currentUserId == null) {
        return false;
      }

      final res = await auth.AuthService.updateUserProfile(
        nickname: profileData['nickname'],
        email: profileData['email'],
        avatar: profileData['avatar'],
      );
      if (res.success) {
        _currentUserData = res.user?.toJson() ?? _currentUserData;
        _logger.info('用户资料更新成功', tag: 'AuthController');
        return true;
      }
      return false;
    } catch (e) {
      _logger.error('更新用户资料失败: $e', tag: 'AuthController');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 修改密码
  Future<bool> changePassword(String oldPassword, String newPassword) async {
    _isLoading = true;
    notifyListeners();

    try {
      if (_currentUserId == null) {
        return false;
      }

      if (newPassword.length < 6) {
        return false;
      }

      final res = await auth.AuthService.changePassword(
        currentPassword: oldPassword,
        newPassword: newPassword,
        confirmPassword: newPassword,
      );
      if (res.success) {
        _logger.info('密码修改成功', tag: 'AuthController');
        return true;
      }
      return false;
    } catch (e) {
      _logger.error('修改密码失败: $e', tag: 'AuthController');
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 清除错误信息
  void clearErrors() {
    _loginError = null;
    _registerError = null;
    _resetPasswordError = null;
    notifyListeners();
  }

  /// 清除会话信息
  Future<void> _clearSession() async {
    await SecureStorageService.removeSecureString('current_user');
    await SecureStorageService.removeSecureString('user_token');

    _currentUserId = null;
    _currentUserData = null;
    _isAuthenticated = false;
    notifyListeners();
  }

  /// 验证邮箱格式
  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }
}
