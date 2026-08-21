import 'dart:convert';
import 'dart:io';

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
    ..writeln('GET  /mock/meituan/cashier');

  await for (final request in server) {
    _addCorsHeaders(request.response);
    stdout.writeln('[${DateTime.now().toIso8601String()}] '
        '${request.method} ${request.uri.path}');
    if (request.method == 'OPTIONS') {
      request.response.statusCode = HttpStatus.noContent;
      await request.response.close();
      continue;
    }
    if (request.method == 'GET' && request.uri.path == '/health') {
      await _writeJson(request.response, HttpStatus.ok, {
        'status': 'ok',
        'mode': 'mock',
        'providers': {'meituan': true},
      });
      continue;
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
      continue;
    }
    if (request.method == 'GET' &&
        request.uri.path == '/mock/meituan/cashier') {
      request.response
        ..statusCode = HttpStatus.ok
        ..headers.contentType = ContentType.html
        ..write(
            '''<!doctype html><html lang="zh-CN"><head><meta charset="utf-8">
<meta name="viewport" content="width=device-width,initial-scale=1">
<title>美团模拟收银台</title></head><body style="font-family:-apple-system;padding:32px;background:#fff8ee">
<h1>美团模拟收银台</h1><p>订单 ${request.uri.queryParameters['orderId'] ?? 'mock-order'} 已创建。</p>
<p>本页仅用于本地验收，不会产生真实扣款。</p></body></html>''');
      await request.response.close();
      continue;
    }
    if (request.method != 'POST') {
      await _writeError(request.response, HttpStatus.notFound,
          'route_not_found', 'Mock 路由不存在');
      continue;
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
          'previewToken':
              'mock-preview-${DateTime.now().millisecondsSinceEpoch}',
          'preview': {
            'merchantName': '锅气食堂（美团联调店）',
            'total': productTotal + 5,
            'shippingFee': 4,
            'boxFee': 1,
          },
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
