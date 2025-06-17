/// 用户偏好模型
class UserPreference {
  final String userId;
  final Map<String, double> bubblePreferences; // 气泡名称 -> 偏好分数
  final Map<String, int> bubbleInteractions; // 气泡名称 -> 交互次数
  final List<String> favoriteFoods; // 收藏的食物ID
  final List<String> dislikedFoods; // 不喜欢的食物ID
  final Map<String, int> cuisinePreferences; // 菜系偏好
  final Map<String, int> tastePreferences; // 口味偏好
  final List<String> likedBubbles; // 喜欢的气泡
  final List<String> dislikedBubbles; // 不喜欢的气泡
  final List<String> ignoredBubbles; // 忽略的气泡
  final Map<String, int> bubbleInteractionCount; // 气泡交互次数
  final Map<String, double> bubbleWeights; // 气泡权重
  final DateTime lastUpdated;

  UserPreference({
    required this.userId,
    this.bubblePreferences = const {},
    this.bubbleInteractions = const {},
    this.favoriteFoods = const [],
    this.dislikedFoods = const [],
    this.cuisinePreferences = const {},
    this.tastePreferences = const {},
    this.likedBubbles = const [],
    this.dislikedBubbles = const [],
    this.ignoredBubbles = const [],
    this.bubbleInteractionCount = const {},
    this.bubbleWeights = const {},
    DateTime? lastUpdated,
  }) : lastUpdated = lastUpdated ?? DateTime.now();

  /// 复制用户偏好并修改部分属性
  UserPreference copyWith({
    String? userId,
    Map<String, double>? bubblePreferences,
    Map<String, int>? bubbleInteractions,
    List<String>? favoriteFoods,
    List<String>? dislikedFoods,
    Map<String, int>? cuisinePreferences,
    Map<String, int>? tastePreferences,
    List<String>? likedBubbles,
    List<String>? dislikedBubbles,
    List<String>? ignoredBubbles,
    Map<String, int>? bubbleInteractionCount,
    Map<String, double>? bubbleWeights,
    DateTime? lastUpdated,
  }) {
    return UserPreference(
      userId: userId ?? this.userId,
      bubblePreferences: bubblePreferences ?? this.bubblePreferences,
      bubbleInteractions: bubbleInteractions ?? this.bubbleInteractions,
      favoriteFoods: favoriteFoods ?? this.favoriteFoods,
      dislikedFoods: dislikedFoods ?? this.dislikedFoods,
      cuisinePreferences: cuisinePreferences ?? this.cuisinePreferences,
      tastePreferences: tastePreferences ?? this.tastePreferences,
      likedBubbles: likedBubbles ?? this.likedBubbles,
      dislikedBubbles: dislikedBubbles ?? this.dislikedBubbles,
      ignoredBubbles: ignoredBubbles ?? this.ignoredBubbles,
      bubbleInteractionCount: bubbleInteractionCount ?? this.bubbleInteractionCount,
      bubbleWeights: bubbleWeights ?? this.bubbleWeights,
      lastUpdated: lastUpdated ?? this.lastUpdated,
    );
  }

  /// 更新气泡偏好
  UserPreference updateBubblePreference(String bubbleName, double score) {
    final newPreferences = Map<String, double>.from(bubblePreferences);
    final currentScore = newPreferences[bubbleName] ?? 0.0;
    newPreferences[bubbleName] = (currentScore + score).clamp(-10.0, 10.0);
    
    final newInteractions = Map<String, int>.from(bubbleInteractions);
    newInteractions[bubbleName] = (newInteractions[bubbleName] ?? 0) + 1;
    
    return copyWith(
      bubblePreferences: newPreferences,
      bubbleInteractions: newInteractions,
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

  /// 更新菜系偏好
  UserPreference updateCuisinePreference(String cuisine, int score) {
    final newPreferences = Map<String, int>.from(cuisinePreferences);
    newPreferences[cuisine] = score;
    
    return copyWith(
      cuisinePreferences: newPreferences,
      lastUpdated: DateTime.now(),
    );
  }

  /// 更新口味偏好
  UserPreference updateTastePreference(String taste, int score) {
    final newPreferences = Map<String, int>.from(tastePreferences);
    newPreferences[taste] = score;
    
    return copyWith(
      tastePreferences: newPreferences,
      lastUpdated: DateTime.now(),
    );
  }

  /// 获取气泡偏好分数
  double getBubblePreference(String bubbleName) {
    return bubblePreferences[bubbleName] ?? 0.0;
  }

  /// 获取气泡交互次数
  int getBubbleInteractionCount(String bubbleName) {
    return bubbleInteractions[bubbleName] ?? 0;
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'userId': userId,
      'bubblePreferences': bubblePreferences,
      'bubbleInteractions': bubbleInteractions,
      'favoriteFoods': favoriteFoods,
      'dislikedFoods': dislikedFoods,
      'cuisinePreferences': cuisinePreferences,
      'tastePreferences': tastePreferences,
      'likedBubbles': likedBubbles,
      'dislikedBubbles': dislikedBubbles,
      'ignoredBubbles': ignoredBubbles,
      'bubbleInteractionCount': bubbleInteractionCount,
      'bubbleWeights': bubbleWeights,
      'lastUpdated': lastUpdated.toIso8601String(),
    };
  }

  /// 从JSON创建
  factory UserPreference.fromJson(Map<String, dynamic> json) {
    return UserPreference(
      userId: json['userId'] ?? '',
      bubblePreferences: Map<String, double>.from(json['bubblePreferences'] ?? {}),
      bubbleInteractions: Map<String, int>.from(json['bubbleInteractions'] ?? {}),
      favoriteFoods: List<String>.from(json['favoriteFoods'] ?? []),
      dislikedFoods: List<String>.from(json['dislikedFoods'] ?? []),
      cuisinePreferences: Map<String, int>.from(json['cuisinePreferences'] ?? {}),
      tastePreferences: Map<String, int>.from(json['tastePreferences'] ?? {}),
      likedBubbles: List<String>.from(json['likedBubbles'] ?? []),
      dislikedBubbles: List<String>.from(json['dislikedBubbles'] ?? []),
      ignoredBubbles: List<String>.from(json['ignoredBubbles'] ?? []),
      bubbleInteractionCount: Map<String, int>.from(json['bubbleInteractionCount'] ?? {}),
      bubbleWeights: Map<String, double>.from(json['bubbleWeights'] ?? {}),
      lastUpdated: DateTime.parse(json['lastUpdated'] ?? DateTime.now().toIso8601String()),
    );
  }

  @override
  String toString() {
    return 'UserPreference(userId: $userId, favorites: ${favoriteFoods.length}, dislikes: ${dislikedFoods.length})';
  }
}