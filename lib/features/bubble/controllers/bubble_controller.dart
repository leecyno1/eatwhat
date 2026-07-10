import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../../../core/models/bubble.dart';
import '../../../core/models/bubble_factory.dart';
import '../../../core/models/food.dart';
import '../../../core/models/user_preference.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/physics/improved_bubble_physics.dart';
import '../../../core/services/unified_food_data_service.dart';
import '../../../core/services/user_preference_manager.dart' show UserActionType;
import '../../../core/services/realtime_feedback_service.dart';
import '../../../core/services/synchronization_manager.dart';
import '../../../core/services/collaborative_filtering_service.dart';
import '../../../core/utils/performance_optimizer.dart';
import '../../../core/utils/analytics_helper.dart';

/// 优化后的气泡控制器 - Phase 2 实时反馈版本
/// 集成实时反馈服务和同步管理器
class BubbleController extends DebouncedNotifier {
  final List<Bubble> _bubbles = [];
  final List<Bubble> _selectedBubbles = [];
  final List<Food> _recommendedFoods = [];

  // final StorageService _storageService; // 未使用，暂时注释掉
  late UserPreference _userPreference;

  // Phase 2 新增服务
  final RealtimeFeedbackService _feedbackService = RealtimeFeedbackService();
  final SynchronizationManager _syncManager = SynchronizationManager();
  final CollaborativeFilteringService _cfService = CollaborativeFilteringService();

  // 状态标识
  bool _isInitialized = false;
  bool _isLoading = false;
  bool _isGeneratingRecommendations = false;
  Size? _screenSize;

  // TODO: 后续应从AuthService获取
  final String _currentUserId = 'default_user';

  // 偏好保存回调
  void Function(bool isLike)? onPreferenceSaved;

  // Getters
  List<Bubble> get bubbles => _bubbles;
  List<Bubble> get selectedBubbles => _selectedBubbles;
  UserPreference get userPreference => _userPreference;
  List<Food> get recommendedFoods => _recommendedFoods;
  bool get isInitialized => _isInitialized;
  bool get isLoading => _isLoading;
  bool get isGeneratingRecommendations => _isGeneratingRecommendations;
  int get selectedCount => _selectedBubbles.length;

  BubbleController();

  /// 初始化控制器，加载必要数据并创建气泡
  /// [screenSize] 用于初始化气泡在屏幕上的智能分布位置
  Future<void> initialize({Size? screenSize}) async {
    _isLoading = true;
    debouncedNotify();

    try {
      // 记录性能
      PerformanceOptimizer().recordInteraction();

      // 埋点：记录气泡页面进入
      AnalyticsHelper.logPageEnter('bubble_screen');

      // Phase 2: 初始化实时反馈服务
      await _feedbackService.initialize();
      await _syncManager.initialize();
      await _cfService.initialize(); // 协同过滤服务初始化

      // 监听同步事件
      _syncManager.syncStream.listen((event) {
        debugPrint('🔄 同步事件: ${event.message}');
      });

      _userPreference = await StorageService.getUserPreference(_currentUserId);
      _bubbles.clear();
      _bubbles.addAll(BubbleFactory.createDefaultBubbles());

      if (screenSize != null) {
        _screenSize = screenSize;
        ImprovedBubblePhysics.distributeeBubbles(_bubbles, screenSize);
      }

      _isInitialized = true;
    } catch (e) {
      debugPrint('Bubble controller initialization error: $e');
    }

    _isLoading = false;
    debouncedNotify();
  }

  /// 重新分布气泡位置
  void redistributeBubbles() {
    if (_screenSize != null) {
      PerformanceOptimizer().recordInteraction();
      ImprovedBubblePhysics.distributeeBubbles(_bubbles, _screenSize!);
      debouncedNotify();
    }
  }

  /// 切换气泡选择状态 - Phase 2 实时反馈优化版本
  void toggleBubble(Bubble bubble) {
    final index = _bubbles.indexWhere((b) => b.id == bubble.id);
    if (index == -1) return;

    PerformanceOptimizer().recordInteraction();

    final isSelected = !_bubbles[index].isSelected;
    _bubbles[index] = bubble.copyWith(isSelected: isSelected);

    _selectedBubbles.removeWhere((b) => b.id == bubble.id);
    if (isSelected) {
      _selectedBubbles.add(_bubbles[index]);

      // Phase 2: 记录实时反馈
      _feedbackService.recordUserAction(
        bubble.id,
        UserActionType.like,
        metadata: {
          'bubbleName': bubble.name,
          'bubbleType': bubble.type.name,
          'selectionTime': DateTime.now().toIso8601String(),
        },
      );
    } else {
      // 取消选择时记录
      _feedbackService.recordUserAction(
        bubble.id,
        UserActionType.view,
        metadata: {
          'action': 'deselected',
          'bubbleName': bubble.name,
        },
      );
    }

    // 使用防抖通知减少重绘频率
    debouncedNotify();
  }

  /// 取消选择气泡
  void deselectBubble(Bubble bubble) {
    final index = _bubbles.indexWhere((b) => b.id == bubble.id);
    if (index != -1) {
      _bubbles[index] = bubble.copyWith(isSelected: false);
      _selectedBubbles.removeWhere((b) => b.id == bubble.id);
      notifyListeners();
    }
  }

  /// 重置选择
  void resetSelection() {
    for (int i = 0; i < _bubbles.length; i++) {
      if (_bubbles[i].isSelected) {
        _bubbles[i] = _bubbles[i].copyWith(isSelected: false);
      }
    }
    _selectedBubbles.clear();
    notifyListeners();
  }

  /// 重置所有气泡（通常需要提供屏幕尺寸以重新布局）
  void resetAllBubbles({Size? screenSize}) {
    resetSelection();
    // 重新初始化会清空并重新创建气泡
    initialize(screenSize: screenSize);
  }

  /// 清除所有选择
  void clearSelection() {
    _selectedBubbles.clear();
    _recommendedFoods.clear();
    notifyListeners();
  }

  /// 喜欢气泡 - Phase 2 实时反馈版本
  Future<void> likeBubble(Bubble bubble) async {
    if (!_selectedBubbles.any((b) => b.id == bubble.id)) {
      _selectedBubbles.add(bubble.copyWith(isSelected: true));
    }

    // 埋点：记录气泡喜欢（下滑表示不喜欢，上滑表示喜欢）
    AnalyticsHelper.logBubbleLiked(bubble.id, bubble.name);

    // 实时记录用户偏好
    _feedbackService.recordUserAction(
      bubble.id,
      UserActionType.favorite,
      metadata: {
        'bubbleName': bubble.name,
        'bubbleType': bubble.type.name,
        'intensity': 1.0,
      },
      immediate: true, // 高优先级行为立即处理
    );

    // 记录协同过滤交互
    await _cfService.recordInteraction(
      userId: _currentUserId,
      recipeId: bubble.id,
      rating: 3.0, // 喜欢
    );

    await _updateUserPreference(bubble, true);
    notifyListeners();
  }

  /// 不喜欢气泡 - Phase 2 实时反馈版本
  Future<void> dislikeBubble(Bubble bubble) async {
    _selectedBubbles.removeWhere((b) => b.id == bubble.id);

    // 埋点：记录气泡不喜欢
    AnalyticsHelper.logBubbleDisliked(bubble.id, bubble.name);

    // 实时记录负面反馈
    _feedbackService.recordUserAction(
      bubble.id,
      UserActionType.dislike,
      metadata: {
        'bubbleName': bubble.name,
        'bubbleType': bubble.type.name,
        'intensity': -1.0,
      },
      immediate: true,
    );

    // 记录协同过滤交互
    await _cfService.recordInteraction(
      userId: _currentUserId,
      recipeId: bubble.id,
      rating: 1.0, // 不喜欢
    );

    await _updateUserPreference(bubble, false);
    notifyListeners();
  }

  /// 标记气泡为喜欢 - 用于手势操作
  void markBubbleAsLiked(Bubble bubble) {
    likeBubble(bubble);
  }

  /// 标记气泡为不喜欢 - 用于手势操作
  void markBubbleAsDisliked(Bubble bubble) {
    dislikeBubble(bubble);
  }

  /// 忽略气泡
  void ignoreBubble(Bubble bubble) {
    final index = _bubbles.indexWhere((b) => b.id == bubble.id);
    if (index != -1) {
      // 可以添加一个 "ignored" 状态或者直接从列表中移除
      // 这里暂时只更新UI
    }
    notifyListeners();
  }

  /// 处理气泡手势
  void handleBubbleGesture(Bubble bubble, BubbleGesture gesture) {
    switch (gesture) {
      case BubbleGesture.tap:
        AnalyticsHelper.logBubbleTapped(bubble.id, bubble.name);
        toggleBubble(bubble);
        break;
      case BubbleGesture.swipeUp:
        AnalyticsHelper.logBubbleSwiped(bubble.id, bubble.name, 'up');
        likeBubble(bubble);
        break;
      case BubbleGesture.swipeDown:
        AnalyticsHelper.logBubbleSwiped(bubble.id, bubble.name, 'down');
        dislikeBubble(bubble);
        break;
      case BubbleGesture.longPress:
        AnalyticsHelper.logBubbleLongPressed(bubble.id, bubble.name);
        debugPrint('查看气泡详情: ${bubble.name}');
        break;
      case BubbleGesture.swipeLeft:
        AnalyticsHelper.logBubbleSwiped(bubble.id, bubble.name, 'left');
        ignoreBubble(bubble);
        break;
      case BubbleGesture.swipeRight:
        AnalyticsHelper.logBubbleSwiped(bubble.id, bubble.name, 'right');
        markBubbleAsLiked(bubble);
        break;
      // 其他手势可以后续添加
      default:
        break;
    }
    _savePreferences();
  }

  /// 更新用户偏好
  Future<void> _updateUserPreference(Bubble bubble, bool isLiked) async {
    // 这里可以实现用户偏好的更新逻辑
    // 示例：更新口味偏好
    if (isLiked) {
      _userPreference = _userPreference.updateTastePreference(bubble.name, 1.0);
    } else {
      _userPreference = _userPreference.updateTastePreference(bubble.name, -1.0);
    }

    // 异步保存偏好
    await _savePreferences();

    // 触发保存成功回调
    _onPreferenceSaved(isLiked);
  }

  /// 保存偏好到存储
  Future<void> _savePreferences() async {
    await StorageService.saveUserPreference(_userPreference);
  }

  /// 偏好保存成功回调
  void _onPreferenceSaved(bool isLike) {
    // 触发 HapticFeedback
    HapticFeedback.mediumImpact();

    // 触发保存成功回调
    if (onPreferenceSaved != null) {
      onPreferenceSaved!(isLike);
    }
  }

  /// 生成推荐 - 使用统一食物数据服务
  Future<void> generateRecommendations() async {
    _isGeneratingRecommendations = true;
    notifyListeners();

    try {
      debugPrint('🚀 开始生成美食推荐 - 使用统一数据服务...');

      // 使用统一食物数据服务获取推荐
      final unifiedService = UnifiedFoodDataService();
      final recommendations = await unifiedService.getRecommendations(
        _selectedBubbles,
        _userPreference,
        limit: 8,
      );

      _recommendedFoods.clear();
      _recommendedFoods.addAll(recommendations);

      debugPrint('✅ 生成了 ${_recommendedFoods.length} 个美食推荐');

      // 如果推荐结果不足，获取个性化推荐补充
      if (_recommendedFoods.length < 3) {
        debugPrint('📈 推荐结果不足，获取个性化推荐...');
        final personalizedRecommendations = await unifiedService.getPersonalizedRecommendations(
          _userPreference,
          limit: 8 - _recommendedFoods.length,
        );
        _recommendedFoods.addAll(personalizedRecommendations);
      }

      debugPrint('🎯 最终推荐结果: ${_recommendedFoods.length} 个');
    } catch (e, s) {
      debugPrint('❌ 生成推荐时出错: $e\n$s');

      // 如果出错，使用备用推荐
      _recommendedFoods.clear();
      await _generateFallbackRecommendations();
    } finally {
      _isGeneratingRecommendations = false;
      notifyListeners();
    }
  }

  /// 生成备用推荐
  Future<void> _generateFallbackRecommendations() async {
    debugPrint('使用备用推荐策略');

    final fallbackFoods = [
      Food(
        id: 'fallback_001',
        name: '红烧肉',
        description: '经典家常菜，肉香浓郁，肉质软烂',
        cuisineType: '家常菜',
        rating: 4.5,
        price: 35.0,
        tasteAttributes: ['甜', '咸', '香'],
      ),
      Food(
        id: 'fallback_002',
        name: '麻婆豆腐',
        description: '川菜经典，麻辣鲜香，豆腐嫩滑',
        cuisineType: '川菜',
        rating: 4.3,
        price: 18.0,
        tasteAttributes: ['麻', '辣', '鲜'],
      ),
      Food(
        id: 'fallback_003',
        name: '西红柿炒蛋',
        description: '简单家常菜，酸甜可口，营养丰富',
        cuisineType: '家常菜',
        rating: 4.2,
        price: 12.0,
        tasteAttributes: ['酸', '甜', '鲜'],
      ),
    ];

    _recommendedFoods.addAll(fallbackFoods);
  }

  /// 切换食物收藏状态 - Phase 2 实时反馈版本
  Future<void> toggleFoodFavorite(String foodId) async {
    // 使用统一服务处理收藏逻辑
    final unifiedService = UnifiedFoodDataService();
    await unifiedService.toggleFoodFavorite(foodId);

    // 记录用户行为 - 实时反馈
    await _feedbackService.recordUserAction(
      foodId,
      UserActionType.favorite,
      metadata: {
        'source': 'food_recommendation',
        'timestamp': DateTime.now().toIso8601String(),
      },
      immediate: true,
    );

    // 更新本地显示状态
    final index = _recommendedFoods.indexWhere((food) => food.id == foodId);
    if (index != -1) {
      final food = _recommendedFoods[index];
      _recommendedFoods[index] = food.copyWith(isFavorite: !food.isFavorite);

      // 触发增量同步
      _syncManager.performIncrementalSync();

      notifyListeners();
    }
  }

  /// 检查气泡是否被选中
  bool isBubbleSelected(Bubble bubble) {
    return _selectedBubbles.contains(bubble);
  }

  /// 排斥指定位置周围的气泡
  void repelBubblesFromPosition(Offset position, double repelRadius) {
    if (_screenSize != null) {
      ImprovedBubblePhysics.applyPhysics(_bubbles, _screenSize!, position);
      notifyListeners();
    }
  }

  /// 通过名称喜欢气泡
  Future<void> likeBubbleByName(String bubbleName) async {
    final bubble = _bubbles.firstWhere(
      (b) => b.name == bubbleName,
      orElse: () => _bubbles.first,
    );
    await _updateUserPreference(bubble, true);
  }

  /// 通过名称不喜欢气泡
  Future<void> dislikeBubbleByName(String bubbleName) async {
    final bubble = _bubbles.firstWhere(
      (b) => b.name == bubbleName,
      orElse: () => _bubbles.first,
    );
    await _updateUserPreference(bubble, false);
  }

  /// 通过名称忽略气泡
  void ignoreBubbleByName(String bubbleName) {
    final bubbleIndex = _bubbles.indexWhere((b) => b.name == bubbleName);
    if (bubbleIndex != -1) {
      final bubble = _bubbles[bubbleIndex];
      // 将气泡设置为半透明表示忽略状态
      _bubbles[bubbleIndex] = bubble.copyWith(opacity: 0.3);
      notifyListeners();
    }
  }

  /// 通过名称确认气泡
  void confirmBubbleByName(String bubbleName) {
    final bubble = _bubbles.firstWhere(
      (b) => b.name == bubbleName,
      orElse: () => _bubbles.first,
    );
    if (!_selectedBubbles.contains(bubble)) {
      toggleBubble(bubble);
    }
  }

  /// 获取推荐结果
  List<Food> get recommendations => _recommendedFoods;

  @override
  void dispose() {
    // Phase 2: 清理实时反馈资源
    _feedbackService.dispose();
    _syncManager.dispose();

    // 在这里清理资源，例如取消定时器、关闭流等
    super.dispose();
  }

  // Phase 2 新增方法

  /// 处理即时反馈
  void handleInstantFeedback(
    String itemId,
    InstantFeedbackType feedbackType,
    double intensity,
  ) {
    _feedbackService.handleInstantFeedback(itemId, feedbackType, intensity);
  }

  /// 获取实时统计
  Map<String, dynamic> getRealtimeStats() {
    return {
      'userActions': _feedbackService.getUserActionStatistics(),
      'syncStatus': _syncManager.getSyncStatistics(),
    };
  }

  /// 手动触发同步
  Future<void> manualSync() async {
    await _syncManager.performFullSync();
  }
}

/// 气泡手势
enum BubbleGesture {
  tap,
  longPress,
  swipeUp,
  swipeDown,
  swipeLeft,
  swipeRight,
  dragStart,
  dragUpdate,
  dragEnd,
}
