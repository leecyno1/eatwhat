import 'package:eatwhat_app/v2/core/data/schema/unified_tag_model.dart';
import 'package:eatwhat_app/v2/features/home/game/bubble_data_manager.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('V2 气泡视觉映射', () {
    test('默认圆形标签会回退到口味视觉规则', () {
      final data = BubbleData(
        tag: const UnifiedTagModel(
          id: 'flavor_spicy',
          label: '辣',
          category: 'flavor',
          iconAsset: 'local_fire_department',
          visual: VisualConfig(
            shapeType: 'circle',
            colors: [],
            particleEffect: 'none',
          ),
        ),
      );

      expect(data.shapeType, 'chili');
      expect(data.particleEffect, 'steam');
      expect(data.primaryColor.toARGB32(), isNot(equals(0xFF9E9E9E)));
    });

    test('标签自带视觉配置时优先使用标签配置', () {
      final data = BubbleData(
        tag: const UnifiedTagModel(
          id: 'fortune_coin',
          label: '财运',
          category: 'fortune',
          iconAsset: 'savings',
          visual: VisualConfig(
            shapeType: 'hexagon',
            colors: ['#D4AF37', '#FFE7A8'],
            particleEffect: 'sparkle',
          ),
        ),
      );

      expect(data.shapeType, 'hexagon');
      expect(data.particleEffect, 'sparkle');
      expect(data.primaryColor.toARGB32(), equals(0xFFD4AF37));
    });
  });
}
