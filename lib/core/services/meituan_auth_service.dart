import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:eatwhat_app/core/services/chrome_cdp_service.dart';

/// 美团开放平台认证信息
class MeituanAuthTokens {
  final String? accessToken;
  final String? refreshToken;
  final String? tokenType;
  final DateTime? expiresAt;
  final List<Map<String, dynamic>> cookies;
  final Map<String, String> headers;

  MeituanAuthTokens({
    this.accessToken,
    this.refreshToken,
    this.tokenType,
    this.expiresAt,
    this.cookies = const [],
    this.headers = const {},
  });

  bool get isValid {
    if (accessToken == null || accessToken!.isEmpty) return false;
    if (expiresAt != null && DateTime.now().isAfter(expiresAt!)) return false;
    return true;
  }

  Map<String, dynamic> toJson() => {
        'accessToken': accessToken,
        'refreshToken': refreshToken,
        'tokenType': tokenType,
        'expiresAt': expiresAt?.toIso8601String(),
        'cookies': cookies,
        'headers': headers,
      };

  factory MeituanAuthTokens.fromJson(Map<String, dynamic> json) {
    return MeituanAuthTokens(
      accessToken: json['accessToken'] as String?,
      refreshToken: json['refreshToken'] as String?,
      tokenType: json['tokenType'] as String?,
      expiresAt: json['expiresAt'] != null
          ? DateTime.parse(json['expiresAt'] as String)
          : null,
      cookies: (json['cookies'] as List<dynamic>?)
              ?.cast<Map<String, dynamic>>() ??
          [],
      headers: (json['headers'] as Map<String, dynamic>?)
              ?.cast<String, String>() ??
          {},
    );
  }
}

/// 美团开放平台认证服务
///
/// 通过Chrome CDP自动化登录美团开放平台，获取Access Token和Cookie
class MeituanAuthService {
  MeituanAuthService({ChromeCdpService? cdpService})
      : _cdp = cdpService ?? ChromeCdpService();

  final ChromeCdpService _cdp;
  final _secureStorage = const FlutterSecureStorage();

  static const _storageKey = 'meituan_auth_tokens';
  static const _loginUrl = 'https://open.meituan.com/user/login';

  MeituanAuthTokens? _cachedTokens;

  /// 当前认证状态
  MeituanAuthTokens? get currentTokens => _cachedTokens;

  /// 是否已登录
  bool get isLoggedIn => _cachedTokens?.isValid ?? false;

  /// 从存储加载已保存的认证信息
  Future<void> loadSavedTokens() async {
    try {
      final json = await _secureStorage.read(key: _storageKey);
      if (json != null) {
        final tokens = MeituanAuthTokens.fromJson(
          Map<String, dynamic>.from(
            Uri.splitQueryString(json).map(
              (k, v) => MapEntry(k, v),
            ),
          ),
        );
        if (tokens.isValid) {
          _cachedTokens = tokens;
          debugPrint('[MeituanAuth] 已加载保存的认证信息');
        }
      }
    } catch (e) {
      debugPrint('[MeituanAuth] 加载认证信息失败: $e');
    }
  }

  /// 保存认证信息到安全存储
  Future<void> _saveTokens(MeituanAuthTokens tokens) async {
    try {
      final json = tokens.toJson().entries
          .map((e) => '${e.key}=${e.value}')
          .join('&');
      await _secureStorage.write(key: _storageKey, value: json);
      _cachedTokens = tokens;
      debugPrint('[MeituanAuth] 认证信息已保存');
    } catch (e) {
      debugPrint('[MeituanAuth] 保存认证信息失败: $e');
    }
  }

  /// 清除认证信息
  Future<void> clearTokens() async {
    try {
      await _secureStorage.delete(key: _storageKey);
      _cachedTokens = null;
      debugPrint('[MeituanAuth] 认证信息已清除');
    } catch (e) {
      debugPrint('[MeituanAuth] 清除认证信息失败: $e');
    }
  }

  /// 检查是否有可用的标签页
  Future<ChromeTab?> _findOrCreateMeituanTab() async {
    final tabs = await _cdp.listTabs();

    // 查找是否已有美团开放平台标签页
    for (final tab in tabs) {
      if (tab.url.contains('meituan.com') ||
          tab.title.contains('美团')) {
        debugPrint('[MeituanAuth] 找到美团标签页: ${tab.title}');
        return tab;
      }
    }

    // 创建新标签页
    debugPrint('[MeituanAuth] 创建新标签页');
    return await _cdp.newTab(_loginUrl);
  }

  /// 通过Chrome CDP自动化登录美团
  ///
  /// 返回登录后的认证信息
  Future<MeituanAuthTokens> loginWithCdp({
    required String username,
    required String password,
  }) async {
    debugPrint('[MeituanAuth] 开始CDP自动化登录美团...');

    try {
      // 1. 找到或创建美团标签页
      final tab = await _findOrCreateMeituanTab();
      if (tab == null) {
        throw Exception('无法打开美团开放平台');
      }

      // 2. 连接到标签页
      await _cdp.connectToTab(tab);
      debugPrint('[MeituanAuth] 已连接到标签页');

      // 3. 等待页面加载
      await _cdp.waitForLoad(15);
      debugPrint('[MeituanAuth] 页面已加载');

      // 4. 检查是否已登录
      final isAlreadyLoggedIn = await _checkLoginStatus();
      if (isAlreadyLoggedIn) {
        debugPrint('[MeituanAuth] 已处于登录状态');
        return await _extractAuthInfo();
      }

      // 5. 填写登录表单
      // 美团开放平台的登录表单通常使用以下选择器
      await _fillLoginForm(username, password);

      // 6. 提交登录
      await _submitLogin();

      // 7. 等待登录完成
      await _waitForLoginComplete();

      // 8. 提取认证信息
      final tokens = await _extractAuthInfo();
      await _saveTokens(tokens);

      return tokens;
    } catch (e) {
      debugPrint('[MeituanAuth] 登录失败: $e');
      rethrow;
    } finally {
      _cdp.disconnect();
    }
  }

  /// 检查当前页面登录状态
  Future<bool> _checkLoginStatus() async {
    try {
      // 检查是否存在用户头像或用户名元素（已登录状态）
      final result = await _cdp.evaluate('''
        (function() {
          // 检查登录状态元素
          const loggedInIndicators = [
            document.querySelector('.user-info'),
            document.querySelector('.avatar'),
            document.querySelector('[class*="user"]'),
            document.querySelector('[class*="avatar"]'),
          ];
          return loggedInIndicators.some(el => el !== null);
        })();
      ''');
      return result == true;
    } catch (e) {
      debugPrint('[MeituanAuth] 检查登录状态失败: $e');
      return false;
    }
  }

  /// 填写登录表单
  Future<void> _fillLoginForm(String username, String password) async {
    debugPrint('[MeituanAuth] 填写登录表单...');

    // 常见的用户名输入框选择器
    final usernameSelectors = [
      'input[name="username"]',
      'input[name="phone"]',
      'input[name="email"]',
      'input[type="text"]',
      'input[id*="username"]',
      'input[placeholder*="账号"]',
      'input[placeholder*="手机"]',
      '#username',
      '#phone',
    ];

    // 常见的密码输入框选择器
    final passwordSelectors = [
      'input[name="password"]',
      'input[type="password"]',
      'input[id*="password"]',
      '#password',
    ];

    // 填写用户名
    for (final selector in usernameSelectors) {
      try {
        final exists = await _cdp.evaluate(
          'document.querySelector("$selector") !== null',
        );
        if (exists == true) {
          await _cdp.fillInput(selector, username);
          debugPrint('[MeituanAuth] 用户名已填写: $selector');
          break;
        }
      } catch (_) {
        continue;
      }
    }

    // 填写密码
    for (final selector in passwordSelectors) {
      try {
        final exists = await _cdp.evaluate(
          'document.querySelector("$selector") !== null',
        );
        if (exists == true) {
          await _cdp.fillInput(selector, password);
          debugPrint('[MeituanAuth] 密码已填写: $selector');
          break;
        }
      } catch (_) {
        continue;
      }
    }

    // 等待一下让输入生效
    await Future.delayed(const Duration(milliseconds: 300));
  }

  /// 提交登录表单
  Future<void> _submitLogin() async {
    debugPrint('[MeituanAuth] 提交登录...');

    // 常见的登录按钮选择器
    final submitSelectors = [
      'button[type="submit"]',
      'button:contains("登录")',
      'button:contains("登 录")',
      'button[class*="login"]',
      'button[id*="login"]',
      '.login-btn',
      '#loginBtn',
      '[class*="login-button"]',
    ];

    for (final selector in submitSelectors) {
      try {
        final exists = await _cdp.evaluate(
          selector.contains('button:contains')
              ? 'document.querySelectorAll("button").some(b => b.textContent.includes("登录"))'
              : 'document.querySelector("$selector") !== null',
        );
        if (exists == true) {
          if (selector.contains('button:contains')) {
            await _cdp.evaluate(
              'document.querySelectorAll("button").find(b => b.textContent.includes("登录"))?.click()',
            );
          } else {
            await _cdp.clickElement(selector);
          }
          debugPrint('[MeituanAuth] 点击登录按钮: $selector');
          break;
        }
      } catch (_) {
        continue;
      }
    }
  }

  /// 等待登录完成
  Future<void> _waitForLoginComplete() async {
    debugPrint('[MeituanAuth] 等待登录完成...');

    final maxWaitSeconds = 30;
    final startTime = DateTime.now();

    while (DateTime.now().difference(startTime).inSeconds < maxWaitSeconds) {
      // 检查是否跳转到dashboard或用户页面
      final currentUrl = await _cdp.evaluate('window.location.href');
      if (currentUrl.toString().contains('/user') ||
          currentUrl.toString().contains('/dashboard') ||
          currentUrl.toString().contains('/home')) {
        debugPrint('[MeituanAuth] 登录成功，当前URL: $currentUrl');
        return;
      }

      // 检查是否有错误提示
      final errorText = await _getLoginError();
      if (errorText != null && errorText.isNotEmpty) {
        debugPrint('[MeituanAuth] 登录错误: $errorText');
        throw Exception('登录失败: $errorText');
      }

      await Future.delayed(const Duration(seconds: 1));
    }

    throw Exception('登录超时');
  }

  /// 获取登录错误信息
  Future<String?> _getLoginError() async {
    try {
      return await _cdp.evaluate('''
        (function() {
          const errorSelectors = [
            '.error',
            '.error-msg',
            '.login-error',
            '[class*="error"]',
            '[class*="warning"]',
          ];
          for (const selector of errorSelectors) {
            const el = document.querySelector(selector);
            if (el && el.offsetParent !== null) {
              return el.innerText?.trim();
            }
          }
          return null;
        })();
      ''');
    } catch (_) {
      return null;
    }
  }

  /// 从页面提取认证信息
  Future<MeituanAuthTokens> _extractAuthInfo() async {
    debugPrint('[MeituanAuth] 提取认证信息...');

    // 获取所有Cookie
    final cookies = await _cdp.getCookies();

    // 获取localStorage中的token
    final localStorage = await _extractLocalStorage();

    // 尝试从页面获取token
    final accessToken = await _extractAccessToken(localStorage);

    // 提取User-Agent等Headers
    final headers = await _extractHeaders();

    return MeituanAuthTokens(
      accessToken: accessToken,
      refreshToken: localStorage['refreshToken'],
      tokenType: 'Bearer',
      expiresAt: DateTime.now().add(const Duration(days: 30)),
      cookies: cookies,
      headers: headers,
    );
  }

  /// 提取localStorage内容
  Future<Map<String, String>> _extractLocalStorage() async {
    try {
      final result = await _cdp.evaluate('''
        (function() {
          const data = {};
          for (let i = 0; i < localStorage.length; i++) {
            const key = localStorage.key(i);
            data[key] = localStorage.getItem(key);
          }
          return data;
        })();
      ''');

      if (result is Map) {
        return result.map((k, v) => MapEntry(k.toString(), v.toString()));
      }
    } catch (e) {
      debugPrint('[MeituanAuth] 提取localStorage失败: $e');
    }
    return {};
  }

  /// 提取Access Token
  Future<String?> _extractAccessToken(Map<String, String> localStorage) async {
    // 优先从localStorage获取
    if (localStorage.containsKey('accessToken')) {
      return localStorage['accessToken'];
    }
    if (localStorage.containsKey('token')) {
      return localStorage['token'];
    }
    if (localStorage.containsKey('access_token')) {
      return localStorage['access_token'];
    }

    // 尝试从Cookie获取
    try {
      final cookies = await _cdp.getCookies();
      for (final cookie in cookies) {
        final name = cookie['name']?.toString() ?? '';
        if (name.contains('token') || name.contains('Token')) {
          return cookie['value']?.toString();
        }
      }
    } catch (_) {}

    return null;
  }

  /// 提取Headers
  Future<Map<String, String>> _extractHeaders() async {
    final headers = <String, String>{
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };

    try {
      // 从Cookie中提取必要信息
      final cookies = await _cdp.getCookies();
      if (cookies.isNotEmpty) {
        headers['Cookie'] = cookies
            .map((c) => '${c['name']}=${c['value']}')
            .join('; ');
      }
    } catch (_) {}

    return headers;
  }

  /// 刷新Token
  Future<MeituanAuthTokens?> refreshTokens() async {
    if (_cachedTokens?.refreshToken == null) {
      return null;
    }

    debugPrint('[MeituanAuth] 刷新Token...');
    // TODO: 实现Token刷新逻辑
    return null;
  }

  /// 验证当前Token是否有效
  Future<bool> validateToken() async {
    if (_cachedTokens?.accessToken == null) {
      return false;
    }

    try {
      // 尝试用当前token访问API
      // 这里可以调用美团API验证token有效性
      return true;
    } catch (e) {
      debugPrint('[MeituanAuth] Token验证失败: $e');
      return false;
    }
  }

  /// 获取认证Header（用于API请求）
  Map<String, String> getAuthHeaders() {
    if (_cachedTokens == null || !_cachedTokens!.isValid) {
      return {};
    }

    return {
      ..._cachedTokens!.headers,
      if (_cachedTokens!.accessToken != null)
        'Authorization': 'Bearer ${_cachedTokens!.accessToken}',
    };
  }

  /// 释放资源
  void dispose() {
    _cdp.dispose();
  }
}
