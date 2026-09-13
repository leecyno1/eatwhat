import 'dart:convert';
import 'dart:io';

import 'package:eatwhat_app/core/services/auth_service.dart';
import 'package:eatwhat_app/v2/core/external/platform/execution_proxy_client.dart';
import 'package:eatwhat_app/v2/core/services/membership_credential.dart';
import 'package:eatwhat_app/v2/core/services/v2_membership_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  const seed = 'eatwhat-dev-seed';

  setUpAll(() async {
    // AuthService 持久化走 Hive：给测试一个真实临时目录。
    final dir = await Directory.systemTemp.createTemp('membership_test');
    Hive.init(dir.path);
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    dotenv.testLoad(fileInput: 'MEMBERSHIP_SIGNING_SEED=$seed');
    await AuthService.register(
      username: '会员买家',
      email: 'buyer@example.com',
      password: 'Eat123456',
      confirmPassword: 'Eat123456',
    );
  });

  tearDown(() async {
    dotenv.clean();
    await AuthService.logout();
  });

  test('支付成功且凭证验签通过才升级，并持久化凭证', () async {
    final userId = AuthService.currentUser!.id;
    final client = _FakePaymentClient(userId: userId, seed: seed);
    final service = V2MembershipService(client: client);

    final ok = await service.waitForPaymentAndUpgrade('order-1');

    expect(ok, isTrue);
    final user = AuthService.currentUser!;
    expect(user.isMember, isTrue);
    expect(user.membershipCredential, isNotNull);
    final stored =
        MembershipCredential.fromJson(_decode(user.membershipCredential!));
    expect(stored, isNotNull);
    expect(stored!.userId, userId);
    expect(user.memberExpiresAt, stored.expiresAt);
  });

  test('支付成功但服务端未带凭证：拒绝升级（fail closed）', () async {
    final client = _FakePaymentClient(includeCredential: false);
    final service = V2MembershipService(client: client);

    final ok = await service.waitForPaymentAndUpgrade('order-1');

    expect(ok, isFalse);
    expect(AuthService.currentUser!.membershipCredential, isNull);
  });

  test('凭证签名种子不符：拒绝升级', () async {
    final userId = AuthService.currentUser!.id;
    final client = _FakePaymentClient(userId: userId, seed: 'another-seed');
    final service = V2MembershipService(client: client);

    final ok = await service.waitForPaymentAndUpgrade('order-1');

    expect(ok, isFalse);
  });

  test('凭证绑定账号与当前登录账号不符：拒绝升级', () async {
    final client = _FakePaymentClient(userId: 'someone-else', seed: seed);
    final service = V2MembershipService(client: client);

    final ok = await service.waitForPaymentAndUpgrade('order-1');

    expect(ok, isFalse);
  });
}

Map<String, dynamic> _decode(String raw) =>
    jsonDecode(raw) as Map<String, dynamic>;

class _FakePaymentClient extends ExecutionProxyClient {
  _FakePaymentClient({
    this.userId = 'user-1',
    this.seed = 'eatwhat-dev-seed',
    this.includeCredential = true,
  });

  final String userId;
  final String seed;
  final bool includeCredential;

  @override
  bool get isConfigured => true;

  @override
  Future<Map<String, dynamic>> getJson(String path) async {
    if (path.startsWith('/api/v1/payment/alipay/status')) {
      if (!includeCredential) {
        return {'status': 'paid', 'orderId': 'order-1'};
      }
      final now = DateTime.now();
      final credential = await MembershipCredentials.issue(
        userId: userId,
        orderId: 'order-1',
        issuedAt: now,
        expiresAt: now.add(const Duration(days: 365)),
        signingKeyPair: await MembershipCredentials.keyPairFromSeed(seed),
      );
      return {
        'status': 'paid',
        'orderId': 'order-1',
        'membershipCredential': credential.toJson(),
      };
    }
    throw StateError('unexpected path: $path');
  }
}
