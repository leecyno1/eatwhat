import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import 'bubble.dart';

part 'food.g.dart';

/// 食物类型枚举
enum FoodType {
  chinese,      // 中餐
  western,      // 西餐
  japanese,     // 日料
  korean,       // 韩料
  thai,         // 泰餐
  indian,       // 印度菜
  italian,      // 意大利菜
  mexican,      // 墨西哥菜
  vietnamese,   // 越南菜
  dessert,      // 甜品
  snack,        // 小食
  drink,        // 饮品
  other,        // 其他
}

/// 营养信息类
class NutritionInfo {
  final double calories;      // 卡路里
  final double protein;       // 蛋白质(g)
  final double carbs;         // 碳水化合物(g)
  final double fat;           // 脂肪(g)
  final double fiber;         // 纤维(g)
  final double sugar;         // 糖分(g)
  final double sodium;        // 钠(mg)

  const NutritionInfo({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
    this.fiber = 0.0,
    this.sugar = 0.0,
    this.sodium = 0.0,
  });

  /// 从JSON创建营养信息
  factory NutritionInfo.fromJson(Map<String, dynamic> json) {
    return NutritionInfo(
      calories: (json['calories'] ?? 0.0).toDouble(),
      protein: (json['protein'] ?? 0.0).toDouble(),
      carbs: (json['carbs'] ?? 0.0).toDouble(),
      fat: (json['fat'] ?? 0.0).toDouble(),
      fiber: (json['fiber'] ?? 0.0).toDouble(),
      sugar: (json['sugar'] ?? 0.0).toDouble(),
      sodium: (json['sodium'] ?? 0.0).toDouble(),
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'calories': calories,
      'protein': protein,
      'carbs': carbs,
      'fat': fat,
      'fiber': fiber,
      'sugar': sugar,
      'sodium': sodium,
    };
  }
}

/// 食物数据模型
@HiveType(typeId: 2)
class Food {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String name;
  
  @HiveField(2)
  final String? description;
  
  @HiveField(3)
  final String? imageUrl;
  
  @HiveField(4)
  final String cuisineType;
  
  @HiveField(5)
  final List<String> tasteAttributes;
  
  @HiveField(6)
  final List<String> ingredients;
  
  @HiveField(7)
  final Map<String, double>? nutritionFacts;
  
  @HiveField(8)
  final int? calories;
  
  @HiveField(9)
  final List<String>? scenarios;
  
  @HiveField(10)
  final DateTime createdAt;
  
  @HiveField(11)
  final double rating;
  
  @HiveField(12)
  final int ratingCount;
  
  @HiveField(13)
  final String? preparationTime;
  
  @HiveField(14)
  final String? difficulty;
  
  @HiveField(15)
  final double? price;
  
  @HiveField(16)
  final List<String>? tags;

  Food({
    String? id,
    required this.name,
    this.description,
    this.imageUrl,
    required this.cuisineType,
    required this.tasteAttributes,
    required this.ingredients,
    this.nutritionFacts,
    this.calories,
    this.scenarios,
    DateTime? createdAt,
    this.rating = 0.0,
    this.ratingCount = 0,
    this.preparationTime,
    this.difficulty,
    this.price,
    this.tags,
  }) : id = id ?? const Uuid().v4(),
       createdAt = createdAt ?? DateTime.now();

  /// 复制食物并修改属性
  Food copyWith({
    String? id,
    String? name,
    String? description,
    String? imageUrl,
    String? cuisineType,
    List<String>? tasteAttributes,
    List<String>? ingredients,
    Map<String, double>? nutritionFacts,
    int? calories,
    List<String>? scenarios,
    DateTime? createdAt,
    double? rating,
    int? ratingCount,
    String? preparationTime,
    String? difficulty,
    double? price,
    List<String>? tags,
  }) {
    return Food(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      imageUrl: imageUrl ?? this.imageUrl,
      cuisineType: cuisineType ?? this.cuisineType,
      tasteAttributes: tasteAttributes ?? this.tasteAttributes,
      ingredients: ingredients ?? this.ingredients,
      nutritionFacts: nutritionFacts ?? this.nutritionFacts,
      calories: calories ?? this.calories,
      scenarios: scenarios ?? this.scenarios,
      createdAt: createdAt ?? this.createdAt,
      rating: rating ?? this.rating,
      ratingCount: ratingCount ?? this.ratingCount,
      preparationTime: preparationTime ?? this.preparationTime,
      difficulty: difficulty ?? this.difficulty,
      price: price ?? this.price,
      tags: tags ?? this.tags,
    );
  }

  /// 计算与气泡的匹配度
  double calculateMatchScore(List<Bubble> selectedBubbles) {
    if (selectedBubbles.isEmpty) return 0.0;
    
    double totalScore = 0.0;
    int matchCount = 0;
    
    for (final bubble in selectedBubbles) {
      double bubbleScore = 0.0;
      
      switch (bubble.type) {
        case BubbleType.taste:
          if (tasteAttributes.contains(bubble.name)) {
            bubbleScore = 1.0;
          }
          break;
        case BubbleType.cuisine:
          if (cuisineType == bubble.name) {
            bubbleScore = 1.0;
          }
          break;
        case BubbleType.ingredient:
          if (ingredients.any((ingredient) => 
              ingredient.toLowerCase().contains(bubble.name.toLowerCase()))) {
            bubbleScore = 0.8;
          }
          break;
        case BubbleType.scenario:
          if (scenarios?.contains(bubble.name) == true) {
            bubbleScore = 1.0;
          }
          break;
        case BubbleType.calorie:
          if (calories != null) {
            // 根据热量范围匹配
            bubbleScore = _calculateCalorieScore(bubble.name);
          }
          break;
        case BubbleType.nutrition:
          if (nutritionFacts != null) {
            bubbleScore = _calculateNutritionScore(bubble.name);
          }
          break;
        case BubbleType.temperature:
        case BubbleType.spiciness:
          if (tags?.contains(bubble.name) == true) {
            bubbleScore = 0.7;
          }
          break;
      }
      
      if (bubbleScore > 0) {
        totalScore += bubbleScore;
        matchCount++;
      }
    }
    
    return matchCount > 0 ? totalScore / selectedBubbles.length : 0.0;
  }

  /// 计算热量匹配分数
  double _calculateCalorieScore(String calorieRange) {
    if (calories == null) return 0.0;
    
    switch (calorieRange) {
      case '低热量':
        return calories! < 200 ? 1.0 : 0.0;
      case '中等热量':
        return calories! >= 200 && calories! <= 500 ? 1.0 : 0.0;
      case '高热量':
        return calories! > 500 ? 1.0 : 0.0;
      default:
        return 0.0;
    }
  }

  /// 计算营养匹配分数
  double _calculateNutritionScore(String nutritionType) {
    if (nutritionFacts == null) return 0.0;
    
    switch (nutritionType) {
      case '高蛋白':
        return (nutritionFacts!['protein'] ?? 0) > 15 ? 1.0 : 0.0;
      case '低脂肪':
        return (nutritionFacts!['fat'] ?? 0) < 10 ? 1.0 : 0.0;
      case '高纤维':
        return (nutritionFacts!['fiber'] ?? 0) > 5 ? 1.0 : 0.0;
      default:
        return 0.0;
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Food && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Food{id: $id, name: $name, cuisineType: $cuisineType}';
  }
}

/// 用户评分模型
@HiveType(typeId: 3)
class UserRating {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String userId;
  
  @HiveField(2)
  final String foodId;
  
  @HiveField(3)
  final int rating;
  
  @HiveField(4)
  final DateTime timestamp;
  
  @HiveField(5)
  final String? comment;

  UserRating({
    String? id,
    required this.userId,
    required this.foodId,
    required this.rating,
    DateTime? timestamp,
    this.comment,
  }) : id = id ?? const Uuid().v4(),
       timestamp = timestamp ?? DateTime.now();

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserRating && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}

/// 食物工厂类
class FoodFactory {
  /// 创建示例食物数据
  static List<Food> createSampleFoods() {
    return [
      Food(
        name: '宫保鸡丁',
        description: '经典川菜，酸甜微辣，口感丰富',
        cuisineType: '川菜',
        tasteAttributes: ['甜', '酸', '辣'],
        ingredients: ['鸡肉', '花生', '青椒', '红椒'],
        calories: 280,
        scenarios: ['午餐', '晚餐'],
        rating: 4.5,
        ratingCount: 128,
        preparationTime: '20分钟',
        difficulty: '中等',
        price: 25.0,
        tags: ['热菜', '微辣'],
        nutritionFacts: {
          'protein': 22.0,
          'fat': 15.0,
          'carbs': 12.0,
          'fiber': 3.0,
        },
      ),
      Food(
        name: '三文鱼刺身',
        description: '新鲜三文鱼，口感鲜美',
        cuisineType: '日料',
        tasteAttributes: ['鲜'],
        ingredients: ['三文鱼', '芥末', '生抽'],
        calories: 180,
        scenarios: ['午餐', '晚餐'],
        rating: 4.8,
        ratingCount: 95,
        preparationTime: '5分钟',
        difficulty: '简单',
        price: 45.0,
        tags: ['生食', '清淡'],
        nutritionFacts: {
          'protein': 25.0,
          'fat': 8.0,
          'carbs': 0.0,
          'fiber': 0.0,
        },
      ),
      Food(
        name: '白切鸡',
        description: '粤菜经典，清淡鲜美',
        cuisineType: '粤菜',
        tasteAttributes: ['鲜', '清淡'],
        ingredients: ['鸡肉', '姜', '葱'],
        calories: 220,
        scenarios: ['午餐', '晚餐'],
        rating: 4.3,
        ratingCount: 76,
        preparationTime: '30分钟',
        difficulty: '中等',
        price: 35.0,
        tags: ['热菜', '清淡'],
        nutritionFacts: {
          'protein': 28.0,
          'fat': 10.0,
          'carbs': 2.0,
          'fiber': 0.5,
        },
      ),
      Food(
        name: '蔬菜沙拉',
        description: '新鲜蔬菜搭配，健康低卡',
        cuisineType: '西式',
        tasteAttributes: ['清淡', '酸'],
        ingredients: ['生菜', '番茄', '黄瓜', '胡萝卜'],
        calories: 120,
        scenarios: ['早餐', '午餐'],
        rating: 4.0,
        ratingCount: 42,
        preparationTime: '10分钟',
        difficulty: '简单',
        price: 18.0,
        tags: ['冷菜', '素食'],
        nutritionFacts: {
          'protein': 3.0,
          'fat': 2.0,
          'carbs': 15.0,
          'fiber': 8.0,
        },
      ),
      Food(
        name: '小笼包',
        description: '上海特色点心，皮薄馅大',
        cuisineType: '沪菜',
        tasteAttributes: ['鲜', '香'],
        ingredients: ['猪肉', '面粉', '葱', '姜'],
        calories: 320,
        scenarios: ['早餐', '午餐'],
        rating: 4.6,
        ratingCount: 156,
        preparationTime: '15分钟',
        difficulty: '困难',
        price: 22.0,
        tags: ['热菜', '点心'],
        nutritionFacts: {
          'protein': 18.0,
          'fat': 12.0,
          'carbs': 35.0,
          'fiber': 2.0,
        },
      ),
    ];
  }
} 