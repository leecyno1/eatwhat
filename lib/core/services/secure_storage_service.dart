import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:eatwhat_app/v2/core/external/storage/flutter_secure_store.dart';
import 'package:eatwhat_app/v2/core/ports/secure_store.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../config/env_config.dart';

class SecureStorageService {
  static const String _keyPrefix = 'secure_';
  static const String _ivPrefix = 'iv_';
  static const SecureStore _store = FlutterSecureStore();

  static Future<bool> setSecureString(String key, String value) async {
    try {
      await _store.write(key: _nativeKey(key), value: value);
      await _removeLegacyValue(key);
      return true;
    } catch (error) {
      debugPrint('Secure storage write failed: $error');
      return false;
    }
  }

  static Future<String?> getSecureString(String key) async {
    try {
      final stored = await _store.read(key: _nativeKey(key));
      if (stored != null) return stored;

      final legacy = await _readLegacyValue(key);
      if (legacy == null) return null;

      await _store.write(key: _nativeKey(key), value: legacy);
      await _removeLegacyValue(key);
      return legacy;
    } catch (error) {
      debugPrint('Secure storage read failed: $error');
      return null;
    }
  }

  static Future<bool> removeSecureString(String key) async {
    try {
      await _store.delete(key: _nativeKey(key));
      await _removeLegacyValue(key);
      return true;
    } catch (error) {
      debugPrint('Secure storage delete failed: $error');
      return false;
    }
  }

  static Future<bool> containsSecureKey(String key) async {
    try {
      if (await _store.containsKey(key: _nativeKey(key))) return true;
      final prefs = await SharedPreferences.getInstance();
      return prefs.containsKey(_keyPrefix + key) &&
          prefs.containsKey(_ivPrefix + key);
    } catch (_) {
      return false;
    }
  }

  static Future<bool> setSecureJson(
    String key,
    Map<String, dynamic> value,
  ) {
    return setSecureString(key, json.encode(value));
  }

  static Future<Map<String, dynamic>?> getSecureJson(String key) async {
    final jsonString = await getSecureString(key);
    if (jsonString == null) return null;

    try {
      return json.decode(jsonString) as Map<String, dynamic>;
    } catch (error) {
      debugPrint('Secure JSON decode failed: $error');
      return null;
    }
  }

  static Future<bool> clearAllSecureData() async {
    try {
      final storedValues = await _store.readAll();
      final storedKeys =
          storedValues.keys.where((key) => key.startsWith(_keyPrefix)).toList();
      for (final key in storedKeys) {
        await _store.delete(key: key);
      }

      final prefs = await SharedPreferences.getInstance();
      final legacyKeys = prefs
          .getKeys()
          .where(
            (key) => key.startsWith(_keyPrefix) || key.startsWith(_ivPrefix),
          )
          .toList();
      for (final key in legacyKeys) {
        await prefs.remove(key);
      }
      return true;
    } catch (error) {
      debugPrint('Secure storage clear failed: $error');
      return false;
    }
  }

  static Future<List<String>> getSecureKeys() async {
    try {
      final storedValues = await _store.readAll();
      final prefs = await SharedPreferences.getInstance();
      return <String>{
        ...storedValues.keys
            .where((key) => key.startsWith(_keyPrefix))
            .map((key) => key.substring(_keyPrefix.length)),
        ...prefs
            .getKeys()
            .where((key) => key.startsWith(_keyPrefix))
            .map((key) => key.substring(_keyPrefix.length)),
      }.toList();
    } catch (_) {
      return [];
    }
  }

  static String _nativeKey(String key) => _keyPrefix + key;

  static Future<void> _removeLegacyValue(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyPrefix + key);
    await prefs.remove(_ivPrefix + key);
  }

  static Future<String?> _readLegacyValue(String key) async {
    final prefs = await SharedPreferences.getInstance();
    final ciphertext = prefs.getString(_keyPrefix + key);
    final iv = prefs.getString(_ivPrefix + key);
    if (ciphertext == null || iv == null) return null;
    return _legacyDecrypt(ciphertext, iv);
  }

  // 仅用于迁移升级前的 XOR 数据，绝不再用该格式写入新值。
  static String _legacyDecrypt(String ciphertext, String iv) {
    final key = _deriveLegacyKey();
    final encrypted = base64Decode(ciphertext);
    final decrypted = _LegacyCipher(key, base64Decode(iv)).process(encrypted);
    return utf8.decode(decrypted);
  }

  static Uint8List _deriveLegacyKey() {
    final hmac = Hmac(sha256, utf8.encode(EnvConfig.encryptionKey));
    var key = hmac.convert(utf8.encode('eatwhat_salt_2024')).bytes;
    for (var i = 0; i < 1000; i++) {
      key = hmac.convert(key).bytes;
    }
    return Uint8List.fromList(key);
  }
}

class _LegacyCipher {
  _LegacyCipher(this._key, this._iv);

  final Uint8List _key;
  final Uint8List _iv;

  Uint8List process(List<int> data) {
    final result = Uint8List(data.length);
    final state = List<int>.from(_iv);
    for (var i = 0; i < data.length; i++) {
      state[i % state.length] =
          (state[i % state.length] + _key[i % _key.length]) % 256;
      result[i] = data[i] ^ state[i % state.length];
    }
    return result;
  }
}
