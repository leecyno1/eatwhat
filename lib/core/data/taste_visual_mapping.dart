import 'package:flutter/material.dart';

/// 可视化规范：为口味/偏好键提供颜色与图标建议
class TasteVisualSpec {
  final IconData? materialIcon;
  final String? emoji;
  final Color color;
  final String label;
  final String shapeType;
  final String particleEffect;

  const TasteVisualSpec({
    this.materialIcon,
    this.emoji,
    required this.color,
    required this.label,
    this.shapeType = 'circle',
    this.particleEffect = 'none',
  });
}

/// 统一的口味映射（示例+规则化补全）。
/// 后续可由 `TastePreferenceDatabase` 动态扩充覆盖到 ~100 项。
class TasteVisualMapping {
  static final Map<String, TasteVisualSpec> tasteKeyToVisual = {
    '辣': TasteVisualSpec(
      materialIcon: Icons.local_fire_department,
      emoji: '🌶️',
      color: Colors.red.shade600,
      label: '辣',
      shapeType: 'chili',
      particleEffect: 'steam',
    ),
    '酸': TasteVisualSpec(
      materialIcon: Icons.eco,
      emoji: '🍋',
      color: Colors.yellow.shade600,
      label: '酸',
      shapeType: 'drop',
      particleEffect: 'bubble',
    ),
    '麻': TasteVisualSpec(
      materialIcon: Icons.bolt,
      emoji: '🧨',
      color: Colors.purple.shade700,
      label: '麻',
      shapeType: 'star',
      particleEffect: 'sparkle',
    ),
    '甜': TasteVisualSpec(
      materialIcon: Icons.cake,
      emoji: '🍭',
      color: Colors.pink.shade400,
      label: '甜',
      shapeType: 'circle',
      particleEffect: 'sparkle',
    ),
    '咸': TasteVisualSpec(
      materialIcon: Icons.water_drop,
      emoji: '🧂',
      color: Colors.blueGrey.shade500,
      label: '咸',
      shapeType: 'hexagon',
      particleEffect: 'none',
    ),
    '鲜': TasteVisualSpec(
      materialIcon: Icons.restaurant_menu,
      emoji: '🦐',
      color: Colors.teal.shade500,
      label: '鲜',
      shapeType: 'drop',
      particleEffect: 'bubble',
    ),
    '清淡': TasteVisualSpec(
      materialIcon: Icons.spa,
      emoji: '🍃',
      color: Colors.blueGrey.shade300,
      label: '清淡',
      shapeType: 'leaf',
      particleEffect: 'bubble',
    ),
    '重口': TasteVisualSpec(
      materialIcon: Icons.thunderstorm,
      emoji: '⚡',
      color: Colors.brown.shade700,
      label: '重口',
      shapeType: 'hexagon',
      particleEffect: 'glow',
    ),
    '火锅': TasteVisualSpec(
      materialIcon: Icons.ramen_dining, // 替代火锅图标
      emoji: '🍲',
      color: Colors.red.shade700,
      label: '火锅',
      shapeType: 'fire',
      particleEffect: 'steam',
    ),
    '酸辣': TasteVisualSpec(
      materialIcon: Icons.local_fire_department,
      emoji: '🌶️',
      color: Colors.orange.shade700,
      label: '酸辣',
      shapeType: 'fire',
      particleEffect: 'steam',
    ),
  };

  /// 规则化补全：根据词根猜测可视化
  static TasteVisualSpec guess(String key) {
    final k = key.trim();
    // 优先命中显式表
    final explicit = tasteKeyToVisual[k];
    if (explicit != null) return explicit;

    // 规则映射
    if (k.contains('辣') || k.contains('麻')) {
      return TasteVisualSpec(
        materialIcon: Icons.local_fire_department,
        emoji: '🌶️',
        color: Colors.red.shade600,
        label: k,
        shapeType: k.contains('麻') ? 'star' : 'chili',
        particleEffect: 'steam',
      );
    }
    if (k.contains('酸') || k.contains('柠檬') || k.contains('醋')) {
      return TasteVisualSpec(
        materialIcon: Icons.eco,
        emoji: '🍋',
        color: Colors.yellow.shade600,
        label: k,
        shapeType: 'drop',
        particleEffect: 'bubble',
      );
    }
    if (k.contains('甜') || k.contains('奶') || k.contains('蜜')) {
      return TasteVisualSpec(
        materialIcon: Icons.cake,
        emoji: '🍯',
        color: Colors.pink.shade400,
        label: k,
        shapeType: 'circle',
        particleEffect: 'sparkle',
      );
    }
    if (k.contains('咸') || k.contains('卤')) {
      return TasteVisualSpec(
        materialIcon: Icons.water_drop,
        emoji: '🧂',
        color: Colors.blueGrey.shade500,
        label: k,
        shapeType: 'hexagon',
        particleEffect: 'none',
      );
    }
    if (k.contains('鲜') || k.contains('海') || k.contains('清')) {
      return TasteVisualSpec(
        materialIcon: Icons.restaurant_menu,
        emoji: '🦐',
        color: Colors.teal.shade500,
        label: k,
        shapeType: k.contains('清') ? 'leaf' : 'drop',
        particleEffect: 'bubble',
      );
    }
    if (k.contains('锅')) {
      return TasteVisualSpec(
        materialIcon: Icons.ramen_dining,
        emoji: '🍲',
        color: Colors.red.shade700,
        label: k,
        shapeType: 'fire',
        particleEffect: 'steam',
      );
    }

    // 默认
    return TasteVisualSpec(
      materialIcon: Icons.restaurant,
      emoji: '🍽️',
      color: Colors.blue.shade400,
      label: k,
      shapeType: 'circle',
      particleEffect: 'none',
    );
  }
}
