import 'package:flutter/foundation.dart';
import 'dart:async';
import '../utils/memory_manager.dart';
import 'ai_service.dart';

/// 美食人格类型
enum FoodPersonality {
  gourmetChef,    // 美食大厨 - 专业严谨
  cuteHelper,     // 萌宠助手 - 可爱活泼  
  wiseMaster,     // 养生大师 - 健康专业
  trendyFriend,   // 潮流达人 - 时尚年轻
  homelyMom,      // 居家妈妈 - 温暖贴心
}

/// 用户场景类型
enum FoodScenario {
  lateNightSnack,    // 深夜食堂
  fitnessRecovery,   // 健身餐
  dateNight,         // 情侣约会
  familyGathering,   // 家庭聚餐
  businessMeal,      // 商务用餐
  hangoverCure,      // 解酒醒胃
  comfortFood,       // 心情调节
  quickBite,         // 快速充饥
  healthyChoice,     // 健康选择
  celebrationMeal,   // 庆祝大餐
}

/// 个性化AI服务 - 提供拟人化的美食推荐体验
class PersonalityAiService {
  static final PersonalityAiService _instance = PersonalityAiService._internal();
  factory PersonalityAiService() => _instance;
  PersonalityAiService._internal();

  final AiService _aiService = AiService();
  final MemoryManager _memoryManager = MemoryManager();
  
  // 用户个性档案缓存
  final Map<String, FoodPersonality> _userPersonalities = {};
  final Map<String, Map<String, dynamic>> _userContexts = {};

  /// 初始化个性化AI服务
  Future<void> initialize() async {
    await _aiService.init();
    debugPrint('PersonalityAiService initialized');
  }

  /// 根据用户资料确定AI人格
  FoodPersonality determinePersonality(EnhancedUserProfile user) {
    final cacheKey = 'personality_${user.userId}';
    final cached = _memoryManager.getCached<FoodPersonality>(cacheKey);
    if (cached != null) return cached;

    FoodPersonality personality;

    // 基于用户画像智能选择人格
    if (user.age != null && user.age! < 25) {
      personality = user.gender == 'female' ? FoodPersonality.cuteHelper : FoodPersonality.trendyFriend;
    } else if (user.healthGoals.isNotEmpty) {
      personality = FoodPersonality.wiseMaster;
    } else if (user.workoutFrequency > 3) {
      personality = FoodPersonality.wiseMaster;
    } else if (user.prefersGroupDining) {
      personality = FoodPersonality.homelyMom;
    } else {
      personality = FoodPersonality.gourmetChef;
    }

    _memoryManager.cache(cacheKey, personality, duration: const Duration(days: 7));
    _userPersonalities[user.userId] = personality;
    
    debugPrint('Determined personality for ${user.userId}: $personality');
    return personality;
  }

  /// 检测当前使用场景
  FoodScenario detectCurrentScenario(EnhancedUserProfile user) {
    final now = DateTime.now();
    final hour = now.hour;
    final isWeekend = now.weekday >= 6;
    
    // 时间场景判断
    if (hour >= 23 || hour <= 2) {
      return FoodScenario.lateNightSnack;
    } else if (hour >= 6 && hour <= 9) {
      return _getBreakfastScenario(user);
    } else if (hour >= 11 && hour <= 14) {
      return _getLunchScenario(user, isWeekend);
    } else if (hour >= 17 && hour <= 21) {
      return _getDinnerScenario(user, isWeekend);
    }
    
    // 活动场景判断
    if (user.currentActivity == 'workout') {
      return FoodScenario.fitnessRecovery;
    } else if (user.currentMood == 'romantic' && user.prefersGroupDining) {
      return FoodScenario.dateNight;
    } else if (user.currentMood == 'stressed') {
      return FoodScenario.comfortFood;
    } else if (user.currentMood == 'celebratory') {
      return FoodScenario.celebrationMeal;
    }
    
    return FoodScenario.quickBite;
  }

  FoodScenario _getBreakfastScenario(EnhancedUserProfile user) {
    if (user.healthGoals.contains('减脂') || user.healthGoals.contains('健康')) {
      return FoodScenario.healthyChoice;
    }
    return FoodScenario.quickBite;
  }

  FoodScenario _getLunchScenario(EnhancedUserProfile user, bool isWeekend) {
    if (!isWeekend && user.currentActivity == 'work') {
      return FoodScenario.businessMeal;
    } else if (isWeekend && user.prefersGroupDining) {
      return FoodScenario.familyGathering;
    }
    return FoodScenario.quickBite;
  }

  FoodScenario _getDinnerScenario(EnhancedUserProfile user, bool isWeekend) {
    if (user.prefersGroupDining) {
      return FoodScenario.familyGathering;
    } else if (user.currentMood == 'romantic') {
      return FoodScenario.dateNight;
    }
    return FoodScenario.comfortFood;
  }

  /// 生成个性化推荐对话
  Future<PersonalizedRecommendation> generatePersonalizedRecommendation({
    required String foodName,
    required List<String> matchedBubbles,
    required double matchScore,
    required EnhancedUserProfile user,
  }) async {
    final personality = determinePersonality(user);
    final scenario = detectCurrentScenario(user);
    
    final cacheKey = 'rec_${foodName}_${personality.name}_${scenario.name}';
    final cached = _memoryManager.getCached<PersonalizedRecommendation>(cacheKey);
    if (cached != null) return cached;

    try {
      final dialogue = await _generatePersonalizedDialogue(
        foodName: foodName,
        matchedBubbles: matchedBubbles,
        matchScore: matchScore,
        personality: personality,
        scenario: scenario,
        user: user,
      );

      final recommendation = PersonalizedRecommendation(
        foodName: foodName,
        dialogue: dialogue,
        personality: personality,
        scenario: scenario,
        matchScore: matchScore,
        matchedBubbles: matchedBubbles,
        tips: _getScenarioTips(foodName, scenario),
        encouragement: _getPersonalityEncouragement(personality),
        timestamp: DateTime.now(),
      );

      _memoryManager.cache(cacheKey, recommendation, duration: const Duration(hours: 2));
      return recommendation;
    } catch (e) {
      debugPrint('Error generating personalized recommendation: $e');
      return _getFallbackRecommendation(foodName, matchedBubbles, matchScore, personality, scenario);
    }
  }

  /// 生成个性化对话内容
  Future<String> _generatePersonalizedDialogue({
    required String foodName,
    required List<String> matchedBubbles,
    required double matchScore,
    required FoodPersonality personality,
    required FoodScenario scenario,
    required EnhancedUserProfile user,
  }) async {
    final prompt = _buildPersonalityPrompt(
      foodName: foodName,
      matchedBubbles: matchedBubbles,
      matchScore: matchScore,
      personality: personality,
      scenario: scenario,
      user: user,
    );

    try {
      final response = await _aiService.getBubbleRecommendations(
        selectedBubbles: matchedBubbles,
        availableFoods: [foodName],
        userPreferences: _buildUserContext(user),
        timeOfDay: _getTimeContext(),
        weather: user.currentWeather,
      );
      
      return _formatPersonalizedResponse(response.reasons, personality);
    } catch (e) {
      return _getFallbackDialogue(foodName, personality, scenario);
    }
  }

  /// 构建个性化提示词
  String _buildPersonalityPrompt({
    required String foodName,
    required List<String> matchedBubbles,
    required double matchScore,
    required FoodPersonality personality,
    required FoodScenario scenario,
    required EnhancedUserProfile user,
  }) {
    final personalityContext = _getPersonalityContext(personality);
    final scenarioContext = _getScenarioContext(scenario);
    final userContext = _buildUserContext(user);
    
    return '''
作为一个${personalityContext['name']}，请用${personalityContext['style']}的语气为用户推荐「$foodName」。

当前场景：${scenarioContext['description']}
用户偏好：${matchedBubbles.join('、')}
匹配度：${matchScore.toStringAsFixed(1)}分
用户信息：$userContext

请按照以下格式回复：
1. 个性化问候语
2. 场景感知的推荐理由
3. 食物特色介绍
4. 实用建议
5. 鼓励性结语

语气要求：${personalityContext['tone']}
长度：100-150字
''';
  }

  /// 获取人格上下文
  Map<String, String> _getPersonalityContext(FoodPersonality personality) {
    switch (personality) {
      case FoodPersonality.cuteHelper:
        return {
          'name': '萌宠助手',
          'style': '可爱活泼',
          'tone': '使用萌萌的语气，多用颜文字和可爱的表达方式',
          'greeting': '主人～',
          'encouragement': '相信你会喜欢的哦！(＾◡＾)',
        };
      case FoodPersonality.gourmetChef:
        return {
          'name': '美食大厨',
          'style': '专业严谨',
          'tone': '用专业的厨师语气，展现烹饪专业知识',
          'greeting': '尊敬的食客',
          'encouragement': '这道菜绝对不会让您失望',
        };
      case FoodPersonality.wiseMaster:
        return {
          'name': '养生大师',
          'style': '健康专业',
          'tone': '注重营养搭配和健康理念',
          'greeting': '亲爱的朋友',
          'encouragement': '健康饮食，从这一餐开始',
        };
      case FoodPersonality.trendyFriend:
        return {
          'name': '潮流达人',
          'style': '时尚年轻',
          'tone': '用年轻人的语言，充满活力和潮流感',
          'greeting': 'Hey',
          'encouragement': '这绝对是最in的选择！',
        };
      case FoodPersonality.homelyMom:
        return {
          'name': '居家妈妈',
          'style': '温暖贴心',
          'tone': '像妈妈一样温暖关怀，注重营养和家庭感',
          'greeting': '孩子',
          'encouragement': '记得要好好吃饭哦',
        };
    }
  }

  /// 获取场景上下文
  Map<String, String> _getScenarioContext(FoodScenario scenario) {
    switch (scenario) {
      case FoodScenario.lateNightSnack:
        return {
          'description': '深夜时光',
          'awareness': '注意到您在深夜还在觅食',
          'tip': '建议选择清淡易消化的食物',
        };
      case FoodScenario.fitnessRecovery:
        return {
          'description': '健身后补充',
          'awareness': '刚结束运动的您',
          'tip': '建议补充优质蛋白质和复合碳水',
        };
      case FoodScenario.dateNight:
        return {
          'description': '浪漫约会',
          'awareness': '为您的浪漫时光',
          'tip': '建议选择精致优雅的料理',
        };
      case FoodScenario.familyGathering:
        return {
          'description': '家庭聚餐',
          'awareness': '温馨的家庭时光',
          'tip': '建议选择老少皆宜的家常菜',
        };
      case FoodScenario.businessMeal:
        return {
          'description': '商务用餐',
          'awareness': '忙碌的工作间隙',
          'tip': '建议选择不易溅洒的食物',
        };
      default:
        return {
          'description': '日常用餐',
          'awareness': '为您的用餐时光',
          'tip': '建议根据个人喜好选择',
        };
    }
  }

  /// 构建用户上下文
  String _buildUserContext(EnhancedUserProfile user) {
    final contexts = <String>[];
    
    if (user.age != null) contexts.add('年龄${user.age}岁');
    if (user.healthGoals.isNotEmpty) contexts.add('健康目标：${user.healthGoals.join('、')}');
    if (user.allergies.isNotEmpty) contexts.add('过敏：${user.allergies.join('、')}');
    if (user.currentMood != null) contexts.add('心情：${user.currentMood}');
    
    return contexts.join('，');
  }

  /// 获取时间上下文
  String _getTimeContext() {
    final hour = DateTime.now().hour;
    if (hour < 6) return '凌晨';
    if (hour < 9) return '早晨';
    if (hour < 12) return '上午';
    if (hour < 14) return '中午';
    if (hour < 18) return '下午';
    if (hour < 22) return '晚上';
    return '深夜';
  }

  /// 格式化个性化回复
  String _formatPersonalizedResponse(String response, FoodPersonality personality) {
    final context = _getPersonalityContext(personality);
    
    // 添加人格化的开头和结尾
    return '${context['greeting']}！\n\n$response\n\n${context['encouragement']}';
  }

  /// 获取场景提示
  String _getScenarioTips(String foodName, FoodScenario scenario) {
    switch (scenario) {
      case FoodScenario.lateNightSnack:
        return '深夜进食建议小份量，避免过于油腻';
      case FoodScenario.fitnessRecovery:
        return '运动后30分钟内补充效果最佳';
      case FoodScenario.dateNight:
        return '建议搭配红酒或茶品，营造浪漫氛围';
      case FoodScenario.familyGathering:
        return '可以准备大份量，方便分享';
      case FoodScenario.businessMeal:
        return '建议选择容易用餐具的食物';
      default:
        return '记得细嚼慢咽，享受美食时光';
    }
  }

  /// 获取人格鼓励语
  String _getPersonalityEncouragement(FoodPersonality personality) {
    final context = _getPersonalityContext(personality);
    return context['encouragement']!;
  }

  /// 获取备用对话
  String _getFallbackDialogue(String foodName, FoodPersonality personality, FoodScenario scenario) {
    final personalityContext = _getPersonalityContext(personality);
    final scenarioContext = _getScenarioContext(scenario);
    
    return '''
${personalityContext['greeting']}！

${scenarioContext['awareness']}，我为您推荐「$foodName」。这道美食的特色在于其独特的口感和丰富的营养价值。

💡 ${scenarioContext['tip']}

${personalityContext['encouragement']}
''';
  }

  /// 获取备用推荐
  PersonalizedRecommendation _getFallbackRecommendation(
    String foodName,
    List<String> matchedBubbles,
    double matchScore,
    FoodPersonality personality,
    FoodScenario scenario,
  ) {
    return PersonalizedRecommendation(
      foodName: foodName,
      dialogue: _getFallbackDialogue(foodName, personality, scenario),
      personality: personality,
      scenario: scenario,
      matchScore: matchScore,
      matchedBubbles: matchedBubbles,
      tips: _getScenarioTips(foodName, scenario),
      encouragement: _getPersonalityEncouragement(personality),
      timestamp: DateTime.now(),
    );
  }
}

/// 增强用户档案
class EnhancedUserProfile {
  final String userId;
  final int? age;
  final String? gender;
  final String location;
  
  // 健康数据
  final double? bmi;
  final List<String> allergies;
  final List<String> healthGoals;
  
  // 生活作息
  final Map<String, String> mealTimes; // 时间字符串，如 "12:30"
  final int sleepHours;
  final int workoutFrequency;
  
  // 社交偏好
  final bool prefersGroupDining;
  final List<String> favoriteCuisines;
  final double spiceLevel;
  
  // 环境感知
  final String? currentWeather;
  final String? currentMood;
  final String? currentActivity;
  
  // 行为数据
  final Map<String, int> bubbleInteractionCount;
  final Map<String, double> timeBasedPreferences;

  EnhancedUserProfile({
    required this.userId,
    this.age,
    this.gender,
    required this.location,
    this.bmi,
    required this.allergies,
    required this.healthGoals,
    required this.mealTimes,
    required this.sleepHours,
    required this.workoutFrequency,
    required this.prefersGroupDining,
    required this.favoriteCuisines,
    required this.spiceLevel,
    this.currentWeather,
    this.currentMood,
    this.currentActivity,
    required this.bubbleInteractionCount,
    required this.timeBasedPreferences,
  });
}

/// 个性化推荐结果
class PersonalizedRecommendation {
  final String foodName;
  final String dialogue;
  final FoodPersonality personality;
  final FoodScenario scenario;
  final double matchScore;
  final List<String> matchedBubbles;
  final String tips;
  final String encouragement;
  final DateTime timestamp;

  PersonalizedRecommendation({
    required this.foodName,
    required this.dialogue,
    required this.personality,
    required this.scenario,
    required this.matchScore,
    required this.matchedBubbles,
    required this.tips,
    required this.encouragement,
    required this.timestamp,
  });
}