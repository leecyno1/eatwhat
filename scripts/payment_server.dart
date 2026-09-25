import 'dart:convert';
import 'dart:io';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:eatwhat_app/v2/core/services/membership_credential.dart';

import 'execution_proxy_server.dart' show EatWhatJwtVerifier;

/// 支付服务端（P1-1 真实支付）：
/// - 创建会员订单并对 alipay.trade.wap.pay 请求做 RSA2 签名（商户私钥仅存服务端）；
/// - 接收支付宝异步通知（notify），用支付宝平台公钥验签后把订单置为已支付；
/// - 支付成功后用 Ed25519 种子签发会员凭证（[MembershipCredentials]），
///   客户端轮询 status 拿到凭证并本地验签升级；
/// - status 在 notify 未到达时用 trade.query 兜底核对（响应节点验签）。
///
/// 密钥全部来自环境变量（见 .env.example 的 ALIPAY_* / PAYMENT_* 段），
/// 不落仓库。本地开发：JWT_SECRET 留空 = 本地模式（body userId / 网关头生效）。
Future<void> main(List<String> args) async {
  final config = PaymentServerConfig.fromEnvironment(
    Platform.environment,
    args: args,
  );
  final errors = config.startupErrors();
  if (errors.isNotEmpty) {
    stderr.writeln('支付服务端配置不完整：');
    for (final error in errors) {
      stderr.writeln('  - $error');
    }
    exit(1);
  }
  if (config.jwtSecret.isEmpty) {
    stderr.writeln('警告：JWT_SECRET 为空，运行在本地开发模式'
        '（不校验登录态，body userId / x-eatwhat-user-id 直接生效）');
  }

  final PaymentServer server;
  try {
    server = PaymentServer(config);
  } on FormatException catch (error) {
    stderr.writeln('支付宝密钥解析失败：${error.message}');
    exit(1);
  }
  await server.start();
  stdout
    ..writeln(
      'Payment server listening on '
      'http://${config.bindAddress.address}:${server.port}',
    )
    ..writeln('GET  /health')
    ..writeln('POST /api/v1/payment/alipay/orders')
    ..writeln('GET  /api/v1/payment/alipay/status')
    ..writeln('POST /api/v1/payment/alipay/notify');
}

/// 会员套餐：价格等敏感参数必须显式配置，不允许代码里猜默认值。
class MembershipPlan {
  const MembershipPlan({
    required this.id,
    required this.subject,
    required this.totalAmount,
    required this.days,
  });

  final String id;
  final String subject;

  /// 元为单位的金额字符串（如 '12.00'），与支付宝 total_amount 口径一致。
  final String totalAmount;
  final int days;
}

/// RSA 公钥（BigInt 形式）。cryptography 包的纯 Dart RSA 签名是
/// UnimplementedError，这里直接用 BigInt 实现签名/验签（PKCS#1 v1.5）。
class RsaPublicKey {
  const RsaPublicKey({required this.n, required this.e});

  final BigInt n;
  final BigInt e;

  int get modulusLengthInBytes => (n.bitLength + 7) ~/ 8;
}

class RsaPrivateKey {
  const RsaPrivateKey({
    required this.n,
    required this.e,
    required this.d,
    required this.p,
    required this.q,
    required this.dp,
    required this.dq,
    required this.qi,
  });

  final BigInt n;
  final BigInt e;
  final BigInt d;
  final BigInt p;
  final BigInt q;
  final BigInt dp;
  final BigInt dq;

  /// q^-1 mod p（CRT 系数）。
  final BigInt qi;

  RsaPublicKey get publicKey => RsaPublicKey(n: n, e: e);

  int get modulusLengthInBytes => (n.bitLength + 7) ~/ 8;
}

/// 解析 PEM 编码的 RSA 密钥：私钥支持 PKCS#8（BEGIN PRIVATE KEY）与
/// PKCS#1（BEGIN RSA PRIVATE KEY），公钥支持 SPKI（BEGIN PUBLIC KEY）。
class RsaPem {
  RsaPem._();

  static RsaPrivateKey parsePrivateKey(String pem) {
    final (label, der) = _decodePem(pem);
    switch (label) {
      case 'RSA PRIVATE KEY':
        return _parsePkcs1PrivateKey(der);
      case 'PRIVATE KEY':
        return _parsePkcs8PrivateKey(der);
      default:
        throw FormatException('不支持的私钥 PEM 格式：$label');
    }
  }

  static RsaPublicKey parsePublicKey(String pem) {
    final (label, der) = _decodePem(pem);
    if (label != 'PUBLIC KEY') {
      throw FormatException('不支持的公钥 PEM 格式：$label');
    }
    return _parseSpkiPublicKey(der);
  }

  static (String, List<int>) _decodePem(String pem) {
    final beginMatch =
        RegExp(r'-----BEGIN ([A-Z0-9 ]+)-----').firstMatch(pem.trim());
    if (beginMatch == null) {
      throw const FormatException('PEM 缺少 BEGIN 标记');
    }
    final label = beginMatch.group(1)!;
    final endMarker = '-----END $label-----';
    final end = pem.indexOf(endMarker, beginMatch.end);
    if (end < 0) {
      throw const FormatException('PEM 缺少 END 标记');
    }
    final body =
        pem.substring(beginMatch.end, end).replaceAll(RegExp(r'\s'), '');
    return (label, base64.decode(body));
  }

  static RsaPrivateKey _parsePkcs1PrivateKey(List<int> der) {
    final reader = _DerReader(der).readSequence();
    final version = reader.readInteger();
    if (version != BigInt.zero) {
      throw const FormatException('不支持的 RSAPrivateKey 版本');
    }
    final n = reader.readInteger();
    final e = reader.readInteger();
    final d = reader.readInteger();
    final p = reader.readInteger();
    final q = reader.readInteger();
    final dp = reader.readInteger();
    final dq = reader.readInteger();
    final qi = reader.readInteger();
    return RsaPrivateKey(
      n: n,
      e: e,
      d: d,
      p: p,
      q: q,
      dp: dp,
      dq: dq,
      qi: qi,
    );
  }

  static RsaPrivateKey _parsePkcs8PrivateKey(List<int> der) {
    final reader = _DerReader(der).readSequence();
    final version = reader.readInteger();
    if (version != BigInt.zero) {
      throw const FormatException('不支持的 PrivateKeyInfo 版本');
    }
    final algorithm = reader.readSequence();
    _expectRsaEncryption(algorithm);
    // OCTET STRING 内层即 PKCS#1 RSAPrivateKey。
    final innerDer = reader.readTag(0x04);
    return _parsePkcs1PrivateKey(innerDer);
  }

  static RsaPublicKey _parseSpkiPublicKey(List<int> der) {
    final reader = _DerReader(der).readSequence();
    final algorithm = reader.readSequence();
    _expectRsaEncryption(algorithm);
    final bitString = reader.readTag(0x03);
    if (bitString.isEmpty || bitString.first != 0) {
      throw const FormatException('SPKI BIT STRING 无效');
    }
    final inner = _DerReader(bitString.sublist(1)).readSequence();
    final n = inner.readInteger();
    final e = inner.readInteger();
    return RsaPublicKey(n: n, e: e);
  }

  static void _expectRsaEncryption(_DerReader algorithm) {
    final oid = algorithm.readTag(0x06);
    const expected = [
      0x2a,
      0x86,
      0x48,
      0x86,
      0xf7,
      0x0d,
      0x01,
      0x01,
      0x01,
    ];
    if (oid.length != expected.length) {
      throw const FormatException('不是 RSA 密钥（OID 不符）');
    }
    for (var i = 0; i < expected.length; i++) {
      if (oid[i] != expected[i]) {
        throw const FormatException('不是 RSA 密钥（OID 不符）');
      }
    }
  }
}

/// 极简 DER TLV 读取器：只覆盖 RSA 密钥结构需要的标签。
class _DerReader {
  _DerReader(this.bytes);

  final List<int> bytes;
  int _offset = 0;

  List<int> readTag(int expectedTag) {
    if (_offset + 2 > bytes.length) {
      throw const FormatException('DER 数据截断');
    }
    if (bytes[_offset] != expectedTag) {
      throw FormatException(
        'DER 标签不匹配：期望 0x${expectedTag.toRadixString(16)}，'
        '实际 0x${bytes[_offset].toRadixString(16)}',
      );
    }
    var length = bytes[_offset + 1];
    var headerSize = 2;
    if (length & 0x80 != 0) {
      final count = length & 0x7f;
      if (count == 0 || count > 4 || _offset + 2 + count > bytes.length) {
        throw const FormatException('DER 长度字段无效');
      }
      length = 0;
      for (var i = 0; i < count; i++) {
        length = (length << 8) | bytes[_offset + 2 + i];
      }
      headerSize = 2 + count;
    }
    final start = _offset + headerSize;
    final end = start + length;
    if (end > bytes.length) {
      throw const FormatException('DER 内容越界');
    }
    _offset = end;
    return bytes.sublist(start, end);
  }

  _DerReader readSequence() => _DerReader(readTag(0x30));

  BigInt readInteger() {
    final content = readTag(0x02);
    if (content.isEmpty) {
      throw const FormatException('DER INTEGER 为空');
    }
    return _bytesToBigInt(content);
  }
}

List<int> _bigIntToBytes(BigInt value, {int? length}) {
  var hex = value.toRadixString(16);
  if (hex.length.isOdd) {
    hex = '0$hex';
  }
  final bytes = <int>[
    for (var i = 0; i < hex.length; i += 2)
      int.parse(hex.substring(i, i + 2), radix: 16),
  ];
  if (length == null || bytes.length >= length) {
    return bytes;
  }
  return <int>[...List<int>.filled(length - bytes.length, 0), ...bytes];
}

BigInt _bytesToBigInt(List<int> bytes) {
  var result = BigInt.zero;
  for (final byte in bytes) {
    result = (result << 8) | BigInt.from(byte);
  }
  return result;
}

/// RSA2（RSASSA-PKCS1-v1_5 + SHA-256）与支付宝参数规范化。
class AlipaySigner {
  AlipaySigner._();

  /// SHA-256 DigestInfo 的 DER 前缀（不含 32 字节摘要本体）。
  static const _sha256DigestInfoPrefix = [
    0x30,
    0x31,
    0x30,
    0x0d,
    0x06,
    0x09,
    0x60,
    0x86,
    0x48,
    0x01,
    0x65,
    0x03,
    0x04,
    0x02,
    0x01,
    0x05,
    0x00,
    0x04,
    0x20,
  ];

  /// 参数按 key 字典序排列，排除 sign / sign_type 与空值，
  /// 以「key=value」用 & 连接（值为原始值，不做 URL 编码）。
  static String canonicalParams(Map<String, String> params) {
    final entries = params.entries
        .where(
          (entry) =>
              entry.key != 'sign' &&
              entry.key != 'sign_type' &&
              entry.value.isNotEmpty,
        )
        .toList()
      ..sort((a, b) => a.key.compareTo(b.key));
    return entries.map((entry) => '${entry.key}=${entry.value}').join('&');
  }

  static String signContent(String content, RsaPrivateKey key) {
    final em = _buildEm(utf8.encode(content), key.modulusLengthInBytes);
    final m = _bytesToBigInt(em);
    // CRT：openssl 导出的密钥自带 dp/dq/qi。
    final m1 = m.modPow(key.dp, key.p);
    final m2 = m.modPow(key.dq, key.q);
    final h = (key.qi * (m1 - m2)) % key.p;
    final s = m2 + h * key.q;
    return base64Encode(_bigIntToBytes(s, length: key.modulusLengthInBytes));
  }

  static bool verifyContent(
    String content,
    String signatureBase64,
    RsaPublicKey key,
  ) {
    try {
      final signature = base64Decode(signatureBase64);
      final s = _bytesToBigInt(signature);
      if (s < BigInt.zero || s >= key.n) return false;
      final em = _bigIntToBytes(
        s.modPow(key.e, key.n),
        length: key.modulusLengthInBytes,
      );
      final expected = _buildEm(utf8.encode(content), key.modulusLengthInBytes);
      if (em.length != expected.length) return false;
      var difference = 0;
      for (var i = 0; i < em.length; i++) {
        difference |= em[i] ^ expected[i];
      }
      return difference == 0;
    } on Object {
      return false;
    }
  }

  static List<int> _buildEm(List<int> message, int modulusLength) {
    final t = [..._sha256DigestInfoPrefix, ...sha256.convert(message).bytes];
    if (modulusLength < t.length + 11) {
      throw const FormatException('RSA 模数长度不足以容纳摘要');
    }
    return <int>[
      0x00,
      0x01,
      ...List<int>.filled(modulusLength - t.length - 3, 0xff),
      0x00,
      ...t,
    ];
  }
}

/// 支付宝对响应的内层节点（如 alipay_trade_query_response）签名，
/// 必须提取节点原文验签，不能用 jsonDecode 后重新序列化的结果。
class PaymentSignedNodes {
  const PaymentSignedNodes._();

  static bool verifyQueryResponse(
    String rawBody, {
    required RsaPublicKey publicKey,
  }) {
    const nodeKey = '"alipay_trade_query_response":';
    final nodeStart = rawBody.indexOf(nodeKey);
    if (nodeStart < 0) return false;
    // key 之后到对象首个 '{' 之间只可能是空白。
    final valueStart = rawBody.indexOf('{', nodeStart + nodeKey.length);
    if (valueStart < 0) return false;
    final nodeEnd = _matchingBraceEnd(rawBody, valueStart);
    if (nodeEnd < 0) return false;
    final sign = _extractSign(rawBody);
    if (sign == null || sign.isEmpty) return false;
    return AlipaySigner.verifyContent(
      rawBody.substring(valueStart, nodeEnd + 1),
      sign,
      publicKey,
    );
  }

  static String? _extractSign(String rawBody) {
    final keyIndex = rawBody.indexOf('"sign":');
    if (keyIndex < 0) return null;
    var index = keyIndex + '"sign":'.length;
    while (index < rawBody.length &&
        (rawBody[index] == ' ' ||
            rawBody[index] == '\n' ||
            rawBody[index] == '\r' ||
            rawBody[index] == '\t')) {
      index++;
    }
    if (index >= rawBody.length) return null;
    if (rawBody[index] == '"') {
      final end = rawBody.indexOf('"', index + 1);
      if (end < 0) return null;
      return rawBody.substring(index + 1, end);
    }
    var end = index;
    while (end < rawBody.length && _isBase64Byte(rawBody.codeUnitAt(end))) {
      end++;
    }
    return rawBody.substring(index, end);
  }

  static bool _isBase64Byte(int code) =>
      (code >= 0x30 && code <= 0x39) ||
      (code >= 0x41 && code <= 0x5a) ||
      (code >= 0x61 && code <= 0x7a) ||
      code == 0x2b ||
      code == 0x2f ||
      code == 0x3d;

  static int _matchingBraceEnd(String source, int openIndex) {
    var depth = 0;
    var inString = false;
    var escaped = false;
    for (var i = openIndex; i < source.length; i++) {
      final code = source.codeUnitAt(i);
      if (escaped) {
        escaped = false;
        continue;
      }
      if (inString) {
        if (code == 0x5c) {
          escaped = true;
        } else if (code == 0x22) {
          inString = false;
        }
        continue;
      }
      if (code == 0x22) {
        inString = true;
      } else if (code == 0x7b) {
        depth++;
      } else if (code == 0x7d) {
        depth--;
        if (depth == 0) return i;
      }
    }
    return -1;
  }
}

class AlipayTradeQueryResult {
  const AlipayTradeQueryResult({required this.tradeStatus});

  final String tradeStatus;
}

/// 支付宝网关访问。签名/验签、网关地址、密钥全部在服务端，
/// 客户端只拿到 buildWapPayUrl 产生的收银台地址。
abstract class AlipayGateway {
  factory AlipayGateway.http({
    required String appId,
    required String gatewayUrl,
    required String merchantPrivateKeyPem,
    required String alipayPublicKeyPem,
    required DateTime Function() now,
  }) {
    return HttpAlipayGateway(
      appId: appId,
      gatewayUrl: gatewayUrl,
      merchantPrivateKeyPem: merchantPrivateKeyPem,
      alipayPublicKeyPem: alipayPublicKeyPem,
      now: now,
    );
  }

  Uri buildWapPayUrl({
    required String outTradeNo,
    required MembershipPlan plan,
    required String notifyUrl,
  });

  Future<AlipayTradeQueryResult?> queryTrade({required String outTradeNo});
}

class HttpAlipayGateway implements AlipayGateway {
  HttpAlipayGateway({
    required this.appId,
    required String gatewayUrl,
    required String merchantPrivateKeyPem,
    required String alipayPublicKeyPem,
    required DateTime Function() now,
    HttpClient? httpClient,
  })  : gatewayUrl = Uri.parse(gatewayUrl),
        _merchantKeyPair = RsaPem.parsePrivateKey(merchantPrivateKeyPem),
        _alipayPublicKey = RsaPem.parsePublicKey(alipayPublicKeyPem),
        _now = now,
        _httpClient = httpClient ?? HttpClient() {
    _httpClient.connectionTimeout = const Duration(seconds: 10);
  }

  final String appId;
  final Uri gatewayUrl;
  final RsaPrivateKey _merchantKeyPair;
  final RsaPublicKey _alipayPublicKey;
  final DateTime Function() _now;
  final HttpClient _httpClient;

  @override
  Uri buildWapPayUrl({
    required String outTradeNo,
    required MembershipPlan plan,
    required String notifyUrl,
  }) {
    final params = _commonParams('alipay.trade.wap.pay')
      ..['notify_url'] = notifyUrl
      ..['biz_content'] = jsonEncode({
        'out_trade_no': outTradeNo,
        'total_amount': plan.totalAmount,
        'product_code': 'QUICK_WAP_WAY',
        'subject': plan.subject,
      });
    final sign = _signedQuery(params);
    return gatewayUrl.replace(query: sign);
  }

  @override
  Future<AlipayTradeQueryResult?> queryTrade({
    required String outTradeNo,
  }) async {
    final params = _commonParams('alipay.trade.query')
      ..['biz_content'] = jsonEncode({'out_trade_no': outTradeNo});
    final body = _signedQuery(params);

    final request = await _httpClient.postUrl(gatewayUrl);
    request
      ..headers.contentType = ContentType(
        'application',
        'x-www-form-urlencoded',
        charset: 'utf-8',
      )
      ..write(body);
    final response = await request.close();
    final rawBody = await utf8.decoder.bind(response).join();
    if (!PaymentSignedNodes.verifyQueryResponse(
      rawBody,
      publicKey: _alipayPublicKey,
    )) {
      return null;
    }
    final decoded = jsonDecode(rawBody);
    if (decoded is! Map) return null;
    final node = decoded['alipay_trade_query_response'];
    if (node is! Map || node['code']?.toString() != '10000') return null;
    final tradeStatus = node['trade_status']?.toString();
    if (tradeStatus == null || tradeStatus.isEmpty) return null;
    return AlipayTradeQueryResult(tradeStatus: tradeStatus);
  }

  Map<String, String> _commonParams(String method) => {
        'app_id': appId,
        'charset': 'utf-8',
        'method': method,
        'sign_type': 'RSA2',
        'timestamp': _formatAlipayTimestamp(_now()),
        'version': '1.0',
      };

  String _signedQuery(Map<String, String> params) {
    final sign = AlipaySigner.signContent(
      AlipaySigner.canonicalParams(params),
      _merchantKeyPair,
    );
    return [
      ...params.entries.map(
        (entry) =>
            '${Uri.encodeComponent(entry.key)}=${Uri.encodeComponent(entry.value)}',
      ),
      'sign=${Uri.encodeComponent(sign)}',
    ].join('&');
  }
}

String _formatAlipayTimestamp(DateTime time) {
  String two(int value) => value.toString().padLeft(2, '0');
  return '${time.year}-${two(time.month)}-${two(time.day)} '
      '${two(time.hour)}:${two(time.minute)}:${two(time.second)}';
}

class MembershipOrder {
  MembershipOrder({
    required this.orderId,
    required this.userId,
    required this.planId,
    required this.totalAmount,
    required this.status,
    this.membershipCredential,
  });

  factory MembershipOrder.fromJson(Map<String, dynamic> json) =>
      MembershipOrder(
        orderId: json['orderId']?.toString() ?? '',
        userId: json['userId']?.toString() ?? '',
        planId: json['planId']?.toString() ?? '',
        totalAmount: json['totalAmount']?.toString() ?? '',
        status: json['status']?.toString() ?? 'pending',
        membershipCredential: json['membershipCredential'] is Map
            ? Map<String, dynamic>.from(json['membershipCredential'] as Map)
            : null,
      );

  final String orderId;
  final String userId;
  final String planId;
  final String totalAmount;
  final String status;

  /// 已签发的会员凭证（订单支付后落库，重复请求返回同一份字节）。
  final Map<String, dynamic>? membershipCredential;

  bool get isPaid => status == 'paid';

  MembershipOrder copyWith({
    String? status,
    Map<String, dynamic>? membershipCredential,
  }) =>
      MembershipOrder(
        orderId: orderId,
        userId: userId,
        planId: planId,
        totalAmount: totalAmount,
        status: status ?? this.status,
        membershipCredential: membershipCredential ?? this.membershipCredential,
      );

  Map<String, dynamic> toJson() => {
        'orderId': orderId,
        'userId': userId,
        'planId': planId,
        'totalAmount': totalAmount,
        'status': status,
        if (membershipCredential != null)
          'membershipCredential': membershipCredential,
      };
}

/// 订单 JSON 文件存储：单进程内存态 + 每次变更全量落盘。
class MembershipOrderStore {
  MembershipOrderStore(String path) : _file = File(path) {
    _load();
  }

  final File _file;
  final Map<String, MembershipOrder> _orders = {};

  MembershipOrder? find(String orderId) => _orders[orderId];

  void upsert(MembershipOrder order) {
    _orders[order.orderId] = order;
    final parent = _file.parent;
    if (!parent.existsSync()) {
      parent.createSync(recursive: true);
    }
    _file.writeAsStringSync(
      jsonEncode([for (final order in _orders.values) order.toJson()]),
    );
  }

  void _load() {
    if (!_file.existsSync()) return;
    try {
      final decoded = jsonDecode(_file.readAsStringSync());
      if (decoded is! List) return;
      for (final item in decoded) {
        if (item is! Map) continue;
        final order = MembershipOrder.fromJson(Map<String, dynamic>.from(item));
        if (order.orderId.isNotEmpty) {
          _orders[order.orderId] = order;
        }
      }
    } on FormatException {
      // 损坏的持久化文件按空订单表处理。
    }
  }
}

class PaymentServerConfig {
  PaymentServerConfig({
    required this.bindAddress,
    required this.port,
    required this.jwtSecret,
    required this.localUserId,
    required this.alipayAppId,
    required this.alipayGatewayUrl,
    required this.alipayMerchantPrivateKeyPem,
    required this.alipayPublicKeyPem,
    required this.notifyUrl,
    required this.plans,
    required this.membershipSigningSeed,
    required this.orderStorePath,
    this.allowedOrigin,
    this.now = _defaultNow,
  });

  factory PaymentServerConfig.fromEnvironment(
    Map<String, String> environment, {
    List<String> args = const [],
  }) {
    final bindAddress = InternetAddress.tryParse(
          environment['PAYMENT_SERVER_BIND_ADDRESS'] ?? '',
        ) ??
        InternetAddress.loopbackIPv4;
    final port = args.isNotEmpty
        ? int.tryParse(args.first) ?? 8788
        : int.tryParse(environment['PAYMENT_SERVER_PORT'] ?? '') ?? 8788;

    final plans = <String, MembershipPlan>{};
    final planKeyPattern = RegExp(r'^PAYMENT_PLAN_([A-Z0-9]+)_TOTAL_AMOUNT$');
    for (final entry in environment.entries) {
      final match = planKeyPattern.firstMatch(entry.key);
      if (match == null) continue;
      final prefix = match.group(1)!;
      final subject =
          environment['PAYMENT_PLAN_${prefix}_SUBJECT']?.trim() ?? '';
      final days =
          int.tryParse(environment['PAYMENT_PLAN_${prefix}_DAYS'] ?? '');
      final totalAmount = entry.value.trim();
      if (subject.isEmpty || days == null || totalAmount.isEmpty) continue;
      plans[prefix.toLowerCase()] = MembershipPlan(
        id: prefix.toLowerCase(),
        subject: subject,
        totalAmount: totalAmount,
        days: days,
      );
    }

    return PaymentServerConfig(
      bindAddress: bindAddress,
      port: port,
      jwtSecret: environment['JWT_SECRET']?.trim() ?? '',
      localUserId: _trimmedOr(
        environment['PAYMENT_SERVER_LOCAL_USER_ID'],
        'local-eatwhat-user',
      ),
      alipayAppId: environment['ALIPAY_APP_ID']?.trim() ?? '',
      alipayGatewayUrl: _trimmedOr(
        environment['ALIPAY_GATEWAY_URL'],
        'https://openapi.alipay.com/gateway.do',
      ),
      alipayMerchantPrivateKeyPem:
          _pemFromBase64(environment['ALIPAY_MERCHANT_PRIVATE_KEY_PEM_B64']),
      alipayPublicKeyPem:
          _pemFromBase64(environment['ALIPAY_PUBLIC_KEY_PEM_B64']),
      notifyUrl: environment['PAYMENT_NOTIFY_URL']?.trim() ?? '',
      plans: plans,
      membershipSigningSeed:
          environment['MEMBERSHIP_SIGNING_SEED']?.trim() ?? '',
      orderStorePath: _trimmedOr(
        environment['PAYMENT_ORDER_STORE_PATH'],
        'payment_orders.json',
      ),
      allowedOrigin: environment['PAYMENT_ALLOWED_ORIGIN']?.trim(),
    );
  }

  final InternetAddress bindAddress;
  final int port;

  /// 与 auth 服务签发 JWT 使用的同一密钥；留空 = 本地开发模式。
  final String jwtSecret;
  final String localUserId;
  final String alipayAppId;
  final String alipayGatewayUrl;
  final String alipayMerchantPrivateKeyPem;
  final String alipayPublicKeyPem;
  final String notifyUrl;
  final Map<String, MembershipPlan> plans;
  final String membershipSigningSeed;
  final String orderStorePath;
  final String? allowedOrigin;
  final DateTime Function() now;

  /// 缺失即拒绝启动的配置项（密钥不落仓库，只走环境变量）。
  List<String> startupErrors() => [
        if (alipayAppId.isEmpty) '缺少 ALIPAY_APP_ID（支付宝开放平台应用 ID）',
        if (alipayMerchantPrivateKeyPem.isEmpty)
          '缺少 ALIPAY_MERCHANT_PRIVATE_KEY_PEM_B64（商户应用私钥 PEM 的 base64）',
        if (alipayPublicKeyPem.isEmpty)
          '缺少 ALIPAY_PUBLIC_KEY_PEM_B64（支付宝平台公钥 PEM 的 base64）',
        if (notifyUrl.isEmpty) '缺少 PAYMENT_NOTIFY_URL（异步回调的公网地址）',
        if (membershipSigningSeed.isEmpty)
          '缺少 MEMBERSHIP_SIGNING_SEED（会员凭证 Ed25519 签发种子）',
        if (plans.isEmpty)
          '缺少套餐配置：需同时设置 PAYMENT_PLAN_*_SUBJECT / '
              'PAYMENT_PLAN_*_TOTAL_AMOUNT / PAYMENT_PLAN_*_DAYS',
      ];

  static String _trimmedOr(String? value, String fallback) =>
      value == null || value.trim().isEmpty ? fallback : value.trim();

  static String _pemFromBase64(String? value) {
    final encoded = value?.trim() ?? '';
    if (encoded.isEmpty) return '';
    try {
      return utf8.decode(base64.decode(encoded));
    } on FormatException {
      return '';
    }
  }
}

DateTime _defaultNow() => DateTime.now();

class PaymentServer {
  PaymentServer(this.config, {AlipayGateway? gateway})
      : _gateway = gateway ??
            AlipayGateway.http(
              appId: config.alipayAppId,
              gatewayUrl: config.alipayGatewayUrl,
              merchantPrivateKeyPem: config.alipayMerchantPrivateKeyPem,
              alipayPublicKeyPem: config.alipayPublicKeyPem,
              now: config.now,
            ),
        _store = MembershipOrderStore(config.orderStorePath),
        _alipayPublicKey = RsaPem.parsePublicKey(config.alipayPublicKeyPem);

  final PaymentServerConfig config;
  final AlipayGateway _gateway;
  final MembershipOrderStore _store;
  final RsaPublicKey _alipayPublicKey;
  final Random _random = Random();

  HttpServer? _httpServer;

  int get port {
    final server = _httpServer;
    if (server == null) {
      throw StateError('服务尚未启动');
    }
    return server.port;
  }

  Future<void> start() async {
    final server = await HttpServer.bind(config.bindAddress, config.port);
    _httpServer = server;
    server.listen(_handleRequest);
  }

  Future<void> close() async {
    await _httpServer?.close(force: true);
    _httpServer = null;
  }

  Future<void> _handleRequest(HttpRequest request) async {
    try {
      _addCorsHeaders(request.response);
      if (request.method == 'OPTIONS') {
        request.response.statusCode = HttpStatus.noContent;
        await request.response.close();
        return;
      }
      final path = request.uri.path;
      if (request.method == 'GET' && path == '/health') {
        await _writeJson(
          request.response,
          HttpStatus.ok,
          {'status': 'ok', 'service': 'payment'},
        );
        return;
      }
      if (request.method == 'POST' && path == '/api/v1/payment/alipay/orders') {
        await _handleCreateOrder(request);
        return;
      }
      if (request.method == 'GET' && path == '/api/v1/payment/alipay/status') {
        await _handleStatus(request);
        return;
      }
      if (request.method == 'POST' && path == '/api/v1/payment/alipay/notify') {
        await _handleNotify(request);
        return;
      }
      await _writeError(
        request.response,
        HttpStatus.notFound,
        code: 'route_not_found',
        message: '路由不存在',
      );
    } on Object catch (error, stackTrace) {
      stderr.writeln('[Payment] 处理请求失败：$error\n$stackTrace');
      try {
        await _writeError(
          request.response,
          HttpStatus.internalServerError,
          code: 'internal_error',
          message: '服务内部错误',
        );
      } on Object {
        // 响应可能已关闭。
      }
    }
  }

  Future<void> _handleCreateOrder(HttpRequest request) async {
    final body = await _readJsonBody(request);
    final userId = _resolveUserId(request, body);
    if (userId == null) {
      await _writeError(
        request.response,
        HttpStatus.unauthorized,
        code: 'unauthorized',
        message: '缺少有效的登录凭证',
      );
      return;
    }
    final planId = body['plan']?.toString() ?? '';
    final plan = config.plans[planId];
    if (plan == null) {
      await _writeError(
        request.response,
        HttpStatus.unprocessableEntity,
        code: 'unknown_plan',
        message: '未知套餐：$planId',
      );
      return;
    }
    final orderId = _newOrderId();
    _store.upsert(
      MembershipOrder(
        orderId: orderId,
        userId: userId,
        planId: planId,
        totalAmount: plan.totalAmount,
        status: 'pending',
      ),
    );
    final payUrl = _gateway.buildWapPayUrl(
      outTradeNo: orderId,
      plan: plan,
      notifyUrl: config.notifyUrl,
    );
    await _writeJson(request.response, HttpStatus.ok, {
      'status': 'payment_required',
      'orderId': orderId,
      'plan': planId,
      'payUrl': payUrl.toString(),
    });
  }

  Future<void> _handleStatus(HttpRequest request) async {
    final userId = _resolveUserId(request, const <String, dynamic>{});
    if (userId == null) {
      await _writeError(
        request.response,
        HttpStatus.unauthorized,
        code: 'unauthorized',
        message: '缺少有效的登录凭证',
      );
      return;
    }
    final orderId = request.uri.queryParameters['orderId']?.trim() ?? '';
    if (orderId.isEmpty) {
      await _writeError(
        request.response,
        HttpStatus.unprocessableEntity,
        code: 'validation_error',
        message: 'orderId 不能为空',
      );
      return;
    }
    var order = _store.find(orderId);
    if (order == null ||
        (config.jwtSecret.isNotEmpty && order.userId != userId)) {
      await _writeError(
        request.response,
        HttpStatus.notFound,
        code: 'order_not_found',
        message: '订单不存在',
      );
      return;
    }
    if (!order.isPaid) {
      // notify 未到达时用 trade.query 兜底核对。
      final result = await _gateway.queryTrade(outTradeNo: orderId);
      if (result != null && _isSuccessTradeStatus(result.tradeStatus)) {
        order = await _settleOrder(order);
      }
    }
    final payload = <String, dynamic>{
      'status': order.status,
      'orderId': orderId,
    };
    if (order.membershipCredential != null) {
      payload['membershipCredential'] = order.membershipCredential;
    }
    await _writeJson(request.response, HttpStatus.ok, payload);
  }

  Future<void> _handleNotify(HttpRequest request) async {
    final fields = await _readFormBody(request);
    Future<void> respond(String outcome) async {
      request.response
        ..statusCode = HttpStatus.ok
        ..headers.contentType = ContentType.text
        ..write(outcome);
      await request.response.close();
    }

    final sign = fields['sign']?.trim() ?? '';
    final signType = fields['sign_type']?.trim() ?? 'RSA2';
    if (sign.isEmpty || signType != 'RSA2') {
      await respond('failure');
      return;
    }
    final verified = AlipaySigner.verifyContent(
      AlipaySigner.canonicalParams(fields),
      sign,
      _alipayPublicKey,
    );
    if (!verified) {
      await respond('failure');
      return;
    }
    if (fields['app_id'] != config.alipayAppId) {
      await respond('failure');
      return;
    }
    final orderId = fields['out_trade_no']?.trim() ?? '';
    final order = orderId.isEmpty ? null : _store.find(orderId);
    if (order == null) {
      await respond('failure');
      return;
    }
    if (fields['total_amount'] != order.totalAmount) {
      await respond('failure');
      return;
    }
    if (!_isSuccessTradeStatus(fields['trade_status']?.trim() ?? '')) {
      await respond('failure');
      return;
    }
    await _settleOrder(order);
    await respond('success');
  }

  /// 支付成功 → 签发会员凭证并落库。幂等：已支付的订单不重复签发。
  Future<MembershipOrder> _settleOrder(MembershipOrder order) async {
    final stored = _store.find(order.orderId);
    if (stored != null && stored.isPaid) {
      return stored;
    }
    final plan = config.plans[order.planId];
    if (plan == null) {
      throw StateError('订单引用的套餐不存在：${order.planId}');
    }
    final issuedAt = config.now();
    final credential = await MembershipCredentials.issue(
      userId: order.userId,
      orderId: order.orderId,
      issuedAt: issuedAt,
      expiresAt: issuedAt.add(Duration(days: plan.days)),
      signingKeyPair: await MembershipCredentials.keyPairFromSeed(
          config.membershipSigningSeed),
    );
    final paid = order.copyWith(
      status: 'paid',
      membershipCredential: credential.toJson(),
    );
    _store.upsert(paid);
    return paid;
  }

  String _newOrderId() {
    final suffix =
        _random.nextInt(0x100000000).toRadixString(16).padLeft(8, '0');
    return 'EW${DateTime.now().millisecondsSinceEpoch}$suffix';
  }

  /// 身份解析：JWT（HS256，同 auth 服务密钥）→ 网关头 / body userId（仅本地模式）。
  /// 返回 null 表示应拒绝（401）。
  String? _resolveUserId(
    HttpRequest request,
    Map<String, dynamic> body,
  ) {
    final authHeader = request.headers.value(HttpHeaders.authorizationHeader);
    final token = authHeader != null && authHeader.startsWith('Bearer ')
        ? authHeader.substring('Bearer '.length).trim()
        : null;
    if (config.jwtSecret.isNotEmpty) {
      if (token == null || token.isEmpty) return null;
      return EatWhatJwtVerifier.verify(token, secret: config.jwtSecret);
    }
    final headerUser = request.headers.value('x-eatwhat-user-id')?.trim();
    if (headerUser != null && headerUser.isNotEmpty) return headerUser;
    final bodyUser = body['userId']?.toString().trim();
    if (bodyUser != null && bodyUser.isNotEmpty) return bodyUser;
    return config.localUserId;
  }

  bool _isSuccessTradeStatus(String status) =>
      status == 'TRADE_SUCCESS' || status == 'TRADE_FINISHED';

  Future<Map<String, dynamic>> _readJsonBody(HttpRequest request) async {
    try {
      final raw = await utf8.decoder.bind(request).join();
      if (raw.trim().isEmpty) return const <String, dynamic>{};
      final decoded = jsonDecode(raw);
      return decoded is Map
          ? Map<String, dynamic>.from(decoded)
          : const <String, dynamic>{};
    } on Object {
      return const <String, dynamic>{};
    }
  }

  Future<Map<String, String>> _readFormBody(HttpRequest request) async {
    final raw = await utf8.decoder.bind(request).join();
    if (raw.isEmpty) return const {};
    final fields = <String, String>{};
    for (final pair in raw.split('&')) {
      if (pair.isEmpty) continue;
      final separator = pair.indexOf('=');
      if (separator <= 0) continue;
      fields[Uri.decodeQueryComponent(pair.substring(0, separator))] =
          Uri.decodeQueryComponent(pair.substring(separator + 1));
    }
    return fields;
  }

  void _addCorsHeaders(HttpResponse response) {
    final origin = config.allowedOrigin;
    if (origin == null || origin.isEmpty) return;
    response.headers
      ..set('Access-Control-Allow-Origin', origin)
      ..set('Access-Control-Allow-Methods', 'GET,POST,OPTIONS')
      ..set(
        'Access-Control-Allow-Headers',
        'Content-Type, Authorization, X-Request-Id',
      );
  }
}

Future<void> _writeError(
  HttpResponse response,
  int statusCode, {
  required String code,
  required String message,
}) {
  return _writeJson(
    response,
    statusCode,
    {
      'error': {'code': code, 'message': message},
    },
  );
}

Future<void> _writeJson(
  HttpResponse response,
  int statusCode,
  Map<String, dynamic> payload,
) async {
  response
    ..statusCode = statusCode
    ..headers.contentType = ContentType.json
    ..write(jsonEncode(payload));
  await response.close();
}
