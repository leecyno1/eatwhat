import 'package:eatwhat_app/v2/core/data/models/taste_selection_models.dart';
import 'package:eatwhat_app/v2/features/home/widgets/taste_card_chips.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TasteCardReactionChip', () {
    testWidgets('renders reaction label', (tester) async {
      await tester.pumpWidget(
        _host(
          const TasteCardReactionChip(
            reaction: TasteCardReaction.liked,
            color: Color(0xFFF46B40),
            compact: true,
          ),
        ),
      );

      expect(find.text('喜欢'), findsOneWidget);
    });
  });

  group('TasteCardMicroCodePill', () {
    testWidgets('renders compact micro code', (tester) async {
      await tester.pumpWidget(
        _host(
          const TasteCardMicroCodePill(
            text: 'F001',
            accent: Color(0xFFF46B40),
          ),
        ),
      );

      expect(find.text('F001'), findsOneWidget);
    });
  });
}

Widget _host(Widget child) {
  return MaterialApp(
    home: Scaffold(
      body: Center(child: child),
    ),
  );
}
