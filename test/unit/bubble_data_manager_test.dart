import 'package:eatwhat_app/v2/core/data/schema/unified_tag_model.dart';
import 'package:eatwhat_app/v2/features/home/game/bubble_data_manager.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  UnifiedTagModel makeTag({
    required String label,
    required String category,
    String shapeType = 'circle',
    List<String> colors = const ['#FFFFFF', '#EEEEEE'],
    String particleEffect = 'none',
  }) {
    return UnifiedTagModel(
      id: 'test_$label',
      label: label,
      category: category,
      iconAsset: 'test',
      visual: VisualConfig(
        shapeType: shapeType,
        colors: colors,
        particleEffect: particleEffect,
      ),
    );
  }

  group('BubbleData shape priority', () {
    test('健康类标签优先使用 shield 而不是被轻食规则覆盖', () {
      final bubble = BubbleData(
        tag: makeTag(
          label: '健康轻食',
          category: 'dietary',
        ),
      );

      expect(bubble.shapeType, 'shield');
    });

    test('火锅类标签优先使用 pot', () {
      final bubble = BubbleData(
        tag: makeTag(
          label: '火锅夜宵',
          category: 'scene',
        ),
      );

      expect(bubble.shapeType, 'pot');
    });
  });

  group('BubbleData sizeMultiplier', () {
    test('零历史时不放大', () {
      final bubble = BubbleData(tag: makeTag(label: '辣', category: 'flavor'));

      expect(bubble.usageCount, 0);
      expect(bubble.sizeMultiplier, 1.0);
    });

    test('历史越多越大且单调递增', () {
      final cold = BubbleData(
        tag: makeTag(label: '辣', category: 'flavor'),
        usageCount: 1,
      );
      final warm = BubbleData(
        tag: makeTag(label: '辣', category: 'flavor'),
        usageCount: 10,
      );
      final hot = BubbleData(
        tag: makeTag(label: '辣', category: 'flavor'),
        usageCount: 50,
      );

      expect(cold.sizeMultiplier, greaterThan(1.0));
      expect(warm.sizeMultiplier, greaterThan(cold.sizeMultiplier));
      expect(hot.sizeMultiplier, greaterThan(warm.sizeMultiplier));
      // 10 次历史约在 1.31x 附近。
      expect(warm.sizeMultiplier, closeTo(1.31, 0.02));
    });

    test('超高频封顶 1.6x', () {
      final veteran = BubbleData(
        tag: makeTag(label: '辣', category: 'flavor'),
        usageCount: 500,
      );
      final legendary = BubbleData(
        tag: makeTag(label: '辣', category: 'flavor'),
        usageCount: 10000,
      );

      expect(veteran.sizeMultiplier, lessThanOrEqualTo(1.6));
      expect(legendary.sizeMultiplier, 1.6);
    });
  });
}
