import 'package:eatwhat_app/v2/features/home/widgets/taste_card_board_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TasteCardBoardShell', () {
    testWidgets('renders board chrome and requested slots', (tester) async {
      await tester.pumpWidget(
        _host(
          const TasteCardBoardShell(
            slotCount: 8,
            slotRectFor: _slotRectFor,
          ),
        ),
      );

      expect(find.byKey(const ValueKey('taste-board-corner-markers')),
          findsOneWidget);
      expect(find.byKey(const ValueKey('taste-board-slot-0')), findsOneWidget);
      expect(find.byKey(const ValueKey('taste-board-slot-7')), findsOneWidget);

      final shell = find.byType(TasteCardBoardShell);
      expect(
        find.descendant(of: shell, matching: find.byType(DecoratedBox)),
        findsAtLeastNWidgets(8),
      );
    });

    testWidgets('uses slotCount as the exact board capacity', (tester) async {
      await tester.pumpWidget(
        _host(
          const TasteCardBoardShell(
            slotCount: 3,
            slotRectFor: _slotRectFor,
          ),
        ),
      );

      expect(find.byKey(const ValueKey('taste-board-slot-0')), findsOneWidget);
      expect(find.byKey(const ValueKey('taste-board-slot-2')), findsOneWidget);
      expect(find.byKey(const ValueKey('taste-board-slot-3')), findsNothing);
    });
  });
}

Widget _host(Widget child) {
  return MaterialApp(
    home: Scaffold(
      body: SizedBox(
        width: 330,
        height: 520,
        child: Stack(
          children: [child],
        ),
      ),
    ),
  );
}

Rect _slotRectFor(int index) {
  final row = index ~/ 2;
  final column = index % 2;
  return Rect.fromLTWH(
    18 + column * 150,
    24 + row * 118,
    138,
    108,
  );
}
