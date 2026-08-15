import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../scripts/execution_proxy_server.dart';

void main() {
  final servers = <HttpServer>[];
  final proxies = <ExecutionProxyServer>[];
  final clients = <HttpClient>[];

  tearDown(() async {
    for (final client in clients) {
      client.close(force: true);
    }
    for (final server in servers) {
      await server.close(force: true);
    }
    for (final proxy in proxies) {
      proxy.close();
    }
    clients.clear();
    servers.clear();
    proxies.clear();
  });

  test('健康检查只返回平台配置状态', () async {
    final proxyServer = await _startProxy(
      adapters: {
        '/v2/execution/meituan/delivery-match':
            const ExecutionProxyAdapterConfig(
          route: '/v2/execution/meituan/delivery-match',
          platform: 'meituan',
          displayName: '美团外卖',
          upstreamUrl: 'https://adapter.example.com/meituan',
        ),
        '/v2/execution/eleme/delivery-match': const ExecutionProxyAdapterConfig(
          route: '/v2/execution/eleme/delivery-match',
          platform: 'eleme',
          displayName: '饿了么',
          upstreamUrl: '',
        ),
      },
      servers: servers,
      proxies: proxies,
    );
    final client = HttpClient();
    clients.add(client);

    final response = await client
        .getUrl(Uri.parse('http://127.0.0.1:${proxyServer.port}/health'))
        .then((request) => request.close());
    final body = await _readResponse(response);

    expect(response.statusCode, HttpStatus.ok);
    expect(body['status'], 'ok');
    expect(body['providers'], {'meituan': true, 'eleme': false});
  });

  test('配置鉴权后拒绝未授权请求', () async {
    const route = '/v2/execution/meituan/delivery-match';
    final proxyServer = await _startProxy(
      requiredToken: 'server-token',
      adapters: {
        route: const ExecutionProxyAdapterConfig(
          route: route,
          platform: 'meituan',
          displayName: '美团外卖',
          upstreamUrl: '',
        ),
      },
      servers: servers,
      proxies: proxies,
    );
    final client = HttpClient();
    clients.add(client);

    final response = await _postJson(
      client,
      Uri.parse('http://127.0.0.1:${proxyServer.port}$route'),
      _validBody(),
    );
    final body = await _readResponse(response);

    expect(response.statusCode, HttpStatus.unauthorized);
    expect((body['error'] as Map<String, dynamic>)['code'], 'unauthorized');
  });

  test('代理会转发请求和平台适配器令牌', () async {
    final upstreamRequest = Completer<Map<String, dynamic>>();
    final upstream = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    servers.add(upstream);
    upstream.listen((request) async {
      final body = jsonDecode(await utf8.decoder.bind(request).join())
          as Map<String, dynamic>;
      upstreamRequest.complete({
        'body': body,
        'authorization': request.headers.value(HttpHeaders.authorizationHeader),
        'requestId': request.headers.value('x-request-id'),
        'userId': request.headers.value('x-eatwhat-user-id'),
      });
      request.response
        ..statusCode = HttpStatus.ok
        ..headers.contentType = ContentType.json
        ..write(
          jsonEncode({
            'status': 'available',
            'matches': [
              {
                'merchantId': 'm1',
                'merchantName': '锅气食堂',
                'dishName': '麻婆豆腐',
                'webUrl': 'https://example.com/order',
              },
            ],
          }),
        );
      await request.response.close();
    });

    const route = '/v2/execution/meituan/delivery-match';
    final proxyServer = await _startProxy(
      requiredToken: 'client-token',
      adapters: {
        route: ExecutionProxyAdapterConfig(
          route: route,
          platform: 'meituan',
          displayName: '美团外卖',
          upstreamUrl: 'http://127.0.0.1:${upstream.port}/match',
          upstreamToken: 'adapter-token',
        ),
      },
      servers: servers,
      proxies: proxies,
    );
    final client = HttpClient();
    clients.add(client);
    final uri = Uri.parse('http://127.0.0.1:${proxyServer.port}$route');

    final response = await _postJson(
      client,
      uri,
      _validBody(),
      token: 'client-token',
      requestId: 'req-001',
    );
    final responseBody = await _readResponse(response);
    final forwarded = await upstreamRequest.future;

    expect(response.statusCode, HttpStatus.ok);
    expect(responseBody['status'], 'available');
    expect(responseBody['requestId'], 'req-001');
    expect(forwarded['body'], _validBody());
    expect(forwarded['authorization'], 'Bearer adapter-token');
    expect(forwarded['requestId'], 'req-001');
    expect(forwarded['userId'], 'local-eatwhat-user');
  });

  test('网关验证吃什么 JWT 后转发可信用户身份', () async {
    const route = '/api/v1/delivery/oauth/status';
    final forwardedUserId = Completer<String?>();
    final upstream = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    servers.add(upstream);
    upstream.listen((request) async {
      forwardedUserId.complete(request.headers.value('x-eatwhat-user-id'));
      request.response
        ..headers.contentType = ContentType.json
        ..write(jsonEncode({'connected': false}));
      await request.response.close();
    });
    final proxyServer = await _startProxy(
      jwtSecret: 'jwt-secret',
      adapters: {
        route: ExecutionProxyAdapterConfig(
          route: route,
          platform: 'meituan',
          displayName: '美团外卖用户授权状态',
          upstreamUrl: 'http://127.0.0.1:${upstream.port}/oauth/status',
          requestKind: ExecutionProxyRequestKind.oauthStatus,
        ),
      },
      servers: servers,
      proxies: proxies,
    );
    final client = HttpClient();
    clients.add(client);
    final request = await client.getUrl(
      Uri.parse('http://127.0.0.1:${proxyServer.port}$route'),
    );
    request.headers.set(
      HttpHeaders.authorizationHeader,
      'Bearer ${_jwt('eatwhat-user-42', 'jwt-secret')}',
    );

    final response = await request.close();
    await _readResponse(response);

    expect(response.statusCode, HttpStatus.ok);
    expect(await forwardedUserId.future, 'eatwhat-user-42');
  });

  test('客户端不能通过请求头伪造吃什么用户身份', () async {
    const route = '/api/v1/delivery/oauth/status';
    final forwardedUserId = Completer<String?>();
    final upstream = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    servers.add(upstream);
    upstream.listen((request) async {
      forwardedUserId.complete(request.headers.value('x-eatwhat-user-id'));
      request.response
        ..headers.contentType = ContentType.json
        ..write(jsonEncode({'connected': false}));
      await request.response.close();
    });
    final proxyServer = await _startProxy(
      jwtSecret: 'jwt-secret',
      adapters: {
        route: ExecutionProxyAdapterConfig(
          route: route,
          platform: 'meituan',
          displayName: '美团外卖用户授权状态',
          upstreamUrl: 'http://127.0.0.1:${upstream.port}/oauth/status',
          requestKind: ExecutionProxyRequestKind.oauthStatus,
        ),
      },
      servers: servers,
      proxies: proxies,
    );
    final client = HttpClient();
    clients.add(client);
    final request = await client.getUrl(
      Uri.parse('http://127.0.0.1:${proxyServer.port}$route'),
    );
    request.headers
      ..set(
        HttpHeaders.authorizationHeader,
        'Bearer ${_jwt('trusted-user', 'jwt-secret')}',
      )
      ..set('x-eatwhat-user-id', 'forged-user');

    final response = await request.close();
    await _readResponse(response);

    expect(response.statusCode, HttpStatus.ok);
    expect(await forwardedUserId.future, 'trusted-user');
  });

  test('OAuth 路由不要求 dishName 或 geo', () async {
    const route = '/api/v1/delivery/oauth/authorize';
    final upstream = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    servers.add(upstream);
    upstream.listen((request) async {
      await utf8.decoder.bind(request).join();
      request.response
        ..headers.contentType = ContentType.json
        ..write(jsonEncode({'authorizationUrl': 'https://example.com/oauth'}));
      await request.response.close();
    });
    final proxyServer = await _startProxy(
      adapters: {
        route: ExecutionProxyAdapterConfig(
          route: route,
          platform: 'meituan',
          displayName: '美团外卖用户授权',
          upstreamUrl: 'http://127.0.0.1:${upstream.port}/oauth/authorize',
          requestKind: ExecutionProxyRequestKind.oauthAuthorize,
        ),
      },
      servers: servers,
      proxies: proxies,
    );
    final client = HttpClient();
    clients.add(client);

    final response = await _postJson(
      client,
      Uri.parse('http://127.0.0.1:${proxyServer.port}$route'),
      const {},
    );

    expect(response.statusCode, HttpStatus.ok);
    expect((await _readResponse(response))['authorizationUrl'], isNotEmpty);
  });

  test('未配置平台适配器时返回可识别的 503', () async {
    const route = '/v2/execution/jd-delivery/delivery-match';
    final proxyServer = await _startProxy(
      adapters: {
        route: const ExecutionProxyAdapterConfig(
          route: route,
          platform: 'jd_delivery',
          displayName: '京东外卖（秒送）',
          upstreamUrl: '',
        ),
      },
      servers: servers,
      proxies: proxies,
    );
    final client = HttpClient();
    clients.add(client);

    final response = await _postJson(
      client,
      Uri.parse('http://127.0.0.1:${proxyServer.port}$route'),
      _validBody(),
    );
    final body = await _readResponse(response);

    expect(response.statusCode, HttpStatus.serviceUnavailable);
    expect(body['status'], 'unavailable');
    expect(body['matches'], isEmpty);
    expect(
      (body['error'] as Map<String, dynamic>)['code'],
      'adapter_not_configured',
    );
  });

  test('上游权限错误会原样透传给客户端', () async {
    const route = '/api/v1/delivery/products/search';
    final upstream = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    servers.add(upstream);
    upstream.listen((request) async {
      await utf8.decoder.bind(request).join();
      request.response
        ..statusCode = HttpStatus.badGateway
        ..headers.contentType = ContentType.json
        ..write(
          jsonEncode({
            'error': {
              'code': 'meituan_permission_denied',
              'message': '无权访问该接口',
              'details': {'failCode': 1},
            },
          }),
        );
      await request.response.close();
    });
    final proxyServer = await _startProxy(
      adapters: {
        route: ExecutionProxyAdapterConfig(
          route: route,
          platform: 'meituan',
          displayName: '美团外卖菜品搜索',
          upstreamUrl: 'http://127.0.0.1:${upstream.port}/products',
          requestKind: ExecutionProxyRequestKind.productSearch,
        ),
      },
      servers: servers,
      proxies: proxies,
    );
    final client = HttpClient();
    clients.add(client);

    final response = await _postJson(
      client,
      Uri.parse('http://127.0.0.1:${proxyServer.port}$route'),
      {
        'merchantId': 'm1',
        'geo': {'latitude': 39.9, 'longitude': 116.4},
      },
    );
    final body = await _readResponse(response);

    expect(response.statusCode, HttpStatus.badGateway);
    expect(
      (body['error'] as Map<String, dynamic>)['code'],
      'meituan_permission_denied',
    );
    expect((body['error'] as Map<String, dynamic>)['message'], '无权访问该接口');
  });
}

Future<HttpServer> _startProxy({
  required Map<String, ExecutionProxyAdapterConfig> adapters,
  required List<HttpServer> servers,
  required List<ExecutionProxyServer> proxies,
  String requiredToken = '',
  String jwtSecret = '',
}) async {
  final proxy = ExecutionProxyServer(
    ExecutionProxyServerConfig(
      bindAddress: InternetAddress.loopbackIPv4,
      port: 0,
      requiredToken: requiredToken,
      jwtSecret: jwtSecret,
      upstreamTimeout: const Duration(seconds: 2),
      adapters: adapters,
    ),
  );
  final server = await proxy.start();
  servers.add(server);
  proxies.add(proxy);
  return server;
}

String _jwt(String userId, String secret) {
  String encode(Map<String, dynamic> value) =>
      base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');
  final header = encode({'alg': 'HS256', 'typ': 'JWT'});
  final payload = encode({
    'sub': userId,
    'type': 'access',
    'exp':
        DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch ~/
            1000,
  });
  final signature = base64Url
      .encode(Hmac(sha256, utf8.encode(secret))
          .convert(utf8.encode('$header.$payload'))
          .bytes)
      .replaceAll('=', '');
  return '$header.$payload.$signature';
}

Map<String, dynamic> _validBody() {
  return {
    'dishName': '麻婆豆腐',
    'geo': {
      'latitude': 39.9042,
      'longitude': 116.4074,
    },
    'limit': 10,
  };
}

Future<HttpClientResponse> _postJson(
  HttpClient client,
  Uri uri,
  Map<String, dynamic> body, {
  String? token,
  String? requestId,
}) async {
  final request = await client.postUrl(uri);
  request.headers.contentType = ContentType.json;
  if (token != null) {
    request.headers.set(HttpHeaders.authorizationHeader, 'Bearer $token');
  }
  if (requestId != null) {
    request.headers.set('x-request-id', requestId);
  }
  request.write(jsonEncode(body));
  return request.close();
}

Future<Map<String, dynamic>> _readResponse(HttpClientResponse response) async {
  return jsonDecode(await utf8.decoder.bind(response).join())
      as Map<String, dynamic>;
}
