import 'dart:convert';
import 'dart:math' as math;
import 'package:crypto/crypto.dart';
import '../config/env_config.dart';

/// API请求签名服务
/// 为API请求提供签名验证，防止请求篡改和重放攻击
class ApiSignatureService {
  static const String _signatureHeader = 'X-EatWhat-Signature';
  static const String _timestampHeader = 'X-EatWhat-Timestamp';
  static const String _nonceHeader = 'X-EatWhat-Nonce';
  static const String _versionHeader = 'X-EatWhat-Version';
  static const String _apiVersion = '1.0';
  static const int _maxTimestampDrift = 300; // 5分钟时间漂移容忍度

  /// 为API请求生成签名
  static SignedRequest signRequest({
    required String method,
    required String url,
    Map<String, String>? headers,
    String? body,
  }) {
    final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final nonce = _generateNonce();

    // 构建签名字符串
    final signatureString = _buildSignatureString(
      method: method.toUpperCase(),
      url: url,
      headers: headers ?? {},
      body: body ?? '',
      timestamp: timestamp,
      nonce: nonce,
    );

    // 生成签名
    final signature = _generateSignature(signatureString);

    // 构建最终的请求头
    final finalHeaders = Map<String, String>.from(headers ?? {});
    finalHeaders[_signatureHeader] = signature;
    finalHeaders[_timestampHeader] = timestamp.toString();
    finalHeaders[_nonceHeader] = nonce;
    finalHeaders[_versionHeader] = _apiVersion;

    return SignedRequest(
      method: method,
      url: url,
      headers: finalHeaders,
      body: body,
      signature: signature,
      timestamp: timestamp,
      nonce: nonce,
    );
  }

  /// 验证API请求签名
  static SignatureValidationResult validateRequest({
    required String method,
    required String url,
    required Map<String, String> headers,
    String? body,
  }) {
    try {
      // 提取签名相关的头部信息
      final signature = headers[_signatureHeader];
      final timestampStr = headers[_timestampHeader];
      final nonce = headers[_nonceHeader];
      final version = headers[_versionHeader];

      if (signature == null || timestampStr == null || nonce == null) {
        return SignatureValidationResult(
          isValid: false,
          error: 'Missing required signature headers',
        );
      }

      // 验证版本
      if (version != _apiVersion) {
        return SignatureValidationResult(
          isValid: false,
          error: 'Unsupported API version',
        );
      }

      // 验证时间戳
      final timestamp = int.tryParse(timestampStr);
      if (timestamp == null) {
        return SignatureValidationResult(
          isValid: false,
          error: 'Invalid timestamp format',
        );
      }

      final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
      if ((now - timestamp).abs() > _maxTimestampDrift) {
        return SignatureValidationResult(
          isValid: false,
          error: 'Timestamp out of acceptable range',
        );
      }

      // 构建签名字符串
      final signatureString = _buildSignatureString(
        method: method.toUpperCase(),
        url: url,
        headers: headers,
        body: body ?? '',
        timestamp: timestamp,
        nonce: nonce,
      );

      // 验证签名
      final expectedSignature = _generateSignature(signatureString);
      if (!_constantTimeEquals(signature, expectedSignature)) {
        return SignatureValidationResult(
          isValid: false,
          error: 'Invalid signature',
        );
      }

      return SignatureValidationResult(
        isValid: true,
        timestamp: timestamp,
        nonce: nonce,
      );
    } catch (e) {
      return SignatureValidationResult(
        isValid: false,
        error: 'Signature validation failed: $e',
      );
    }
  }

  /// 构建签名字符串
  static String _buildSignatureString({
    required String method,
    required String url,
    required Map<String, String> headers,
    required String body,
    required int timestamp,
    required String nonce,
  }) {
    // 解析URL组件
    final uri = Uri.parse(url);
    final path = uri.path;
    final query = uri.query;

    // 规范化查询参数
    final normalizedQuery = _normalizeQueryString(query);

    // 规范化头部（排除签名相关的头部）
    final normalizedHeaders = _normalizeHeaders(headers);

    // 构建签名字符串
    final parts = [
      method,
      path,
      normalizedQuery,
      normalizedHeaders,
      _hashBody(body),
      timestamp.toString(),
      nonce,
      _apiVersion,
    ];

    return parts.join('\n');
  }

  /// 规范化查询字符串
  static String _normalizeQueryString(String query) {
    if (query.isEmpty) return '';

    final params = <String>[];
    final pairs = query.split('&');

    for (final pair in pairs) {
      if (pair.isNotEmpty) {
        params.add(pair);
      }
    }

    params.sort();
    return params.join('&');
  }

  /// 规范化头部
  static String _normalizeHeaders(Map<String, String> headers) {
    final normalizedHeaders = <String>[];

    // 排除签名相关的头部
    final filteredHeaders = Map<String, String>.from(headers);
    filteredHeaders.remove(_signatureHeader);
    filteredHeaders.remove(_timestampHeader);
    filteredHeaders.remove(_nonceHeader);
    filteredHeaders.remove(_versionHeader);

    // 转换为小写并排序
    final sortedKeys = filteredHeaders.keys.map((key) => key.toLowerCase()).toList()..sort();

    for (final key in sortedKeys) {
      final originalKey = headers.keys.firstWhere(
        (k) => k.toLowerCase() == key,
        orElse: () => key,
      );
      final value = headers[originalKey]?.trim() ?? '';
      if (value.isNotEmpty) {
        normalizedHeaders.add('$key:$value');
      }
    }

    return normalizedHeaders.join('\n');
  }

  /// 计算请求体哈希
  static String _hashBody(String body) {
    if (body.isEmpty) return '';

    final bytes = utf8.encode(body);
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  /// 生成签名
  static String _generateSignature(String signatureString) {
    final key = utf8.encode('${EnvConfig.jwtSecret}_api_signature');
    final hmac = Hmac(sha256, key);
    final digest = hmac.convert(utf8.encode(signatureString));
    return base64.encode(digest.bytes);
  }

  /// 生成随机数
  static String _generateNonce() {
    final random = math.Random.secure();
    final bytes = List<int>.generate(16, (_) => random.nextInt(256));
    return base64.encode(bytes);
  }

  /// 常量时间字符串比较
  static bool _constantTimeEquals(String a, String b) {
    if (a.length != b.length) return false;

    int result = 0;
    for (int i = 0; i < a.length; i++) {
      result |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return result == 0;
  }

  /// 生成API密钥对
  static ApiKeyPair generateApiKeyPair() {
    final random = math.Random.secure();

    // 生成公钥（API Key ID）
    final keyId = _generateRandomString(32);

    // 生成私钥（API Secret）
    final secret = _generateRandomString(64);

    return ApiKeyPair(keyId: keyId, secret: secret);
  }

  /// 生成随机字符串
  static String _generateRandomString(int length) {
    const charset = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789';
    final random = math.Random.secure();

    return String.fromCharCodes(
      Iterable.generate(length, (_) => charset.codeUnitAt(random.nextInt(charset.length))),
    );
  }

  /// 验证API密钥
  static bool validateApiKey(String keyId, String secret) {
    // 这里应该与服务器端存储的密钥进行比较
    // 为了演示，我们使用简单的验证逻辑
    return keyId.isNotEmpty && secret.isNotEmpty && keyId.length >= 16 && secret.length >= 32;
  }

  /// 创建带签名的HTTP头部
  static Map<String, String> createSignedHeaders({
    required String method,
    required String url,
    Map<String, String>? additionalHeaders,
    String? body,
  }) {
    final signedRequest = signRequest(
      method: method,
      url: url,
      headers: additionalHeaders,
      body: body,
    );

    return signedRequest.headers;
  }
}

/// 签名的请求
class SignedRequest {
  final String method;
  final String url;
  final Map<String, String> headers;
  final String? body;
  final String signature;
  final int timestamp;
  final String nonce;

  SignedRequest({
    required this.method,
    required this.url,
    required this.headers,
    this.body,
    required this.signature,
    required this.timestamp,
    required this.nonce,
  });

  @override
  String toString() {
    return 'SignedRequest(method: $method, url: $url, signature: $signature)';
  }
}

/// 签名验证结果
class SignatureValidationResult {
  final bool isValid;
  final String? error;
  final int? timestamp;
  final String? nonce;

  SignatureValidationResult({
    required this.isValid,
    this.error,
    this.timestamp,
    this.nonce,
  });
}

/// API密钥对
class ApiKeyPair {
  final String keyId;
  final String secret;

  ApiKeyPair({required this.keyId, required this.secret});

  @override
  String toString() {
    return 'ApiKeyPair(keyId: $keyId, secret: [HIDDEN])';
  }
}
