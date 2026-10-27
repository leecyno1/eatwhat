import 'dart:convert';
import 'dart:io';

import 'package:eatwhat_app/core/services/auth_service.dart';
import 'package:eatwhat_app/core/services/secure_storage_service.dart';
import 'package:eatwhat_app/core/services/token_service.dart';
import 'package:eatwhat_app/v2/core/external/platform/execution_proxy_client.dart';
import 'package:eatwhat_app/v2/core/services/membership_credential.dart';
import 'package:eatwhat_app/v2/core/services/membership_pending_order.dart';
import 'package:eatwhat_app/v2/core/services/v2_membership_service.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
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
    FlutterSecureStorage.setMockInitialValues({});
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

  test('代理可用但缺验签钥匙时不开放购买', () {
    dotenv.clean();
    final service = V2MembershipService(client: _FakePaymentClient());

    expect(service.isConfigured, isTrue);
    expect(service.canCompletePurchase, isFalse);
  });

  test('代理与验签钥匙齐备时开放购买', () {
    final service = V2MembershipService(client: _FakePaymentClient());

    expect(service.canCompletePurchase, isTrue);
  });

  test('待对账订单可持久化、判断过期并清理', () async {
    const store = MembershipPendingOrderStore();
    final createdAt = DateTime(2026, 10, 24, 12);
    await store.save(
      MembershipPendingOrder(
        orderId: 'order-1',
        userId: 'user-1',
        createdAt: createdAt,
      ),
    );

    final stored = await store.read();
    expect(stored, isNotNull);
    expect(stored!.orderId, 'order-1');
    expect(
        stored.isExpiredAt(createdAt.add(const Duration(hours: 23))), isFalse);
    expect(
        stored.isExpiredAt(createdAt.add(const Duration(hours: 25))), isTrue);

    await store.clear();
    expect(await store.read(), isNull);
  });

  test('轮询超时后重新打开账号页，补对账成功并清理待办', () async {
    final userId = AuthService.currentUser!.id;
    const store = MembershipPendingOrderStore();
    await store.save(
      MembershipPendingOrder(
        orderId: 'order-1',
        userId: userId,
        createdAt: DateTime.now(),
      ),
    );
    final service = V2MembershipService(
      client: _FakePaymentClient(userId: userId),
      pendingOrders: store,
    );

    final ok = await service.resumePendingPurchase();

    expect(ok, isTrue);
    expect(AuthService.currentUser!.isMember, isTrue);
    expect(await store.read(), isNull);
  });

  test('待对账订单不属于当前账号：不查状态并清理', () async {
    const store = MembershipPendingOrderStore();
    await store.save(
      MembershipPendingOrder(
        orderId: 'order-1',
        userId: 'someone-else',
        createdAt: DateTime.now(),
      ),
    );
    final client = _ExplodingStatusClient();
    final service = V2MembershipService(
      client: client,
      pendingOrders: store,
    );

    expect(await service.resumePendingPurchase(), isFalse);
    expect(client.calls, 0);
    expect(await store.read(), isNull);
  });

  test('过期的待对账订单不再查询并清理', () async {
    const store = MembershipPendingOrderStore();
    await store.save(
      MembershipPendingOrder(
        orderId: 'order-1',
        userId: AuthService.currentUser!.id,
        createdAt: DateTime.now().subtract(const Duration(hours: 25)),
      ),
    );
    final client = _ExplodingStatusClient();
    final service = V2MembershipService(
      client: client,
      pendingOrders: store,
    );

    expect(await service.resumePendingPurchase(), isFalse);
    expect(client.calls, 0);
    expect(await store.read(), isNull);
  });

  test('未登录时保留待对账订单，重新登录后仍可恢复', () async {
    const store = MembershipPendingOrderStore();
    final userId = AuthService.currentUser!.id;
    await store.save(
      MembershipPendingOrder(
        orderId: 'order-1',
        userId: userId,
        createdAt: DateTime.now(),
      ),
    );
    await AuthService.logout();
    final client = _ExplodingStatusClient();
    final service = V2MembershipService(
      client: client,
      pendingOrders: store,
    );

    expect(await service.resumePendingPurchase(), isFalse);
    expect(client.calls, 0);
    expect(await store.read(), isNotNull);
  });

  test('支付成功且凭证验签通过才升级，并持久化凭证', () async {
    final userId = AuthService.currentUser!.id;
    final client = _FakePaymentClient(userId: userId);
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
    final client = _FakePaymentClient(userId: 'someone-else');
    final service = V2MembershipService(client: client);

    final ok = await service.waitForPaymentAndUpgrade('order-1');

    expect(ok, isFalse);
  });

  test('凭证被篡改后写入即被拦截降级（写侧强制）', () async {
    final user = AuthService.currentUser!;
    // 合法凭证写入：保留会员身份。
    final valid = await _issueFor(user.id);
    await AuthService.updateCurrentUser(
      user.copyWith(
        isMember: true,
        membershipCredential: jsonEncode(valid.toJson()),
      ),
    );
    expect(AuthService.currentUser!.isMember, isTrue);

    // 篡改有效期（签名不变 → 验签必败）再写入：应立即被降级。
    final tamperedMap = valid.toJson()
      ..['expiresAt'] =
          DateTime.now().add(const Duration(days: 3650)).millisecondsSinceEpoch;
    await AuthService.updateCurrentUser(
      AuthService.currentUser!
          .copyWith(membershipCredential: jsonEncode(tamperedMap)),
    );

    expect(AuthService.currentUser!.isMember, isFalse);
    expect(AuthService.currentUser!.membershipCredential, isNull);
  });

  test('凭证被篡改后重开会话即降级（读侧强制）', () async {
    final user = AuthService.currentUser!;
    final tamperedMap = (await _issueFor(user.id)).toJson()
      ..['expiresAt'] =
          DateTime.now().add(const Duration(days: 3650)).millisecondsSinceEpoch;
    final tamperedUser = user.copyWith(
      isMember: true,
      membershipCredential: jsonEncode(tamperedMap),
    );

    await AuthService.logout();
    // 把被篡改的会话直接写进存储，模拟本地数据被改写后冷启动恢复。
    await SecureStorageService.setSecureJson(
        'current_user', tamperedUser.toJson());
    final pair = await TokenService.generateTokenPair(user.id);
    await SecureStorageService.setSecureString('user_token', pair.accessToken);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('remember_me', true);

    await AuthService.initialize();

    expect(AuthService.currentUser, isNotNull);
    expect(AuthService.currentUser!.isMember, isFalse);
    expect(AuthService.currentUser!.membershipCredential, isNull);
  });
}

Future<MembershipCredential> _issueFor(String userId) async {
  final now = DateTime.now();
  return MembershipCredentials.issue(
    userId: userId,
    orderId: 'order-1',
    issuedAt: now,
    expiresAt: now.add(const Duration(days: 365)),
    signingKeyPair:
        await MembershipCredentials.keyPairFromSeed('eatwhat-dev-seed'),
  );
}

Map<String, dynamic> _decode(String raw) =>
    jsonDecode(raw) as Map<String, dynamic>;

class _ExplodingStatusClient extends ExecutionProxyClient {
  int calls = 0;

  @override
  bool get isConfigured => true;

  @override
  Future<Map<String, dynamic>> getJson(String path) async {
    calls++;
    throw StateError('不应查询支付状态：$path');
  }
}

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
