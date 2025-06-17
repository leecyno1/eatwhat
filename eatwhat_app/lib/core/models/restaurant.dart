import 'dart:math';

/// 餐厅信息模型
/// 统一美团外卖和饿了么的餐厅数据格式
class Restaurant {
  final String id;
  final String name;
  final String address;
  final String? phone;
  final String? description;
  final String? logoUrl;
  final String? imageUrl;
  final double? latitude;
  final double? longitude;
  final double? distance; // 距离（米）
  final double? rating; // 评分
  final int? reviewCount; // 评价数量
  final String? openTime; // 营业时间
  final String? closeTime;
  final double? deliveryFee; // 配送费
  final double? minOrderAmount; // 起送价
  final int? deliveryTime; // 配送时间（分钟）
  final bool isOpen; // 是否营业
  final RestaurantPlatform platform; // 平台来源
  final List<String> categories; // 餐厅分类
  final List<String> tags; // 标签
  final String? announcement; // 公告
  final bool isPromotional; // 是否有优惠
  final String? promotionalInfo; // 优惠信息
  
  const Restaurant({
    required this.id,
    required this.name,
    required this.address,
    this.phone,
    this.description,
    this.logoUrl,
    this.imageUrl,
    this.latitude,
    this.longitude,
    this.distance,
    this.rating,
    this.reviewCount,
    this.openTime,
    this.closeTime,
    this.deliveryFee,
    this.minOrderAmount,
    this.deliveryTime,
    this.isOpen = true,
    this.platform = RestaurantPlatform.unknown,
    this.categories = const [],
    this.tags = const [],
    this.announcement,
    this.isPromotional = false,
    this.promotionalInfo,
  });
  
  /// 从美团API数据创建餐厅对象
  factory Restaurant.fromMeiTuanJson(Map<String, dynamic> json) {
    return Restaurant(
      id: json['poi_id']?.toString() ?? '',
      name: json['name'] ?? '',
      address: json['address'] ?? '',
      phone: json['phone'],
      description: json['description'],
      logoUrl: json['logo_url'],
      imageUrl: json['pic_url'],
      latitude: _parseDouble(json['latitude']),
      longitude: _parseDouble(json['longitude']),
      distance: _parseDouble(json['distance']),
      rating: _parseDouble(json['avg_score']),
      reviewCount: _parseInt(json['review_count']),
      openTime: json['open_time'],
      closeTime: json['close_time'],
      deliveryFee: _parseDouble(json['delivery_fee']),
      minOrderAmount: _parseDouble(json['min_order_amount']),
      deliveryTime: _parseInt(json['delivery_time']),
      isOpen: json['is_open'] == 1 || json['is_open'] == true,
      platform: RestaurantPlatform.meituan,
      categories: _parseStringList(json['categories']),
      tags: _parseStringList(json['tags']),
      announcement: json['announcement'],
      isPromotional: json['has_activity'] == 1 || json['has_activity'] == true,
      promotionalInfo: json['activity_info'],
    );
  }
  
  /// 从饿了么API数据创建餐厅对象
  factory Restaurant.fromElemeJson(Map<String, dynamic> json) {
    return Restaurant(
      id: json['restaurant_id']?.toString() ?? '',
      name: json['name'] ?? '',
      address: json['address'] ?? '',
      phone: json['phone'],
      description: json['description'],
      logoUrl: json['image_url'],
      imageUrl: json['image_url'],
      latitude: _parseDouble(json['latitude']),
      longitude: _parseDouble(json['longitude']),
      distance: _parseDouble(json['distance']),
      rating: _parseDouble(json['rating']),
      reviewCount: _parseInt(json['rating_count']),
      openTime: json['opening_hours']?['open'],
      closeTime: json['opening_hours']?['close'],
      deliveryFee: _parseDouble(json['float_delivery_fee']),
      minOrderAmount: _parseDouble(json['float_minimum_order_amount']),
      deliveryTime: _parseInt(json['order_lead_time']),
      isOpen: json['is_open'] == 1 || json['is_open'] == true,
      platform: RestaurantPlatform.eleme,
      categories: _parseStringList(json['flavors']),
      tags: _parseStringList(json['tags']),
      announcement: json['promotion_info'],
      isPromotional: json['activities']?.isNotEmpty == true,
      promotionalInfo: json['activities']?.first?['description'],
    );
  }
  
  /// 计算与指定位置的距离
  double? calculateDistance(double targetLat, double targetLng) {
    if (latitude == null || longitude == null) return null;
    
    return _calculateHaversineDistance(
      latitude!, longitude!, 
      targetLat, targetLng
    );
  }
  
  /// 是否在配送范围内
  bool isInDeliveryRange(double targetLat, double targetLng, {double maxDistance = 5000}) {
    final dist = calculateDistance(targetLat, targetLng);
    return dist != null && dist <= maxDistance;
  }
  
  /// 获取营业状态文本
  String get businessStatusText {
    if (!isOpen) return '休息中';
    
    final now = DateTime.now();
    final currentTime = '${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}';
    
    if (openTime != null && closeTime != null) {
      if (_isTimeInRange(currentTime, openTime!, closeTime!)) {
        return '营业中';
      } else {
        return '休息中';
      }
    }
    
    return isOpen ? '营业中' : '休息中';
  }
  
  /// 获取配送信息文本
  String get deliveryInfoText {
    final parts = <String>[];
    
    if (deliveryFee != null) {
      parts.add('配送费¥${deliveryFee!.toStringAsFixed(1)}');
    }
    
    if (minOrderAmount != null) {
      parts.add('起送¥${minOrderAmount!.toStringAsFixed(0)}');
    }
    
    if (deliveryTime != null) {
      parts.add('${deliveryTime}分钟');
    }
    
    return parts.join(' · ');
  }
  
  /// 获取距离文本
  String get distanceText {
    if (distance == null) return '';
    
    if (distance! < 1000) {
      return '${distance!.toInt()}m';
    } else {
      return '${(distance! / 1000).toStringAsFixed(1)}km';
    }
  }
  
  /// 获取评分文本
  String get ratingText {
    if (rating == null) return '';
    return rating!.toStringAsFixed(1);
  }
  
  /// 复制并修改餐厅信息
  Restaurant copyWith({
    String? id,
    String? name,
    String? address,
    String? phone,
    String? description,
    String? logoUrl,
    String? imageUrl,
    double? latitude,
    double? longitude,
    double? distance,
    double? rating,
    int? reviewCount,
    String? openTime,
    String? closeTime,
    double? deliveryFee,
    double? minOrderAmount,
    int? deliveryTime,
    bool? isOpen,
    RestaurantPlatform? platform,
    List<String>? categories,
    List<String>? tags,
    String? announcement,
    bool? isPromotional,
    String? promotionalInfo,
  }) {
    return Restaurant(
      id: id ?? this.id,
      name: name ?? this.name,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      description: description ?? this.description,
      logoUrl: logoUrl ?? this.logoUrl,
      imageUrl: imageUrl ?? this.imageUrl,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      distance: distance ?? this.distance,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      openTime: openTime ?? this.openTime,
      closeTime: closeTime ?? this.closeTime,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      minOrderAmount: minOrderAmount ?? this.minOrderAmount,
      deliveryTime: deliveryTime ?? this.deliveryTime,
      isOpen: isOpen ?? this.isOpen,
      platform: platform ?? this.platform,
      categories: categories ?? this.categories,
      tags: tags ?? this.tags,
      announcement: announcement ?? this.announcement,
      isPromotional: isPromotional ?? this.isPromotional,
      promotionalInfo: promotionalInfo ?? this.promotionalInfo,
    );
  }
  
  @override
  String toString() {
    return 'Restaurant(id: $id, name: $name, platform: $platform, isOpen: $isOpen)';
  }
  
  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Restaurant && other.id == id && other.platform == platform;
  }
  
  @override
  int get hashCode => Object.hash(id, platform);
}

/// 餐厅平台枚举
enum RestaurantPlatform {
  meituan('美团外卖'),
  eleme('饿了么'),
  unknown('未知');
  
  const RestaurantPlatform(this.displayName);
  final String displayName;
}

// 辅助函数
double? _parseDouble(dynamic value) {
  if (value == null) return null;
  if (value is double) return value;
  if (value is int) return value.toDouble();
  if (value is String) return double.tryParse(value);
  return null;
}

int? _parseInt(dynamic value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is double) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}

List<String> _parseStringList(dynamic value) {
  if (value == null) return [];
  if (value is List) {
    return value.map((e) => e.toString()).toList();
  }
  if (value is String) {
    return value.split(',').map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
  }
  return [];
}

/// 计算两点间的距离（米）
double _calculateHaversineDistance(double lat1, double lon1, double lat2, double lon2) {
  const double earthRadius = 6371000; // 地球半径（米）
  
  final double dLat = _degreesToRadians(lat2 - lat1);
  final double dLon = _degreesToRadians(lon2 - lon1);
  
  final double a = sin(dLat / 2) * sin(dLat / 2) +
      cos(_degreesToRadians(lat1)) * cos(_degreesToRadians(lat2)) *
      sin(dLon / 2) * sin(dLon / 2);
  
  final double c = 2 * atan2(sqrt(a), sqrt(1 - a));
  
  return earthRadius * c;
}

double _degreesToRadians(double degrees) {
  return degrees * pi / 180;
}

/// 检查时间是否在范围内
bool _isTimeInRange(String currentTime, String openTime, String closeTime) {
  try {
    final current = _parseTime(currentTime);
    final open = _parseTime(openTime);
    final close = _parseTime(closeTime);
    
    if (close < open) {
      // 跨天营业（如 22:00 - 02:00）
      return current >= open || current <= close;
    } else {
      // 当天营业
      return current >= open && current <= close;
    }
  } catch (e) {
    return true; // 解析失败时默认营业
  }
}

int _parseTime(String timeStr) {
  final parts = timeStr.split(':');
  if (parts.length != 2) throw FormatException('Invalid time format: $timeStr');
  
  final hour = int.parse(parts[0]);
  final minute = int.parse(parts[1]);
  
  return hour * 60 + minute; // 转换为分钟数
}