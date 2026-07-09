import 'package:eatwhat_app/v2/core/data/models/taste_selection_models.dart';
import 'package:eatwhat_app/v2/features/home/widgets/taste_card_deck_motion_layers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TasteDealEntryCard', () {
    testWidgets('wraps child with deal entry transform', (tester) async {
      final controller = AnimationController(
        vsync: tester,
        duration: const Duration(milliseconds: 520),
      )..value = 1;
      addTearDown(controller.dispose);

      await tester.pumpWidget(
        _host(
          TasteDealEntryCard(
            index: 4,
            animation: controller,
            child: const Text('card'),
          ),
        ),
      );

      expect(find.text('card'), findsOneWidget);
      expect(
        find.descendant(
          of: find.byType(TasteDealEntryCard),
          matching: find.byType(Transform),
        ),
        findsOneWidget,
      );
    });
  });

  group('TasteOutgoingPageGhostCard', () {
    testWidgets('renders ghost card label and descriptor', (tester) async {
      await tester.pumpWidget(
        _host(
          const TasteOutgoingPageGhostCard(
            card: TasteDeckCard(
              id: 'f_spicy',
              label: '重辣',
              category: 'flavor',
              accentHexes: ['0xFFF46B40', '0xFF7ABF88'],
              iconName: 'local_fire_department',
            ),
          ),
        ),
      );

      expect(find.text('重辣'), findsOneWidget);
      expect(find.text('口味'), findsOneWidget);
    });
  });

  group('TasteFlipHintPill', () {
    testWidgets('renders compact flip hint affordance', (tester) async {
      await tester.pumpWidget(_host(const TasteFlipHintPill()));

      expect(find.text('点按卡片翻面'), findsOneWidget);
      expect(find.byIcon(Icons.flip_rounded), findsOneWidget);
    });
  });
}

Widget _host(Widget child) {
  return MaterialApp(
    home: Scaffold(
      body: Center(
        child: SizedBox(
          width: 180,
          height: 160,
          child: child,
        ),
      ),
    ),
  );
}
