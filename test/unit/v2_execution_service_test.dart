import 'package:eatwhat_app/v2/core/data/models/recipe_model.dart';
import 'package:eatwhat_app/v2/core/external/platform/platform_exceptions.dart';
import 'package:eatwhat_app/v2/core/external/platform/platform_provider.dart';
import 'package:eatwhat_app/v2/core/external/platform/platform_types.dart';
import 'package:eatwhat_app/v2/core/services/v2_execution_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('执行服务能汇总平台能力快照', () async {
    final snapshot = await V2ExecutionService.instance.getProviderSnapshot();

    expect(snapshot.isNotEmpty, isTrue);
    expect(
      snapshot.any((state) => state.platform == 'meituan'),
      isTrue,
    );
  });

  test('未配置开放平台时，外卖匹配返回平台搜索兜底入口', () async {
    final result = await V2ExecutionService.instance.matchDelivery(
      intent: const ExecutionIntent(
        recipe: RecipeModel(
          id: 'r1',
          name: '番茄肥牛锅',
          description: '热一点，有锅气，适合夜里吃。',
        ),
        pairings: [],
        sourceTags: ['辣', '火锅'],
      ),
    );

    expect(result.status, ExecutionAvailabilityStatus.partial);
    expect(result.providerStates, isNotEmpty);
    expect(result.matches, isNotEmpty);
    expect(
      result.matches.map((match) => match.platform),
      containsAll(<String>['meituan', 'eleme']),
    );
    expect(result.matches.first.source, 'deep_link_fallback');
    expect(Uri.decodeFull(result.matches.first.url), contains('番茄肥牛锅'));
    expect(result.message, contains('搜索入口'));
  });

  test('未配置开放平台时，堂食匹配返回点评和地图搜索兜底入口', () async {
    final result = await V2ExecutionService.instance.matchDineIn(
      intent: _intent(),
    );

    expect(result.status, ExecutionAvailabilityStatus.partial);
    expect(result.providerStates, isNotEmpty);
    expect(result.matches, isNotEmpty);
    expect(
      result.matches.map((match) => match.platform),
      containsAll(<String>['dianping', 'apple_maps']),
    );
    expect(Uri.decodeFull(result.matches.first.url), contains('番茄肥牛锅'));
  });

  test('执行服务在代理返回真实外卖候选时返回 available', () async {
    final service = V2ExecutionService(
      providers: [
        _FakePlatformProvider(
          platform: 'meituan',
          displayName: '美团外卖',
          isConfigured: true,
          capabilities: const ProviderCapabilityMatrix(
            supportsDishSearch: true,
            supportsPrefillCart: true,
          ),
          deliveryResults: const [
            DeliveryMatchResult(
              platform: 'meituan',
              providerDisplayName: '美团外卖',
              merchantId: 'mt_1',
              merchantName: '番茄小馆',
              dishName: '番茄肥牛锅',
              url: 'https://example.com/order',
              productId: 'sku_1',
              price: Money(amount: 46),
              deliveryTimeMinutes: 25,
              supportsPrefillCart: true,
              source: 'proxy',
            ),
          ],
        ),
      ],
      locationResolver: () async =>
          const GeoPoint(latitude: 39.9042, longitude: 116.4074),
    );

    final result = await service.matchDelivery(intent: _intent());

    expect(result.status, ExecutionAvailabilityStatus.available);
    expect(result.matches, hasLength(1));
    expect(result.matches.first.productId, 'sku_1');
    expect(result.providerStates.single.platform, 'meituan');
  });

  test('执行服务在代理失败时返回搜索兜底入口并保留平台原因', () async {
    final service = V2ExecutionService(
      providers: [
        _FakePlatformProvider(
          platform: 'meituan',
          displayName: '美团外卖',
          isConfigured: true,
          capabilities: const ProviderCapabilityMatrix(
            supportsDishSearch: true,
            supportsPrefillCart: true,
          ),
          deliveryError: PlatformApiException(
            'meituan',
            '代理服务未返回可用商品检索结果',
          ),
        ),
      ],
      locationResolver: () async =>
          const GeoPoint(latitude: 39.9042, longitude: 116.4074),
    );

    final result = await service.matchDelivery(intent: _intent());

    expect(result.status, ExecutionAvailabilityStatus.partial);
    expect(
      result.providerStates.single.reason,
      contains('代理服务未返回可用商品检索结果'),
    );
    expect(result.matches, isNotEmpty);
    expect(result.matches.first.source, 'deep_link_fallback');
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

class _FakePlatformProvider implements PlatformProvider {
  _FakePlatformProvider({
    required this.platform,
    required this.displayName,
    required this.isConfigured,
    required this.capabilities,
    this.deliveryResults = const [],
    this.deliveryError,
  });

  @override
  final String platform;

  @override
  final String displayName;

  @override
  final bool isConfigured;

  @override
  final ProviderCapabilityMatrix capabilities;

  final List<DeliveryMatchResult> deliveryResults;
  final Exception? deliveryError;

  @override
  Future<List<DeliveryMatchResult>> searchDishCandidates({
    required ExecutionIntent intent,
    required GeoPoint location,
    int limit = 10,
  }) async {
    if (deliveryError != null) {
      throw deliveryError!;
    }
    return deliveryResults;
  }

  @override
  Future<List<DineInMatchResult>> searchMerchantCandidates({
    required ExecutionIntent intent,
    required GeoPoint location,
    int limit = 10,
  }) async {
    return const [];
  }
}
