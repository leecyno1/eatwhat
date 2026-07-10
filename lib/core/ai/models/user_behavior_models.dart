/// 用户行为数据模型 - Phase 3 AI学习基础
/// 记录用户与应用的各种交互行为，用于AI偏好学习
class UserBehaviorData {
  final String userId;
  final String sessionId;
  final DateTime timestamp;
  final UserActionType actionType;
  final String targetId; // 菜谱ID、食材ID等
  final String targetType; // 'recipe', 'ingredient', 'cuisine', etc.
  final Map<String, dynamic> actionDetails;
  final double actionIntensity; // 行为强度 0.0-1.0
  final String? contextInfo; // 上下文信息（时间、场景等）

  UserBehaviorData({
    required this.userId,
    required this.sessionId,
    required this.timestamp,
    required this.actionType,
    required this.targetId,
    required this.targetType,
    this.actionDetails = const {},
    this.actionIntensity = 0.5,
    this.contextInfo,
  });

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'sessionId': sessionId,
        'timestamp': timestamp.toIso8601String(),
        'actionType': actionType.name,
        'targetId': targetId,
        'targetType': targetType,
        'actionDetails': actionDetails,
        'actionIntensity': actionIntensity,
        'contextInfo': contextInfo,
      };

  factory UserBehaviorData.fromJson(Map<String, dynamic> json) => UserBehaviorData(
        userId: json['userId'] ?? '',
        sessionId: json['sessionId'] ?? '',
        timestamp: DateTime.parse(json['timestamp']),
        actionType: UserActionType.values.firstWhere(
          (type) => type.name == json['actionType'],
          orElse: () => UserActionType.view,
        ),
        targetId: json['targetId'] ?? '',
        targetType: json['targetType'] ?? '',
        actionDetails: Map<String, dynamic>.from(json['actionDetails'] ?? {}),
        actionIntensity: (json['actionIntensity'] ?? 0.5).toDouble(),
        contextInfo: json['contextInfo'],
      );
}

/// 用户行为类型枚举
enum UserActionType {
  // 浏览行为
  view('浏览'), // 查看菜谱、食材等
  scroll('滚动'), // 滚动浏览
  hover('悬停'), // 悬停停留

  // 搜索行为
  search('搜索'), // 搜索菜谱
  filter('筛选'), // 使用筛选功能
  sort('排序'), // 排序操作

  // 互动行为
  like('喜欢'), // 点赞、收藏
  dislike('不喜欢'), // 不喜欢
  share('分享'), // 分享菜谱
  comment('评论'), // 评论反馈

  // 深度参与
  favorite('收藏'), // 添加收藏
  unfavorite('取消收藏'), // 取消收藏
  cook('制作'), // 标记制作过
  rate('评分'), // 给出评分

  // 学习行为
  learn('学习'), // 查看制作步骤
  compare('比较'), // 比较菜谱
  substitute('替换'), // 食材替换

  // 对话行为
  ask('询问'), // AI对话询问
  clarify('澄清'), // 澄清需求
  accept('接受'), // 接受推荐
  reject('拒绝'); // 拒绝推荐

  const UserActionType(this.label);
  final String label;
}

/// 偏好向量系统 - 多维度用户偏好表示
class PreferenceVector {
  // 口味偏好向量 (0.0-1.0)
  final Map<String, double> tastePreferences;

  // 菜系偏好向量
  final Map<String, double> cuisinePreferences;

  // 食材偏好向量
  final Map<String, double> ingredientPreferences;

  // 场景偏好向量
  final Map<String, double> scenarioPreferences;

  // 营养偏好向量
  final Map<String, double> nutritionPreferences;

  // 难度偏好向量
  final Map<String, double> difficultyPreferences;

  // 时间偏好向量
  final Map<String, double> timePreferences;

  // 情感偏好向量
  final Map<String, double> emotionalPreferences;

  // 季节偏好向量
  final Map<String, double> seasonalPreferences;

  // 动态权重 (各维度的重要性)
  final Map<String, double> dimensionWeights;

  // 最后更新时间
  final DateTime lastUpdated;

  // 置信度分数
  final double confidenceScore;

  PreferenceVector({
    this.tastePreferences = const {},
    this.cuisinePreferences = const {},
    this.ingredientPreferences = const {},
    this.scenarioPreferences = const {},
    this.nutritionPreferences = const {},
    this.difficultyPreferences = const {},
    this.timePreferences = const {},
    this.emotionalPreferences = const {},
    this.seasonalPreferences = const {},
    this.dimensionWeights = const {},
    DateTime? lastUpdated,
    this.confidenceScore = 0.0,
  }) : lastUpdated = lastUpdated ?? DateTime.now();

  /// 计算与另一个偏好向量的相似度
  double calculateSimilarity(PreferenceVector other) {
    double totalSimilarity = 0.0;
    double totalWeight = 0.0;

    final dimensions = [
      ('taste', tastePreferences, other.tastePreferences),
      ('cuisine', cuisinePreferences, other.cuisinePreferences),
      ('ingredient', ingredientPreferences, other.ingredientPreferences),
      ('scenario', scenarioPreferences, other.scenarioPreferences),
      ('nutrition', nutritionPreferences, other.nutritionPreferences),
      ('difficulty', difficultyPreferences, other.difficultyPreferences),
      ('time', timePreferences, other.timePreferences),
      ('emotional', emotionalPreferences, other.emotionalPreferences),
      ('seasonal', seasonalPreferences, other.seasonalPreferences),
    ];

    for (final (dimension, prefs1, prefs2) in dimensions) {
      final weight = dimensionWeights[dimension] ?? 1.0;
      final similarity = _calculateVectorSimilarity(prefs1, prefs2);
      totalSimilarity += similarity * weight;
      totalWeight += weight;
    }

    return totalWeight > 0 ? totalSimilarity / totalWeight : 0.0;
  }

  /// 计算两个偏好向量之间的余弦相似度
  double _calculateVectorSimilarity(Map<String, double> vec1, Map<String, double> vec2) {
    final allKeys = {...vec1.keys, ...vec2.keys};
    if (allKeys.isEmpty) return 0.0;

    double dotProduct = 0.0;
    double norm1 = 0.0;
    double norm2 = 0.0;

    for (final key in allKeys) {
      final val1 = vec1[key] ?? 0.0;
      final val2 = vec2[key] ?? 0.0;

      dotProduct += val1 * val2;
      norm1 += val1 * val1;
      norm2 += val2 * val2;
    }

    final magnitude = (norm1 * norm2);
    return magnitude > 0 ? dotProduct / magnitude : 0.0;
  }

  /// 更新偏好向量
  PreferenceVector updateWith({
    Map<String, double>? tasteUpdate,
    Map<String, double>? cuisineUpdate,
    Map<String, double>? ingredientUpdate,
    Map<String, double>? scenarioUpdate,
    Map<String, double>? nutritionUpdate,
    Map<String, double>? difficultyUpdate,
    Map<String, double>? timeUpdate,
    Map<String, double>? emotionalUpdate,
    Map<String, double>? seasonalUpdate,
    Map<String, double>? weightUpdate,
    double? newConfidenceScore,
  }) {
    return PreferenceVector(
      tastePreferences: _mergePreferences(tastePreferences, tasteUpdate),
      cuisinePreferences: _mergePreferences(cuisinePreferences, cuisineUpdate),
      ingredientPreferences: _mergePreferences(ingredientPreferences, ingredientUpdate),
      scenarioPreferences: _mergePreferences(scenarioPreferences, scenarioUpdate),
      nutritionPreferences: _mergePreferences(nutritionPreferences, nutritionUpdate),
      difficultyPreferences: _mergePreferences(difficultyPreferences, difficultyUpdate),
      timePreferences: _mergePreferences(timePreferences, timeUpdate),
      emotionalPreferences: _mergePreferences(emotionalPreferences, emotionalUpdate),
      seasonalPreferences: _mergePreferences(seasonalPreferences, seasonalUpdate),
      dimensionWeights: _mergePreferences(dimensionWeights, weightUpdate),
      lastUpdated: DateTime.now(),
      confidenceScore: newConfidenceScore ?? confidenceScore,
    );
  }

  /// 合并偏好更新
  Map<String, double> _mergePreferences(
      Map<String, double> original, Map<String, double>? updates) {
    if (updates == null) return Map.from(original);

    final merged = Map<String, double>.from(original);
    for (final entry in updates.entries) {
      // 使用加权平均更新偏好值
      final currentValue = merged[entry.key] ?? 0.5;
      final newValue = entry.value;
      final learningRate = 0.1; // 学习率

      merged[entry.key] = currentValue * (1 - learningRate) + newValue * learningRate;
      merged[entry.key] = merged[entry.key]!.clamp(0.0, 1.0);
    }
    return merged;
  }

  /// 获取最强偏好
  Map<String, String> getTopPreferences({int limit = 5}) {
    final topPrefs = <String, String>{};

    final allPrefs = [
      ('口味', tastePreferences),
      ('菜系', cuisinePreferences),
      ('食材', ingredientPreferences),
      ('场景', scenarioPreferences),
      ('营养', nutritionPreferences),
      ('难度', difficultyPreferences),
      ('时间', timePreferences),
      ('情感', emotionalPreferences),
      ('季节', seasonalPreferences),
    ];

    for (final (category, prefs) in allPrefs) {
      if (prefs.isNotEmpty) {
        final sortedEntries = prefs.entries.toList()..sort((a, b) => b.value.compareTo(a.value));

        final topItems = sortedEntries.take(limit).map((e) => e.key).join(', ');
        if (topItems.isNotEmpty) {
          topPrefs[category] = topItems;
        }
      }
    }

    return topPrefs;
  }

  Map<String, dynamic> toJson() => {
        'tastePreferences': tastePreferences,
        'cuisinePreferences': cuisinePreferences,
        'ingredientPreferences': ingredientPreferences,
        'scenarioPreferences': scenarioPreferences,
        'nutritionPreferences': nutritionPreferences,
        'difficultyPreferences': difficultyPreferences,
        'timePreferences': timePreferences,
        'emotionalPreferences': emotionalPreferences,
        'seasonalPreferences': seasonalPreferences,
        'dimensionWeights': dimensionWeights,
        'lastUpdated': lastUpdated.toIso8601String(),
        'confidenceScore': confidenceScore,
      };

  factory PreferenceVector.fromJson(Map<String, dynamic> json) => PreferenceVector(
        tastePreferences: Map<String, double>.from(json['tastePreferences'] ?? {}),
        cuisinePreferences: Map<String, double>.from(json['cuisinePreferences'] ?? {}),
        ingredientPreferences: Map<String, double>.from(json['ingredientPreferences'] ?? {}),
        scenarioPreferences: Map<String, double>.from(json['scenarioPreferences'] ?? {}),
        nutritionPreferences: Map<String, double>.from(json['nutritionPreferences'] ?? {}),
        difficultyPreferences: Map<String, double>.from(json['difficultyPreferences'] ?? {}),
        timePreferences: Map<String, double>.from(json['timePreferences'] ?? {}),
        emotionalPreferences: Map<String, double>.from(json['emotionalPreferences'] ?? {}),
        seasonalPreferences: Map<String, double>.from(json['seasonalPreferences'] ?? {}),
        dimensionWeights: Map<String, double>.from(json['dimensionWeights'] ?? {}),
        lastUpdated: DateTime.parse(json['lastUpdated'] ?? DateTime.now().toIso8601String()),
        confidenceScore: (json['confidenceScore'] ?? 0.0).toDouble(),
      );

  /// 创建默认偏好向量
  factory PreferenceVector.defaultVector() => PreferenceVector(
        dimensionWeights: {
          'taste': 1.0,
          'cuisine': 0.8,
          'ingredient': 0.9,
          'scenario': 0.7,
          'nutrition': 0.6,
          'difficulty': 0.5,
          'time': 0.6,
          'emotional': 0.4,
          'seasonal': 0.3,
        },
        confidenceScore: 0.1,
      );
}

/// 用户偏好档案
class UserPreferenceProfile {
  final String userId;
  final PreferenceVector preferenceVector;
  final List<UserBehaviorData> recentBehaviors;
  final Map<String, dynamic> demographicInfo;
  final DateTime createdAt;
  final DateTime lastActiveAt;
  final int totalInteractions;
  final Map<String, int> actionCounts;

  UserPreferenceProfile({
    required this.userId,
    required this.preferenceVector,
    this.recentBehaviors = const [],
    this.demographicInfo = const {},
    DateTime? createdAt,
    DateTime? lastActiveAt,
    this.totalInteractions = 0,
    this.actionCounts = const {},
  })  : createdAt = createdAt ?? DateTime.now(),
        lastActiveAt = lastActiveAt ?? DateTime.now();

  /// 更新用户档案
  UserPreferenceProfile updateProfile({
    PreferenceVector? newPreferenceVector,
    UserBehaviorData? newBehavior,
    Map<String, dynamic>? demographicUpdate,
  }) {
    final updatedBehaviors = List<UserBehaviorData>.from(recentBehaviors);
    final updatedActionCounts = Map<String, int>.from(actionCounts);

    if (newBehavior != null) {
      updatedBehaviors.add(newBehavior);
      // 只保留最近100个行为
      if (updatedBehaviors.length > 100) {
        updatedBehaviors.removeRange(0, updatedBehaviors.length - 100);
      }

      // 更新行为计数
      final actionName = newBehavior.actionType.name;
      updatedActionCounts[actionName] = (updatedActionCounts[actionName] ?? 0) + 1;
    }

    final updatedDemographic = Map<String, dynamic>.from(demographicInfo);
    if (demographicUpdate != null) {
      updatedDemographic.addAll(demographicUpdate);
    }

    return UserPreferenceProfile(
      userId: userId,
      preferenceVector: newPreferenceVector ?? preferenceVector,
      recentBehaviors: updatedBehaviors,
      demographicInfo: updatedDemographic,
      createdAt: createdAt,
      lastActiveAt: DateTime.now(),
      totalInteractions: totalInteractions + (newBehavior != null ? 1 : 0),
      actionCounts: updatedActionCounts,
    );
  }

  /// 获取用户活跃度分数
  double getActivityScore() {
    final daysSinceCreated = DateTime.now().difference(createdAt).inDays;
    final daysSinceActive = DateTime.now().difference(lastActiveAt).inDays;

    if (daysSinceCreated == 0) return 1.0;

    final interactionRate = totalInteractions / daysSinceCreated;
    final recencyScore = (7 - daysSinceActive.clamp(0, 7)) / 7.0;

    return (interactionRate * 0.7 + recencyScore * 0.3).clamp(0.0, 1.0);
  }

  Map<String, dynamic> toJson() => {
        'userId': userId,
        'preferenceVector': preferenceVector.toJson(),
        'recentBehaviors': recentBehaviors.map((b) => b.toJson()).toList(),
        'demographicInfo': demographicInfo,
        'createdAt': createdAt.toIso8601String(),
        'lastActiveAt': lastActiveAt.toIso8601String(),
        'totalInteractions': totalInteractions,
        'actionCounts': actionCounts,
      };

  factory UserPreferenceProfile.fromJson(Map<String, dynamic> json) => UserPreferenceProfile(
        userId: json['userId'] ?? '',
        preferenceVector: PreferenceVector.fromJson(json['preferenceVector'] ?? {}),
        recentBehaviors: (json['recentBehaviors'] as List? ?? [])
            .map((b) => UserBehaviorData.fromJson(b))
            .toList(),
        demographicInfo: Map<String, dynamic>.from(json['demographicInfo'] ?? {}),
        createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
        lastActiveAt: DateTime.parse(json['lastActiveAt'] ?? DateTime.now().toIso8601String()),
        totalInteractions: json['totalInteractions'] ?? 0,
        actionCounts: Map<String, int>.from(json['actionCounts'] ?? {}),
      );
}
