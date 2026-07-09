import 'package:eatwhat_app/v2/core/data/models/taste_selection_models.dart';
import 'package:eatwhat_app/v2/features/home/widgets/taste_card_surface_pattern_layer.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TasteCardSurfacePatternLayer', () {
    testWidgets('renders ember bars as non-interactive surface detail',
        (tester) async {
      await tester.pumpWidget(
        _host(
          TasteCardSurfacePatternLayer(
            card: _card(surfacePattern: 'ember'),
            accentA: const Color(0xFFF46B40),
            accentB: const Color(0xFF7ABF88),
            compact: false,
          ),
        ),
      );

      final layer = find.byType(TasteCardSurfacePatternLayer);
      expect(
        find.descendant(of: layer, matching: find.byType(IgnorePointer)),
        findsOneWidget,
      );
      expect(find.descendant(of: layer, matching: find.byType(Row)), findsOneWidget);
      expect(
        find.descendant(of: layer, matching: find.byType(Expanded)),
        findsNWidgets(5),
      );
    });

    testWidgets('renders grid pattern through CustomPaint', (tester) async {
      await tester.pumpWidget(
        _host(
          TasteCardSurfacePatternLayer(
            card: _card(surfacePattern: 'grid'),
            accentA: const Color(0xFFF46B40),
            accentB: const Color(0xFF7ABF88),
            compact: true,
          ),
        ),
      );

      expect(
        find.descendant(
          of: find.byType(TasteCardSurfacePatternLayer),
          matching: find.byType(CustomPaint),
        ),
        findsOneWidget,
      );
    });

    testWidgets('falls back to an empty box for unknown pattern',
        (tester) async {
      await tester.pumpWidget(
        _host(
          TasteCardSurfacePatternLayer(
            card: _card(surfacePattern: 'unknown'),
            accentA: const Color(0xFFF46B40),
            accentB: const Color(0xFF7ABF88),
            compact: true,
          ),
        ),
      );

      final layer = find.byType(TasteCardSurfacePatternLayer);
      expect(
        find.descendant(of: layer, matching: find.byType(CustomPaint)),
        findsNothing,
      );
      expect(
        find.descendant(of: layer, matching: find.byType(SizedBox)),
        findsOneWidget,
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

TasteDeckCard _card({required String surfacePattern}) {
  return TasteDeckCard(
    id: 'card_1',
    label: '重辣',
    category: 'flavor',
    accentHexes: const ['#F46B40', '#7ABF88'],
    iconName: 'local_fire_department',
    surfacePattern: surfacePattern,
  );
}
