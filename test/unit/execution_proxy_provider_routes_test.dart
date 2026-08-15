import 'package:eatwhat_app/v2/core/data/models/recipe_model.dart';
import 'package:eatwhat_app/v2/core/external/platform/execution_proxy_client.dart';
import 'package:eatwhat_app/v2/core/external/platform/platform_provider.dart';
import 'package:eatwhat_app/v2/core/external/platform/platform_types.dart';
import 'package:eatwhat_app/v2/core/external/platform/providers/dianping_provider.dart';
import 'package:eatwhat_app/v2/core/external/platform/providers/eleme_provider.dart';
import 'package:eatwhat_app/v2/core/external/platform/providers/jd_delivery_provider.dart';
import 'package:eatwhat_app/v2/core/external/platform/providers/meituan_provider.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('四个平台分别调用自己的外卖代理路径', () async {
    final cases = <({
      String platform,
      String path,
      PlatformProvider Function(ExecutionProxyClient client) build,
    })>[
      (
        platform: 'meituan',
        path: '/v2/execution/meituan/delivery-match',
        build: (client) => MeituanProvider(client: client),
      ),
      (
        platform: 'eleme',
        path: '/v2/execution/eleme/delivery-match',
        build: (client) => ElemeProvider(client: client),
      ),
      (
        platform: 'jd_delivery',
        path: '/v2/execution/jd-delivery/delivery-match',
        build: (client) => JdDeliveryProvider(client: client),
      ),
      (
        platform: 'dianping',
        path: '/v2/execution/dianping/delivery-match',
        build: (client) => DianpingProvider(client: client),
      ),
    ];

    for (final item in cases) {
      final client = _RecordingExecutionProxyClient();
      final provider = item.build(client);

      final matches = await provider.searchDishCandidates(
        intent: _intent,
        location: _location,
      );

      expect(client.lastPath, item.path, reason: item.platform);
      expect(client.lastBody?['dishName'], '麻婆豆腐');
      expect(matches.single.platform, item.platform);
    }
  });

  test('大众点评到店使用独立代理路径', () async {
    final client = _RecordingExecutionProxyClient(dineIn: true);
    final provider = DianpingProvider(client: client);

    final matches = await provider.searchMerchantCandidates(
      intent: _intent,
      location: _location,
    );

    expect(client.lastPath, '/v2/execution/dianping/dine-in-match');
    expect(matches.single.platform, 'dianping');
  });
}

const _location = GeoPoint(latitude: 39.9042, longitude: 116.4074);

const _intent = ExecutionIntent(
  recipe: RecipeModel(
    id: 'r1',
    name: '麻婆豆腐',
    description: '麻辣下饭',
  ),
  pairings: [],
  sourceTags: ['麻辣', '下饭'],
);

class _RecordingExecutionProxyClient extends ExecutionProxyClient {
  _RecordingExecutionProxyClient({this.dineIn = false})
      : super(baseUrl: 'http://127.0.0.1:8787');

  final bool dineIn;
  String? lastPath;
  Map<String, dynamic>? lastBody;

  @override
  Future<Map<String, dynamic>> postJson(
    String path, {
    Map<String, dynamic> body = const {},
  }) async {
    lastPath = path;
    lastBody = body;
    if (dineIn) {
      return {
        'status': 'available',
        'matches': [
          {
            'merchantId': 'shop_1',
            'merchantName': '锅气食堂',
            'matchedDishName': '麻婆豆腐',
            'jumpUrl': 'https://example.com/shop',
          },
        ],
      };
    }
    return {
      'status': 'available',
      'matches': [
        {
          'merchantId': 'shop_1',
          'merchantName': '锅气食堂',
          'dishName': '麻婆豆腐',
          'webUrl': 'https://example.com/order',
        },
      ],
    };
  }
}
