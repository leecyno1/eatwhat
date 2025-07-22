import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/user_preference.dart';
import '../models/food.dart';
import '../models/bubble.dart';

/// 本地存储服务
/// 负责所有应用数据的持久化存储，使用Hive。
class StorageService {
  static const String _userPreferenceBoxName = 'user_preference_box';
  static const String _favoriteBoxName = 'favorite_foods';
  static const String _historyBoxName = 'food_history';
  static const String _bubbleStateBoxName = 'bubble_states';
  static const String _appSettingsBoxName = 'app_settings';

  static late Box<UserPreference> _userPreferenceBox;
  static late Box _favoriteBox;
  static late Box _historyBox;
  static late Box _bubbleStateBox;
  static late Box _appSettingsBox;

  /// 初始化存储服务
  static Future<void> initialize() async {
    try {
      await Hive.initFlutter();

      // 注册所有需要存储的适配器
      Hive.registerAdapter(UserPreferenceAdapter());

      // 打开所有需要的Box
      _userPreferenceBox = await Hive.openBox<UserPreference>(_userPreferenceBoxName);
      _favoriteBox = await Hive.openBox(_favoriteBoxName);
      _historyBox = await Hive.openBox(_historyBoxName);
      _bubbleStateBox = await Hive.openBox(_bubbleStateBoxName);
      _appSettingsBox = await Hive.openBox(_appSettingsBoxName);
    } catch (e) {
      debugPrint('StorageService initialization failed: $e');
      // 可选：清理损坏的存储
      // await Hive.deleteFromDisk();
    }
  }

  /// 清理存储服务（用于解决锁定问题）
  static Future<void> cleanup() async {
    try {
      await Hive.close();
    } catch (e) {
      debugPrint('关闭Hive失败: $e');
    }
  }

  // ============ 用户偏好存储 ============

  /// 保存或更新用户偏好
  static Future<void> saveUserPreference(UserPreference preference) async {
    // Hive的put方法会覆盖具有相同键的值，因此可用于创建和更新
    await _userPreferenceBox.put(preference.userId, preference);
  }

  /// 获取用户偏好
  /// 如果不存在，则创建一个新的默认偏好并保存
  static Future<UserPreference> getUserPreference(String userId) async {
    final preference = _userPreferenceBox.get(userId);
    if (preference != null) {
      return preference;
    } else {
      // 如果没有找到偏好，创建一个新的并保存它
      final defaultPreference = UserPreference(userId: userId);
      await saveUserPreference(defaultPreference);
      return defaultPreference;
    }
  }
  
  /// 获取当前用户偏好，或返回默认值
  static UserPreference getCurrentUserPreference(String userId) {
    return _userPreferenceBox.get(userId) ?? UserPreference(userId: userId);
  }

  /// 清空所有用户偏好数据
  static Future<void> clearAllPreferences() async {
    final clearedCount = await _userPreferenceBox.clear();
    debugPrint('Cleared $clearedCount user preferences.');
  }

  /// 删除特定用户的偏好数据
  static Future<void> deleteUserPreference(String userId) async {
    await _userPreferenceBox.delete(userId);
  }

  // ============ 收藏系统 ============

  /// 添加收藏食物
  static Future<void> addFavoriteFood(Food food) async {
    await _favoriteBox.put(food.id, food.toJson());
  }

  /// 移除收藏食物
  static Future<void> removeFavoriteFood(String foodId) async {
    await _favoriteBox.delete(foodId);
  }

  /// 获取所有收藏食物
  static List<Food> getFavoriteFoods() {
    final favorites = <Food>[];
    for (final data in _favoriteBox.values) {
      try {
        favorites.add(Food.fromJson(Map<String, dynamic>.from(data)));
      } catch (e) {
        debugPrint('解析收藏食物数据失败: $e');
      }
    }
    return favorites;
  }

  /// 检查食物是否被收藏
  static bool isFoodFavorited(String foodId) {
    return _favoriteBox.containsKey(foodId);
  }

  // ============ 历史记录系统 ============

  /// 添加浏览历史
  static Future<void> addFoodHistory(Food food) async {
    final historyItem = {
      ...food.toJson(),
      'viewedAt': DateTime.now().toIso8601String(),
    };

    // 使用时间戳作为key确保唯一性
    final key = '${food.id}_${DateTime.now().millisecondsSinceEpoch}';
    await _historyBox.put(key, historyItem);

    // 限制历史记录数量（最多100条）
    if (_historyBox.length > 100) {
      final oldestKey = _historyBox.keys.first;
      await _historyBox.delete(oldestKey);
    }
  }

  /// 获取浏览历史
  static List<Map<String, dynamic>> getFoodHistory({int limit = 50}) {
    final history = <Map<String, dynamic>>[];

    // 按时间倒序排列
    final sortedKeys = _historyBox.keys.toList()
      ..sort((a, b) => b.toString().compareTo(a.toString()));

    for (final key in sortedKeys.take(limit)) {
      final data = _historyBox.get(key);
      if (data != null) {
        history.add(Map<String, dynamic>.from(data));
      }
    }

    return history;
  }

  /// 清空历史记录
  static Future<void> clearFoodHistory() async {
    await _historyBox.clear();
  }

  /// 移除食物历史记录（新增方法）
  static Future<void> removeFoodHistory(String foodId) async {
    final keysToRemove = <String>[];

    for (final key in _historyBox.keys) {
      final data = _historyBox.get(key);
      if (data != null && data is Map) {
        final id = data['id'];
        if (id == foodId) {
          keysToRemove.add(key.toString());
        }
      }
    }

    for (final key in keysToRemove) {
      await _historyBox.delete(key);
    }
  }

  // ============ 气泡状态存储 ============

  /// 保存气泡序列
  static Future<void> saveBubbleSequence(
      String sequenceId, List<Bubble> bubbles) async {
    final bubbleData = bubbles.map((bubble) => bubble.toJson()).toList();
    await _bubbleStateBox.put(sequenceId, bubbleData);
  }

  /// 获取气泡序列
  static List<Bubble> getBubbleSequence(String sequenceId) {
    final data = _bubbleStateBox.get(sequenceId);
    if (data != null && data is List) {
      try {
        return data
            .map((item) => Bubble.fromJson(Map<String, dynamic>.from(item)))
            .toList();
      } catch (e) {
        debugPrint('解析气泡序列失败: $e');
      }
    }
    return [];
  }

  /// 删除气泡序列
  static Future<void> deleteBubbleSequence(String sequenceId) async {
    await _bubbleStateBox.delete(sequenceId);
  }

  // ============ 应用设置 ============

  /// 保存应用设置
  static Future<void> saveAppSetting(String key, dynamic value) async {
    await _appSettingsBox.put(key, {'value': value});
  }

  /// 获取应用设置
  static T? getAppSetting<T>(String key, {T? defaultValue}) {
    final data = _appSettingsBox.get(key);
    if (data != null && data['value'] is T) {
      return data['value'] as T;
    }
    return defaultValue;
  }

  /// 获取主题模式
  static String getThemeMode() {
    return getAppSetting<String>('theme_mode', defaultValue: 'system') ??
        'system';
  }

  /// 保存主题模式
  static Future<void> saveThemeMode(String mode) async {
    await saveAppSetting('theme_mode', mode);
  }

  /// 获取语言设置
  static String getLanguage() {
    return getAppSetting<String>('language', defaultValue: 'zh_CN') ?? 'zh_CN';
  }

  /// 保存语言设置
  static Future<void> saveLanguage(String language) async {
    await saveAppSetting('language', language);
  }

  /// 获取通知设置
  static bool getNotificationEnabled() {
    return getAppSetting<bool>('notification_enabled', defaultValue: true) ??
        true;
  }

  /// 保存通知设置
  static Future<void> saveNotificationEnabled(bool enabled) async {
    await saveAppSetting('notification_enabled', enabled);
  }

  // ============ 数据统计和清理 ============

  /// 获取存储统计信息
  static Map<String, dynamic> getStorageStats() {
    return {
      'favoriteCount': _favoriteBox.length,
      'historyCount': _historyBox.length,
      'hasUserPreference': _userPreferenceBox.isNotEmpty,
      'hasBubbleState': _bubbleStateBox.isNotEmpty,
      'settingsCount': _appSettingsBox.length,
    };
  }

  /// 清空所有数据
  static Future<void> clearAllData() async {
    await _userPreferenceBox.clear();
    await _favoriteBox.clear();
    await _historyBox.clear();
    await _bubbleStateBox.clear();
    await _appSettingsBox.clear();
  }

  /// 导出用户数据
  static Map<String, dynamic> exportUserData() {
    return {
      'userPreference': _userPreferenceBox.values.toList(),
      'favorites': _favoriteBox.values.toList(),
      'history': _historyBox.values.toList(),
      'bubbleStates': _bubbleStateBox.values.toList(),
      'appSettings': _appSettingsBox.values.toList(),
      'exportedAt': DateTime.now().toIso8601String(),
    };
  }

  /// 导入用户数据
  static Future<bool> importUserData(Map<String, dynamic> data) async {
    try {
      // 清空现有数据
      await clearAllData();

      // 导入用户偏好
      if (data['userPreference'] != null) {
        for (final preference in data['userPreference']) {
          await saveUserPreference(UserPreference.fromJson(preference));
        }
      }

      // 导入收藏
      if (data['favorites'] != null) {
        final favorites = List<Map>.from(data['favorites']);
        for (final favorite in favorites) {
          await _favoriteBox.put(favorite['id'], favorite);
        }
      }

      // 导入历史记录
      if (data['history'] != null) {
        final history = List<Map>.from(data['history']);
        for (int i = 0; i < history.length; i++) {
          await _historyBox.put('imported_$i', history[i]);
        }
      }

      return true;
    } catch (e) {
      debugPrint('导入用户数据失败: $e');
      return false;
    }
  }

  /// 关闭所有Box
  static Future<void> close() async {
    await _userPreferenceBox.close();
    await _favoriteBox.close();
    await _historyBox.close();
    await _bubbleStateBox.close();
    await _appSettingsBox.close();
  }
}
