import 'dart:convert';
import 'dart:math' as math;
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';
import '../config/env_config.dart';
import 'secure_storage_service.dart';

/// JWT令牌服务
/// 处理用户认证令牌的生成、验证和管理
class TokenService {
  static const String _tokenKey = 'auth_token';
  static const String _refreshTokenKey = 'refresh_token';
  static const int _tokenExpiryHours = 24; // Token有效期24小时
  static const int _refreshTokenExpiryDays = 30; // 刷新Token有效期30天
  
  /// 生成JWT令牌
  static Future<TokenPair> generateTokenPair(String userId) async {
    final now = DateTime.now();
    final tokenExpiry = now.add(Duration(hours: _tokenExpiryHours));
    final refreshTokenExpiry = now.add(Duration(days: _refreshTokenExpiryDays));
    
    // 生成访问令牌
    final accessToken = _generateToken(userId, tokenExpiry);
    
    // 生成刷新令牌
    final refreshToken = _generateToken(userId, refreshTokenExpiry, isRefreshToken: true);
    
    // 安全存储令牌
    await SecureStorageService.setSecureString(_tokenKey, accessToken);
    await SecureStorageService.setSecureString(_refreshTokenKey, refreshToken);
    
    return TokenPair(
      accessToken: accessToken,
      refreshToken: refreshToken,
      expiresAt: tokenExpiry,
      refreshExpiresAt: refreshTokenExpiry,
    );
  }
  
  /// 验证令牌
  static TokenValidationResult validateToken(String token) {
    try {
      final parts = token.split('.');
      if (parts.length != 3) {
        return TokenValidationResult(isValid: false, error: 'Invalid token format');
      }
      
      // 验证签名
      final header = parts[0];
      final payload = parts[1];
      final signature = parts[2];
      
      final expectedSignature = _generateSignature('$header.$payload');
      if (signature != expectedSignature) {
        return TokenValidationResult(isValid: false, error: 'Invalid signature');
      }
      
      // 解析载荷
      final payloadJson = _base64UrlDecode(payload);
      final payloadMap = json.decode(payloadJson) as Map<String, dynamic>;
      
      // 检查过期时间
      final exp = payloadMap['exp'] as int;
      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      
      if (exp < now) {
        return TokenValidationResult(isValid: false, error: 'Token expired');
      }
      
      return TokenValidationResult(
        isValid: true,
        userId: payloadMap['sub'] as String,
        expiresAt: DateTime.fromMillisecondsSinceEpoch(exp * 1000),
      );
    } catch (e) {
      return TokenValidationResult(isValid: false, error: 'Token validation failed: $e');
    }
  }
  
  /// 刷新令牌
  static Future<TokenPair?> refreshToken() async {
    try {
      final refreshToken = await SecureStorageService.getSecureString(_refreshTokenKey);
      if (refreshToken == null) return null;
      
      final validation = validateToken(refreshToken);
      if (!validation.isValid || validation.userId == null) return null;
      
      // 生成新的令牌对
      return await generateTokenPair(validation.userId!);
    } catch (e) {
      debugPrint('Token refresh failed: $e');
      return null;
    }
  }
  
  /// 获取当前存储的令牌
  static Future<String?> getCurrentToken() async {
    return await SecureStorageService.getSecureString(_tokenKey);
  }
  
  /// 清除所有令牌
  static Future<void> clearTokens() async {
    await SecureStorageService.removeSecureString(_tokenKey);
    await SecureStorageService.removeSecureString(_refreshTokenKey);
  }
  
  /// 检查令牌是否即将过期
  static Future<bool> isTokenExpiringSoon({int warningMinutes = 30}) async {
    final token = await getCurrentToken();
    if (token == null) return true;
    
    final validation = validateToken(token);
    if (!validation.isValid || validation.expiresAt == null) return true;
    
    final now = DateTime.now();
    final warningTime = validation.expiresAt!.subtract(Duration(minutes: warningMinutes));
    
    return now.isAfter(warningTime);
  }
  
  /// 生成JWT令牌
  static String _generateToken(String userId, DateTime expiry, {bool isRefreshToken = false}) {
    // JWT Header
    final header = {
      'alg': 'HS256',
      'typ': 'JWT',
    };
    
    // JWT Payload
    final payload = {
      'sub': userId, // Subject (用户ID)
      'iat': DateTime.now().millisecondsSinceEpoch ~/ 1000, // Issued at
      'exp': expiry.millisecondsSinceEpoch ~/ 1000, // Expiration
      'jti': _generateJti(), // JWT ID
      'type': isRefreshToken ? 'refresh' : 'access',
    };
    
    final encodedHeader = _base64UrlEncode(json.encode(header));
    final encodedPayload = _base64UrlEncode(json.encode(payload));
    final signature = _generateSignature('$encodedHeader.$encodedPayload');
    
    return '$encodedHeader.$encodedPayload.$signature';
  }
  
  /// 生成签名
  static String _generateSignature(String data) {
    final key = utf8.encode(EnvConfig.jwtSecret);
    final hmac = Hmac(sha256, key);
    final digest = hmac.convert(utf8.encode(data));
    return _base64UrlEncode(digest.bytes);
  }
  
  /// 生成JWT ID
  static String _generateJti() {
    final random = math.Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    return base64Url.encode(bytes);
  }
  
  /// Base64 URL编码
  static String _base64UrlEncode(dynamic data) {
    String encoded;
    if (data is String) {
      encoded = base64Url.encode(utf8.encode(data));
    } else if (data is List<int>) {
      encoded = base64Url.encode(data);
    } else {
      throw ArgumentError('Unsupported data type for base64 encoding');
    }
    
    // 移除填充字符
    return encoded.replaceAll('=', '');
  }
  
  /// Base64 URL解码
  static String _base64UrlDecode(String data) {
    // 添加填充字符
    switch (data.length % 4) {
      case 2:
        data += '==';
        break;
      case 3:
        data += '=';
        break;
    }
    
    final bytes = base64Url.decode(data);
    return utf8.decode(bytes);
  }
  
  /// 获取令牌信息
  static Future<TokenInfo?> getTokenInfo() async {
    final token = await getCurrentToken();
    if (token == null) return null;
    
    final validation = validateToken(token);
    if (!validation.isValid) return null;
    
    return TokenInfo(
      userId: validation.userId!,
      isValid: true,
      expiresAt: validation.expiresAt!,
      isExpiringSoon: await isTokenExpiringSoon(),
    );
  }
}

/// 令牌对
class TokenPair {
  final String accessToken;
  final String refreshToken;
  final DateTime expiresAt;
  final DateTime refreshExpiresAt;
  
  TokenPair({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAt,
    required this.refreshExpiresAt,
  });
}

/// 令牌验证结果
class TokenValidationResult {
  final bool isValid;
  final String? userId;
  final DateTime? expiresAt;
  final String? error;
  
  TokenValidationResult({
    required this.isValid,
    this.userId,
    this.expiresAt,
    this.error,
  });
}

/// 令牌信息
class TokenInfo {
  final String userId;
  final bool isValid;
  final DateTime expiresAt;
  final bool isExpiringSoon;
  
  TokenInfo({
    required this.userId,
    required this.isValid,
    required this.expiresAt,
    required this.isExpiringSoon,
  });
}