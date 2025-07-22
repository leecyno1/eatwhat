import 'package:flutter/material.dart';
import '../../../core/models/bubble.dart';
import '../../../core/models/bubble_factory.dart';
import '../../../core/models/food.dart';
import '../../../core/models/user_preference.dart';
import '../../../core/services/storage_service.dart';
import '../../../core/physics/improved_bubble_physics.dart';
import '../../../core/services/unified_food_data_service.dart';
import '../../../core/utils/performance_optimizer.dart';

/// 优化后的气泡控制器 - 减少不必要的重绘和内存使用
class BubbleController extends DebouncedNotifier {
  final List<Bubble> _bubbles = [];
  final List<Bubble> _selectedBubbles = [];
  final List<Food> _recommendedFoods = [];

  // final StorageService _storageService; // 未使用，暂时注释掉
  late UserPreference _userPreference;

  // 状态标识
  bool _isInitialized = false;
  bool _isLoading = false;
  bool _isGeneratingRecommendations = false;
  Size? _screenSize;
  
  // TODO: 后续应从AuthService获取
  final String _currentUserId = 'default_user'; 

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

  /// 切换气泡选择状态 - 优化版本，减少重绘
  void toggleBubble(Bubble bubble) {
    final index = _bubbles.indexWhere((b) => b.id == bubble.id);
    if (index == -1) return;

    PerformanceOptimizer().recordInteraction();

    final isSelected = !_bubbles[index].isSelected;
    _bubbles[index] = bubble.copyWith(isSelected: isSelected);

    _selectedBubbles.removeWhere((b) => b.id == bubble.id);
    if (isSelected) {
      _selectedBubbles.add(_bubbles[index]);
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

  /// 喜欢气泡
  void likeBubble(Bubble bubble) {
    if (!_selectedBubbles.any((b) => b.id == bubble.id)) {
      _selectedBubbles.add(bubble.copyWith(isSelected: true));
    }
    _updateUserPreference(bubble, true);
    notifyListeners();
  }

  /// 不喜欢气泡
  void dislikeBubble(Bubble bubble) {
    _selectedBubbles.removeWhere((b) => b.id == bubble.id);
    _updateUserPreference(bubble, false);
    notifyListeners();
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
        toggleBubble(bubble);
        break;
      case BubbleGesture.swipeUp:
        likeBubble(bubble);
        break;
      case BubbleGesture.swipeDown:
        dislikeBubble(bubble);
        break;
      case BubbleGesture.longPress:
        debugPrint('查看气泡详情: ${bubble.name}');
        break;
      // 其他手势可以后续添加
      default:
        break;
    }
    _savePreferences();
  }

  /// 更新用户偏好
  void _updateUserPreference(Bubble bubble, bool isLiked) {
    // 这里可以实现用户偏好的更新逻辑
    // 示例：更新口味偏好
    if (isLiked) {
      _userPreference = _userPreference.updateTastePreference(bubble.name, 1.0);
    } else {
      _userPreference = _userPreference.updateTastePreference(bubble.name, -1.0);
    }
  }

  /// 保存偏好到存储
  void _savePreferences() {
    StorageService.saveUserPreference(_userPreference);
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

  /// 切换食物收藏状态
  Future<void> toggleFoodFavorite(String foodId) async {
    // 使用统一服务处理收藏逻辑
    final unifiedService = UnifiedFoodDataService();
    await unifiedService.toggleFoodFavorite(foodId);
    
    // 记录用户行为
    await unifiedService.recordUserAction(
      foodId, 
      UserActionType.favorite,
    );
    
    // 更新本地显示状态
    final index = _recommendedFoods.indexWhere((food) => food.id == foodId);
    if (index != -1) {
      final food = _recommendedFoods[index];
      _recommendedFoods[index] = food.copyWith(isFavorite: !food.isFavorite);
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
  void likeBubbleByName(String bubbleName) {
    final bubble = _bubbles.firstWhere(
      (b) => b.name == bubbleName,
      orElse: () => _bubbles.first,
    );
    _updateUserPreference(bubble, true);
    _savePreferences();
  }

  /// 通过名称不喜欢气泡
  void dislikeBubbleByName(String bubbleName) {
    final bubble = _bubbles.firstWhere(
      (b) => b.name == bubbleName,
      orElse: () => _bubbles.first,
    );
    _updateUserPreference(bubble, false);
    _savePreferences();
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
    // 在这里清理资源，例如取消定时器、关闭流等
    super.dispose();
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
