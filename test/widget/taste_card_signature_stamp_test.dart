import 'package:eatwhat_app/v2/core/data/models/taste_selection_models.dart';
import 'package:eatwhat_app/v2/features/home/widgets/taste_card_signature_stamp.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TasteCardSignatureStamp', () {
    testWidgets('renders default category signature block', (tester) async {
      await tester.pumpWidget(
        _host(
          TasteCardSignatureStamp(
            card: _card(category: 'flavor'),
            accent: const Color(0xFFF46B40),
            compact: false,
          ),
        ),
      );

      expect(find.text('味'), findsOneWidget);
      expect(find.text('FLAVOR'), findsOneWidget);
    });

    testWidgets('adjusts signature for vertical layout', (tester) async {
      await tester.pumpWidget(
        _host(
          TasteCardSignatureStamp(
            card: _card(category: 'ingredient', symbolLayout: 'vertical'),
            accent: const Color(0xFFF46B40),
            compact: true,
          ),
        ),
      );

      final stamp = find.byType(TasteCardSignatureStamp);
      expect(
        find.descendant(of: stamp, matching: find.byType(Transform)),
        findsOneWidget,
      );
      expect(find.text('材'), findsOneWidget);
    });
  });
}

Widget _host(Widget child) {
  return MaterialApp(
    home: Scaffold(
      body: SizedBox(
        width: 180,
        height: 180,
        child: Stack(children: [child]),
      ),
    ),
  );
}

TasteDeckCard _card({
  required String category,
  String symbolLayout = 'stamp',
}) {
  return TasteDeckCard(
    id: 'card_1',
    label: '重辣',
    category: category,
    accentHexes: const ['#F46B40', '#7ABF88'],
    iconName: 'local_fire_department',
    symbolLayout: symbolLayout,
  );
}
