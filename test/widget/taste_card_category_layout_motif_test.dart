import 'package:eatwhat_app/v2/core/data/models/taste_selection_models.dart';
import 'package:eatwhat_app/v2/features/home/widgets/taste_card_category_layout_motif.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TasteCardCategoryLayoutMotif', () {
    testWidgets('renders flavor motif with bright icon', (tester) async {
      await tester.pumpWidget(
        _host(
          TasteCardCategoryLayoutMotif(
            card: _card(category: 'flavor'),
            accentA: const Color(0xFFF46B40),
            accentB: const Color(0xFF7ABF88),
            compact: false,
          ),
        ),
      );

      expect(find.byIcon(Icons.brightness_high_rounded), findsOneWidget);
    });

    testWidgets('renders ingredient motif with guide bars', (tester) async {
      await tester.pumpWidget(
        _host(
          TasteCardCategoryLayoutMotif(
            card: _card(category: 'ingredient'),
            accentA: const Color(0xFFF46B40),
            accentB: const Color(0xFF7ABF88),
            compact: true,
          ),
        ),
      );

      expect(find.byType(TasteCardCategoryLayoutMotif), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(TasteCardCategoryLayoutMotif),
          matching: find.byType(FractionallySizedBox),
        ),
        findsNWidgets(3),
      );
    });

    testWidgets('falls back to compact base block for unknown category',
        (tester) async {
      await tester.pumpWidget(
        _host(
          TasteCardCategoryLayoutMotif(
            card: _card(category: 'unknown'),
            accentA: const Color(0xFFF46B40),
            accentB: const Color(0xFF7ABF88),
            compact: true,
          ),
        ),
      );

      expect(find.byIcon(Icons.brightness_high_rounded), findsNothing);
      expect(find.byIcon(Icons.menu_book_rounded), findsNothing);
    });
  });
}

Widget _host(Widget child) {
  return MaterialApp(
    home: Scaffold(
      body: SizedBox(
        width: 220,
        height: 220,
        child: Stack(
          children: [child],
        ),
      ),
    ),
  );
}

TasteDeckCard _card({required String category}) {
  return TasteDeckCard(
    id: 'card_1',
    label: '重辣',
    category: category,
    accentHexes: const ['#F46B40', '#7ABF88'],
    iconName: 'local_fire_department',
  );
}
