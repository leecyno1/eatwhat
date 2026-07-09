import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:eatwhat_app/v2/core/external/platform/signing/request_signer.dart';

/// 通用 MD5 签名器（占位实现）
///
/// 注意：不同平台对“待签名字符串”的拼接规则不同。
/// 这里提供一个最小可用的、可替换的默认实现，后续按官方文档调整。
class Md5Signer implements RequestSigner {
  @override
  String sign({
    required String method,
    required String path,
    required Map<String, String> params,
    required String secret,
    required int timestampSeconds,
  }) {
    final sortedKeys = params.keys.toList()..sort();
    final canonicalQuery =
        sortedKeys.map((k) => '$k=${params[k] ?? ''}').join('&');

    final canonical = [
      method.toUpperCase(),
      path,
      timestampSeconds.toString(),
      canonicalQuery,
      secret,
    ].join('\n');

    return md5.convert(utf8.encode(canonical)).toString();
  }
}
