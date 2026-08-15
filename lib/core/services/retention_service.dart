import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// 用户留存追踪服务
class RetentionService {
  static final RetentionService _instance = RetentionService._internal();
  factory RetentionService() => _instance;

  RetentionService._internal();

  /// 记录用户首次启动日期
  Future<void> recordFirstLaunch(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'first_launch_$userId';
    if (!prefs.containsKey(key)) {
      await prefs.setString(key, DateTime.now().toIso8601String());
      debugPrint('[RetentionService] 记录用户首次启动: $userId');
    }
  }

  /// 获取用户首次启动日期
  Future<DateTime?> getFirstLaunchDate(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'first_launch_$userId';
    final value = prefs.getString(key);
    if (value != null) {
      return DateTime.parse(value);
    }
    return null;
  }

  /// 获取用户注册天数
  Future<int> getUserAge(String userId) async {
    final firstLaunch = await getFirstLaunchDate(userId);
    if (firstLaunch == null) return 0;
    return DateTime.now().difference(firstLaunch).inDays;
  }

  /// 判断用户是否是 N 天前注册的
  Future<bool> isRegisteredDaysAgo(String userId, int days) async {
    final firstLaunch = await getFirstLaunchDate(userId);
    if (firstLaunch == null) return false;
    final daysSinceRegistration = DateTime.now().difference(firstLaunch).inDays;
    return daysSinceRegistration >= days;
  }

  /// 计算指定日的留存率
  /// [registeredUsers] 注册用户数
  /// [retainedUsers] 留存用户数
  double calculateRetentionRate(int registeredUsers, int retainedUsers) {
    if (registeredUsers == 0) return 0;
    return retainedUsers / registeredUsers;
  }

  /// 批量计算多日留存率
  Map<int, double> calculateMultiDayRetention(
    Map<int, int> registeredByDay,
    Map<int, int> retainedByDay,
  ) {
    final rates = <int, double>{};
    for (final day in registeredByDay.keys) {
      final registered = registeredByDay[day] ?? 0;
      final retained = retainedByDay[day] ?? 0;
      rates[day] = calculateRetentionRate(registered, retained);
    }
    return rates;
  }

  /// 获取次日留存率
  Future<double> getDay1Retention() async {
    // 这需要聚合数据，实际实现应该从 MetricsService 获取
    // 这里提供接口，由 MetricsService 调用
    return 0;
  }

  /// 获取第 7 天留存率
  Future<double> getDay7Retention() async {
    return 0;
  }

  /// 获取第 30 天留存率
  Future<double> getDay30Retention() async {
    return 0;
  }

  /// 清除用户留存数据（用于测试）
  Future<void> clearUserData(String userId) async {
    final prefs = await SharedPreferences.getInstance();
    final key = 'first_launch_$userId';
    await prefs.remove(key);
  }

  /// 清除所有留存数据（用于测试）
  Future<void> clearAll() async {
    final prefs = await SharedPreferences.getInstance();
    final keys = prefs.getKeys().where((k) => k.startsWith('first_launch_'));
    for (final key in keys) {
      await prefs.remove(key);
    }
  }
}
