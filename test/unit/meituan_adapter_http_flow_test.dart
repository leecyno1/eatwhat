import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../scripts/meituan_delivery_adapter_server.dart';

void main() {
  test('适配器 HTTP 路由完成 OAuth、门店、菜品、预览与提交闭环', () async {
    final upstream = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => upstream.close(force: true));
    upstream.listen((request) async {
      final path = request.uri.path;
      if (path == '/oauth/access_token') {
        expect(request.method, 'GET');
        await _writeJson(request.response, {
          'access_token': 'token-1',
          'refresh_token': 'refresh-1',
          'expires_in': 7200,
        });
        return;
      }
      if (path == '/oauth/userinfo') {
        expect(request.method, 'POST');
        final body = await utf8.decoder.bind(request).join();
        final params = Uri.splitQueryString(body);
        expect(params['app_id'], 'app-id');
        expect(params['secret'], 'app-secret');
        expect(params['access_token'], 'token-1');
        await _writeJson(request.response, {
          'openid': 'openid-1',
          'nickname': '测试用户',
          'desensitization_phone': '138****0000',
        });
        return;
      }
      expect(request.uri.queryParameters['access_token'], 'token-1');
      expect(request.uri.queryParameters['sign'], isNotEmpty);
      switch (path) {
        case '/openapi/v1/poilist':
          await _writeJson(request.response, {
            'data': {
              'code': 0,
              'openPoiBaseInfoList': [
                {
                  'wm_poi_id': '171899',
                  'name': '锅气食堂',
                  'status': 1,
                  'shipping_fee': 5,
                  'min_price': 20,
                  'wm_poi_score': 4.8,
                  'avg_delivery_time': 35,
                  'distance': 1200,
                  'address': '测试路 1 号',
                },
              ],
              'current_page_index': 1,
              'page_size': 10,
              'have_next_page': 0,
              'poi_total_num': 1,
            },
          });
        case '/openapi/v1/poi/food':
          await _writeJson(request.response, {
            'data': {
              'code': 0,
              'poi_info': {
                'wm_poi_id': '171899',
                'name': '锅气食堂',
                'status': 1,
                'shipping_fee': 5,
                'min_price': 20,
                'avg_delivery_time': 35,
                'support_pay': 1,
              },
              'food_spu_tags': [
                {
                  'tag': '1',
                  'name': '热菜',
                  'spus': [
                    {
                      'id': 'spu-1',
                      'name': '麻婆豆腐',
                      'description': '麻辣下饭',
                      'min_price': 26,
                      'month_saled': 100,
                      'status': 1,
                      'skus': [
                        {
                          'id': 'sku-1',
                          'spec': '标准份',
                          'price': 26,
                          'origin_price': 26,
                          'box_price': 0,
                          'min_order_count': 1,
                          'stock': -1,
                          'status': 0,
                        },
                      ],
                    },
                  ],
                },
              ],
            },
          });
        case '/openapi/v1/order/preview':
          await _writeJson(request.response, {
            'data': {
              'code': 0,
              'token': 'preview-token',
              'wm_ordering_preview_order_vo': {
                'wm_poi_id': '171899',
                'poi_name': '锅气食堂',
                'total': 31,
                'shipping_fee': 5,
                'box_total_price': 0,
              },
              'wm_ordering_preview_detail_vo_list': [],
              'discounts': [],
            },
          });
        case '/openapi/v1/order/submit':
          await _writeJson(request.response, {
            'data': {
              'code': 0,
              'order_id': 'order-1',
              'payUrl': 'https://pay.meituan.test/order-1',
            },
          });
        default:
          request.response.statusCode = HttpStatus.notFound;
          await request.response.close();
      }
    });

    final tempDir = await Directory.systemTemp.createTemp('eatwhat-oauth-');
    addTearDown(() => tempDir.delete(recursive: true));
    final config = MeituanDeliveryAdapterConfig.fromEnvironment(
      {
        'MEITUAN_OPEN_APP_ID': 'app-id',
        'MEITUAN_OPEN_APP_SECRET': 'app-secret',
        'MEITUAN_OPEN_ORDER_ENABLED': 'true',
        'MEITUAN_OPEN_API_BASE_URL': 'http://127.0.0.1:${upstream.port}',
        'MEITUAN_OAUTH_REDIRECT_URL': 'https://example.com/callback',
        'MEITUAN_OAUTH_STORE_PATH': '${tempDir.path}/oauth.json',
        'MEITUAN_OPEN_REVIEW_MODE': 'false',
      },
      args: ['0'],
    );
    final adapterServer = MeituanDeliveryAdapterServer(config);
    final httpServer = await adapterServer.start();
    addTearDown(() async {
      await httpServer.close(force: true);
      adapterServer.close();
    });
    final client = HttpClient();
    addTearDown(() => client.close(force: true));
    final base = Uri.parse('http://127.0.0.1:${httpServer.port}');
    const userHeaders = {'x-eatwhat-user-id': 'user-1'};

    final authorize = await _request(
      client,
      base.resolve('/oauth/authorize'),
      method: 'POST',
      headers: userHeaders,
      body: const {},
    );
    expect(authorize.status, HttpStatus.ok);
    final authorizationUrl = Uri.parse(authorize.json!['authorizationUrl']);
    final state = authorizationUrl.queryParameters['state'];
    expect(state, isNotEmpty);

    final callback = await _request(
      client,
      base.resolve('/oauth/callback').replace(
        queryParameters: {'code': 'code-1', 'state': state!},
      ),
      method: 'GET',
    );
    expect(callback.status, HttpStatus.ok);
    expect(callback.text, contains('绑定成功'));

    final status = await _request(
      client,
      base.resolve('/oauth/status'),
      method: 'GET',
      headers: userHeaders,
    );
    expect(status.status, HttpStatus.ok);
    expect(status.json!['connected'], isTrue);
    expect(status.json!['nickname'], '测试用户');

    final merchants = await _request(
      client,
      base.resolve('/merchants/search'),
      method: 'POST',
      headers: userHeaders,
      body: {
        'keyword': '麻婆豆腐',
        'geo': {'latitude': 39.9, 'longitude': 116.4},
        'limit': 10,
      },
    );
    expect(merchants.status, HttpStatus.ok);
    expect(merchants.json!['merchants'][0]['merchantName'], '锅气食堂');

    final products = await _request(
      client,
      base.resolve('/products/search'),
      method: 'POST',
      headers: userHeaders,
      body: {
        'merchantId': '171899',
        'geo': {'latitude': 39.9, 'longitude': 116.4},
      },
    );
    expect(products.status, HttpStatus.ok);
    expect(products.json!['products'][0]['name'], '麻婆豆腐');

    final orderBody = {
      'merchantId': '171899',
      'items': [
        {'skuId': 'sku-1', 'count': 1},
      ],
      'recipient': {
        'name': '张三',
        'phone': '13800000000',
        'address': '测试地址',
        'currentLatitude': 39.9,
        'currentLongitude': 116.4,
        'addressLatitude': 39.9,
        'addressLongitude': 116.4,
      },
    };
    final preview = await _request(
      client,
      base.resolve('/order-previews'),
      method: 'POST',
      headers: userHeaders,
      body: orderBody,
    );
    expect(preview.status, HttpStatus.ok);
    expect(preview.json!['previewToken'], 'preview-token');

    final submitted = await _request(
      client,
      base.resolve('/orders'),
      method: 'POST',
      headers: userHeaders,
      body: {
        ...orderBody,
        'previewToken': 'preview-token',
        'paymentSuccessUrl': 'https://eatwhat.test/pay/success',
        'paymentFailureUrl': 'https://eatwhat.test/pay/failure',
      },
    );
    expect(submitted.status, HttpStatus.ok);
    final paymentUrl = Uri.parse(submitted.json!['paymentUrl']);
    expect(paymentUrl.queryParameters['pay_success_url'],
        'https://eatwhat.test/pay/success');
    expect(paymentUrl.queryParameters['redr_url'],
        'https://eatwhat.test/pay/failure');
  });
}

Future<void> _writeJson(
  HttpResponse response,
  Map<String, dynamic> body,
) async {
  response.headers.contentType = ContentType.json;
  response.write(jsonEncode(body));
  await response.close();
}

Future<_Response> _request(
  HttpClient client,
  Uri uri, {
  required String method,
  Map<String, String>? headers,
  Map<String, dynamic>? body,
}) async {
  final request = await client.openUrl(method, uri);
  headers?.forEach(request.headers.set);
  if (body != null) {
    request.headers.contentType = ContentType.json;
    request.write(jsonEncode(body));
  }
  final response = await request.close();
  final text = await utf8.decoder.bind(response).join();
  final isJson =
      response.headers.contentType?.mimeType == ContentType.json.mimeType;
  return _Response(
    status: response.statusCode,
    text: text,
    json: !isJson || text.isEmpty
        ? null
        : jsonDecode(text) as Map<String, dynamic>,
  );
}

class _Response {
  const _Response({required this.status, required this.text, this.json});

  final int status;
  final String text;
  final Map<String, dynamic>? json;
}
