import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_preference.dart';

/// 用户认证服务
/// 处理用户注册、登录、注销等认证相关功能
class AuthService {
  static const String _keyCurrentUser = 'current_user';
  static const String _keyUserToken = 'user_token';
  static const String _keyRememberMe = 'remember_me';
  static const String _keyUsers = 'users_db';

  static User? _currentUser;
  static String? _authToken;
  
  /// 获取当前用户
  static User? get currentUser => _currentUser;
  
  /// 获取认证令牌
  static String? get authToken => _authToken;
  
  /// 检查是否已登录
  static bool get isLoggedIn => _currentUser != null && _authToken != null;

  /// 初始化认证服务
  static Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    
    // 检查记住登录状态
    final rememberMe = prefs.getBool(_keyRememberMe) ?? false;
    if (rememberMe) {
      final userJson = prefs.getString(_keyCurrentUser);
      final token = prefs.getString(_keyUserToken);
      
      if (userJson != null && token != null) {
        try {
          final userMap = json.decode(userJson) as Map<String, dynamic>;
          _currentUser = User.fromJson(userMap);
          _authToken = token;
        } catch (e) {
          // 如果数据损坏，清除存储的登录信息
          await _clearStoredAuth();
        }
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
    try {
      // 验证输入
      final validation = _validateRegistration(username, email, password, confirmPassword);
      if (!validation.success) {
        return validation;
      }

      final prefs = await SharedPreferences.getInstance();
      
      // 检查用户是否已存在
      final existingUser = await _getUserByUsernameOrEmail(username, email);
      if (existingUser != null) {
        return AuthResult(
          success: false,
          message: existingUser.username == username ? '用户名已存在' : '邮箱已被注册',
        );
      }

      // 创建新用户
      final user = User(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        username: username,
        email: email,
        nickname: nickname ?? username,
        passwordHash: _hashPassword(password),
        createdAt: DateTime.now(),
        lastLoginAt: DateTime.now(),
        userPreference: UserPreference(
          userId: DateTime.now().millisecondsSinceEpoch.toString(),
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
    try {
      // 验证输入
      if (usernameOrEmail.trim().isEmpty || password.isEmpty) {
        return AuthResult(
          success: false,
          message: '用户名/邮箱和密码不能为空',
        );
      }

      // 查找用户
      final user = await _getUserByUsernameOrEmail(usernameOrEmail, usernameOrEmail);
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

      // 设置当前用户
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
  static Future<void> logout() async {
    _currentUser = null;
    _authToken = null;
    
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyCurrentUser);
    await prefs.remove(_keyUserToken);
    await prefs.remove(_keyRememberMe);
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

      // 更新存储的用户信息
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_keyCurrentUser, json.encode(updatedUser.toJson()));

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

    if (!RegExp(r'^[a-zA-Z0-9_]+$').hasMatch(username)) {
      return AuthResult(success: false, message: '用户名只能包含字母、数字和下划线');
    }

    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      return AuthResult(success: false, message: '邮箱格式不正确');
    }

    if (password.length < 6) {
      return AuthResult(success: false, message: '密码长度至少6位');
    }

    if (password != confirmPassword) {
      return AuthResult(success: false, message: '两次输入的密码不一致');
    }

    return AuthResult(success: true, message: '验证通过');
  }

  /// 密码哈希
  static String _hashPassword(String password) {
    final bytes = utf8.encode(password + 'eatwhat_salt'); // 添加盐值
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// 验证密码
  static bool _verifyPassword(String password, String hash) {
    return _hashPassword(password) == hash;
  }

  /// 生成认证令牌
  static String _generateToken(String userId) {
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString();
    final bytes = utf8.encode('$userId:$timestamp:eatwhat_secret');
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// 设置当前用户
  static Future<void> _setCurrentUser(User user, {bool rememberMe = false}) async {
    _currentUser = user;
    _authToken = _generateToken(user.id);

    final prefs = await SharedPreferences.getInstance();
    
    if (rememberMe) {
      await prefs.setString(_keyCurrentUser, json.encode(user.toJson()));
      await prefs.setString(_keyUserToken, _authToken!);
      await prefs.setBool(_keyRememberMe, true);
    }
  }

  /// 清除存储的认证信息
  static Future<void> _clearStoredAuth() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyCurrentUser);
    await prefs.remove(_keyUserToken);
    await prefs.remove(_keyRememberMe);
  }

  /// 获取用户通过用户名或邮箱
  static Future<User?> _getUserByUsernameOrEmail(String username, String email) async {
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
      updatedAt: json['updatedAt'] != null ? DateTime.parse(json['updatedAt']) : null,
      lastLoginAt: DateTime.parse(json['lastLoginAt']),
      userPreference: UserPreference.fromJson(json['userPreference']),
    );
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