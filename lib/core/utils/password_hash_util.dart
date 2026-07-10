import 'dart:convert';
import 'dart:math' as math;
import 'dart:typed_data';
import 'package:crypto/crypto.dart';
import '../config/env_config.dart';

/// 密码哈希工具类
/// 提供安全的密码哈希和验证功能
class PasswordHashUtil {
  static const int _saltLength = 16;
  static const int _keyLength = 32;
  static const int _iterations = 10000;

  /// 生成密码哈希（使用PBKDF2）
  /// 相比直接的SHA256，PBKDF2更安全，可以有效防止彩虹表攻击
  static String hashPassword(String password) {
    try {
      // 生成随机盐值
      final salt = _generateSalt();

      // 使用PBKDF2进行哈希
      final hashedPassword = _pbkdf2(password, salt, _iterations, _keyLength);

      // 将盐值和哈希结果组合存储
      final combined = salt + hashedPassword;

      // 返回Base64编码的结果
      return base64Encode(combined);
    } catch (e) {
      throw Exception('Password hashing failed: $e');
    }
  }

  /// 验证密码
  static bool verifyPassword(String password, String hashedPassword) {
    try {
      // 解码存储的哈希
      final combined = base64Decode(hashedPassword);

      // 提取盐值和哈希
      final salt = combined.sublist(0, _saltLength);
      final hash = combined.sublist(_saltLength);

      // 使用相同的盐值和参数重新哈希输入的密码
      final newHash = _pbkdf2(password, salt, _iterations, _keyLength);

      // 比较哈希值
      return _constantTimeEquals(hash, newHash);
    } catch (e) {
      // 验证失败时返回false，避免泄露信息
      return false;
    }
  }

  /// 生成随机盐值
  static Uint8List _generateSalt() {
    final random = math.Random.secure();
    final salt = Uint8List(_saltLength);
    for (int i = 0; i < _saltLength; i++) {
      salt[i] = random.nextInt(256);
    }
    return salt;
  }

  /// PBKDF2实现（使用HMAC-SHA256）
  static Uint8List _pbkdf2(String password, Uint8List salt, int iterations, int keyLength) {
    final passwordBytes = utf8.encode(password + EnvConfig.passwordSalt);
    final result = Uint8List(keyLength);

    // PBKDF2 implementation using HMAC-SHA256
    var blockCount = (keyLength + 32 - 1) ~/ 32; // 32 is SHA256 hash length
    var resultIndex = 0;

    for (int i = 1; i <= blockCount; i++) {
      final block = _pbkdf2Block(passwordBytes, salt, iterations, i);
      final copyLength = math.min(32, keyLength - resultIndex);

      result.setRange(resultIndex, resultIndex + copyLength, block);
      resultIndex += copyLength;
    }

    return result;
  }

  /// PBKDF2 block computation
  static Uint8List _pbkdf2Block(
      List<int> password, Uint8List salt, int iterations, int blockIndex) {
    // Create U1 = HMAC(password, salt + INT(i))
    final hmac = Hmac(sha256, password);
    final blockBytes = Uint8List(4);
    blockBytes.buffer.asByteData().setUint32(0, blockIndex, Endian.big);

    var u = Uint8List.fromList(hmac.convert([...salt, ...blockBytes]).bytes);
    var result = Uint8List.fromList(u);

    // Compute U2, U3, ..., Uc and XOR them all together
    for (int j = 1; j < iterations; j++) {
      u = Uint8List.fromList(hmac.convert(u).bytes);
      for (int k = 0; k < result.length; k++) {
        result[k] ^= u[k];
      }
    }

    return result;
  }

  /// 常量时间比较，防止时序攻击
  static bool _constantTimeEquals(Uint8List a, Uint8List b) {
    if (a.length != b.length) return false;

    int result = 0;
    for (int i = 0; i < a.length; i++) {
      result |= a[i] ^ b[i];
    }
    return result == 0;
  }

  /// 生成安全的随机密码
  static String generateSecurePassword({int length = 16}) {
    const charset = 'ABCDEFGHIJKLMNOPQRSTUVWXYZabcdefghijklmnopqrstuvwxyz0123456789!@#\$%^&*()';
    final random = math.Random.secure();

    return String.fromCharCodes(
      Iterable.generate(length, (_) => charset.codeUnitAt(random.nextInt(charset.length))),
    );
  }

  /// 密码强度检查
  static PasswordStrength checkPasswordStrength(String password) {
    if (password.length < 6) {
      return PasswordStrength.weak;
    }

    int score = 0;

    // 长度加分
    if (password.length >= 8) score += 1;
    if (password.length >= 12) score += 1;

    // 字符类型检查
    if (password.contains(RegExp(r'[a-z]'))) score += 1; // 小写字母
    if (password.contains(RegExp(r'[A-Z]'))) score += 1; // 大写字母
    if (password.contains(RegExp(r'[0-9]'))) score += 1; // 数字
    if (password.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]'))) score += 1; // 特殊字符

    // 复杂度检查
    if (password.length >= 16) score += 1;
    if (!password.contains(RegExp(r'(.)\1{2,}'))) score += 1; // 无连续重复字符

    if (score <= 2) return PasswordStrength.weak;
    if (score <= 4) return PasswordStrength.medium;
    if (score <= 6) return PasswordStrength.strong;
    return PasswordStrength.veryStrong;
  }

  /// 验证密码复杂度
  static String? validatePasswordComplexity(String password) {
    if (password.length < 6) {
      return '密码长度至少6位';
    }

    if (password.length < 8) {
      return '建议密码长度至少8位';
    }

    if (!password.contains(RegExp(r'[a-z]'))) {
      return '密码应包含小写字母';
    }

    if (!password.contains(RegExp(r'[A-Z]'))) {
      return '密码应包含大写字母';
    }

    if (!password.contains(RegExp(r'[0-9]'))) {
      return '密码应包含数字';
    }

    if (password.contains(RegExp(r'(.)\1{2,}'))) {
      return '密码不应包含连续重复字符';
    }

    // 检查常见弱密码
    final weakPasswords = [
      '123456',
      'password',
      'qwerty',
      'admin',
      'letmein',
      '123456789',
      'welcome',
      'monkey',
      '1234567890'
    ];

    if (weakPasswords.contains(password.toLowerCase())) {
      return '密码过于简单，请使用更复杂的密码';
    }

    return null; // 验证通过
  }
}

/// 密码强度枚举
enum PasswordStrength {
  weak,
  medium,
  strong,
  veryStrong,
}

/// 密码强度扩展
extension PasswordStrengthExtension on PasswordStrength {
  String get description {
    switch (this) {
      case PasswordStrength.weak:
        return '弱';
      case PasswordStrength.medium:
        return '中等';
      case PasswordStrength.strong:
        return '强';
      case PasswordStrength.veryStrong:
        return '非常强';
    }
  }

  double get value {
    switch (this) {
      case PasswordStrength.weak:
        return 0.25;
      case PasswordStrength.medium:
        return 0.5;
      case PasswordStrength.strong:
        return 0.75;
      case PasswordStrength.veryStrong:
        return 1.0;
    }
  }
}
