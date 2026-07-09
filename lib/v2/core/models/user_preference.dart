/// 用户偏好数据模型 (V2版本 - 轻量级)
class UserPreference {
  final String id;
  final String userId;
  final List<String> likedBubbles;
  final List<String> dislikedBubbles;
  final List<String> ignoredBubbles;
  final Map<String, int> bubbleInteractionCount;
  final DateTime lastUpdated;
  final Map<String, double> bubbleWeights;
  final List<String> favoriteFoods;
  final List<String> dislikedFoods;
  final Map<String, double> cuisinePreferences;
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
  })  : id = id ?? DateTime.now().millisecondsSinceEpoch.toString(),
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
  UserPreference updateTastePreference(String taste, double score) {
    final newPreferences = Map<String, double>.from(tastePreferences);
    newPreferences[taste] = score.clamp(-10.0, 10.0);

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

  @override
  String toString() {
    return 'UserPreference(userId: $userId, cuisinePrefs: ${cuisinePreferences.length}, tastePrefs: ${tastePreferences.length})';
  }
}
