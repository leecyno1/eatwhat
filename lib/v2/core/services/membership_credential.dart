import 'dart:convert';

import 'package:crypto/crypto.dart';
import 'package:cryptography/cryptography.dart';

/// 会员凭证：服务端（支付确认后）用 Ed25519 私钥签发，客户端用内嵌公钥验签。
/// 取代「轮询到 paid 就本地升级」的裸信任——本地存储被篡改也无法伪造签名。
///
/// 本文件保持纯 Dart（不依赖 Flutter/EnvConfig），以便支付服务端与 mock
/// 服务端以 `dart run` 直接复用同一契约。客户端的公钥解析见
/// [membership_verification.dart]。
class MembershipCredential {
  const MembershipCredential({
    required this.userId,
    required this.orderId,
    required this.tier,
    required this.issuedAt,
    required this.expiresAt,
    required this.signature,
  });

  final String userId;
  final String orderId;

  /// 会员档位，当前固定 'member'。
  final String tier;
  final DateTime issuedAt;
  final DateTime expiresAt;

  /// base64 编码的 Ed25519 签名。
  final String signature;

  /// 规范载荷：管道分隔、字段定序，签名字节只取决于它。
  String get canonicalPayload => 'membership.v1|$userId|$orderId|$tier|'
      '${issuedAt.millisecondsSinceEpoch}|${expiresAt.millisecondsSinceEpoch}';

  bool get isExpired => DateTime.now().isAfter(expiresAt);

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'orderId': orderId,
        'tier': tier,
        'issuedAt': issuedAt.millisecondsSinceEpoch,
        'expiresAt': expiresAt.millisecondsSinceEpoch,
        'signature': signature,
      };

  static MembershipCredential? fromJson(Object? json) {
    if (json is! Map) return null;
    final userId = json['userId']?.toString() ?? '';
    final orderId = json['orderId']?.toString() ?? '';
    final tier = json['tier']?.toString() ?? '';
    final signature = json['signature']?.toString() ?? '';
    final issuedAtMs = int.tryParse(json['issuedAt']?.toString() ?? '');
    final expiresAtMs = int.tryParse(json['expiresAt']?.toString() ?? '');
    if (userId.isEmpty ||
        orderId.isEmpty ||
        tier.isEmpty ||
        signature.isEmpty ||
        issuedAtMs == null ||
        expiresAtMs == null) {
      return null;
    }
    return MembershipCredential(
      userId: userId,
      orderId: orderId,
      tier: tier,
      issuedAt: DateTime.fromMillisecondsSinceEpoch(issuedAtMs),
      expiresAt: DateTime.fromMillisecondsSinceEpoch(expiresAtMs),
      signature: signature,
    );
  }
}

/// 签发与验签。签发只发生在服务端（mock 代理在本地开发时充当签发方）；
/// 客户端只验签。
class MembershipCredentials {
  MembershipCredentials._();

  static final _algorithm = Ed25519();

  /// 开发种子 → 32 字节：sha256(seed)。生产环境种子只留在服务端，
  /// 客户端只内嵌公钥（MEMBERSHIP_SIGNING_PUBLIC_KEY）。
  static List<int> seedBytes(String seed) =>
      sha256.convert(utf8.encode(seed)).bytes;

  /// 由开发种子派生 Ed25519 密钥对（mock 服务端签发、客户端开发态验签共用）。
  static Future<SimpleKeyPair> keyPairFromSeed(String seed) {
    return _algorithm.newKeyPairFromSeed(seedBytes(seed));
  }

  static Future<SimplePublicKey> publicKeyFromSeed(String seed) async {
    final keyPair = await keyPairFromSeed(seed);
    return keyPair.extractPublicKey();
  }

  /// 服务端签发。
  static Future<MembershipCredential> issue({
    required String userId,
    required String orderId,
    required DateTime issuedAt,
    required DateTime expiresAt,
    required SimpleKeyPair signingKeyPair,
    String tier = 'member',
  }) async {
    final draft = MembershipCredential(
      userId: userId,
      orderId: orderId,
      tier: tier,
      issuedAt: issuedAt,
      expiresAt: expiresAt,
      signature: '',
    );
    final signature = await _algorithm.sign(
      utf8.encode(draft.canonicalPayload),
      keyPair: signingKeyPair,
    );
    return MembershipCredential(
      userId: userId,
      orderId: orderId,
      tier: tier,
      issuedAt: issuedAt,
      expiresAt: expiresAt,
      signature: base64Encode(signature.bytes),
    );
  }

  /// 验签 + 有效期 + 账号绑定。任何一项不过都视为无效。
  /// 公钥由调用方显式提供：客户端经 MembershipVerification 从 EnvConfig
  /// 解析，服务端在测试中从种子派生。
  static Future<bool> verify(
    MembershipCredential credential, {
    required SimplePublicKey key,
    String? expectedUserId,
  }) async {
    if (credential.isExpired) return false;
    if (expectedUserId != null && credential.userId != expectedUserId) {
      return false;
    }
    try {
      return await _algorithm.verify(
        utf8.encode(credential.canonicalPayload),
        signature: Signature(
          base64Decode(credential.signature),
          publicKey: key,
        ),
      );
    } catch (_) {
      return false;
    }
  }
}
