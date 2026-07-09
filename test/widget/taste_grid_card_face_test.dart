import 'package:eatwhat_app/v2/core/data/models/taste_selection_models.dart';
import 'package:eatwhat_app/v2/features/home/widgets/taste_grid_card_face.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('TasteGridCardFace', () {
    testWidgets('renders front face content for a taste card', (tester) async {
      await tester.pumpWidget(
        _host(
          TasteGridCardFace(
            card: _card(),
            reaction: null,
            dragReaction: null,
            dragProgress: 0,
            isCommitting: false,
            isFlipped: false,
          ),
        ),
      );

      expect(find.byKey(const ValueKey('taste-card-front-flavor-f_spicy')),
          findsOneWidget);
      expect(find.text('重辣'), findsWidgets);
      expect(find.byKey(const ValueKey('taste-card-footer-flavor-f_spicy')),
          findsOneWidget);
    });

    testWidgets('renders game card frame and art asset layers', (tester) async {
      await tester.pumpWidget(
        _host(
          TasteGridCardFace(
            card: _card(),
            reaction: null,
            dragReaction: null,
            dragProgress: 0,
            isCommitting: false,
            isFlipped: false,
          ),
        ),
      );

      expect(find.byKey(const ValueKey('taste-card-game-frame-flavor-f_spicy')),
          findsOneWidget);
      expect(find.byKey(const ValueKey('taste-card-game-art-flavor-f_spicy')),
          findsOneWidget);
    });

    testWidgets('renders back face when flipped', (tester) async {
      await tester.pumpWidget(
        _host(
          TasteGridCardFace(
            card: _card(),
            reaction: null,
            dragReaction: null,
            dragProgress: 0,
            isCommitting: false,
            isFlipped: true,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 180));

      expect(find.byKey(const ValueKey('taste-card-back-flavor-f_spicy')),
          findsOneWidget);
      expect(find.text('辣度轮廓'), findsOneWidget);
    });

    testWidgets('renders drag preview affordance', (tester) async {
      await tester.pumpWidget(
        _host(
          TasteGridCardFace(
            card: _card(),
            reaction: null,
            dragReaction: TasteCardReaction.liked,
            dragProgress: 0.8,
            isCommitting: false,
            isFlipped: false,
          ),
        ),
      );

      expect(find.text('喜欢'), findsWidgets);
      expect(find.byIcon(Icons.keyboard_arrow_up_rounded), findsOneWidget);
    });

    testWidgets('renders reaction stamp for resolved cards', (tester) async {
      await tester.pumpWidget(
        _host(
          TasteGridCardFace(
            card: _card(),
            reaction: TasteCardReaction.disliked,
            dragReaction: null,
            dragProgress: 1,
            isCommitting: false,
            isFlipped: false,
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 180));

      expect(find.text('封印'), findsOneWidget);
      expect(
        find.byKey(
          const ValueKey('taste-card-reaction-stamp-disliked-f_spicy'),
        ),
        findsOneWidget,
      );
    });
  });
}

Widget _host(Widget child) {
  return MaterialApp(
    home: Scaffold(
      body: Center(
        child: SizedBox(
          width: 172,
          height: 220,
          child: child,
        ),
      ),
    ),
  );
}

TasteDeckCard _card() {
  return const TasteDeckCard(
    id: 'f_spicy',
    label: '重辣',
    category: 'flavor',
    accentHexes: ['0xFFF46B40', '0xFFFFAB91'],
    iconName: 'local_fire_department',
    blurb: '把重辣收进今天的味型骨架',
    backTitle: '辣度轮廓',
    examples: ['重辣', '更热', '更醒'],
    surfacePattern: 'ember',
  );
}
