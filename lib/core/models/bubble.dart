import 'package:flutter/material.dart';
import 'package:hive/hive.dart';
import 'package:uuid/uuid.dart';

part 'bubble.g.dart';

/// 气泡类型枚举
@HiveType(typeId: 0)
enum BubbleType {
  @HiveField(0)
  taste,        // 口味
  @HiveField(1)
  cuisine,      // 菜系
  @HiveField(2)
  ingredient,   // 食材
  @HiveField(3)
  nutrition,    // 营养
  @HiveField(4)
  calorie,      // 热量
  @HiveField(5)
  scenario,     // 情境
  @HiveField(6)
  temperature,  // 温度
  @HiveField(7)
  spiciness,    // 辣度
}

/// 气泡数据模型
@HiveType(typeId: 1)
class Bubble {
  @HiveField(0)
  final String id;
  
  @HiveField(1)
  final BubbleType type;
  
  @HiveField(2)
  final String name;
  
  @HiveField(3)
  final String? icon;
  
  @HiveField(4)
  final Color color;
  
  @HiveField(5)
  final double size;
  
  @HiveField(6)
  final String? description;
  
  @HiveField(7)
  final Map<String, dynamic>? metadata;

  // 运行时属性（不持久化）
  Offset position;
  Offset velocity;
  double opacity;
  bool isSelected;
  bool isAnimating;
  double weight;

  Bubble({
    String? id,
    required this.type,
    required this.name,
    this.icon,
    required this.color,
    this.size = 300.0,
    this.description,
    this.metadata,
    this.position = Offset.zero,
    this.velocity = Offset.zero,
    this.opacity = 1.0,
    this.isSelected = false,
    this.isAnimating = false,
    this.weight = 1.0,
  }) : id = id ?? const Uuid().v4();

  /// 复制气泡并修改属性
  Bubble copyWith({
    String? id,
    BubbleType? type,
    String? name,
    String? icon,
    Color? color,
    double? size,
    String? description,
    Map<String, dynamic>? metadata,
    Offset? position,
    Offset? velocity,
    double? opacity,
    bool? isSelected,
    bool? isAnimating,
    double? weight,
  }) {
    return Bubble(
      id: id ?? this.id,
      type: type ?? this.type,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      color: color ?? this.color,
      size: size ?? this.size,
      description: description ?? this.description,
      metadata: metadata ?? this.metadata,
      position: position ?? this.position,
      velocity: velocity ?? this.velocity,
      opacity: opacity ?? this.opacity,
      isSelected: isSelected ?? this.isSelected,
      isAnimating: isAnimating ?? this.isAnimating,
      weight: weight ?? this.weight,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Bubble && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Bubble{id: $id, type: $type, name: $name, position: $position}';
  }
  
  /// 获取气泡的emoji和text
  String get emoji => icon ?? '🔮';
  String get text => name;
}

/// 气泡手势类型
enum BubbleGesture {
  swipeUp,      // 上滑（喜欢）
  swipeDown,    // 下滑（不喜欢）
  swipeLeft,    // 左滑（忽略）
  swipeRight,   // 右滑（收藏）
  tap,          // 点击（选择/取消选择）
  longPress,    // 长按（查看详情）
}

/// 气泡交互结果
class BubbleInteraction {
  final Bubble bubble;
  final BubbleGesture gesture;
  final DateTime timestamp;
  final Offset gesturePosition;
  final double gestureVelocity;

  BubbleInteraction({
    required this.bubble,
    required this.gesture,
    required this.timestamp,
    required this.gesturePosition,
    required this.gestureVelocity,
  });
}

/// 气泡工厂类
class BubbleFactory {
  static const Map<BubbleType, Color> _typeColors = {
    BubbleType.taste: Colors.orange,
    BubbleType.cuisine: Colors.red,
    BubbleType.ingredient: Colors.green,
    BubbleType.nutrition: Colors.blue,
    BubbleType.calorie: Colors.purple,
    BubbleType.scenario: Colors.teal,
    BubbleType.temperature: Colors.cyan,
    BubbleType.spiciness: Colors.deepOrange,
  };

  static const Map<BubbleType, String> _typeNames = {
    BubbleType.taste: '口味',
    BubbleType.cuisine: '菜系',
    BubbleType.ingredient: '食材',
    BubbleType.nutrition: '营养',
    BubbleType.calorie: '热量',
    BubbleType.scenario: '情境',
    BubbleType.temperature: '温度',
    BubbleType.spiciness: '辣度',
  };

  /// 创建预定义的气泡
  static List<Bubble> createDefaultBubbles() {
    return [
      // 口味类
      Bubble(
        type: BubbleType.taste,
        name: '甜',
        color: _typeColors[BubbleType.taste]!,
        icon: '🍯',
      ),
      Bubble(
        type: BubbleType.taste,
        name: '酸',
        color: _typeColors[BubbleType.taste]!,
        icon: '🍋',
      ),
      Bubble(
        type: BubbleType.taste,
        name: '咸',
        color: _typeColors[BubbleType.taste]!,
        icon: '🧂',
      ),
      
      // 菜系类
      Bubble(
        type: BubbleType.cuisine,
        name: '川菜',
        color: _typeColors[BubbleType.cuisine]!,
        icon: '🌶️',
      ),
      Bubble(
        type: BubbleType.cuisine,
        name: '粤菜',
        color: _typeColors[BubbleType.cuisine]!,
        icon: '🥟',
      ),
      Bubble(
        type: BubbleType.cuisine,
        name: '日料',
        color: _typeColors[BubbleType.cuisine]!,
        icon: '🍣',
      ),
      
      // 食材类
      Bubble(
        type: BubbleType.ingredient,
        name: '肉类',
        color: _typeColors[BubbleType.ingredient]!,
        icon: '🥩',
      ),
      Bubble(
        type: BubbleType.ingredient,
        name: '蔬菜',
        color: _typeColors[BubbleType.ingredient]!,
        icon: '🥬',
      ),
      Bubble(
        type: BubbleType.ingredient,
        name: '海鲜',
        color: _typeColors[BubbleType.ingredient]!,
        icon: '🦐',
      ),
      
      // 情境类
      Bubble(
        type: BubbleType.scenario,
        name: '早餐',
        color: _typeColors[BubbleType.scenario]!,
        icon: '🌅',
      ),
      Bubble(
        type: BubbleType.scenario,
        name: '午餐',
        color: _typeColors[BubbleType.scenario]!,
        icon: '☀️',
      ),
      Bubble(
        type: BubbleType.scenario,
        name: '晚餐',
        color: _typeColors[BubbleType.scenario]!,
        icon: '🌙',
      ),
    ];
  }

  /// 根据类型获取颜色
  static Color getColorByType(BubbleType type) {
    return _typeColors[type] ?? Colors.grey;
  }

  /// 根据类型获取名称
  static String getNameByType(BubbleType type) {
    return _typeNames[type] ?? '未知';
  }
} 