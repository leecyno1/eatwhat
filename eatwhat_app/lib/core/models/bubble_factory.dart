import 'package:flutter/material.dart';
import 'bubble.dart';

/// 气泡工厂类，用于创建预定义的气泡
class BubbleFactory {
  /// 创建默认气泡集合
  static List<Bubble> createDefaultBubbles() {
    return [
      // 口味类气泡
      ...createTasteBubbles(),
      // 菜系类气泡
      ...createCuisineBubbles(),
      // 食材类气泡
      ...createIngredientBubbles(),
      // 情境类气泡
      ...createScenarioBubbles(),
      // 营养类气泡
      ...createNutritionBubbles(),
    ];
  }

  /// 创建口味类气泡
  static List<Bubble> createTasteBubbles() {
    return [
      Bubble(
        type: BubbleType.taste,
        name: '甜',
        icon: '🍯',
        description: '甜味食物',
        color: Colors.pink.shade300,
        size: 60.0,
      ),
      Bubble(
        type: BubbleType.taste,
        name: '酸',
        icon: '🍋',
        description: '酸味食物',
        color: Colors.yellow.shade400,
        size: 55.0,
      ),
      Bubble(
        type: BubbleType.taste,
        name: '辣',
        icon: '🌶️',
        description: '辣味食物',
        color: Colors.red.shade400,
        size: 65.0,
      ),
      Bubble(
        type: BubbleType.taste,
        name: '咸',
        icon: '🧂',
        description: '咸味食物',
        color: Colors.grey.shade400,
        size: 50.0,
      ),
      Bubble(
        type: BubbleType.taste,
        name: '鲜',
        icon: '🦐',
        description: '鲜味食物',
        color: Colors.blue.shade300,
        size: 58.0,
      ),
    ];
  }

  /// 创建菜系类气泡
  static List<Bubble> createCuisineBubbles() {
    return [
      Bubble(
        type: BubbleType.cuisine,
        name: '川菜',
        icon: '🌶️',
        description: '四川菜系',
        color: Colors.red.shade500,
        size: 70.0,
      ),
      Bubble(
        type: BubbleType.cuisine,
        name: '粤菜',
        icon: '🦆',
        description: '广东菜系',
        color: Colors.orange.shade400,
        size: 68.0,
      ),
      Bubble(
        type: BubbleType.cuisine,
        name: '湘菜',
        icon: '🌶️',
        description: '湖南菜系',
        color: Colors.deepOrange.shade400,
        size: 65.0,
      ),
      Bubble(
        type: BubbleType.cuisine,
        name: '鲁菜',
        icon: '🥟',
        description: '山东菜系',
        color: Colors.brown.shade400,
        size: 62.0,
      ),
      Bubble(
        type: BubbleType.cuisine,
        name: '苏菜',
        icon: '🦀',
        description: '江苏菜系',
        color: Colors.green.shade400,
        size: 60.0,
      ),
      Bubble(
        type: BubbleType.cuisine,
        name: '浙菜',
        icon: '🐟',
        description: '浙江菜系',
        color: Colors.teal.shade400,
        size: 58.0,
      ),
      Bubble(
        type: BubbleType.cuisine,
        name: '闽菜',
        icon: '🦪',
        description: '福建菜系',
        color: Colors.cyan.shade400,
        size: 56.0,
      ),
      Bubble(
        type: BubbleType.cuisine,
        name: '徽菜',
        icon: '🐷',
        description: '安徽菜系',
        color: Colors.indigo.shade400,
        size: 54.0,
      ),
    ];
  }

  /// 创建食材类气泡
  static List<Bubble> createIngredientBubbles() {
    return [
      Bubble(
        type: BubbleType.ingredient,
        name: '猪肉',
        icon: '🐷',
        description: '猪肉类食材',
        color: Colors.pink.shade400,
        size: 55.0,
      ),
      Bubble(
        type: BubbleType.ingredient,
        name: '牛肉',
        icon: '🐄',
        description: '牛肉类食材',
        color: Colors.brown.shade500,
        size: 58.0,
      ),
      Bubble(
        type: BubbleType.ingredient,
        name: '鸡肉',
        icon: '🐔',
        description: '鸡肉类食材',
        color: Colors.orange.shade300,
        size: 52.0,
      ),
      Bubble(
        type: BubbleType.ingredient,
        name: '鱼',
        icon: '🐟',
        description: '鱼类食材',
        color: Colors.blue.shade400,
        size: 50.0,
      ),
      Bubble(
        type: BubbleType.ingredient,
        name: '虾',
        icon: '🦐',
        description: '虾类食材',
        color: Colors.red.shade300,
        size: 48.0,
      ),
      Bubble(
        type: BubbleType.ingredient,
        name: '蔬菜',
        icon: '🥬',
        description: '蔬菜类食材',
        color: Colors.green.shade500,
        size: 60.0,
      ),
      Bubble(
        type: BubbleType.ingredient,
        name: '豆腐',
        icon: '🧈',
        description: '豆制品',
        color: Colors.grey.shade300,
        size: 45.0,
      ),
      Bubble(
        type: BubbleType.ingredient,
        name: '蛋',
        icon: '🥚',
        description: '蛋类食材',
        color: Colors.yellow.shade300,
        size: 47.0,
      ),
    ];
  }

  /// 创建情境类气泡
  static List<Bubble> createScenarioBubbles() {
    return [
      Bubble(
        type: BubbleType.scenario,
        name: '早餐',
        icon: '🌅',
        description: '早餐时间',
        color: Colors.amber.shade300,
        size: 65.0,
      ),
      Bubble(
        type: BubbleType.scenario,
        name: '午餐',
        icon: '☀️',
        description: '午餐时间',
        color: Colors.orange.shade400,
        size: 70.0,
      ),
      Bubble(
        type: BubbleType.scenario,
        name: '晚餐',
        icon: '🌙',
        description: '晚餐时间',
        color: Colors.purple.shade400,
        size: 68.0,
      ),
      Bubble(
        type: BubbleType.scenario,
        name: '夜宵',
        icon: '🌃',
        description: '夜宵时间',
        color: Colors.indigo.shade500,
        size: 60.0,
      ),
      Bubble(
        type: BubbleType.scenario,
        name: '聚餐',
        icon: '👥',
        description: '聚餐场合',
        color: Colors.green.shade400,
        size: 62.0,
      ),
      Bubble(
        type: BubbleType.scenario,
        name: '快餐',
        icon: '⚡',
        description: '快速用餐',
        color: Colors.red.shade400,
        size: 55.0,
      ),
      Bubble(
        type: BubbleType.scenario,
        name: '外卖',
        icon: '🛵',
        description: '外卖订餐',
        color: Colors.blue.shade400,
        size: 58.0,
      ),
      Bubble(
        type: BubbleType.scenario,
        name: '下厨',
        icon: '👨‍🍳',
        description: '自己做饭',
        color: Colors.teal.shade400,
        size: 53.0,
      ),
    ];
  }

  /// 创建营养类气泡
  static List<Bubble> createNutritionBubbles() {
    return [
      Bubble(
        type: BubbleType.nutrition,
        name: '高蛋白',
        icon: '💪',
        description: '高蛋白食物',
        color: Colors.red.shade500,
        size: 60.0,
      ),
      Bubble(
        type: BubbleType.nutrition,
        name: '低脂',
        icon: '🥗',
        description: '低脂肪食物',
        color: Colors.green.shade500,
        size: 58.0,
      ),
      Bubble(
        type: BubbleType.nutrition,
        name: '高纤维',
        icon: '🌾',
        description: '高纤维食物',
        color: Colors.brown.shade400,
        size: 55.0,
      ),
      Bubble(
        type: BubbleType.nutrition,
        name: '维生素',
        icon: '🍊',
        description: '富含维生素',
        color: Colors.orange.shade400,
        size: 52.0,
      ),
      Bubble(
        type: BubbleType.nutrition,
        name: '低糖',
        icon: '🚫',
        description: '低糖食物',
        color: Colors.grey.shade500,
        size: 50.0,
      ),
      Bubble(
        type: BubbleType.nutrition,
        name: '补钙',
        icon: '🦴',
        description: '补钙食物',
        color: Colors.white,
        size: 48.0,
      ),
    ];
  }

  /// 根据类型创建气泡
  static List<Bubble> createBubblesByType(BubbleType type) {
    switch (type) {
      case BubbleType.taste:
        return createTasteBubbles();
      case BubbleType.cuisine:
        return createCuisineBubbles();
      case BubbleType.ingredient:
        return createIngredientBubbles();
      case BubbleType.scenario:
        return createScenarioBubbles();
      case BubbleType.nutrition:
        return createNutritionBubbles();
    }
  }

  /// 创建自定义气泡
  static Bubble createCustomBubble({
    required BubbleType type,
    required String name,
    String? icon,
    String? description,
    Color? color,
    double? size,
  }) {
    return Bubble(
      type: type,
      name: name,
      icon: icon,
      description: description,
      color: color ?? Colors.blue.shade400,
      size: size ?? 50.0,
    );
  }
} 