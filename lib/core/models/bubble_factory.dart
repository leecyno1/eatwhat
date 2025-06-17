import 'dart:math';
import 'package:flutter/material.dart';
import 'bubble.dart';

/// 气泡工厂类
class BubbleFactory {
  static final Random _random = Random();

  /// 创建默认气泡集合
  static List<Bubble> createDefaultBubbles() {
    final bubbles = <Bubble>[];
    
    // 口味气泡
    bubbles.addAll(_createTasteBubbles());
    
    // 菜系气泡
    bubbles.addAll(_createCuisineBubbles());
    
    // 食材气泡
    bubbles.addAll(_createIngredientBubbles());
    
    // 情境气泡
    bubbles.addAll(_createScenarioBubbles());
    
    // 营养气泡
    bubbles.addAll(_createNutritionBubbles());
    
    // 随机化位置和速度
    _randomizePositions(bubbles);
    
    return bubbles;
  }

  /// 创建口味气泡
  static List<Bubble> _createTasteBubbles() {
    final tastes = [
      {'name': '甜', 'icon': '🍯', 'color': Colors.pink},
      {'name': '酸', 'icon': '🍋', 'color': Colors.yellow},
      {'name': '辣', 'icon': '🌶️', 'color': Colors.red},
      {'name': '咸', 'icon': '🧂', 'color': Colors.grey},
      {'name': '鲜', 'icon': '🦐', 'color': Colors.orange},
      {'name': '香', 'icon': '🌿', 'color': Colors.green},
    ];

    return tastes.map((taste) => Bubble(
      type: BubbleType.taste,
      name: taste['name'] as String,
      icon: taste['icon'] as String,
      color: taste['color'] as Color,
      size: 40 + _random.nextDouble() * 20,
    )).toList();
  }

  /// 创建菜系气泡
  static List<Bubble> _createCuisineBubbles() {
    final cuisines = [
      {'name': '川菜', 'icon': '🌶️', 'color': Colors.red},
      {'name': '粤菜', 'icon': '🦆', 'color': Colors.brown},
      {'name': '湘菜', 'icon': '🥘', 'color': Colors.deepOrange},
      {'name': '鲁菜', 'icon': '🐟', 'color': Colors.blue},
      {'name': '苏菜', 'icon': '🦀', 'color': Colors.teal},
      {'name': '浙菜', 'icon': '🍤', 'color': Colors.cyan},
      {'name': '闽菜', 'icon': '🐠', 'color': Colors.indigo},
      {'name': '徽菜', 'icon': '🍖', 'color': Colors.purple},
      {'name': '日料', 'icon': '🍣', 'color': Colors.pink},
      {'name': '韩料', 'icon': '🥢', 'color': Colors.amber},
      {'name': '西餐', 'icon': '🍝', 'color': Colors.lime},
      {'name': '泰菜', 'icon': '🍜', 'color': Colors.lightGreen},
    ];

    return cuisines.map((cuisine) => Bubble(
      type: BubbleType.cuisine,
      name: cuisine['name'] as String,
      icon: cuisine['icon'] as String,
      color: cuisine['color'] as Color,
      size: 45 + _random.nextDouble() * 25,
    )).toList();
  }

  /// 创建食材气泡
  static List<Bubble> _createIngredientBubbles() {
    final ingredients = [
      {'name': '牛肉', 'icon': '🥩', 'color': Colors.red[700]!},
      {'name': '猪肉', 'icon': '🐷', 'color': Colors.pink[300]!},
      {'name': '鸡肉', 'icon': '🐔', 'color': Colors.orange[200]!},
      {'name': '鱼肉', 'icon': '🐟', 'color': Colors.blue[300]!},
      {'name': '虾', 'icon': '🦐', 'color': Colors.orange[400]!},
      {'name': '蟹', 'icon': '🦀', 'color': Colors.red[400]!},
      {'name': '蔬菜', 'icon': '🥬', 'color': Colors.green[400]!},
      {'name': '豆腐', 'icon': '🧈', 'color': Colors.grey[200]!},
      {'name': '蛋类', 'icon': '🥚', 'color': Colors.yellow[200]!},
      {'name': '面条', 'icon': '🍜', 'color': Colors.brown[200]!},
      {'name': '米饭', 'icon': '🍚', 'color': Colors.grey[100]!},
    ];

    return ingredients.map((ingredient) => Bubble(
      type: BubbleType.ingredient,
      name: ingredient['name'] as String,
      icon: ingredient['icon'] as String,
      color: ingredient['color'] as Color,
      size: 35 + _random.nextDouble() * 20,
    )).toList();
  }

  /// 创建情境气泡
  static List<Bubble> _createScenarioBubbles() {
    final scenarios = [
      {'name': '早餐', 'icon': '🌅', 'color': Colors.orange[300]!},
      {'name': '午餐', 'icon': '☀️', 'color': Colors.yellow[600]!},
      {'name': '晚餐', 'icon': '🌙', 'color': Colors.indigo[400]!},
      {'name': '夜宵', 'icon': '🌃', 'color': Colors.purple[400]!},
      {'name': '聚餐', 'icon': '👥', 'color': Colors.green[400]!},
      {'name': '约会', 'icon': '💕', 'color': Colors.pink[400]!},
      {'name': '工作餐', 'icon': '💼', 'color': Colors.grey[600]!},
      {'name': '家庭餐', 'icon': '🏠', 'color': Colors.brown[400]!},
      {'name': '快餐', 'icon': '⚡', 'color': Colors.red[500]!},
      {'name': '精致餐', 'icon': '✨', 'color': Colors.amber[400]!},
    ];

    return scenarios.map((scenario) => Bubble(
      type: BubbleType.scenario,
      name: scenario['name'] as String,
      icon: scenario['icon'] as String,
      color: scenario['color'] as Color,
      size: 40 + _random.nextDouble() * 25,
    )).toList();
  }

  /// 创建营养气泡
  static List<Bubble> _createNutritionBubbles() {
    final nutrition = [
      {'name': '高蛋白', 'icon': '💪', 'color': Colors.red[600]!},
      {'name': '低脂肪', 'icon': '🏃', 'color': Colors.green[600]!},
      {'name': '高纤维', 'icon': '🌾', 'color': Colors.brown[400]!},
      {'name': '维生素', 'icon': '🍊', 'color': Colors.orange[500]!},
      {'name': '低热量', 'icon': '📉', 'color': Colors.blue[500]!},
      {'name': '补钙', 'icon': '🦴', 'color': Colors.grey[300]!},
      {'name': '补铁', 'icon': '🩸', 'color': Colors.red[800]!},
    ];

    return nutrition.map((nut) => Bubble(
      type: BubbleType.nutrition,
      name: nut['name'] as String,
      icon: nut['icon'] as String,
      color: nut['color'] as Color,
      size: 35 + _random.nextDouble() * 20,
    )).toList();
  }

  /// 随机化气泡位置和速度
  static void _randomizePositions(List<Bubble> bubbles) {
    for (final bubble in bubbles) {
      bubble.position = Offset(
        _random.nextDouble() * 300,
        _random.nextDouble() * 600,
      );
      
      bubble.velocity = Offset(
        (_random.nextDouble() - 0.5) * 2,
        (_random.nextDouble() - 0.5) * 2,
      );
    }
  }

  /// 根据用户偏好创建个性化气泡
  static List<Bubble> createPersonalizedBubbles(Map<String, double> preferences) {
    final bubbles = createDefaultBubbles();
    
    // 根据偏好调整气泡大小和权重
    for (final bubble in bubbles) {
      final preference = preferences[bubble.name] ?? 0.5;
      bubble.size = bubble.size * (0.5 + preference);
      bubble.weight = preference;
    }
    
    return bubbles;
  }
} 