import 'dart:convert';
import 'package:crypto/crypto.dart';
import 'package:dio/dio.dart';
import 'package:eatwhat_app/core/config/env_config.dart';
import 'package:eatwhat_app/core/services/meituan_auth_service.dart';
import 'package:eatwhat_app/v2/core/external/platform/platform_exceptions.dart';

/// 美团开放平台 API Client
///
/// 使用从 Chrome CDP 登录获取的认证信息，调用美团开放平台 API
class MeituanOpenPlatformClient {
  MeituanOpenPlatformClient({
    Dio? dio,
    MeituanAuthService? authService,
  })  : _dio = dio ?? Dio(),
        _authService = authService ?? MeituanAuthService();

  final Dio _dio;
  final MeituanAuthService _authService;

  /// API Base URL
  static const _baseUrl = 'https://open.meituan.com/api';

  /// 初始化 - 加载保存的认证信息
  Future<void> init() async {
    await _authService.loadSavedTokens();
  }

  /// 是否已认证
  bool get isAuthenticated => _authService.isLoggedIn;

  /// 当前认证信息
  MeituanAuthTokens? get tokens => _authService.currentTokens;

  /// 通过 CDP 自动化登录美团
  ///
  /// [username] 美团开放平台账号（手机号或邮箱）
  /// [password] 密码
  Future<MeituanAuthTokens> login({
    required String username,
    required String password,
  }) async {
    return await _authService.loginWithCdp(
      username: username,
      password: password,
    );
  }

  /// 登出
  Future<void> logout() async {
    await _authService.clearTokens();
  }

  /// 生成 API 请求签名（美团开放平台标准签名算法）
  ///
  /// 签名规则：
  /// 1. 将所有参数按字典序排列
  /// 2. 拼接成 key=value&key=value 格式
  /// 3. 在末尾拼接 App Secret
  /// 4. 对整个字符串进行 MD5 签名
  String _generateSignature(
    String method,
    String path,
    Map<String, String> params,
    String appSecret,
    int timestamp,
  ) {
    // 按字典序排序参数
    final sortedKeys = params.keys.toList()..sort();
    final sortedParams = <String, String>{};
    for (final key in sortedKeys) {
      sortedParams[key] = params[key] ?? '';
    }

    // 拼接成 key=value&key=value 格式
    final paramString =
        sortedParams.entries.map((e) => '${e.key}=${e.value}').join('&');

    // 拼接方法、路径、参数和密钥
    final signString = '$method&$path&$paramString&$appSecret';

    // MD5 签名
    final bytes = utf8.encode(signString);
    return md5.convert(bytes).toString();
  }

  /// 发送带签名的 GET 请求
  Future<Map<String, dynamic>> _signedGet(
    String path, {
    Map<String, String> extraParams = const {},
  }) async {
    if (!_authService.isLoggedIn) {
      throw PlatformApiException(
        'meituan',
        '未登录美团开放平台，请先调用 login()',
      );
    }

    final appKey = EnvConfig.meituanAppKey;
    final appSecret = EnvConfig.meituanAppSecret;

    // 如果 authService 有自己的 baseUrl 和 key/secret，使用它
    // 否则使用 env 配置
    final actualAppKey = appKey.isNotEmpty ? appKey : 'from_auth';
    final actualAppSecret = appSecret.isNotEmpty ? appSecret : 'from_auth';

    final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final params = <String, String>{
      'appKey': actualAppKey,
      'timestamp': timestamp.toString(),
      ...extraParams,
    };

    final signature = _generateSignature(
      'GET',
      path,
      params,
      actualAppSecret,
      timestamp,
    );
    params['sign'] = signature;

    final headers = {
      'Authorization': 'Bearer ${_authService.currentTokens?.accessToken}',
      'Accept': 'application/json',
      ..._authService.getAuthHeaders(),
    };

    try {
      final response = await _dio.get(
        '$_baseUrl$path',
        queryParameters: params,
        options: Options(headers: headers),
      );

      return _parseResponse(response);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  /// 发送带签名的 POST 请求
  Future<Map<String, dynamic>> _signedPost(
    String path, {
    Map<String, dynamic> body = const {},
  }) async {
    if (!_authService.isLoggedIn) {
      throw PlatformApiException(
        'meituan',
        '未登录美团开放平台，请先调用 login()',
      );
    }

    final appKey = EnvConfig.meituanAppKey;
    final appSecret = EnvConfig.meituanAppSecret;

    final actualAppKey = appKey.isNotEmpty ? appKey : 'from_auth';
    final actualAppSecret = appSecret.isNotEmpty ? appSecret : 'from_auth';

    final timestamp = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    final params = <String, String>{
      'appKey': actualAppKey,
      'timestamp': timestamp.toString(),
    };

    final signature = _generateSignature(
      'POST',
      path,
      params,
      actualAppSecret,
      timestamp,
    );
    params['sign'] = signature;

    final headers = {
      'Authorization': 'Bearer ${_authService.currentTokens?.accessToken}',
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      ..._authService.getAuthHeaders(),
    };

    try {
      final response = await _dio.post(
        '$_baseUrl$path',
        data: body,
        queryParameters: params,
        options: Options(headers: headers),
      );

      return _parseResponse(response);
    } on DioException catch (e) {
      throw _handleDioError(e);
    }
  }

  Map<String, dynamic> _parseResponse(Response response) {
    if (response.data == null) {
      return {};
    }
    if (response.data is String) {
      return jsonDecode(response.data as String) as Map<String, dynamic>;
    }
    return response.data as Map<String, dynamic>;
  }

  PlatformApiException _handleDioError(DioException error) {
    final statusCode = error.response?.statusCode;
    final message = error.message ?? '未知错误';
    final data = error.response?.data;
    String detailMessage = message;

    if (data is Map) {
      detailMessage = data['message']?.toString() ?? message;
    }

    return PlatformApiException(
      'meituan',
      detailMessage,
      statusCode: statusCode,
    );
  }

  // ==================== 开放平台 API ====================

  /// 搜索商户
  ///
  /// [keyword] 搜索关键词（店名、菜品名等）
  /// [latitude] 纬度
  /// [longitude] 经度
  /// [limit] 返回数量限制
  Future<MeituanMerchantSearchResult> searchMerchants({
    required String keyword,
    required double latitude,
    required double longitude,
    int limit = 20,
  }) async {
    final data = await _signedGet(
      '/waimai/merchant/search',
      extraParams: {
        'keyword': keyword,
        'latitude': latitude.toString(),
        'longitude': longitude.toString(),
        'limit': limit.toString(),
      },
    );

    return MeituanMerchantSearchResult.fromJson(data);
  }

  /// 获取商户详情
  ///
  /// [merchantId] 商户ID
  Future<MeituanMerchantDetail> getMerchantDetail(String merchantId) async {
    final data = await _signedGet(
      '/waimai/merchant/detail',
      extraParams: {'merchantId': merchantId},
    );

    return MeituanMerchantDetail.fromJson(data);
  }

  /// 搜索外卖菜品
  ///
  /// [keyword] 搜索关键词
  /// [latitude] 纬度
  /// [longitude] 经度
  /// [limit] 返回数量限制
  Future<MeituanDishSearchResult> searchDishes({
    required String keyword,
    required double latitude,
    required double longitude,
    int limit = 20,
  }) async {
    final data = await _signedGet(
      '/waimai/dish/search',
      extraParams: {
        'keyword': keyword,
        'latitude': latitude.toString(),
        'longitude': longitude.toString(),
        'limit': limit.toString(),
      },
    );

    return MeituanDishSearchResult.fromJson(data);
  }

  /// 预填充购物车
  ///
  /// [merchantId] 商户ID
  /// [items] 商品列表
  /// 返回预填充后的链接
  Future<String> prefillCart({
    required String merchantId,
    required List<CartItemInput> items,
  }) async {
    final data = await _signedPost(
      '/waimai/cart/prefill',
      body: {
        'merchantId': merchantId,
        'items': items.map((i) => i.toJson()).toList(),
      },
    );

    return data['prefillUrl']?.toString() ?? '';
  }

  /// 创建订单
  ///
  /// [createOrderRequest] 订单信息
  Future<MeituanOrderResult> createOrder(
    MeituanCreateOrderRequest createOrderRequest,
  ) async {
    final data = await _signedPost(
      '/waimai/order/create',
      body: createOrderRequest.toJson(),
    );

    return MeituanOrderResult.fromJson(data);
  }

  /// 查询订单状态
  ///
  /// [orderId] 订单ID
  Future<MeituanOrderStatus> getOrderStatus(String orderId) async {
    final data = await _signedGet(
      '/waimai/order/status',
      extraParams: {'orderId': orderId},
    );

    return MeituanOrderStatus.fromJson(data);
  }

  /// 获取订单详情
  ///
  /// [orderId] 订单ID
  Future<MeituanOrderDetail> getOrderDetail(String orderId) async {
    final data = await _signedGet(
      '/waimai/order/detail',
      extraParams: {'orderId': orderId},
    );

    return MeituanOrderDetail.fromJson(data);
  }

  /// 取消订单
  ///
  /// [orderId] 订单ID
  /// [reason] 取消原因
  Future<void> cancelOrder(String orderId, {String? reason}) async {
    await _signedPost(
      '/waimai/order/cancel',
      body: {
        'orderId': orderId,
        if (reason != null) 'reason': reason,
      },
    );
  }

  /// 释放资源
  void dispose() {
    _authService.dispose();
    _dio.close();
  }
}

// ==================== 数据模型 ====================

/// 购物车商品输入
class CartItemInput {
  final String dishId;
  final String name;
  final double price;
  final int quantity;
  final List<String>? specs;
  final String? comment;

  CartItemInput({
    required this.dishId,
    required this.name,
    required this.price,
    required this.quantity,
    this.specs,
    this.comment,
  });

  Map<String, dynamic> toJson() => {
        'dishId': dishId,
        'name': name,
        'price': price,
        'quantity': quantity,
        if (specs != null) 'specs': specs,
        if (comment != null) 'comment': comment,
      };
}

/// 商户搜索结果
class MeituanMerchantSearchResult {
  final int total;
  final List<MeituanMerchant> merchants;

  MeituanMerchantSearchResult({
    required this.total,
    required this.merchants,
  });

  factory MeituanMerchantSearchResult.fromJson(Map<String, dynamic> json) {
    return MeituanMerchantSearchResult(
      total: json['total'] as int? ?? 0,
      merchants: (json['merchants'] as List<dynamic>?)
              ?.map((m) => MeituanMerchant.fromJson(m))
              .toList() ??
          [],
    );
  }
}

/// 商户信息
class MeituanMerchant {
  final String id;
  final String name;
  final String address;
  final double? latitude;
  final double? longitude;
  final double? rating;
  final int? monthSales;
  final String? deliveryTime;
  final String? imageUrl;
  final double? averagePrice;

  MeituanMerchant({
    required this.id,
    required this.name,
    required this.address,
    this.latitude,
    this.longitude,
    this.rating,
    this.monthSales,
    this.deliveryTime,
    this.imageUrl,
    this.averagePrice,
  });

  factory MeituanMerchant.fromJson(Map<String, dynamic> json) {
    return MeituanMerchant(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      rating: (json['rating'] as num?)?.toDouble(),
      monthSales: json['monthSales'] as int?,
      deliveryTime: json['deliveryTime']?.toString(),
      imageUrl: json['imageUrl']?.toString(),
      averagePrice: (json['averagePrice'] as num?)?.toDouble(),
    );
  }
}

/// 商户详情
class MeituanMerchantDetail extends MeituanMerchant {
  final List<MeituanDish> dishes;
  final String? description;
  final List<String>? tags;
  final String? phone;
  final String? businessHours;

  MeituanMerchantDetail({
    required super.id,
    required super.name,
    required super.address,
    super.latitude,
    super.longitude,
    super.rating,
    super.monthSales,
    super.deliveryTime,
    super.imageUrl,
    super.averagePrice,
    required this.dishes,
    this.description,
    this.tags,
    this.phone,
    this.businessHours,
  });

  factory MeituanMerchantDetail.fromJson(Map<String, dynamic> json) {
    return MeituanMerchantDetail(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      rating: (json['rating'] as num?)?.toDouble(),
      monthSales: json['monthSales'] as int?,
      deliveryTime: json['deliveryTime']?.toString(),
      imageUrl: json['imageUrl']?.toString(),
      averagePrice: (json['averagePrice'] as num?)?.toDouble(),
      dishes: (json['dishes'] as List<dynamic>?)
              ?.map((d) => MeituanDish.fromJson(d))
              .toList() ??
          [],
      description: json['description']?.toString(),
      tags: (json['tags'] as List<dynamic>?)?.cast<String>(),
      phone: json['phone']?.toString(),
      businessHours: json['businessHours']?.toString(),
    );
  }
}

/// 菜品信息
class MeituanDish {
  final String id;
  final String name;
  final double price;
  final String? imageUrl;
  final String? description;
  final int? sales;
  final String? unit;

  MeituanDish({
    required this.id,
    required this.name,
    required this.price,
    this.imageUrl,
    this.description,
    this.sales,
    this.unit,
  });

  factory MeituanDish.fromJson(Map<String, dynamic> json) {
    return MeituanDish(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0,
      imageUrl: json['imageUrl']?.toString(),
      description: json['description']?.toString(),
      sales: json['sales'] as int?,
      unit: json['unit']?.toString(),
    );
  }
}

/// 菜品搜索结果
class MeituanDishSearchResult {
  final int total;
  final List<MeituanDish> dishes;

  MeituanDishSearchResult({
    required this.total,
    required this.dishes,
  });

  factory MeituanDishSearchResult.fromJson(Map<String, dynamic> json) {
    return MeituanDishSearchResult(
      total: json['total'] as int? ?? 0,
      dishes: (json['dishes'] as List<dynamic>?)
              ?.map((d) => MeituanDish.fromJson(d))
              .toList() ??
          [],
    );
  }
}

/// 创建订单请求
class MeituanCreateOrderRequest {
  final String merchantId;
  final String addressId;
  final List<CartItemInput> items;
  final String? remark;
  final int? couponId;

  MeituanCreateOrderRequest({
    required this.merchantId,
    required this.addressId,
    required this.items,
    this.remark,
    this.couponId,
  });

  Map<String, dynamic> toJson() => {
        'merchantId': merchantId,
        'addressId': addressId,
        'items': items.map((i) => i.toJson()).toList(),
        if (remark != null) 'remark': remark,
        if (couponId != null) 'couponId': couponId,
      };
}

/// 订单结果
class MeituanOrderResult {
  final String orderId;
  final String status;
  final double totalPrice;
  final String? message;

  MeituanOrderResult({
    required this.orderId,
    required this.status,
    required this.totalPrice,
    this.message,
  });

  factory MeituanOrderResult.fromJson(Map<String, dynamic> json) {
    return MeituanOrderResult(
      orderId: json['orderId']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      totalPrice: (json['totalPrice'] as num?)?.toDouble() ?? 0,
      message: json['message']?.toString(),
    );
  }
}

/// 订单状态
class MeituanOrderStatus {
  final String orderId;
  final String status;
  final String? statusDescription;
  final String? deliveryTime;
  final String? riderName;
  final String? riderPhone;

  MeituanOrderStatus({
    required this.orderId,
    required this.status,
    this.statusDescription,
    this.deliveryTime,
    this.riderName,
    this.riderPhone,
  });

  factory MeituanOrderStatus.fromJson(Map<String, dynamic> json) {
    return MeituanOrderStatus(
      orderId: json['orderId']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      statusDescription: json['statusDescription']?.toString(),
      deliveryTime: json['deliveryTime']?.toString(),
      riderName: json['riderName']?.toString(),
      riderPhone: json['riderPhone']?.toString(),
    );
  }
}

/// 订单详情
class MeituanOrderDetail {
  final String orderId;
  final String status;
  final MeituanMerchant merchant;
  final List<MeituanOrderItem> items;
  final double totalPrice;
  final double deliveryFee;
  final String? address;
  final String? createTime;
  final String? payTime;

  MeituanOrderDetail({
    required this.orderId,
    required this.status,
    required this.merchant,
    required this.items,
    required this.totalPrice,
    required this.deliveryFee,
    this.address,
    this.createTime,
    this.payTime,
  });

  factory MeituanOrderDetail.fromJson(Map<String, dynamic> json) {
    return MeituanOrderDetail(
      orderId: json['orderId']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      merchant: MeituanMerchant.fromJson(json['merchant'] ?? {}),
      items: (json['items'] as List<dynamic>?)
              ?.map((i) => MeituanOrderItem.fromJson(i))
              .toList() ??
          [],
      totalPrice: (json['totalPrice'] as num?)?.toDouble() ?? 0,
      deliveryFee: (json['deliveryFee'] as num?)?.toDouble() ?? 0,
      address: json['address']?.toString(),
      createTime: json['createTime']?.toString(),
      payTime: json['payTime']?.toString(),
    );
  }
}

/// 订单商品项
class MeituanOrderItem {
  final String dishId;
  final String name;
  final double price;
  final int quantity;
  final List<String>? specs;

  MeituanOrderItem({
    required this.dishId,
    required this.name,
    required this.price,
    required this.quantity,
    this.specs,
  });

  factory MeituanOrderItem.fromJson(Map<String, dynamic> json) {
    return MeituanOrderItem(
      dishId: json['dishId']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0,
      quantity: json['quantity'] as int? ?? 1,
      specs: (json['specs'] as List<dynamic>?)?.cast<String>(),
    );
  }
}
