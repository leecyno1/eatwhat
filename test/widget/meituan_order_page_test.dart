import 'package:eatwhat_app/v2/core/data/models/recipe_model.dart';
import 'package:eatwhat_app/v2/core/external/platform/meituan_delivery_order_client.dart';
import 'package:eatwhat_app/v2/core/external/platform/platform_types.dart';
import 'package:eatwhat_app/v2/features/execution/execution_home_page.dart';
import 'package:eatwhat_app/v2/features/execution/meituan_order_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('美团 OpenAPI 候选进入 EatWhat 选菜流程', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: DeliveryExecutionPage(
          intent: ExecutionIntent(
            recipe: RecipeModel(
              id: 'r1',
              name: '麻婆豆腐',
              description: '麻辣下饭',
            ),
            pairings: [],
            sourceTags: ['麻辣'],
          ),
          snapshot: DeliveryExecutionSnapshot(
            status: ExecutionAvailabilityStatus.available,
            providerStates: [],
            matches: [
              DeliveryMatchResult(
                platform: 'meituan',
                providerDisplayName: '美团外卖',
                merchantId: '171899',
                merchantName: '锅气食堂',
                dishName: '麻婆豆腐',
                url: '',
                source: 'meituan_open_api',
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('EatWhat 内选菜'), findsOneWidget);
    expect(find.text('选菜并下单'), findsOneWidget);
  });

  testWidgets('美团真实点餐页生成多商品菜单、预览并打开支付链接', (tester) async {
    Uri? launchedUri;
    final client = _FakeMeituanOrderClient();

    await tester.pumpWidget(
      MaterialApp(
        home: MeituanOrderPage(
          intent: const ExecutionIntent(
            recipe: RecipeModel(
              id: 'r1',
              name: '麻婆豆腐',
              description: '麻辣下饭',
            ),
            pairings: [
              PairingSelection(
                category: '小菜',
                title: '凉拌黄瓜',
                subtitle: '清爽解腻',
              ),
            ],
            sourceTags: ['麻辣'],
          ),
          match: const DeliveryMatchResult(
            platform: 'meituan',
            providerDisplayName: '美团外卖',
            merchantId: '171899',
            merchantName: '锅气食堂',
            dishName: '麻婆豆腐',
            url: '',
            source: 'meituan_open_api',
          ),
          client: client,
          locationResolver: () async =>
              const GeoPoint(latitude: 39.9042, longitude: 116.4074),
          paymentLauncher: (uri) async {
            launchedUri = uri;
            return true;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('麻婆豆腐'), findsOneWidget);
    expect(find.text('凉拌黄瓜'), findsOneWidget);
    expect(find.text('菜单已选 2 份'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('meituan-recipient-name')),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    expect(
      find.byKey(const ValueKey('meituan-recipient-name')),
      findsOneWidget,
    );

    await tester.enterText(
      find.byKey(const ValueKey('meituan-recipient-name')),
      '张三',
    );
    await tester.enterText(
      find.byKey(const ValueKey('meituan-recipient-phone')),
      '13800000000',
    );
    await tester.enterText(
      find.byKey(const ValueKey('meituan-recipient-address')),
      '测试地址 1 号',
    );
    await tester.drag(
      find.byKey(const ValueKey('meituan-order-flow')),
      const Offset(0, -700),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('meituan-preview-order')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('meituan-order-preview')), findsOneWidget);

    await tester.drag(
      find.byKey(const ValueKey('meituan-order-flow')),
      const Offset(0, -350),
    );
    await tester.pumpAndSettle();
    expect(find.text('提交订单并去美团支付'), findsOneWidget);
    await tester.tap(find.byKey(const ValueKey('meituan-submit-order')));
    await tester.pumpAndSettle();

    expect(launchedUri, Uri.parse('https://pay.meituan.test/order-1'));
    expect(
      client.previewedRequest?.items.map((item) => item.skuId),
      ['sku-1', 'sku-side-1'],
    );
    expect(client.submittedPreviewToken, 'preview-token');
  });

  testWidgets('修改购物车后必须重新预览订单', (tester) async {
    final client = _FakeMeituanOrderClient();
    await tester.pumpWidget(
      MaterialApp(
        home: MeituanOrderPage(
          intent: const ExecutionIntent(
            recipe: RecipeModel(
              id: 'r1',
              name: '麻婆豆腐',
              description: '麻辣下饭',
            ),
            pairings: [],
            sourceTags: ['麻辣'],
          ),
          match: const DeliveryMatchResult(
            platform: 'meituan',
            providerDisplayName: '美团外卖',
            merchantId: '171899',
            merchantName: '锅气食堂',
            dishName: '麻婆豆腐',
            url: '',
          ),
          client: client,
          locationResolver: () async =>
              const GeoPoint(latitude: 39.9042, longitude: 116.4074),
        ),
      ),
    );
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('meituan-recipient-name')),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.enterText(
      find.byKey(const ValueKey('meituan-recipient-name')),
      '张三',
    );
    await tester.enterText(
      find.byKey(const ValueKey('meituan-recipient-phone')),
      '13800000000',
    );
    await tester.enterText(
      find.byKey(const ValueKey('meituan-recipient-address')),
      '测试地址 1 号',
    );
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('meituan-preview-order')),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const ValueKey('meituan-preview-order')));
    await tester.pumpAndSettle();
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('meituan-submit-order')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.byKey(const ValueKey('meituan-submit-order')), findsOneWidget);

    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('meituan-plus-spu-1')),
      -400,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const ValueKey('meituan-plus-spu-1')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('meituan-order-preview')), findsNothing);
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('meituan-preview-order')),
      400,
      scrollable: find.byType(Scrollable).first,
    );
    expect(find.byKey(const ValueKey('meituan-preview-order')), findsOneWidget);
  });
}

class _FakeMeituanOrderClient extends MeituanDeliveryOrderClient {
  MeituanDeliveryOrderRequest? previewedRequest;
  String? submittedPreviewToken;

  @override
  Future<MeituanProductSearchResult> searchProducts({
    required String merchantId,
    required GeoPoint location,
    String keyword = '',
  }) async {
    return const MeituanProductSearchResult(
      merchantName: '锅气食堂',
      products: [
        MeituanDeliveryProduct(
          productId: 'spu-1',
          name: '麻婆豆腐',
          attributes: [],
          skus: [
            MeituanDeliverySku(
              skuId: 'sku-1',
              price: 26,
              specification: '标准份',
              stock: -1,
            ),
          ],
        ),
        MeituanDeliveryProduct(
          productId: 'spu-side-1',
          name: '凉拌黄瓜',
          categoryName: '小菜',
          attributes: [],
          skus: [
            MeituanDeliverySku(
              skuId: 'sku-side-1',
              price: 8,
              specification: '一份',
              stock: -1,
            ),
          ],
        ),
      ],
    );
  }

  @override
  Future<MeituanOrderPreview> previewOrder(
    MeituanDeliveryOrderRequest request,
  ) async {
    previewedRequest = request;
    return const MeituanOrderPreview(
      previewToken: 'preview-token',
      total: 31,
      shippingFee: 5,
      boxFee: 0,
      merchantName: '锅气食堂',
    );
  }

  @override
  Future<MeituanSubmittedOrder> submitOrder(
    MeituanDeliveryOrderRequest request, {
    required String previewToken,
    String? verifyCode,
    String? paymentSuccessUrl,
    String? paymentFailureUrl,
  }) async {
    submittedPreviewToken = previewToken;
    return const MeituanSubmittedOrder(
      status: 'payment_required',
      orderId: 'order-1',
      paymentUrl: 'https://pay.meituan.test/order-1',
      requiresVerification: false,
    );
  }
}
