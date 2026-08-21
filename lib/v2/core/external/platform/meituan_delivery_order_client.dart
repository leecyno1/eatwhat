import 'package:eatwhat_app/core/config/env_config.dart';
import 'package:eatwhat_app/v2/core/external/platform/execution_proxy_client.dart';
import 'package:eatwhat_app/v2/core/external/platform/platform_types.dart';

/// 美团消费者点餐客户端。
///
/// 只调用 EatWhat 自己的代理后端；AppID、AppSecret、OAuth token
/// 和美团签名全部保留在服务端。
class MeituanDeliveryOrderClient {
  MeituanDeliveryOrderClient({ExecutionProxyClient? client})
      : _client = client ?? ExecutionProxyClient();

  final ExecutionProxyClient _client;

  /// Whether the execution proxy backend is configured at all. When false,
  /// every ordering call would fail on network grounds — entry points use
  /// this to degrade gracefully (外卖服务暂未接入) instead of walking the
  /// user through login only to hit a technical error.
  bool get isConfigured => _client.isConfigured;

  Future<MeituanOAuthStatus> getOAuthStatus() async {
    final payload = await _client.getJson(EnvConfig.meituanOAuthStatusPath);
    return MeituanOAuthStatus.fromJson(payload);
  }

  Future<Uri> createOAuthAuthorizationUri() async {
    final payload = await _client.postJson(EnvConfig.meituanOAuthAuthorizePath);
    final rawUrl = payload['authorizationUrl']?.toString() ?? '';
    final uri = Uri.tryParse(rawUrl);
    if (uri == null || !uri.hasScheme) {
      throw StateError('吃什么服务端没有返回可用的美团服务授权地址');
    }
    return uri;
  }

  Future<Map<String, dynamic>> searchMerchants({
    required String keyword,
    required GeoPoint location,
    int limit = 10,
  }) {
    return _client.postJson(
      EnvConfig.meituanMerchantSearchPath,
      body: {
        'keyword': keyword,
        'geo': _geo(location),
        'limit': limit,
      },
    );
  }

  Future<MeituanMerchantSearchResult> searchMerchantResults({
    required String keyword,
    required GeoPoint location,
    int limit = 10,
  }) async {
    final payload = await searchMerchants(
      keyword: keyword,
      location: location,
      limit: limit,
    );
    return MeituanMerchantSearchResult.fromJson(payload);
  }

  Future<MeituanProductSearchResult> searchProducts({
    required String merchantId,
    required GeoPoint location,
    String keyword = '',
  }) async {
    final payload = await _client.postJson(
      EnvConfig.meituanProductSearchPath,
      body: {
        'merchantId': merchantId,
        'keyword': keyword,
        'geo': _geo(location),
      },
    );
    return MeituanProductSearchResult.fromJson(payload);
  }

  Future<MeituanOrderPreview> previewOrder(
    MeituanDeliveryOrderRequest request,
  ) async {
    final payload = await _client.postJson(
      EnvConfig.meituanOrderPreviewPath,
      body: request.toJson(),
    );
    return MeituanOrderPreview.fromJson(payload);
  }

  Future<MeituanSubmittedOrder> submitOrder(
    MeituanDeliveryOrderRequest request, {
    required String previewToken,
    String? verifyCode,
    String? paymentSuccessUrl,
    String? paymentFailureUrl,
  }) async {
    final payload = await _client.postJson(
      EnvConfig.meituanOrderSubmitPath,
      body: {
        ...request.toJson(),
        'previewToken': previewToken,
        if (verifyCode?.isNotEmpty == true) 'verifyCode': verifyCode,
        if (paymentSuccessUrl?.isNotEmpty == true)
          'paymentSuccessUrl': paymentSuccessUrl,
        if (paymentFailureUrl?.isNotEmpty == true)
          'paymentFailureUrl': paymentFailureUrl,
      },
    );
    return MeituanSubmittedOrder.fromJson(payload);
  }

  Map<String, double> _geo(GeoPoint location) {
    return {
      'latitude': location.latitude,
      'longitude': location.longitude,
    };
  }
}

class MeituanOAuthStatus {
  const MeituanOAuthStatus({
    required this.connected,
    required this.requiresUserAuthorization,
    this.nickname,
    this.maskedPhone,
  });

  factory MeituanOAuthStatus.fromJson(Map<String, dynamic> json) {
    return MeituanOAuthStatus(
      connected: json['connected'] == true,
      requiresUserAuthorization: json['requiresUserAuthorization'] != false,
      nickname: json['nickname']?.toString(),
      maskedPhone: json['maskedPhone']?.toString(),
    );
  }

  final bool connected;
  final bool requiresUserAuthorization;
  final String? nickname;
  final String? maskedPhone;
}

class MeituanMerchantSearchResult {
  const MeituanMerchantSearchResult({
    required this.merchants,
    required this.hasNextPage,
  });

  factory MeituanMerchantSearchResult.fromJson(Map<String, dynamic> json) {
    return MeituanMerchantSearchResult(
      merchants: _maps(json['merchants'])
          .map(MeituanDeliveryMerchant.fromJson)
          .toList(),
      hasNextPage: json['hasNextPage'] == true,
    );
  }

  final List<MeituanDeliveryMerchant> merchants;
  final bool hasNextPage;
}

class MeituanDeliveryMerchant {
  const MeituanDeliveryMerchant({
    required this.merchantId,
    required this.merchantName,
    this.address = '',
    this.imageUrl,
    this.rating,
    this.deliveryTimeMinutes,
    this.shippingFee,
    this.minimumPrice,
  });

  factory MeituanDeliveryMerchant.fromJson(Map<String, dynamic> json) {
    return MeituanDeliveryMerchant(
      merchantId: json['merchantId']?.toString() ?? '',
      merchantName: json['merchantName']?.toString() ?? '',
      address: json['address']?.toString() ?? '',
      imageUrl: json['imageUrl']?.toString(),
      rating: _nullableDouble(json['rating']),
      deliveryTimeMinutes: _nullableInt(json['deliveryTimeMinutes']),
      shippingFee: _nullableDouble(json['shippingFee']),
      minimumPrice: _nullableDouble(json['minimumOrder']),
    );
  }

  final String merchantId;
  final String merchantName;
  final String address;
  final String? imageUrl;
  final double? rating;
  final int? deliveryTimeMinutes;
  final double? shippingFee;
  final double? minimumPrice;
}

class MeituanProductSearchResult {
  const MeituanProductSearchResult({
    required this.merchantName,
    required this.products,
  });

  factory MeituanProductSearchResult.fromJson(Map<String, dynamic> json) {
    final merchant = _map(json['merchant']);
    return MeituanProductSearchResult(
      merchantName: merchant['merchantName']?.toString() ?? '',
      products:
          _maps(json['products']).map(MeituanDeliveryProduct.fromJson).toList(),
    );
  }

  final String merchantName;
  final List<MeituanDeliveryProduct> products;
}

class MeituanDeliveryProduct {
  const MeituanDeliveryProduct({
    required this.productId,
    required this.name,
    required this.skus,
    required this.attributes,
    this.imageUrl,
    this.description,
    this.categoryId = '',
    this.categoryName = '',
    this.monthlySales,
  });

  factory MeituanDeliveryProduct.fromJson(Map<String, dynamic> json) {
    return MeituanDeliveryProduct(
      productId: json['productId']?.toString() ?? '',
      name: json['name']?.toString() ?? '',
      imageUrl: json['imageUrl']?.toString(),
      description: json['description']?.toString(),
      categoryId: json['categoryId']?.toString() ?? '',
      categoryName: json['categoryName']?.toString() ?? '',
      monthlySales: _nullableInt(json['monthlySales']),
      skus: _maps(json['skus']).map(MeituanDeliverySku.fromJson).toList(),
      attributes: _maps(json['attributes'])
          .map(MeituanDeliveryAttribute.fromJson)
          .toList(),
    );
  }

  final String productId;
  final String name;
  final String? imageUrl;
  final String? description;
  final String categoryId;
  final String categoryName;
  final int? monthlySales;
  final List<MeituanDeliverySku> skus;
  final List<MeituanDeliveryAttribute> attributes;
}

class MeituanDeliverySku {
  const MeituanDeliverySku({
    required this.skuId,
    required this.price,
    this.specification = '',
    this.stock,
    this.status = 0,
    this.minimumOrderCount = 1,
    this.boxPrice = 0,
  });

  factory MeituanDeliverySku.fromJson(Map<String, dynamic> json) {
    return MeituanDeliverySku(
      skuId: json['skuId']?.toString() ?? '',
      price: _double(json['price']),
      specification: json['specification']?.toString() ?? '',
      stock: _nullableInt(json['stock']),
      status: _int(json['status']),
      minimumOrderCount: _int(json['minimumOrderCount']).clamp(1, 999),
      boxPrice: _double(json['boxPrice']),
    );
  }

  final String skuId;
  final double price;
  final String specification;
  final int? stock;
  final int status;
  final int minimumOrderCount;
  final double boxPrice;

  bool get isAvailable => status == 0 && stock != 0 && skuId.isNotEmpty;
}

class MeituanDeliveryAttribute {
  const MeituanDeliveryAttribute({
    required this.name,
    required this.values,
  });

  factory MeituanDeliveryAttribute.fromJson(Map<String, dynamic> json) {
    return MeituanDeliveryAttribute(
      name: json['name']?.toString() ?? '',
      values: _maps(json['values'])
          .map(MeituanDeliveryAttributeValue.fromJson)
          .toList(),
    );
  }

  final String name;
  final List<MeituanDeliveryAttributeValue> values;
}

class MeituanDeliveryAttributeValue {
  const MeituanDeliveryAttributeValue({
    required this.id,
    required this.label,
  });

  factory MeituanDeliveryAttributeValue.fromJson(Map<String, dynamic> json) {
    return MeituanDeliveryAttributeValue(
      id: _int(json['id']),
      label: json['value']?.toString() ?? '',
    );
  }

  final int id;
  final String label;
}

class MeituanOrderPreview {
  const MeituanOrderPreview({
    required this.previewToken,
    required this.total,
    required this.shippingFee,
    required this.boxFee,
    required this.merchantName,
  });

  factory MeituanOrderPreview.fromJson(Map<String, dynamic> json) {
    final preview = _map(json['preview']);
    return MeituanOrderPreview(
      previewToken: json['previewToken']?.toString() ?? '',
      total: _double(preview['total']),
      shippingFee: _double(preview['shippingFee']),
      boxFee: _double(preview['boxFee']),
      merchantName: preview['merchantName']?.toString() ?? '',
    );
  }

  final String previewToken;
  final double total;
  final double shippingFee;
  final double boxFee;
  final String merchantName;
}

class MeituanSubmittedOrder {
  const MeituanSubmittedOrder({
    required this.status,
    required this.orderId,
    required this.paymentUrl,
    required this.requiresVerification,
    this.message,
  });

  factory MeituanSubmittedOrder.fromJson(Map<String, dynamic> json) {
    return MeituanSubmittedOrder(
      status: json['status']?.toString() ?? '',
      orderId: json['orderId']?.toString() ?? '',
      paymentUrl: json['paymentUrl']?.toString() ?? '',
      requiresVerification: json['requiresVerification'] == true,
      message: json['message']?.toString(),
    );
  }

  final String status;
  final String orderId;
  final String paymentUrl;
  final bool requiresVerification;
  final String? message;
}

class MeituanDeliveryOrderRequest {
  const MeituanDeliveryOrderRequest({
    required this.merchantId,
    required this.items,
    this.addressId,
    this.recipient,
    this.deliveryTime = 0,
  });

  final String merchantId;
  final List<MeituanDeliveryOrderItem> items;
  final String? addressId;
  final MeituanDeliveryRecipient? recipient;
  final int deliveryTime;

  Map<String, dynamic> toJson() {
    return {
      'merchantId': merchantId,
      'items': items.map((item) => item.toJson()).toList(),
      if (addressId?.isNotEmpty == true) 'addressId': addressId,
      if (recipient != null) 'recipient': recipient!.toJson(),
      'deliveryTime': deliveryTime,
    };
  }
}

class MeituanDeliveryOrderItem {
  const MeituanDeliveryOrderItem({
    required this.skuId,
    required this.count,
    this.attributeIds = const [],
  });

  final String skuId;
  final int count;
  final List<int> attributeIds;

  Map<String, dynamic> toJson() {
    return {
      'skuId': skuId,
      'count': count,
      if (attributeIds.isNotEmpty) 'attributeIds': attributeIds,
    };
  }
}

class MeituanDeliveryRecipient {
  const MeituanDeliveryRecipient({
    required this.name,
    required this.phone,
    required this.address,
    required this.currentLocation,
    required this.addressLocation,
    this.houseNumber,
    this.note,
  });

  final String name;
  final String phone;
  final String address;
  final GeoPoint currentLocation;
  final GeoPoint addressLocation;
  final String? houseNumber;
  final String? note;

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'phone': phone,
      'address': address,
      'currentLatitude': currentLocation.latitude,
      'currentLongitude': currentLocation.longitude,
      'addressLatitude': addressLocation.latitude,
      'addressLongitude': addressLocation.longitude,
      if (houseNumber?.isNotEmpty == true) 'houseNumber': houseNumber,
      if (note?.isNotEmpty == true) 'note': note,
    };
  }
}

Map<String, dynamic> _map(dynamic value) {
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  return const {};
}

Iterable<Map<String, dynamic>> _maps(dynamic value) sync* {
  if (value is! List) return;
  for (final item in value) {
    if (item is Map) yield Map<String, dynamic>.from(item);
  }
}

int _int(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? 0;
}

int? _nullableInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}

double _double(dynamic value) {
  if (value is num) return value.toDouble();
  return double.tryParse(value?.toString() ?? '') ?? 0;
}

double? _nullableDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString());
}
