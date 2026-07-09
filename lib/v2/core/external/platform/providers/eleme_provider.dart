import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:eatwhat_app/core/config/env_config.dart';
import 'package:eatwhat_app/core/models/cart_item.dart';
import 'package:eatwhat_app/v2/core/external/platform/platform_exceptions.dart';
import 'package:eatwhat_app/v2/core/external/platform/platform_provider.dart';
import 'package:eatwhat_app/v2/core/external/platform/platform_types.dart';
import 'package:eatwhat_app/v2/core/external/platform/signing/md5_signer.dart';

/// 饿了么开放平台 Provider
///
/// 提供饿了么外卖平台的搜索、预填购物车和深度链接功能
class ElemeProvider implements PlatformProvider {
  final Dio _dio;
  final String baseUrl;
  final String appKey;
  final String appSecret;
  final String accessToken;
  final Md5Signer _signer;

  ElemeProvider._({
    required Dio dio,
    required this.baseUrl,
    required this.appKey,
    required this.appSecret,
    required this.accessToken,
    required Md5Signer signer,
  })  : _dio = dio,
        _signer = signer;

  factory ElemeProvider() {
    final dio = Dio();
    return ElemeProvider._(
      dio: dio,
      baseUrl: EnvConfig.elemeOpenBaseUrl,
      appKey: EnvConfig.elemeAppKey,
      appSecret: EnvConfig.elemeAppSecret,
      accessToken: EnvConfig.elemeAccessToken,
      signer: Md5Signer(),
    );
  }

  bool get _isConfigured =>
      baseUrl.isNotEmpty &&
      appKey.isNotEmpty &&
      appSecret.isNotEmpty &&
      accessToken.isNotEmpty;

  @override
  String get platform => 'eleme';

  @override
  String get displayName => '饿了么';

  @override
  bool get isConfigured => _isConfigured;

  @override
  ProviderCapabilityMatrix get capabilities => _isConfigured
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
    if (!isConfigured) {
      throw PlatformApiNotConfiguredException(platform);
    }

    // 饿了么以外卖为主，到店功能有限
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
      throw PlatformApiNotConfiguredException(platform);
    }

    try {
      final response = await _signedGet(
        '/search/shopping',
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
        return DeliveryMatchResult(
          platform: platform,
          providerDisplayName: displayName,
          merchantId: item['merchantId']?.toString() ?? '',
          merchantName: item['merchantName']?.toString() ?? '未命名商家',
          dishName: item['dishName']?.toString() ??
              item['name']?.toString() ??
              '未命名菜品',
          url: item['url']?.toString() ?? '',
          productId: item['productId']?.toString(),
          price: item['price'] != null
              ? Money(amount: (item['price'] as num).toDouble())
              : null,
          deliveryTimeMinutes: (item['deliveryTime'] as num?)?.toInt(),
          supportsPrefillCart: true,
          source: 'eleme_api',
          linkTarget: ExecutionLinkTarget.app,
        );
      }).toList();
    } catch (e) {
      debugPrint('[ElemeProvider] 搜索菜品失败: $e');
      throw PlatformApiException(platform, '搜索菜品失败: $e');
    }
  }

  /// 搜索餐厅（外卖）
  Future<List<DeliveryMatchResult>> searchRestaurants(String query) async {
    if (!isConfigured) {
      debugPrint('[ElemeProvider] 饿了么未配置，返回空结果');
      return [];
    }

    try {
      final response = await _signedGet(
        '/search/shop',
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
          source: 'eleme_api',
          linkTarget: ExecutionLinkTarget.app,
        );
      }).toList();
    } catch (e) {
      debugPrint('[ElemeProvider] 搜索餐厅失败: $e');
      return [];
    }
  }

  /// 搜索菜品
  Future<List<DeliveryMatchResult>> searchDishes(String query) async {
    if (!isConfigured) {
      debugPrint('[ElemeProvider] 饿了么未配置，返回空结果');
      return [];
    }

    try {
      final response = await _signedGet(
        '/search/product',
        queryParameters: {'keyword': query},
      );

      final data = response.data as Map<String, dynamic>?;
      final results = data?['results'] as List<dynamic>? ?? [];

      return results.whereType<Map<String, dynamic>>().map((item) {
        return DeliveryMatchResult(
          platform: platform,
          providerDisplayName: displayName,
          merchantId: item['merchantId']?.toString() ?? '',
          merchantName: item['merchantName']?.toString() ?? '未命名商家',
          dishName: item['productName']?.toString() ?? query,
          url: item['url']?.toString() ?? '',
          productId: item['productId']?.toString(),
          price: item['price'] != null
              ? Money(amount: (item['price'] as num).toDouble())
              : null,
          supportsPrefillCart: true,
          source: 'eleme_api',
          linkTarget: ExecutionLinkTarget.app,
        );
      }).toList();
    } catch (e) {
      debugPrint('[ElemeProvider] 搜索菜品失败: $e');
      return [];
    }
  }

  /// 预填购物车
  ///
  /// 将商品信息预填到饿了么App购物车
  Future<String> prefillCart(List<CartItem> items) async {
    if (items.isEmpty) {
      throw ArgumentError('商品列表不能为空');
    }

    if (!isConfigured) {
      debugPrint('[ElemeProvider] 饿了么未配置，使用H5降级链接');
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
      debugPrint('[ElemeProvider] 预填购物车失败: $e');
      return _generateAppLink(items);
    }
  }

  /// 生成饿了么深度链接
  String generateDeepLink(List<CartItem> items) {
    if (items.isEmpty) {
      throw ArgumentError('商品列表不能为空');
    }

    return _generateAppLink(items);
  }

  /// 生成App深度链接
  String _generateAppLink(List<CartItem> items) {
    if (items.isEmpty) {
      return 'ele://';
    }

    final keyword = _buildKeyword(items);
    final encodedKeyword = Uri.encodeComponent(keyword);

    // 饿了么 URL Scheme
    // 注意：饿了么App主要通过淘宝/支付宝Scheme唤起
    var link = 'ele://search?query=$encodedKeyword';

    // 单个商品添加商品信息
    if (items.length == 1) {
      final item = items.first;
      if (item.foodId.isNotEmpty) {
        link = '$link&product_id=${item.foodId}';
      }
    }

    return link;
  }

  /// 生成H5降级链接
  String _generateH5Link(List<CartItem> items) {
    final keyword = _buildKeyword(items);
    final encodedKeyword = Uri.encodeComponent(keyword);
    return 'https://h5.ele.me/search?query=$encodedKeyword';
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
