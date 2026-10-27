import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:eatwhat_app/core/services/auth_service.dart';
import 'package:eatwhat_app/v2/core/config/client_config.dart';
import 'package:eatwhat_app/v2/core/ports/ai_gateway.dart';

class GenerationTransport implements AiGateway {
  GenerationTransport({ClientConfig? config}) : _fixedConfig = config;

  final ClientConfig? _fixedConfig;
  final Dio _dio = Dio();

  ClientConfig get _config => _fixedConfig ?? ClientConfig.fromEnvConfig();

  String get _baseUrl => _config.minimaxChatApiUrl;

  String get _apiKey => _config.minimaxApiKey;
  String get _textModel => _config.minimaxChatModel;

  bool get _useAiProxy =>
      _apiKey.trim().isEmpty && _config.hasUsableExecutionProxy;

  String get _proxyChatCompletionsUrl =>
      '${_config.executionProxyBaseUrl.trim().replaceAll(RegExp(r'/+$'), '')}'
      '/api/v1/ai/chat/completions';

  String get _imageModel => _config.aiImageModelName;
  String get _miniMaxImageModel => _config.minimaxImageModel.trim().isNotEmpty
      ? _config.minimaxImageModel
      : (_imageModel.trim().isNotEmpty ? _imageModel : 'image-01');
  String get _imageApiKey => _apiKey;
  String get _imageApiUrl => _config.minimaxApiUrl;

  int get _timeoutSeconds => _config.aiRequestTimeoutSeconds;

  int get _maxRetries => _config.aiMaxRetries;

  double get _temperature => _config.aiTemperature;

  @override
  bool get isConfigured => _apiKey.trim().isNotEmpty || _useAiProxy;
  bool get _isMiniMaxTextApi =>
      _baseUrl.contains('api.minimaxi.com') ||
      _baseUrl.contains('api.minimax.io');

  Options _options() {
    return Options(
      headers: {
        'Authorization': 'Bearer $_apiKey',
        'Content-Type': 'application/json',
      },
      sendTimeout: Duration(seconds: _timeoutSeconds),
      receiveTimeout: Duration(seconds: _timeoutSeconds),
    );
  }

  Options _proxyOptions() {
    final userToken = AuthService.remoteAuthToken ?? '';
    final serviceToken = _config.executionProxyAuthToken.trim();
    return Options(
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
        if (userToken.isNotEmpty) 'Authorization': 'Bearer $userToken',
        if (serviceToken.isNotEmpty) 'X-Execution-Proxy-Token': serviceToken,
      },
      sendTimeout: Duration(seconds: _timeoutSeconds),
      receiveTimeout: Duration(seconds: _timeoutSeconds),
    );
  }

  Options _imageOptions() {
    return Options(
      headers: {
        'Authorization': 'Bearer $_imageApiKey',
        'Content-Type': 'application/json',
      },
      sendTimeout: Duration(seconds: _timeoutSeconds),
      receiveTimeout: Duration(seconds: _timeoutSeconds),
    );
  }

  @override
  Future<Map<String, dynamic>> chatJson({
    required String system,
    required String user,
    double? temperature,
    CancelToken? cancelToken,
  }) async {
    if (!isConfigured) {
      throw StateError('AI 未配置：缺少 MINIMAX_API_KEY 或 EXECUTION_PROXY_BASE_URL');
    }

    Object? lastError;
    for (var attempt = 0; attempt < _maxRetries; attempt++) {
      try {
        final response = await _postChatCompletions(
          system: system,
          user: user,
          temperature: temperature ?? _temperature,
          includeResponseFormat: true,
          cancelToken: cancelToken,
        );

        final content = response.data['choices'][0]['message']['content'];
        return _parseJsonFromModelContent(content?.toString() ?? '');
      } catch (e) {
        lastError = e;
        if (cancelToken?.isCancelled == true) rethrow;

        if (_shouldRetryWithoutResponseFormat(e)) {
          try {
            final response = await _postChatCompletions(
              system: system,
              user: user,
              temperature: temperature ?? _temperature,
              includeResponseFormat: false,
              cancelToken: cancelToken,
            );
            final content = response.data['choices'][0]['message']['content'];
            return _parseJsonFromModelContent(content?.toString() ?? '');
          } catch (e2) {
            lastError = e2;
            if (cancelToken?.isCancelled == true) rethrow;
            if (!_shouldRetryRequest(e2)) break;
            continue;
          }
        }
        if (!_shouldRetryRequest(e)) break;
      }
    }
    throw Exception('AI 请求失败：$lastError');
  }

  bool _shouldRetryRequest(Object error) {
    if (error is! DioException) return false;
    if (error.type == DioExceptionType.cancel) return false;
    if (error.type == DioExceptionType.connectionTimeout ||
        error.type == DioExceptionType.sendTimeout ||
        error.type == DioExceptionType.receiveTimeout ||
        error.type == DioExceptionType.connectionError) {
      return true;
    }
    if (error.type == DioExceptionType.unknown && error.response == null) {
      final cause = error.error?.toString() ?? '';
      return cause.startsWith('SocketException:') ||
          cause.startsWith('HttpException:');
    }
    final statusCode = error.response?.statusCode;
    return statusCode == 429 ||
        (statusCode != null && statusCode >= 500 && statusCode < 600);
  }

  Future<Response<dynamic>> _postChatCompletions({
    required String system,
    required String user,
    required double temperature,
    required bool includeResponseFormat,
    CancelToken? cancelToken,
  }) async {
    final data = <String, dynamic>{
      'model': _textModel,
      'messages': [
        {'role': 'system', 'content': system},
        {'role': 'user', 'content': user},
      ],
      'temperature': temperature,
      'stream': false,
    };
    if (includeResponseFormat) {
      data['response_format'] = {'type': 'json_object'};
    }

    if (_useAiProxy) {
      return _dio.post(
        _proxyChatCompletionsUrl,
        options: _proxyOptions(),
        data: data,
        cancelToken: cancelToken,
      );
    }
    return _dio.post(
      '$_baseUrl/chat/completions',
      options: _options(),
      data: data,
      cancelToken: cancelToken,
    );
  }

  bool _shouldRetryWithoutResponseFormat(Object error) {
    if (error is! DioException) return false;
    final status = error.response?.statusCode;
    if (status != 400) return false;
    final body = error.response?.data?.toString() ?? '';
    final msg = error.message ?? '';
    final text = '$msg\n$body'.toLowerCase();
    return text.contains('response_format');
  }

  Map<String, dynamic> _parseJsonFromModelContent(String raw) {
    var text = raw.trim();
    text = text.replaceAll(RegExp(r'<think>[\s\S]*?</think>'), '');
    final unclosedThink = text.indexOf('<think>');
    if (unclosedThink >= 0) {
      text = text.substring(0, unclosedThink);
    }
    if (text.startsWith('```json')) {
      text = text.replaceFirst(RegExp(r'^```json\s*'), '');
      text = text.replaceFirst(RegExp(r'```\s*$'), '');
    } else if (text.startsWith('```')) {
      text = text.replaceFirst(RegExp(r'^```\s*'), '');
      text = text.replaceFirst(RegExp(r'```\s*$'), '');
    }

    final start = text.indexOf('{');
    final end = text.lastIndexOf('}');
    if (start >= 0 && end >= 0 && end > start) {
      text = text.substring(start, end + 1);
    }

    final decoded = jsonDecode(text);
    if (decoded is Map<String, dynamic>) return decoded;
    if (decoded is Map) {
      return decoded.map((k, v) => MapEntry(k.toString(), v));
    }
    throw const FormatException('AI 返回不是 JSON 对象');
  }

  @override
  Future<String?> generateImage({
    required String prompt,
    CancelToken? cancelToken,
  }) async {
    if ((!isConfigured && _imageApiKey.trim().isEmpty) ||
        (_imageModel.trim().isEmpty && _miniMaxImageModel.trim().isEmpty)) {
      return null;
    }

    Object? lastError;
    for (var attempt = 0; attempt < _maxRetries; attempt++) {
      try {
        if (_isMiniMaxTextApi || _imageApiUrl.contains('api.minimaxi.com')) {
          return await _generateMiniMaxImageLocation(
            prompt,
            cancelToken: cancelToken,
          );
        }

        final response = await _dio.post(
          '$_baseUrl/images/generations',
          options: _options(),
          data: {
            'model': _imageModel,
            'prompt': prompt,
            'size': '1024x1024',
            'n': 1,
            'style': 'vivid',
            'quality': 'hd',
          },
          cancelToken: cancelToken,
        );

        final data = response.data;
        final list = data['data'];
        if (list is List && list.isNotEmpty) {
          final url = list.first['url']?.toString();
          if (url != null && url.isNotEmpty) {
            return url;
          }
        }
        return null;
      } catch (e) {
        lastError = e;
        if (cancelToken?.isCancelled == true) rethrow;
        if (!_shouldRetryRequest(e)) break;
      }
    }
    throw Exception('图片生成失败：$lastError');
  }

  Future<String?> _generateMiniMaxImageLocation(
    String prompt, {
    CancelToken? cancelToken,
  }) async {
    if (_imageApiKey.trim().isEmpty) {
      return null;
    }

    final response = await _dio.post(
      _imageApiUrl,
      options: _imageOptions(),
      data: {
        'model': _miniMaxImageModel,
        'prompt': prompt,
        'aspect_ratio': '4:3',
        'response_format': 'url',
        'n': 1,
        'prompt_optimizer': false,
      },
      cancelToken: cancelToken,
    );

    final miniMaxError = _extractMiniMaxError(response.data);
    if (miniMaxError != null) {
      final normalized = miniMaxError.toLowerCase();
      final isAuthIssue = normalized.contains('status_code=1004') ||
          normalized.contains('authorization') ||
          normalized.contains('secret key');
      if (isAuthIssue) {
        throw Exception(
          'MiniMax 图片接口鉴权失败，请检查当前 API Key、'
          'Authorization 请求头以及本地 .env 配置。'
          '官方返回：$miniMaxError',
        );
      }
      throw Exception('MiniMax 图片接口返回错误：$miniMaxError');
    }

    final url = extractMiniMaxImageUrl(response.data);
    if (url != null && url.isNotEmpty) {
      return url;
    }

    final base64Payload = extractMiniMaxImageBase64(response.data);
    if (base64Payload == null || base64Payload.isEmpty) {
      return null;
    }
    return 'data:image/jpeg;base64,$base64Payload';
  }

  static String? extractMiniMaxImageBase64(dynamic payload) {
    String? pickFirstString(dynamic candidate) {
      if (candidate is String) {
        final value = candidate.trim();
        return value.isEmpty ? null : value;
      }
      if (candidate is List) {
        for (final item in candidate) {
          final value = pickFirstString(item);
          if (value != null) {
            return value;
          }
        }
      }
      return null;
    }

    if (payload is Map) {
      final directCandidates = [
        payload['base64'],
        payload['image_base64'],
        payload['base64_data'],
        payload['b64_json'],
      ];
      for (final candidate in directCandidates) {
        final value = pickFirstString(candidate);
        if (value != null) {
          return value;
        }
      }

      final data = payload['data'];
      if (data is Map) {
        return extractMiniMaxImageBase64(data);
      }
      if (data is List && data.isNotEmpty) {
        return extractMiniMaxImageBase64(data.first);
      }
    }
    return null;
  }

  static String? extractMiniMaxImageUrl(dynamic payload) {
    String? pickFirstString(dynamic candidate) {
      if (candidate is String) {
        final value = candidate.trim();
        return value.isEmpty ? null : value;
      }
      if (candidate is List) {
        for (final item in candidate) {
          final value = pickFirstString(item);
          if (value != null) {
            return value;
          }
        }
      }
      return null;
    }

    if (payload is Map) {
      final directCandidates = [
        payload['url'],
        payload['image_url'],
        payload['image_urls'],
      ];
      for (final candidate in directCandidates) {
        final value = pickFirstString(candidate);
        if (value != null) {
          return value;
        }
      }

      final data = payload['data'];
      if (data is Map) {
        return extractMiniMaxImageUrl(data);
      }
      if (data is List && data.isNotEmpty) {
        return extractMiniMaxImageUrl(data.first);
      }
    }
    return null;
  }

  String? _extractMiniMaxError(dynamic payload) {
    if (payload is Map) {
      final baseResp = payload['base_resp'];
      if (baseResp is Map) {
        final statusCode = baseResp['status_code']?.toString() ?? '';
        final statusMsg = baseResp['status_msg']?.toString() ?? '';
        final normalizedMsg = statusMsg.trim().toLowerCase();
        const successMessages = {'', 'success', 'ok'};
        if ((statusCode.isNotEmpty && statusCode != '0') ||
            !successMessages.contains(normalizedMsg)) {
          return 'status_code=$statusCode, status_msg=$statusMsg';
        }
      }
    }
    return null;
  }
}
