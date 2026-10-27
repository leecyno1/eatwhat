import 'dart:convert';
import 'dart:io';

import 'package:eatwhat_app/core/services/auth_service.dart';
import 'package:eatwhat_app/v2/core/external/platform/execution_proxy_client.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  test('ExecutionProxyClient 读取生产平台健康状态', () async {
    String? authorization;
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));
    server.listen((request) async {
      authorization = request.headers.value(HttpHeaders.authorizationHeader);
      request.response
        ..statusCode = HttpStatus.ok
        ..headers.contentType = ContentType.json
        ..write(
          jsonEncode({
            'status': 'ok',
            'providers': {
              'meituan': true,
              'eleme': false,
            },
          }),
        );
      await request.response.close();
    });
    final client = ExecutionProxyClient(
      baseUrl: 'http://127.0.0.1:${server.port}',
      authToken: 'client-token',
      serviceToken: '',
    );

    final result = await client.getProviderHealth();

    expect(result, {'meituan': true, 'eleme': false});
    expect(authorization, 'Bearer client-token');
  });

  test('ExecutionProxyClient 分开发送用户 JWT 和网关服务令牌', () async {
    String? authorization;
    String? serviceToken;
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));
    server.listen((request) async {
      authorization = request.headers.value(HttpHeaders.authorizationHeader);
      serviceToken = request.headers.value('x-execution-proxy-token');
      await utf8.decoder.bind(request).join();
      request.response
        ..headers.contentType = ContentType.json
        ..write(jsonEncode({'status': 'ok'}));
      await request.response.close();
    });
    final client = ExecutionProxyClient(
      baseUrl: 'http://127.0.0.1:${server.port}',
      authToken: 'eatwhat-user-jwt',
      serviceToken: 'proxy-service-token',
    );

    await client.postJson('/orders');

    expect(authorization, 'Bearer eatwhat-user-jwt');
    expect(serviceToken, 'proxy-service-token');
  });

  test('本地会话令牌不会作为执行代理用户身份发送', () async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    dotenv.testLoad();
    addTearDown(dotenv.clean);
    addTearDown(AuthService.logout);
    final registered = await AuthService.register(
      username: 'local_proxy',
      email: 'local@example.com',
      password: 'LocalPass123',
      confirmPassword: 'LocalPass123',
    );
    expect(registered.success, isTrue);
    expect(AuthService.authToken, isNotNull);

    String? authorization;
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));
    server.listen((request) async {
      authorization = request.headers.value(HttpHeaders.authorizationHeader);
      request.response
        ..headers.contentType = ContentType.json
        ..write(jsonEncode({'status': 'ok', 'providers': {}}));
      await request.response.close();
    });
    final client = ExecutionProxyClient(
      baseUrl: 'http://127.0.0.1:${server.port}',
      serviceToken: '',
    );

    await client.getProviderHealth();

    expect(authorization, isNull);
  });

  test('远程会话令牌继续作为执行代理用户身份发送', () async {
    SharedPreferences.setMockInitialValues({});
    FlutterSecureStorage.setMockInitialValues({});
    final now = DateTime.now().toUtc();
    final authServer = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => authServer.close(force: true));
    authServer.listen((request) async {
      await utf8.decoder.bind(request).join();
      request.response
        ..headers.contentType = ContentType.json
        ..write(
          jsonEncode({
            'accessToken': 'remote-access-token',
            'expiresAt': now.add(const Duration(hours: 1)).toIso8601String(),
            'user': {
              'id': 'remote-user-1',
              'username': 'remote_user',
              'email': 'remote@example.com',
              'nickname': '远程用户',
              'createdAt': now.toIso8601String(),
              'lastLoginAt': now.toIso8601String(),
            },
          }),
        );
      await request.response.close();
    });
    dotenv.testLoad(
      fileInput: 'EATWHAT_AUTH_BASE_URL=http://127.0.0.1:${authServer.port}',
    );
    addTearDown(dotenv.clean);
    addTearDown(AuthService.logout);
    final loggedIn = await AuthService.login(
      usernameOrEmail: 'remote@example.com',
      password: 'RemotePass123',
      rememberMe: true,
    );
    expect(loggedIn.success, isTrue);
    final updated = await AuthService.updateCurrentUser(
      loggedIn.user!.copyWith(nickname: '更新后的远程用户'),
    );
    expect(updated, isTrue);
    expect(AuthService.authToken, 'remote-access-token');

    String? authorization;
    final proxyServer = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => proxyServer.close(force: true));
    proxyServer.listen((request) async {
      authorization = request.headers.value(HttpHeaders.authorizationHeader);
      request.response
        ..headers.contentType = ContentType.json
        ..write(jsonEncode({'status': 'ok', 'providers': {}}));
      await request.response.close();
    });
    final client = ExecutionProxyClient(
      baseUrl: 'http://127.0.0.1:${proxyServer.port}',
      serviceToken: '',
    );

    await client.getProviderHealth();

    expect(authorization, 'Bearer remote-access-token');
  });
}
