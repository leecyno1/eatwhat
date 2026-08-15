import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';

Future<void> main(List<String> args) async {
  final config = ExecutionProxyServerConfig.fromEnvironment(
    Platform.environment,
    args: args,
  );
  final proxy = ExecutionProxyServer(config);
  final server = await proxy.start();

  stdout
    ..writeln(
      'Execution proxy listening on '
      'http://${server.address.address}:${server.port}',
    )
    ..writeln('GET /health')
    ..writeln(
      'POST /v2/execution/{meituan|eleme|jd-delivery|dianping}/delivery-match',
    )
    ..writeln('POST /api/v1/delivery/merchants/search')
    ..writeln('POST /api/v1/delivery/products/search')
    ..writeln('POST /api/v1/delivery/order-previews')
    ..writeln('POST /api/v1/delivery/orders')
    ..writeln('GET  /api/v1/delivery/oauth/status')
    ..writeln('POST /api/v1/delivery/oauth/authorize');

  ProcessSignal.sigint.watch().listen((_) async {
    await server.close(force: true);
    proxy.close();
    exit(0);
  });
}

class ExecutionProxyServer {
  ExecutionProxyServer(
    this.config, {
    HttpClient? httpClient,
  }) : _httpClient = httpClient ?? HttpClient() {
    _httpClient.connectionTimeout = config.upstreamTimeout;
    _httpClient.idleTimeout = config.upstreamTimeout;
  }

  final ExecutionProxyServerConfig config;
  final HttpClient _httpClient;

  Future<HttpServer> start() async {
    final server = await HttpServer.bind(config.bindAddress, config.port);
    server.listen((request) {
      unawaited(_handle(request));
    });
    return server;
  }

  void close() {
    _httpClient.close(force: true);
  }

  Future<void> _handle(HttpRequest request) async {
    _addCorsHeaders(request.response);

    if (request.method == 'OPTIONS') {
      request.response.statusCode = HttpStatus.noContent;
      await request.response.close();
      return;
    }

    final requestId = request.headers.value('x-request-id') ??
        DateTime.now().microsecondsSinceEpoch.toString();

    if (request.method == 'GET' && request.uri.path == '/health') {
      await _writeJson(
        request.response,
        HttpStatus.ok,
        {
          'status': 'ok',
          'providers': {
            for (final adapter in config.adapters.values.where(
              (adapter) =>
                  adapter.requestKind ==
                  ExecutionProxyRequestKind.deliveryMatch,
            ))
              adapter.platform: adapter.isConfigured,
          },
        },
      );
      return;
    }

    final adapter = config.adapters[request.uri.path];
    if (adapter == null) {
      await _writeError(
        request.response,
        HttpStatus.notFound,
        code: 'route_not_found',
        message: '执行代理路由不存在',
        requestId: requestId,
      );
      return;
    }

    final expectedMethod =
        adapter.requestKind == ExecutionProxyRequestKind.oauthStatus
            ? 'GET'
            : 'POST';
    if (request.method != expectedMethod) {
      request.response.headers.set(
        HttpHeaders.allowHeader,
        '$expectedMethod, OPTIONS',
      );
      await _writeError(
        request.response,
        HttpStatus.methodNotAllowed,
        code: 'method_not_allowed',
        message: '该路由仅支持 $expectedMethod',
        requestId: requestId,
      );
      return;
    }

    final identity = _authenticate(request);
    if (identity == null) {
      await _writeError(
        request.response,
        HttpStatus.unauthorized,
        code: 'unauthorized',
        message: '执行代理鉴权失败',
        requestId: requestId,
      );
      return;
    }

    final body = expectedMethod == 'GET'
        ? <String, dynamic>{}
        : await _readJsonBody(request);
    if (body == null) {
      await _writeError(
        request.response,
        HttpStatus.badRequest,
        code: 'invalid_json',
        message: '请求体必须是 JSON 对象',
        requestId: requestId,
      );
      return;
    }

    final validationError = _validateRequest(adapter.requestKind, body);
    if (validationError != null) {
      await _writeError(
        request.response,
        HttpStatus.unprocessableEntity,
        code: 'validation_error',
        message: validationError,
        requestId: requestId,
      );
      return;
    }

    if (!adapter.isConfigured) {
      request.response.headers.set(HttpHeaders.retryAfterHeader, '60');
      await _writeJson(
        request.response,
        HttpStatus.serviceUnavailable,
        {
          'status': 'unavailable',
          'reason': '${adapter.displayName}适配器未配置',
          'matches': const [],
          'requestId': requestId,
          'error': {
            'code': 'adapter_not_configured',
            'message': '${adapter.displayName}适配器未配置',
          },
        },
      );
      return;
    }

    await _forwardToAdapter(
      request.response,
      adapter: adapter,
      body: body,
      requestId: requestId,
      eatWhatUserId: identity.userId,
    );
  }

  _ExecutionProxyIdentity? _authenticate(HttpRequest request) {
    final bearerToken = _bearerToken(request);
    if (config.jwtSecret.isNotEmpty) {
      final userId = EatWhatJwtVerifier.verify(
        bearerToken ?? '',
        secret: config.jwtSecret,
      );
      if (userId == null || !_hasRequiredProxyToken(request, bearerToken)) {
        return null;
      }
      return _ExecutionProxyIdentity(userId);
    }

    if (!_hasRequiredProxyToken(request, bearerToken)) return null;
    return _ExecutionProxyIdentity(config.localUserId);
  }

  bool _hasRequiredProxyToken(HttpRequest request, String? bearerToken) {
    if (config.requiredToken.isEmpty) return true;
    return request.headers.value('x-execution-proxy-token') ==
            config.requiredToken ||
        bearerToken == config.requiredToken;
  }

  String? _bearerToken(HttpRequest request) {
    final raw = request.headers.value(HttpHeaders.authorizationHeader) ?? '';
    if (!raw.startsWith('Bearer ')) return null;
    final token = raw.substring(7).trim();
    return token.isEmpty ? null : token;
  }

  Future<Map<String, dynamic>?> _readJsonBody(HttpRequest request) async {
    try {
      final rawBody = await utf8.decoder.bind(request).join();
      final decoded = jsonDecode(rawBody);
      if (decoded is! Map) return null;
      return Map<String, dynamic>.from(decoded);
    } on FormatException {
      return null;
    }
  }

  String? _validateRequest(
    ExecutionProxyRequestKind requestKind,
    Map<String, dynamic> body,
  ) {
    if (requestKind == ExecutionProxyRequestKind.oauthStatus ||
        requestKind == ExecutionProxyRequestKind.oauthAuthorize) {
      return null;
    }
    if (requestKind == ExecutionProxyRequestKind.productSearch &&
        (body['merchantId']?.toString().trim().isEmpty ?? true)) {
      return 'merchantId 不能为空';
    }
    if (requestKind == ExecutionProxyRequestKind.orderPreview ||
        requestKind == ExecutionProxyRequestKind.orderSubmit) {
      if (body['merchantId']?.toString().trim().isEmpty ?? true) {
        return 'merchantId 不能为空';
      }
      final items = body['items'];
      if (items is! List || items.isEmpty) return 'items 不能为空';
      if (requestKind == ExecutionProxyRequestKind.orderSubmit &&
          (body['previewToken']?.toString().trim().isEmpty ?? true)) {
        return 'previewToken 不能为空';
      }
      return null;
    }

    if (requestKind == ExecutionProxyRequestKind.productSearch ||
        requestKind == ExecutionProxyRequestKind.merchantSearch) {
      return _validateGeoAndLimit(body);
    }

    final dishName = body['dishName'];
    if (dishName is! String || dishName.trim().isEmpty) {
      return 'dishName 不能为空';
    }

    return _validateGeoAndLimit(body);
  }

  String? _validateGeoAndLimit(Map<String, dynamic> body) {
    final geo = body['geo'];
    if (geo is! Map || geo['latitude'] is! num || geo['longitude'] is! num) {
      return 'geo.latitude 和 geo.longitude 必须是数字';
    }

    final limit = body['limit'];
    if (limit != null && (limit is! num || limit < 1 || limit > 20)) {
      return 'limit 必须在 1 到 20 之间';
    }
    return null;
  }

  Future<void> _forwardToAdapter(
    HttpResponse clientResponse, {
    required ExecutionProxyAdapterConfig adapter,
    required Map<String, dynamic> body,
    required String requestId,
    required String eatWhatUserId,
  }) async {
    try {
      final upstreamRequest =
          adapter.requestKind == ExecutionProxyRequestKind.oauthStatus
              ? await _httpClient
                  .getUrl(adapter.upstreamUri!)
                  .timeout(config.upstreamTimeout)
              : await _httpClient
                  .postUrl(adapter.upstreamUri!)
                  .timeout(config.upstreamTimeout);
      upstreamRequest.headers
        ..contentType = ContentType.json
        ..set(HttpHeaders.acceptHeader, ContentType.json.mimeType)
        ..set('x-request-id', requestId)
        ..set('x-eatwhat-user-id', eatWhatUserId);
      if (adapter.upstreamToken.isNotEmpty) {
        upstreamRequest.headers.set(
          HttpHeaders.authorizationHeader,
          'Bearer ${adapter.upstreamToken}',
        );
      }
      if (adapter.requestKind != ExecutionProxyRequestKind.oauthStatus) {
        upstreamRequest.write(jsonEncode(body));
      }

      final upstreamResponse =
          await upstreamRequest.close().timeout(config.upstreamTimeout);
      final rawResponse = await utf8.decoder
          .bind(upstreamResponse)
          .join()
          .timeout(config.upstreamTimeout);

      if (upstreamResponse.statusCode < 200 ||
          upstreamResponse.statusCode >= 300) {
        await _forwardAdapterError(
          clientResponse,
          adapter: adapter,
          requestId: requestId,
          statusCode: upstreamResponse.statusCode,
          rawResponse: rawResponse,
        );
        return;
      }

      final decoded = jsonDecode(rawResponse);
      if (decoded is! Map) {
        await _writeAdapterFailure(
          clientResponse,
          adapter: adapter,
          requestId: requestId,
        );
        return;
      }
      final payload = Map<String, dynamic>.from(decoded)
        ..putIfAbsent('requestId', () => requestId);
      await _writeJson(clientResponse, HttpStatus.ok, payload);
    } on TimeoutException {
      await _writeAdapterFailure(
        clientResponse,
        adapter: adapter,
        requestId: requestId,
        reason: '${adapter.displayName}适配器响应超时',
      );
    } on Object {
      await _writeAdapterFailure(
        clientResponse,
        adapter: adapter,
        requestId: requestId,
      );
    }
  }

  Future<void> _forwardAdapterError(
    HttpResponse response, {
    required ExecutionProxyAdapterConfig adapter,
    required String requestId,
    required int statusCode,
    required String rawResponse,
  }) async {
    try {
      final decoded = jsonDecode(rawResponse);
      if (decoded is Map) {
        final payload = Map<String, dynamic>.from(decoded)
          ..putIfAbsent('requestId', () => requestId);
        await _writeJson(response, statusCode, payload);
        return;
      }
    } on FormatException {
      // 由统一错误继续处理。
    }
    await _writeAdapterFailure(
      response,
      adapter: adapter,
      requestId: requestId,
    );
  }

  Future<void> _writeAdapterFailure(
    HttpResponse response, {
    required ExecutionProxyAdapterConfig adapter,
    required String requestId,
    String? reason,
  }) async {
    final message = reason ?? '${adapter.displayName}适配器暂时不可用';
    await _writeJson(
      response,
      HttpStatus.badGateway,
      {
        'status': 'unavailable',
        'reason': message,
        'matches': const [],
        'requestId': requestId,
        'error': {
          'code': 'adapter_unavailable',
          'message': message,
        },
      },
    );
  }

  void _addCorsHeaders(HttpResponse response) {
    final allowedOrigin = config.allowedOrigin;
    if (allowedOrigin == null || allowedOrigin.isEmpty) return;
    response.headers
      ..set('Access-Control-Allow-Origin', allowedOrigin)
      ..set('Access-Control-Allow-Methods', 'GET,POST,OPTIONS')
      ..set(
        'Access-Control-Allow-Headers',
        'Content-Type, Authorization, X-Execution-Proxy-Token, X-Request-Id',
      );
  }
}

class ExecutionProxyServerConfig {
  ExecutionProxyServerConfig({
    required this.bindAddress,
    required this.port,
    required this.requiredToken,
    required this.upstreamTimeout,
    required this.adapters,
    this.allowedOrigin,
    this.jwtSecret = '',
    this.localUserId = 'local-eatwhat-user',
  });

  factory ExecutionProxyServerConfig.fromEnvironment(
    Map<String, String> environment, {
    List<String> args = const [],
  }) {
    final bindAddress = InternetAddress.tryParse(
          environment['EXECUTION_PROXY_BIND_ADDRESS'] ?? '',
        ) ??
        InternetAddress.loopbackIPv4;
    final port = args.isNotEmpty
        ? int.tryParse(args.first) ?? 8787
        : int.tryParse(environment['EXECUTION_PROXY_PORT'] ?? '') ?? 8787;
    final timeoutMilliseconds = int.tryParse(
          environment['EXECUTION_PROXY_UPSTREAM_TIMEOUT_MS'] ?? '',
        ) ??
        6000;

    ExecutionProxyAdapterConfig adapter({
      required String route,
      required String platform,
      required String displayName,
      required String urlKey,
      required String tokenKey,
      ExecutionProxyRequestKind requestKind =
          ExecutionProxyRequestKind.deliveryMatch,
    }) {
      return ExecutionProxyAdapterConfig(
        route: route,
        platform: platform,
        displayName: displayName,
        upstreamUrl: environment[urlKey] ?? '',
        upstreamToken: environment[tokenKey] ?? '',
        requestKind: requestKind,
      );
    }

    final adapters = [
      adapter(
        route: '/v2/execution/meituan/delivery-match',
        platform: 'meituan',
        displayName: '美团外卖',
        urlKey: 'MEITUAN_EXECUTION_ADAPTER_URL',
        tokenKey: 'MEITUAN_EXECUTION_ADAPTER_TOKEN',
      ),
      adapter(
        route: '/api/v1/delivery/merchants/search',
        platform: 'meituan',
        displayName: '美团外卖门店搜索',
        urlKey: 'MEITUAN_MERCHANT_SEARCH_ADAPTER_URL',
        tokenKey: 'MEITUAN_EXECUTION_ADAPTER_TOKEN',
        requestKind: ExecutionProxyRequestKind.merchantSearch,
      ),
      adapter(
        route: '/api/v1/delivery/products/search',
        platform: 'meituan',
        displayName: '美团外卖菜品搜索',
        urlKey: 'MEITUAN_PRODUCT_SEARCH_ADAPTER_URL',
        tokenKey: 'MEITUAN_EXECUTION_ADAPTER_TOKEN',
        requestKind: ExecutionProxyRequestKind.productSearch,
      ),
      adapter(
        route: '/api/v1/delivery/order-previews',
        platform: 'meituan',
        displayName: '美团外卖订单预览',
        urlKey: 'MEITUAN_ORDER_PREVIEW_ADAPTER_URL',
        tokenKey: 'MEITUAN_EXECUTION_ADAPTER_TOKEN',
        requestKind: ExecutionProxyRequestKind.orderPreview,
      ),
      adapter(
        route: '/api/v1/delivery/orders',
        platform: 'meituan',
        displayName: '美团外卖提交订单',
        urlKey: 'MEITUAN_ORDER_SUBMIT_ADAPTER_URL',
        tokenKey: 'MEITUAN_EXECUTION_ADAPTER_TOKEN',
        requestKind: ExecutionProxyRequestKind.orderSubmit,
      ),
      adapter(
        route: '/api/v1/delivery/oauth/status',
        platform: 'meituan',
        displayName: '美团外卖用户授权状态',
        urlKey: 'MEITUAN_OAUTH_STATUS_ADAPTER_URL',
        tokenKey: 'MEITUAN_EXECUTION_ADAPTER_TOKEN',
        requestKind: ExecutionProxyRequestKind.oauthStatus,
      ),
      adapter(
        route: '/api/v1/delivery/oauth/authorize',
        platform: 'meituan',
        displayName: '美团外卖用户授权',
        urlKey: 'MEITUAN_OAUTH_AUTHORIZE_ADAPTER_URL',
        tokenKey: 'MEITUAN_EXECUTION_ADAPTER_TOKEN',
        requestKind: ExecutionProxyRequestKind.oauthAuthorize,
      ),
      adapter(
        route: '/v2/execution/eleme/delivery-match',
        platform: 'eleme',
        displayName: '饿了么',
        urlKey: 'ELEME_EXECUTION_ADAPTER_URL',
        tokenKey: 'ELEME_EXECUTION_ADAPTER_TOKEN',
      ),
      adapter(
        route: '/v2/execution/jd-delivery/delivery-match',
        platform: 'jd_delivery',
        displayName: '京东外卖（秒送）',
        urlKey: 'JD_DELIVERY_EXECUTION_ADAPTER_URL',
        tokenKey: 'JD_DELIVERY_EXECUTION_ADAPTER_TOKEN',
      ),
      adapter(
        route: '/v2/execution/dianping/delivery-match',
        platform: 'dianping',
        displayName: '大众点评',
        urlKey: 'DIANPING_EXECUTION_ADAPTER_URL',
        tokenKey: 'DIANPING_EXECUTION_ADAPTER_TOKEN',
      ),
      adapter(
        route: '/v2/execution/dianping/dine-in-match',
        platform: 'dianping_dine_in',
        displayName: '大众点评到店',
        urlKey: 'DIANPING_DINE_IN_ADAPTER_URL',
        tokenKey: 'DIANPING_DINE_IN_ADAPTER_TOKEN',
      ),
    ];

    return ExecutionProxyServerConfig(
      bindAddress: bindAddress,
      port: port,
      requiredToken:
          environment['EXECUTION_PROXY_REQUIRED_TOKEN']?.trim() ?? '',
      jwtSecret: environment['EXECUTION_PROXY_JWT_SECRET']?.trim() ?? '',
      localUserId:
          environment['EXECUTION_PROXY_LOCAL_USER_ID']?.trim().isNotEmpty ==
                  true
              ? environment['EXECUTION_PROXY_LOCAL_USER_ID']!.trim()
              : 'local-eatwhat-user',
      upstreamTimeout: Duration(milliseconds: timeoutMilliseconds),
      allowedOrigin: environment['EXECUTION_PROXY_ALLOWED_ORIGIN']?.trim(),
      adapters: {for (final item in adapters) item.route: item},
    );
  }

  final InternetAddress bindAddress;
  final int port;
  final String requiredToken;
  final Duration upstreamTimeout;
  final String? allowedOrigin;
  final String jwtSecret;
  final String localUserId;
  final Map<String, ExecutionProxyAdapterConfig> adapters;
}

class EatWhatJwtVerifier {
  const EatWhatJwtVerifier._();

  static String? verify(
    String token, {
    required String secret,
    DateTime Function()? now,
  }) {
    try {
      final parts = token.split('.');
      if (parts.length != 3 || secret.isEmpty) return null;

      final header = _decodeJsonPart(parts[0]);
      final payload = _decodeJsonPart(parts[1]);
      if (header['alg'] != 'HS256') return null;

      final expected = Hmac(sha256, utf8.encode(secret))
          .convert(utf8.encode('${parts[0]}.${parts[1]}'))
          .bytes;
      final actual = base64Url.decode(base64Url.normalize(parts[2]));
      if (!_constantTimeEquals(expected, actual)) return null;

      final expiresAt = _int(payload['exp']);
      final nowSeconds = (now ?? DateTime.now)().millisecondsSinceEpoch ~/ 1000;
      if (expiresAt == null || expiresAt <= nowSeconds) return null;
      if (payload['type'] != null && payload['type'] != 'access') return null;

      final userId = payload['sub']?.toString().trim() ?? '';
      return userId.isEmpty ? null : userId;
    } on Object {
      return null;
    }
  }

  static Map<String, dynamic> _decodeJsonPart(String value) {
    final decoded = jsonDecode(
      utf8.decode(base64Url.decode(base64Url.normalize(value))),
    );
    if (decoded is! Map) throw const FormatException('JWT payload 无效');
    return Map<String, dynamic>.from(decoded);
  }

  static int? _int(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }

  static bool _constantTimeEquals(List<int> left, List<int> right) {
    if (left.length != right.length) return false;
    var difference = 0;
    for (var index = 0; index < left.length; index++) {
      difference |= left[index] ^ right[index];
    }
    return difference == 0;
  }
}

class _ExecutionProxyIdentity {
  const _ExecutionProxyIdentity(this.userId);

  final String userId;
}

class ExecutionProxyAdapterConfig {
  const ExecutionProxyAdapterConfig({
    required this.route,
    required this.platform,
    required this.displayName,
    required this.upstreamUrl,
    this.upstreamToken = '',
    this.requestKind = ExecutionProxyRequestKind.deliveryMatch,
  });

  final String route;
  final String platform;
  final String displayName;
  final String upstreamUrl;
  final String upstreamToken;
  final ExecutionProxyRequestKind requestKind;

  Uri? get upstreamUri {
    final uri = Uri.tryParse(upstreamUrl.trim());
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) return null;
    return uri;
  }

  bool get isConfigured => upstreamUri != null;
}

enum ExecutionProxyRequestKind {
  deliveryMatch,
  merchantSearch,
  productSearch,
  orderPreview,
  orderSubmit,
  oauthStatus,
  oauthAuthorize,
}

Future<void> _writeError(
  HttpResponse response,
  int statusCode, {
  required String code,
  required String message,
  required String requestId,
}) {
  return _writeJson(
    response,
    statusCode,
    {
      'error': {
        'code': code,
        'message': message,
      },
      'requestId': requestId,
    },
  );
}

Future<void> _writeJson(
  HttpResponse response,
  int statusCode,
  Map<String, dynamic> payload,
) async {
  response
    ..statusCode = statusCode
    ..headers.contentType = ContentType.json
    ..write(jsonEncode(payload));
  await response.close();
}
