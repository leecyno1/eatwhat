import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 引导状态服务 - 管理新手引导的显示状态
class OnboardingService {
  factory OnboardingService() => _instance;
  OnboardingService._internal();

  static const String handfeelTutorialSeenKey = 'handfeel_tutorial_v1_seen';
  static const List<String> _legacySeenKeys = [
    'has_seen_onboarding_v2',
    'v2_home_generation_guide_seen',
  ];

  /// 单例模式
  static final OnboardingService _instance = OnboardingService._internal();

  /// 新版“开席三式”教学是否应该显示；任一旧标记为真时视为已看过。
  Future<bool> shouldShowHandfeelTutorial() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(handfeelTutorialSeenKey) ?? false) return false;
      for (final key in _legacySeenKeys) {
        if (prefs.getBool(key) ?? false) return false;
      }
      return true;
    } catch (error) {
      debugPrint('OnboardingService: 读取教学状态失败 - $error');
      return false;
    }
  }

  Future<void> markHandfeelTutorialSeen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(handfeelTutorialSeenKey, true);
    } catch (error) {
      debugPrint('OnboardingService: 写入教学状态失败 - $error');
    }
  }

  Future<void> resetHandfeelTutorial() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(handfeelTutorialSeenKey);
      for (final key in _legacySeenKeys) {
        await prefs.remove(key);
      }
    } catch (error) {
      debugPrint('OnboardingService: 重置教学状态失败 - $error');
    }
  }
}
