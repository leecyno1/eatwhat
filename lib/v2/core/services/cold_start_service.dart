import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/cold_start_questionnaire.dart';
import '../models/user_preference.dart';

/// 冷启动服务 - 处理问卷答案到味觉向量的映射
class ColdStartService {
  factory ColdStartService() => _instance;

  ColdStartService._internal();

  static const String _questionnaireKey = 'cold_start_questionnaire_completed';
  static const String _userPreferenceKey = 'user_preference_initialized';

  /// 单例模式
  static final ColdStartService _instance = ColdStartService._internal();

  /// 检查是否已完成冷启动问卷
  Future<bool> isQuestionnaireCompleted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_questionnaireKey) ?? false;
    } catch (e) {
      debugPrint('检查问卷状态失败: $e');
      return false;
    }
  }

  /// 标记问卷已完成
  Future<void> markQuestionnaireCompleted() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_questionnaireKey, true);
      debugPrint('冷启动问卷已完成');
    } catch (e) {
      debugPrint('标记问卷状态失败: $e');
    }
  }

  /// 重置问卷状态（用于调试）
  Future<void> resetQuestionnaireStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_questionnaireKey, false);
      await prefs.remove(_userPreferenceKey);
      debugPrint('已重置问卷状态');
    } catch (e) {
      debugPrint('重置问卷状态失败: $e');
    }
  }

  /// 根据问卷答案初始化用户偏好
  Future<UserPreference> initializeUserPreference(
    ColdStartQuestionnaireData questionnaireData,
  ) async {
    debugPrint('开始初始化用户偏好...');

    // 初始化空的偏好对象
    UserPreference preference = UserPreference(
      userId: 'default_user',
      cuisinePreferences: {},
      tastePreferences: {},
    );

    // 处理每个问题的答案
    for (final answer in questionnaireData.answers) {
      preference = _processAnswer(preference, answer);
    }

    // 标记用户偏好已初始化
    await _markUserPreferenceInitialized();

    debugPrint('用户偏好初始化完成: ${preference.cuisinePreferences}');
    debugPrint('口味偏好: ${preference.tastePreferences}');

    return preference;
  }

  /// 处理单个问题的答案
  UserPreference _processAnswer(
      UserPreference preference, ColdStartAnswer answer) {
    switch (answer.questionId) {
      case 1:
        // 菜系偏好
        return _processCuisinePreferences(preference, answer.selectedOptions);
      case 2:
        // 忌口偏好
        return _processDietaryRestrictions(preference, answer.selectedOptions);
      case 3:
        // 口味偏好
        return _processTastePreferences(preference, answer.selectedOptions);
      case 4:
        // 用餐场景
        return _processDiningScenario(preference, answer.singleOption);
      case 5:
        // 用餐人数
        return _processDiningPartySize(preference, answer.singleOption);
      case 6:
        // 用餐时间
        return _processDiningTime(preference, answer.singleOption);
      case 7:
        // 预算
        return _processDiningBudget(preference, answer.singleOption);
      case 8:
        // 心情
        return _processDiningMood(preference, answer.singleOption);
      default:
        return preference;
    }
  }

  /// 处理菜系偏好
  UserPreference _processCuisinePreferences(
    UserPreference preference,
    List<String> cuisines,
  ) {
    // 菜系到口味的映射
    final cuisineTasteMapping = {
      '川菜': {'辣': 1.5, '麻辣': 1.5, '重口味': 1.0},
      '湘菜': {'辣': 1.5, '香辣': 1.0, '重口味': 0.8},
      '粤菜': {'清淡': 1.5, '鲜': 1.0, '甜': 0.5},
      '苏菜': {'清淡': 1.5, '甜': 0.8, '鲜': 0.8},
      '鲁菜': {'咸': 1.0, '鲜': 0.8, '浓郁': 0.8},
      '闽菜': {'鲜': 1.5, '清淡': 1.0, '甜': 0.5},
      '浙菜': {'鲜': 1.2, '甜': 0.8, '清淡': 0.8},
      '徽菜': {'咸': 1.0, '鲜': 0.8, '重口味': 0.8},
      '西餐': {'浓郁': 1.0, '奶酪': 1.0, '蒜香': 0.8},
      '日料': {'清淡': 1.5, '鲜': 1.5, '甜': 0.5},
      '韩料': {'辣': 1.2, '酸': 0.8, '咸': 0.8},
    };

    UserPreference result = preference;

    for (final cuisine in cuisines) {
      // 更新菜系偏好分数
      result = result.updateCuisinePreference(cuisine, 2.0);

      // 根据菜系更新口味偏好
      final tasteMapping = cuisineTasteMapping[cuisine];
      if (tasteMapping != null) {
        for (final entry in tasteMapping.entries) {
          result = result.updateTastePreference(entry.key, entry.value);
        }
      }
    }

    return result;
  }

  /// 处理忌口偏好
  UserPreference _processDietaryRestrictions(
    UserPreference preference,
    List<String> restrictions,
  ) {
    // 忌口到排除项的映射
    final restrictionMapping = {
      '无忌口': {},
      '海鲜过敏': {'海鲜': -5.0, '海鲜鲜': -5.0},
      '芒果过敏': {'芒果': -5.0, '热带果': -3.0},
      '乳糖不耐': {'奶酪': -4.0, '奶油': -4.0, '牛奶': -3.0, '奶酪浓': -4.0},
      '素食': {'素菜': 2.0, '素食': 2.0, '植物基': 1.5},
      '清真': {'清真': 2.0, 'halal': 2.0},
    };

    UserPreference result = preference;

    for (final restriction in restrictions) {
      final mapping = restrictionMapping[restriction];
      if (mapping != null) {
        for (final entry in mapping.entries) {
          result = result.updateTastePreference(entry.key, entry.value);
        }
      }
    }

    return result;
  }

  /// 处理口味偏好
  UserPreference _processTastePreferences(
    UserPreference preference,
    List<String> tastes,
  ) {
    // 口味选项到味觉向量的映射
    final tasteMapping = {
      '辣': {'辣': 1.5, '麻辣': 1.0, '香辣': 1.0},
      '微辣': {'辣': 0.8, '麻辣': 0.5, '香辣': 0.5},
      '不辣': {'清淡': 1.5, '鲜': 1.0},
      '酸': {'酸': 1.5, '柠檬': 1.0, '酸奶': 1.0},
      '甜': {'甜': 1.5, '焦糖': 1.0, '蜂蜜': 1.0},
      '苦': {'苦': 1.5, '咖啡': 1.0, '可可': 1.0},
      '咸': {'咸': 1.5, '海盐': 1.0, '酱油': 1.0},
      '鲜': {'鲜': 1.5, '菌菇': 1.0, '鸡汤': 1.0},
    };

    UserPreference result = preference;

    for (final taste in tastes) {
      final mapping = tasteMapping[taste];
      if (mapping != null) {
        for (final entry in mapping.entries) {
          result = result.updateTastePreference(entry.key, entry.value);
        }
      }
    }

    return result;
  }

  /// 处理用餐场景
  UserPreference _processDiningScenario(
    UserPreference preference,
    String? scenario,
  ) {
    if (scenario == null) return preference;

    // 用餐场景到食材/菜系的映射
    final scenarioMapping = {
      '在家做饭': {
        '场景_家常': 2.0,
        '低脂': 1.0,
        '健康': 1.0,
      },
      '外卖': {
        '场景_外卖': 2.0,
        '快餐': 1.0,
        '便捷': 1.0,
      },
      '堂食': {
        '场景_餐厅': 2.0,
        '精致': 1.0,
        '聚会': 1.0,
      },
      '都可以': {}, // 不做特殊处理
    };

    final mapping = scenarioMapping[scenario];
    if (mapping != null) {
      UserPreference result = preference;
      for (final entry in mapping.entries) {
        result = result.updateTastePreference(entry.key, entry.value);
      }
      return result;
    }

    return preference;
  }

  /// 处理用餐人数
  UserPreference _processDiningPartySize(
    UserPreference preference,
    String? partySize,
  ) {
    if (partySize == null) return preference;

    final partySizeMapping = {
      '1人': {
        '人数_小份': 1.5,
        '一人食': 1.5,
        '简餐': 1.0,
      },
      '2-3人': {
        '人数_小份': 1.2,
        '家常': 1.2,
        '分享': 0.8,
      },
      '4-6人': {
        '人数_多人': 1.5,
        '聚餐': 1.2,
        '下饭': 1.0,
      },
      '6人以上': {
        '人数_多人': 2.0,
        '聚会': 1.5,
        '大份': 1.5,
      },
    };

    return _applyTasteMapping(preference, partySizeMapping[partySize]);
  }

  /// 处理用餐时间
  UserPreference _processDiningTime(
    UserPreference preference,
    String? timeLimit,
  ) {
    if (timeLimit == null) return preference;

    final timeMapping = {
      '15 分钟内': {
        '时间_快手': 2.0,
        '快餐': 1.2,
        '少步骤': 1.2,
      },
      '20 分钟内': {
        '时间_快手': 1.6,
        '家常快手': 1.2,
        '简单': 1.0,
      },
      '30 分钟内': {
        '时间_适中': 1.4,
        '家常': 1.0,
      },
      '不着急': {
        '时间_从容': 1.4,
        '炖煮': 1.0,
        '仪式感': 0.8,
      },
    };

    return _applyTasteMapping(preference, timeMapping[timeLimit]);
  }

  /// 处理预算
  UserPreference _processDiningBudget(
    UserPreference preference,
    String? budget,
  ) {
    if (budget == null) return preference;

    final budgetMapping = {
      '30 元内': {
        '预算_经济': 1.8,
        '家常': 1.0,
        '实惠': 1.4,
      },
      '30-60 元': {
        '预算_日常': 1.5,
        '均衡': 1.0,
      },
      '60-100 元': {
        '预算_改善': 1.5,
        '精致': 1.0,
        '肉菜': 0.8,
      },
      '想吃好一点': {
        '预算_品质': 1.8,
        '招牌': 1.2,
        '精致': 1.2,
      },
    };

    return _applyTasteMapping(preference, budgetMapping[budget]);
  }

  /// 处理心情
  UserPreference _processDiningMood(
    UserPreference preference,
    String? mood,
  ) {
    if (mood == null) return preference;

    final moodMapping = {
      '想吃热乎': {
        '心情_暖胃': 1.8,
        '热菜': 1.4,
        '汤': 1.0,
      },
      '想清爽点': {
        '心情_清爽': 1.8,
        '清淡': 1.2,
        '低脂': 1.0,
      },
      '想解压': {
        '心情_解压': 1.8,
        '满足感': 1.3,
        '重口味': 0.8,
      },
      '想冒险': {
        '心情_探索': 1.8,
        '新奇': 1.2,
        '异域': 1.0,
      },
    };

    return _applyTasteMapping(preference, moodMapping[mood]);
  }

  UserPreference _applyTasteMapping(
    UserPreference preference,
    Map<String, double>? mapping,
  ) {
    if (mapping == null) return preference;

    UserPreference result = preference;
    for (final entry in mapping.entries) {
      result = result.updateTastePreference(entry.key, entry.value);
    }
    return result;
  }

  /// 标记用户偏好已初始化
  Future<void> _markUserPreferenceInitialized() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_userPreferenceKey, true);
    } catch (e) {
      debugPrint('标记用户偏好初始化失败: $e');
    }
  }

  /// 检查用户偏好是否已初始化
  Future<bool> isUserPreferenceInitialized() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_userPreferenceKey) ?? false;
    } catch (e) {
      debugPrint('检查用户偏好初始化状态失败: $e');
      return false;
    }
  }
}
