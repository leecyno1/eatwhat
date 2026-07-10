import 'dart:convert';
import 'package:flutter/foundation.dart';

/// 日志脱敏工具类
/// 在记录日志时自动移除或掩盖敏感信息
class LogSanitizer {
  // 敏感字段关键词
  static const List<String> _sensitiveKeywords = [
    'password',
    'passwd',
    'pwd',
    'secret',
    'token',
    'key',
    'api_key',
    'apikey',
    'auth',
    'authorization',
    'bearer',
    'session',
    'cookie',
    'csrf',
    'credit_card',
    'creditcard',
    'card_number',
    'cardnumber',
    'cvv',
    'ssn',
    'social_security',
    'phone',
    'mobile',
    'email',
    'address',
    'location',
    'signature',
    'hash',
    'salt',
    'nonce',
    'private',
    'confidential',
    'personal',
    'pii',
    'sensitive',
    'encrypted',
    'decrypt'
  ];

  // URL中敏感的查询参数
  static const List<String> _sensitiveUrlParams = [
    'token',
    'api_key',
    'apikey',
    'auth',
    'password',
    'secret',
    'session',
    'access_token',
    'refresh_token',
    'bearer',
    'key',
    'signature'
  ];

  // 敏感的HTTP头部
  static const List<String> _sensitiveHeaders = [
    'authorization',
    'cookie',
    'set-cookie',
    'x-api-key',
    'x-auth-token',
    'x-access-token',
    'x-csrf-token',
    'x-session-id',
    'authentication',
    'proxy-authorization',
    'www-authenticate'
  ];

  /// 脱敏字符串
  static String sanitizeString(String input) {
    if (input.isEmpty) return input;

    // 检查是否为JSON格式
    if (_isJson(input)) {
      return _sanitizeJson(input);
    }

    // 检查是否为URL格式
    if (_isUrl(input)) {
      return _sanitizeUrl(input);
    }

    // 一般字符串处理
    return _sanitizeGeneralString(input);
  }

  /// 脱敏JSON字符串
  static String _sanitizeJson(String jsonString) {
    try {
      final decoded = json.decode(jsonString);
      final sanitized = _sanitizeObject(decoded);
      return json.encode(sanitized);
    } catch (e) {
      // 如果解析失败，按一般字符串处理
      return _sanitizeGeneralString(jsonString);
    }
  }

  /// 脱敏对象
  static dynamic _sanitizeObject(dynamic obj) {
    if (obj is Map<String, dynamic>) {
      final sanitized = <String, dynamic>{};
      obj.forEach((key, value) {
        final sanitizedKey = key.toLowerCase();
        if (_isSensitiveKey(sanitizedKey)) {
          sanitized[key] = _maskValue(value);
        } else {
          sanitized[key] = _sanitizeObject(value);
        }
      });
      return sanitized;
    } else if (obj is List) {
      return obj.map((item) => _sanitizeObject(item)).toList();
    } else {
      return obj;
    }
  }

  /// 脱敏URL
  static String _sanitizeUrl(String url) {
    try {
      final uri = Uri.parse(url);
      final sanitizedParams = <String, String>{};

      uri.queryParameters.forEach((key, value) {
        if (_isSensitiveUrlParam(key.toLowerCase())) {
          sanitizedParams[key] = _maskValue(value);
        } else {
          sanitizedParams[key] = value;
        }
      });

      return uri.replace(queryParameters: sanitizedParams).toString();
    } catch (e) {
      // 如果URL解析失败，返回掩码版本
      return _maskLongString(url);
    }
  }

  /// 脱敏HTTP头部
  static Map<String, String> sanitizeHeaders(Map<String, String> headers) {
    final sanitized = <String, String>{};

    headers.forEach((key, value) {
      if (_isSensitiveHeader(key.toLowerCase())) {
        sanitized[key] = _maskValue(value);
      } else {
        sanitized[key] = value;
      }
    });

    return sanitized;
  }

  /// 脱敏一般字符串
  static String _sanitizeGeneralString(String input) {
    String result = input;

    // 查找并替换可能的敏感信息模式

    // Email模式
    result = result.replaceAll(
        RegExp(r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b'), '***@***.***');

    // 手机号模式（中国）
    result = result.replaceAll(RegExp(r'\b1[3-9]\d{9}\b'), '***-****-****');

    // 信用卡号模式
    result = result.replaceAll(
        RegExp(r'\b\d{4}[\s-]?\d{4}[\s-]?\d{4}[\s-]?\d{4}\b'), '****-****-****-****');

    // API密钥模式（以sk-、pk-等开头的长字符串）
    result =
        result.replaceAll(RegExp(r'\b(sk|pk|rk|ak)[-_][a-zA-Z0-9]{20,}\b'), r'$1-***[REDACTED]***');

    // JWT令牌模式
    result = result.replaceAll(RegExp(r'\beyJ[a-zA-Z0-9_-]*\.[a-zA-Z0-9_-]*\.[a-zA-Z0-9_-]*\b'),
        'eyJ***[JWT_REDACTED]***');

    // 长的Base64字符串
    result = result.replaceAll(RegExp(r'\b[A-Za-z0-9+/]{40,}={0,2}\b'), '[BASE64_REDACTED]');

    return result;
  }

  /// 检查是否为敏感字段
  static bool _isSensitiveKey(String key) {
    return _sensitiveKeywords.any((keyword) => key.contains(keyword));
  }

  /// 检查是否为敏感URL参数
  static bool _isSensitiveUrlParam(String param) {
    return _sensitiveUrlParams.any((sensitive) => param.contains(sensitive));
  }

  /// 检查是否为敏感HTTP头部
  static bool _isSensitiveHeader(String header) {
    return _sensitiveHeaders.any((sensitive) => header.contains(sensitive));
  }

  /// 掩盖值
  static String _maskValue(dynamic value) {
    if (value == null) return 'null';

    final str = value.toString();
    if (str.isEmpty) return '';

    if (str.length <= 4) {
      return '***';
    } else if (str.length <= 8) {
      return '${str.substring(0, 2)}***';
    } else {
      return '${str.substring(0, 3)}***${str.substring(str.length - 2)}';
    }
  }

  /// 掩盖长字符串
  static String _maskLongString(String str) {
    if (str.length <= 20) {
      return _maskValue(str);
    }
    return '${str.substring(0, 10)}***[REDACTED]***${str.substring(str.length - 10)}';
  }

  /// 检查是否为JSON格式
  static bool _isJson(String str) {
    try {
      json.decode(str);
      return true;
    } catch (e) {
      return false;
    }
  }

  /// 检查是否为URL格式
  static bool _isUrl(String str) {
    try {
      final uri = Uri.parse(str);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }

  /// 脱敏异常信息
  static String sanitizeException(Exception exception) {
    final message = exception.toString();
    return sanitizeString(message);
  }

  /// 脱敏堆栈跟踪
  static String sanitizeStackTrace(StackTrace stackTrace) {
    final trace = stackTrace.toString();
    // 移除可能包含敏感信息的文件路径
    return trace.replaceAll(RegExp(r'/[^/\s]+/[^/\s]+/[^/\s]+/'), '/.../.../.../');
  }

  /// 安全日志记录
  static void secureLog(String message, {String? tag}) {
    if (!kDebugMode) return; // 生产环境不记录日志

    final sanitizedMessage = sanitizeString(message);
    final logTag = tag != null ? '[$tag] ' : '';
    debugPrint('$logTag$sanitizedMessage');
  }

  /// 安全错误日志记录
  static void secureLogError(String message, {Exception? error, StackTrace? stackTrace}) {
    if (!kDebugMode) return;

    final sanitizedMessage = sanitizeString(message);
    debugPrint('ERROR: $sanitizedMessage');

    if (error != null) {
      final sanitizedError = sanitizeException(error);
      debugPrint('Exception: $sanitizedError');
    }

    if (stackTrace != null) {
      final sanitizedTrace = sanitizeStackTrace(stackTrace);
      debugPrint('Stack trace: $sanitizedTrace');
    }
  }

  /// 验证脱敏效果
  static bool isDataSanitized(String data) {
    // 检查是否包含常见的敏感信息模式

    // 检查明文密码
    if (RegExp(r'"password"\s*:\s*"[^*]').hasMatch(data)) return false;

    // 检查API密钥
    if (RegExp(r'"api_key"\s*:\s*"[^*]').hasMatch(data)) return false;

    // 检查JWT令牌
    if (RegExp(r'\beyJ[a-zA-Z0-9_-]{20,}\.[a-zA-Z0-9_-]+\.[a-zA-Z0-9_-]+\b').hasMatch(data))
      return false;

    // 检查邮箱
    if (RegExp(r'\b[A-Za-z0-9._%+-]+@[A-Za-z0-9.-]+\.[A-Z|a-z]{2,}\b').hasMatch(data)) return false;

    return true;
  }
}

/// 安全日志记录器
class SecureLogger {
  static const String _defaultTag = 'EatWhat';

  /// 记录信息日志
  static void info(String message, {String? tag}) {
    LogSanitizer.secureLog(message, tag: tag ?? _defaultTag);
  }

  /// 记录警告日志
  static void warning(String message, {String? tag}) {
    LogSanitizer.secureLog('WARNING: $message', tag: tag ?? _defaultTag);
  }

  /// 记录错误日志
  static void error(String message, {Exception? error, StackTrace? stackTrace, String? tag}) {
    LogSanitizer.secureLogError(message, error: error, stackTrace: stackTrace);
  }

  /// 记录调试日志
  static void debug(String message, {String? tag}) {
    if (kDebugMode) {
      LogSanitizer.secureLog('DEBUG: $message', tag: tag ?? _defaultTag);
    }
  }

  /// 记录API请求
  static void apiRequest(String method, String url, {Map<String, String>? headers, String? body}) {
    if (!kDebugMode) return;

    final sanitizedUrl = LogSanitizer._sanitizeUrl(url);
    final sanitizedHeaders = headers != null ? LogSanitizer.sanitizeHeaders(headers) : null;
    final sanitizedBody = body != null ? LogSanitizer.sanitizeString(body) : null;

    info('API Request: $method $sanitizedUrl');
    if (sanitizedHeaders != null) {
      debug('Headers: $sanitizedHeaders');
    }
    if (sanitizedBody != null) {
      debug('Body: $sanitizedBody');
    }
  }

  /// 记录API响应
  static void apiResponse(int statusCode, String? body) {
    if (!kDebugMode) return;

    final sanitizedBody = body != null ? LogSanitizer.sanitizeString(body) : null;

    info('API Response: $statusCode');
    if (sanitizedBody != null) {
      debug('Response body: $sanitizedBody');
    }
  }
}
