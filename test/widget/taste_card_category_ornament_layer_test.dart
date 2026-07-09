import 'package:eatwhat_app/v2/core/data/models/taste_selection_models.dart';
import 'package:eatwhat_app/v2/features/home/widgets/taste_card_category_ornament_layer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TasteCardCategoryOrnamentLayer', () {
    testWidgets('renders flavor ornament with flare highlight', (tester) async {
      await tester.pumpWidget(
        _host(
          TasteCardCategoryOrnamentLayer(
            card: _card(category: 'flavor', motionPreset: 'flare'),
            accentA: const Color(0xFFF46B40),
            accentB: const Color(0xFF7ABF88),
          ),
        ),
      );

      final layer = find.byType(TasteCardCategoryOrnamentLayer);
      expect(find.descendant(of: layer, matching: find.byType(Stack)),
          findsOneWidget);
      expect(
        find.descendant(of: layer, matching: find.byType(Container)),
        findsNWidgets(3),
      );
    });

    testWidgets('renders ingredient ornament with vertical guide',
        (tester) async {
      await tester.pumpWidget(
        _host(
          TasteCardCategoryOrnamentLayer(
            card: _card(category: 'ingredient', symbolLayout: 'vertical'),
            accentA: const Color(0xFFF46B40),
            accentB: const Color(0xFF7ABF88),
          ),
        ),
      );

      expect(
        find.descendant(
          of: find.byType(TasteCardCategoryOrnamentLayer),
          matching: find.byType(Container),
        ),
        findsNWidgets(3),
      );
    });

    testWidgets('renders scene ornament twinkle accent', (tester) async {
      await tester.pumpWidget(
        _host(
          TasteCardCategoryOrnamentLayer(
            card: _card(category: 'scene', motionPreset: 'twinkle'),
            accentA: const Color(0xFFF46B40),
            accentB: const Color(0xFF7ABF88),
          ),
        ),
      );

      final layer = find.byType(TasteCardCategoryOrnamentLayer);
      expect(
        find.descendant(
            of: layer, matching: find.byIcon(Icons.auto_awesome_rounded)),
        findsOneWidget,
      );
    });

    testWidgets('falls back to default ornament for unknown category',
        (tester) async {
      await tester.pumpWidget(
        _host(
          TasteCardCategoryOrnamentLayer(
            card: _card(category: 'unknown'),
            accentA: const Color(0xFFF46B40),
            accentB: const Color(0xFF7ABF88),
          ),
        ),
      );

      expect(
        find.descendant(
          of: find.byType(TasteCardCategoryOrnamentLayer),
          matching: find.byType(Container),
        ),
        findsNWidgets(2),
      );
    });
  });
}

Widget _host(Widget child) {
  return MaterialApp(
    home: Scaffold(
      body: SizedBox(
        width: 180,
        height: 180,
        child: Stack(
          children: [child],
        ),
      ),
    ),
  );
}

TasteDeckCard _card({
  required String category,
  String motionPreset = 'breathe',
  String symbolLayout = 'stamp',
}) {
  return TasteDeckCard(
    id: 'card_1',
    label: '重辣',
    category: category,
    accentHexes: const ['#F46B40', '#7ABF88'],
    iconName: 'local_fire_department',
    motionPreset: motionPreset,
    symbolLayout: symbolLayout,
  );
}
