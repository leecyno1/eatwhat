import 'package:flutter/material.dart';

/// 食物模型
class Food {
  final String id;
  final String name;
  final String? description;
  final String? imageUrl;
  final List<String> tags;
  final double rating;
  final bool isFavorite;

  // 新增属性
  final String? cuisineType;
  final List<String>? tasteAttributes;
  final String? emoji;
  final double? score;
  final List<String>? ingredients;
  final int? ratingCount;
  final double? price;
  final double? calories;
  final String? restaurant;
  final List<String>? scenarios;
  final String? difficulty;
  final Map<String, dynamic>? nutritionFacts;
  final int? preparationTime; // 准备时间（分钟）

  const Food({
    required this.id,
    required this.name,
    this.description,
    this.imageUrl,
    this.tags = const [],
    this.rating = 0.0,
    this.isFavorite = false,
    this.cuisineType,
    this.tasteAttributes,
    this.emoji,
    this.score,
    this.ingredients,
    this.ratingCount,
    this.price,
    this.calories,
    this.restaurant,
    this.scenarios,
    this.difficulty,
    this.nutritionFacts,
    this.preparationTime,
  });

  /// 复制食物并修改部分属性
  Food copyWith({
    String? id,
    String? name,
    String? description,
    String? imageUrl,
    List<String>? tags,
    double? rating,
    bool? isFavorite,
    String? cuisineType,
    List<String>? tasteAttributes,
    String? emoji,
    double? score,
    List<String>? ingredients,
    int? ratingCount,
    double? price,
    double? calories,
    String? restaurant,
    List<String>? scenarios,
    String? difficulty,
    Map<String, dynamic>? nutritionFacts,
    int? preparationTime,
  }) {
    return Food(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      tags: tags ?? this.tags,
      rating: rating ?? this.rating,
      isFavorite: isFavorite ?? this.isFavorite,
      cuisineType: cuisineType ?? this.cuisineType,
      tasteAttributes: tasteAttributes ?? this.tasteAttributes,
      emoji: emoji ?? this.emoji,
      score: score ?? this.score,
      ingredients: ingredients ?? this.ingredients,
      ratingCount: ratingCount ?? this.ratingCount,
      price: price ?? this.price,
      calories: calories ?? this.calories,
      restaurant: restaurant ?? this.restaurant,
      scenarios: scenarios ?? this.scenarios,
      difficulty: difficulty ?? this.difficulty,
      nutritionFacts: nutritionFacts ?? this.nutritionFacts,
      preparationTime: preparationTime ?? this.preparationTime,
    );
  }

  /// 从JSON创建食物
  factory Food.fromJson(Map<String, dynamic> json) {
    return Food(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String?,
      imageUrl: json['imageUrl'] as String?,
      tags: List<String>.from(json['tags'] ?? []),
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      isFavorite: json['isFavorite'] as bool? ?? false,
      cuisineType: json['cuisineType'] as String?,
      tasteAttributes: List<String>.from(json['tasteAttributes'] ?? []),
      emoji: json['emoji'] as String?,
      score: (json['score'] as num?)?.toDouble(),
      ingredients: List<String>.from(json['ingredients'] ?? []),
      ratingCount: json['ratingCount'] as int?,
      price: (json['price'] as num?)?.toDouble(),
      calories: (json['calories'] as num?)?.toDouble(),
      restaurant: json['restaurant'] as String?,
      scenarios: List<String>.from(json['scenarios'] ?? []),
      difficulty: json['difficulty'] as String?,
      nutritionFacts: json['nutritionFacts'] as Map<String, dynamic>?,
      preparationTime: json['preparationTime'] as int?,
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'imageUrl': imageUrl,
      'tags': tags,
      'rating': rating,
      'isFavorite': isFavorite,
      'cuisineType': cuisineType,
      'tasteAttributes': tasteAttributes,
      'emoji': emoji,
      'score': score,
      'ingredients': ingredients,
      'ratingCount': ratingCount,
      'price': price,
      'calories': calories,
      'restaurant': restaurant,
      'scenarios': scenarios,
      'difficulty': difficulty,
      'nutritionFacts': nutritionFacts,
      'preparationTime': preparationTime,
    };
  }
}
