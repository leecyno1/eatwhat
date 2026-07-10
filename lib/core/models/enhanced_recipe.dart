import 'dart:convert';
import 'package:flutter/foundation.dart';
import '../utils/advanced_logger.dart';
import '../error/global_error_handler.dart';

/// 增强的菜谱数据模型 - 基于下厨房结构分析
class EnhancedRecipe {
  /// 基础信息
  final String id;
  final String name;
  final String description;
  final String? author;
  final String? authorAvatar;
  final DateTime? createTime;
  final DateTime? updateTime;

  /// 评价和互动
  final double rating; // 评分 (0-5)
  final int reviewCount; // 评论数
  final int favoriteCount; // 收藏数
  final int makeCount; // 制作次数 ("XX人做过")
  final int viewCount; // 浏览次数

  /// 分类信息 - 基于下厨房分类体系
  final RecipeCategory category;
  final List<String> tags; // 标签：家常菜、快手菜等
  final List<String> occasions; // 场合：早餐、下午茶等
  final List<String> effects; // 功效：减肥、美容等
  final List<String> crowds; // 人群：儿童、老人等
  final String? cuisineType; // 菜系：川菜、粤菜等

  /// 制作信息
  final RecipeDifficulty difficulty;
  final Duration prepTime; // 准备时间
  final Duration cookTime; // 烹饪时间
  final Duration totalTime; // 总时间
  final int servings; // 份数
  final String? equipment; // 所需设备
  final List<String> methods; // 烹饪方法：煎、炒、炸等

  /// 食材信息
  final List<RecipeIngredient> ingredients;
  final List<RecipeIngredient>? seasonings; // 调料单独列出

  /// 制作步骤
  final List<RecipeStep> steps;

  /// 营养信息
  final RecipeNutrition nutrition;

  /// 口味特征 - AI推荐用
  final List<String> tasteAttributes; // 辣、甜、酸等
  final double spiceLevel; // 辣度等级 (0-5)
  final List<String> allergens; // 过敏源信息

  /// 媒体资源
  final String? coverImage;
  final List<String> images;
  final String? video;

  /// 提示和技巧
  final List<RecipeTip>? tips;
  final String? notes; // 小贴士

  /// 相关推荐
  final List<String>? relatedRecipeIds;
  final List<String>? substitutions; // 食材替换建议

  /// 来源信息
  final RecipeSource source;
  final String? originalUrl;

  /// 质量控制
  final bool isVerified; // 是否经过验证
  final RecipeStatus status;
  final Map<String, dynamic>? metadata; // 额外元数据

  const EnhancedRecipe({
    required this.id,
    required this.name,
    required this.description,
    this.author,
    this.authorAvatar,
    this.createTime,
    this.updateTime,
    required this.rating,
    required this.reviewCount,
    required this.favoriteCount,
    required this.makeCount,
    this.viewCount = 0,
    required this.category,
    required this.tags,
    this.occasions = const [],
    this.effects = const [],
    this.crowds = const [],
    this.cuisineType,
    required this.difficulty,
    required this.prepTime,
    required this.cookTime,
    required this.totalTime,
    required this.servings,
    this.equipment,
    this.methods = const [],
    required this.ingredients,
    this.seasonings,
    required this.steps,
    required this.nutrition,
    this.tasteAttributes = const [],
    this.spiceLevel = 0,
    this.allergens = const [],
    this.coverImage,
    this.images = const [],
    this.video,
    this.tips,
    this.notes,
    this.relatedRecipeIds,
    this.substitutions,
    required this.source,
    this.originalUrl,
    this.isVerified = false,
    this.status = RecipeStatus.active,
    this.metadata,
  });

  /// 工厂构造函数 - 从下厨房数据创建
  factory EnhancedRecipe.fromXiachufangData(Map<String, dynamic> data) {
    try {
      return EnhancedRecipe(
        id: data['id']?.toString() ?? '',
        name: data['name'] ?? '',
        description: data['description'] ?? '',
        author: data['author']?['name'],
        authorAvatar: data['author']?['avatar'],
        createTime:
            data['create_time'] != null ? DateTime.tryParse(data['create_time'].toString()) : null,
        updateTime:
            data['update_time'] != null ? DateTime.tryParse(data['update_time'].toString()) : null,
        rating: (data['rating'] ?? 0.0).toDouble(),
        reviewCount: data['review_count'] ?? 0,
        favoriteCount: data['favorite_count'] ?? 0,
        makeCount: data['make_count'] ?? 0,
        viewCount: data['view_count'] ?? 0,
        category: _parseCategory(data['category']),
        tags: List<String>.from(data['tags'] ?? []),
        occasions: List<String>.from(data['occasions'] ?? []),
        effects: List<String>.from(data['effects'] ?? []),
        crowds: List<String>.from(data['crowds'] ?? []),
        cuisineType: data['cuisine_type'],
        difficulty: _parseDifficulty(data['difficulty']),
        prepTime: Duration(minutes: data['prep_time'] ?? 0),
        cookTime: Duration(minutes: data['cook_time'] ?? 0),
        totalTime: Duration(minutes: data['total_time'] ?? 0),
        servings: data['servings'] ?? 1,
        equipment: data['equipment'],
        methods: List<String>.from(data['methods'] ?? []),
        ingredients:
            (data['ingredients'] as List?)?.map((i) => RecipeIngredient.fromMap(i)).toList() ?? [],
        seasonings: (data['seasonings'] as List?)?.map((s) => RecipeIngredient.fromMap(s)).toList(),
        steps: (data['steps'] as List?)?.map((s) => RecipeStep.fromMap(s)).toList() ?? [],
        nutrition: RecipeNutrition.fromMap(data['nutrition'] ?? {}),
        tasteAttributes: List<String>.from(data['taste_attributes'] ?? []),
        spiceLevel: (data['spice_level'] ?? 0.0).toDouble(),
        allergens: List<String>.from(data['allergens'] ?? []),
        coverImage: data['cover_image'],
        images: List<String>.from(data['images'] ?? []),
        video: data['video'],
        tips: (data['tips'] as List?)?.map((t) => RecipeTip.fromMap(t)).toList(),
        notes: data['notes'],
        relatedRecipeIds: List<String>.from(data['related_recipes'] ?? []),
        substitutions: List<String>.from(data['substitutions'] ?? []),
        source: RecipeSource.xiachufang,
        originalUrl: data['original_url'],
        isVerified: data['is_verified'] ?? false,
        status: _parseStatus(data['status']),
        metadata: data['metadata'],
      );
    } catch (e, stackTrace) {
      AdvancedLogger.instance.error(
        'Failed to parse Xiachufang recipe data: $e',
        stackTrace: stackTrace,
        tag: 'EnhancedRecipe',
      );
      rethrow;
    }
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'author': author,
      'author_avatar': authorAvatar,
      'create_time': createTime?.toIso8601String(),
      'update_time': updateTime?.toIso8601String(),
      'rating': rating,
      'review_count': reviewCount,
      'favorite_count': favoriteCount,
      'make_count': makeCount,
      'view_count': viewCount,
      'category': category.name,
      'tags': tags,
      'occasions': occasions,
      'effects': effects,
      'crowds': crowds,
      'cuisine_type': cuisineType,
      'difficulty': difficulty.name,
      'prep_time': prepTime.inMinutes,
      'cook_time': cookTime.inMinutes,
      'total_time': totalTime.inMinutes,
      'servings': servings,
      'equipment': equipment,
      'methods': methods,
      'ingredients': ingredients.map((i) => i.toJson()).toList(),
      'seasonings': seasonings?.map((s) => s.toJson()).toList(),
      'steps': steps.map((s) => s.toJson()).toList(),
      'nutrition': nutrition.toJson(),
      'taste_attributes': tasteAttributes,
      'spice_level': spiceLevel,
      'allergens': allergens,
      'cover_image': coverImage,
      'images': images,
      'video': video,
      'tips': tips?.map((t) => t.toJson()).toList(),
      'notes': notes,
      'related_recipes': relatedRecipeIds,
      'substitutions': substitutions,
      'source': source.name,
      'original_url': originalUrl,
      'is_verified': isVerified,
      'status': status.name,
      'metadata': metadata,
    };
  }

  /// 从JSON创建
  factory EnhancedRecipe.fromJson(Map<String, dynamic> json) {
    return EnhancedRecipe(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      author: json['author'],
      authorAvatar: json['author_avatar'],
      createTime: json['create_time'] != null ? DateTime.tryParse(json['create_time']) : null,
      updateTime: json['update_time'] != null ? DateTime.tryParse(json['update_time']) : null,
      rating: (json['rating'] ?? 0.0).toDouble(),
      reviewCount: json['review_count'] ?? 0,
      favoriteCount: json['favorite_count'] ?? 0,
      makeCount: json['make_count'] ?? 0,
      viewCount: json['view_count'] ?? 0,
      category: _parseCategory(json['category']),
      tags: List<String>.from(json['tags'] ?? []),
      occasions: List<String>.from(json['occasions'] ?? []),
      effects: List<String>.from(json['effects'] ?? []),
      crowds: List<String>.from(json['crowds'] ?? []),
      cuisineType: json['cuisine_type'],
      difficulty: _parseDifficulty(json['difficulty']),
      prepTime: Duration(minutes: json['prep_time'] ?? 0),
      cookTime: Duration(minutes: json['cook_time'] ?? 0),
      totalTime: Duration(minutes: json['total_time'] ?? 0),
      servings: json['servings'] ?? 1,
      equipment: json['equipment'],
      methods: List<String>.from(json['methods'] ?? []),
      ingredients:
          (json['ingredients'] as List?)?.map((i) => RecipeIngredient.fromJson(i)).toList() ?? [],
      seasonings: (json['seasonings'] as List?)?.map((s) => RecipeIngredient.fromJson(s)).toList(),
      steps: (json['steps'] as List?)?.map((s) => RecipeStep.fromJson(s)).toList() ?? [],
      nutrition: RecipeNutrition.fromJson(json['nutrition'] ?? {}),
      tasteAttributes: List<String>.from(json['taste_attributes'] ?? []),
      spiceLevel: (json['spice_level'] ?? 0.0).toDouble(),
      allergens: List<String>.from(json['allergens'] ?? []),
      coverImage: json['cover_image'],
      images: List<String>.from(json['images'] ?? []),
      video: json['video'],
      tips: (json['tips'] as List?)?.map((t) => RecipeTip.fromJson(t)).toList(),
      notes: json['notes'],
      relatedRecipeIds:
          json['related_recipes'] != null ? List<String>.from(json['related_recipes']) : null,
      substitutions:
          json['substitutions'] != null ? List<String>.from(json['substitutions']) : null,
      source: RecipeSource.values.firstWhere(
        (s) => s.name == json['source'],
        orElse: () => RecipeSource.unknown,
      ),
      originalUrl: json['original_url'],
      isVerified: json['is_verified'] ?? false,
      status: RecipeStatus.values.firstWhere(
        (s) => s.name == json['status'],
        orElse: () => RecipeStatus.active,
      ),
      metadata: json['metadata'],
    );
  }

  /// 辅助方法 - 解析分类
  static RecipeCategory _parseCategory(dynamic category) {
    if (category == null) return RecipeCategory.other;

    final categoryName = category.toString().toLowerCase();
    return RecipeCategory.values.firstWhere(
      (c) => c.name.toLowerCase() == categoryName,
      orElse: () => RecipeCategory.other,
    );
  }

  /// 辅助方法 - 解析难度
  static RecipeDifficulty _parseDifficulty(dynamic difficulty) {
    if (difficulty == null) return RecipeDifficulty.medium;

    final difficultyName = difficulty.toString().toLowerCase();
    return RecipeDifficulty.values.firstWhere(
      (d) => d.name.toLowerCase() == difficultyName,
      orElse: () => RecipeDifficulty.medium,
    );
  }

  /// 辅助方法 - 解析状态
  static RecipeStatus _parseStatus(dynamic status) {
    if (status == null) return RecipeStatus.active;

    final statusName = status.toString().toLowerCase();
    return RecipeStatus.values.firstWhere(
      (s) => s.name.toLowerCase() == statusName,
      orElse: () => RecipeStatus.active,
    );
  }

  /// 复制并修改
  EnhancedRecipe copyWith({
    String? id,
    String? name,
    String? description,
    String? author,
    String? authorAvatar,
    DateTime? createTime,
    DateTime? updateTime,
    double? rating,
    int? reviewCount,
    int? favoriteCount,
    int? makeCount,
    int? viewCount,
    RecipeCategory? category,
    List<String>? tags,
    List<String>? occasions,
    List<String>? effects,
    List<String>? crowds,
    String? cuisineType,
    RecipeDifficulty? difficulty,
    Duration? prepTime,
    Duration? cookTime,
    Duration? totalTime,
    int? servings,
    String? equipment,
    List<String>? methods,
    List<RecipeIngredient>? ingredients,
    List<RecipeIngredient>? seasonings,
    List<RecipeStep>? steps,
    RecipeNutrition? nutrition,
    List<String>? tasteAttributes,
    double? spiceLevel,
    List<String>? allergens,
    String? coverImage,
    List<String>? images,
    String? video,
    List<RecipeTip>? tips,
    String? notes,
    List<String>? relatedRecipeIds,
    List<String>? substitutions,
    RecipeSource? source,
    String? originalUrl,
    bool? isVerified,
    RecipeStatus? status,
    Map<String, dynamic>? metadata,
  }) {
    return EnhancedRecipe(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      author: author ?? this.author,
      authorAvatar: authorAvatar ?? this.authorAvatar,
      createTime: createTime ?? this.createTime,
      updateTime: updateTime ?? this.updateTime,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      favoriteCount: favoriteCount ?? this.favoriteCount,
      makeCount: makeCount ?? this.makeCount,
      viewCount: viewCount ?? this.viewCount,
      category: category ?? this.category,
      tags: tags ?? this.tags,
      occasions: occasions ?? this.occasions,
      effects: effects ?? this.effects,
      crowds: crowds ?? this.crowds,
      cuisineType: cuisineType ?? this.cuisineType,
      difficulty: difficulty ?? this.difficulty,
      prepTime: prepTime ?? this.prepTime,
      cookTime: cookTime ?? this.cookTime,
      totalTime: totalTime ?? this.totalTime,
      servings: servings ?? this.servings,
      equipment: equipment ?? this.equipment,
      methods: methods ?? this.methods,
      ingredients: ingredients ?? this.ingredients,
      seasonings: seasonings ?? this.seasonings,
      steps: steps ?? this.steps,
      nutrition: nutrition ?? this.nutrition,
      tasteAttributes: tasteAttributes ?? this.tasteAttributes,
      spiceLevel: spiceLevel ?? this.spiceLevel,
      allergens: allergens ?? this.allergens,
      coverImage: coverImage ?? this.coverImage,
      images: images ?? this.images,
      video: video ?? this.video,
      tips: tips ?? this.tips,
      notes: notes ?? this.notes,
      relatedRecipeIds: relatedRecipeIds ?? this.relatedRecipeIds,
      substitutions: substitutions ?? this.substitutions,
      source: source ?? this.source,
      originalUrl: originalUrl ?? this.originalUrl,
      isVerified: isVerified ?? this.isVerified,
      status: status ?? this.status,
      metadata: metadata ?? this.metadata,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EnhancedRecipe && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() => 'EnhancedRecipe(id: $id, name: $name)';
}

/// 菜谱分类枚举 - 基于下厨房分类体系
enum RecipeCategory {
  // 菜式分类
  homeStyle('家常菜'), // 家常菜
  quickDish('快手菜'), // 快手菜
  riceDish('下饭菜'), // 下饭菜
  vegetarian('素菜'), // 素菜
  meatDish('大鱼大肉'), // 大鱼大肉
  appetizer('下酒菜'), // 下酒菜
  creative('创意菜'), // 创意菜

  // 特色食品
  snack('小吃'), // 小吃
  sauce('酱'), // 酱
  salad('沙拉'), // 沙拉
  coldDish('凉菜'), // 凉菜
  dimSum('点心'), // 点心
  sandwich('三明治'), // 三明治
  sushi('寿司'), // 寿司

  // 汤粥主食
  soup('汤羹'), // 汤羹
  rice('饭'), // 饭
  noodles('面条'), // 面条
  porridge('粥'), // 粥
  bread('饼'), // 饼
  dumpling('饺子'), // 饺子

  // 烘焙甜品
  baking('烘焙'), // 烘焙
  cake('蛋糕'), // 蛋糕
  dessert('甜品'), // 甜品
  beverage('饮品'), // 饮品

  // 其他
  other('其他'); // 其他

  const RecipeCategory(this.label);
  final String label;
}

/// 菜谱难度枚举
enum RecipeDifficulty {
  beginner('新手'),
  easy('简单'),
  medium('普通'),
  hard('困难'),
  expert('大师级');

  const RecipeDifficulty(this.label);
  final String label;
}

/// 菜谱状态枚举
enum RecipeStatus {
  active('正常'),
  inactive('已下架'),
  pending('待审核'),
  draft('草稿');

  const RecipeStatus(this.label);
  final String label;
}

/// 菜谱来源枚举
enum RecipeSource {
  xiachufang('下厨房'),
  user('用户创建'),
  imported('导入'),
  generated('AI生成'),
  unknown('未知');

  const RecipeSource(this.label);
  final String label;
}

/// 食材信息类
class RecipeIngredient {
  final String name; // 食材名称
  final String? amount; // 用量
  final String? unit; // 单位
  final bool isMain; // 是否主料
  final String? notes; // 备注
  final String? category; // 食材分类
  final List<String>? alternatives; // 替换选项

  const RecipeIngredient({
    required this.name,
    this.amount,
    this.unit,
    this.isMain = true,
    this.notes,
    this.category,
    this.alternatives,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'amount': amount,
      'unit': unit,
      'is_main': isMain,
      'notes': notes,
      'category': category,
      'alternatives': alternatives,
    };
  }

  factory RecipeIngredient.fromJson(Map<String, dynamic> json) {
    return RecipeIngredient(
      name: json['name'] ?? '',
      amount: json['amount'],
      unit: json['unit'],
      isMain: json['is_main'] ?? true,
      notes: json['notes'],
      category: json['category'],
      alternatives: json['alternatives'] != null ? List<String>.from(json['alternatives']) : null,
    );
  }

  factory RecipeIngredient.fromMap(Map<String, dynamic> map) {
    return RecipeIngredient.fromJson(map);
  }

  @override
  String toString() => '$name ${amount ?? ''} ${unit ?? ''}';
}

/// 制作步骤类
class RecipeStep {
  final int order; // 步骤顺序
  final String description; // 步骤描述
  final Duration? duration; // 耗时
  final String? image; // 步骤图片
  final String? video; // 步骤视频
  final List<String>? tips; // 步骤提示
  final String? equipment; // 所需工具
  final int? temperature; // 温度（如烘焙）

  const RecipeStep({
    required this.order,
    required this.description,
    this.duration,
    this.image,
    this.video,
    this.tips,
    this.equipment,
    this.temperature,
  });

  Map<String, dynamic> toJson() {
    return {
      'order': order,
      'description': description,
      'duration': duration?.inMinutes,
      'image': image,
      'video': video,
      'tips': tips,
      'equipment': equipment,
      'temperature': temperature,
    };
  }

  factory RecipeStep.fromJson(Map<String, dynamic> json) {
    return RecipeStep(
      order: json['order'] ?? 0,
      description: json['description'] ?? '',
      duration: json['duration'] != null ? Duration(minutes: json['duration']) : null,
      image: json['image'],
      video: json['video'],
      tips: json['tips'] != null ? List<String>.from(json['tips']) : null,
      equipment: json['equipment'],
      temperature: json['temperature'],
    );
  }

  factory RecipeStep.fromMap(Map<String, dynamic> map) {
    return RecipeStep.fromJson(map);
  }

  @override
  String toString() => '步骤$order: $description';
}

/// 营养信息类
class RecipeNutrition {
  final double calories; // 卡路里
  final double protein; // 蛋白质(g)
  final double carbs; // 碳水化合物(g)
  final double fat; // 脂肪(g)
  final double fiber; // 纤维(g)
  final double sugar; // 糖分(g)
  final double sodium; // 钠(mg)
  final double cholesterol; // 胆固醇(mg)
  final Map<String, double>? vitamins; // 维生素
  final Map<String, double>? minerals; // 矿物质

  const RecipeNutrition({
    this.calories = 0,
    this.protein = 0,
    this.carbs = 0,
    this.fat = 0,
    this.fiber = 0,
    this.sugar = 0,
    this.sodium = 0,
    this.cholesterol = 0,
    this.vitamins,
    this.minerals,
  });

  Map<String, dynamic> toJson() {
    return {
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'fiber': fiber,
      'sugar': sugar,
      'sodium': sodium,
      'cholesterol': cholesterol,
      'vitamins': vitamins,
      'minerals': minerals,
    };
  }

  factory RecipeNutrition.fromJson(Map<String, dynamic> json) {
    return RecipeNutrition(
      calories: (json['calories'] ?? 0).toDouble(),
      protein: (json['protein'] ?? 0).toDouble(),
      carbs: (json['carbs'] ?? 0).toDouble(),
      fat: (json['fat'] ?? 0).toDouble(),
      fiber: (json['fiber'] ?? 0).toDouble(),
      sugar: (json['sugar'] ?? 0).toDouble(),
      sodium: (json['sodium'] ?? 0).toDouble(),
      cholesterol: (json['cholesterol'] ?? 0).toDouble(),
      vitamins: json['vitamins'] != null ? Map<String, double>.from(json['vitamins']) : null,
      minerals: json['minerals'] != null ? Map<String, double>.from(json['minerals']) : null,
    );
  }

  factory RecipeNutrition.fromMap(Map<String, dynamic> map) {
    return RecipeNutrition.fromJson(map);
  }
}

/// 制作提示类
class RecipeTip {
  final String title; // 提示标题
  final String content; // 提示内容
  final RecipeTipType type; // 提示类型
  final int? stepOrder; // 关联步骤（可选）

  const RecipeTip({
    required this.title,
    required this.content,
    this.type = RecipeTipType.general,
    this.stepOrder,
  });

  Map<String, dynamic> toJson() {
    return {
      'title': title,
      'content': content,
      'type': type.name,
      'step_order': stepOrder,
    };
  }

  factory RecipeTip.fromJson(Map<String, dynamic> json) {
    return RecipeTip(
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      type: RecipeTipType.values.firstWhere(
        (t) => t.name == json['type'],
        orElse: () => RecipeTipType.general,
      ),
      stepOrder: json['step_order'],
    );
  }

  factory RecipeTip.fromMap(Map<String, dynamic> map) {
    return RecipeTip.fromJson(map);
  }
}

/// 提示类型枚举
enum RecipeTipType {
  general('通用提示'),
  ingredient('食材选择'),
  technique('制作技巧'),
  storage('保存方法'),
  substitution('替换建议'),
  safety('安全提醒');

  const RecipeTipType(this.label);
  final String label;
}
