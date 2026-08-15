import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'meituan_oauth_store.dart';

class MeituanOAuthService {
  MeituanOAuthService(
    this.config,
    this.store, {
    HttpClient? httpClient,
    DateTime Function()? now,
    Random? random,
  })  : _httpClient = httpClient ?? HttpClient(),
        _now = now ?? DateTime.now,
        _random = random ?? Random.secure();

  final MeituanOAuthConfig config;
  final MeituanOAuthStore store;
  final HttpClient _httpClient;
  final DateTime Function() _now;
  final Random _random;
  final Map<String, _PendingOAuthState> _pendingStates = {};
  final Map<String, Future<MeituanOAuthCredential>> _refreshes = {};

  Uri createAuthorizationUri(String eatWhatUserId) {
    final state = _randomState();
    _pendingStates[state] = _PendingOAuthState(
      eatWhatUserId: eatWhatUserId,
      expiresAt: _now().add(const Duration(minutes: 10)),
    );
    return config.apiBaseUrl.resolve('/oauth/authorize').replace(
      queryParameters: {
        'app_id': config.appId,
        'redirect_uri': config.redirectUri.toString(),
        'response_type': 'code',
        'scope': '',
        'state': state,
      },
    );
  }

  Future<MeituanOAuthCredential> completeAuthorization({
    required String code,
    required String state,
  }) async {
    final pending = _pendingStates.remove(state);
    if (pending == null || _now().isAfter(pending.expiresAt)) {
      throw const MeituanOAuthException('oauth_state_invalid', '授权状态已失效，请重新绑定');
    }
    final tokenPayload = await _getJson(
      config.apiBaseUrl.resolve('/oauth/access_token').replace(
        queryParameters: {
          'app_id': config.appId,
          'secret': config.appSecret,
          'code': code,
          'grant_type': 'authorization_code',
        },
      ),
    );
    final accessToken = _required(tokenPayload, 'access_token');
    final refreshToken = _required(tokenPayload, 'refresh_token');
    final expiresIn = _int(tokenPayload['expires_in'], fallback: 7200);
    final user = await _loadUserInfo(accessToken);
    final credential = MeituanOAuthCredential(
      accessToken: accessToken,
      refreshToken: refreshToken,
      openId: user['openid']?.toString() ?? '',
      nickname: user['nickname']?.toString(),
      maskedPhone: user['desensitization_phone']?.toString(),
      expiresAt: _now().add(Duration(seconds: expiresIn)),
    );
    await store.write(pending.eatWhatUserId, credential);
    return credential;
  }

  Future<MeituanOAuthCredential?> credentialFor(String eatWhatUserId) async {
    final credential = await store.read(eatWhatUserId);
    if (credential == null) return null;
    if (!credential.isExpired) return credential;
    if (credential.refreshToken.isEmpty) return null;
    return _refreshes.putIfAbsent(eatWhatUserId, () async {
      try {
        return await _refresh(eatWhatUserId, credential);
      } finally {
        await Future<void>.microtask(() {
          _refreshes.remove(eatWhatUserId);
        });
      }
    });
  }

  Future<MeituanOAuthCredential> _refresh(
    String eatWhatUserId,
    MeituanOAuthCredential current,
  ) async {
    final payload = await _getJson(
      config.apiBaseUrl.resolve('/oauth/refresh_token').replace(
        queryParameters: {
          'app_id': config.appId,
          'secret': config.appSecret,
          'refresh_token': current.refreshToken,
          'grant_type': 'refresh_token',
        },
      ),
    );
    final refreshed = MeituanOAuthCredential(
      accessToken: _required(payload, 'access_token'),
      refreshToken:
          payload['refresh_token']?.toString().trim().isNotEmpty == true
              ? payload['refresh_token'].toString()
              : current.refreshToken,
      openId: current.openId,
      nickname: current.nickname,
      maskedPhone: current.maskedPhone,
      expiresAt: _now().add(
        Duration(seconds: _int(payload['expires_in'], fallback: 7200)),
      ),
    );
    await store.write(eatWhatUserId, refreshed);
    return refreshed;
  }

  Future<Map<String, dynamic>> _loadUserInfo(String accessToken) {
    return _getJson(
      config.apiBaseUrl.resolve('/oauth/userinfo').replace(
        queryParameters: {
          'app_id': config.appId,
          'secret': config.appSecret,
          'access_token': accessToken,
        },
      ),
    );
  }

  Future<Map<String, dynamic>> _getJson(Uri uri) async {
    final request = await _httpClient.getUrl(uri).timeout(config.timeout);
    final response = await request.close().timeout(config.timeout);
    final raw =
        await utf8.decoder.bind(response).join().timeout(config.timeout);
    if (response.statusCode < 200 || response.statusCode >= 300) {
      throw MeituanOAuthException(
        'meituan_oauth_http_error',
        '美团授权服务 HTTP ${response.statusCode}',
      );
    }
    final decoded = jsonDecode(raw);
    if (decoded is! Map) {
      throw const MeituanOAuthException('meituan_oauth_invalid', '美团授权返回格式错误');
    }
    final payload = Map<String, dynamic>.from(decoded);
    if (payload['error_code'] != null || payload['error'] != null) {
      throw MeituanOAuthException(
        payload['error_code']?.toString() ?? 'meituan_oauth_failed',
        payload['error_msg']?.toString() ??
            payload['erroe_msg']?.toString() ??
            payload['error_description']?.toString() ??
            '美团授权失败',
      );
    }
    return payload;
  }

  String _randomState() {
    final bytes = List<int>.generate(24, (_) => _random.nextInt(256));
    return base64UrlEncode(bytes).replaceAll('=', '');
  }

  void close() => _httpClient.close(force: true);
}

class MeituanOAuthConfig {
  const MeituanOAuthConfig({
    required this.appId,
    required this.appSecret,
    required this.redirectUri,
    required this.apiBaseUrl,
    required this.timeout,
  });

  final String appId;
  final String appSecret;
  final Uri redirectUri;
  final Uri apiBaseUrl;
  final Duration timeout;

  bool get isConfigured =>
      appId.isNotEmpty && appSecret.isNotEmpty && redirectUri.hasScheme;
}

class MeituanOAuthException implements Exception {
  const MeituanOAuthException(this.code, this.message);

  final String code;
  final String message;
}

class _PendingOAuthState {
  const _PendingOAuthState(
      {required this.eatWhatUserId, required this.expiresAt});

  final String eatWhatUserId;
  final DateTime expiresAt;
}

String _required(Map<String, dynamic> json, String key) {
  final value = json[key]?.toString().trim() ?? '';
  if (value.isEmpty) {
    throw MeituanOAuthException('meituan_oauth_invalid', '$key 不能为空');
  }
  return value;
}

int _int(dynamic value, {required int fallback}) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}
