import 'dart:convert';

import 'package:cryptography/cryptography.dart';
import 'package:eatwhat_app/core/config/env_config.dart';
import 'package:eatwhat_app/v2/core/services/membership_credential.dart';

/// 客户端侧的会员凭证验签入口：公钥来自内嵌公钥（生产）或开发种子（本地联调）。
/// membership_credential.dart 保持纯 Dart 以便服务端 CLI 复用，EnvConfig
/// 相关的解析集中在这里。
class MembershipVerification {
  MembershipVerification._();

  /// 客户端验签公钥：优先用内嵌公钥（生产）；否则用开发种子派生（本地联调）。
  /// 两者都没有 → null（调用方应拒绝升级，fail closed）。
  static Future<SimplePublicKey?> verificationKey() async {
    final embedded = EnvConfig.membershipSigningPublicKey.trim();
    if (embedded.isNotEmpty) {
      return SimplePublicKey(
        base64Decode(embedded),
        type: KeyPairType.ed25519,
      );
    }
    final seed = EnvConfig.membershipSigningSeed.trim();
    if (seed.isEmpty) return null;
    return MembershipCredentials.publicKeyFromSeed(seed);
  }

  /// fail closed：公钥缺失、过期、错账号、坏签名都返回 false。
  static Future<bool> verify(
    MembershipCredential credential, {
    String? expectedUserId,
  }) async {
    final key = await verificationKey();
    if (key == null) return false;
    return MembershipCredentials.verify(
      credential,
      key: key,
      expectedUserId: expectedUserId,
    );
  }
}
