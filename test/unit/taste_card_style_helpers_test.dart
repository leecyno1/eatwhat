import 'package:eatwhat_app/v2/core/data/models/taste_selection_models.dart';
import 'package:eatwhat_app/v2/features/home/widgets/taste_card_style_helpers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('taste card style helpers', () {
    test('maps headline styles to stable typography values', () {
      expect(tasteCardHeadlineWeight('signature'), FontWeight.w700);
      expect(tasteCardHeadlineWeight('poster'), FontWeight.w900);
      expect(tasteCardHeadlineWeight('unknown'), FontWeight.w900);

      expect(tasteCardHeadlineSpacing('airy'), 0.22);
      expect(tasteCardHeadlineSpacing('minimal'), -0.1);
      expect(tasteCardHeadlineSpacing('unknown'), -0.2);

      expect(tasteCardHeadlineItalic('signature'), isTrue);
      expect(tasteCardHeadlineItalic('serif'), isTrue);
      expect(tasteCardHeadlineItalic('poster'), isFalse);
    });

    test('adjusts headline bar width for compact and expressive styles', () {
      expect(tasteCardHeadlineBarWidth('minimal', true), closeTo(0.36, 0.001));
      expect(tasteCardHeadlineBarWidth('seal', true), closeTo(0.52, 0.001));
      expect(tasteCardHeadlineBarWidth('poster', false), closeTo(0.58, 0.001));
      expect(
        tasteCardHeadlineBarWidth('editorial', false),
        closeTo(0.52, 0.001),
      );
    });

    test('maps symbol layout to responsive offsets and icon opacity', () {
      expect(tasteCardSymbolIconOffset('corner', true), const Offset(10, 24));
      expect(tasteCardSymbolIconOffset('orbit', false), const Offset(18, 48));
      expect(tasteCardSymbolIconOffset('unknown', true), const Offset(10, 34));

      expect(tasteCardIconOpacity('flare', true), closeTo(0.15, 0.001));
      expect(tasteCardIconOpacity('rise', false), closeTo(0.14, 0.001));
      expect(tasteCardIconOpacity('still', false), closeTo(0.12, 0.001));
    });

    test('resolves signature config by category and layout', () {
      final card = _card(category: 'flavor', symbolLayout: 'crest');
      final config = tasteCardSignatureConfigForCard(card);

      expect(config.glyph, '味');
      expect(config.code, 'FLAVOR');
      expect(config.angle, -0.11);
      expect(config.radius, 18);
      expect(config.top, 36);
      expect(config.right, 8);
    });

    test('parses six and eight digit hex colors', () {
      expect(tasteCardParseHexColor('F46B40'), const Color(0xFFF46B40));
      expect(tasteCardParseHexColor('0x80F46B40'), const Color(0x80F46B40));
    });
  });
}

TasteDeckCard _card({
  required String category,
  required String symbolLayout,
}) {
  return TasteDeckCard(
    id: 'card_1',
    label: '重辣',
    category: category,
    accentHexes: const ['#F46B40', '#7ABF88'],
    iconName: 'restaurant',
    symbolLayout: symbolLayout,
  );
}
