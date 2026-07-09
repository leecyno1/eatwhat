import 'package:eatwhat_app/v2/core/external/platform/platform_types.dart';

class V2ExecutionFallbackLinkService {
  const V2ExecutionFallbackLinkService();

  List<DeliveryMatchResult> buildDeliveryFallbacks({
    required ExecutionIntent intent,
  }) {
    final keyword = _keywordFor(intent);
    final encoded = Uri.encodeComponent(keyword);

    return [
      DeliveryMatchResult(
        platform: 'meituan',
        providerDisplayName: '美团外卖',
        merchantId: 'fallback_meituan',
        merchantName: '美团外卖搜索',
        dishName: keyword,
        url: 'https://i.meituan.com/search?keyword=$encoded',
        note: '未接入实时商品检索时，先打开美团搜索同款或相近菜品。',
        source: 'deep_link_fallback',
        capabilityReason: 'H5 搜索兜底',
      ),
      DeliveryMatchResult(
        platform: 'eleme',
        providerDisplayName: '饿了么',
        merchantId: 'fallback_eleme',
        merchantName: '饿了么搜索',
        dishName: keyword,
        url: 'https://h5.ele.me/search?keyword=$encoded',
        note: '未接入实时商品检索时，先打开饿了么搜索同款或相近菜品。',
        source: 'deep_link_fallback',
        capabilityReason: 'H5 搜索兜底',
      ),
    ];
  }

  List<DineInMatchResult> buildDineInFallbacks({
    required ExecutionIntent intent,
    required GeoPoint location,
  }) {
    final keyword = _keywordFor(intent);
    final encoded = Uri.encodeComponent(keyword);

    return [
      DineInMatchResult(
        platform: 'dianping',
        providerDisplayName: '大众点评',
        merchantId: 'fallback_dianping',
        merchantName: '大众点评搜索',
        matchedDishName: keyword,
        url: 'https://m.dianping.com/search?keyword=$encoded',
        supportsMerchantDetail: true,
        note: '未接入实时店铺检索时，先打开点评搜索附近同款。',
      ),
      DineInMatchResult(
        platform: 'apple_maps',
        providerDisplayName: 'Apple 地图',
        merchantId: 'fallback_apple_maps',
        merchantName: '地图附近搜索',
        matchedDishName: keyword,
        url: Uri(
          scheme: 'https',
          host: 'maps.apple.com',
          queryParameters: {
            'q': keyword,
            'll': '${location.latitude},${location.longitude}',
          },
        ).toString(),
        supportsNavigation: true,
        note: '用当前位置在地图里搜索附近能吃到这道菜的店。',
      ),
    ];
  }

  String _keywordFor(ExecutionIntent intent) {
    final name = intent.recipe.name.trim();
    if (name.isNotEmpty) return name;
    final tag = intent.sourceTags.firstWhere(
      (item) => item.trim().isNotEmpty,
      orElse: () => '美食',
    );
    return tag.trim();
  }
}
