import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:cryptography/cryptography.dart' hide Hmac;
import 'package:eatwhat_app/v2/core/services/membership_credential.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../scripts/payment_server.dart';

const _merchantPrivateKeyPem = '''
-----BEGIN PRIVATE KEY-----
MIIEvgIBADANBgkqhkiG9w0BAQEFAASCBKgwggSkAgEAAoIBAQCrlfm1h18Kfgdi
1VMAxIEw6uBGaelYZ7zNRT4V3nwNQTdsHiKwNp5/Z68X89ZfOcrST0QdRhizASCX
IDDV+IOL0BNILkPcWSyJWehcHihTd6kjHUzGXjBeTFi6Py1odpPUp5V8H69C/NEH
f5GWImilii119PwWInlCM8zKD1y+zxFidBtyLZ7QNhBqCLYqW+5YJqWuMJ0L7dAw
YBNgmal96G6Yq33cJ2V9F8ItQ/S4bzf4pQ39pOaClxRaPsyMGBv7wFo0tHqA1Wog
7A1FWjte7EkqbX7UkCoTL8ZELehiiZATgvygdbt8SqK0UAGFp9M71hcXoWhDQV78
vyqzKXYxAgMBAAECggEAFPnZ48T3i60SApVRFxYus/f2sGz4q4fNBywYlaxT7nvj
Rlqdw3x93lXizBMRSSVjw9eQXGLKGLIB1a/IAJRnonMutEOBpMGbBfSBiSdfpyqI
+QO3M8XmdFSxgR1BlBRw6I2PIvQtpQsKk7fW6KturxQIEDRBkAQpXjw+ZBJCNIog
yY1qxrKUEpqp8PLqhL4G3K8MwGUZi9RCdBADyH40lu6uyJMAdb5J0GL60lbQnEbZ
9kCL4x5DGHQ61WZ9JF2OVbAdTwt/lDHcROkJ3b1y6y2/OWYixLQUiInQsMOqeddv
XguGpbzDrO1N/eAvQ3o7WNRejv9lGnzMJ6frownHJQKBgQDpxb2e9OufnqJaS8Kp
k3Iy/sV8NjTh2XaC6GCZpqxj/AgH/cNQjMGTH7/OvmvvXrEjSkyIL8evwfyGwFO9
Df3RMOVHWpdkRStUnW8kW8XqQBgIZiHJZBkLldbOUqjIgVLwZ2SvxphIIKpw8XSs
MkDKkwtO99DqbzL7LqZJFEKnNQKBgQC75ozC1I7oQOYf+aTc6x+2lNbKkeDH3F3f
yq/gmVO8ADntKMT6xspaLPD1orMFVvKk2ZgQnGuCkfEc3+i6Ab42hr/Zh/XgYMOL
NkujKG/cgO1/v+YPiT/vwzGca1h+kH6pyT86zBBrJdlw3uXflN/cqn6kIiYCu5+O
XCySL8umjQKBgQCFT4OD602W+ALDlWKMC45bMFh0LgFYLgfcPSIhXR//4JC/5eGE
xM/602cxQfwRRCGl60/bdcvdGbWlLnZSYHE24zhMyYd94cgE98aSqFcj76sE1yE7
VH7H0YnunMqtlLo0Z/HOH2Vl9GLeB4OuUvYJz3LqdH3JwuICxaaEFC6yZQKBgQCT
34S3b4Bn12tDjrvoAEIc9lVzZgp4PzzBekmfgAsd0S/FLGiY0wk8nlGjfj9U3HBo
u7WonPEe+KvABZapi+WeE723+//MbVp2nGw6IwClj/FYsDTl1SW0EvFgIDqsoBqO
lApmw2HIcSkGYuSVaBwlFShFE3rGe9G9v1x0T5j9oQKBgCS2PhB1RrlY5J4F3SBr
mO6A5XBCfUSzx2jm2Ge3PZn3eqlYlUqB7XDOd98mawSfJXbVjlB5cZ9UEtE3i0BR
stdNCYW812Nx+C5ihgqMm8MMMv0olRQNf93kBOVv7WmKVOIFtQT4EHTeG+338V3/
m/5t50ldeKUJOiAH3C+TDjmZ
-----END PRIVATE KEY-----''';

const _merchantPrivateKeyPkcs1Pem = '''
-----BEGIN RSA PRIVATE KEY-----
MIIEpAIBAAKCAQEAq5X5tYdfCn4HYtVTAMSBMOrgRmnpWGe8zUU+Fd58DUE3bB4i
sDaef2evF/PWXznK0k9EHUYYswEglyAw1fiDi9ATSC5D3FksiVnoXB4oU3epIx1M
xl4wXkxYuj8taHaT1KeVfB+vQvzRB3+RliJopYotdfT8FiJ5QjPMyg9cvs8RYnQb
ci2e0DYQagi2KlvuWCalrjCdC+3QMGATYJmpfehumKt93CdlfRfCLUP0uG83+KUN
/aTmgpcUWj7MjBgb+8BaNLR6gNVqIOwNRVo7XuxJKm1+1JAqEy/GRC3oYomQE4L8
oHW7fEqitFABhafTO9YXF6FoQ0Fe/L8qsyl2MQIDAQABAoIBABT52ePE94utEgKV
URcWLrP39rBs+KuHzQcsGJWsU+5740ZancN8fd5V4swTEUklY8PXkFxiyhiyAdWv
yACUZ6JzLrRDgaTBmwX0gYknX6cqiPkDtzPF5nRUsYEdQZQUcOiNjyL0LaULCpO3
1uirbq8UCBA0QZAEKV48PmQSQjSKIMmNasaylBKaqfDy6oS+BtyvDMBlGYvUQnQQ
A8h+NJbursiTAHW+SdBi+tJW0JxG2fZAi+MeQxh0OtVmfSRdjlWwHU8Lf5Qx3ETp
Cd29custvzlmIsS0FIiJ0LDDqnnXb14LhqW8w6ztTf3gL0N6O1jUXo7/ZRp8zCen
66MJxyUCgYEA6cW9nvTrn56iWkvCqZNyMv7FfDY04dl2guhgmaasY/wIB/3DUIzB
kx+/zr5r716xI0pMiC/Hr8H8hsBTvQ390TDlR1qXZEUrVJ1vJFvF6kAYCGYhyWQZ
C5XWzlKoyIFS8Gdkr8aYSCCqcPF0rDJAypMLTvfQ6m8y+y6mSRRCpzUCgYEAu+aM
wtSO6EDmH/mk3OsftpTWypHgx9xd38qv4JlTvAA57SjE+sbKWizw9aKzBVbypNmY
EJxrgpHxHN/ougG+Noa/2Yf14GDDizZLoyhv3IDtf7/mD4k/78MxnGtYfpB+qck/
OswQayXZcN7l35Tf3Kp+pCImArufjlwski/Lpo0CgYEAhU+Dg+tNlvgCw5VijAuO
WzBYdC4BWC4H3D0iIV0f/+CQv+XhhMTP+tNnMUH8EUQhpetP23XL3Rm1pS52UmBx
NuM4TMmHfeHIBPfGkqhXI++rBNchO1R+x9GJ7pzKrZS6NGfxzh9lZfRi3geDrlL2
Cc9y6nR9ycLiAsWmhBQusmUCgYEAk9+Et2+AZ9drQ4676ABCHPZVc2YKeD88wXpJ
n4ALHdEvxSxomNMJPJ5Ro34/VNxwaLu1qJzxHvirwAWWqYvlnhO9t/v/zG1adpxs
OiMApY/xWLA05dUltBLxYCA6rKAajpQKZsNhyHEpBmLklWgcJRUoRRN6xnvRvb9c
dE+Y/aECgYAktj4QdUa5WOSeBd0ga5jugOVwQn1Es8do5thntz2Z93qpWJVKge1w
znffJmsEnyV21Y5QeXGfVBLRN4tAUbLXTQmFvNdjcfguYoYKjJvDDDL9KJUUDX/d
5ATlb+1pilTiBbUE+BB03hvt9/Fd/5v+bedJXXilCTogB9wvkw45mQ==
-----END RSA PRIVATE KEY-----''';

const _merchantPublicKeyPem = '''
-----BEGIN PUBLIC KEY-----
MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAq5X5tYdfCn4HYtVTAMSB
MOrgRmnpWGe8zUU+Fd58DUE3bB4isDaef2evF/PWXznK0k9EHUYYswEglyAw1fiD
i9ATSC5D3FksiVnoXB4oU3epIx1Mxl4wXkxYuj8taHaT1KeVfB+vQvzRB3+RliJo
pYotdfT8FiJ5QjPMyg9cvs8RYnQbci2e0DYQagi2KlvuWCalrjCdC+3QMGATYJmp
fehumKt93CdlfRfCLUP0uG83+KUN/aTmgpcUWj7MjBgb+8BaNLR6gNVqIOwNRVo7
XuxJKm1+1JAqEy/GRC3oYomQE4L8oHW7fEqitFABhafTO9YXF6FoQ0Fe/L8qsyl2
MQIDAQAB
-----END PUBLIC KEY-----''';

const _alipayPrivateKeyPem = '''
-----BEGIN PRIVATE KEY-----
MIIEvQIBADANBgkqhkiG9w0BAQEFAASCBKcwggSjAgEAAoIBAQCip2zT5GmNPmp/
xYCtJkf3TTIf+5vmgCcj30aVg3AyEEf9OM5M9x8FdkdXmoHiTwvT2BHjYnvqSrCW
uqRFfTTtU3AigMuVKtiMicy4AsUtvHHZJLEkN3CjL5tzaA01f33901q8lsTUhpIQ
qakD2xpjtqXFWlF/dCjinIg9CFnDo6Zjnq3BAbEsvMXc4cjfQN9JIOGjoagsRUjk
pTIGPxnu6gUsH9vcSE11dpE5XlR8X5pUnjMBXupukRQHxmBUtfyTY4T3fpWk2Bzq
caf30XcZwrwoHLMZSnJzZRDx0ZcHSEJf/0yca2JU72s1aQFM9SUT428KHbu6y5F9
AJhbsgm5AgMBAAECggEARYVRHxocQVohs/4LOzbHAL02hPQKlRFGaW834JTe4g8S
bfmXN89SK4f8A0YPaNbHY+MQ9kL0WtZUtwAMUYUsF5oXri+llFrNVvhZD3djpuJK
OPkVW7j0hFNHWqLpLmoRRGnPeRbqBzqDeOrDSloeY+s/3GP3vIW+Kemk041brKH5
LN+m+LSU5nL/6tUot4MpsbJNEw46W8eO4apN0OPYSs0wbAUvDvqAD2flXWGshc5c
U7Och1hmOH3/NwZGZealvpsP24FJvWsloyA4qruuNaK55bxSpz26L4neg0SWmbXn
wRsQdyI+YdM78qAiGTyZ0B3qDoiwwSH5UnpzP+HkvwKBgQDg1RmYLMbyt8GdHjOw
hXiJAKP5njPwRiY2JWQHUFL6n8qsLoZdQASC057Zde8kkgOPoU4JYqHxrb/6l1Dp
YE4J03pHrB4VoUUVoCOPtXnqCowPH+ZAFqYdp+I4GJRsFCK9apa9TyKow4qY/y9F
b/uFcMkk39zi5MNAfuI4nIF9ewKBgQC5M7l1FFKZw19nEzdQUSgGsSYjIAZygEV6
lWL6JMc4tI66eJC05ABtRcVqD2qeVZSgFnDkZXWhmWAARkqGedKlXKqxFhXkB8na
e7nemdiCRJBNg9zdPPR+3B3KfDhgIc+OqgyORsjF0E+Y/2wR6eHbXR4wxcRAQE8c
5BxgAkKdWwKBgD1nlhzspc1miHeL5xwf5+KrDR3AqnjF/+ur3JzuwCr491Z9Qm83
a8P7XhgQUKcRRe21ZWXEzWv/Qz6CkzOZ/NZMLspiZLkNmZulZ/D45HoaNVRwJud8
CBRzZKJjfC3kdfR7pv2/Hj0vYqwUjemOAwjX2+e5SE+joPv9a3WAsRD/AoGAeRz0
STZzFg8IErYkVCfejxHGKO5GiRaNWS7cPU1T4ydgt10k9Mat6MfZ5BQU21qICXDj
ftlC5d0RRNyy2+JK+Mzy6z/QLQFS5chHsuTVC8ueurJi+2NjWJrF+KbnjyZNP7TA
5UIxBfvGMf3HRKe4heYNWkPapVHo6rHaRIb13UUCgYEAopc78Tq57cVOEzVEQfM1
Qew0maaoEZcL0raRxpoR+2bWTG5VHFo59NucisP/HCg/wse4EuzVZ01+mzvuGo/J
IL/bcuUbjvn+dTBY2UMIXQS+1R/P/t1pnEXNBtotsb3mfx7F2auWiLY5dIOmdowf
oiu03Igk5Al+tCIVaCiEftM=
-----END PRIVATE KEY-----''';

const _alipayPublicKeyPem = '''
-----BEGIN PUBLIC KEY-----
MIIBIjANBgkqhkiG9w0BAQEFAAOCAQ8AMIIBCgKCAQEAoqds0+RpjT5qf8WArSZH
900yH/ub5oAnI99GlYNwMhBH/TjOTPcfBXZHV5qB4k8L09gR42J76kqwlrqkRX00
7VNwIoDLlSrYjInMuALFLbxx2SSxJDdwoy+bc2gNNX99/dNavJbE1IaSEKmpA9sa
Y7alxVpRf3Qo4pyIPQhZw6OmY56twQGxLLzF3OHI30DfSSDho6GoLEVI5KUyBj8Z
7uoFLB/b3EhNdXaROV5UfF+aVJ4zAV7qbpEUB8ZgVLX8k2OE936VpNgc6nGn99F3
GcK8KByzGUpyc2UQ8dGXB0hCX/9MnGtiVO9rNWkBTPUlE+NvCh27usuRfQCYW7IJ
uQIDAQAB
-----END PUBLIC KEY-----''';

/// openssl dgst -sha256 -sign merchant.pem 对固定内容的签名（交叉验证 PEM 解析与签名实现）。
const _opensslSignedContent = 'notify-content-test-1750000000000';
const _opensslSignatureBase64 =
    'Ic4kLbPWFy/Ih2acR4awpZZPHL6/WHWHQK6YwMm7NRAC4TbCXh2oovSFd8y/k1zy/G6CYdVB2pGaEl/pvwRVShXP3IprTqzo3+M+T4EIBDbx7BgtSNV8CvGYLdVaKdtx5vLv/XAluOVTj8z0LW8sfmYhFV3YbAUm3z/OkDKRBKhdNgQ5Z788gI2F8b5WzGdmVkg+CCumEF01nANnwjYwz8p/OUM3X8CY34Z7m9ipxDZ7OxYC9SFQRs3KW3PwZx59wxun5BepnNB6nuZocMxMpiVlfefSuZpJqPVvMOaqw7tBQPtx2W+3Lk5soa+Imxpss/+YHZAFQcYnVhPh+SOeBQ==';

/// openssl 对规范化 wap.pay 请求参数（含 JSON biz_content）的签名，
/// 交叉验证 PEM 解析与签名实现（含特殊字符内容的第二样本）。
const _opensslMerchantRequestParamContent =
    'app_id=2021000000000002&biz_content={"out_trade_no":"EW17500000000001"}&charset=utf-8&method=alipay.trade.wap.pay';
const _opensslMerchantRequestParamSignatureBase64 =
    'jIVehGYGqLgAKYte2NPkrs6XpajnPSGZZTFKNKt/4fU3JYxnvW3NpOBBnrWzFdgRnw7dyOzjm4i4T1NHQZVFnQDVZAzWrF04L9lplSOzVdTT9MSvXBhfZUSHStJL/4JTLoqcCuiM/7uE9lWitKNXfM9m5InW6+3UgT8cTreQ5pFIAh50ynPr3GZWIySpBshfYU8sefyfvFe6IgS+O8D2n7zErvOSZhxb+LIC0byTRvDHolU7BAWncoLmD8I/J1iWGG1Bo1S7xn+5wijEEOTPIo4ionRCvhNVw6Zl0+U/0YeeOc2afLGz9gPGXOVqzeQ043vbLbEAUlwPDWGPP8E+Bw==';

const _testJwtSecret = 'payment-test-jwt-secret';
const _testUserId = 'user-payment-001';
const _otherUserId = 'user-payment-002';
const _testSigningSeed = 'payment-test-seed';

DateTime _fixedNow() => DateTime(2026, 9, 20, 12);

class _RecordingGateway implements AlipayGateway {
  _RecordingGateway({this.tradeStatus});

  final String? tradeStatus;
  final wapPayRequests = <Map<String, String>>[];
  final queryRequests = <String>[];

  @override
  Uri buildWapPayUrl({
    required String outTradeNo,
    required MembershipPlan plan,
    required String notifyUrl,
  }) {
    wapPayRequests.add({
      'outTradeNo': outTradeNo,
      'totalAmount': plan.totalAmount,
      'subject': plan.subject,
    });
    return Uri.parse('https://pay.test/cashier?out_trade_no=$outTradeNo');
  }

  @override
  Future<AlipayTradeQueryResult?> queryTrade(
      {required String outTradeNo}) async {
    queryRequests.add(outTradeNo);
    if (tradeStatus == null) return null;
    return AlipayTradeQueryResult(tradeStatus: tradeStatus!);
  }
}

String _jwtFor(String userId, {String? secret}) {
  String encode(Map<String, Object> value) =>
      base64Url.encode(utf8.encode(jsonEncode(value))).replaceAll('=', '');
  final header = encode({'alg': 'HS256', 'typ': 'JWT'});
  final payload = encode({
    'sub': userId,
    'exp':
        DateTime.now().add(const Duration(hours: 1)).millisecondsSinceEpoch ~/
            1000,
    'type': 'access',
  });
  final signature = Hmac(sha256, utf8.encode(secret ?? _testJwtSecret))
      .convert(utf8.encode('$header.$payload'))
      .bytes;
  return '$header.$payload.'
      '${base64Url.encode(signature).replaceAll('=', '')}';
}

Future<PaymentServer> _startServer(
  _RecordingGateway gateway, {
  required Directory directory,
  bool requireJwt = true,
}) async {
  final config = PaymentServerConfig(
    bindAddress: InternetAddress.loopbackIPv4,
    port: 0,
    jwtSecret: requireJwt ? _testJwtSecret : '',
    localUserId: 'local-eatwhat-user',
    alipayAppId: '2021000000000002',
    alipayGatewayUrl: 'https://openapi.alipay.com/gateway.do',
    alipayMerchantPrivateKeyPem: _merchantPrivateKeyPem,
    alipayPublicKeyPem: _alipayPublicKeyPem,
    notifyUrl: 'https://pay.example.com/api/v1/payment/alipay/notify',
    plans: const {
      'yearly': MembershipPlan(
        id: 'yearly',
        subject: '吃什么年度会员',
        totalAmount: '12.00',
        days: 365,
      ),
    },
    membershipSigningSeed: _testSigningSeed,
    orderStorePath: '${directory.path}/payment_orders.json',
    now: _fixedNow,
  );
  final server = PaymentServer(config, gateway: gateway);
  await server.start();
  return server;
}

Future<Map<String, dynamic>> _postJson(
  HttpClient client,
  Uri uri, {
  Map<String, dynamic> body = const {},
  Map<String, String> headers = const {},
}) async {
  final request = await client.postUrl(uri)
    ..headers.contentType = ContentType.json;
  headers.forEach(request.headers.set);
  request.write(jsonEncode(body));
  final response = await request.close();
  final raw = await utf8.decoder.bind(response).join();
  return {
    'statusCode': response.statusCode,
    'payload': raw.isEmpty ? null : jsonDecode(raw),
  };
}

Future<Map<String, dynamic>> _getJson(
  HttpClient client,
  Uri uri, {
  Map<String, String> headers = const {},
}) async {
  final request = await client.getUrl(uri);
  headers.forEach(request.headers.set);
  final response = await request.close();
  final raw = await utf8.decoder.bind(response).join();
  return {
    'statusCode': response.statusCode,
    'payload': raw.isEmpty ? null : jsonDecode(raw),
  };
}

Future<(int, String)> _postNotify(
  HttpClient client,
  Uri uri,
  Map<String, String> fields,
) async {
  final body = fields.entries
      .map((entry) =>
          '${Uri.encodeComponent(entry.key)}=${Uri.encodeComponent(entry.value)}')
      .join('&');
  final request = await client.postUrl(uri)
    ..headers.contentType = ContentType(
      'application',
      'x-www-form-urlencoded',
    )
    ..write(body);
  final response = await request.close();
  final raw = await utf8.decoder.bind(response).join();
  return (response.statusCode, raw);
}

void main() {
  // 不初始化 TestWidgetsFlutterBinding：它会接管 HttpClient（一律 400），
  // 而这里需要真实的 loopback HTTP 请求。
  final directory = Directory.systemTemp.createTempSync('payment_server_');
  tearDownAll(() => directory.deleteSync(recursive: true));

  group('RSA PEM 解析与 RSA2 签名（openssl 交叉验证）', () {
    test('PKCS#8 与 PKCS#1 私钥解析出同一密钥并能与 SPKI 公钥互验', () async {
      final pkcs8 = RsaPem.parsePrivateKey(_merchantPrivateKeyPem);
      final pkcs1 = RsaPem.parsePrivateKey(_merchantPrivateKeyPkcs1Pem);
      final publicKey = RsaPem.parsePublicKey(_merchantPublicKeyPem);

      const content = '吃什么支付服务端测试内容';
      final signature = AlipaySigner.signContent(content, pkcs8);
      expect(
        AlipaySigner.verifyContent(content, signature, publicKey),
        isTrue,
      );
      final signature1 = AlipaySigner.signContent(content, pkcs1);
      expect(signature, signature1);
    });

    test('openssl 生成的固定签名可被本实现验签，篡改即失败', () async {
      final publicKey = RsaPem.parsePublicKey(_merchantPublicKeyPem);
      expect(
        AlipaySigner.verifyContent(
          _opensslSignedContent,
          _opensslSignatureBase64,
          publicKey,
        ),
        isTrue,
      );
      expect(
        AlipaySigner.verifyContent(
          _opensslMerchantRequestParamContent,
          _opensslMerchantRequestParamSignatureBase64,
          publicKey,
        ),
        isTrue,
      );
      expect(
        AlipaySigner.verifyContent(
          '$_opensslSignedContent-tampered',
          _opensslSignatureBase64,
          publicKey,
        ),
        isFalse,
      );
      expect(
        AlipaySigner.verifyContent(
          _opensslSignedContent,
          'AAAA',
          publicKey,
        ),
        isFalse,
      );
    });

    test('canonicalParams 排序并排除 sign/sign_type 与空值', () {
      expect(
        AlipaySigner.canonicalParams({
          'method': 'alipay.trade.wap.pay',
          'sign_type': 'RSA2',
          'sign': 'should-be-excluded',
          'charset': 'utf-8',
          'app_id': '2021000000000002',
          'empty': '',
        }),
        'app_id=2021000000000002&charset=utf-8&method=alipay.trade.wap.pay',
      );
    });
  });

  group('支付服务端订单与凭证生命周期', () {
    late PaymentServer server;
    late _RecordingGateway gateway;
    late Uri base;
    late HttpClient client;

    setUp(() async {
      gateway = _RecordingGateway();
      server = await _startServer(gateway, directory: directory);
      base = Uri.parse('http://127.0.0.1:${server.port}');
      client = HttpClient();
    });

    tearDown(() async {
      client.close(force: true);
      await server.close();
    });

    Map<String, String> authHeader() =>
        {'Authorization': 'Bearer ${_jwtFor(_testUserId)}'};

    Future<String> createOrder({
      Map<String, String> headers = const {},
      Map<String, dynamic> body = const {'plan': 'yearly'},
    }) async {
      final response = await _postJson(
        client,
        base.resolve('api/v1/payment/alipay/orders'),
        body: body,
        headers: headers,
      );
      expect(response['statusCode'], 200, reason: '${response['payload']}');
      final payload = response['payload'] as Map<String, dynamic>;
      expect(payload['status'], 'payment_required');
      expect(payload['plan'], 'yearly');
      expect(payload['payUrl'].toString(), isNotEmpty);
      return payload['orderId'].toString();
    }

    test('未鉴权创建订单被拒绝', () async {
      final response = await _postJson(
        client,
        base.resolve('api/v1/payment/alipay/orders'),
      );
      expect(response['statusCode'], 401);
    });

    test('未知套餐被拒绝', () async {
      final response = await _postJson(
        client,
        base.resolve('api/v1/payment/alipay/orders'),
        body: {'plan': 'lifetime'},
        headers: authHeader(),
      );
      expect(response['statusCode'], 422);
    });

    test('创建订单返回签名 payUrl 并落 pending 订单，身份取 JWT 而非 body', () async {
      final orderId = await createOrder(
        headers: authHeader(),
        body: {'plan': 'yearly', 'userId': _otherUserId},
      );
      expect(orderId, isNotEmpty);
      expect(gateway.wapPayRequests.single['totalAmount'], '12.00');
      expect(gateway.wapPayRequests.single['subject'], '吃什么年度会员');

      final status = await _getJson(
        client,
        base.resolve('api/v1/payment/alipay/status?orderId=$orderId'),
        headers: authHeader(),
      );
      expect(status['statusCode'], 200);
      expect((status['payload'] as Map)['status'], 'pending');
      expect(
        (status['payload'] as Map).containsKey('membershipCredential'),
        isFalse,
      );
    });

    test('支付前查询他人订单返回 404', () async {
      final orderId = await createOrder(headers: authHeader());
      final response = await _getJson(
        client,
        base.resolve('api/v1/payment/alipay/status?orderId=$orderId'),
        headers: {'Authorization': 'Bearer ${_jwtFor(_otherUserId)}'},
      );
      expect(response['statusCode'], 404);
    });

    test('notify 签名有效才标记支付，之后 status 返回绑定 JWT 用户且可验签的凭证', () async {
      final orderId = await createOrder(headers: authHeader());

      final notifyParams = {
        'app_id': '2021000000000002',
        'charset': 'utf-8',
        'out_trade_no': orderId,
        'trade_no': '2026092022001400000',
        'total_amount': '12.00',
        'trade_status': 'TRADE_SUCCESS',
        'sign_type': 'RSA2',
      };
      final content = AlipaySigner.canonicalParams(notifyParams);
      final alipayKey = RsaPem.parsePrivateKey(_alipayPrivateKeyPem);
      final notify = await _postNotify(
        client,
        base.resolve('api/v1/payment/alipay/notify'),
        {
          ...notifyParams,
          'sign': AlipaySigner.signContent(content, alipayKey),
        },
      );
      expect(notify, (200, 'success'));

      final status = await _getJson(
        client,
        base.resolve('api/v1/payment/alipay/status?orderId=$orderId'),
        headers: authHeader(),
      );
      expect(status['statusCode'], 200);
      final payload = status['payload'] as Map<String, dynamic>;
      expect(payload['status'], 'paid');
      final credentialJson = payload['membershipCredential'] as Map;
      expect(credentialJson['userId'], _testUserId);
      expect(credentialJson['orderId'], orderId);

      final credential = MembershipCredential.fromJson(credentialJson);
      expect(credential, isNotNull);
      final publicKey = await MembershipCredentials.publicKeyFromSeed(
        _testSigningSeed,
      );
      final valid = await Ed25519().verify(
        utf8.encode(credential!.canonicalPayload),
        signature: Signature(
          base64Decode(credential.signature),
          publicKey: publicKey,
        ),
      );
      expect(valid, isTrue);
      expect(
        credential.expiresAt.difference(credential.issuedAt).inDays,
        365,
      );
    });

    test('notify 篡改、错 app_id、错金额、未知订单均被拒绝且订单保持 pending', () async {
      final orderId = await createOrder(headers: authHeader());
      final alipayKey = RsaPem.parsePrivateKey(_alipayPrivateKeyPem);

      Future<(int, String)> sendNotify(Map<String, String> params) async {
        final content = AlipaySigner.canonicalParams(params);
        return _postNotify(
          client,
          base.resolve('api/v1/payment/alipay/notify'),
          {
            ...params,
            'sign': AlipaySigner.signContent(content, alipayKey),
          },
        );
      }

      final tampered = {
        'app_id': '2021000000000002',
        'out_trade_no': orderId,
        'total_amount': '0.01',
        'trade_status': 'TRADE_SUCCESS',
        'sign_type': 'RSA2',
      };
      final tamperedContent =
          'app_id=2021000000000002&out_trade_no=$orderId&total_amount=12.00&trade_status=TRADE_SUCCESS';
      final tamperedResponse = await _postNotify(
        client,
        base.resolve('api/v1/payment/alipay/notify'),
        {
          ...tampered,
          'sign': AlipaySigner.signContent(tamperedContent, alipayKey),
        },
      );
      expect(tamperedResponse.$2, 'failure');

      expect(
        (await sendNotify({
          'app_id': '2021999999999999',
          'out_trade_no': orderId,
          'total_amount': '12.00',
          'trade_status': 'TRADE_SUCCESS',
          'sign_type': 'RSA2',
        }))
            .$2,
        'failure',
      );
      expect(
        (await sendNotify({
          'app_id': '2021000000000002',
          'out_trade_no': 'EW-not-exist',
          'total_amount': '12.00',
          'trade_status': 'TRADE_SUCCESS',
          'sign_type': 'RSA2',
        }))
            .$2,
        'failure',
      );

      final status = await _getJson(
        client,
        base.resolve('api/v1/payment/alipay/status?orderId=$orderId'),
        headers: authHeader(),
      );
      expect((status['payload'] as Map)['status'], 'pending');
    });

    test('重复 notify 幂等，凭证字节不变', () async {
      final orderId = await createOrder(headers: authHeader());
      final alipayKey = RsaPem.parsePrivateKey(_alipayPrivateKeyPem);
      final params = {
        'app_id': '2021000000000002',
        'out_trade_no': orderId,
        'total_amount': '12.00',
        'trade_status': 'TRADE_SUCCESS',
        'sign_type': 'RSA2',
      };
      final sign = AlipaySigner.signContent(
        AlipaySigner.canonicalParams(params),
        alipayKey,
      );
      final first = await _postNotify(
        client,
        base.resolve('api/v1/payment/alipay/notify'),
        {...params, 'sign': sign},
      );
      final second = await _postNotify(
        client,
        base.resolve('api/v1/payment/alipay/notify'),
        {...params, 'sign': sign},
      );
      expect(first, (200, 'success'));
      expect(second, (200, 'success'));

      Future<Map> readCredential() async {
        final status = await _getJson(
          client,
          base.resolve('api/v1/payment/alipay/status?orderId=$orderId'),
          headers: authHeader(),
        );
        return (status['payload']
            as Map<String, dynamic>)['membershipCredential'] as Map;
      }

      final firstCredential = await readCredential();
      final secondCredential = await readCredential();
      expect(jsonEncode(secondCredential), jsonEncode(firstCredential));
    });

    test('trade.query 兜底把 TRADE_SUCCESS 订单置为 paid', () async {
      final paidGateway = _RecordingGateway(tradeStatus: 'TRADE_SUCCESS');
      final paidServer = await _startServer(paidGateway, directory: directory);
      final paidBase = Uri.parse('http://127.0.0.1:${paidServer.port}');
      final paidClient = HttpClient();
      try {
        final created = await _postJson(
          paidClient,
          paidBase.resolve('api/v1/payment/alipay/orders'),
          body: {'plan': 'yearly'},
          headers: {'Authorization': 'Bearer ${_jwtFor(_testUserId)}'},
        );
        expect(created['statusCode'], 200);
        final orderId = (created['payload'] as Map)['orderId'].toString();

        final status = await _getJson(
          paidClient,
          paidBase.resolve('api/v1/payment/alipay/status?orderId=$orderId'),
          headers: {'Authorization': 'Bearer ${_jwtFor(_testUserId)}'},
        );
        expect(status['statusCode'], 200);
        expect((status['payload'] as Map)['status'], 'paid');
        expect(paidGateway.queryRequests, [orderId]);
      } finally {
        paidClient.close(force: true);
        await paidServer.close();
      }
    });

    test('本地开发模式（无 JWT 密钥）：body userId 绑定订单，status 免鉴权', () async {
      final localGateway = _RecordingGateway();
      final localServer = await _startServer(
        localGateway,
        directory: directory,
        requireJwt: false,
      );
      final localBase = Uri.parse('http://127.0.0.1:${localServer.port}');
      final localClient = HttpClient();
      try {
        final created = await _postJson(
          localClient,
          localBase.resolve('api/v1/payment/alipay/orders'),
          body: {'plan': 'yearly', 'userId': 'local-user-42'},
        );
        expect(created['statusCode'], 200);
        final orderId = (created['payload'] as Map)['orderId'].toString();

        final params = {
          'app_id': '2021000000000002',
          'out_trade_no': orderId,
          'total_amount': '12.00',
          'trade_status': 'TRADE_SUCCESS',
          'sign_type': 'RSA2',
        };
        final notify = await _postNotify(
          localClient,
          localBase.resolve('api/v1/payment/alipay/notify'),
          {
            ...params,
            'sign': AlipaySigner.signContent(
              AlipaySigner.canonicalParams(params),
              RsaPem.parsePrivateKey(_alipayPrivateKeyPem),
            ),
          },
        );
        expect(notify, (200, 'success'));

        final status = await _getJson(
          localClient,
          localBase.resolve('api/v1/payment/alipay/status?orderId=$orderId'),
        );
        expect(status['statusCode'], 200);
        final payload = status['payload'] as Map<String, dynamic>;
        expect(payload['status'], 'paid');
        expect((payload['membershipCredential'] as Map)['userId'],
            'local-user-42');
      } finally {
        localClient.close(force: true);
        await localServer.close();
      }
    });
  });

  group('查询响应签名提取', () {
    test('提取响应节点原文并验签，篡改失败', () async {
      final alipayKey = RsaPem.parsePrivateKey(_alipayPrivateKeyPem);
      final responseBody = jsonEncode({
        'alipay_trade_query_response': {
          'code': '10000',
          'msg': 'Success',
          'out_trade_no': 'EW17500000000001',
          'trade_status': 'TRADE_SUCCESS',
          'total_amount': '12.00',
        },
        'sign': 'placeholder',
      });
      final nodeStart = responseBody.indexOf('"alipay_trade_query_response":');
      final nodeEnd = responseBody.indexOf(',"sign"');
      final nodeContent = responseBody
          .substring(nodeStart, nodeEnd)
          .split(':')
          .skip(1)
          .join(':')
          .trim();
      final signature = AlipaySigner.signContent(nodeContent, alipayKey);
      final signed = responseBody.replaceFirst('"placeholder"', signature);

      expect(
        PaymentSignedNodes.verifyQueryResponse(
          signed,
          publicKey: RsaPem.parsePublicKey(_alipayPublicKeyPem),
        ),
        isTrue,
      );
      expect(
        PaymentSignedNodes.verifyQueryResponse(
          signed.replaceFirst('TRADE_SUCCESS', 'TRADE_FINISHED'),
          publicKey: RsaPem.parsePublicKey(_alipayPublicKeyPem),
        ),
        isFalse,
      );
    });
  });

  test('真实网关构建 wap.pay URL：参数齐全且签名可用商户公钥验签', () async {
    final gateway = AlipayGateway.http(
      appId: '2021000000000000000',
      gatewayUrl: 'https://openapi.alipay.com/gateway.do',
      merchantPrivateKeyPem: _merchantPrivateKeyPem,
      alipayPublicKeyPem: _alipayPublicKeyPem,
      now: _fixedNow,
    );
    const plan = MembershipPlan(
      id: 'yearly',
      subject: '吃什么年度会员',
      totalAmount: '12.00',
      days: 365,
    );
    final uri = gateway.buildWapPayUrl(
      outTradeNo: 'EW17500000000002',
      plan: plan,
      notifyUrl: 'https://pay.example.com/api/v1/payment/alipay/notify',
    );
    expect(uri.origin, 'https://openapi.alipay.com');
    final params = uri.queryParameters;
    expect(params['method'], 'alipay.trade.wap.pay');
    expect(params['app_id'], '2021000000000000000');
    expect(params['charset'], 'utf-8');
    expect(params['sign_type'], 'RSA2');
    expect(params['version'], '1.0');
    expect(params['timestamp'], '2026-09-20 12:00:00');
    expect(params['notify_url'],
        'https://pay.example.com/api/v1/payment/alipay/notify');
    final bizContent =
        jsonDecode(params['biz_content']!) as Map<String, dynamic>;
    expect(bizContent['out_trade_no'], 'EW17500000000002');
    expect(bizContent['total_amount'], '12.00');
    expect(bizContent['product_code'], 'QUICK_WAP_WAY');
    expect(bizContent['subject'], '吃什么年度会员');

    final sign = params['sign']!;
    final signLess = {
      for (final entry in uri.queryParameters.entries)
        if (entry.key != 'sign') entry.key: entry.value,
    };
    final verified = AlipaySigner.verifyContent(
      AlipaySigner.canonicalParams(signLess),
      sign,
      RsaPem.parsePublicKey(_merchantPublicKeyPem),
    );
    expect(verified, isTrue);
  });
}
