import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:eatwhat_app/core/config/env_config.dart';
import 'package:eatwhat_app/core/models/cart_item.dart';
import 'package:eatwhat_app/v2/core/external/platform/platform_provider.dart';
import 'package:eatwhat_app/v2/core/external/platform/platform_types.dart';
import 'package:eatwhat_app/v2/core/external/platform/signing/hmac_sha256_signer.dart';

/// 大众点评开放平台 Provider
///
/// 提供大众点评平台的搜索、预填购物车和深度链接功能
class DianpingProvider implements PlatformProvider {
  final Dio _dio;
  final String baseUrl;
  final String appKey;
  final String appSecret;
  final String accessToken;
  final HmacSha256Signer _signer;

  DianpingProvider._({
    required Dio dio,
    required this.baseUrl,
    required this.appKey,
    required this.appSecret,
    required this.accessToken,
    required HmacSha256Signer signer,
  })  : _dio = dio,
        _signer = signer;

  factory DianpingProvider() {
    final dio = Dio();
    return DianpingProvider._(
      dio: dio,
      baseUrl: EnvConfig.dianpingOpenBaseUrl,
      appKey: EnvConfig.dianpingAppKey,
      appSecret: EnvConfig.dianpingAppSecret,
      accessToken: EnvConfig.dianpingAccessToken,
      signer: HmacSha256Signer(),
    );
  }

  bool get _isConfigured =>
      baseUrl.isNotEmpty &&
      appKey.isNotEmpty &&
      appSecret.isNotEmpty &&
      accessToken.isNotEmpty;

  @override
  String get platform => 'dianping';

  @override
  String get displayName => '大众点评';

  @override
  bool get isConfigured => _isConfigured;

  @override
  ProviderCapabilityMatrix get capabilities => _isConfigured
      ? const ProviderCapabilityMatrix(
          supportsDishSearch: true,
          supportsMerchantSearch: true,
          supportsPrefillCart: true,
        )
      : const ProviderCapabilityMatrix();

  /// 搜索餐厅（到店）
  @override
  Future<List<DineInMatchResult>> searchMerchantCandidates({
    required ExecutionIntent intent,
    required GeoPoint location,
    int limit = 10,
  }) async {
    if (!_isConfigured) {
      debugPrint('[DianpingProvider] 大众点评未配置，返回空结果');
      return [];
    }

    try {
      final response = await _signedGet(
        '/shop/search',
        queryParameters: {
          'keyword': intent.recipe.name,
          'latitude': location.latitude.toString(),
          'longitude': location.longitude.toString(),
          'limit': limit.toString(),
        },
      );

      final data = response.data as Map<String, dynamic>?;
      final results = data?['results'] as List<dynamic>? ?? [];

      return results.whereType<Map<String, dynamic>>().map((item) {
        final priceAmount = (item['avgPrice'] as num?)?.toDouble();
        return DineInMatchResult(
          platform: platform,
          providerDisplayName: displayName,
          merchantId: item['shopId']?.toString() ?? '',
          merchantName: item['shopName']?.toString() ?? '未命名商家',
          matchedDishName: intent.recipe.name,
          url: item['url']?.toString() ?? '',
          rating: (item['rating'] as num?)?.toDouble(),
          pricePerPerson:
              priceAmount != null ? Money(amount: priceAmount) : null,
          distanceMeters: (item['distance'] as num?)?.toDouble(),
          supportsMerchantDetail: true,
          supportsReservation: item['supportsReservation'] == true,
          supportsNavigation: true,
          note: item['address']?.toString(),
        );
      }).toList();
    } catch (e) {
      debugPrint('[DianpingProvider] 搜索餐厅失败: $e');
      return [];
    }
  }

  /// 搜索菜品（外卖/团购）
  @override
  Future<List<DeliveryMatchResult>> searchDishCandidates({
    required ExecutionIntent intent,
    required GeoPoint location,
    int limit = 10,
  }) async {
    if (!_isConfigured) {
      debugPrint('[DianpingProvider] 大众点评未配置，返回空结果');
      return [];
    }

    try {
      final response = await _signedGet(
        '/product/search',
        queryParameters: {
          'keyword': intent.recipe.name,
          'latitude': location.latitude.toString(),
          'longitude': location.longitude.toString(),
          'limit': limit.toString(),
        },
      );

      final data = response.data as Map<String, dynamic>?;
      final results = data?['results'] as List<dynamic>? ?? [];

      return results.whereType<Map<String, dynamic>>().map((item) {
        final priceAmount = (item['price'] as num?)?.toDouble();
        return DeliveryMatchResult(
          platform: platform,
          providerDisplayName: displayName,
          merchantId: item['merchantId']?.toString() ?? '',
          merchantName: item['merchantName']?.toString() ?? '未命名商家',
          dishName: item['productName']?.toString() ?? intent.recipe.name,
          url: item['url']?.toString() ?? '',
          productId: item['productId']?.toString(),
          price: priceAmount != null ? Money(amount: priceAmount) : null,
          deliveryTimeMinutes: (item['deliveryTime'] as num?)?.toInt(),
          supportsPrefillCart: true,
          source: 'dianping_api',
          linkTarget: ExecutionLinkTarget.app,
        );
      }).toList();
    } catch (e) {
      debugPrint('[DianpingProvider] 搜索菜品失败: $e');
      return [];
    }
  }

  /// 搜索餐厅
  Future<List<DeliveryMatchResult>> searchRestaurants(String query) async {
    if (!_isConfigured) {
      debugPrint('[DianpingProvider] 大众点评未配置，返回空结果');
      return [];
    }

    try {
      final response = await _signedGet(
        '/shop/search',
        queryParameters: {'keyword': query},
      );

      final data = response.data as Map<String, dynamic>?;
      final results = data?['results'] as List<dynamic>? ?? [];

      return results.whereType<Map<String, dynamic>>().map((item) {
        return DeliveryMatchResult(
          platform: platform,
          providerDisplayName: displayName,
          merchantId: item['shopId']?.toString() ?? '',
          merchantName: item['shopName']?.toString() ?? '未命名商家',
          dishName: query,
          url: item['url']?.toString() ?? '',
          deliveryTimeMinutes: (item['deliveryTime'] as num?)?.toInt(),
          supportsPrefillCart: true,
          source: 'dianping_api',
          linkTarget: ExecutionLinkTarget.app,
        );
      }).toList();
    } catch (e) {
      debugPrint('[DianpingProvider] 搜索餐厅失败: $e');
      return [];
    }
  }

  /// 搜索菜品
  Future<List<DeliveryMatchResult>> searchDishes(String query) async {
    if (!_isConfigured) {
      debugPrint('[DianpingProvider] 大众点评未配置，返回空结果');
      return [];
    }

    try {
      final response = await _signedGet(
        '/product/search',
        queryParameters: {'keyword': query},
      );

      final data = response.data as Map<String, dynamic>?;
      final results = data?['results'] as List<dynamic>? ?? [];

      return results.whereType<Map<String, dynamic>>().map((item) {
        final priceAmount = (item['price'] as num?)?.toDouble();
        return DeliveryMatchResult(
          platform: platform,
          providerDisplayName: displayName,
          merchantId: item['merchantId']?.toString() ?? '',
          merchantName: item['merchantName']?.toString() ?? '未命名商家',
          dishName: item['productName']?.toString() ?? query,
          url: item['url']?.toString() ?? '',
          productId: item['productId']?.toString(),
          price: priceAmount != null ? Money(amount: priceAmount) : null,
          supportsPrefillCart: true,
          source: 'dianping_api',
          linkTarget: ExecutionLinkTarget.app,
        );
      }).toList();
    } catch (e) {
      debugPrint('[DianpingProvider] 搜索菜品失败: $e');
      return [];
    }
  }

  /// 预填购物车
  ///
  /// 将商品信息预填到大众点评App购物车
  Future<String> prefillCart(List<CartItem> items) async {
    if (items.isEmpty) {
      throw ArgumentError('商品列表不能为空');
    }

    if (!_isConfigured) {
      debugPrint('[DianpingProvider] 大众点评未配置，使用H5降级链接');
      return _generateH5Link(items);
    }

    try {
      // 通过API预填购物车
      final response = await _signedPost(
        '/cart/prefill',
        data: {
          'items': items.map((item) => {
                'foodId': item.foodId,
                'name': item.name,
                'price': item.price.toString(),
                'quantity': item.quantity.toString(),
                'specs': item.specs,
              }).toList(),
          'source': 'eatwhat_app',
        },
      );

      final data = response.data as Map<String, dynamic>?;
      final prefillUrl = data?['prefillUrl']?.toString();
      if (prefillUrl != null && prefillUrl.isNotEmpty) {
        return prefillUrl;
      }

      return _generateAppLink(items);
    } catch (e) {
      debugPrint('[DianpingProvider] 预填购物车失败: $e');
      return _generateAppLink(items);
    }
  }

  /// 生成大众点评深度链接
  String generateDeepLink(List<CartItem> items) {
    if (items.isEmpty) {
      throw ArgumentError('商品列表不能为空');
    }

    return _generateAppLink(items);
  }

  /// 生成App深度链接
  String _generateAppLink(List<CartItem> items) {
    if (items.isEmpty) {
      return 'dianping://';
    }

    final keyword = _buildKeyword(items);
    final encodedKeyword = Uri.encodeComponent(keyword);

    // 大众点评 URL Scheme
    var link = 'dianping://search?keyword=$encodedKeyword';

    // 单个商品添加商品信息
    if (items.length == 1) {
      final item = items.first;
      if (item.foodId.isNotEmpty) {
        link = '$link&shopid=${item.foodId}';
      }
    }

    return link;
  }

  /// 生成H5降级链接
  String _generateH5Link(List<CartItem> items) {
    final keyword = _buildKeyword(items);
    final encodedKeyword = Uri.encodeComponent(keyword);
    return 'https://m.dianping.com/search?keyword=$encodedKeyword';
  }

  /// 构建搜索关键词
  String _buildKeyword(List<CartItem> items) {
    if (items.isEmpty) return '';
    if (items.length == 1) return items.first.name;
    return '${items.first.name}等${items.length}件';
  }

  /// 签名GET请求
  Future<Response<dynamic>> _signedGet(
    String path, {
    Map<String, String> queryParameters = const {},
  }) async {
    final ts = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final params = <String, String>{
      ...queryParameters,
      'appKey': appKey,
      'timestamp': ts.toString(),
    };
    final signature = _signer.sign(
      method: 'GET',
      path: path,
      params: params,
      secret: appSecret,
      timestampSeconds: ts,
    );

    final signedParams = <String, String>{
      ...params,
      'sign': signature,
    };

    return _dio.get(
      '$baseUrl$path',
      queryParameters: signedParams,
      options: Options(
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Accept': 'application/json',
        },
      ),
    );
  }

  /// 签名POST请求
  Future<Response<dynamic>> _signedPost(
    String path, {
    Map<String, dynamic> data = const {},
  }) async {
    final ts = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final params = <String, String>{
      'appKey': appKey,
      'timestamp': ts.toString(),
    };
    final signature = _signer.sign(
      method: 'POST',
      path: path,
      params: params,
      secret: appSecret,
      timestampSeconds: ts,
    );

    final signedParams = <String, String>{
      ...params,
      'sign': signature,
    };

    return _dio.post(
      '$baseUrl$path',
      queryParameters: signedParams,
      data: data,
      options: Options(
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      ),
    );
  }
}
