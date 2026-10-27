import 'dart:convert';
import 'dart:typed_data';

import 'package:crypto/crypto.dart';
import 'package:eatwhat_app/core/config/env_config.dart';
import 'package:eatwhat_app/core/services/secure_storage_service.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('SecureStorageService 原生存储与迁移', () {
    late Map<String, String> nativeValues;

    setUp(() {
      SharedPreferences.setMockInitialValues({});
      nativeValues = <String, String>{};
      FlutterSecureStorage.setMockInitialValues(nativeValues);
    });

    test('新值只写原生安全存储，不落地普通偏好存储', () async {
      final saved = await SecureStorageService.setSecureString(
        'user_token',
        'remote-access-token',
      );

      expect(saved, isTrue);
      expect(nativeValues['secure_user_token'], 'remote-access-token');
      final prefs = await SharedPreferences.getInstance();
      expect(
        prefs.getKeys().where(
              (key) => key.startsWith('secure_') || key.startsWith('iv_'),
            ),
        isEmpty,
      );
      expect(
        await SecureStorageService.getSecureString('user_token'),
        'remote-access-token',
      );
    });

    test('读取旧 XOR 值后迁移到原生存储并清理旧副本', () async {
      final legacy = _legacyEncrypt('legacy-remote-token');
      SharedPreferences.setMockInitialValues({
        'secure_user_token': legacy['ciphertext']!,
        'iv_user_token': legacy['iv']!,
      });

      expect(
        await SecureStorageService.getSecureString('user_token'),
        'legacy-remote-token',
      );
      expect(nativeValues['secure_user_token'], 'legacy-remote-token');
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.containsKey('secure_user_token'), isFalse);
      expect(prefs.containsKey('iv_user_token'), isFalse);
    });
  });
}

Map<String, String> _legacyEncrypt(String plaintext) {
  final hmac = Hmac(sha256, utf8.encode(EnvConfig.encryptionKey));
  var key = hmac.convert(utf8.encode('eatwhat_salt_2024')).bytes;
  for (var i = 0; i < 1000; i++) {
    key = hmac.convert(key).bytes;
  }

  final iv = Uint8List.fromList(List<int>.generate(16, (index) => index));
  final data = utf8.encode(plaintext);
  final encrypted = Uint8List(data.length);
  final state = List<int>.from(iv);
  for (var i = 0; i < data.length; i++) {
    state[i % state.length] =
        (state[i % state.length] + key[i % key.length]) % 256;
    encrypted[i] = data[i] ^ state[i % state.length];
  }
  return {
    'ciphertext': base64Encode(encrypted),
    'iv': base64Encode(iv),
  };
}
