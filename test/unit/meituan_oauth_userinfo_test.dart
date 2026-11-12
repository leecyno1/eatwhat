import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../scripts/meituan_oauth_service.dart';
import '../../scripts/meituan_oauth_store.dart';

void main() {
  test('OAuth 回调用 POST 读取 userinfo 并保存凭证', () async {
    final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => server.close(force: true));
    server.listen((request) async {
      if (request.uri.path == '/oauth/access_token') {
        expect(request.method, 'GET');
        request.response.headers.contentType = ContentType.json;
        request.response.write(
          jsonEncode({
            'access_token': 'token-1',
            'refresh_token': 'refresh-1',
            'expires_in': 7200,
          }),
        );
      } else if (request.uri.path == '/oauth/userinfo') {
        expect(request.method, 'POST');
        final body = await utf8.decoder.bind(request).join();
        final params = Uri.splitQueryString(body);
        expect(params['app_id'], 'app-id');
        expect(params['secret'], 'app-secret');
        expect(params['access_token'], 'token-1');
        request.response.headers.contentType = ContentType.json;
        request.response.write(
          jsonEncode({
            'openid': 'openid-1',
            'nickname': '测试用户',
            'desensitization_phone': '138****0000',
          }),
        );
      } else {
        request.response.statusCode = HttpStatus.notFound;
      }
      await request.response.close();
    });

    final store = _MemoryStore();
    final service = MeituanOAuthService(
      MeituanOAuthConfig(
        appId: 'app-id',
        appSecret: 'app-secret',
        redirectUri: Uri.parse('https://example.com/callback'),
        apiBaseUrl: Uri.parse('http://127.0.0.1:${server.port}'),
        timeout: const Duration(seconds: 5),
      ),
      store,
    );
    addTearDown(service.close);

    final authorizationUri = service.createAuthorizationUri('user-1');
    final state = authorizationUri.queryParameters['state'];
    expect(state, isNotEmpty);

    final credential = await service.completeAuthorization(
      code: 'code-1',
      state: state!,
    );

    expect(credential.accessToken, 'token-1');
    expect(credential.refreshToken, 'refresh-1');
    expect(credential.openId, 'openid-1');
    expect(credential.nickname, '测试用户');
    expect(credential.maskedPhone, '138****0000');
    expect(store.saved?.accessToken, 'token-1');
  });
}

class _MemoryStore implements MeituanOAuthStore {
  MeituanOAuthCredential? saved;

  @override
  Future<MeituanOAuthCredential?> read(String eatWhatUserId) async => saved;

  @override
  Future<void> write(
    String eatWhatUserId,
    MeituanOAuthCredential credential,
  ) async {
    saved = credential;
  }
}
