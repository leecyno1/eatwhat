/// 菜谱难度等级
enum RecipeDifficulty {
  easy('简单'),
  medium('中等'),
  hard('困难');

  const RecipeDifficulty(this.label);
  final String label;
}

/// 烹饪方式
enum CookingMethod {
  stirFry('炒'),
  boil('煮'),
  steam('蒸'),
  fry('炸'),
  grill('烤'),
  braise('焖'),
  stew('炖'),
  coldMix('凉拌'),
  bake('烘焙');

  const CookingMethod(this.label);
  final String label;
}

/// 菜谱食材
class RecipeIngredient {
  final String name;
  final String amount;
  final String unit;
  final bool isMain; // 是否为主料
  final String? note; // 备注

  RecipeIngredient({
    required this.name,
    required this.amount,
    required this.unit,
    this.isMain = false,
    this.note,
  });

  Map<String, dynamic> toJson() => {
        'name': name,
        'amount': amount,
        'unit': unit,
        'isMain': isMain,
        'note': note,
      };

  factory RecipeIngredient.fromJson(Map<String, dynamic> json) =>
      RecipeIngredient(
        name: json['name'] ?? '',
        amount: json['amount'] ?? '',
        unit: json['unit'] ?? '',
        isMain: json['isMain'] ?? false,
        note: json['note'],
      );
}

/// 烹饪步骤
class CookingStep {
  final int stepNumber;
  final String description;
  final String? imageUrl;
  final int estimatedTime; // 预计时间（分钟）
  final String? tip; // 小贴士

  CookingStep({
    required this.stepNumber,
    required this.description,
    this.imageUrl,
    this.estimatedTime = 0,
    this.tip,
  });

  Map<String, dynamic> toJson() => {
        'stepNumber': stepNumber,
        'description': description,
        'imageUrl': imageUrl,
        'estimatedTime': estimatedTime,
        'tip': tip,
      };

  factory CookingStep.fromJson(Map<String, dynamic> json) => CookingStep(
        stepNumber: json['stepNumber'] ?? 0,
        description: json['description'] ?? '',
        imageUrl: json['imageUrl'],
        estimatedTime: json['estimatedTime'] ?? 0,
        tip: json['tip'],
      );
}

/// 营养信息
class NutritionInfo {
  final double calories; // 卡路里
  final double protein; // 蛋白质(g)
  final double carbs; // 碳水化合物(g)
  final double fat; // 脂肪(g)
  final double fiber; // 纤维(g)
  final double sodium; // 钠(mg)

  NutritionInfo({
    this.calories = 0.0,
    this.protein = 0.0,
    this.carbs = 0.0,
    this.fat = 0.0,
    this.fiber = 0.0,
    this.sodium = 0.0,
  });

  Map<String, dynamic> toJson() => {
        'calories': calories,
        'protein': protein,
        'carbs': carbs,
        'fat': fat,
        'fiber': fiber,
        'sodium': sodium,
      };

  factory NutritionInfo.fromJson(Map<String, dynamic> json) => NutritionInfo(
        calories: (json['calories'] ?? 0.0).toDouble(),
        protein: (json['protein'] ?? 0.0).toDouble(),
        carbs: (json['carbs'] ?? 0.0).toDouble(),
        fat: (json['fat'] ?? 0.0).toDouble(),
        fiber: (json['fiber'] ?? 0.0).toDouble(),
        sodium: (json['sodium'] ?? 0.0).toDouble(),
      );
}

/// 菜谱模型
class Recipe {
  final String id;
  final String name;
  final String description;
  final String cuisine; // 菜系
  final CookingMethod cookingMethod;
  final RecipeDifficulty difficulty;
  final int preparationTime; // 准备时间（分钟）
  final int cookingTime; // 烹饪时间（分钟）
  final int servings; // 份量
  final String imageUrl;
  final List<String> tags;
  final List<RecipeIngredient> ingredients;
  final List<CookingStep> steps;
  final NutritionInfo nutrition;
  final double rating;
  final int reviewCount;
  final String authorId;
  final String authorName;
  final DateTime createdAt;
  final DateTime updatedAt;
  final bool isFavorite;
  final bool isBookmarked;
  final int viewCount;
  final int likeCount;
  final String? videoUrl; // 视频教程URL
  final List<String>? allergens; // 过敏原信息
  final String? tips; // 制作小贴士

  Recipe({
    required this.id,
    required this.name,
    required this.description,
    required this.cuisine,
    required this.cookingMethod,
    required this.difficulty,
    required this.preparationTime,
    required this.cookingTime,
    required this.servings,
    required this.imageUrl,
    required this.tags,
    required this.ingredients,
    required this.steps,
    required this.nutrition,
    required this.rating,
    required this.reviewCount,
    required this.authorId,
    required this.authorName,
    required this.createdAt,
    required this.updatedAt,
    this.isFavorite = false,
    this.isBookmarked = false,
    this.viewCount = 0,
    this.likeCount = 0,
    this.videoUrl,
    this.allergens,
    this.tips,
  });

  /// 总时间
  int get totalTime => preparationTime + cookingTime;

  /// 是否为素食
  bool get isVegetarian {
    final meatKeywords = ['肉', '鸡', '鸭', '鱼', '虾', '蟹', '牛', '猪', '羊'];
    return !ingredients.any((ingredient) =>
        meatKeywords.any((keyword) => ingredient.name.contains(keyword)));
  }

  /// 是否为快手菜
  bool get isQuickDish => totalTime <= 30;

  Recipe copyWith({
    String? id,
    String? name,
    String? description,
    String? cuisine,
    CookingMethod? cookingMethod,
    RecipeDifficulty? difficulty,
    int? preparationTime,
    int? cookingTime,
    int? servings,
    String? imageUrl,
    List<String>? tags,
    List<RecipeIngredient>? ingredients,
    List<CookingStep>? steps,
    NutritionInfo? nutrition,
    double? rating,
    int? reviewCount,
    String? authorId,
    String? authorName,
    DateTime? createdAt,
    DateTime? updatedAt,
    bool? isFavorite,
    bool? isBookmarked,
    int? viewCount,
    int? likeCount,
    String? videoUrl,
    List<String>? allergens,
    String? tips,
  }) {
    return Recipe(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      cuisine: cuisine ?? this.cuisine,
      cookingMethod: cookingMethod ?? this.cookingMethod,
      difficulty: difficulty ?? this.difficulty,
      preparationTime: preparationTime ?? this.preparationTime,
      cookingTime: cookingTime ?? this.cookingTime,
      servings: servings ?? this.servings,
      imageUrl: imageUrl ?? this.imageUrl,
      tags: tags ?? this.tags,
      ingredients: ingredients ?? this.ingredients,
      steps: steps ?? this.steps,
      nutrition: nutrition ?? this.nutrition,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      authorId: authorId ?? this.authorId,
      authorName: authorName ?? this.authorName,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      isFavorite: isFavorite ?? this.isFavorite,
      isBookmarked: isBookmarked ?? this.isBookmarked,
      viewCount: viewCount ?? this.viewCount,
      likeCount: likeCount ?? this.likeCount,
      videoUrl: videoUrl ?? this.videoUrl,
      allergens: allergens ?? this.allergens,
      tips: tips ?? this.tips,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'cuisine': cuisine,
        'cookingMethod': cookingMethod.name,
        'difficulty': difficulty.name,
        'preparationTime': preparationTime,
        'cookingTime': cookingTime,
        'servings': servings,
        'imageUrl': imageUrl,
        'tags': tags,
        'ingredients': ingredients.map((i) => i.toJson()).toList(),
        'steps': steps.map((s) => s.toJson()).toList(),
        'nutrition': nutrition.toJson(),
        'rating': rating,
        'reviewCount': reviewCount,
        'authorId': authorId,
        'authorName': authorName,
        'createdAt': createdAt.toIso8601String(),
        'updatedAt': updatedAt.toIso8601String(),
        'isFavorite': isFavorite,
        'isBookmarked': isBookmarked,
        'viewCount': viewCount,
        'likeCount': likeCount,
        'videoUrl': videoUrl,
        'allergens': allergens,
        'tips': tips,
      };

  factory Recipe.fromJson(Map<String, dynamic> json) {
    return Recipe(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      cuisine: json['cuisine'] ?? '',
      cookingMethod: CookingMethod.values.firstWhere(
        (method) => method.name == json['cookingMethod'],
        orElse: () => CookingMethod.stirFry,
      ),
      difficulty: RecipeDifficulty.values.firstWhere(
        (diff) => diff.name == json['difficulty'],
        orElse: () => RecipeDifficulty.medium,
      ),
      preparationTime: json['preparationTime'] ?? 0,
      cookingTime: json['cookingTime'] ?? 0,
      servings: json['servings'] ?? 2,
      imageUrl: json['imageUrl'] ?? '',
      tags: List<String>.from(json['tags'] ?? []),
      ingredients: (json['ingredients'] as List? ?? [])
          .map((i) => RecipeIngredient.fromJson(i))
          .toList(),
      steps: (json['steps'] as List? ?? [])
          .map((s) => CookingStep.fromJson(s))
          .toList(),
      nutrition: NutritionInfo.fromJson(json['nutrition'] ?? {}),
      rating: (json['rating'] ?? 0.0).toDouble(),
      reviewCount: json['reviewCount'] ?? 0,
      authorId: json['authorId'] ?? '',
      authorName: json['authorName'] ?? '',
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      updatedAt: DateTime.tryParse(json['updatedAt'] ?? '') ?? DateTime.now(),
      isFavorite: json['isFavorite'] ?? false,
      isBookmarked: json['isBookmarked'] ?? false,
      viewCount: json['viewCount'] ?? 0,
      likeCount: json['likeCount'] ?? 0,
      videoUrl: json['videoUrl'],
      allergens: json['allergens'] != null
          ? List<String>.from(json['allergens'])
          : null,
      tips: json['tips'],
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Recipe && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'Recipe(id: $id, name: $name)';
}
