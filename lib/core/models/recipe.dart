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

  factory RecipeIngredient.fromJson(Map<String, dynamic> json) => RecipeIngredient(
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

/// 季节性信息
class SeasonalInfo {
  final List<String> bestSeasons; // 最佳季节：['春', '夏', '秋', '冬']
  final List<String> seasonalIngredients; // 时令食材
  final double seasonalScore; // 季节相关度评分 (0-1)

  SeasonalInfo({
    this.bestSeasons = const [],
    this.seasonalIngredients = const [],
    this.seasonalScore = 0.5,
  });

  Map<String, dynamic> toJson() => {
        'bestSeasons': bestSeasons,
        'seasonalIngredients': seasonalIngredients,
        'seasonalScore': seasonalScore,
      };

  factory SeasonalInfo.fromJson(Map<String, dynamic> json) => SeasonalInfo(
        bestSeasons: List<String>.from(json['bestSeasons'] ?? []),
        seasonalIngredients: List<String>.from(json['seasonalIngredients'] ?? []),
        seasonalScore: (json['seasonalScore'] ?? 0.5).toDouble(),
      );
}

/// 所需厨具
class CookingEquipment {
  final List<String> required; // 必需厨具
  final List<String> optional; // 可选厨具
  final String difficultyLevel; // 厨具要求难度

  CookingEquipment({
    this.required = const [],
    this.optional = const [],
    this.difficultyLevel = '基础',
  });

  Map<String, dynamic> toJson() => {
        'required': required,
        'optional': optional,
        'difficultyLevel': difficultyLevel,
      };

  factory CookingEquipment.fromJson(Map<String, dynamic> json) => CookingEquipment(
        required: List<String>.from(json['required'] ?? []),
        optional: List<String>.from(json['optional'] ?? []),
        difficultyLevel: json['difficultyLevel'] ?? '基础',
      );
}

/// 用户评论
class Review {
  final String id;
  final String userId;
  final String userName;
  final double rating;
  final String content;
  final DateTime createdAt;
  final List<String> images; // 用户上传的图片
  final int likeCount;
  final bool isVerified; // 是否为认证评论

  Review({
    required this.id,
    required this.userId,
    required this.userName,
    required this.rating,
    required this.content,
    required this.createdAt,
    this.images = const [],
    this.likeCount = 0,
    this.isVerified = false,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'userId': userId,
        'userName': userName,
        'rating': rating,
        'content': content,
        'createdAt': createdAt.toIso8601String(),
        'images': images,
        'likeCount': likeCount,
        'isVerified': isVerified,
      };

  factory Review.fromJson(Map<String, dynamic> json) => Review(
        id: json['id'] ?? '',
        userId: json['userId'] ?? '',
        userName: json['userName'] ?? '',
        rating: (json['rating'] ?? 0.0).toDouble(),
        content: json['content'] ?? '',
        createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
        images: List<String>.from(json['images'] ?? []),
        likeCount: json['likeCount'] ?? 0,
        isVerified: json['isVerified'] ?? false,
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
  final double sugar; // 糖分(g)
  final double cholesterol; // 胆固醇(mg)
  final double calcium; // 钙(mg)
  final double iron; // 铁(mg)
  final double vitaminC; // 维生素C(mg)

  NutritionInfo({
    this.calories = 0.0,
    this.protein = 0.0,
    this.carbs = 0.0,
    this.fat = 0.0,
    this.fiber = 0.0,
    this.sodium = 0.0,
    this.sugar = 0.0,
    this.cholesterol = 0.0,
    this.calcium = 0.0,
    this.iron = 0.0,
    this.vitaminC = 0.0,
  });

  Map<String, dynamic> toJson() => {
        'calories': calories,
        'protein': protein,
        'carbs': carbs,
        'fat': fat,
        'fiber': fiber,
        'sodium': sodium,
        'sugar': sugar,
        'cholesterol': cholesterol,
        'calcium': calcium,
        'iron': iron,
        'vitaminC': vitaminC,
      };

  factory NutritionInfo.fromJson(Map<String, dynamic> json) => NutritionInfo(
        calories: (json['calories'] ?? 0.0).toDouble(),
        protein: (json['protein'] ?? 0.0).toDouble(),
        carbs: (json['carbs'] ?? 0.0).toDouble(),
        fat: (json['fat'] ?? 0.0).toDouble(),
        fiber: (json['fiber'] ?? 0.0).toDouble(),
        sodium: (json['sodium'] ?? 0.0).toDouble(),
        sugar: (json['sugar'] ?? 0.0).toDouble(),
        cholesterol: (json['cholesterol'] ?? 0.0).toDouble(),
        calcium: (json['calcium'] ?? 0.0).toDouble(),
        iron: (json['iron'] ?? 0.0).toDouble(),
        vitaminC: (json['vitaminC'] ?? 0.0).toDouble(),
      );

  /// 健康评分 (0-10)
  double get healthScore {
    double score = 5.0; // 基础分数

    // 高纤维加分
    if (fiber > 5) score += 1.0;
    if (fiber > 10) score += 0.5;

    // 高蛋白加分
    if (protein > 20) score += 1.0;
    if (protein > 30) score += 0.5;

    // 高钠扣分
    if (sodium > 1000) score -= 1.0;
    if (sodium > 2000) score -= 1.5;

    // 高糖扣分
    if (sugar > 20) score -= 1.0;
    if (sugar > 40) score -= 1.5;

    // 高胆固醇扣分
    if (cholesterol > 200) score -= 1.0;
    if (cholesterol > 300) score -= 1.5;

    return score.clamp(0.0, 10.0);
  }
}

/// 菜谱模型 - Phase 2 增强版
/// 对齐下厨房颗粒度，添加口味画像、场景标签等详细字段
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

  // Phase 2 新增字段 - 对齐下厨房标准
  final List<String> tasteProfile; // 口味画像：['甜', '辣', '鲜', '香']
  final List<String> scenarioTags; // 场景标签：['下饭菜', '宵夜', '聚餐', '减脂']
  final List<String> healthBenefits; // 健康功效：['补血', '暖胃', '美容']
  final SeasonalInfo seasonalInfo; // 季节性信息
  final CookingEquipment equipment; // 所需厨具
  final List<Review> reviews; // 用户评论
  final Map<String, double> tasteIntensity; // 口味强度：{'辣度': 0.8, '甜度': 0.3}
  final String spiceLevel; // 辣度等级：'不辣', '微辣', '中辣', '重辣'
  final String? origin; // 菜品起源地
  final bool isAuthentic; // 是否为正宗做法
  final List<String> cookingTechniques; // 烹饪技巧：['腌制', '爆炒', '焖煮']
  final Map<String, String> ingredientSubstitutes; // 食材替代：{'生抽': '老抽+糖'}
  final double costEstimate; // 成本估算（元）
  final List<String> mealTypes; // 餐类：['早餐', '午餐', '晚餐', '夜宵']

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
    // Phase 2 新增参数
    this.tasteProfile = const [],
    this.scenarioTags = const [],
    this.healthBenefits = const [],
    required this.seasonalInfo,
    required this.equipment,
    this.reviews = const [],
    this.tasteIntensity = const {},
    this.spiceLevel = '不辣',
    this.origin,
    this.isAuthentic = true,
    this.cookingTechniques = const [],
    this.ingredientSubstitutes = const {},
    this.costEstimate = 0.0,
    this.mealTypes = const [],
  });

  /// 总时间
  int get totalTime => preparationTime + cookingTime;

  /// 是否为素食
  bool get isVegetarian {
    final meatKeywords = ['肉', '鸡', '鸭', '鱼', '虾', '蟹', '牛', '猪', '羊'];
    return !ingredients
        .any((ingredient) => meatKeywords.any((keyword) => ingredient.name.contains(keyword)));
  }

  /// 是否为快手菜
  bool get isQuickDish => totalTime <= 30;

  // Phase 2 新增 getter 方法

  /// 辣度等级数值 (0-4)
  int get spiceLevelNumber {
    switch (spiceLevel) {
      case '不辣':
        return 0;
      case '微辣':
        return 1;
      case '中辣':
        return 2;
      case '重辣':
        return 3;
      case '特辣':
        return 4;
      default:
        return 0;
    }
  }

  /// 是否为健康菜品
  bool get isHealthy => nutrition.healthScore >= 7.0;

  /// 是否为低卡菜品
  bool get isLowCalorie => nutrition.calories < 300;

  /// 是否为高蛋白菜品
  bool get isHighProtein => nutrition.protein > 20;

  /// 获取主要口味标签
  List<String> get primaryTasteAttributes {
    final intensityThreshold = 0.5;
    return tasteIntensity.entries
        .where((entry) => entry.value > intensityThreshold)
        .map((entry) => entry.key)
        .toList();
  }

  /// 是否适合当前季节
  bool get isSeasonallyAppropriate {
    final now = DateTime.now();
    final currentSeason = _getCurrentSeason(now);
    return seasonalInfo.bestSeasons.contains(currentSeason);
  }

  /// 获取当前季节
  String _getCurrentSeason(DateTime date) {
    final month = date.month;
    if (month >= 3 && month <= 5) return '春';
    if (month >= 6 && month <= 8) return '夏';
    if (month >= 9 && month <= 11) return '秋';
    return '冬';
  }

  /// 获取难度星级 (1-5星)
  int get difficultyStars {
    switch (difficulty) {
      case RecipeDifficulty.easy:
        return 1;
      case RecipeDifficulty.medium:
        return 3;
      case RecipeDifficulty.hard:
        return 5;
    }
  }

  /// 获取成本等级描述
  String get costLevel {
    if (costEstimate <= 10) return '经济实惠';
    if (costEstimate <= 30) return '中等成本';
    if (costEstimate <= 50) return '价格较高';
    return '成本较高';
  }

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
    // Phase 2 新增参数
    List<String>? tasteProfile,
    List<String>? scenarioTags,
    List<String>? healthBenefits,
    SeasonalInfo? seasonalInfo,
    CookingEquipment? equipment,
    List<Review>? reviews,
    Map<String, double>? tasteIntensity,
    String? spiceLevel,
    String? origin,
    bool? isAuthentic,
    List<String>? cookingTechniques,
    Map<String, String>? ingredientSubstitutes,
    double? costEstimate,
    List<String>? mealTypes,
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
      // Phase 2 新增字段
      tasteProfile: tasteProfile ?? this.tasteProfile,
      scenarioTags: scenarioTags ?? this.scenarioTags,
      healthBenefits: healthBenefits ?? this.healthBenefits,
      seasonalInfo: seasonalInfo ?? this.seasonalInfo,
      equipment: equipment ?? this.equipment,
      reviews: reviews ?? this.reviews,
      tasteIntensity: tasteIntensity ?? this.tasteIntensity,
      spiceLevel: spiceLevel ?? this.spiceLevel,
      origin: origin ?? this.origin,
      isAuthentic: isAuthentic ?? this.isAuthentic,
      cookingTechniques: cookingTechniques ?? this.cookingTechniques,
      ingredientSubstitutes: ingredientSubstitutes ?? this.ingredientSubstitutes,
      costEstimate: costEstimate ?? this.costEstimate,
      mealTypes: mealTypes ?? this.mealTypes,
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
        // Phase 2 新增字段
        'tasteProfile': tasteProfile,
        'scenarioTags': scenarioTags,
        'healthBenefits': healthBenefits,
        'seasonalInfo': seasonalInfo.toJson(),
        'equipment': equipment.toJson(),
        'reviews': reviews.map((r) => r.toJson()).toList(),
        'tasteIntensity': tasteIntensity,
        'spiceLevel': spiceLevel,
        'origin': origin,
        'isAuthentic': isAuthentic,
        'cookingTechniques': cookingTechniques,
        'ingredientSubstitutes': ingredientSubstitutes,
        'costEstimate': costEstimate,
        'mealTypes': mealTypes,
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
      ingredients:
          (json['ingredients'] as List? ?? []).map((i) => RecipeIngredient.fromJson(i)).toList(),
      steps: (json['steps'] as List? ?? []).map((s) => CookingStep.fromJson(s)).toList(),
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
      allergens: json['allergens'] != null ? List<String>.from(json['allergens']) : null,
      tips: json['tips'],
      // Phase 2 新增字段
      tasteProfile: List<String>.from(json['tasteProfile'] ?? []),
      scenarioTags: List<String>.from(json['scenarioTags'] ?? []),
      healthBenefits: List<String>.from(json['healthBenefits'] ?? []),
      seasonalInfo: json['seasonalInfo'] != null
          ? SeasonalInfo.fromJson(json['seasonalInfo'])
          : SeasonalInfo(),
      equipment: json['equipment'] != null
          ? CookingEquipment.fromJson(json['equipment'])
          : CookingEquipment(),
      reviews: (json['reviews'] as List? ?? []).map((r) => Review.fromJson(r)).toList(),
      tasteIntensity: Map<String, double>.from(json['tasteIntensity'] ?? {}),
      spiceLevel: json['spiceLevel'] ?? '不辣',
      origin: json['origin'],
      isAuthentic: json['isAuthentic'] ?? true,
      cookingTechniques: List<String>.from(json['cookingTechniques'] ?? []),
      ingredientSubstitutes: Map<String, String>.from(json['ingredientSubstitutes'] ?? {}),
      costEstimate: (json['costEstimate'] ?? 0.0).toDouble(),
      mealTypes: List<String>.from(json['mealTypes'] ?? []),
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
