import 'dart:async';
import 'package:flutter/material.dart';
import '../../../core/models/bubble.dart';
import '../../../core/models/food.dart';
import '../../../core/models/user_preference.dart';
import '../../../core/models/bubble_factory.dart';
import '../../../core/physics/optimized_bubble_physics.dart';
import '../../../core/services/recommendation_engine.dart';
import '../../../core/services/user_preference_service.dart';
import '../../../core/utils/performance_optimizer.dart';

/// 气泡控制器
class BubbleController extends PerformanceOptimizer.DebouncedNotifier {
  // 气泡相关
  List<Bubble> _bubbles = [];
  List<Bubble> _selectedBubbles = [];
  Bubble? _selectedBubble; // 用于跟踪当前被拖拽的气泡
  OptimizedBubblePhysics? _physics;
  Timer? _physicsTimer;
  
  // 推荐相关
  List<Food> _recommendations = [];
  bool _isGeneratingRecommendations = false;
  
  // 用户偏好
  UserPreference _userPreference = UserPreference(userId: 'default_user');
  
  // 状态
  bool _isInitialized = false;
  Size _screenSize = Size.zero;
  
  // 性能优化组件
  late final PerformanceOptimizer.FrameRateLimiter _frameRateLimiter;
  late final PerformanceOptimizer.BatchUpdateManager _batchUpdateManager;

  // Getters
  List<Bubble> get bubbles => _bubbles;
  List<Bubble> get selectedBubbles => _selectedBubbles;
  List<Food> get recommendations => _recommendations;
  bool get isGeneratingRecommendations => _isGeneratingRecommendations;
  UserPreference get userPreference => _userPreference;
  bool get isInitialized => _isInitialized;
  int get selectedCount => _selectedBubbles.length;

  /// 初始化控制器
  void initialize(Size screenSize) {
    if (_isInitialized) return;
    
    // 初始化性能优化组件
    _frameRateLimiter = PerformanceOptimizer.FrameRateLimiter(
      minInterval: const Duration(milliseconds: 16), // 60 FPS
    );
    _batchUpdateManager = PerformanceOptimizer.BatchUpdateManager(
      batchInterval: const Duration(milliseconds: 16),
    );
    
    _screenSize = screenSize;
    _physics = OptimizedBubblePhysics(screenSize: screenSize);
    
    // 创建默认气泡
    _bubbles = BubbleFactory.createDefaultBubbles();
    
    // 随机分布气泡
    _physics!.randomDistributeBubbles(_bubbles);
    
    // 启动物理引擎
    _startPhysicsEngine();
    
    // 异步加载用户偏好
    _loadUserPreferences();
    
    _isInitialized = true;
    immediateNotify();
  }
  
  /// 加载用户偏好
  Future<void> _loadUserPreferences() async {
    try {
      _userPreference = await UserPreferenceService.getUserPreference();
      notifyListeners();
    } catch (e) {
      print('Failed to load user preferences: $e');
    }
  }

  /// 启动物理引擎
  void _startPhysicsEngine() {
    _physicsTimer?.cancel();
    _physicsTimer = Timer.periodic(const Duration(milliseconds: 16), (timer) {
      if (_physics != null && _bubbles.isNotEmpty) {
        // 使用帧率限制器控制更新频率
        if (_frameRateLimiter.shouldUpdate()) {
          PerformanceOptimizer.PerformanceProfiler.startTiming('physics_update');
          _physics!.updateBubbles(_bubbles, 0.016);
          PerformanceOptimizer.PerformanceProfiler.endTiming('physics_update');
          
          // 使用防抖动通知
          debouncedNotify();
        }
      }
    });
  }

  /// 停止物理引擎
  void _stopPhysicsEngine() {
    _physicsTimer?.cancel();
    _physicsTimer = null;
    _batchUpdateManager.dispose();
  }

  /// 选择气泡
  void selectBubble(Bubble bubble) {
    if (bubble.isSelected) return;
    
    bubble.isSelected = true;
    bubble.clickCount++; // 增加点击次数
    _selectedBubbles.add(bubble);
    
    // 更新用户偏好和气泡大小
    _updateUserPreference(bubble, BubbleGesture.tap);
    bubble.size = _calculateBubbleSize(bubble); // 根据点击次数更新气泡大小
    debouncedNotify();
  }

  /// 根据气泡的点击次数计算气泡大小
  double _calculateBubbleSize(Bubble bubble) {
    // 基础大小
    double baseSize = 50.0;
    // 根据点击次数增加大小，可以根据需要调整这个逻辑
    double sizeIncrease = bubble.clickCount * 5.0;
    // 限制最大和最小尺寸
    return (baseSize + sizeIncrease).clamp(30.0, 150.0);
  }

  /// 取消选择气泡
  void deselectBubble(Bubble bubble) {
    if (!bubble.isSelected) return;
    
    bubble.isSelected = false;
    _selectedBubbles.remove(bubble);
    
    debouncedNotify();
  }

  /// 切换气泡选择状态
  void toggleBubble(Bubble bubble) {
    if (bubble.isSelected) {
      deselectBubble(bubble);
    } else {
      selectBubble(bubble);
    }
  }

  /// 处理气泡手势
  void handleBubbleGesture(Bubble bubble, BubbleGesture gesture, {DragUpdateDetails? dragDetails}) {
    // 在拖拽更新时，确保 dragDetails 不为 null
    if (gesture == BubbleGesture.dragUpdate && dragDetails == null) {
      // 如果是拖拽更新但 dragDetails 为空，则不进行处理或记录错误
      print('Error: dragDetails is null for dragUpdate gesture.');
      return;
    }
    switch (gesture) {
      case BubbleGesture.tap:
        toggleBubble(bubble);
        break;
            case BubbleGesture.swipeUp:
        _handleSwipeUp(bubble);
        break;
      case BubbleGesture.swipeDown:
        _handleSwipeDown(bubble);
        break;
      case BubbleGesture.dragStart:
        // 选中被拖拽的气泡
        _selectedBubble = bubble;
        if (_selectedBubble != null) {
          _selectedBubble!.isBeingDragged = true;
          _selectedBubble!.velocity = Offset.zero; // 停止物理引擎对该气泡的影响
          immediateNotify(); // 拖拽开始需要立即响应
        }
        break;
      case BubbleGesture.dragUpdate:
        if (_selectedBubble != null && _selectedBubble!.id == bubble.id && dragDetails != null) {
          // 更新被拖拽气泡的位置
          _selectedBubble!.position += dragDetails.delta;
          // 拖拽过程中使用批量更新减少重绘
          _batchUpdateManager.addUpdate(() => debouncedNotify());
        }
        break;
      case BubbleGesture.dragEnd:
        if (_selectedBubble != null && _selectedBubble!.isBeingDragged) {
          _selectedBubble!.isBeingDragged = false;
          // 可选：根据拖拽结束时的速度给气泡一个初始速度
          // _selectedBubble!.velocity = gestureDetails.velocity; // 假设 gestureDetails 包含速度信息
        }
        _selectedBubble = null; // 拖拽结束后取消选中
        immediateNotify(); // 拖拽结束需要立即响应
        break;
      case BubbleGesture.longPress:
        _handleLongPress(bubble);
        break;
    }
    
    _updateUserPreference(bubble, gesture);
  }

  /// 处理上滑（搜索关键词）
  void _handleSwipeUp(Bubble bubble) {
    // 标记为搜索关键词，例如改变颜色
    // bubble.color = Colors.red; // 示例：将颜色变为红色
    // 这里可以添加更复杂的逻辑，比如将关键词添加到搜索列表
    print('Bubble swiped up: ${bubble.name}');
    final newBubble = bubble.copyWith(color: Colors.red);
    _updateBubbleInList(bubble, newBubble);
    notifyListeners();
    
    // 从选中列表中移除
    if (newBubble.isSelected) {
      deselectBubble(newBubble);
    }
  }

  /// 处理下滑（排除关键词）
  void _handleSwipeDown(Bubble bubble) {
    // 标记为排除关键词，例如改变颜色或透明度
    // bubble.color = Colors.grey; // 示例：将颜色变为灰色
    // bubble.opacity = 0.5; // 示例：降低透明度
    // 这里可以添加更复杂的逻辑，比如将关键词添加到排除列表
    print('Bubble swiped down: ${bubble.name}');
    final newBubble = bubble.copyWith(color: Colors.grey);
    _updateBubbleInList(bubble, newBubble);
    notifyListeners();
  }

  // Helper method to update a bubble in the _bubbles list
  void _updateBubbleInList(Bubble oldBubble, Bubble newBubble) {
    final index = _bubbles.indexWhere((b) => b.id == oldBubble.id);
    if (index != -1) {
      _bubbles[index] = newBubble;
      // If the bubble was selected, update it in the _selectedBubbles list as well
      final selectedIndex = _selectedBubbles.indexWhere((b) => b.id == oldBubble.id);
      if (selectedIndex != -1) {
        _selectedBubbles[selectedIndex] = newBubble;
      }
      // If the bubble was the currently dragged bubble, update _selectedBubble
      if (_selectedBubble?.id == oldBubble.id) {
        _selectedBubble = newBubble;
      }
    }
  }

  /// 处理长按
  void _handleLongPress(Bubble bubble) {
    // 显示气泡详情或执行特殊操作
    // 这里可以添加震动反馈等
  }

  /// 更新用户偏好
  void _updateUserPreference(Bubble bubble, BubbleGesture gesture) {
    double score = 0.0;
    
    switch (gesture) {
      case BubbleGesture.tap:
        score = bubble.isSelected ? 1.0 : -0.5;
        break;
      case BubbleGesture.swipeUp: // 上滑，红色，搜索关键词
        score = 2.0; // 假设上滑表示强烈的正向偏好
        break;
      case BubbleGesture.swipeDown: // 下滑，灰色，排除关键词
        score = -2.0; // 假设下滑表示强烈的负向偏好
        break;
      // 对于拖拽手势，通常不直接影响用户偏好分数，除非有特定业务逻辑
      case BubbleGesture.dragStart:
      case BubbleGesture.dragUpdate:
      case BubbleGesture.dragEnd:
        // 拖拽操作不改变偏好分数
        break;
      case BubbleGesture.longPress:
        score = 0.5;
        break;
    }
    
    // 更新用户偏好并保存到存储
    if (score != 0) {
      _userPreference = _userPreference.updateBubblePreference(bubble.name, score);
      _saveUserPreferences();
    }
    
    bubble.size = _calculateBubbleSize(bubble); // 根据点击次数更新气泡大小
    debouncedNotify();
  }
  
  /// 保存用户偏好
  Future<void> _saveUserPreferences() async {
    try {
      await UserPreferenceService.saveUserPreference(_userPreference);
    } catch (e) {
      print('Failed to save user preferences: $e');
    }
  }

  /// 生成推荐
  Future<void> generateRecommendations() async {
    _isGeneratingRecommendations = true;
    immediateNotify(); // 开始生成时立即通知

    // 模拟网络请求或复杂计算
    await Future.delayed(const Duration(seconds: 2));

    try {
      PerformanceOptimizer.PerformanceProfiler.startTiming('generate_recommendations');
      // 基于选中的气泡和用户偏好生成个性化推荐
      _recommendations = RecommendationEngine.generatePersonalizedRecommendations(
        _selectedBubbles,
        _userPreference,
      );
      PerformanceOptimizer.PerformanceProfiler.endTiming('generate_recommendations');
    } catch (e) {
      print('Error generating recommendations: $e');
      _recommendations = [];
    } finally {
      _isGeneratingRecommendations = false;
      immediateNotify(); // 完成时立即通知
    }
  }

  /// 切换食物收藏状态
  void toggleFoodFavorite(Food food) {
    final index = _recommendations.indexOf(food);
    if (index != -1) {
      final newFavoriteStatus = !food.isFavorite;
      _recommendations[index] = food.copyWith(isFavorite: newFavoriteStatus);
      
      // 更新用户偏好
      if (newFavoriteStatus) {
        _userPreference = _userPreference.addFavoriteFood(food.name);
      } else {
        _userPreference = _userPreference.removeFavoriteFood(food.name);
      }
      
      // 保存到存储
      _saveUserPreferences();
      
      debouncedNotify();
    }
  }

  /// 重置选择
  void resetSelection() {
    for (var bubble in _selectedBubbles) {
      bubble.isSelected = false;
    }
    _selectedBubbles.clear();
    notifyListeners();
  }

  /// 重置所有气泡
  void resetAllBubbles() {
    _bubbles.clear();
    _selectedBubbles.clear();
    _bubbles = BubbleFactory.createDefaultBubbles();
    _physics?.randomDistributeBubbles(_bubbles);
    notifyListeners();
  }

  /// 从指定位置排斥气泡
  void repelBubblesFromPosition(Offset position, {double strength = 1.0}) {
    _physics?.repelBubblesFromPosition(_bubbles, position, strength: strength);
    notifyListeners();
  }

  /// 在指定位置施加力
  void addForceAtPosition(Offset position, Offset force, {double radius = 50.0}) {
    _physics?.addForceAtPosition(_bubbles, position, force, radius: radius);
    notifyListeners();
  }


}
