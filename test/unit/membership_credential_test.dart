import 'package:eatwhat_app/v2/core/services/membership_credential.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  const seed = 'eatwhat-dev-seed';

  setUp(() {
    dotenv.testLoad(fileInput: 'MEMBERSHIP_SIGNING_SEED=$seed');
  });

  tearDown(dotenv.clean);

  Future<MembershipCredential> issueDemo({DateTime? expiresAt}) async {
    final keyPair = await MembershipCredentials.keyPairFromSeed(seed);
    final now = DateTime.now();
    return MembershipCredentials.issue(
      userId: 'user-1',
      orderId: 'order-1',
      issuedAt: now,
      expiresAt: expiresAt ?? now.add(const Duration(days: 365)),
      signingKeyPair: keyPair,
    );
  }

  test('签发后可验签通过', () async {
    final credential = await issueDemo();

    expect(
      await MembershipCredentials.verify(credential, expectedUserId: 'user-1'),
      isTrue,
    );
  });

  test('篡改载荷（有效期）后验签失败', () async {
    final credential = await issueDemo();
    final tampered = MembershipCredential(
      userId: credential.userId,
      orderId: credential.orderId,
      tier: credential.tier,
      issuedAt: credential.issuedAt,
      expiresAt: credential.expiresAt.add(const Duration(days: 3650)),
      signature: credential.signature,
    );

    expect(await MembershipCredentials.verify(tampered), isFalse);
  });

  test('种子不同则验签失败', () async {
    final credential = await issueDemo();
    dotenv.testLoad(fileInput: 'MEMBERSHIP_SIGNING_SEED=another-seed');

    expect(await MembershipCredentials.verify(credential), isFalse);
  });

  test('过期凭证不通过', () async {
    final credential = await issueDemo(
      expiresAt: DateTime.now().subtract(const Duration(days: 1)),
    );

    expect(await MembershipCredentials.verify(credential), isFalse);
  });

  test('凭证绑定的账号不一致则不通过', () async {
    final credential = await issueDemo();

    expect(
      await MembershipCredentials.verify(credential, expectedUserId: 'user-2'),
      isFalse,
    );
  });

  test('未配置任何验签钥匙时 fail closed', () async {
    dotenv.clean();
    final credential = await issueDemo();

    expect(await MembershipCredentials.verify(credential), isFalse);
  });

  test('fromJson 拒绝残缺数据', () {
    expect(MembershipCredential.fromJson(null), isNull);
    expect(MembershipCredential.fromJson({'userId': 'u1'}), isNull);
  });
}
