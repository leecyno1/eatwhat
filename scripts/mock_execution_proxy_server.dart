import 'dart:convert';
import 'dart:io';

import 'package:eatwhat_app/v2/core/services/membership_credential.dart';

/// 会员凭证签发种子（仅本地联调；与客户端 .env 的 MEMBERSHIP_SIGNING_SEED
/// 保持一致，双端派生同一 Ed25519 密钥对）。
final String _signingSeed =
    Platform.environment['MEMBERSHIP_SIGNING_SEED'] ?? 'eatwhat-dev-seed';

/// 订单号 → 下单账号：签发会员凭证时绑定用。
final Map<String, String> _orderUsers = {};

Future<void> main(List<String> args) async {
  final port = args.isNotEmpty ? int.tryParse(args.first) ?? 8787 : 8787;
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, port);

  stdout
    ..writeln(
      'Mock execution proxy listening on http://${server.address.address}:$port',
    )
    ..writeln('GET  /health')
    ..writeln('GET  /api/v1/delivery/oauth/status')
    ..writeln('POST /api/v1/delivery/merchants/search')
    ..writeln('POST /api/v1/delivery/products/search')
    ..writeln('POST /api/v1/delivery/order-previews')
    ..writeln('POST /api/v1/delivery/orders')
    ..writeln('GET  /mock/meituan/cashier')
    ..writeln('POST /api/v1/payment/alipay/orders')
    ..writeln('GET  /api/v1/payment/alipay/status')
    ..writeln('GET  /mock/alipay/cashier');

  await for (final request in server) {
    await handleMockProxyRequest(
      request,
      port: port,
      log: (line) => stdout.writeln(line),
    );
  }
}

/// Serves one mock-proxy request. Shared by the CLI server above and the
/// widget-test harness, so tests exercise the exact same responses the
/// local integration flow sees.
Future<void> handleMockProxyRequest(
  HttpRequest request, {
  required int port,
  void Function(String line)? log,
}) async {
  _addCorsHeaders(request.response);
  log?.call('[${DateTime.now().toIso8601String()}] '
      '${request.method} ${request.uri.path}');
  if (request.method == 'OPTIONS') {
    request.response.statusCode = HttpStatus.noContent;
    await request.response.close();
    return;
  }
  if (request.method == 'GET' && request.uri.path == '/health') {
    await _writeJson(request.response, HttpStatus.ok, {
      'status': 'ok',
      'mode': 'mock',
      'providers': {'meituan': true},
    });
    return;
  }
  // The mock proxy answers as an already-connected ordering backend so
  // the client's OAuth status check succeeds during local integration.
  if (request.method == 'GET' &&
      request.uri.path == '/api/v1/delivery/oauth/status') {
    await _writeJson(request.response, HttpStatus.ok, {
      'connected': true,
      'requiresUserAuthorization': false,
      'nickname': '美团联调用户',
      'maskedPhone': '138****8000',
    });
    return;
  }
  if (request.method == 'GET' && request.uri.path == '/mock/meituan/cashier') {
    request.response
      ..statusCode = HttpStatus.ok
      ..headers.contentType = ContentType.html
      ..write('''<!doctype html><html lang="zh-CN"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>美团模拟收银台</title></head><body style="font-family:-apple-system;padding:32px;background:#fff8ee">
<h1>美团模拟收银台</h1><p>订单 ${request.uri.queryParameters['orderId'] ?? 'mock-order'} 已创建。</p>
<p>本页仅用于本地验收，不会产生真实扣款。</p></body></html>''');
    await request.response.close();
    return;
  }
  // Membership payment mock: create an Alipay order, then let the client
  // open a fake cashier page and poll the paid status.
  if (request.method == 'GET' &&
      request.uri.path == '/api/v1/payment/alipay/status') {
    final orderId =
        request.uri.queryParameters['orderId'] ?? 'mock-pay-order';
    final userId = _orderUsers[orderId] ?? 'local-user';
    final now = DateTime.now();
    final credential = await MembershipCredentials.issue(
      userId: userId,
      orderId: orderId,
      issuedAt: now,
      expiresAt: now.add(const Duration(days: 365)),
      signingKeyPair: await MembershipCredentials.keyPairFromSeed(_signingSeed),
    );
    await _writeJson(request.response, HttpStatus.ok, {
      'status': 'paid',
      'orderId': orderId,
      'membershipCredential': credential.toJson(),
    });
    return;
  }
  if (request.method == 'GET' && request.uri.path == '/mock/alipay/cashier') {
    request.response
      ..statusCode = HttpStatus.ok
      ..headers.contentType = ContentType.html
      ..write('''<!doctype html><html lang="zh-CN"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>支付宝模拟收银台</title></head><body style="font-family:-apple-system;padding:32px;background:#1677ff;color:#fff">
<h1>支付宝模拟收银台</h1><p>会员订单 ${request.uri.queryParameters['orderId'] ?? 'mock-pay-order'} 已创建。</p>
<p>本页仅用于本地验收，不会产生真实扣款。</p></body></html>''');
    await request.response.close();
    return;
  }
  if (request.method != 'POST') {
    await _writeError(
        request.response, HttpStatus.notFound, 'route_not_found', 'Mock 路由不存在');
    return;
  }

  final body = await _readJson(request);
  switch (request.uri.path) {
    case '/api/v1/delivery/merchants/search':
      await _writeJson(request.response, HttpStatus.ok, {
        'status': 'available',
        'merchants': [
          {
            'merchantId': 'mock-merchant-001',
            'merchantName': '锅气食堂（美团联调店）',
            'address': '深圳市南山区科技园联调路 1 号',
            'rating': 4.8,
            'deliveryTimeMinutes': 28,
            'shippingFee': 4,
            'minimumOrder': 20,
          },
          {
            'merchantId': 'mock-merchant-002',
            'merchantName': '家常小馆（美团联调店）',
            'address': '深圳市南山区科技园联调路 2 号',
            'rating': 4.6,
            'deliveryTimeMinutes': 35,
            'shippingFee': 3,
            'minimumOrder': 15,
          },
        ],
        'hasNextPage': false,
        'query': body['keyword'],
      });
      break;
    case '/api/v1/delivery/products/search':
      await _writeJson(request.response, HttpStatus.ok, {
        'status': 'available',
        'merchant': {
          'merchantId': body['merchantId'],
          'merchantName': '锅气食堂（美团联调店）',
        },
        'products': _mockProducts,
      });
      break;
    case '/api/v1/delivery/order-previews':
      final items = (body['items'] as List<dynamic>? ?? const [])
          .whereType<Map>()
          .toList();
      if (items.isEmpty) {
        await _writeError(request.response, HttpStatus.unprocessableEntity,
            'validation_error', 'items 不能为空');
        break;
      }
      final productTotal = items.fold<double>(0, (sum, item) {
        final sku = _skuById(item['skuId']?.toString() ?? '');
        final count = (item['count'] as num?)?.toInt() ?? 1;
        return sum + ((sku?['price'] as num?)?.toDouble() ?? 0) * count;
      });
      await _writeJson(request.response, HttpStatus.ok, {
        'status': 'available',
        'previewToken': 'mock-preview-${DateTime.now().millisecondsSinceEpoch}',
        'preview': {
          'merchantName': '锅气食堂（美团联调店）',
          'total': productTotal + 5,
          'shippingFee': 4,
          'boxFee': 1,
        },
      });
      break;
    case '/api/v1/payment/alipay/orders':
      final plan = body['plan']?.toString() ?? 'yearly';
      const orderId = 'mock-pay-20260822';
      final userId = body['userId']?.toString().trim() ?? '';
      if (userId.isNotEmpty) _orderUsers[orderId] = userId;
      await _writeJson(request.response, HttpStatus.ok, {
        'status': 'payment_required',
        'orderId': orderId,
        'plan': plan,
        'payUrl': 'http://127.0.0.1:$port/mock/alipay/cashier?orderId=$orderId',
      });
      break;
    case '/api/v1/delivery/orders':
      if (body['previewToken']?.toString().trim().isEmpty ?? true) {
        await _writeError(request.response, HttpStatus.unprocessableEntity,
            'validation_error', 'previewToken 不能为空');
        break;
      }
      const orderId = 'mock-order-20260812';
      await _writeJson(request.response, HttpStatus.ok, {
        'status': 'payment_required',
        'orderId': orderId,
        'paymentUrl':
            'http://127.0.0.1:$port/mock/meituan/cashier?orderId=$orderId',
        'requiresVerification': false,
      });
      break;
    default:
      await _writeError(request.response, HttpStatus.notFound,
          'route_not_found', 'Mock 路由不存在');
  }
}

const _mockProducts = [
  {
    'productId': 'spu-main-0',
    'name': '麻婆豆腐',
    'description': '麻辣鲜香，适合配米饭。',
    'categoryId': 'main',
    'categoryName': '主菜',
    'monthlySales': 368,
    'attributes': [
      {
        'name': '辣度',
        'values': [
          {'id': 91, 'value': '微辣'},
          {'id': 92, 'value': '中辣'},
        ],
      },
    ],
    'skus': [
      {
        'skuId': 'sku-mapo-standard',
        'specification': '标准份',
        'price': 26,
        'boxPrice': 1,
        'minimumOrderCount': 1,
        'stock': 99,
        'status': 0,
      },
    ],
  },
  {
    'productId': 'spu-main-1',
    'name': '椒麻鸡丝凉面',
    'description': '椒麻清香，鸡丝与凉面拌匀。',
    'categoryId': 'main',
    'categoryName': '主菜',
    'monthlySales': 286,
    'attributes': [
      {
        'name': '辣度',
        'values': [
          {'id': 101, 'value': '微辣'},
          {'id': 102, 'value': '中辣'},
        ],
      },
    ],
    'skus': [
      {
        'skuId': 'sku-main-standard',
        'specification': '标准份',
        'price': 28,
        'boxPrice': 1,
        'minimumOrderCount': 1,
        'stock': 99,
        'status': 0,
      },
      {
        'skuId': 'sku-main-large',
        'specification': '大份',
        'price': 35,
        'boxPrice': 1,
        'minimumOrderCount': 1,
        'stock': 99,
        'status': 0,
      },
    ],
  },
  {
    'productId': 'spu-side-1',
    'name': '凉拌黄瓜',
    'description': '清爽解腻。',
    'categoryId': 'side',
    'categoryName': '小菜',
    'attributes': [],
    'skus': [
      {
        'skuId': 'sku-side-1',
        'specification': '一份',
        'price': 8,
        'minimumOrderCount': 1,
        'stock': 99,
        'status': 0,
      },
    ],
  },
  {
    'productId': 'spu-staple-1',
    'name': '米饭',
    'description': '东北大米。',
    'categoryId': 'staple',
    'categoryName': '主食',
    'attributes': [],
    'skus': [
      {
        'skuId': 'sku-rice-1',
        'specification': '一盒',
        'price': 3,
        'minimumOrderCount': 1,
        'stock': 99,
        'status': 0,
      },
    ],
  },
  {
    'productId': 'spu-drink-1',
    'name': '冰镇乌龙茶',
    'description': '无糖清爽。',
    'categoryId': 'drink',
    'categoryName': '饮品',
    'attributes': [],
    'skus': [
      {
        'skuId': 'sku-drink-1',
        'specification': '500ml',
        'price': 6,
        'minimumOrderCount': 1,
        'stock': 99,
        'status': 0,
      },
    ],
  },
];

Map<String, dynamic>? _skuById(String skuId) {
  for (final product in _mockProducts) {
    for (final rawSku in product['skus'] as List) {
      final sku = Map<String, dynamic>.from(rawSku as Map);
      if (sku['skuId'] == skuId) return sku;
    }
  }
  return null;
}

Future<Map<String, dynamic>> _readJson(HttpRequest request) async {
  final raw = await utf8.decoder.bind(request).join();
  if (raw.trim().isEmpty) return {};
  final decoded = jsonDecode(raw);
  return decoded is Map ? Map<String, dynamic>.from(decoded) : {};
}

void _addCorsHeaders(HttpResponse response) {
  response.headers
    ..set('Access-Control-Allow-Origin', '*')
    ..set('Access-Control-Allow-Methods', 'GET,POST,OPTIONS')
    ..set('Access-Control-Allow-Headers', 'Content-Type, Authorization');
}

Future<void> _writeError(
  HttpResponse response,
  int statusCode,
  String code,
  String message,
) {
  return _writeJson(response, statusCode, {
    'error': {'code': code, 'message': message},
  });
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
