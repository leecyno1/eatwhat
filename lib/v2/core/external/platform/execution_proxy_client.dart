import 'package:dio/dio.dart';
import 'package:eatwhat_app/core/config/env_config.dart';
import 'package:eatwhat_app/core/services/auth_service.dart';
import 'package:eatwhat_app/v2/core/external/platform/platform_exceptions.dart';

class ExecutionProxyClient {
  ExecutionProxyClient({
    Dio? dio,
    String? baseUrl,
    this.authToken,
    String? serviceToken,
  })  : _dio = dio ??
            Dio(
              BaseOptions(
                connectTimeout: const Duration(seconds: 3),
                sendTimeout: const Duration(seconds: 3),
                receiveTimeout: const Duration(seconds: 6),
              ),
            ),
        baseUrl = baseUrl ?? EnvConfig.executionProxyBaseUrl,
        serviceToken = serviceToken ?? EnvConfig.executionProxyAuthToken;

  final Dio _dio;
  final String baseUrl;
  final String? authToken;
  final String serviceToken;

  bool get isConfigured => baseUrl.isNotEmpty;

  Future<Map<String, bool>> getProviderHealth({String? path}) async {
    final payload = await getJson(path ?? EnvConfig.executionProxyHealthPath);
    final providers = payload['providers'];
    if (providers is! Map) return const {};
    return {
      for (final entry in providers.entries)
        entry.key.toString(): entry.value == true,
    };
  }

  Future<Map<String, dynamic>> getJson(String path) async {
    _ensureConfigured();

    try {
      final response = await _dio.get<Map<String, dynamic>>(
        _resolveUrl(path),
        options: Options(headers: _headers()),
      );
      return response.data ?? const <String, dynamic>{};
    } on DioException catch (error) {
      throw _proxyException(error);
    }
  }

  Future<Map<String, dynamic>> getJsonWithQuery(
    String path, {
    Map<String, dynamic> query = const {},
  }) async {
    _ensureConfigured();

    try {
      final response = await _dio.get<Map<String, dynamic>>(
        _resolveUrl(path),
        queryParameters: query,
        options: Options(headers: _headers()),
      );
      return response.data ?? const <String, dynamic>{};
    } on DioException catch (error) {
      throw _proxyException(error);
    }
  }

  Future<Map<String, dynamic>> postJson(
    String path, {
    Map<String, dynamic> body = const {},
  }) async {
    _ensureConfigured();

    try {
      final response = await _dio.post<Map<String, dynamic>>(
        _resolveUrl(path),
        data: body,
        options: Options(headers: _headers()),
      );

      return response.data ?? const <String, dynamic>{};
    } on DioException catch (error) {
      throw _proxyException(error);
    }
  }

  void _ensureConfigured() {
    if (isConfigured) return;
    throw PlatformApiNotConfiguredException(
      'proxy',
      message: '执行层代理服务未配置（缺少 EXECUTION_PROXY_BASE_URL）',
    );
  }

  Map<String, String> _headers() {
    final userToken = authToken ?? AuthService.authToken ?? '';
    return {
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      if (userToken.isNotEmpty) 'Authorization': 'Bearer $userToken',
      if (serviceToken.isNotEmpty) 'X-Execution-Proxy-Token': serviceToken,
    };
  }

  PlatformApiException _proxyException(DioException error) {
    final data = error.response?.data;
    String? upstreamMessage;
    String? upstreamCode;
    var upstreamDetails = const <String, dynamic>{};
    if (data is Map) {
      final rawError = data['error'];
      if (rawError is Map) {
        upstreamMessage = rawError['message']?.toString();
        upstreamCode = rawError['code']?.toString();
        final rawDetails = rawError['details'];
        if (rawDetails is Map) {
          upstreamDetails = Map<String, dynamic>.from(rawDetails);
        }
      }
      upstreamMessage ??= data['reason']?.toString();
    }
    final message = upstreamMessage?.trim().isNotEmpty == true
        ? upstreamMessage!.trim()
        : error.message ?? '代理服务请求失败';
    return PlatformApiException(
      'proxy',
      message,
      statusCode: error.response?.statusCode,
      code: upstreamCode,
      details: upstreamDetails,
    );
  }

  String _resolveUrl(String path) {
    return '${baseUrl.replaceFirst(RegExp(r'/+$'), '')}/${path.replaceFirst(RegExp(r'^/+'), '')}';
  }
}
