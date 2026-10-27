import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../scripts/support/eatwhat_jwt.dart';
import '../../scripts/support/server_http.dart';

void main() {
  group('EatWhatJwt', () {
    final now = DateTime.utc(2026, 10, 1, 12);
    const secret = 'shared-server-jwt-secret';

    test('issues and verifies an access token with a real HS256 signature', () {
      final token = EatWhatJwt.issue(
        userId: 'user-42',
        expiresAt: now.add(const Duration(hours: 1)),
        secret: secret,
        now: () => now,
      );

      expect(
          EatWhatJwt.verify(token, secret: secret, now: () => now), 'user-42');
      final parts = token.split('.');
      expect(_decode(parts[0]), {'alg': 'HS256', 'typ': 'JWT'});
      expect(_decode(parts[1]), {
        'sub': 'user-42',
        'type': 'access',
        'iat': now.millisecondsSinceEpoch ~/ 1000,
        'exp': now.add(const Duration(hours: 1)).millisecondsSinceEpoch ~/ 1000,
      });
      final expectedSignature = base64Url
          .encode(
            Hmac(sha256, utf8.encode(secret))
                .convert(utf8.encode('${parts[0]}.${parts[1]}'))
                .bytes,
          )
          .replaceAll('=', '');
      expect(parts[2], expectedSignature);
    });

    test('rejects an empty secret when issuing a token', () {
      expect(
        () => EatWhatJwt.issue(
          userId: 'user-42',
          expiresAt: now.add(const Duration(hours: 1)),
          secret: '',
          now: () => now,
        ),
        throwsArgumentError,
      );
    });

    test('rejects a wrong or empty secret', () {
      final token = EatWhatJwt.issue(
        userId: 'user-42',
        expiresAt: now.add(const Duration(hours: 1)),
        secret: secret,
        now: () => now,
      );

      expect(EatWhatJwt.verify(token, secret: 'wrong-secret', now: () => now),
          isNull);
      expect(EatWhatJwt.verify(token, secret: '', now: () => now), isNull);
    });

    test('rejects an expired token', () {
      final token = EatWhatJwt.issue(
        userId: 'user-42',
        expiresAt: now,
        secret: secret,
        now: () => now.subtract(const Duration(hours: 1)),
      );

      expect(EatWhatJwt.verify(token, secret: secret, now: () => now), isNull);
    });

    test('rejects a correctly signed token with the wrong algorithm', () {
      final token = _signedToken(
        header: {'alg': 'HS512', 'typ': 'JWT'},
        payload: {
          'sub': 'user-42',
          'type': 'access',
          'exp':
              now.add(const Duration(hours: 1)).millisecondsSinceEpoch ~/ 1000,
        },
        secret: secret,
      );

      expect(EatWhatJwt.verify(token, secret: secret, now: () => now), isNull);
    });

    test('rejects a token without the access type', () {
      for (final type in ['refresh', null]) {
        final token = _signedToken(
          header: {'alg': 'HS256', 'typ': 'JWT'},
          payload: {
            'sub': 'user-42',
            if (type != null) 'type': type,
            'exp': now.add(const Duration(hours: 1)).millisecondsSinceEpoch ~/
                1000,
          },
          secret: secret,
        );

        expect(
            EatWhatJwt.verify(token, secret: secret, now: () => now), isNull);
      }
    });

    test('rejects an empty subject', () {
      final token = _signedToken(
        header: {'alg': 'HS256', 'typ': 'JWT'},
        payload: {
          'sub': '   ',
          'type': 'access',
          'exp':
              now.add(const Duration(hours: 1)).millisecondsSinceEpoch ~/ 1000,
        },
        secret: secret,
      );

      expect(EatWhatJwt.verify(token, secret: secret, now: () => now), isNull);
    });
  });

  group('server HTTP JSON responses', () {
    test('writes JSON success responses with the requested status', () async {
      final response = await _request(
        (response) => writeJsonResponse(
          response,
          HttpStatus.created,
          {'status': 'ok'},
        ),
      );

      expect(response.statusCode, HttpStatus.created);
      expect(response.contentType, ContentType.json.mimeType);
      expect(response.body, {'status': 'ok'});
    });

    test('writes requestId at top level and details inside error', () async {
      final response = await _request(
        (response) => writeJsonError(
          response,
          HttpStatus.badGateway,
          'upstream_failed',
          '上游不可用',
          requestId: 'request-42',
          details: {'failCode': 13001},
        ),
      );

      expect(response.statusCode, HttpStatus.badGateway);
      expect(response.contentType, ContentType.json.mimeType);
      expect(response.body, {
        'error': {
          'code': 'upstream_failed',
          'message': '上游不可用',
          'details': {'failCode': 13001},
        },
        'requestId': 'request-42',
      });
    });

    test('omits optional requestId and empty details', () async {
      final response = await _request(
        (response) => writeJsonError(
          response,
          HttpStatus.unauthorized,
          'unauthorized',
          '登录已失效',
        ),
      );

      expect(response.body, {
        'error': {'code': 'unauthorized', 'message': '登录已失效'},
      });
    });
  });
}

Map<String, dynamic> _decode(String value) => Map<String, dynamic>.from(
      jsonDecode(utf8.decode(base64Url.decode(base64Url.normalize(value))))
          as Map,
    );

String _signedToken({
  required Map<String, dynamic> header,
  required Map<String, dynamic> payload,
  required String secret,
}) {
  String encode(Map<String, dynamic> value) =>
      base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');
  final encodedHeader = encode(header);
  final encodedPayload = encode(payload);
  final signature = base64Url
      .encode(
        Hmac(sha256, utf8.encode(secret))
            .convert(utf8.encode('$encodedHeader.$encodedPayload'))
            .bytes,
      )
      .replaceAll('=', '');
  return '$encodedHeader.$encodedPayload.$signature';
}

Future<({int statusCode, String? contentType, Map<String, dynamic> body})>
    _request(
  Future<void> Function(HttpResponse response) handler,
) async {
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
  final client = HttpClient();
  try {
    server.listen((request) async => handler(request.response));
    final response = await client
        .getUrl(Uri.parse('http://127.0.0.1:${server.port}/'))
        .then((request) => request.close());
    final body = jsonDecode(await utf8.decoder.bind(response).join())
        as Map<String, dynamic>;
    return (
      statusCode: response.statusCode,
      contentType: response.headers.contentType?.mimeType,
      body: body,
    );
  } finally {
    client.close(force: true);
    await server.close(force: true);
  }
}
