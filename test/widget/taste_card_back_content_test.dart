import 'package:eatwhat_app/v2/core/data/models/taste_selection_models.dart';
import 'package:eatwhat_app/v2/features/home/widgets/taste_card_back_content.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TasteCardBackContent', () {
    testWidgets('renders full back content with title blurb and examples',
        (tester) async {
      await tester.pumpWidget(
        _host(
          TasteCardBackContent(
            card: _card(
              category: 'flavor',
              backTitle: '辣度签名',
              blurb: '今天想要直接一点的刺激。',
              examples: const ['火锅', '辣子鸡', '麻辣烫'],
            ),
            accentA: const Color(0xFFF46B40),
            previewColor: const Color(0xFFF46B40),
            compact: false,
            ultraCompact: false,
            categoryFontSize: 9,
            labelFontSize: 15,
            descriptorSize: 10,
            activeReaction: TasteCardReaction.liked,
          ),
        ),
      );

      expect(find.text('辣度签名'), findsOneWidget);
      expect(find.text('今天想要直接一点的刺激。'), findsOneWidget);
      expect(find.text('火锅'), findsOneWidget);
      expect(find.text('喜欢'), findsOneWidget);
    });

    testWidgets('renders ultra compact fallback without overflow',
        (tester) async {
      await tester.pumpWidget(
        _host(
          TasteCardBackContent(
            card: _card(category: 'ingredient', label: '番茄'),
            accentA: const Color(0xFF7ABF88),
            previewColor: const Color(0xFF7ABF88),
            compact: true,
            ultraCompact: true,
            categoryFontSize: 8,
            labelFontSize: 12,
            descriptorSize: 8,
            activeReaction: null,
          ),
          width: 126,
          height: 118,
        ),
      );

      expect(find.text('食材'), findsOneWidget);
      expect(find.text('食材角色'), findsOneWidget);
      expect(
          find.byKey(
              const ValueKey('taste-card-back-layout-ingredient-card_1')),
          findsOneWidget);
    });
  });
}

Widget _host(
  Widget child, {
  double width = 220,
  double height = 220,
}) {
  return MaterialApp(
    home: Scaffold(
      body: SizedBox(
        width: width,
        height: height,
        child: DecoratedBox(
          decoration: const BoxDecoration(color: Color(0xFFF7F0EA)),
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: child,
          ),
        ),
      ),
    ),
  );
}

TasteDeckCard _card({
  required String category,
  String label = '重辣',
  String? backTitle,
  String? blurb,
  List<String> examples = const [],
}) {
  return TasteDeckCard(
    id: 'card_1',
    label: label,
    category: category,
    accentHexes: const ['#F46B40', '#7ABF88'],
    iconName: 'local_fire_department',
    backTitle: backTitle,
    blurb: blurb,
    examples: examples,
  );
}
