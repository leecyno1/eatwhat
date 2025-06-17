/// 食物模型
class Food {
  final String id;
  final String name;
  final String? description;
  final String cuisineType;
  final List<String> tasteAttributes;
  final List<String> ingredients;
  final List<String>? scenarios;
  final int? calories;
  final double rating;
  final int ratingCount;
  final String? imageUrl;
  final Map<String, double>? nutritionFacts;
  final double? price;
  final String? restaurant;
  final bool isFavorite;

  Food({
    String? id,
    required this.name,
    this.description,
    required this.cuisineType,
    this.tasteAttributes = const [],
    this.ingredients = const [],
    this.scenarios,
    this.calories,
    this.rating = 0.0,
    this.ratingCount = 0,
    this.imageUrl,
    this.nutritionFacts,
    this.price,
    this.restaurant,
    this.isFavorite = false,
  }) : id = id ?? DateTime.now().millisecondsSinceEpoch.toString();

  /// 复制食物并修改部分属性
  Food copyWith({
    String? id,
    String? name,
    String? description,
    String? cuisineType,
    List<String>? tasteAttributes,
    List<String>? ingredients,
    List<String>? scenarios,
    int? calories,
    double? rating,
    int? ratingCount,
    String? imageUrl,
    Map<String, double>? nutritionFacts,
    double? price,
    String? restaurant,
    bool? isFavorite,
  }) {
    return Food(
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
    );
  }

  /// 转换为JSON
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
    };
  }

  /// 从JSON创建食物
  factory Food.fromJson(Map<String, dynamic> json) {
    return Food(
      id: json['id'],
      name: json['name'],
      description: json['description'],
      cuisineType: json['cuisineType'],
      tasteAttributes: List<String>.from(json['tasteAttributes'] ?? []),
      ingredients: List<String>.from(json['ingredients'] ?? []),
      scenarios: json['scenarios'] != null 
          ? List<String>.from(json['scenarios']) 
          : null,
      calories: json['calories'],
      rating: json['rating']?.toDouble() ?? 0.0,
      ratingCount: json['ratingCount'] ?? 0,
      imageUrl: json['imageUrl'],
      nutritionFacts: json['nutritionFacts'] != null
          ? Map<String, double>.from(json['nutritionFacts'])
          : null,
      price: json['price']?.toDouble(),
      restaurant: json['restaurant'],
      isFavorite: json['isFavorite'] ?? false,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Food && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Food(id: $id, name: $name, cuisineType: $cuisineType, rating: $rating)';
  }
} 