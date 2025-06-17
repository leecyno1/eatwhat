import 'package:hive/hive.dart';
import '../models/user_preference.dart';

/// 用户偏好存储服务
class UserPreferenceService {
  static const String _boxName = 'user_preferences';
  static const String _defaultUserId = 'default_user';
  
  static Box<Map>? _box;
  
  /// 初始化Hive存储
  static Future<void> init() async {
    try {
      _box = await Hive.openBox<Map>(_boxName);
    } catch (e) {
      print('Failed to initialize UserPreferenceService: $e');
    }
  }
  
  /// 保存用户偏好
  static Future<void> saveUserPreference(UserPreference preference) async {
    if (_box == null) {
      await init();
    }
    
    try {
      await _box!.put(preference.userId, preference.toJson());
    } catch (e) {
      print('Failed to save user preference: $e');
    }
  }
  
  /// 获取用户偏好
  static Future<UserPreference> getUserPreference([String? userId]) async {
    if (_box == null) {
      await init();
    }
    
    final id = userId ?? _defaultUserId;
    
    try {
      final data = _box!.get(id);
      if (data != null) {
        return UserPreference.fromJson(Map<String, dynamic>.from(data));
      }
    } catch (e) {
      print('Failed to load user preference: $e');
    }
    
    // 返回默认用户偏好
    return UserPreference(userId: id);
  }
  
  /// 更新气泡偏好
  static Future<void> updateBubblePreference(String bubbleName, double score, [String? userId]) async {
    final preference = await getUserPreference(userId);
    final updatedPreference = preference.updateBubblePreference(bubbleName, score);
    await saveUserPreference(updatedPreference);
  }
  
  /// 添加收藏食物
  static Future<void> addFavoriteFood(String foodId, [String? userId]) async {
    final preference = await getUserPreference(userId);
    final updatedPreference = preference.addFavoriteFood(foodId);
    await saveUserPreference(updatedPreference);
  }
  
  /// 添加不喜欢的食物
  static Future<void> addDislikedFood(String foodId, [String? userId]) async {
    final preference = await getUserPreference(userId);
    final updatedPreference = preference.addDislikedFood(foodId);
    await saveUserPreference(updatedPreference);
  }
  
  /// 更新菜系偏好
  static Future<void> updateCuisinePreference(String cuisine, int score, [String? userId]) async {
    final preference = await getUserPreference(userId);
    final updatedPreference = preference.updateCuisinePreference(cuisine, score);
    await saveUserPreference(updatedPreference);
  }
  
  /// 更新口味偏好
  static Future<void> updateTastePreference(String taste, int score, [String? userId]) async {
    final preference = await getUserPreference(userId);
    final updatedPreference = preference.updateTastePreference(taste, score);
    await saveUserPreference(updatedPreference);
  }
  
  /// 清除所有用户偏好数据
  static Future<void> clearAllPreferences() async {
    if (_box == null) {
      await init();
    }
    
    try {
      await _box!.clear();
    } catch (e) {
      print('Failed to clear preferences: $e');
    }
  }
  
  /// 删除特定用户的偏好数据
  static Future<void> deleteUserPreference(String userId) async {
    if (_box == null) {
      await init();
    }
    
    try {
      await _box!.delete(userId);
    } catch (e) {
      print('Failed to delete user preference: $e');
    }
  }
  
  /// 获取所有用户ID
  static Future<List<String>> getAllUserIds() async {
    if (_box == null) {
      await init();
    }
    
    try {
      return _box!.keys.cast<String>().toList();
    } catch (e) {
      print('Failed to get user IDs: $e');
      return [];
    }
  }
  
  /// 检查是否存在用户偏好数据
  static Future<bool> hasUserPreference([String? userId]) async {
    if (_box == null) {
      await init();
    }
    
    final id = userId ?? _defaultUserId;
    return _box!.containsKey(id);
  }
  
  /// 关闭存储
  static Future<void> close() async {
    if (_box != null && _box!.isOpen) {
      await _box!.close();
      _box = null;
    }
  }
}