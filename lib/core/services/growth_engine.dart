import 'package:flutter/foundation.dart';
import 'dart:async';

import '../utils/memory_manager.dart';

/// 用户增长策略类型
enum GrowthStrategy {
  viralSharing,      // 病毒式分享
  gamification,      // 游戏化
  socialProof,       // 社会证明
  contentMarketing,  // 内容营销
  referralProgram,   // 推荐计划
  retentionBoosts,   // 留存提升
}

/// 挑战类型
enum ChallengeType {
  bubbleChallenge,    // 气泡挑战
  tasteExploration,   // 口味探索
  cuisineAdventure,   // 菜系冒险
  healthyEating,      // 健康饮食
  socialSharing,      // 社交分享
  streakBuilding,     // 连续打卡
}

/// 成就类型
enum AchievementType {
  firstRecommendation,  // 首次推荐
  bubbleMaster,         // 气泡大师
  foodExplorer,         // 美食探索家
  socialInfluencer,     // 社交影响者
  healthGuru,           // 健康达人
  loyalUser,            // 忠实用户
}

/// 用户增长引擎 - 负责用户获取、激活、留存和推荐
class GrowthEngine {
  static final GrowthEngine _instance = GrowthEngine._internal();
  factory GrowthEngine() => _instance;
  GrowthEngine._internal();

  final MemoryManager _memoryManager = MemoryManager();
  
  // 增长数据
  final Map<String, UserGrowthProfile> _userProfiles = {};
  final Map<String, Challenge> _activeChallenges = {};
  final Map<String, Achievement> _achievements = {};
  final List<ShareableContent> _viralContent = [];
  
  // 增长统计
  final Map<GrowthStrategy, int> _strategyStats = {};
  final Map<String, ReferralProgram> _referralPrograms = {};
  
  bool _isInitialized = false;

  /// 初始化增长引擎
  Future<void> initialize() async {
    if (_isInitialized) return;

    await _loadChallenges();
    await _loadAchievements();
    await _loadReferralPrograms();
    await _generateViralContent();
    
    _isInitialized = true;
    debugPrint('GrowthEngine initialized');
  }

  /// 加载挑战活动
  Future<void> _loadChallenges() async {
    // 气泡挑战
    _activeChallenges['bubble_master'] = Challenge(
      id: 'bubble_master',
      type: ChallengeType.bubbleChallenge,
      title: '气泡大师挑战',
      description: '在一周内尝试选择50个不同的气泡',
      targetValue: 50,
      currentProgress: 0,
      reward: ChallengeReward(
        type: RewardType.badge,
        value: 'bubble_master_badge',
        description: '获得"气泡大师"徽章',
      ),
      startDate: DateTime.now(),
      endDate: DateTime.now().add(const Duration(days: 7)),
      isActive: true,
    );

    // 口味探索挑战
    _activeChallenges['taste_explorer'] = Challenge(
      id: 'taste_explorer',
      type: ChallengeType.tasteExploration,
      title: '口味探索家',
      description: '尝试10种不同风味的美食',
      targetValue: 10,
      currentProgress: 0,
      reward: ChallengeReward(
        type: RewardType.points,
        value: '500',
        description: '获得500积分奖励',
      ),
      startDate: DateTime.now(),
      endDate: DateTime.now().add(const Duration(days: 14)),
      isActive: true,
    );

    // 社交分享挑战
    _activeChallenges['social_sharer'] = Challenge(
      id: 'social_sharer',
      type: ChallengeType.socialSharing,
      title: '分享达人',
      description: '分享5次推荐给朋友',
      targetValue: 5,
      currentProgress: 0,
      reward: ChallengeReward(
        type: RewardType.premiumFeature,
        value: 'ai_personality_unlock',
        description: '解锁AI个性化功能',
      ),
      startDate: DateTime.now(),
      endDate: DateTime.now().add(const Duration(days: 30)),
      isActive: true,
    );
  }

  /// 加载成就系统
  Future<void> _loadAchievements() async {
    _achievements['first_recommendation'] = Achievement(
      id: 'first_recommendation',
      type: AchievementType.firstRecommendation,
      title: '首次推荐',
      description: '完成你的第一次美食推荐',
      icon: '🎯',
      rarity: AchievementRarity.common,
      pointsReward: 100,
      unlockedAt: null,
    );

    _achievements['bubble_master'] = Achievement(
      id: 'bubble_master',
      type: AchievementType.bubbleMaster,
      title: '气泡大师',
      description: '选择超过100个不同的气泡',
      icon: '🌟',
      rarity: AchievementRarity.rare,
      pointsReward: 1000,
      unlockedAt: null,
    );

    _achievements['food_explorer'] = Achievement(
      id: 'food_explorer',
      type: AchievementType.foodExplorer,
      title: '美食探索家',
      description: '尝试超过50种不同的美食',
      icon: '🍽️',
      rarity: AchievementRarity.epic,
      pointsReward: 2000,
      unlockedAt: null,
    );

    _achievements['social_influencer'] = Achievement(
      id: 'social_influencer',
      type: AchievementType.socialInfluencer,
      title: '社交影响者',
      description: '通过分享带来10个新用户',
      icon: '👑',
      rarity: AchievementRarity.legendary,
      pointsReward: 5000,
      unlockedAt: null,
    );
  }

  /// 加载推荐计划
  Future<void> _loadReferralPrograms() async {
    _referralPrograms['standard'] = ReferralProgram(
      id: 'standard',
      name: '好友推荐计划',
      description: '邀请好友获得奖励',
      referrerReward: ReferralReward(
        type: RewardType.points,
        value: '200',
        description: '每成功邀请一位好友获得200积分',
      ),
      refereeReward: ReferralReward(
        type: RewardType.premiumTrial,
        value: '7',
        description: '新用户获得7天高级会员试用',
      ),
      isActive: true,
      maxReferrals: 100,
    );
  }

  /// 生成病毒式传播内容
  Future<void> _generateViralContent() async {
    _viralContent.addAll([
      ShareableContent(
        id: 'recommendation_share',
        type: ShareContentType.recommendation,
        template: '我在《吃什么》发现了超棒的{foodName}！{emoji} AI推荐真的很准，你也来试试吧！',
        callToAction: '立即下载体验',
        deepLink: 'eatwhat://share/recommendation',
        viralScore: 8.5,
      ),
      ShareableContent(
        id: 'bubble_challenge',
        type: ShareContentType.challenge,
        template: '我在《吃什么》完成了{challengeName}挑战！🎉 快来跟我一起探索美食世界吧！',
        callToAction: '加入挑战',
        deepLink: 'eatwhat://challenge/{challengeId}',
        viralScore: 7.2,
      ),
      ShareableContent(
        id: 'achievement_unlock',
        type: ShareContentType.achievement,
        template: '🏆 刚刚解锁了"{achievementName}"成就！感觉自己就是美食专家！',
        callToAction: '看看你能解锁哪些成就',
        deepLink: 'eatwhat://achievements',
        viralScore: 6.8,
      ),
      ShareableContent(
        id: 'food_discovery',
        type: ShareContentType.discovery,
        template: '今天通过《吃什么》发现了{cuisineType}的隐藏美食！🤤 这个AI推荐太神奇了！',
        callToAction: '发现你的专属美食',
        deepLink: 'eatwhat://discover',
        viralScore: 8.0,
      ),
    ]);
  }

  /// 创建用户增长档案
  Future<UserGrowthProfile> createUserProfile(String userId) async {
    final profile = UserGrowthProfile(
      userId: userId,
      joinDate: DateTime.now(),
      totalPoints: 0,
      level: 1,
      streak: 0,
      longestStreak: 0,
      totalRecommendations: 0,
      totalShares: 0,
      referralCount: 0,
      achievementIds: [],
      completedChallengeIds: [],
      lastActiveDate: DateTime.now(),
    );

    _userProfiles[userId] = profile;
    
    // 欢迎奖励
    await _grantWelcomeRewards(userId);
    
    return profile;
  }

  /// 授予欢迎奖励
  Future<void> _grantWelcomeRewards(String userId) async {
    // 新用户积分奖励
    await addPoints(userId, 100, reason: '新用户欢迎奖励');
    
    // 激活新手挑战
    await _activateNewUserChallenges(userId);
  }

  /// 激活新用户挑战
  Future<void> _activateNewUserChallenges(String userId) async {
    // 为新用户激活特定挑战
    final newUserChallenges = _activeChallenges.values
        .where((challenge) => challenge.type == ChallengeType.bubbleChallenge)
        .toList();

    for (final challenge in newUserChallenges) {
      await _enrollUserInChallenge(userId, challenge.id);
    }
  }

  /// 用户参与挑战
  Future<void> _enrollUserInChallenge(String userId, String challengeId) async {
    final profile = _userProfiles[userId];
    if (profile != null && !profile.activeChallengeIds.contains(challengeId)) {
      profile.activeChallengeIds.add(challengeId);
      debugPrint('User $userId enrolled in challenge $challengeId');
    }
  }

  /// 记录用户行为（用于挑战进度和成就解锁）
  Future<List<GrowthEvent>> recordUserAction({
    required String userId,
    required UserAction action,
    Map<String, dynamic>? metadata,
  }) async {
    final profile = _userProfiles[userId];
    if (profile == null) return [];

    final events = <GrowthEvent>[];
    
    // 更新最后活跃时间
    profile.lastActiveDate = DateTime.now();
    
    // 根据行为类型处理
    switch (action) {
      case UserAction.bubbleSelection:
        await _handleBubbleSelection(userId, profile, metadata, events);
        break;
      case UserAction.foodRecommendation:
        await _handleFoodRecommendation(userId, profile, metadata, events);
        break;
      case UserAction.socialShare:
        await _handleSocialShare(userId, profile, metadata, events);
        break;
      case UserAction.referralSuccess:
        await _handleReferralSuccess(userId, profile, metadata, events);
        break;
      case UserAction.dailyLogin:
        await _handleDailyLogin(userId, profile, events);
        break;
      case UserAction.purchaseSubscription:
        // 处理订阅购买
        await addPoints(userId, 500, reason: '购买订阅');
        break;
      case UserAction.rateApp:
        // 处理应用评分
        await addPoints(userId, 100, reason: '应用评分');
        break;
    }

    // 检查成就解锁
    await _checkAchievementUnlocks(userId, profile, events);
    
    // 检查挑战完成
    await _checkChallengeCompletion(userId, profile, events);
    
    return events;
  }

  /// 处理气泡选择行为
  Future<void> _handleBubbleSelection(
    String userId,
    UserGrowthProfile profile,
    Map<String, dynamic>? metadata,
    List<GrowthEvent> events,
  ) async {
    profile.totalBubbleSelections++;
    
    // 更新气泡挑战进度
    await _updateChallengeProgress(
      userId, 
      ChallengeType.bubbleChallenge, 
      1, 
      events,
    );
    
    // 积分奖励
    await addPoints(userId, 5, reason: '气泡选择');
  }

  /// 处理美食推荐行为
  Future<void> _handleFoodRecommendation(
    String userId,
    UserGrowthProfile profile,
    Map<String, dynamic>? metadata,
    List<GrowthEvent> events,
  ) async {
    profile.totalRecommendations++;
    
    // 更新口味探索挑战
    await _updateChallengeProgress(
      userId,
      ChallengeType.tasteExploration,
      1,
      events,
    );
    
    // 积分奖励
    await addPoints(userId, 20, reason: '获得推荐');
    
    // 首次推荐成就
    if (profile.totalRecommendations == 1) {
      await _unlockAchievement(userId, 'first_recommendation', events);
    }
  }

  /// 处理社交分享行为
  Future<void> _handleSocialShare(
    String userId,
    UserGrowthProfile profile,
    Map<String, dynamic>? metadata,
    List<GrowthEvent> events,
  ) async {
    profile.totalShares++;
    
    // 更新分享挑战进度
    await _updateChallengeProgress(
      userId,
      ChallengeType.socialSharing,
      1,
      events,
    );
    
    // 积分奖励
    await addPoints(userId, 50, reason: '社交分享');
    
    // 记录增长策略效果
    _updateStrategyStats(GrowthStrategy.viralSharing);
  }

  /// 处理推荐成功
  Future<void> _handleReferralSuccess(
    String userId,
    UserGrowthProfile profile,
    Map<String, dynamic>? metadata,
    List<GrowthEvent> events,
  ) async {
    profile.referralCount++;
    
    // 推荐奖励
    final program = _referralPrograms['standard'];
    if (program != null) {
      await addPoints(userId, 200, reason: '成功推荐好友');
      
      events.add(GrowthEvent(
        type: GrowthEventType.referralReward,
        userId: userId,
        description: '成功推荐好友，获得奖励',
        timestamp: DateTime.now(),
      ));
    }
    
    _updateStrategyStats(GrowthStrategy.referralProgram);
  }

  /// 处理每日登录
  Future<void> _handleDailyLogin(
    String userId,
    UserGrowthProfile profile,
    List<GrowthEvent> events,
  ) async {
    final today = DateTime.now();
    final lastLogin = profile.lastActiveDate;
    
    // 检查是否连续登录
    if (_isSameDay(lastLogin, today.subtract(const Duration(days: 1)))) {
      profile.streak++;
      if (profile.streak > profile.longestStreak) {
        profile.longestStreak = profile.streak;
      }
    } else if (!_isSameDay(lastLogin, today)) {
      profile.streak = 1; // 重新开始连续登录
    }
    
    // 连续登录奖励
    final streakReward = _calculateStreakReward(profile.streak);
    if (streakReward > 0) {
      await addPoints(userId, streakReward, reason: '连续登录第${profile.streak}天');
      
      events.add(GrowthEvent(
        type: GrowthEventType.streakReward,
        userId: userId,
        description: '连续登录第${profile.streak}天，获得$streakReward积分',
        timestamp: DateTime.now(),
      ));
    }
  }

  /// 判断是否同一天
  bool _isSameDay(DateTime date1, DateTime date2) {
    return date1.year == date2.year &&
           date1.month == date2.month &&
           date1.day == date2.day;
  }

  /// 计算连续登录奖励
  int _calculateStreakReward(int streak) {
    if (streak <= 1) return 10;
    if (streak <= 7) return 20;
    if (streak <= 30) return 50;
    return 100;
  }

  /// 更新挑战进度
  Future<void> _updateChallengeProgress(
    String userId,
    ChallengeType challengeType,
    int progress,
    List<GrowthEvent> events,
  ) async {
    final profile = _userProfiles[userId];
    if (profile == null) return;

    for (final challengeId in profile.activeChallengeIds) {
      final challenge = _activeChallenges[challengeId];
      if (challenge != null && challenge.type == challengeType && challenge.isActive) {
        challenge.currentProgress += progress;
        
        events.add(GrowthEvent(
          type: GrowthEventType.challengeProgress,
          userId: userId,
          description: '${challenge.title} 进度 +$progress',
          timestamp: DateTime.now(),
        ));
        
        break; // 只更新一个匹配的挑战
      }
    }
  }

  /// 检查挑战完成
  Future<void> _checkChallengeCompletion(
    String userId,
    UserGrowthProfile profile,
    List<GrowthEvent> events,
  ) async {
    final completedChallenges = <String>[];
    
    for (final challengeId in profile.activeChallengeIds) {
      final challenge = _activeChallenges[challengeId];
      if (challenge != null && 
          challenge.currentProgress >= challenge.targetValue &&
          !profile.completedChallengeIds.contains(challengeId)) {
        
        // 标记挑战完成
        profile.completedChallengeIds.add(challengeId);
        completedChallenges.add(challengeId);
        
        // 授予奖励
        await _grantChallengeReward(userId, challenge, events);
        
        events.add(GrowthEvent(
          type: GrowthEventType.challengeCompleted,
          userId: userId,
          description: '完成挑战：${challenge.title}',
          timestamp: DateTime.now(),
        ));
      }
    }
    
    // 从活跃挑战中移除已完成的
    profile.activeChallengeIds.removeWhere(completedChallenges.contains);
  }

  /// 授予挑战奖励
  Future<void> _grantChallengeReward(
    String userId,
    Challenge challenge,
    List<GrowthEvent> events,
  ) async {
    switch (challenge.reward.type) {
      case RewardType.points:
        final points = int.tryParse(challenge.reward.value) ?? 0;
        await addPoints(userId, points, reason: '完成挑战奖励');
        break;
      case RewardType.badge:
        // 授予徽章
        break;
      case RewardType.premiumFeature:
        // 解锁高级功能
        break;
      case RewardType.premiumTrial:
        // 提供高级会员试用
        break;
    }
  }

  /// 解锁成就
  Future<void> _unlockAchievement(
    String userId,
    String achievementId,
    List<GrowthEvent> events,
  ) async {
    final profile = _userProfiles[userId];
    final achievement = _achievements[achievementId];
    
    if (profile != null && 
        achievement != null &&
        !profile.achievementIds.contains(achievementId)) {
      
      profile.achievementIds.add(achievementId);
      achievement.unlockedAt = DateTime.now();
      
      // 积分奖励
      await addPoints(userId, achievement.pointsReward, reason: '解锁成就');
      
      events.add(GrowthEvent(
        type: GrowthEventType.achievementUnlocked,
        userId: userId,
        description: '解锁成就：${achievement.title}',
        timestamp: DateTime.now(),
      ));
      
      debugPrint('Achievement unlocked for $userId: ${achievement.title}');
    }
  }

  /// 检查成就解锁
  Future<void> _checkAchievementUnlocks(
    String userId,
    UserGrowthProfile profile,
    List<GrowthEvent> events,
  ) async {
    // 气泡大师成就
    if (profile.totalBubbleSelections >= 100 && 
        !profile.achievementIds.contains('bubble_master')) {
      await _unlockAchievement(userId, 'bubble_master', events);
    }
    
    // 美食探索家成就
    if (profile.totalRecommendations >= 50 &&
        !profile.achievementIds.contains('food_explorer')) {
      await _unlockAchievement(userId, 'food_explorer', events);
    }
    
    // 社交影响者成就
    if (profile.referralCount >= 10 &&
        !profile.achievementIds.contains('social_influencer')) {
      await _unlockAchievement(userId, 'social_influencer', events);
    }
  }

  /// 添加积分
  Future<void> addPoints(String userId, int points, {required String reason}) async {
    final profile = _userProfiles[userId];
    if (profile != null) {
      profile.totalPoints += points;
      
      // 检查等级提升
      final newLevel = _calculateLevel(profile.totalPoints);
      if (newLevel > profile.level) {
        profile.level = newLevel;
        debugPrint('User $userId leveled up to $newLevel');
      }
      
      debugPrint('Added $points points to $userId ($reason)');
    }
  }

  /// 计算用户等级
  int _calculateLevel(int totalPoints) {
    // 简单的等级计算：每1000积分一个等级
    return (totalPoints / 1000).floor() + 1;
  }

  /// 生成分享内容
  Future<ShareableContent> generateShareContent({
    required String userId,
    required String contentType,
    Map<String, dynamic>? context,
  }) async {
    final templates = _viralContent
        .where((content) => content.type.toString().contains(contentType))
        .toList();
    
    if (templates.isEmpty) {
      return _getDefaultShareContent();
    }
    
    // 选择最佳模板
    final template = templates.reduce((a, b) => 
        a.viralScore > b.viralScore ? a : b);
    
    // 个性化内容
    String personalizedText = template.template;
    if (context != null) {
      context.forEach((key, value) {
        personalizedText = personalizedText.replaceAll('{$key}', value.toString());
      });
    }
    
    return ShareableContent(
      id: '${template.id}_${DateTime.now().millisecondsSinceEpoch}',
      type: template.type,
      template: personalizedText,
      callToAction: template.callToAction,
      deepLink: template.deepLink,
      viralScore: template.viralScore,
    );
  }

  /// 获取默认分享内容
  ShareableContent _getDefaultShareContent() {
    return ShareableContent(
      id: 'default_share',
      type: ShareContentType.general,
      template: '我在使用《吃什么》发现了很多美味！快来试试这个神奇的美食推荐app吧！',
      callToAction: '立即下载',
      deepLink: 'eatwhat://download',
      viralScore: 5.0,
    );
  }

  /// 更新策略统计
  void _updateStrategyStats(GrowthStrategy strategy) {
    _strategyStats[strategy] = (_strategyStats[strategy] ?? 0) + 1;
  }

  /// 获取用户增长档案
  UserGrowthProfile? getUserProfile(String userId) {
    return _userProfiles[userId];
  }

  /// 获取活跃挑战
  List<Challenge> getActiveChallenges() {
    return _activeChallenges.values
        .where((challenge) => challenge.isActive)
        .toList();
  }

  /// 获取用户成就
  List<Achievement> getUserAchievements(String userId) {
    final profile = _userProfiles[userId];
    if (profile == null) return [];
    
    return profile.achievementIds
        .map((id) => _achievements[id])
        .where((achievement) => achievement != null)
        .cast<Achievement>()
        .toList();
  }

  /// 获取增长统计
  Map<GrowthStrategy, int> getGrowthStats() {
    return Map.unmodifiable(_strategyStats);
  }
}

/// 用户行为类型
enum UserAction {
  bubbleSelection,
  foodRecommendation,
  socialShare,
  referralSuccess,
  dailyLogin,
  purchaseSubscription,
  rateApp,
}

/// 奖励类型
enum RewardType {
  points,           // 积分
  badge,           // 徽章
  premiumFeature,  // 高级功能
  premiumTrial,    // 高级试用
}

/// 成就稀有度
enum AchievementRarity {
  common,     // 普通
  rare,       // 稀有
  epic,       // 史诗
  legendary,  // 传说
}

/// 分享内容类型
enum ShareContentType {
  recommendation, // 推荐分享
  challenge,      // 挑战分享
  achievement,    // 成就分享
  discovery,      // 发现分享
  general,        // 通用分享
}

/// 增长事件类型
enum GrowthEventType {
  challengeProgress,    // 挑战进度
  challengeCompleted,   // 挑战完成
  achievementUnlocked,  // 成就解锁
  referralReward,      // 推荐奖励
  streakReward,        // 连续奖励
  levelUp,             // 等级提升
}

/// 用户增长档案
class UserGrowthProfile {
  final String userId;
  final DateTime joinDate;
  int totalPoints;
  int level;
  int streak;
  int longestStreak;
  int totalRecommendations;
  int totalShares;
  int referralCount;
  int totalBubbleSelections;
  final List<String> achievementIds;
  final List<String> completedChallengeIds;
  final List<String> activeChallengeIds;
  DateTime lastActiveDate;

  UserGrowthProfile({
    required this.userId,
    required this.joinDate,
    required this.totalPoints,
    required this.level,
    required this.streak,
    required this.longestStreak,
    required this.totalRecommendations,
    required this.totalShares,
    required this.referralCount,
    this.totalBubbleSelections = 0,
    required this.achievementIds,
    required this.completedChallengeIds,
    List<String>? activeChallengeIds,
    required this.lastActiveDate,
  }) : activeChallengeIds = activeChallengeIds ?? [];
}

/// 挑战
class Challenge {
  final String id;
  final ChallengeType type;
  final String title;
  final String description;
  final int targetValue;
  int currentProgress;
  final ChallengeReward reward;
  final DateTime startDate;
  final DateTime endDate;
  bool isActive;

  Challenge({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.targetValue,
    required this.currentProgress,
    required this.reward,
    required this.startDate,
    required this.endDate,
    required this.isActive,
  });

  double get progressPercentage => currentProgress / targetValue;
  bool get isCompleted => currentProgress >= targetValue;
  bool get isExpired => DateTime.now().isAfter(endDate);
}

/// 挑战奖励
class ChallengeReward {
  final RewardType type;
  final String value;
  final String description;

  ChallengeReward({
    required this.type,
    required this.value,
    required this.description,
  });
}

/// 成就
class Achievement {
  final String id;
  final AchievementType type;
  final String title;
  final String description;
  final String icon;
  final AchievementRarity rarity;
  final int pointsReward;
  DateTime? unlockedAt;

  Achievement({
    required this.id,
    required this.type,
    required this.title,
    required this.description,
    required this.icon,
    required this.rarity,
    required this.pointsReward,
    this.unlockedAt,
  });

  bool get isUnlocked => unlockedAt != null;
}

/// 推荐计划
class ReferralProgram {
  final String id;
  final String name;
  final String description;
  final ReferralReward referrerReward;
  final ReferralReward refereeReward;
  final bool isActive;
  final int maxReferrals;

  ReferralProgram({
    required this.id,
    required this.name,
    required this.description,
    required this.referrerReward,
    required this.refereeReward,
    required this.isActive,
    required this.maxReferrals,
  });
}

/// 推荐奖励
class ReferralReward {
  final RewardType type;
  final String value;
  final String description;

  ReferralReward({
    required this.type,
    required this.value,
    required this.description,
  });
}

/// 可分享内容
class ShareableContent {
  final String id;
  final ShareContentType type;
  final String template;
  final String callToAction;
  final String deepLink;
  final double viralScore;

  ShareableContent({
    required this.id,
    required this.type,
    required this.template,
    required this.callToAction,
    required this.deepLink,
    required this.viralScore,
  });
}

/// 增长事件
class GrowthEvent {
  final GrowthEventType type;
  final String userId;
  final String description;
  final DateTime timestamp;

  GrowthEvent({
    required this.type,
    required this.userId,
    required this.description,
    required this.timestamp,
  });
}