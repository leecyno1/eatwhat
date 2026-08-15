import 'dart:convert';
import 'dart:io';

import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../scripts/meituan_delivery_adapter_server.dart';

void main() {
  test('美团消费者 OpenAPI 签名使用 URL、排序参数和 AppSecret', () {
    final endpoint = Uri.parse(
      'https://openapi.waimai.meituan.com/openapi/v1/poilist',
    );
    final actual = MeituanOpenApiSigner.sign(
      endpoint: endpoint,
      parameters: const {
        'timestamp': '1700000000',
        'app_id': 'app-1',
        'keyword': '麻婆豆腐',
      },
      secret: 'secret',
    );
    final expected = md5
        .convert(
          utf8.encode(
            '${endpoint.toString()}?'
            'app_id=app-1&keyword=麻婆豆腐&timestamp=1700000000secret',
          ),
        )
        .toString();

    expect(actual, expected);
  });

  test('真实门店匹配、订单预览和提交支付链接走美团消费者接口', () async {
    final upstream = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => upstream.close(force: true));
    upstream.listen((request) async {
      final raw = await utf8.decoder.bind(request).join();
      final businessParams = Uri.splitQueryString(raw);
      final authParams = Map<String, String>.from(request.uri.queryParameters);
      final sign = authParams.remove('sign');
      final signingParams = {...authParams, ...businessParams};
      final endpoint = Uri.parse(
        'http://127.0.0.1:${upstream.port}${request.uri.path}',
      );
      expect(
        sign,
        MeituanOpenApiSigner.sign(
          endpoint: endpoint,
          parameters: signingParams,
          secret: 'secret',
        ),
      );

      final response = switch (request.uri.path) {
        '/openapi/v1/poilist' => {
            'code': 0,
            'msg': '调用成功',
            'data': {
              'openPoiBaseInfoList': [
                {
                  'wm_poi_id': 171899,
                  'name': '锅气食堂',
                  'avg_delivery_time': 28,
                  'wm_scheme': 'meituanwaimai://menu?restaurant_id=171899',
                  'product_list': [
                    {'id': 403529562, 'name': '麻婆豆腐', 'price': 26},
                  ],
                },
              ],
            },
          },
        '/openapi/v1/order/preview' => {
            'code': 0,
            'msg': '调用成功',
            'data': {
              'code': 0,
              'token': 'preview-token',
              'wm_ordering_preview_order_vo': {
                'wm_poi_id': 171899,
                'poi_name': '锅气食堂',
                'shipping_fee': 5,
                'total': 31,
              },
            },
          },
        '/openapi/v1/order/submit' => {
            'code': 0,
            'msg': '调用成功',
            'data': {
              'code': 0,
              'order_id': 6015602307419773,
              'payUrl': 'https://pay.meituan.test/cashier?token=pay-token',
            },
          },
        _ => {'code': 1, 'msg': 'unknown'},
      };
      request.response
        ..headers.contentType = ContentType.json
        ..write(jsonEncode(response));
      await request.response.close();
    });

    final config = MeituanDeliveryAdapterConfig(
      bindAddress: InternetAddress.loopbackIPv4,
      port: 0,
      requiredToken: '',
      appId: 'app-1',
      appSecret: 'secret',
      accessToken: 'user-token',
      openId: '',
      orderEnabled: true,
      apiBaseUrl: Uri.parse('http://127.0.0.1:${upstream.port}'),
      upstreamTimeout: const Duration(seconds: 2),
      oauthRedirectUri: Uri(),
    );
    final adapter = MeituanDeliveryAdapter(
      config,
      client: MeituanOpenApiClient(
        config,
        now: () => DateTime.fromMillisecondsSinceEpoch(1700000000000),
      ),
    );
    addTearDown(adapter.close);

    final match = await adapter.match({
      'dishName': '麻婆豆腐',
      'geo': {'latitude': 39.9042, 'longitude': 116.4074},
      'limit': 10,
    });
    final first = (match['matches'] as List).first as Map<String, dynamic>;
    expect(first['merchantId'], '171899');
    expect(first['productId'], '403529562');
    expect(first['supportsPrefillCart'], isFalse);

    final order = {
      'merchantId': '171899',
      'items': [
        {'skuId': '441067569', 'count': 1},
      ],
      'recipient': {
        'name': '张三',
        'phone': '13800000000',
        'address': '测试地址',
        'currentLatitude': 39.9042,
        'currentLongitude': 116.4074,
        'addressLatitude': 39.9042,
        'addressLongitude': 116.4074,
      },
    };
    final preview = await adapter.previewOrder(order);
    expect(preview['previewToken'], 'preview-token');

    final submitted = await adapter.submitOrder({
      ...order,
      'previewToken': 'preview-token',
      'paymentSuccessUrl': 'https://eatwhat.test/meituan/success',
      'paymentFailureUrl': 'https://eatwhat.test/meituan/failure',
    });
    expect(submitted['status'], 'payment_required');
    expect(submitted['orderId'], '6015602307419773');
    expect(
      submitted['paymentUrl'],
      contains('pay_success_url=https%3A%2F%2Featwhat.test'),
    );
  });

  test('美团 errorInfo 会保留权限错误名称和 failCode', () {
    final error = MeituanOpenApiException.fromPayload(
      const {
        'code': 1,
        'msg': '调用失败',
        'errorInfo': {'name': '无权访问该接口', 'failCode': 1},
      },
      fallbackMessage: '美团接口调用失败',
    );

    expect(error.code, 'meituan_permission_denied');
    expect(error.failCode, 1);
    expect(error.name, '无权访问该接口');
    expect(error.message, contains('无权访问该接口'));
  });

  test('顶层 code=1 的无权访问会映射为权限未开通', () {
    final error = MeituanOpenApiException.fromPayload(
      const {
        'code': 1,
        'msg': '无权访问该接口',
      },
      fallbackMessage: '美团接口调用失败',
    );

    expect(error.code, 'meituan_permission_denied');
    expect(error.failCode, 1);
  });

  test('审核模式自动使用美团官方测试坐标', () async {
    Map<String, String>? requestParams;
    final upstream = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    addTearDown(() => upstream.close(force: true));
    upstream.listen((request) async {
      requestParams = Uri.splitQueryString(
        await utf8.decoder.bind(request).join(),
      );
      request.response
        ..headers.contentType = ContentType.json
        ..write(jsonEncode({'code': 0, 'data': {}}));
      await request.response.close();
    });
    final config = MeituanDeliveryAdapterConfig(
      bindAddress: InternetAddress.loopbackIPv4,
      port: 0,
      requiredToken: '',
      appId: 'app-1',
      appSecret: 'secret',
      accessToken: 'token',
      openId: '',
      orderEnabled: false,
      reviewMode: true,
      apiBaseUrl: Uri.parse('http://127.0.0.1:${upstream.port}'),
      upstreamTimeout: const Duration(seconds: 2),
      oauthRedirectUri: Uri(),
    );
    final adapter = MeituanDeliveryAdapter(config);
    addTearDown(adapter.close);

    await adapter.searchMerchants({
      'geo': {'latitude': 39.9042, 'longitude': 116.4074},
    });

    expect(requestParams?['longitude'], '95369826');
    expect(requestParams?['latitude'], '29735952');
  });
}
