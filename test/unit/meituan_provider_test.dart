import 'package:eatwhat_app/v2/core/data/models/recipe_model.dart';
import 'package:eatwhat_app/v2/core/external/platform/execution_proxy_client.dart';
import 'package:eatwhat_app/v2/core/external/platform/platform_exceptions.dart';
import 'package:eatwhat_app/v2/core/external/platform/platform_types.dart';
import 'package:eatwhat_app/v2/core/external/platform/providers/meituan_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('MeituanProvider 能解析代理返回的外卖候选', () async {
    final provider = MeituanProvider(
      client: _FakeExecutionProxyClient(
        response: {
          'status': 'available',
          'matches': [
            {
              'merchantId': 'm_1',
              'merchantName': '番茄食堂',
              'dishName': '番茄肥牛锅',
              'appUrl': 'meituan://order/sku_1',
              'webUrl': 'https://example.com/order',
              'productId': 'sku_1',
              'price': 48,
              'deliveryTimeMinutes': 24,
              'supportsPrefillCart': true,
              'note': '命中热锅招牌',
              'source': 'proxy',
              'linkTarget': 'web',
            },
          ],
        },
      ),
    );

    final results = await provider.searchDishCandidates(
      intent: _intent(),
      location: const GeoPoint(latitude: 39.9042, longitude: 116.4074),
    );

    expect(results, hasLength(1));
    expect(results.first.productId, 'sku_1');
    expect(results.first.supportsPrefillCart, isTrue);
    expect(results.first.source, 'proxy');
    expect(results.first.url, 'meituan://order/sku_1');
    expect(results.first.fallbackUrl, 'https://example.com/order');
  });

  test('MeituanProvider 在代理返回 unavailable 且无候选时抛出平台异常', () async {
    final provider = MeituanProvider(
      client: _FakeExecutionProxyClient(
        response: {
          'status': 'unavailable',
          'reason': '美团代理未返回可用商品检索结果',
          'matches': [],
        },
      ),
    );

    expect(
      () => provider.searchDishCandidates(
        intent: _intent(),
        location: const GeoPoint(latitude: 39.9042, longitude: 116.4074),
      ),
      throwsA(
        isA<PlatformApiException>().having(
          (error) => error.message,
          'message',
          contains('美团代理未返回可用商品检索结果'),
        ),
      ),
    );
  });
}

ExecutionIntent _intent() {
  return const ExecutionIntent(
    recipe: RecipeModel(
      id: 'r1',
      name: '番茄肥牛锅',
      description: '热一点，有锅气，适合夜里吃。',
    ),
    pairings: [],
    sourceTags: ['辣', '火锅'],
  );
}

class _FakeExecutionProxyClient extends ExecutionProxyClient {
  _FakeExecutionProxyClient({
    required this.response,
  }) : super(baseUrl: 'http://127.0.0.1:8787');

  final Map<String, dynamic> response;

  @override
  Future<Map<String, dynamic>> postJson(
    String path, {
    Map<String, dynamic> body = const {},
  }) async {
    return response;
  }
}
