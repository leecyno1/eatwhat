import 'package:flutter/foundation.dart';
import 'package:eatwhat_app/core/config/env_config.dart';
import 'package:eatwhat_app/core/models/cart_item.dart';
import 'package:eatwhat_app/v2/core/external/platform/execution_proxy_client.dart';
import 'package:eatwhat_app/v2/core/external/platform/platform_exceptions.dart';
import 'package:eatwhat_app/v2/core/external/platform/platform_provider.dart';
import 'package:eatwhat_app/v2/core/external/platform/platform_types.dart';

/// 美团外卖 Provider
///
/// 提供美团外卖平台的搜索、预填购物车和深度链接功能
class MeituanProvider implements PlatformProvider {
  MeituanProvider({
    ExecutionProxyClient? client,
  }) : _client = client ?? ExecutionProxyClient();

  final ExecutionProxyClient _client;

  @override
  String get platform => 'meituan';

  @override
  String get displayName => '美团外卖';

  @override
  bool get isConfigured => _client.isConfigured;

  @override
  ProviderCapabilityMatrix get capabilities => isConfigured
      ? const ProviderCapabilityMatrix(
          supportsDishSearch: true,
          supportsPrefillCart: true,
        )
      : const ProviderCapabilityMatrix();

  /// 搜索餐厅
  @override
  Future<List<DineInMatchResult>> searchMerchantCandidates({
    required ExecutionIntent intent,
    required GeoPoint location,
    int limit = 10,
  }) async {
    return const [];
  }

  /// 搜索菜品
  @override
  Future<List<DeliveryMatchResult>> searchDishCandidates({
    required ExecutionIntent intent,
    required GeoPoint location,
    int limit = 10,
  }) async {
    if (!isConfigured) {
      throw PlatformApiNotConfiguredException(
        platform,
        message: '美团外卖代理未配置（缺少 EXECUTION_PROXY_BASE_URL）',
      );
    }

    final payload = await _client.postJson(
      EnvConfig.meituanDeliveryMatchPath,
      body: {
        'dishName': intent.recipe.name,
        'recipeId': intent.recipe.id,
        'pairings': intent.pairings
            .map(
              (pairing) => {
                'category': pairing.category,
                'title': pairing.title,
                'subtitle': pairing.subtitle,
              },
            )
            .toList(),
        'sourceTags': intent.sourceTags,
        'geo': {
          'latitude': location.latitude,
          'longitude': location.longitude,
        },
        'limit': limit,
      },
    );

    final status = payload['status']?.toString() ?? 'unavailable';
    final reason =
        payload['reason']?.toString() ?? payload['message']?.toString();
    final matches = (payload['matches'] as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>()
        .map(_parseMatch)
        .toList();

    if (matches.isEmpty && status != 'available') {
      throw PlatformApiException(
        platform,
        reason ?? '美团代理未返回可用的商品候选',
      );
    }

    return matches;
  }

  /// 预填购物车
  ///
  /// 将商品信息预填到美团外卖App购物车
  /// 返回预填后的深度链接
  Future<String> prefillCart(List<CartItem> items) async {
    if (items.isEmpty) {
      throw ArgumentError('商品列表不能为空');
    }

    if (!isConfigured) {
      debugPrint('[MeituanProvider] 美团代理未配置，使用H5降级链接');
      return _generateH5Link(items);
    }

    try {
      // 通过代理服务预填购物车
      final payload = await _client.postJson(
        '${EnvConfig.meituanDeliveryMatchPath}/prefill',
        body: {
          'items': items.map((item) => {
                'foodId': item.foodId,
                'name': item.name,
                'price': item.price,
                'quantity': item.quantity,
                'specs': item.specs,
              }).toList(),
          'source': 'eatwhat_app',
        },
      );

      // 返回预填链接或降级链接
      final prefillUrl = payload['prefillUrl']?.toString();
      if (prefillUrl != null && prefillUrl.isNotEmpty) {
        debugPrint('[MeituanProvider] 预填链接生成成功: $prefillUrl');
        return prefillUrl;
      }

      return _generateAppLink(items);
    } catch (e) {
      debugPrint('[MeituanProvider] 预填购物车失败: $e');
      return _generateAppLink(items);
    }
  }

  /// 生成美团深度链接
  ///
  /// 生成美团外卖App的深度链接，支持预填商品信息
  String generateDeepLink(List<CartItem> items) {
    if (items.isEmpty) {
      throw ArgumentError('商品列表不能为空');
    }

    return _generateAppLink(items);
  }

  /// 生成App深度链接
  String _generateAppLink(List<CartItem> items) {
    if (items.isEmpty) {
      return 'meituan://www.meituan.com';
    }

    // 构造成交关键词
    final keyword = _buildKeyword(items);
    final encodedKeyword = Uri.encodeComponent(keyword);

    // 美团App URL Scheme
    var link = 'meituan://www.meituan.com/search?keyword=$encodedKeyword';

    // 如果是单个商品，添加商品ID
    if (items.length == 1) {
      final item = items.first;
      if (item.foodId.isNotEmpty) {
        link = '$link&product_id=${item.foodId}';
      }
      // 添加价格信息
      link = '$link&price=${item.price.toStringAsFixed(2)}';
    }

    return link;
  }

  /// 生成H5降级链接
  String _generateH5Link(List<CartItem> items) {
    final keyword = _buildKeyword(items);
    final encodedKeyword = Uri.encodeComponent(keyword);
    return 'https://i.meituan.com/search?keyword=$encodedKeyword';
  }

  /// 构建搜索关键词
  String _buildKeyword(List<CartItem> items) {
    if (items.isEmpty) return '';
    if (items.length == 1) return items.first.name;
    return '${items.first.name}等${items.length}件';
  }

  DeliveryMatchResult _parseMatch(Map<String, dynamic> json) {
    final priceAmount = (json['price'] as num?)?.toDouble();
    final rawLinkTarget = json['linkTarget']?.toString().toLowerCase();
    final linkTarget = switch (rawLinkTarget) {
      'app' => ExecutionLinkTarget.app,
      'none' => ExecutionLinkTarget.none,
      _ => ExecutionLinkTarget.web,
    };

    return DeliveryMatchResult(
      platform: platform,
      providerDisplayName:
          json['providerDisplayName']?.toString() ?? displayName,
      merchantId: json['merchantId']?.toString() ?? '',
      merchantName: json['merchantName']?.toString() ?? '未命名商家',
      dishName: json['dishName']?.toString() ?? '未命名菜品',
      url: json['jumpUrl']?.toString() ?? json['url']?.toString() ?? '',
      productId: json['productId']?.toString(),
      price: priceAmount == null ? null : Money(amount: priceAmount),
      deliveryTimeMinutes: (json['deliveryTimeMinutes'] as num?)?.toInt(),
      supportsPrefillCart: json['supportsPrefillCart'] == true,
      note: json['note']?.toString(),
      source: json['source']?.toString() ?? 'proxy',
      capabilityReason: json['capabilityReason']?.toString(),
      linkTarget: linkTarget,
    );
  }
}
