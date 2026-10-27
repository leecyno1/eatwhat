import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:eatwhat_app/core/config/env_config.dart';
import 'package:eatwhat_app/v2/core/services/membership_credential.dart';
import 'package:flutter/foundation.dart' show kReleaseMode;

/// 客户端侧的会员凭证验签入口：公钥来自内嵌公钥（生产）或开发种子（本地联调）。
/// membership_credential.dart 保持纯 Dart 以便服务端 CLI 复用，EnvConfig
/// 相关的解析集中在这里。
class MembershipVerification {
  MembershipVerification._();

  static const int _ed25519PublicKeyLength = 32;

  /// 是否存在可用的验签公钥。购买入口据此决定是否展示：付了钱却无法
  /// 验签升级，比不展示入口更糟。
  static bool hasVerificationKey({bool allowDevSeed = !kReleaseMode}) {
    final embedded = EnvConfig.membershipSigningPublicKey.trim();
    if (embedded.isNotEmpty) {
      return _decodePublicKey(embedded) != null;
    }
    return allowDevSeed && EnvConfig.membershipSigningSeed.trim().isNotEmpty;
  }

  /// 客户端验签公钥：优先用内嵌公钥（生产）；开发构建可回退到种子派生
  /// （本地联调）。两者都不可用 → null（调用方应拒绝升级，fail closed）。
  static Future<SimplePublicKey?> verificationKey({
    bool allowDevSeed = !kReleaseMode,
  }) async {
    final embedded = EnvConfig.membershipSigningPublicKey.trim();
    if (embedded.isNotEmpty) {
      return _decodePublicKey(embedded);
    }
    if (!allowDevSeed) return null;
    final seed = EnvConfig.membershipSigningSeed.trim();
    if (seed.isEmpty) return null;
    return MembershipCredentials.publicKeyFromSeed(seed);
  }

  static SimplePublicKey? _decodePublicKey(String encoded) {
    try {
      final bytes = base64Decode(encoded);
      if (bytes.length != _ed25519PublicKeyLength) return null;
      return SimplePublicKey(bytes, type: KeyPairType.ed25519);
    } catch (_) {
      return null;
    }
  }

  /// fail closed：公钥缺失、过期、错账号、坏签名都返回 false。
  static Future<bool> verify(
    MembershipCredential credential, {
    String? expectedUserId,
    bool allowDevSeed = !kReleaseMode,
  }) async {
    final key = await verificationKey(allowDevSeed: allowDevSeed);
    if (key == null) return false;
    return MembershipCredentials.verify(
      credential,
      key: key,
      expectedUserId: expectedUserId,
    );
  }
}
