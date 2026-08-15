import 'dart:convert';
import 'dart:io';

import 'package:eatwhat_app/v2/core/external/platform/execution_proxy_client.dart';
import 'package:flutter_test/flutter_test.dart';

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
}
