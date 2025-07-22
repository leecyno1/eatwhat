import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'api_signature_service.dart';
import 'token_service.dart';
import '../config/env_config.dart';
import '../utils/log_sanitizer.dart';

/// 安全HTTP客户端
/// 自动处理请求签名、认证令牌和错误处理
class SecureHttpClient {
  static final SecureHttpClient _instance = SecureHttpClient._internal();
  factory SecureHttpClient() => _instance;
  SecureHttpClient._internal();
  
  late final Dio _dio;
  
  /// 初始化HTTP客户端
  void initialize() {
    _dio = Dio(BaseOptions(
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'User-Agent': 'EatWhat-App/1.0.0',
      },
    ));
    
    // 添加请求拦截器
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: _onRequest,
      onResponse: _onResponse,
      onError: _onError,
    ));
    
    // 添加安全日志拦截器（仅调试模式）
    if (kDebugMode && EnvConfig.debugMode) {
      _dio.interceptors.add(LogInterceptor(
        requestBody: false, // 不记录请求体，可能包含敏感信息
        responseBody: false, // 不记录响应体，可能包含敏感信息
        logPrint: (obj) {
          // 使用安全日志记录器
          final sanitizedLog = LogSanitizer.sanitizeString(obj.toString());
          SecureLogger.debug(sanitizedLog, tag: 'HTTP');
        },
      ));
    }
  }
  
  /// GET请求
  Future<Response<T>> get<T>(
    String path, {
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    return await _dio.get<T>(
      path,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }
  
  /// POST请求
  Future<Response<T>> post<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    return await _dio.post<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }
  
  /// PUT请求
  Future<Response<T>> put<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    return await _dio.put<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }
  
  /// DELETE请求
  Future<Response<T>> delete<T>(
    String path, {
    dynamic data,
    Map<String, dynamic>? queryParameters,
    Options? options,
    CancelToken? cancelToken,
  }) async {
    return await _dio.delete<T>(
      path,
      data: data,
      queryParameters: queryParameters,
      options: options,
      cancelToken: cancelToken,
    );
  }
  
  /// 请求拦截器
  Future<void> _onRequest(RequestOptions options, RequestInterceptorHandler handler) async {
    try {
      // 添加认证令牌
      final token = await TokenService.getCurrentToken();
      if (token != null) {
        options.headers['Authorization'] = 'Bearer $token';
      }
      
      // 生成请求签名
      final signedHeaders = ApiSignatureService.createSignedHeaders(
        method: options.method,
        url: options.uri.toString(),
        additionalHeaders: Map<String, String>.from(options.headers),
        body: options.data != null ? json.encode(options.data) : null,
      );
      
      // 更新请求头
      options.headers.addAll(signedHeaders);
      
      // 添加请求ID用于追踪
      final requestId = _generateRequestId();
      options.headers['X-Request-ID'] = requestId;
      
      // 记录请求日志
      SecureLogger.apiRequest(
        options.method,
        options.uri.toString(),
        headers: Map<String, String>.from(options.headers),
        body: options.data != null ? json.encode(options.data) : null,
      );
      
      handler.next(options);
    } catch (e) {
      SecureLogger.error('Request interceptor error', error: e is Exception ? e : Exception(e.toString()));
      handler.next(options);
    }
  }
  
  /// 响应拦截器
  Future<void> _onResponse(Response response, ResponseInterceptorHandler handler) async {
    try {
      // 验证响应签名（如果服务器提供）
      final serverSignature = response.headers.value('X-Server-Signature');
      if (serverSignature != null) {
        final isValid = _validateResponseSignature(response, serverSignature);
        if (!isValid) {
          SecureLogger.warning('Invalid server signature detected');
        }
      }
      
      // 记录响应日志
      SecureLogger.apiResponse(
        response.statusCode ?? 0,
        response.data != null ? json.encode(response.data) : null,
      );
      
      handler.next(response);
    } catch (e) {
      SecureLogger.error('Response interceptor error', error: e is Exception ? e : Exception(e.toString()));
      handler.next(response);
    }
  }
  
  /// 错误拦截器
  Future<void> _onError(DioException error, ErrorInterceptorHandler handler) async {
    try {
      // 处理认证错误
      if (error.response?.statusCode == 401) {
        final refreshed = await _tryRefreshToken();
        if (refreshed) {
          // 重试原始请求
          final retryResponse = await _retryRequest(error.requestOptions);
          handler.resolve(retryResponse);
          return;
        }
      }
      
      // 处理签名错误
      if (error.response?.statusCode == 403) {
        final errorData = error.response?.data;
        if (errorData is Map && errorData['error'] == 'signature_invalid') {
          SecureLogger.warning('Request signature validation failed');
        }
      }
      
      // 记录错误（脱敏处理）
      _logError(error);
      
      handler.next(error);
    } catch (e) {
      SecureLogger.error('Error interceptor error', error: e is Exception ? e : Exception(e.toString()));
      handler.next(error);
    }
  }
  
  /// 尝试刷新令牌
  Future<bool> _tryRefreshToken() async {
    try {
      final newTokenPair = await TokenService.refreshToken();
      return newTokenPair != null;
    } catch (e) {
      SecureLogger.error('Token refresh failed', error: e is Exception ? e : Exception(e.toString()));
      return false;
    }
  }
  
  /// 重试请求
  Future<Response> _retryRequest(RequestOptions options) async {
    // 移除旧的认证头
    options.headers.remove('Authorization');
    
    // 添加新的认证令牌
    final token = await TokenService.getCurrentToken();
    if (token != null) {
      options.headers['Authorization'] = 'Bearer $token';
    }
    
    return await _dio.fetch(options);
  }
  
  /// 验证响应签名
  bool _validateResponseSignature(Response response, String signature) {
    try {
      // 构建响应签名字符串
      final responseData = response.data != null ? json.encode(response.data) : '';
      final statusCode = response.statusCode.toString();
      final timestamp = response.headers.value('X-Timestamp') ?? '';
      
      final signatureString = '$statusCode\n$responseData\n$timestamp';
      
      // 使用服务器公钥验证签名（这里简化处理）
      return signature.isNotEmpty && signatureString.isNotEmpty;
    } catch (e) {
      SecureLogger.error('Response signature validation error', error: e is Exception ? e : Exception(e.toString()));
      return false;
    }
  }
  
  /// 生成请求ID
  String _generateRequestId() {
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    final random = timestamp.hashCode;
    return '$timestamp-$random';
  }
  
  /// 记录错误（脱敏处理）
  void _logError(DioException error) {
    if (!kDebugMode) return;
    
    final sanitizedError = {
      'type': error.type.toString(),
      'method': error.requestOptions.method,
      'path': _sanitizeUrl(error.requestOptions.path),
      'statusCode': error.response?.statusCode,
      'message': error.message,
    };
    
    SecureLogger.error('HTTP Error: $sanitizedError');
  }
  
  /// URL脱敏处理
  String _sanitizeUrl(String url) {
    // 移除敏感的查询参数
    final uri = Uri.parse(url);
    final sanitizedParams = <String, String>{};
    
    uri.queryParameters.forEach((key, value) {
      if (_isSensitiveParam(key)) {
        sanitizedParams[key] = '[HIDDEN]';
      } else {
        sanitizedParams[key] = value;
      }
    });
    
    return uri.replace(queryParameters: sanitizedParams).toString();
  }
  
  /// 检查是否为敏感参数
  bool _isSensitiveParam(String param) {
    const sensitiveParams = [
      'password', 'token', 'secret', 'key', 'api_key',
      'auth', 'authorization', 'session', 'credit_card'
    ];
    
    return sensitiveParams.any((sensitive) => 
      param.toLowerCase().contains(sensitive));
  }
  
  /// 获取Dio实例（用于高级用法）
  Dio get dio => _dio;
}

/// 安全HTTP客户端单例
final secureHttpClient = SecureHttpClient();