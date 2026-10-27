import 'dart:convert';

import 'package:crypto/crypto.dart';

class EatWhatJwt {
  const EatWhatJwt._();

  static String issue({
    required String userId,
    required DateTime expiresAt,
    required String secret,
    DateTime Function()? now,
  }) {
    if (secret.isEmpty) {
      throw ArgumentError.value(
        secret,
        'secret',
        'JWT signing secret must not be empty',
      );
    }
    final header = _encode({'alg': 'HS256', 'typ': 'JWT'});
    final payload = _encode({
      'sub': userId,
      'type': 'access',
      'iat': (now ?? DateTime.now)().toUtc().millisecondsSinceEpoch ~/ 1000,
      'exp': expiresAt.millisecondsSinceEpoch ~/ 1000,
    });
    final signature = _base64(
      Hmac(sha256, utf8.encode(secret))
          .convert(utf8.encode('$header.$payload'))
          .bytes,
    );
    return '$header.$payload.$signature';
  }

  static String? verify(
    String token, {
    required String secret,
    DateTime Function()? now,
  }) {
    try {
      final parts = token.split('.');
      if (parts.length != 3 || secret.isEmpty) return null;
      final header = _decode(parts[0]);
      final payload = _decode(parts[1]);
      if (header['alg'] != 'HS256' || payload['type'] != 'access') return null;

      final expected = Hmac(sha256, utf8.encode(secret))
          .convert(utf8.encode('${parts[0]}.${parts[1]}'))
          .bytes;
      final actual = base64Url.decode(base64Url.normalize(parts[2]));
      if (!constantTimeEquals(expected, actual)) return null;

      final expiresAt = _int(payload['exp']);
      final nowSeconds = (now ?? DateTime.now)().millisecondsSinceEpoch ~/ 1000;
      if (expiresAt == null || expiresAt <= nowSeconds) return null;
      final userId = payload['sub']?.toString().trim() ?? '';
      return userId.isEmpty ? null : userId;
    } on Object {
      return null;
    }
  }

  static bool constantTimeEquals(List<int> left, List<int> right) {
    if (left.length != right.length) return false;
    var difference = 0;
    for (var index = 0; index < left.length; index++) {
      difference |= left[index] ^ right[index];
    }
    return difference == 0;
  }

  static Map<String, dynamic> _decode(String value) {
    final decoded = jsonDecode(
      utf8.decode(base64Url.decode(base64Url.normalize(value))),
    );
    if (decoded is! Map) throw const FormatException('Invalid JWT JSON');
    return Map<String, dynamic>.from(decoded);
  }

  static String _encode(Map<String, dynamic> json) =>
      _base64(utf8.encode(jsonEncode(json)));

  static String _base64(List<int> bytes) =>
      base64Url.encode(bytes).replaceAll('=', '');

  static int? _int(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '');
  }
}
