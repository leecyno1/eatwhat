import 'package:flutter/material.dart';
import '../../../core/models/bubble.dart';
import '../../../core/models/food.dart';
import '../../../core/models/user_preference.dart';
import '../../../core/services/unified_food_data_service.dart';
import '../../../core/services/storage_service.dart';

/// 增强推荐控制器 - Phase 1 优化版本
/// 使用统一食物数据服务和向量化推荐引擎
class RecommendationController extends ChangeNotifier {
  late UserPreference _userPreference;
  List<Food> _recommendations = [];
  bool _isLoading = false;
  String? _errorMessage;
  final String _currentUserId = 'default_user'; // 应该从AuthService获取
  final UnifiedFoodDataService _unifiedService = UnifiedFoodDataService();
  
  // 新增：分类推荐缓存
  Map<String, List<Food>> _categoryRecommendations = {};
  
  // 新增：统计信息
  Map<String, int> _categoryStats = {};
  double _averageRating = 0.0;

  List<Food> get recommendations => _recommendations;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  UserPreference get userPreference => _userPreference;
  Map<String, List<Food>> get categoryRecommendations => _categoryRecommendations;
  Map<String, int> get categoryStats => _categoryStats;
  double get averageRating => _averageRating;

  RecommendationController() {
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      await _unifiedService.initialize();
      _userPreference = await StorageService.getUserPreference(_currentUserId);
      notifyListeners();
    } catch (e) {
      debugPrint('推荐控制器初始化失败: $e');
    }
  }

  /// 设置加载状态
  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// 生成推荐 - 使用统一数据服务
  Future<void> generateRecommendations(List<Bubble> selectedBubbles) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      debugPrint('🚀 开始生成推荐，选中气泡: ${selectedBubbles.length}个');
      
      // 使用统一食物数据服务获取推荐
      final recommendations = await _unifiedService.getRecommendations(
        selectedBubbles,
        _userPreference,
        limit: 12,
      );
      
      _recommendations = recommendations;
      
      // 更新统计信息
      _updateStatistics();
      
      // 按分类缓存推荐结果
      _categorizeFoodRecommendations();
      
      debugPrint('✅ 推荐生成完成，共${_recommendations.length}个结果');
      
    } catch (e) {
      _errorMessage = '生成推荐失败: $e';
      debugPrint('❌ 推荐生成失败: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// 更新统计信息
  void _updateStatistics() {
    if (_recommendations.isEmpty) return;
    
    // 计算平均评分
    _averageRating = _recommendations
        .map((food) => food.rating)
        .reduce((a, b) => a + b) / _recommendations.length;
    
    // 统计菜系分布
    _categoryStats.clear();
    for (final food in _recommendations) {
      _categoryStats[food.cuisineType] = 
          (_categoryStats[food.cuisineType] ?? 0) + 1;
    }
    
    debugPrint('📊 统计信息更新: 平均评分${_averageRating.toStringAsFixed(2)}, 菜系${_categoryStats.length}个');
  }

  /// 按分类缓存推荐结果
  void _categorizeFoodRecommendations() {
    _categoryRecommendations.clear();
    _categoryRecommendations['全部'] = _recommendations;
    
    // 按菜系分类
    final cuisineGroups = <String, List<Food>>{};
    for (final food in _recommendations) {
      cuisineGroups.putIfAbsent(food.cuisineType, () => []).add(food);
    }
    _categoryRecommendations.addAll(cuisineGroups);
    
    // 按口味分类
    final tasteGroups = <String, List<Food>>{};
    for (final food in _recommendations) {
      for (final taste in food.tasteAttributes) {
        if (['辣', '甜', '清淡', '香'].contains(taste)) {
          tasteGroups.putIfAbsent(taste, () => []).add(food);
        }
      }
    }
    _categoryRecommendations.addAll(tasteGroups);
  }

  /// 获取个性化推荐（无气泡选择）
  Future<void> getPersonalizedRecommendations() async {
    _setLoading(true);
    _errorMessage = null;

    try {
      debugPrint('🔍 获取个性化推荐...');
      
      final recommendations = await _unifiedService.getPersonalizedRecommendations(
        _userPreference,
        limit: 10,
      );
      
      _recommendations = recommendations;
      _updateStatistics();
      _categorizeFoodRecommendations();
      
    } catch (e) {
      _errorMessage = '获取个性化推荐失败: $e';
      debugPrint('❌ 个性化推荐失败: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// 切换收藏状态
  Future<void> toggleFavorite(String foodId) async {
    try {
      await _unifiedService.toggleFoodFavorite(foodId);
      
      // 更新本地状态
      final index = _recommendations.indexWhere((food) => food.id == foodId);
      if (index != -1) {
        final food = _recommendations[index];
        _recommendations[index] = food.copyWith(isFavorite: !food.isFavorite);
        notifyListeners();
      }
      
    } catch (e) {
      debugPrint('切换收藏失败: $e');
    }
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