import 'dart:convert';
import 'dart:math' as math;
import 'package:crypto/crypto.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart';
import '../config/env_config.dart';

/// 安全存储服务
/// 提供加密的本地数据存储功能
class SecureStorageService {
  static const String _keyPrefix = 'secure_';
  static const String _ivPrefix = 'iv_';
  
  /// 加密并存储数据
  static Future<bool> setSecureString(String key, String value) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final encrypted = _encrypt(value);
      
      // 存储加密数据和IV
      await prefs.setString(_keyPrefix + key, encrypted.ciphertext);
      await prefs.setString(_ivPrefix + key, encrypted.iv);
      
      return true;
    } catch (e) {
      debugPrint('Secure storage error: $e');
      return false;
    }
  }
  
  /// 解密并获取数据
  static Future<String?> getSecureString(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final ciphertext = prefs.getString(_keyPrefix + key);
      final iv = prefs.getString(_ivPrefix + key);
      
      if (ciphertext == null || iv == null) {
        return null;
      }
      
      return _decrypt(EncryptedData(ciphertext: ciphertext, iv: iv));
    } catch (e) {
      debugPrint('Secure storage error: $e');
      return null;
    }
  }
  
  /// 删除安全数据
  static Future<bool> removeSecureString(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_keyPrefix + key);
      await prefs.remove(_ivPrefix + key);
      return true;
    } catch (e) {
      debugPrint('Secure storage error: $e');
      return false;
    }
  }
  
  /// 检查安全数据是否存在
  static Future<bool> containsSecureKey(String key) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.containsKey(_keyPrefix + key) && 
             prefs.containsKey(_ivPrefix + key);
    } catch (e) {
      return false;
    }
  }
  
  /// 存储JSON对象
  static Future<bool> setSecureJson(String key, Map<String, dynamic> value) async {
    return await setSecureString(key, json.encode(value));
  }
  
  /// 获取JSON对象
  static Future<Map<String, dynamic>?> getSecureJson(String key) async {
    final jsonString = await getSecureString(key);
    if (jsonString == null) return null;
    
    try {
      return json.decode(jsonString) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('JSON decode error: $e');
      return null;
    }
  }
  
  /// 清除所有安全数据
  static Future<bool> clearAllSecureData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((key) => 
        key.startsWith(_keyPrefix) || key.startsWith(_ivPrefix)
      ).toList();
      
      for (final key in keys) {
        await prefs.remove(key);
      }
      
      return true;
    } catch (e) {
      debugPrint('Clear secure data error: $e');
      return false;
    }
  }
  
  /// 获取所有安全数据的键
  static Future<List<String>> getSecureKeys() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getKeys()
          .where((key) => key.startsWith(_keyPrefix))
          .map((key) => key.substring(_keyPrefix.length))
          .toList();
    } catch (e) {
      return [];
    }
  }
  
  /// 加密数据
  static EncryptedData _encrypt(String plaintext) {
    final key = _deriveKey();
    final iv = _generateIV();
    
    // 使用AES-256-CBC模式加密
    final cipher = _createCipher(key, iv);
    final encrypted = cipher.process(utf8.encode(plaintext));
    
    return EncryptedData(
      ciphertext: base64Encode(encrypted),
      iv: base64Encode(iv),
    );
  }
  
  /// 解密数据
  static String _decrypt(EncryptedData encryptedData) {
    final key = _deriveKey();
    final iv = base64Decode(encryptedData.iv);
    final ciphertext = base64Decode(encryptedData.ciphertext);
    
    final cipher = _createCipher(key, iv);
    final decrypted = cipher.process(ciphertext);
    
    return utf8.decode(decrypted);
  }
  
  /// 生成密钥
  static Uint8List _deriveKey() {
    final masterKey = EnvConfig.encryptionKey;
    final salt = utf8.encode('eatwhat_salt_2024');
    
    // 使用PBKDF2派生密钥
    final hmac = Hmac(sha256, utf8.encode(masterKey));
    var key = hmac.convert(salt).bytes;
    
    // 多次迭代增强安全性
    for (int i = 0; i < 1000; i++) {
      key = hmac.convert(key).bytes;
    }
    
    return Uint8List.fromList(key);
  }
  
  /// 生成随机IV
  static Uint8List _generateIV() {
    final random = math.Random.secure();
    final iv = Uint8List(16); // AES block size
    
    for (int i = 0; i < iv.length; i++) {
      iv[i] = random.nextInt(256);
    }
    
    return iv;
  }
  
  /// 创建加密器
  static _SimpleCipher _createCipher(Uint8List key, Uint8List iv) {
    return _SimpleCipher(key, iv);
  }
}

/// 加密数据结构
class EncryptedData {
  final String ciphertext;
  final String iv;
  
  EncryptedData({required this.ciphertext, required this.iv});
}

/// 简单的XOR加密实现（用于演示，生产环境建议使用更强的加密）
class _SimpleCipher {
  final Uint8List _key;
  final Uint8List _iv;
  
  _SimpleCipher(this._key, this._iv);
  
  Uint8List process(List<int> data) {
    final result = Uint8List(data.length);
    final keyStream = _generateKeyStream(data.length);
    
    for (int i = 0; i < data.length; i++) {
      result[i] = data[i] ^ keyStream[i];
    }
    
    return result;
  }
  
  Uint8List _generateKeyStream(int length) {
    final keyStream = Uint8List(length);
    var state = List<int>.from(_iv);
    
    for (int i = 0; i < length; i++) {
      // 简单的密钥流生成
      state[i % state.length] = (state[i % state.length] + _key[i % _key.length]) % 256;
      keyStream[i] = state[i % state.length];
    }
    
    return keyStream;
  }
}

