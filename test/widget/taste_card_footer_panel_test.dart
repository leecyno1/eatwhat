import 'package:eatwhat_app/v2/core/data/models/taste_selection_models.dart';
import 'package:eatwhat_app/v2/features/home/widgets/taste_card_footer_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TasteCardFooterPanel', () {
    testWidgets('renders flavor footer with leading glyph and orb',
        (tester) async {
      await tester.pumpWidget(
        _host(
          TasteCardFooterPanel(
            card: _card(category: 'flavor'),
            accent: const Color(0xFFF46B40),
            ultraCompact: false,
            labelFontSize: 14,
            descriptorSize: 10,
            descriptor: '火力拉满',
          ),
        ),
      );

      expect(find.text('重'), findsOneWidget);
      expect(find.text('重辣'), findsOneWidget);
      expect(find.text('火力拉满'), findsOneWidget);
    });

    testWidgets('renders ingredient footer with micro code', (tester) async {
      await tester.pumpWidget(
        _host(
          TasteCardFooterPanel(
            card: _card(category: 'ingredient', id: 'ingredient_42'),
            accent: const Color(0xFF7ABF88),
            ultraCompact: false,
            labelFontSize: 14,
            descriptorSize: 10,
            descriptor: '清爽蔬香',
          ),
        ),
      );

      expect(find.text('INGR'), findsOneWidget);
    });

    testWidgets('falls back to generic footer for unknown category',
        (tester) async {
      await tester.pumpWidget(
        _host(
          TasteCardFooterPanel(
            card: _card(category: 'unknown', iconName: 'restaurant'),
            accent: const Color(0xFF8186D8),
            ultraCompact: true,
            labelFontSize: 12,
            descriptorSize: 9,
            descriptor: '灵感标签',
          ),
        ),
      );

      expect(find.text('重辣'), findsOneWidget);
      expect(find.text('灵感标签'), findsNothing);
      expect(find.byIcon(Icons.restaurant_rounded), findsOneWidget);
    });
  });
}

Widget _host(Widget child) {
  return MaterialApp(
    home: Scaffold(
      body: SizedBox(
        width: 220,
        height: 120,
        child: Center(child: child),
      ),
    ),
  );
}

TasteDeckCard _card({
  String id = 'card_1',
  required String category,
  String label = '重辣',
  String iconName = 'local_fire_department',
}) {
  return TasteDeckCard(
    id: id,
    label: label,
    category: category,
    accentHexes: const ['#F46B40', '#7ABF88'],
    iconName: iconName,
  );
}
