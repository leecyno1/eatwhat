import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../scripts/eatwhat_auth_server.dart';
import '../../scripts/execution_proxy_server.dart';

void main() {
  test('吃什么后端注册登录并签发可被执行网关验证的 JWT', () async {
    final temporary = await Directory.systemTemp.createTemp('eatwhat-auth-');
    addTearDown(() => temporary.delete(recursive: true));
    const secret = 'eatwhat-test-jwt-secret-at-least-32-characters';
    final auth = EatWhatAuthServer(
      EatWhatAuthServerConfig(
        bindAddress: InternetAddress.loopbackIPv4,
        port: 0,
        jwtSecret: secret,
        storePath: '${temporary.path}/users.json',
      ),
    );
    final server = await auth.start();
    addTearDown(() => server.close(force: true));
    final client = HttpClient();
    addTearDown(() => client.close(force: true));

    final registered = await _post(
      client,
      Uri.parse('http://127.0.0.1:${server.port}/api/v1/auth/register'),
      {
        'username': 'eatwhat_user',
        'email': 'user@eatwhat.test',
        'password': 'StrongPass123',
        'nickname': '吃什么用户',
      },
    );
    expect(registered.statusCode, HttpStatus.created);
    final registeredBody = await _body(registered);
    final token = registeredBody['accessToken'] as String;
    final user = registeredBody['user'] as Map<String, dynamic>;
    expect(
      EatWhatJwtVerifier.verify(token, secret: secret),
      user['id'],
    );

    final sessionRequest = await client.getUrl(
      Uri.parse('http://127.0.0.1:${server.port}/api/v1/auth/session'),
    );
    sessionRequest.headers.set(
      HttpHeaders.authorizationHeader,
      'Bearer $token',
    );
    final session = await sessionRequest.close();
    expect(session.statusCode, HttpStatus.ok);
    expect(((await _body(session))['user'] as Map)['id'], user['id']);

    final login = await _post(
      client,
      Uri.parse('http://127.0.0.1:${server.port}/api/v1/auth/login'),
      {
        'account': 'user@eatwhat.test',
        'password': 'StrongPass123',
      },
    );
    expect(login.statusCode, HttpStatus.ok);
    expect((await _body(login))['accessToken'], isNotEmpty);

    final adapter = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => adapter.close(force: true));
    final forwardedUserId = Completer<String?>();
    adapter.listen((request) async {
      forwardedUserId.complete(request.headers.value('x-eatwhat-user-id'));
      request.response
        ..headers.contentType = ContentType.json
        ..write(jsonEncode({'connected': false}));
      await request.response.close();
    });
    const route = '/api/v1/delivery/oauth/status';
    final proxy = ExecutionProxyServer(
      ExecutionProxyServerConfig(
        bindAddress: InternetAddress.loopbackIPv4,
        port: 0,
        requiredToken: '',
        jwtSecret: secret,
        upstreamTimeout: const Duration(seconds: 2),
        adapters: {
          route: ExecutionProxyAdapterConfig(
            route: route,
            platform: 'meituan',
            displayName: '美团外卖用户授权状态',
            upstreamUrl: 'http://127.0.0.1:${adapter.port}/oauth/status',
            requestKind: ExecutionProxyRequestKind.oauthStatus,
          ),
        },
      ),
    );
    final proxyServer = await proxy.start();
    addTearDown(() async {
      await proxyServer.close(force: true);
      proxy.close();
    });
    final gatewayRequest = await client.getUrl(
      Uri.parse('http://127.0.0.1:${proxyServer.port}$route'),
    );
    gatewayRequest.headers.set(
      HttpHeaders.authorizationHeader,
      'Bearer $token',
    );
    final gatewayResponse = await gatewayRequest.close();
    expect(gatewayResponse.statusCode, HttpStatus.ok);
    await _body(gatewayResponse);
    expect(await forwardedUserId.future, user['id']);
  });

  test('重复账号被拒绝', () async {
    final temporary = await Directory.systemTemp.createTemp('eatwhat-auth-');
    addTearDown(() => temporary.delete(recursive: true));
    final auth = EatWhatAuthServer(
      EatWhatAuthServerConfig(
        bindAddress: InternetAddress.loopbackIPv4,
        port: 0,
        jwtSecret: 'eatwhat-test-jwt-secret-at-least-32-characters',
        storePath: '${temporary.path}/users.json',
      ),
    );
    final server = await auth.start();
    addTearDown(() => server.close(force: true));
    final client = HttpClient();
    addTearDown(() => client.close(force: true));
    final uri = Uri.parse(
      'http://127.0.0.1:${server.port}/api/v1/auth/register',
    );
    final body = {
      'username': 'eatwhat_user',
      'email': 'user@eatwhat.test',
      'password': 'StrongPass123',
    };

    await _body(await _post(client, uri, body));
    final duplicate = await _post(client, uri, body);

    expect(duplicate.statusCode, HttpStatus.conflict);
    expect(
      ((await _body(duplicate))['error'] as Map<String, dynamic>)['code'],
      'account_exists',
    );
  });

  test('无效 JWT 不能恢复吃什么会话', () async {
    final temporary = await Directory.systemTemp.createTemp('eatwhat-auth-');
    addTearDown(() => temporary.delete(recursive: true));
    final auth = EatWhatAuthServer(
      EatWhatAuthServerConfig(
        bindAddress: InternetAddress.loopbackIPv4,
        port: 0,
        jwtSecret: 'eatwhat-test-jwt-secret-at-least-32-characters',
        storePath: '${temporary.path}/users.json',
      ),
    );
    final server = await auth.start();
    addTearDown(() => server.close(force: true));
    final client = HttpClient();
    addTearDown(() => client.close(force: true));

    final request = await client.getUrl(
      Uri.parse('http://127.0.0.1:${server.port}/api/v1/auth/session'),
    );
    request.headers.set(HttpHeaders.authorizationHeader, 'Bearer invalid');
    final response = await request.close();

    expect(response.statusCode, HttpStatus.unauthorized);
    expect(
      ((await _body(response))['error'] as Map<String, dynamic>)['code'],
      'unauthorized',
    );
  });
}

Future<HttpClientResponse> _post(
  HttpClient client,
  Uri uri,
  Map<String, dynamic> body,
) async {
  final request = await client.postUrl(uri);
  request.headers.contentType = ContentType.json;
  request.write(jsonEncode(body));
  return request.close();
}

Future<Map<String, dynamic>> _body(HttpClientResponse response) async {
  return jsonDecode(await utf8.decoder.bind(response).join())
      as Map<String, dynamic>;
}
