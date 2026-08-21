import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/env_config.dart';
import '../models/user_preference.dart';
import '../utils/password_hash_util.dart';
import 'secure_storage_service.dart';
import 'token_service.dart';

/// 用户认证服务
/// 处理用户注册、登录、注销等认证相关功能
class AuthService {
  static const String _keyCurrentUser = 'current_user';
  static const String _keyUserToken = 'user_token';
  static const String _keyRememberMe = 'remember_me';
  static const String _keyUsers = 'users_db';

  static User? _currentUser;
  static String? _authToken;
  static DateTime? _sessionExpiry;
  static DateTime? _lastActivity;
  static final Dio _dio = Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 4),
      sendTimeout: const Duration(seconds: 4),
      receiveTimeout: const Duration(seconds: 8),
    ),
  );

  /// 获取当前用户
  static User? get currentUser => _currentUser;

  /// 获取认证令牌
  static String? get authToken => _authToken;

  /// 检查是否已登录
  static bool get isLoggedIn =>
      _currentUser != null && _authToken != null && !isSessionExpired;

  /// 检查会话是否过期
  static bool get isSessionExpired {
    if (_sessionExpiry == null) return false;
    return DateTime.now().isAfter(_sessionExpiry!);
  }

  /// 获取会话剩余时间
  static Duration? get sessionTimeRemaining {
    if (_sessionExpiry == null) return null;
    final now = DateTime.now();
    if (now.isAfter(_sessionExpiry!)) return Duration.zero;
    return _sessionExpiry!.difference(now);
  }

  /// 检查是否需要刷新会话
  static bool get shouldRefreshSession {
    final remaining = sessionTimeRemaining;
    if (remaining == null) return false;
    return remaining.inMinutes < 30; // 30分钟内过期时需要刷新
  }

  /// Seed admin/user credentials for demos and reviews (管理员/用户测试账号).
  static const String seedUsername = '17600806220';
  static const String seedPassword = 'Iv19whot@123';

  /// 初始化认证服务
  static Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    _resetSession();
    await _ensureSeedAccount();

    // 检查记住登录状态
    final rememberMe = prefs.getBool(_keyRememberMe) ?? false;
    if (rememberMe) {
      try {
        // 从安全存储读取用户信息
        final userMap =
            await SecureStorageService.getSecureJson(_keyCurrentUser);
        final token = await SecureStorageService.getSecureString(_keyUserToken);

        if (token == null) {
          await _clearStoredAuth();
          return;
        }

        if (EnvConfig.eatWhatAuthBaseUrl.isNotEmpty) {
          final restored = await _restoreRemoteSession(token);
          if (!restored) await _clearStoredAuth();
          return;
        }

        if (userMap != null) {
          final tokenValidation = TokenService.validateToken(token);
          if (tokenValidation.isValid && tokenValidation.expiresAt != null) {
            _currentUser = User.fromJson(userMap);
            _authToken = token;
            _sessionExpiry = tokenValidation.expiresAt;
            _lastActivity = DateTime.now();
            return;
          }
        }
        await _clearStoredAuth();
      } catch (e) {
        // 如果数据损坏，清除存储的登录信息
        await _clearStoredAuth();
      }
    }
  }

  /// 用户注册
  static Future<AuthResult> register({
    required String username,
    required String email,
    required String password,
    required String confirmPassword,
    String? nickname,
  }) async {
    if (EnvConfig.eatWhatAuthBaseUrl.isNotEmpty) {
      return _registerRemote(
        username: username,
        email: email,
        password: password,
        confirmPassword: confirmPassword,
        nickname: nickname,
      );
    }
    try {
      // 验证输入
      final validation =
          _validateRegistration(username, email, password, confirmPassword);
      if (!validation.success) {
        return validation;
      }

      // 验证密码强度
      final passwordValidation =
          PasswordHashUtil.validatePasswordComplexity(password);
      if (passwordValidation != null) {
        return AuthResult(success: false, message: passwordValidation);
      }

      // 检查用户是否已存在
      final existingUser = await _getUserByUsernameOrEmail(username, email);
      if (existingUser != null) {
        return AuthResult(
          success: false,
          message: existingUser.username == username ? '用户名已存在' : '邮箱已被注册',
        );
      }

      // 创建新用户
      final now = DateTime.now();
      final user = User(
        id: now.millisecondsSinceEpoch.toString(),
        username: username,
        email: email,
        nickname: nickname ?? username,
        passwordHash: _hashPassword(password),
        createdAt: now,
        lastLoginAt: now,
        // Registration comes with a trial membership so the account sheet
        // shows a live tier instead of a coming-soon teaser.
        isMember: true,
        memberSince: now,
        memberExpiresAt: now.add(
          const Duration(days: User.trialMemberDays),
        ),
        userPreference: UserPreference(
          userId: now.millisecondsSinceEpoch.toString(),
          // 默认偏好设置
        ),
      );

      // 保存用户到本地数据库
      await _saveUser(user);

      // 自动登录
      await _setCurrentUser(user, rememberMe: true);

      return AuthResult(
        success: true,
        message: '注册成功',
        user: user,
      );
    } catch (e) {
      return AuthResult(
        success: false,
        message: '注册失败: ${e.toString()}',
      );
    }
  }

  /// 用户登录
  static Future<AuthResult> login({
    required String usernameOrEmail,
    required String password,
    bool rememberMe = false,
  }) async {
    if (EnvConfig.eatWhatAuthBaseUrl.isNotEmpty) {
      return _loginRemote(
        usernameOrEmail: usernameOrEmail,
        password: password,
        rememberMe: rememberMe,
      );
    }
    try {
      // 验证输入
      if (usernameOrEmail.trim().isEmpty || password.isEmpty) {
        return AuthResult(
          success: false,
          message: '用户名/邮箱和密码不能为空',
        );
      }

      // 查找用户
      final user =
          await _getUserByUsernameOrEmail(usernameOrEmail, usernameOrEmail);
      if (user == null) {
        return AuthResult(
          success: false,
          message: '用户不存在',
        );
      }

      // 验证密码
      if (!_verifyPassword(password, user.passwordHash)) {
        return AuthResult(
          success: false,
          message: '密码错误',
        );
      }

      // 更新最后登录时间
      final updatedUser = user.copyWith(lastLoginAt: DateTime.now());
      await _updateUser(updatedUser);

      // 设置当前用户和会话
      await _setCurrentUser(updatedUser, rememberMe: rememberMe);

      return AuthResult(
        success: true,
        message: '登录成功',
        user: updatedUser,
      );
    } catch (e) {
      return AuthResult(
        success: false,
        message: '登录失败: ${e.toString()}',
      );
    }
  }

  /// 用户注销
  /// 更新当前用户资料（会员状态、昵称等），同步本地库与会话。
  static Future<bool> updateCurrentUser(User user) async {
    if (_currentUser == null || _currentUser!.id != user.id) return false;
    try {
      await _updateUser(user);
      await _setCurrentUser(user, rememberMe: true);
      return true;
    } catch (e) {
      debugPrint('更新当前用户失败: $e');
      return false;
    }
  }

  static Future<void> logout() async {
    _resetSession();

    // 清除所有存储的认证信息和令牌
    await _clearStoredAuth();
    await TokenService.clearTokens();
  }

  /// 更新用户信息
  static Future<AuthResult> updateUserProfile({
    String? nickname,
    String? email,
    String? avatar,
  }) async {
    if (!isLoggedIn) {
      return AuthResult(success: false, message: '用户未登录');
    }

    try {
      final updatedUser = _currentUser!.copyWith(
        nickname: nickname,
        email: email,
        avatar: avatar,
        updatedAt: DateTime.now(),
      );

      await _updateUser(updatedUser);
      _currentUser = updatedUser;

      // 更新安全存储中的用户信息
      await SecureStorageService.setSecureJson(
          _keyCurrentUser, updatedUser.toJson());

      return AuthResult(
        success: true,
        message: '用户信息更新成功',
        user: updatedUser,
      );
    } catch (e) {
      return AuthResult(
        success: false,
        message: '更新失败: ${e.toString()}',
      );
    }
  }

  /// 修改密码
  static Future<AuthResult> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    if (!isLoggedIn) {
      return AuthResult(success: false, message: '用户未登录');
    }

    try {
      // 验证当前密码
      if (!_verifyPassword(currentPassword, _currentUser!.passwordHash)) {
        return AuthResult(success: false, message: '当前密码错误');
      }

      // 验证新密码
      if (newPassword.length < 6) {
        return AuthResult(success: false, message: '新密码长度至少6位');
      }

      if (newPassword != confirmPassword) {
        return AuthResult(success: false, message: '两次输入的新密码不一致');
      }

      // 更新密码
      final updatedUser = _currentUser!.copyWith(
        passwordHash: _hashPassword(newPassword),
        updatedAt: DateTime.now(),
      );

      await _updateUser(updatedUser);
      _currentUser = updatedUser;

      return AuthResult(success: true, message: '密码修改成功');
    } catch (e) {
      return AuthResult(
        success: false,
        message: '密码修改失败: ${e.toString()}',
      );
    }
  }

  /// 删除账户
  static Future<AuthResult> deleteAccount(String password) async {
    if (!isLoggedIn) {
      return AuthResult(success: false, message: '用户未登录');
    }

    try {
      // 验证密码
      if (!_verifyPassword(password, _currentUser!.passwordHash)) {
        return AuthResult(success: false, message: '密码错误');
      }

      // 删除用户数据
      await _deleteUser(_currentUser!.id);

      // 注销登录
      await logout();

      return AuthResult(success: true, message: '账户删除成功');
    } catch (e) {
      return AuthResult(
        success: false,
        message: '账户删除失败: ${e.toString()}',
      );
    }
  }

  // 私有方法

  /// 验证注册信息
  static AuthResult _validateRegistration(
    String username,
    String email,
    String password,
    String confirmPassword,
  ) {
    if (username.trim().isEmpty) {
      return AuthResult(success: false, message: '用户名不能为空');
    }

    if (username.length < 3 || username.length > 20) {
      return AuthResult(success: false, message: '用户名长度应在3-20字符之间');
    }

    // Chinese usernames are the natural choice for this app: letters,
    // digits, underscore, and CJK characters are all allowed.
    if (!RegExp(r'^[a-zA-Z0-9_\u4e00-\u9fa5]+$').hasMatch(username)) {
      return AuthResult(success: false, message: '用户名只能包含中文、字母、数字和下划线');
    }

    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      return AuthResult(success: false, message: '邮箱格式不正确');
    }

    if (password.length < 8 ||
        !password.contains(RegExp('[a-z]')) ||
        !password.contains(RegExp('[A-Z]')) ||
        !password.contains(RegExp('[0-9]'))) {
      return AuthResult(success: false, message: '密码至少8位，并包含大小写字母和数字');
    }

    if (password != confirmPassword) {
      return AuthResult(success: false, message: '两次输入的密码不一致');
    }

    return AuthResult(success: true, message: '验证通过');
  }

  /// 密码哈希（使用PBKDF2）
  static String _hashPassword(String password) {
    return PasswordHashUtil.hashPassword(password);
  }

  /// 验证密码
  static bool _verifyPassword(String password, String hash) {
    return PasswordHashUtil.verifyPassword(password, hash);
  }

  /// 设置当前用户
  static Future<void> _setCurrentUser(User user,
      {bool rememberMe = false}) async {
    _currentUser = user;

    // 生成JWT令牌对
    final tokenPair = await TokenService.generateTokenPair(user.id);
    _authToken = tokenPair.accessToken;
    _sessionExpiry = tokenPair.expiresAt;
    _lastActivity = DateTime.now();

    if (rememberMe) {
      // 使用安全存储保存敏感信息
      await SecureStorageService.setSecureJson(_keyCurrentUser, user.toJson());
      await SecureStorageService.setSecureString(_keyUserToken, _authToken!);

      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_keyRememberMe, true);
    }
  }

  static Future<AuthResult> _registerRemote({
    required String username,
    required String email,
    required String password,
    required String confirmPassword,
    String? nickname,
  }) async {
    final validation = _validateRegistration(
      username,
      email,
      password,
      confirmPassword,
    );
    if (!validation.success) return validation;
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        _authUrl('/api/v1/auth/register'),
        data: {
          'username': username.trim(),
          'email': email.trim(),
          'password': password,
          if (nickname?.trim().isNotEmpty == true) 'nickname': nickname!.trim(),
        },
      );
      return _acceptRemoteSession(
        response.data,
        rememberMe: true,
        successMessage: '注册成功',
      );
    } on DioException catch (error) {
      return AuthResult(success: false, message: _remoteError(error, '注册失败'));
    }
  }

  static Future<AuthResult> _loginRemote({
    required String usernameOrEmail,
    required String password,
    required bool rememberMe,
  }) async {
    if (usernameOrEmail.trim().isEmpty || password.isEmpty) {
      return AuthResult(success: false, message: '用户名/邮箱和密码不能为空');
    }
    try {
      final response = await _dio.post<Map<String, dynamic>>(
        _authUrl('/api/v1/auth/login'),
        data: {
          'account': usernameOrEmail.trim(),
          'password': password,
        },
      );
      return _acceptRemoteSession(
        response.data,
        rememberMe: rememberMe,
        successMessage: '登录成功',
      );
    } on DioException catch (error) {
      return AuthResult(success: false, message: _remoteError(error, '登录失败'));
    }
  }

  static Future<AuthResult> _acceptRemoteSession(
    Map<String, dynamic>? payload, {
    required bool rememberMe,
    required String successMessage,
  }) async {
    final json = payload ?? const <String, dynamic>{};
    final token = json['accessToken']?.toString() ?? '';
    final expiresAt = DateTime.tryParse(json['expiresAt']?.toString() ?? '');
    final user = _remoteUser(json['user']);
    if (token.isEmpty || user == null || expiresAt == null) {
      return AuthResult(success: false, message: '吃什么登录服务返回格式错误');
    }
    final now = DateTime.now();
    _currentUser = user;
    _authToken = token;
    _sessionExpiry = expiresAt;
    _lastActivity = now;
    if (rememberMe) {
      await _storeRemoteSession(user, token);
    } else {
      await _clearStoredAuth(resetSession: false);
    }
    return AuthResult(success: true, message: successMessage, user: user);
  }

  static Future<bool> _restoreRemoteSession(String token) async {
    try {
      final response = await _dio.get<Map<String, dynamic>>(
        _authUrl('/api/v1/auth/session'),
        options: Options(
          headers: {'Authorization': 'Bearer $token'},
        ),
      );
      final user = _remoteUser(response.data?['user']);
      final expiresAt = _jwtExpiryWithoutVerification(token);
      if (user == null ||
          expiresAt == null ||
          !expiresAt.isAfter(DateTime.now())) {
        return false;
      }
      _currentUser = user;
      _authToken = token;
      _sessionExpiry = expiresAt;
      _lastActivity = DateTime.now();
      await _storeRemoteSession(user, token);
      return true;
    } on DioException {
      return false;
    }
  }

  static User? _remoteUser(dynamic rawUser) {
    if (rawUser is! Map) return null;
    final json = Map<String, dynamic>.from(rawUser);
    final id = json['id']?.toString().trim() ?? '';
    final username = json['username']?.toString().trim() ?? '';
    final email = json['email']?.toString().trim() ?? '';
    final createdAt = DateTime.tryParse(json['createdAt']?.toString() ?? '');
    final lastLoginAt =
        DateTime.tryParse(json['lastLoginAt']?.toString() ?? '');
    if (id.isEmpty ||
        username.isEmpty ||
        email.isEmpty ||
        createdAt == null ||
        lastLoginAt == null) {
      return null;
    }
    return User(
      id: id,
      username: username,
      email: email,
      nickname: json['nickname']?.toString().trim().isNotEmpty == true
          ? json['nickname'].toString().trim()
          : username,
      passwordHash: '',
      createdAt: createdAt,
      lastLoginAt: lastLoginAt,
      userPreference: UserPreference(userId: id),
    );
  }

  static DateTime? _jwtExpiryWithoutVerification(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) return null;
      final payload = json.decode(
        utf8.decode(base64Url.decode(base64Url.normalize(parts[1]))),
      );
      if (payload is! Map || payload['exp'] is! num) return null;
      return DateTime.fromMillisecondsSinceEpoch(
        (payload['exp'] as num).toInt() * 1000,
      );
    } on Object {
      return null;
    }
  }

  static Future<void> _storeRemoteSession(User user, String token) async {
    await SecureStorageService.setSecureJson(_keyCurrentUser, user.toJson());
    await SecureStorageService.setSecureString(_keyUserToken, token);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_keyRememberMe, true);
  }

  static String _authUrl(String path) {
    return '${EnvConfig.eatWhatAuthBaseUrl.replaceFirst(RegExp(r'/+$'), '')}$path';
  }

  static String _remoteError(DioException error, String fallback) {
    final data = error.response?.data;
    if (data is Map && data['error'] is Map) {
      final message =
          (data['error'] as Map)['message']?.toString().trim() ?? '';
      if (message.isNotEmpty) return message;
    }
    return fallback;
  }

  /// 清除存储的认证信息
  static Future<void> _clearStoredAuth({bool resetSession = true}) async {
    if (resetSession) _resetSession();
    // 清除安全存储中的敏感信息
    await SecureStorageService.removeSecureString(_keyCurrentUser);
    await SecureStorageService.removeSecureString(_keyUserToken);

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyRememberMe);
  }

  /// 获取用户通过用户名或邮箱
  static Future<User?> _getUserByUsernameOrEmail(
      String username, String email) async {
    final prefs = await SharedPreferences.getInstance();
    final usersJson = prefs.getString(_keyUsers);

    if (usersJson == null) return null;

    try {
      final List<dynamic> usersList = json.decode(usersJson);
      for (final userMap in usersList) {
        final user = User.fromJson(userMap as Map<String, dynamic>);
        if (user.username == username || user.email == email) {
          return user;
        }
      }
    } catch (e) {
      // 数据损坏，清除
      await prefs.remove(_keyUsers);
    }

    return null;
  }

  /// 保存用户
  static Future<void> _saveUser(User user) async {
    final prefs = await SharedPreferences.getInstance();

    List<Map<String, dynamic>> users = [];

    final usersJson = prefs.getString(_keyUsers);
    if (usersJson != null) {
      try {
        final List<dynamic> usersList = json.decode(usersJson);
        users = usersList.cast<Map<String, dynamic>>();
      } catch (e) {
        // 数据损坏，重新开始
        users = [];
      }
    }

    users.add(user.toJson());
    await prefs.setString(_keyUsers, json.encode(users));
  }

  /// Creates the seeded admin/user account once if absent. The account is a
  /// full member (no trial expiry) so demo flows exercise the member path.
  static Future<void> _ensureSeedAccount() async {
    try {
      final existing = await _getUserByUsernameOrEmail(
        seedUsername,
        '$seedUsername@seed.eatwhat',
      );
      if (existing != null) return;
      final now = DateTime.now();
      final user = User(
        id: 'seed-admin-001',
        username: seedUsername,
        email: '$seedUsername@seed.eatwhat',
        nickname: '管理员',
        passwordHash: _hashPassword(seedPassword),
        createdAt: now,
        lastLoginAt: now,
        userPreference: UserPreference(userId: 'seed-admin-001'),
        isMember: true,
        memberSince: now,
      );
      await _saveUser(user);
      debugPrint('种子账号已创建: $seedUsername');
    } catch (e) {
      debugPrint('种子账号创建失败: $e');
    }
  }

  /// 更新用户
  static Future<void> _updateUser(User user) async {
    final prefs = await SharedPreferences.getInstance();

    List<Map<String, dynamic>> users = [];

    final usersJson = prefs.getString(_keyUsers);
    if (usersJson != null) {
      try {
        final List<dynamic> usersList = json.decode(usersJson);
        users = usersList.cast<Map<String, dynamic>>();
      } catch (e) {
        return; // 无法更新
      }
    }

    // 找到并更新用户
    for (int i = 0; i < users.length; i++) {
      if (users[i]['id'] == user.id) {
        users[i] = user.toJson();
        break;
      }
    }

    await prefs.setString(_keyUsers, json.encode(users));
  }

  /// 删除用户
  static Future<void> _deleteUser(String userId) async {
    final prefs = await SharedPreferences.getInstance();

    final usersJson = prefs.getString(_keyUsers);
    if (usersJson == null) return;

    try {
      final List<dynamic> usersList = json.decode(usersJson);
      final users = usersList.cast<Map<String, dynamic>>();

      users.removeWhere((userMap) => userMap['id'] == userId);

      await prefs.setString(_keyUsers, json.encode(users));
    } catch (e) {
      // 忽略删除错误
    }
  }

  /// 刷新会话
  static Future<bool> refreshSession() async {
    if (!isLoggedIn || _currentUser == null) return false;

    if (EnvConfig.eatWhatAuthBaseUrl.isNotEmpty) {
      final token = _authToken;
      if (token == null) return false;
      final restored = await _restoreRemoteSession(token);
      if (!restored) await logout();
      return restored;
    }

    try {
      final newTokenPair = await TokenService.refreshToken();
      if (newTokenPair != null) {
        _authToken = newTokenPair.accessToken;
        _sessionExpiry = newTokenPair.expiresAt;
        _lastActivity = DateTime.now();

        // 更新存储的令牌
        await SecureStorageService.setSecureString(_keyUserToken, _authToken!);
        return true;
      }
    } catch (e) {
      debugPrint('Session refresh failed: $e');
    }

    return false;
  }

  /// 记录用户活动
  static void recordActivity() {
    if (isLoggedIn) {
      _lastActivity = DateTime.now();
    }
  }

  /// 检查会话并自动刷新
  static Future<bool> checkAndRefreshSession() async {
    if (!isLoggedIn) return false;

    // 记录活动
    recordActivity();

    // 检查是否需要刷新
    if (shouldRefreshSession) {
      return refreshSession();
    }

    // 检查是否已过期
    if (isSessionExpired) {
      await logout();
      return false;
    }

    return true;
  }

  /// 强制过期会话
  static Future<void> expireSession() async {
    _sessionExpiry = DateTime.now().subtract(const Duration(seconds: 1));
    await logout();
  }

  /// 延长会话
  static Future<bool> extendSession({Duration? extension}) async {
    if (!isLoggedIn || _sessionExpiry == null) return false;
    if (EnvConfig.eatWhatAuthBaseUrl.isNotEmpty) return false;

    final extensionDuration = extension ?? const Duration(hours: 1);
    final newExpiry = _sessionExpiry!.add(extensionDuration);

    // 检查新的过期时间是否合理（不超过7天）
    final maxExpiry = DateTime.now().add(const Duration(days: 7));
    if (newExpiry.isAfter(maxExpiry)) {
      return false;
    }

    _sessionExpiry = newExpiry;
    _lastActivity = DateTime.now();

    return true;
  }

  /// 获取会话信息
  static SessionInfo? getSessionInfo() {
    if (!isLoggedIn || _currentUser == null) return null;

    return SessionInfo(
      userId: _currentUser!.id,
      sessionExpiry: _sessionExpiry,
      lastActivity: _lastActivity,
      isExpired: isSessionExpired,
      timeRemaining: sessionTimeRemaining,
      shouldRefresh: shouldRefreshSession,
    );
  }

  static void _resetSession() {
    _currentUser = null;
    _authToken = null;
    _sessionExpiry = null;
    _lastActivity = null;
  }
}

/// 用户模型
class User {
  final String id;
  final String username;
  final String email;
  final String nickname;
  final String passwordHash;
  final String? avatar;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final DateTime lastLoginAt;
  final UserPreference userPreference;

  /// Membership flag for the eatwhat account. New accounts start with a
  /// trial membership (see [trialMemberDays]); the tier drives the account
  /// sheet and future member perks.
  final bool isMember;
  final DateTime? memberSince;

  /// When the current membership period ends (trial or paid). Null means
  /// the flag carries no expiry — kept for forward compatibility.
  final DateTime? memberExpiresAt;

  /// Trial membership granted at registration, in days.
  static const int trialMemberDays = 7;

  User({
    required this.id,
    required this.username,
    required this.email,
    required this.nickname,
    required this.passwordHash,
    this.avatar,
    required this.createdAt,
    this.updatedAt,
    required this.lastLoginAt,
    required this.userPreference,
    this.isMember = false,
    this.memberSince,
    this.memberExpiresAt,
  });

  User copyWith({
    String? id,
    String? username,
    String? email,
    String? nickname,
    String? passwordHash,
    String? avatar,
    DateTime? createdAt,
    DateTime? updatedAt,
    DateTime? lastLoginAt,
    UserPreference? userPreference,
    bool? isMember,
    DateTime? memberSince,
    DateTime? memberExpiresAt,
  }) {
    return User(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      nickname: nickname ?? this.nickname,
      passwordHash: passwordHash ?? this.passwordHash,
      avatar: avatar ?? this.avatar,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      lastLoginAt: lastLoginAt ?? this.lastLoginAt,
      userPreference: userPreference ?? this.userPreference,
      isMember: isMember ?? this.isMember,
      memberSince: memberSince ?? this.memberSince,
      memberExpiresAt: memberExpiresAt ?? this.memberExpiresAt,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'nickname': nickname,
      'passwordHash': passwordHash,
      'avatar': avatar,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'lastLoginAt': lastLoginAt.toIso8601String(),
      'userPreference': userPreference.toJson(),
      'isMember': isMember,
      'memberSince': memberSince?.toIso8601String(),
      'memberExpiresAt': memberExpiresAt?.toIso8601String(),
    };
  }

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      id: json['id'],
      username: json['username'],
      email: json['email'],
      nickname: json['nickname'],
      passwordHash: json['passwordHash'],
      avatar: json['avatar'],
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt:
          json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
      lastLoginAt: DateTime.parse(json['lastLoginAt']),
      userPreference: UserPreference.fromJson(json['userPreference']),
      // Older stored accounts predate the membership fields.
      isMember: (json['isMember'] as bool?) ?? false,
      memberSince: json['memberSince'] != null
          ? DateTime.parse(json['memberSince'])
          : null,
      memberExpiresAt: json['memberExpiresAt'] != null
          ? DateTime.parse(json['memberExpiresAt'])
          : null,
    );
  }

  /// Whether the membership is currently active — the flag is set and the
  /// period (if any) has not ended yet.
  bool get isMembershipActive {
    if (!isMember) return false;
    final expiresAt = memberExpiresAt;
    if (expiresAt == null) return true;
    return DateTime.now().isBefore(expiresAt);
  }

  /// Whole days left in the membership period (null when there is no
  /// expiry to count down).
  int? get membershipDaysLeft {
    final expiresAt = memberExpiresAt;
    if (expiresAt == null) return null;
    final leftHours = expiresAt.difference(DateTime.now()).inHours;
    if (leftHours <= 0) return 0;
    return (leftHours / 24).ceil();
  }
}

/// 认证结果
class AuthResult {
  final bool success;
  final String message;
  final User? user;

  AuthResult({
    required this.success,
    required this.message,
    this.user,
  });
}

/// 会话信息
class SessionInfo {
  final String userId;
  final DateTime? sessionExpiry;
  final DateTime? lastActivity;
  final bool isExpired;
  final Duration? timeRemaining;
  final bool shouldRefresh;

  SessionInfo({
    required this.userId,
    this.sessionExpiry,
    this.lastActivity,
    required this.isExpired,
    this.timeRemaining,
    required this.shouldRefresh,
  });

  @override
  String toString() {
    return 'SessionInfo(userId: $userId, expired: $isExpired, timeRemaining: $timeRemaining)';
  }
}
