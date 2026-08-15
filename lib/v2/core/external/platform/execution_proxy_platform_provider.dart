import 'package:eatwhat_app/v2/core/external/platform/execution_proxy_client.dart';
import 'package:eatwhat_app/v2/core/external/platform/platform_exceptions.dart';
import 'package:eatwhat_app/v2/core/external/platform/platform_provider.dart';
import 'package:eatwhat_app/v2/core/external/platform/platform_types.dart';

class ExecutionProxyPlatformProvider implements PlatformProvider {
  ExecutionProxyPlatformProvider({
    required this.platform,
    required this.displayName,
    required this.deliveryMatchPath,
    required this.capabilities,
    this.dineInMatchPath = '',
    ExecutionProxyClient? client,
  }) : _client = client ?? ExecutionProxyClient();

  final ExecutionProxyClient _client;

  @override
  final String platform;

  @override
  final String displayName;

  final String deliveryMatchPath;
  final String dineInMatchPath;

  @override
  final ProviderCapabilityMatrix capabilities;

  @override
  bool get isConfigured => _client.isConfigured;

  @override
  Future<List<DeliveryMatchResult>> searchDishCandidates({
    required ExecutionIntent intent,
    required GeoPoint location,
    int limit = 10,
  }) async {
    if (!isConfigured || deliveryMatchPath.isEmpty) {
      throw PlatformApiNotConfiguredException(
        platform,
        message: '$displayName 代理未配置',
      );
    }

    final payload = await _client.postJson(
      deliveryMatchPath,
      body: _requestBody(intent, location, limit),
    );
    final matches = _maps(payload['matches']).map(_parseDeliveryMatch).toList();
    _throwWhenUnavailable(payload, matches.isEmpty);
    return matches;
  }

  @override
  Future<List<DineInMatchResult>> searchMerchantCandidates({
    required ExecutionIntent intent,
    required GeoPoint location,
    int limit = 10,
  }) async {
    if (!isConfigured || dineInMatchPath.isEmpty) {
      throw PlatformApiNotConfiguredException(
        platform,
        message: '$displayName 到店代理未配置',
      );
    }

    final payload = await _client.postJson(
      dineInMatchPath,
      body: _requestBody(intent, location, limit),
    );
    final matches = _maps(payload['matches']).map(_parseDineInMatch).toList();
    _throwWhenUnavailable(payload, matches.isEmpty);
    return matches;
  }

  Map<String, dynamic> _requestBody(
    ExecutionIntent intent,
    GeoPoint location,
    int limit,
  ) {
    return {
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
    };
  }

  DeliveryMatchResult _parseDeliveryMatch(Map<String, dynamic> json) {
    final appUrl = _firstString(json, const ['appUrl', 'app_url']);
    final webUrl = _firstString(
      json,
      const ['webUrl', 'web_url', 'fallbackUrl', 'fallback_url'],
    );
    final primaryUrl = _firstString(
      json,
      const ['checkoutUrl', 'checkout_url', 'jumpUrl', 'jump_url', 'url'],
    );
    final url = appUrl.isNotEmpty
        ? appUrl
        : primaryUrl.isNotEmpty
            ? primaryUrl
            : webUrl;
    final priceAmount = _number(json, const ['price', 'amount']);
    final rawTarget = _firstString(
      json,
      const ['linkTarget', 'link_target'],
    ).toLowerCase();
    final linkTarget = appUrl.isNotEmpty || rawTarget == 'app'
        ? ExecutionLinkTarget.app
        : rawTarget == 'none'
            ? ExecutionLinkTarget.none
            : ExecutionLinkTarget.web;

    return DeliveryMatchResult(
      platform: platform,
      providerDisplayName:
          _firstString(json, const ['providerDisplayName', 'displayName'])
                  .trim()
                  .isNotEmpty
              ? _firstString(
                  json,
                  const ['providerDisplayName', 'displayName'],
                )
              : displayName,
      merchantId: _firstString(json, const ['merchantId', 'shopId']),
      merchantName:
          _firstString(json, const ['merchantName', 'shopName']).trim().isEmpty
              ? '未命名商家'
              : _firstString(json, const ['merchantName', 'shopName']),
      dishName: _firstString(json, const ['dishName', 'productName', 'name'])
              .trim()
              .isEmpty
          ? '未命名菜品'
          : _firstString(
              json,
              const ['dishName', 'productName', 'name'],
            ),
      url: url,
      fallbackUrl: webUrl.isNotEmpty && webUrl != url ? webUrl : null,
      productId: _nullableString(json, const ['productId', 'skuId']),
      price: priceAmount == null ? null : Money(amount: priceAmount),
      deliveryTimeMinutes: _integer(
        json,
        const ['deliveryTimeMinutes', 'deliveryTime'],
      ),
      supportsPrefillCart: json['supportsPrefillCart'] == true ||
          json['supportsCheckout'] == true ||
          json['canOrder'] == true,
      note: _nullableString(json, const ['note', 'description']),
      source: _firstString(json, const ['source']).trim().isEmpty
          ? 'proxy'
          : _firstString(json, const ['source']),
      capabilityReason: _nullableString(
        json,
        const ['capabilityReason', 'capability_reason'],
      ),
      linkTarget: linkTarget,
    );
  }

  DineInMatchResult _parseDineInMatch(Map<String, dynamic> json) {
    final priceAmount = _number(
      json,
      const ['pricePerPerson', 'avgPrice'],
    );
    return DineInMatchResult(
      platform: platform,
      providerDisplayName:
          _firstString(json, const ['providerDisplayName', 'displayName'])
                  .trim()
                  .isNotEmpty
              ? _firstString(
                  json,
                  const ['providerDisplayName', 'displayName'],
                )
              : displayName,
      merchantId: _firstString(json, const ['merchantId', 'shopId']),
      merchantName:
          _firstString(json, const ['merchantName', 'shopName']).trim().isEmpty
              ? '未命名商家'
              : _firstString(json, const ['merchantName', 'shopName']),
      matchedDishName:
          _firstString(json, const ['matchedDishName', 'dishName']),
      url: _firstString(json, const ['jumpUrl', 'url', 'webUrl']),
      rating: _number(json, const ['rating']),
      pricePerPerson: priceAmount == null ? null : Money(amount: priceAmount),
      distanceMeters: _number(json, const ['distanceMeters', 'distance']),
      supportsMerchantDetail: json['supportsMerchantDetail'] == true,
      supportsReservation: json['supportsReservation'] == true,
      supportsNavigation: json['supportsNavigation'] == true,
      note: _nullableString(json, const ['note', 'address']),
    );
  }

  void _throwWhenUnavailable(
    Map<String, dynamic> payload,
    bool matchesEmpty,
  ) {
    final status = payload['status']?.toString() ?? 'unavailable';
    if (!matchesEmpty || status == 'available') return;
    throw PlatformApiException(
      platform,
      payload['reason']?.toString() ??
          payload['message']?.toString() ??
          '$displayName 未返回可用候选',
    );
  }

  Iterable<Map<String, dynamic>> _maps(dynamic value) {
    return (value as List<dynamic>? ?? const [])
        .whereType<Map<String, dynamic>>();
  }

  String _firstString(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key]?.toString() ?? '';
      if (value.trim().isNotEmpty) return value;
    }
    return '';
  }

  String? _nullableString(Map<String, dynamic> json, List<String> keys) {
    final value = _firstString(json, keys).trim();
    return value.isEmpty ? null : value;
  }

  double? _number(Map<String, dynamic> json, List<String> keys) {
    for (final key in keys) {
      final value = json[key];
      if (value is num) return value.toDouble();
      final parsed = double.tryParse(value?.toString() ?? '');
      if (parsed != null) return parsed;
    }
    return null;
  }

  int? _integer(Map<String, dynamic> json, List<String> keys) {
    final value = _number(json, keys);
    return value?.round();
  }
}
