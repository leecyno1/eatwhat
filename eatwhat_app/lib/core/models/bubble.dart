import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

/// 气泡类型枚举
enum BubbleType {
  taste,      // 口味
  cuisine,    // 菜系
  ingredient, // 食材
  scenario,   // 情境
  nutrition,  // 营养
}

/// 气泡手势枚举
enum BubbleGesture {
  tap,        // 点击
  swipeUp,    // 上滑
  swipeDown,  // 下滑
  longPress,  // 长按
  dragStart,  // 开始拖拽
  dragUpdate, // 拖拽中
  dragEnd,    // 结束拖拽
}

/// 气泡模型
class Bubble {
  final String id;
  final BubbleType type;
  final String name;
  final String? icon;
  final String? description;
  final Color color;
  double size;
  double currentDisplaySize; // 用于碰撞检测的实际显示大小
  Offset position;
  Offset velocity;
  double weight;
  bool isSelected;
  bool isVisible;
  double opacity;
  int clickCount; // 新增点击次数字段
  bool isBeingDragged; // 新增拖拽状态字段

  Bubble({
    String? id,
    required this.type,
    required this.name,
    this.icon,
    this.description,
    required this.color,
    this.size = 50.0,
    this.position = Offset.zero,
    this.velocity = Offset.zero,
    this.weight = 1.0,
    this.isSelected = false,
    this.isVisible = true,
    this.opacity = 1.0,
    double? currentDisplaySize, // 添加为可选命名参数
    this.clickCount = 0, // 初始化点击次数为0
    this.isBeingDragged = false, // 初始化拖拽状态为false
  }) : id = id ?? const Uuid().v4(),
       this.currentDisplaySize = currentDisplaySize ?? size; // 初始化

  /// 复制气泡并修改部分属性
  Bubble copyWith({
    String? id,
    BubbleType? type,
    String? name,
    String? icon,
    String? description,
    Color? color,
    double? size,
    Offset? position,
    Offset? velocity,
    double? weight,
    bool? isSelected,
    bool? isVisible,
    double? opacity,
    double? currentDisplaySize,
    int? clickCount,
    bool? isBeingDragged,
  }) {
    return Bubble(
      id: id ?? this.id,
      type: type ?? this.type,
      name: name ?? this.name,
      icon: icon ?? this.icon,
      description: description ?? this.description,
      color: color ?? this.color,
      size: size ?? this.size,
      position: position ?? this.position,
      velocity: velocity ?? this.velocity,
      weight: weight ?? this.weight,
      isSelected: isSelected ?? this.isSelected,
      isVisible: isVisible ?? this.isVisible,
      opacity: opacity ?? this.opacity,
      currentDisplaySize: currentDisplaySize ?? this.currentDisplaySize,
      clickCount: clickCount ?? this.clickCount,
      isBeingDragged: isBeingDragged ?? this.isBeingDragged,
    );
  }

  /// 转换为JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'type': type.index,
      'name': name,
      'icon': icon,
      'description': description,
      'color': color.value,
      'size': size,
      'weight': weight,
      'isSelected': isSelected,
      'isVisible': isVisible,
      'opacity': opacity,
      'clickCount': clickCount, // 添加到toJson
    };
  }

  /// 从JSON创建气泡
  factory Bubble.fromJson(Map<String, dynamic> json) {
    return Bubble(
      id: json['id'],
      type: BubbleType.values[json['type']],
      name: json['name'],
      icon: json['icon'],
      description: json['description'],
      color: Color(json['color']),
      size: json['size']?.toDouble() ?? 50.0,
      weight: json['weight']?.toDouble() ?? 1.0,
      isSelected: json['isSelected'] ?? false,
      isVisible: json['isVisible'] ?? true,
      opacity: json['opacity']?.toDouble() ?? 1.0,
      clickCount: json['clickCount'] ?? 0, // 从fromJson恢复
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is Bubble && other.id == id;
  }

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() {
    return 'Bubble(id: $id, name: $name, type: $type, isSelected: $isSelected)';
  }
}

