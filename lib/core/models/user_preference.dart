import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';
import 'bubble.dart';

part 'user_preference.g.dart';

/// 用户偏好模型
@HiveType(typeId: 4)
class UserPreference {
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
  final List<String> favoriteFood;
  
  @HiveField(9)
  final List<String> dislikedFood;

  UserPreference({
    String? id,
    required this.userId,
    List<String>? likedBubbles,
    List<String>? dislikedBubbles,
    List<String>? ignoredBubbles,
    Map<String, int>? bubbleInteractionCount,
    DateTime? lastUpdated,
    Map<String, double>? bubbleWeights,
    List<String>? favoriteFood,
    List<String>? dislikedFood,
  }) : id = id ?? const Uuid().v4(),
       likedBubbles = likedBubbles ?? [],
       dislikedBubbles = dislikedBubbles ?? [],
       ignoredBubbles = ignoredBubbles ?? [],
       bubbleInteractionCount = bubbleInteractionCount ?? {},
       lastUpdated = lastUpdated ?? DateTime.now(),
       bubbleWeights = bubbleWeights ?? {},
       favoriteFood = favoriteFood ?? [],
       dislikedFood = dislikedFood ?? [];

  /// 更新气泡偏好
  UserPreference updateBubblePreference(
    String bubbleName,
    BubbleGesture gesture,
  ) {
    final newLiked = List<String>.from(likedBubbles);
    final newDisliked = List<String>.from(dislikedBubbles);
    final newIgnored = List<String>.from(ignoredBubbles);
    final newInteractionCount = Map<String, int>.from(bubbleInteractionCount);
    final newWeights = Map<String, double>.from(bubbleWeights);

    // 更新交互次数
    newInteractionCount[bubbleName] = (newInteractionCount[bubbleName] ?? 0) + 1;

    // 根据手势更新偏好
    switch (gesture) {
      case BubbleGesture.swipeUp:
        if (!newLiked.contains(bubbleName)) {
          newLiked.add(bubbleName);
        }
        newDisliked.remove(bubbleName);
        newIgnored.remove(bubbleName);
        newWeights[bubbleName] = (newWeights[bubbleName] ?? 0.5) + 0.2;
        break;
      case BubbleGesture.swipeDown:
        if (!newDisliked.contains(bubbleName)) {
          newDisliked.add(bubbleName);
        }
        newLiked.remove(bubbleName);
        newIgnored.remove(bubbleName);
        newWeights[bubbleName] = (newWeights[bubbleName] ?? 0.5) - 0.3;
        break;
      case BubbleGesture.swipeLeft:
        if (!newIgnored.contains(bubbleName)) {
          newIgnored.add(bubbleName);
        }
        newWeights[bubbleName] = (newWeights[bubbleName] ?? 0.5) - 0.1;
        break;
      case BubbleGesture.tap:
        newWeights[bubbleName] = (newWeights[bubbleName] ?? 0.5) + 0.1;
        break;
      default:
        break;
    }

    // 确保权重在合理范围内
    newWeights[bubbleName] = (newWeights[bubbleName] ?? 0.5).clamp(0.0, 1.0);

    return UserPreference(
      id: id,
      userId: userId,
      likedBubbles: newLiked,
      dislikedBubbles: newDisliked,
      ignoredBubbles: newIgnored,
      bubbleInteractionCount: newInteractionCount,
      lastUpdated: DateTime.now(),
      bubbleWeights: newWeights,
      favoriteFood: favoriteFood,
      dislikedFood: dislikedFood,
    );
  }

  /// 更新食物偏好
  UserPreference updateFoodPreference(String foodId, bool isLiked) {
    final newFavorite = List<String>.from(favoriteFood);
    final newDisliked = List<String>.from(dislikedFood);

    if (isLiked) {
      if (!newFavorite.contains(foodId)) {
        newFavorite.add(foodId);
      }
      newDisliked.remove(foodId);
    } else {
      if (!newDisliked.contains(foodId)) {
        newDisliked.add(foodId);
      }
      newFavorite.remove(foodId);
    }

    return copyWith(
      favoriteFood: newFavorite,
      dislikedFood: newDisliked,
      lastUpdated: DateTime.now(),
    );
  }

  /// 获取气泡权重
  double getBubbleWeight(String bubbleName) {
    return bubbleWeights[bubbleName] ?? 0.5;
  }

  /// 获取气泡偏好类型
  BubblePreferenceType getBubblePreferenceType(String bubbleName) {
    if (likedBubbles.contains(bubbleName)) {
      return BubblePreferenceType.liked;
    } else if (dislikedBubbles.contains(bubbleName)) {
      return BubblePreferenceType.disliked;
    } else if (ignoredBubbles.contains(bubbleName)) {
      return BubblePreferenceType.ignored;
    } else {
      return BubblePreferenceType.neutral;
    }
  }

  /// 获取推荐分数调整值
  double getRecommendationBonus(List<String> bubbleNames) {
    double bonus = 0.0;
    for (final bubbleName in bubbleNames) {
      final weight = getBubbleWeight(bubbleName);
      if (likedBubbles.contains(bubbleName)) {
        bonus += weight * 0.3;
      } else if (dislikedBubbles.contains(bubbleName)) {
        bonus -= weight * 0.5;
      }
    }
    return bonus.clamp(-1.0, 1.0);
  }

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
    List<String>? favoriteFood,
    List<String>? dislikedFood,
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
      favoriteFood: favoriteFood ?? this.favoriteFood,
      dislikedFood: dislikedFood ?? this.dislikedFood,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserPreference && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'UserPreference{userId: $userId, likedBubbles: ${likedBubbles.length}, dislikedBubbles: ${dislikedBubbles.length}}';
  }
}

/// 气泡偏好类型
enum BubblePreferenceType {
  liked,
  disliked,
  ignored,
  neutral,
}

/// 用户会话模型
@HiveType(typeId: 5)
class UserSession {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final String userId;
  
  @HiveField(2)
  final DateTime startTime;
  
  @HiveField(3)
  final DateTime? endTime;
  
  @HiveField(4)
  final List<BubbleInteraction> interactions;
  
  @HiveField(5)
  final List<String> recommendedFoods;
  
  @HiveField(6)
  final String? selectedFood;

  UserSession({
    String? id,
    required this.userId,
    DateTime? startTime,
    this.endTime,
    List<BubbleInteraction>? interactions,
    List<String>? recommendedFoods,
    this.selectedFood,
  }) : id = id ?? const Uuid().v4(),
       startTime = startTime ?? DateTime.now(),
       interactions = interactions ?? [],
       recommendedFoods = recommendedFoods ?? [];

  /// 添加交互记录
  UserSession addInteraction(BubbleInteraction interaction) {
    final newInteractions = List<BubbleInteraction>.from(interactions);
    newInteractions.add(interaction);
    
    return copyWith(interactions: newInteractions);
  }

  /// 设置推荐结果
  UserSession setRecommendations(List<String> foodIds) {
    return copyWith(recommendedFoods: foodIds);
  }

  /// 选择食物
  UserSession selectFood(String foodId) {
    return copyWith(
      selectedFood: foodId,
      endTime: DateTime.now(),
    );
  }

  /// 复制并修改属性
  UserSession copyWith({
    String? id,
    String? userId,
    DateTime? startTime,
    DateTime? endTime,
    List<BubbleInteraction>? interactions,
    List<String>? recommendedFoods,
    String? selectedFood,
  }) {
    return UserSession(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      interactions: interactions ?? this.interactions,
      recommendedFoods: recommendedFoods ?? this.recommendedFoods,
      selectedFood: selectedFood ?? this.selectedFood,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserSession && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
} 