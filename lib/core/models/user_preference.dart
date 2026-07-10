import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'user_preference.g.dart';

/// 用户偏好模型
///
/// 使用Hive进行本地存储
@HiveType(typeId: 4)
class UserPreference extends HiveObject {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String userId;

  @HiveField(2)
  final List<String> likedBubbles;

  @HiveField(3)
  final List<String> dislikedBubbles;

  @HiveField(4)
  final List<String> ignoredBubbles;

  @HiveField(5)
  final Map<String, int> bubbleInteractionCount;

  @HiveField(6)
  final DateTime lastUpdated;

  @HiveField(7)
  final Map<String, double> bubbleWeights;

  @HiveField(8)
  final List<String> favoriteFoods;

  @HiveField(9)
  final List<String> dislikedFoods;

  @HiveField(10)
  final Map<String, double> cuisinePreferences;

  @HiveField(11)
  final Map<String, double> tastePreferences;

  UserPreference({
    String? id,
    required this.userId,
    List<String>? likedBubbles,
    List<String>? dislikedBubbles,
    List<String>? ignoredBubbles,
    Map<String, int>? bubbleInteractionCount,
    DateTime? lastUpdated,
    Map<String, double>? bubbleWeights,
    List<String>? favoriteFoods,
    List<String>? dislikedFoods,
    Map<String, double>? cuisinePreferences,
    Map<String, double>? tastePreferences,
  })  : id = id ?? const Uuid().v4(),
        likedBubbles = likedBubbles ?? [],
        dislikedBubbles = dislikedBubbles ?? [],
        ignoredBubbles = ignoredBubbles ?? [],
        bubbleInteractionCount = bubbleInteractionCount ?? {},
        lastUpdated = lastUpdated ?? DateTime.now(),
        bubbleWeights = bubbleWeights ?? {},
        favoriteFoods = favoriteFoods ?? [],
        dislikedFoods = dislikedFoods ?? [],
        cuisinePreferences = cuisinePreferences ?? {},
        tastePreferences = tastePreferences ?? {};

  /// 复制并修改属性
  UserPreference copyWith({
    String? id,
    String? userId,
    List<String>? likedBubbles,
    List<String>? dislikedBubbles,
    List<String>? ignoredBubbles,
    Map<String, int>? bubbleInteractionCount,
    DateTime? lastUpdated,
    Map<String, double>? bubbleWeights,
    List<String>? favoriteFoods,
    List<String>? dislikedFoods,
    Map<String, double>? cuisinePreferences,
    Map<String, double>? tastePreferences,
  }) {
    return UserPreference(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      likedBubbles: likedBubbles ?? this.likedBubbles,
      dislikedBubbles: dislikedBubbles ?? this.dislikedBubbles,
      ignoredBubbles: ignoredBubbles ?? this.ignoredBubbles,
      bubbleInteractionCount: bubbleInteractionCount ?? this.bubbleInteractionCount,
      lastUpdated: lastUpdated ?? this.lastUpdated,
      bubbleWeights: bubbleWeights ?? this.bubbleWeights,
      favoriteFoods: favoriteFoods ?? this.favoriteFoods,
      dislikedFoods: dislikedFoods ?? this.dislikedFoods,
      cuisinePreferences: cuisinePreferences ?? this.cuisinePreferences,
      tastePreferences: tastePreferences ?? this.tastePreferences,
    );
  }

  /// 转换为JSON (用于API, 而非Hive)
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'userId': userId,
      'likedBubbles': likedBubbles,
      'dislikedBubbles': dislikedBubbles,
      'ignoredBubbles': ignoredBubbles,
      'bubbleInteractionCount': bubbleInteractionCount,
      'lastUpdated': lastUpdated.toIso8601String(),
      'bubbleWeights': bubbleWeights,
      'favoriteFoods': favoriteFoods,
      'dislikedFoods': dislikedFoods,
      'cuisinePreferences': cuisinePreferences,
      'tastePreferences': tastePreferences,
    };
  }

  /// 从JSON创建 (用于API, 而非Hive)
  factory UserPreference.fromJson(Map<String, dynamic> json) {
    return UserPreference(
      id: json['id'],
      userId: json['userId'],
      likedBubbles: List<String>.from(json['likedBubbles'] ?? []),
      dislikedBubbles: List<String>.from(json['dislikedBubbles'] ?? []),
      ignoredBubbles: List<String>.from(json['ignoredBubbles'] ?? []),
      bubbleInteractionCount: Map<String, int>.from(json['bubbleInteractionCount'] ?? {}),
      lastUpdated: DateTime.parse(json['lastUpdated'] ?? DateTime.now().toIso8601String()),
      bubbleWeights: Map<String, double>.from(json['bubbleWeights'] ?? {}),
      favoriteFoods: List<String>.from(json['favoriteFoods'] ?? []),
      dislikedFoods: List<String>.from(json['dislikedFoods'] ?? []),
      cuisinePreferences: Map<String, double>.from(json['cuisinePreferences'] ?? {}),
      tastePreferences: Map<String, double>.from(json['tastePreferences'] ?? {}),
    );
  }

  /// 更新气泡偏好
  UserPreference updateBubblePreference(String bubbleName, double score) {
    final newPreferences = Map<String, double>.from(bubbleWeights);
    final currentScore = newPreferences[bubbleName] ?? 0.0;
    newPreferences[bubbleName] = (currentScore + score).clamp(-10.0, 10.0);

    final newInteractions = Map<String, int>.from(bubbleInteractionCount);
    newInteractions[bubbleName] = (newInteractions[bubbleName] ?? 0) + 1;

    return copyWith(
      bubbleWeights: newPreferences,
      bubbleInteractionCount: newInteractions,
      lastUpdated: DateTime.now(),
    );
  }

  /// 添加收藏食物
  UserPreference addFavoriteFood(String foodId) {
    if (favoriteFoods.contains(foodId)) return this;

    final newFavorites = List<String>.from(favoriteFoods)..add(foodId);
    final newDislikes = List<String>.from(dislikedFoods)..remove(foodId);

    return copyWith(
      favoriteFoods: newFavorites,
      dislikedFoods: newDislikes,
      lastUpdated: DateTime.now(),
    );
  }

  /// 添加不喜欢的食物
  UserPreference addDislikedFood(String foodId) {
    if (dislikedFoods.contains(foodId)) return this;

    final newDislikes = List<String>.from(dislikedFoods)..add(foodId);
    final newFavorites = List<String>.from(favoriteFoods)..remove(foodId);

    return copyWith(
      dislikedFoods: newDislikes,
      favoriteFoods: newFavorites,
      lastUpdated: DateTime.now(),
    );
  }

  /// 移除收藏食物
  UserPreference removeFavoriteFood(String foodId) {
    if (!favoriteFoods.contains(foodId)) return this;

    final newFavorites = List<String>.from(favoriteFoods)..remove(foodId);

    return copyWith(
      favoriteFoods: newFavorites,
      lastUpdated: DateTime.now(),
    );
  }

  /// 移除不喜欢的食物
  UserPreference removeDislikedFood(String foodId) {
    if (!dislikedFoods.contains(foodId)) return this;

    final newDislikes = List<String>.from(dislikedFoods)..remove(foodId);

    return copyWith(
      dislikedFoods: newDislikes,
      lastUpdated: DateTime.now(),
    );
  }

  /// 获取气泡偏好分数
  double getBubblePreference(String bubbleName) {
    return bubbleWeights[bubbleName] ?? 0.0;
  }

  /// 获取气泡交互次数
  int getBubbleInteractionCount(String bubbleName) {
    return bubbleInteractionCount[bubbleName] ?? 0;
  }

  /// 更新菜系偏好
  UserPreference updateCuisinePreference(String cuisine, double score) {
    final newPreferences = Map<String, double>.from(cuisinePreferences);
    newPreferences[cuisine] = score.clamp(-10.0, 10.0);

    return copyWith(
      cuisinePreferences: newPreferences,
      lastUpdated: DateTime.now(),
    );
  }

  /// 更新口味偏好
  /// [taste] 口味名称
  /// [score] 基础分数变化量（正数增加偏好，负数减少偏好）
  /// [intensity] 强度因子（0.0-1.0），默认1.0，实际分数变化量为 score * intensity
  UserPreference updateTastePreference(String taste, double score, {double intensity = 1.0}) {
    final newPreferences = Map<String, double>.from(tastePreferences);
    final currentScore = newPreferences[taste] ?? 0.0;
    // 实际变化量 = 基础分数 * 强度
    final actualChange = score * intensity.clamp(0.0, 1.0);
    newPreferences[taste] = (currentScore + actualChange).clamp(-10.0, 10.0);

    return copyWith(
      tastePreferences: newPreferences,
      lastUpdated: DateTime.now(),
    );
  }

  /// 获取喜爱的菜系列表
  List<String> get favoriteCuisines {
    return cuisinePreferences.entries
        .where((entry) => entry.value > 0)
        .map((entry) => entry.key)
        .toList();
  }

  /// 获取喜爱的口味列表
  List<String> get likedTastes {
    return tastePreferences.entries
        .where((entry) => entry.value > 0)
        .map((entry) => entry.key)
        .toList();
  }

  /// 获取不喜欢的口味列表
  List<String> get dislikedTastes {
    return tastePreferences.entries
        .where((entry) => entry.value < 0)
        .map((entry) => entry.key)
        .toList();
  }

  /// 创建默认用户偏好
  static UserPreference defaultPreference() {
    return UserPreference(
      userId: 'default_user',
      likedBubbles: [],
      dislikedBubbles: [],
      ignoredBubbles: [],
      bubbleInteractionCount: {},
      bubbleWeights: {},
      favoriteFoods: [],
      dislikedFoods: [],
      cuisinePreferences: {},
      tastePreferences: {},
    );
  }

  @override
  String toString() {
    return 'UserPreference(userId: $userId, favorites: ${favoriteFoods.length}, dislikes: ${dislikedFoods.length})';
  }
}
