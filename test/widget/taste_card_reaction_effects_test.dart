import 'package:eatwhat_app/v2/core/data/models/taste_selection_models.dart';
import 'package:eatwhat_app/v2/features/home/widgets/taste_card_reaction_effects.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TasteStampTextureLayer', () {
    testWidgets('renders stamp texture through a non-interactive painter',
        (tester) async {
      await tester.pumpWidget(
        _host(
          const TasteStampTextureLayer(
            reaction: TasteCardReaction.liked,
            color: Color(0xFFF46B40),
          ),
        ),
      );

      final layer = find.byType(TasteStampTextureLayer);
      expect(
        find.descendant(of: layer, matching: find.byType(IgnorePointer)),
        findsOneWidget,
      );
      expect(
        find.descendant(of: layer, matching: find.byType(CustomPaint)),
        findsOneWidget,
      );
    });
  });

  group('TasteFlipLightOverlay', () {
    testWidgets('renders sweep light as a decorated non-interactive layer',
        (tester) async {
      await tester.pumpWidget(
        _host(
          const TasteFlipLightOverlay(
            progress: 0.5,
            strength: 1,
          ),
        ),
      );

      expect(find.byType(TasteFlipLightOverlay), findsOneWidget);
      expect(find.byType(DecoratedBox), findsOneWidget);
    });
  });

  group('TasteReactionImpactPulse', () {
    testWidgets('renders a liked reaction pulse with layered containers',
        (tester) async {
      await tester.pumpWidget(
        _host(
          const TasteReactionImpactPulse(
            reaction: TasteCardReaction.liked,
            accent: Color(0xFFF46B40),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 180));

      final pulse = find.byType(TasteReactionImpactPulse);
      expect(pulse, findsOneWidget);
      expect(
        find.descendant(of: pulse, matching: find.byType(Container)),
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
        height: 120,
        child: Stack(
          fit: StackFit.expand,
          children: [child],
        ),
      ),
    ),
  );
}
