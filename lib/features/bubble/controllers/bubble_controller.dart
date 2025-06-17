import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import '../../../core/models/bubble.dart';
import '../../../core/models/bubble_factory.dart';
import '../../../core/models/food.dart';
import '../../../core/models/user_preference.dart';

/// 气泡控制器
class BubbleController extends ChangeNotifier {
  final List<Bubble> _bubbles = [];
  final List<Bubble> _selectedBubbles = [];
  final List<Food> _recommendedFoods = [];
  
  UserPreference? _userPreference;
  bool _isLoading = false;

  // Getters
  List<Bubble> get bubbles => _bubbles;
  List<Bubble> get selectedBubbles => _selectedBubbles;
  UserPreference? get userPreference => _userPreference;
  List<Food> get recommendedFoods => _recommendedFoods;
  bool get isLoading => _isLoading;
  bool get isInitialized => _bubbles.isNotEmpty;

  /// 初始化气泡
  void initializeBubbles() {
    _bubbles.clear();
    _bubbles.addAll(BubbleFactory.createDefaultBubbles());
    notifyListeners();
  }

  /// 初始化（带屏幕尺寸）
  void initialize(Size screenSize) {
    _bubbles.clear();
    _bubbles.addAll(BubbleFactory.createDefaultBubbles());
    
    // 随机分布气泡位置
    final random = Random();
    for (final bubble in _bubbles) {
      bubble.position = Offset(
        random.nextDouble() * (screenSize.width - bubble.size) + bubble.size / 2,
        random.nextDouble() * (screenSize.height - bubble.size) + bubble.size / 2,
      );
    }
    
    notifyListeners();
  }

  /// 简化的气泡切换
  void toggleBubble(Bubble bubble) {
    final index = _bubbles.indexWhere((b) => b.id == bubble.id);
    if (index != -1) {
      _bubbles[index] = bubble.copyWith(isSelected: !bubble.isSelected);
      
      if (_bubbles[index].isSelected) {
        if (!_selectedBubbles.any((b) => b.id == bubble.id)) {
          _selectedBubbles.add(_bubbles[index]);
        }
      } else {
        _selectedBubbles.removeWhere((b) => b.id == bubble.id);
      }
      
      notifyListeners();
    }
  }

  /// 重置选择
  void resetSelection() {
    for (int i = 0; i < _bubbles.length; i++) {
      _bubbles[i] = _bubbles[i].copyWith(isSelected: false);
    }
    _selectedBubbles.clear();
    notifyListeners();
  }

  /// 重置所有气泡
  void resetAllBubbles() {
    resetSelection();
    initializeBubbles();
  }

  /// 切换气泡选择状态
  void toggleBubbleSelection(Bubble bubble) {
    if (_selectedBubbles.contains(bubble)) {
      _selectedBubbles.remove(bubble);
    } else {
      _selectedBubbles.add(bubble);
    }
    notifyListeners();
  }

  /// 清除所有选择
  void clearSelection() {
    _selectedBubbles.clear();
    _recommendedFoods.clear();
    notifyListeners();
  }

  /// 喜欢气泡
  void likeBubble(Bubble bubble) {
    if (!_selectedBubbles.contains(bubble)) {
      _selectedBubbles.add(bubble);
    }
    _updateUserPreference(bubble, true);
    notifyListeners();
  }

  /// 不喜欢气泡
  void dislikeBubble(Bubble bubble) {
    _selectedBubbles.remove(bubble);
    _updateUserPreference(bubble, false);
    notifyListeners();
  }

  /// 忽略气泡
  void ignoreBubble(Bubble bubble) {
    _selectedBubbles.remove(bubble);
    notifyListeners();
  }

  /// 处理气泡手势
  void handleBubbleGesture(Bubble bubble, BubbleGesture gesture, Offset position, double velocity) {
    switch (gesture) {
      case BubbleGesture.tap:
        toggleBubbleSelection(bubble);
        break;
      case BubbleGesture.swipeUp:
        likeBubble(bubble);
        break;
      case BubbleGesture.swipeDown:
        dislikeBubble(bubble);
        break;
      case BubbleGesture.swipeRight:
        if (!_selectedBubbles.contains(bubble)) {
          _selectedBubbles.add(bubble);
        }
        _updateUserPreference(bubble, true);
        break;
      case BubbleGesture.swipeLeft:
        ignoreBubble(bubble);
        break;
      case BubbleGesture.longPress:
        debugPrint('查看气泡详情: ${bubble.name}');
        break;
    }
    notifyListeners();
  }

  /// 更新用户偏好
  void _updateUserPreference(Bubble bubble, bool isLiked) {
    // 这里可以实现用户偏好的更新逻辑
    // 暂时简化处理
  }

  /// 生成推荐
  Future<void> generateRecommendations() async {
    _isLoading = true;
    notifyListeners();

    try {
      // 模拟网络请求延迟
      await Future.delayed(const Duration(milliseconds: 800));

      // 简化的推荐逻辑
      _recommendedFoods.clear();
      for (final bubble in _selectedBubbles) {
        // 基于气泡类型生成简单的推荐
        _recommendedFoods.add(Food(
          id: 'food_${bubble.id}',
          name: '推荐${bubble.name}',
          description: '基于你对${bubble.name}的喜好推荐',
          cuisineType: bubble.name,
          rating: 4.0 + Random().nextDouble(),
          price: 20.0 + Random().nextDouble() * 30,
          tasteAttributes: [bubble.name],
        ));
      }

    } catch (e) {
      debugPrint('生成推荐时出错: $e');
      _recommendedFoods.clear();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// 切换食物收藏状态
  void toggleFoodFavorite(String foodId) {
    final index = _recommendedFoods.indexWhere((food) => food.id == foodId);
    if (index != -1) {
      _recommendedFoods[index] = _recommendedFoods[index].copyWith(
        isFavorite: !_recommendedFoods[index].isFavorite,
      );
      notifyListeners();
    }
  }

  /// 排斥气泡位置
  void repelBubblesFromPosition(Offset position, double force) {
    for (final bubble in _bubbles) {
      final distance = (bubble.position - position).distance;
      if (distance < 100) {
        final direction = (bubble.position - position).direction;
        bubble.position = Offset(
          bubble.position.dx + cos(direction) * force,
          bubble.position.dy + sin(direction) * force,
        );
      }
    }
    notifyListeners();
  }

  /// 在位置添加力
  void addForceAtPosition(Offset position, double force) {
    repelBubblesFromPosition(position, force);
  }

  /// 重置推荐
  void resetRecommendations() {
    _recommendedFoods.clear();
    notifyListeners();
  }

  /// 获取气泡统计信息
  Map<BubbleType, int> getBubbleStats() {
    final stats = <BubbleType, int>{};
    for (final bubble in _selectedBubbles) {
      stats[bubble.type] = (stats[bubble.type] ?? 0) + 1;
    }
    return stats;
  }

  /// 获取推荐置信度
  double getRecommendationConfidence() {
    if (_selectedBubbles.isEmpty) return 0.0;
    if (_selectedBubbles.length < 3) return 0.3;
    if (_selectedBubbles.length < 5) return 0.6;
    return 0.9;
  }

  /// 添加自定义气泡
  void addCustomBubble(Bubble bubble) {
    _bubbles.add(bubble);
    notifyListeners();
  }

  /// 移除气泡
  void removeBubble(String bubbleId) {
    _bubbles.removeWhere((bubble) => bubble.id == bubbleId);
    _selectedBubbles.removeWhere((bubble) => bubble.id == bubbleId);
    notifyListeners();
  }

  @override
  void dispose() {
    super.dispose();
  }
} 