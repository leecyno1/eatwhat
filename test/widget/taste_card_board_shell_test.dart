import 'package:eatwhat_app/v2/features/home/widgets/taste_card_board_shell.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TasteCardBoardShell', () {
    testWidgets('renders board chrome, slots, and progress dots',
        (tester) async {
      await tester.pumpWidget(
        _host(
          const TasteCardBoardShell(
            pageCount: 4,
            currentPage: 2,
            progress: 0.35,
            blendProgress: 0.4,
            slotRectFor: _slotRectFor,
          ),
        ),
      );

      expect(find.byKey(const ValueKey('taste-board-corner-markers')),
          findsOneWidget);
      expect(find.byKey(const ValueKey('taste-board-progress-dots')),
          findsOneWidget);
      expect(find.byKey(const ValueKey('taste-board-slot-0')), findsOneWidget);
      expect(find.byKey(const ValueKey('taste-board-slot-8')), findsOneWidget);

      final shell = find.byType(TasteCardBoardShell);
      expect(
        find.descendant(of: shell, matching: find.byType(DecoratedBox)),
        findsAtLeastNWidgets(10),
      );
    });

    testWidgets('keeps progress dots bounded to the provided page count',
        (tester) async {
      await tester.pumpWidget(
        _host(
          const TasteCardBoardShell(
            pageCount: 2,
            currentPage: 1,
            progress: 0,
            blendProgress: 0,
            slotRectFor: _slotRectFor,
          ),
        ),
      );

      final progressRow =
          find.byKey(const ValueKey('taste-board-progress-dots'));
      expect(
        find.descendant(
            of: progressRow, matching: find.byType(AnimatedContainer)),
        findsNWidgets(2),
      );
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
  final row = index ~/ 3;
  final column = index % 3;
  return Rect.fromLTWH(
    18 + column * 96,
    24 + row * 142,
    86,
    124,
  );
}
