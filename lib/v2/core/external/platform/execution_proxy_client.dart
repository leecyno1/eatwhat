import 'package:dio/dio.dart';
import 'package:eatwhat_app/core/config/env_config.dart';
import 'package:eatwhat_app/v2/core/external/platform/platform_exceptions.dart';

class ExecutionProxyClient {
  ExecutionProxyClient({
    Dio? dio,
    String? baseUrl,
    String? authToken,
  })  : _dio = dio ?? Dio(),
        baseUrl = baseUrl ?? EnvConfig.executionProxyBaseUrl,
        authToken = authToken ?? EnvConfig.executionProxyAuthToken;

  final Dio _dio;
  final String baseUrl;
  final String authToken;

  bool get isConfigured => baseUrl.isNotEmpty;

  Future<Map<String, dynamic>> postJson(
    String path, {
    Map<String, dynamic> body = const {},
  }) async {
    if (!isConfigured) {
      throw PlatformApiNotConfiguredException(
        'proxy',
        message: '执行层代理服务未配置（缺少 EXECUTION_PROXY_BASE_URL）',
      );
    }

    try {
      final response = await _dio.post<Map<String, dynamic>>(
        '$baseUrl$path',
        data: body,
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
            if (authToken.isNotEmpty) 'Authorization': 'Bearer $authToken',
          },
        ),
      );

      return response.data ?? const <String, dynamic>{};
    } on DioException catch (error) {
      throw PlatformApiException(
        'proxy',
        error.message ?? '代理服务请求失败',
        statusCode: error.response?.statusCode,
      );
    }
  }
}
