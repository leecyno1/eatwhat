import 'package:flutter/material.dart';
import 'package:eatwhat_app/core/models/bubble.dart';
import 'package:eatwhat_app/core/models/food.dart';
import 'package:eatwhat_app/core/models/user_preference.dart';
import 'package:eatwhat_app/core/services/recommendation_engine.dart';
import 'package:eatwhat_app/core/services/storage_service.dart';

/// 推荐控制器
class RecommendationController extends ChangeNotifier {
  late UserPreference _userPreference;
  List<Food> _recommendations = [];
  bool _isLoading = false;
  String? _errorMessage;
  final String _currentUserId = 'default_user'; // 应该从AuthService获取
  final RecommendationEngine _engine = RecommendationEngine();

  List<Food> get recommendations => _recommendations;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  UserPreference get userPreference => _userPreference;

  RecommendationController() {
    _initialize();
  }

  void _initialize() async {
    _userPreference = await StorageService.getUserPreference(_currentUserId);
    notifyListeners();
  }

  /// 设置加载状态
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// 生成推荐
  Future<void> generateRecommendations(List<Bubble> selectedBubbles) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      await Future.delayed(const Duration(milliseconds: 800));
      _recommendations = await _engine.getPersonalizedRecommendations(_userPreference);
      _adjustRecommendationsWithPreferences();
    } catch (e) {
      _errorMessage = '生成推荐失败: $e';
    } finally {
      _setLoading(false);
    }
  }

  /// 根据用户偏好调整推荐分数
  void _adjustRecommendationsWithPreferences() {
    // ... (现有逻辑不变)
    // 确保使用 _userPreference
  }

  /// 标记食物为喜欢/不喜欢
  Future<void> updateFoodPreference(String foodId, bool isLiked) async {
    final updatedFavorites = List<String>.from(_userPreference.favoriteFoods);
    final updatedDislikes = List<String>.from(_userPreference.dislikedFoods);

    if (isLiked) {
      if (!updatedFavorites.contains(foodId)) updatedFavorites.add(foodId);
      updatedDislikes.remove(foodId);
    } else {
      if (!updatedDislikes.contains(foodId)) updatedDislikes.add(foodId);
      updatedFavorites.remove(foodId);
    }

    _userPreference = _userPreference.copyWith(
      favoriteFoods: updatedFavorites,
      dislikedFoods: updatedDislikes,
    );
    
    await StorageService.saveUserPreference(_userPreference);
    _adjustRecommendationsWithPreferences();
    notifyListeners();
  }

  // ... (其他方法保持不变)
} 