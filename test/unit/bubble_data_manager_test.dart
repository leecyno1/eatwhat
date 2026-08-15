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
}
