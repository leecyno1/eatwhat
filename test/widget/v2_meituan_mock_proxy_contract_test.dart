import 'dart:io';

import 'package:eatwhat_app/v2/core/external/platform/execution_proxy_client.dart';
import 'package:eatwhat_app/v2/core/external/platform/meituan_delivery_order_client.dart';
import 'package:eatwhat_app/v2/core/external/platform/platform_types.dart';
import 'package:eatwhat_app/v2/core/services/v2_membership_service.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../scripts/mock_execution_proxy_server.dart';

/// End-to-end contract test between the delivery client and the mock
/// execution proxy. The proxy runs in-process on a random port and serves
/// the exact same responses as `dart run
/// scripts/mock_execution_proxy_server.dart` (the handler is shared), so any
/// drift between the client's parsing and the mock the local integration
/// flow relies on fails here instead of on the simulator.
void main() {
  late HttpServer server;
  late MeituanDeliveryOrderClient client;

  setUpAll(() async {
    server = await HttpServer.bind(InternetAddress.loopbackIPv4, 0);
    server.listen((request) {
      handleMockProxyRequest(request, port: server.port);
    });
    client = MeituanDeliveryOrderClient(
      client: ExecutionProxyClient(baseUrl: 'http://127.0.0.1:${server.port}'),
    );
  });

  tearDownAll(() async {
    await server.close();
  });

  test('代理配置状态与健康检查', () async {
    expect(client.isConfigured, isTrue);

    final health = await ExecutionProxyClient(
      baseUrl: 'http://127.0.0.1:${server.port}',
    ).getProviderHealth();
    expect(health['meituan'], isTrue);
  });

  test('OAuth 状态返回已连接的联调用户', () async {
    final status = await client.getOAuthStatus();
    expect(status.connected, isTrue);
    expect(status.requiresUserAuthorization, isFalse);
    expect(status.nickname, '美团联调用户');
  });

  test('门店搜索解析出联调门店与配送信息', () async {
    const location = GeoPoint(latitude: 39.9042, longitude: 116.4074);
    final result = await client.searchMerchantResults(
      keyword: '麻婆豆腐',
      location: location,
    );

    expect(result.hasNextPage, isFalse);
    expect(result.merchants, hasLength(2));

    final first = result.merchants.first;
    expect(first.merchantId, 'mock-merchant-001');
    expect(first.merchantName, '锅气食堂（美团联调店）');
    expect(first.rating, 4.8);
    expect(first.deliveryTimeMinutes, 28);
    expect(first.shippingFee, 4);
    expect(first.minimumPrice, 20);
  });

  test('菜品搜索解析出 SPU/SKU/规格与属性', () async {
    const location = GeoPoint(latitude: 39.9042, longitude: 116.4074);
    final result = await client.searchProducts(
      merchantId: 'mock-merchant-001',
      location: location,
    );

    expect(result.merchantName, '锅气食堂（美团联调店）');
    final mapo = result.products.firstWhere((p) => p.name == '麻婆豆腐');
    expect(mapo.skus, hasLength(1));
    expect(mapo.skus.first.skuId, 'sku-mapo-standard');
    expect(mapo.skus.first.price, 26);
    expect(mapo.skus.first.isAvailable, isTrue);
    expect(mapo.attributes, hasLength(1));
    expect(mapo.attributes.first.name, '辣度');
    expect(mapo.attributes.first.values.first.label, '微辣');
  });

  test('会员支付链路：创建订单、收银台地址、支付状态查询', () async {
    final membership = V2MembershipService(
      client: ExecutionProxyClient(
        baseUrl: 'http://127.0.0.1:${server.port}',
      ),
    );

    // 创建会员订单 → 模拟收银台地址
    final payload = await ExecutionProxyClient(
      baseUrl: 'http://127.0.0.1:${server.port}',
    ).postJson('/api/v1/payment/alipay/orders', body: {'plan': 'yearly'});
    expect(payload['status'], 'payment_required');
    expect(payload['orderId'], 'mock-pay-20260822');
    expect(
      payload['payUrl'].toString(),
      contains('/mock/alipay/cashier'),
    );

    // 支付状态查询（mock 恒为 paid）
    final status = await ExecutionProxyClient(
      baseUrl: 'http://127.0.0.1:${server.port}',
    ).getJson(
      '/api/v1/payment/alipay/status?orderId=mock-pay-20260822',
    );
    expect(status['status'], 'paid');

    expect(membership.isConfigured, isTrue);
  });

  test('订单预览与提交的全链路返回模拟收银台', () async {
    const request = MeituanDeliveryOrderRequest(
      merchantId: 'mock-merchant-001',
      items: [
        MeituanDeliveryOrderItem(
          skuId: 'sku-mapo-standard',
          count: 2,
          attributeIds: [91],
        ),
      ],
    );

    final preview = await client.previewOrder(request);
    expect(preview.previewToken, isNotEmpty);
    expect(preview.merchantName, '锅气食堂（美团联调店）');
    // 2 × 麻婆豆腐(26) + mock 包装/配送加价
    expect(preview.total, greaterThan(52));
    expect(preview.shippingFee, 4);
    expect(preview.boxFee, 1);

    final order = await client.submitOrder(
      request,
      previewToken: preview.previewToken,
    );
    expect(order.status, 'payment_required');
    expect(order.orderId, 'mock-order-20260812');
    expect(order.paymentUrl, contains('/mock/meituan/cashier'));
    expect(order.paymentUrl, contains('orderId=mock-order-20260812'));
    expect(order.requiresVerification, isFalse);
  });
}
