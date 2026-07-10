import 'food.dart';

/// 外卖平台枚举
enum DeliveryPlatform {
  meituan('美团外卖'),
  eleme('饿了么'),
  unknown('未知');

  const DeliveryPlatform(this.displayName);
  final String displayName;
}

/// 食品规格平台枚举
enum FoodItemPlatform {
  meituan('美团外卖'),
  eleme('饿了么'),
  unknown('未知');

  const FoodItemPlatform(this.displayName);
  final String displayName;
}

/// 餐次类型
enum MealType {
  breakfast('早餐'),
  lunch('午餐'),
  dinner('晚餐'),
  snack('零食'),
  lateNight('夜宵');

  const MealType(this.displayName);
  final String displayName;
}

/// 外卖平台菜品模型
/// 扩展基础Food模型，添加外卖平台特有的属性
class FoodItem extends Food {
  final String restaurantId;
  final String? categoryId;
  final String? categoryName;
  final double originalPrice; // 原价
  final double? discountPrice; // 折扣价
  final bool isAvailable; // 是否有货
  final int? stock; // 库存数量
  final int salesCount; // 销量
  final List<FoodSpec> specs; // 规格选项
  final List<String> allergens; // 过敏原信息
  final FoodItemPlatform platform; // 平台来源
  final String? platformItemId; // 平台商品ID
  final bool isRecommended; // 是否推荐
  final bool isNew; // 是否新品
  final bool isHot; // 是否热销
  @override
  final int? preparationTime; // 制作时间（分钟）
  final Map<String, dynamic>? platformData; // 平台原始数据

  FoodItem({
    required super.id,
    required super.name,
    super.description,
    required super.cuisineType,
    super.tasteAttributes = const [],
    super.ingredients = const [],
    super.scenarios,
    super.calories,
    super.rating = 0.0,
    super.ratingCount = 0,
    super.imageUrl,
    super.nutritionFacts,
    super.price,
    super.restaurant,
    super.isFavorite = false,
    super.emoji,
    super.score,
    super.tags,
    required this.restaurantId,
    this.categoryId,
    this.categoryName,
    required this.originalPrice,
    this.discountPrice,
    this.isAvailable = true,
    this.stock,
    this.salesCount = 0,
    this.specs = const [],
    this.allergens = const [],
    this.platform = FoodItemPlatform.unknown,
    this.platformItemId,
    this.isRecommended = false,
    this.isNew = false,
    this.isHot = false,
    this.preparationTime,
    this.platformData,
  });

  /// 从美团API数据创建菜品对象
  factory FoodItem.fromMeiTuanJson(Map<String, dynamic> json) {
    final specs = <FoodSpec>[];
    if (json['skus'] != null) {
      for (final sku in json['skus']) {
        specs.add(FoodSpec.fromMeiTuanJson(sku));
      }
    }

    return FoodItem(
      id: json['food_id']?.toString() ?? '',
      platformItemId: json['food_id']?.toString(),
      name: json['food_name'] ?? '',
      description: json['food_description'],
      cuisineType: json['category_name'] ?? '其他',
      tasteAttributes: _parseStringList(json['attributes']),
      ingredients: _parseStringList(json['ingredients']),
      calories: _parseDouble(json['calorie']),
      rating: _parseDouble(json['rating']) ?? 0.0,
      ratingCount: _parseInt(json['rating_count']) ?? 0,
      imageUrl: json['picture'],
      price: _parseDouble(json['price']),
      restaurant: json['restaurant_name'],
      restaurantId: json['restaurant_id']?.toString() ?? '',
      categoryId: json['category_id']?.toString(),
      categoryName: json['category_name'],
      originalPrice: _parseDouble(json['original_price']) ?? 0.0,
      discountPrice: _parseDouble(json['activity_price']),
      isAvailable: json['is_sold_out'] != 1,
      stock: _parseInt(json['stock']),
      salesCount: _parseInt(json['month_sales']) ?? 0,
      specs: specs,
      allergens: _parseStringList(json['allergens']),
      platform: FoodItemPlatform.meituan,
      isRecommended: json['is_featured'] == 1,
      isNew: json['is_new'] == 1,
      isHot: json['is_popular'] == 1,
      preparationTime: _parseInt(json['prepare_time']),
      platformData: json,
    );
  }

  /// 从饿了么API数据创建菜品对象
  factory FoodItem.fromElemeJson(Map<String, dynamic> json) {
    final specs = <FoodSpec>[];
    if (json['specifications'] != null) {
      for (final spec in json['specifications']) {
        specs.add(FoodSpec.fromElemeJson(spec));
      }
    }

    return FoodItem(
      id: json['item_id']?.toString() ?? '',
      platformItemId: json['item_id']?.toString(),
      name: json['name'] ?? '',
      description: json['description'],
      cuisineType: json['category_name'] ?? '其他',
      tasteAttributes: _parseStringList(json['attributes']),
      ingredients: _parseStringList(json['ingredients']),
      calories: _parseDouble(json['calorie']),
      rating: _parseDouble(json['rating']) ?? 0.0,
      ratingCount: _parseInt(json['rating_count']) ?? 0,
      imageUrl: json['image_url'],
      price: _parseDouble(json['price']),
      restaurant: json['restaurant_name'],
      restaurantId: json['restaurant_id']?.toString() ?? '',
      categoryId: json['category_id']?.toString(),
      categoryName: json['category_name'],
      originalPrice: _parseDouble(json['original_price']) ?? 0.0,
      discountPrice: _parseDouble(json['activity_price']),
      isAvailable: json['is_available'] == true,
      stock: _parseInt(json['stock']),
      salesCount: _parseInt(json['recent_sales']) ?? 0,
      specs: specs,
      allergens: _parseStringList(json['allergens']),
      platform: FoodItemPlatform.eleme,
      isRecommended: json['is_featured'] == true,
      isNew: json['is_new'] == true,
      isHot: json['is_popular'] == true,
      preparationTime: _parseInt(json['prepare_time']),
      platformData: json,
    );
  }

  /// 获取当前有效价格
  double get currentPrice {
    return discountPrice ?? originalPrice;
  }

  /// 是否有折扣
  bool get hasDiscount {
    return discountPrice != null && discountPrice! < originalPrice;
  }

  /// 折扣百分比
  double? get discountPercentage {
    if (!hasDiscount) return null;
    return ((originalPrice - discountPrice!) / originalPrice * 100);
  }

  /// 获取价格显示文本
  String get priceText {
    if (hasDiscount) {
      return '¥${discountPrice!.toStringAsFixed(1)}';
    }
    return '¥${originalPrice.toStringAsFixed(1)}';
  }

  /// 获取原价显示文本（有折扣时显示）
  String? get originalPriceText {
    if (hasDiscount) {
      return '¥${originalPrice.toStringAsFixed(1)}';
    }
    return null;
  }

  /// 获取销量文本
  String get salesText {
    if (salesCount >= 10000) {
      return '月销${(salesCount / 10000).toStringAsFixed(1)}万+';
    } else if (salesCount >= 1000) {
      return '月销${(salesCount / 1000).toStringAsFixed(1)}k+';
    } else {
      return '月销$salesCount';
    }
  }

  /// 获取评分文本
  String get ratingText {
    if (rating == 0.0) return '';
    return rating.toStringAsFixed(1);
  }

  /// 获取状态标签
  List<String> get statusTags {
    final tags = <String>[];
    if (isNew) tags.add('新品');
    if (isHot) tags.add('热销');
    if (isRecommended) tags.add('推荐');
    if (hasDiscount) tags.add('特价');
    if (!isAvailable) tags.add('售罄');
    return tags;
  }

  /// 转换为基础Food对象
  Food toFood() {
    return Food(
      id: id,
      name: name,
      description: description,
      cuisineType: cuisineType,
      tasteAttributes: tasteAttributes,
      ingredients: ingredients,
      scenarios: scenarios,
      calories: calories,
      rating: rating,
      ratingCount: ratingCount,
      imageUrl: imageUrl,
      nutritionFacts: nutritionFacts,
      price: currentPrice,
      restaurant: restaurant,
      isFavorite: isFavorite,
    );
  }

  @override
  FoodItem copyWith({
    String? id,
    String? name,
    String? description,
    String? cuisineType,
    List<String>? tasteAttributes,
    List<String>? ingredients,
    List<String>? scenarios,
    double? calories,
    double? rating,
    int? ratingCount,
    String? imageUrl,
    Map<String, dynamic>? nutritionFacts,
    double? price,
    String? restaurant,
    bool? isFavorite,
    int? preparationTime,
    String? difficulty,
    List<String>? tags,
    String? emoji,
    double? score,
  }) {
    return FoodItem(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      cuisineType: cuisineType ?? this.cuisineType,
      tasteAttributes: tasteAttributes ?? this.tasteAttributes,
      ingredients: ingredients ?? this.ingredients,
      scenarios: scenarios ?? this.scenarios,
      calories: calories ?? this.calories,
      rating: rating ?? this.rating,
      ratingCount: ratingCount ?? this.ratingCount,
      imageUrl: imageUrl ?? this.imageUrl,
      nutritionFacts: nutritionFacts ?? this.nutritionFacts,
      price: price ?? this.price,
      restaurant: restaurant ?? this.restaurant,
      isFavorite: isFavorite ?? this.isFavorite,
      emoji: emoji ?? this.emoji,
      score: score ?? this.score,
      tags: tags ?? this.tags,
      restaurantId: restaurantId,
      categoryId: categoryId,
      categoryName: categoryName,
      originalPrice: originalPrice,
      discountPrice: discountPrice,
      isAvailable: isAvailable,
      stock: stock,
      salesCount: salesCount,
      specs: specs,
      allergens: allergens,
      platform: platform,
      platformItemId: platformItemId,
      isRecommended: isRecommended,
      isNew: isNew,
      isHot: isHot,
      preparationTime: preparationTime ?? this.preparationTime,
      platformData: platformData,
    );
  }

  /// 复制FoodItem并修改外卖特有属性
  FoodItem copyWithFoodItem({
    String? restaurantId,
    String? categoryId,
    String? categoryName,
    double? originalPrice,
    double? discountPrice,
    bool? isAvailable,
    int? stock,
    int? salesCount,
    List<FoodSpec>? specs,
    List<String>? allergens,
    FoodItemPlatform? platform,
    String? platformItemId,
    bool? isRecommended,
    bool? isNew,
    bool? isHot,
    Map<String, dynamic>? platformData,
  }) {
    return FoodItem(
      id: id,
      name: name,
      description: description,
      cuisineType: cuisineType,
      tasteAttributes: tasteAttributes,
      ingredients: ingredients,
      scenarios: scenarios,
      calories: calories,
      rating: rating,
      ratingCount: ratingCount,
      imageUrl: imageUrl,
      nutritionFacts: nutritionFacts,
      price: price,
      restaurant: restaurant,
      isFavorite: isFavorite,
      restaurantId: restaurantId ?? this.restaurantId,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      originalPrice: originalPrice ?? this.originalPrice,
      discountPrice: discountPrice ?? this.discountPrice,
      isAvailable: isAvailable ?? this.isAvailable,
      stock: stock ?? this.stock,
      salesCount: salesCount ?? this.salesCount,
      specs: specs ?? this.specs,
      allergens: allergens ?? this.allergens,
      platform: platform ?? this.platform,
      platformItemId: platformItemId ?? this.platformItemId,
      isRecommended: isRecommended ?? this.isRecommended,
      isNew: isNew ?? this.isNew,
      isHot: isHot ?? this.isHot,
      preparationTime: preparationTime,
      platformData: platformData ?? this.platformData,
    );
  }

  @override
  String toString() {
    return 'FoodItem(id: $id, name: $name, platform: $platform, price: ¥$currentPrice)';
  }

  /// 转换为JSON
  @override
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'cuisineType': cuisineType,
      'tasteAttributes': tasteAttributes,
      'ingredients': ingredients,
      'scenarios': scenarios,
      'calories': calories,
      'rating': rating,
      'ratingCount': ratingCount,
      'imageUrl': imageUrl,
      'nutritionFacts': nutritionFacts,
      'price': price,
      'restaurant': restaurant,
      'isFavorite': isFavorite,
      'restaurantId': restaurantId,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'originalPrice': originalPrice,
      'discountPrice': discountPrice,
      'isAvailable': isAvailable,
      'stock': stock,
      'salesCount': salesCount,
      'specs': specs.map((spec) => spec.toJson()).toList(),
      'allergens': allergens,
      'platform': platform.name,
      'platformItemId': platformItemId,
      'isRecommended': isRecommended,
      'isNew': isNew,
      'isHot': isHot,
      'preparationTime': preparationTime,
      'platformData': platformData,
    };
  }

  /// 从JSON创建FoodItem对象
  factory FoodItem.fromJson(Map<String, dynamic> json) {
    final specs = <FoodSpec>[];
    if (json['specs'] != null) {
      for (final spec in json['specs']) {
        specs.add(FoodSpec.fromJson(Map<String, dynamic>.from(spec)));
      }
    }

    return FoodItem(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'],
      cuisineType: json['cuisineType'] ?? '其他',
      tasteAttributes: List<String>.from(json['tasteAttributes'] ?? []),
      ingredients: List<String>.from(json['ingredients'] ?? []),
      scenarios: json['scenarios'] != null ? List<String>.from(json['scenarios']) : null,
      calories: json['calories'],
      rating: (json['rating'] ?? 0.0).toDouble(),
      ratingCount: json['ratingCount'] ?? 0,
      imageUrl: json['imageUrl'],
      nutritionFacts:
          json['nutritionFacts'] != null ? Map<String, double>.from(json['nutritionFacts']) : null,
      price: json['price']?.toDouble(),
      restaurant: json['restaurant'],
      isFavorite: json['isFavorite'] ?? false,
      restaurantId: json['restaurantId'] ?? '',
      categoryId: json['categoryId'],
      categoryName: json['categoryName'],
      originalPrice: (json['originalPrice'] ?? 0.0).toDouble(),
      discountPrice: json['discountPrice']?.toDouble(),
      isAvailable: json['isAvailable'] ?? true,
      stock: json['stock'],
      salesCount: json['salesCount'] ?? 0,
      specs: specs,
      allergens: List<String>.from(json['allergens'] ?? []),
      platform: FoodItemPlatform.values.firstWhere(
        (e) => e.name == (json['platform'] ?? 'unknown'),
        orElse: () => FoodItemPlatform.unknown,
      ),
      platformItemId: json['platformItemId'],
      isRecommended: json['isRecommended'] ?? false,
      isNew: json['isNew'] ?? false,
      isHot: json['isHot'] ?? false,
      preparationTime: json['preparationTime'],
      platformData: json['platformData'],
    );
  }
}

/// 食品规格模型
class FoodSpec {
  final String id;
  final String name;
  final double price;
  final bool isDefault;
  final Map<String, dynamic>? attributes;

  FoodSpec({
    required this.id,
    required this.name,
    required this.price,
    this.isDefault = false,
    this.attributes,
  });

  /// 从美团数据创建
  factory FoodSpec.fromMeiTuanJson(Map<String, dynamic> json) {
    return FoodSpec(
      id: json['sku_id']?.toString() ?? '',
      name: json['sku_name'] ?? '',
      price: _parseDouble(json['price']) ?? 0.0,
      isDefault: json['is_default'] == 1,
      attributes: json,
    );
  }

  /// 从饿了么数据创建
  factory FoodSpec.fromElemeJson(Map<String, dynamic> json) {
    return FoodSpec(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      price: _parseDouble(json['price']) ?? 0.0,
      isDefault: json['is_default'] == true,
      attributes: json,
    );
  }

  /// 从JSON创建FoodSpec对象
  factory FoodSpec.fromJson(Map<String, dynamic> json) {
    return FoodSpec(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      price: (json['price'] ?? 0.0).toDouble(),
      isDefault: json['isDefault'] ?? false,
      attributes: json['attributes'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'isDefault': isDefault,
      'attributes': attributes,
    };
  }
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
