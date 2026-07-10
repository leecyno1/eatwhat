import 'package:flutter/material.dart';
import '../../../core/models/bubble.dart';
import '../../../core/models/food.dart';
import '../../../core/models/recipe.dart';
import '../../../core/models/user_preference.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/services/recipe_recommendation_sync_service.dart';
import '../../../core/utils/analytics_helper.dart';

/// 增强推荐控制器 - Phase 3 下厨房同步版本
/// 集成下厨房数据库和智能口味映射算法
class RecommendationController extends ChangeNotifier {
  late UserPreference _userPreference;
  List<Food> _recommendations = [];
  bool _isLoading = false;
  String? _errorMessage;
  final String _currentUserId = 'default_user'; // 应该从AuthService获取
  final RecipeRecommendationSyncService _syncService = RecipeRecommendationSyncService();

  // Phase 3 新增：下厨房数据同步相关
  bool _isSyncing = false;
  Map<String, dynamic> _syncStats = {};

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

  // Phase 3 新增 getter
  bool get isSyncing => _isSyncing;
  Map<String, dynamic> get syncStatistics => _syncStats;

  RecommendationController() {
    _initialize();
  }

  Future<void> _initialize() async {
    try {
      // Phase 3: 初始化同步服务
      await _syncService.initialize();

      // 监听同步进度
      _syncService.progressStream.listen((event) {
        debugPrint('🔄 同步进度: ${event.message}');
        _updateSyncStatus(event);
      });

      _userPreference = await StorageService.getUserPreference(_currentUserId);

      // 获取同步统计
      _updateSyncStatistics();

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

  /// 生成推荐 - Phase 3 下厨房数据库版本
  Future<void> generateRecommendations(List<Bubble> selectedBubbles) async {
    _setLoading(true);
    _errorMessage = null;

    try {
      debugPrint('🚀 开始生成推荐，选中气泡: ${selectedBubbles.length}个');

      // 埋点：记录推荐开始
      AnalyticsHelper.logPageEnter('recommendation_screen');

      // 使用同步服务的智能推荐算法
      final recommendations = await _syncService.getSmartRecommendations(
        selectedBubbles,
        _userPreference,
        limit: 12,
        minMatchScore: 0.3,
      );

      _recommendations = recommendations;

      // 更新统计信息
      _updateStatistics();

      // 按分类缓存推荐结果
      _categorizeFoodRecommendations();

      // 埋点：记录推荐结果展示
      AnalyticsHelper.logRecommendationShown(
        recommendations.length,
        foodIds: recommendations.map((f) => f.id).toList(),
        source: 'bubble_selection',
      );

      debugPrint('✅ 推荐生成完成，共${_recommendations.length}个结果');
    } catch (e) {
      _errorMessage = '生成推荐失败: $e';
      debugPrint('❌ 推荐生成失败: $e');
      // 埋点：记录错误
      AnalyticsHelper.logError('recommendation_failed', e.toString());
    } finally {
      _setLoading(false);
    }
  }

  /// 更新统计信息
  void _updateStatistics() {
    if (_recommendations.isEmpty) return;

    // 计算平均评分
    _averageRating = _recommendations.map((food) => food.rating).reduce((a, b) => a + b) /
        _recommendations.length;

    // 统计菜系分布
    _categoryStats.clear();
    for (final food in _recommendations) {
      final cuisineType = food.cuisineType ?? '未知';
      _categoryStats[cuisineType] = (_categoryStats[cuisineType] ?? 0) + 1;
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
      final cuisineType = food.cuisineType ?? '未知';
      cuisineGroups.putIfAbsent(cuisineType, () => []).add(food);
    }
    _categoryRecommendations.addAll(cuisineGroups);

    // 按口味分类
    final tasteGroups = <String, List<Food>>{};
    for (final food in _recommendations) {
      final tasteAttributes = food.tasteAttributes ?? [];
      for (final taste in tasteAttributes) {
        if (['辣', '甜', '清淡', '香'].contains(taste)) {
          tasteGroups.putIfAbsent(taste, () => []).add(food);
        }
      }
    }
    _categoryRecommendations.addAll(tasteGroups);
  }

  /// 获取个性化推荐（无气泡选择）- Phase 3 版本
  Future<void> getPersonalizedRecommendations() async {
    _setLoading(true);
    _errorMessage = null;

    try {
      debugPrint('🔍 获取个性化推荐...');

      // 使用空气泡列表获取基于历史的推荐
      final recommendations = await _syncService.getSmartRecommendations(
        [], // 空气泡列表
        _userPreference,
        limit: 10,
        minMatchScore: 0.2, // 降低阈值以获取更多结果
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

  /// 切换收藏状态 - Phase 3 同步版本
  Future<void> toggleFavorite(String foodId) async {
    try {
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

    // 埋点：记录口味反馈
    AnalyticsHelper.logTasteFeedback(foodId, isLiked);

    await StorageService.saveUserPreference(_userPreference);
    notifyListeners();
  }

  // ... (其他方法保持不变)

  // ========== 埋点相关方法 ==========

  /// 记录推荐项点击
  void trackRecommendationClicked(String foodId, String foodName, int position) {
    AnalyticsHelper.logRecommendationClicked(foodId, foodName, position);
  }

  /// 记录食物详情浏览
  void trackFoodDetailViewed(String foodId, String foodName) {
    AnalyticsHelper.logFoodDetailViewed(foodId, foodName);
  }

  /// 记录加入购物车
  void trackAddToCart(String foodId, String foodName, double price, {int quantity = 1}) {
    AnalyticsHelper.logAddToCart(foodId, foodName, price, quantity);
  }

  /// 记录收藏状态切换
  void trackFavoriteToggled(String foodId, String foodName, bool isFavorite) {
    AnalyticsHelper.logFoodFavoriteToggled(foodId, foodName, isFavorite);
  }

  // Phase 3 新增方法

  /// 获取菜谱详情
  Future<Recipe?> getRecipeDetail(String foodId) async {
    try {
      return await _syncService.getRecipeDetail(foodId);
    } catch (e) {
      debugPrint('获取菜谱详情失败: $e');
      return null;
    }
  }

  /// 搜索菜谱
  Future<List<Food>> searchRecipes({
    String? keyword,
    List<String>? cuisines,
    List<String>? tastes,
    RecipeDifficulty? difficulty,
    int? maxTime,
    bool? isVegetarian,
    int limit = 20,
  }) async {
    try {
      return await _syncService.searchRecipes(
        keyword: keyword,
        cuisines: cuisines,
        tastes: tastes,
        difficulty: difficulty,
        maxTime: maxTime,
        isVegetarian: isVegetarian,
        limit: limit,
      );
    } catch (e) {
      debugPrint('搜索菜谱失败: $e');
      return [];
    }
  }

  /// 执行数据同步
  Future<void> performDataSync({bool fullSync = false}) async {
    _isSyncing = true;
    notifyListeners();

    try {
      final result = fullSync
          ? await _syncService.performFullSync()
          : await _syncService.performIncrementalSync();

      if (result.success) {
        debugPrint('✅ 数据同步成功: ${result.message}');
        _updateSyncStatistics();
      } else {
        debugPrint('❌ 数据同步失败: ${result.message}');
      }
    } catch (e) {
      debugPrint('数据同步异常: $e');
    } finally {
      _isSyncing = false;
      notifyListeners();
    }
  }

  /// 更新同步状态
  void _updateSyncStatus(SyncProgressEvent event) {
    // 根据同步事件更新UI状态
    notifyListeners();
  }

  /// 更新同步统计
  void _updateSyncStatistics() {
    _syncStats = _syncService.getSyncStatistics();
    notifyListeners();
  }
}
