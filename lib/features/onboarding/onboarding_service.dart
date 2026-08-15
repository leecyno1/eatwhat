import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 引导状态服务 - 管理新手引导的显示状态
class OnboardingService {
  static const String _hasSeenOnboardingKey = 'has_seen_onboarding';

  /// 单例模式
  static final OnboardingService _instance = OnboardingService._internal();
  factory OnboardingService() => _instance;
  OnboardingService._internal();

  /// 检查是否应该显示新手引导
  Future<bool> shouldShowOnboarding() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final hasSeen = prefs.getBool(_hasSeenOnboardingKey) ?? false;
      debugPrint('OnboardingService: 检查引导状态 - hasSeenOnboarding = $hasSeen');
      return !hasSeen;
    } catch (e) {
      debugPrint('OnboardingService: 检查引导状态失败 - $e');
      return false;
    }
  }

  /// 标记已看过引导
  Future<void> markOnboardingAsSeen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_hasSeenOnboardingKey, true);
      debugPrint('OnboardingService: 已标记引导为已看过');
    } catch (e) {
      debugPrint('OnboardingService: 标记引导状态失败 - $e');
    }
  }

  /// 重置引导状态（用于测试或重新显示引导）
  Future<void> resetOnboardingStatus() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_hasSeenOnboardingKey);
      debugPrint('OnboardingService: 已重置引导状态');
    } catch (e) {
      debugPrint('OnboardingService: 重置引导状态失败 - $e');
    }
  }
}
