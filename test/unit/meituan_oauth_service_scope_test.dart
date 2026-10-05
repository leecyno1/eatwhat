import 'dart:math';

import 'package:flutter_test/flutter_test.dart';

import '../../scripts/meituan_oauth_service.dart';
import '../../scripts/meituan_oauth_store.dart';

class _NoopStore implements MeituanOAuthStore {
  @override
  Future<MeituanOAuthCredential?> read(String eatWhatUserId) async => null;

  @override
  Future<void> write(
    String eatWhatUserId,
    MeituanOAuthCredential credential,
  ) async {}
}

MeituanOAuthService _service({String? scope}) {
  return MeituanOAuthService(
    MeituanOAuthConfig(
      appId: 'app-1',
      appSecret: 'secret-1',
      redirectUri: Uri.parse('https://example.com/oauth/callback'),
      apiBaseUrl: Uri.parse('https://openapi.waimai.meituan.com'),
      timeout: const Duration(seconds: 5),
      scope: scope ?? '',
    ),
    _NoopStore(),
    random: Random(7),
  );
}

void main() {
  group('MeituanOAuthService scope', () {
    test('默认 scope 为空串（官方文档口径）', () {
      final uri = _service().createAuthorizationUri('user-1');
      expect(uri.queryParameters['scope'], '');
    });

    test('环境变量覆盖的 scope 原样透传', () {
      final uri = _service(scope: 'custom_scope').createAuthorizationUri(
        'user-1',
      );
      expect(uri.queryParameters['scope'], 'custom_scope');
    });

    test('授权链接携带必需参数与一次性 state', () {
      final uri = _service().createAuthorizationUri('user-1');
      expect(uri.path, '/oauth/authorize');
      expect(uri.queryParameters['app_id'], 'app-1');
      expect(uri.queryParameters['response_type'], 'code');
      expect(
        uri.queryParameters['redirect_uri'],
        'https://example.com/oauth/callback',
      );
      expect(uri.queryParameters['state'], isNotEmpty);
    });
  });
}
