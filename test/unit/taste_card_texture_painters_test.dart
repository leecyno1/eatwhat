import 'package:eatwhat_app/v2/features/home/widgets/taste_card_texture_painters.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('taste card texture painters', () {
    testWidgets('render inside CustomPaint without throwing', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 120,
              height: 120,
              child: CustomPaint(
                key: ValueKey('linear-texture-painter'),
                painter: LinearTexturePainter(
                  primary: Color(0xFFF46B40),
                  secondary: Color(0xFF7ABF88),
                  angleSeed: 0.3,
                ),
              ),
            ),
          ),
        ),
      );

      expect(tester.takeException(), isNull);
      expect(find.byKey(const ValueKey('linear-texture-painter')), findsOneWidget);
    });

    test('linear texture repaints when color or angle changes', () {
      const painter = LinearTexturePainter(
        primary: Color(0xFFF46B40),
        secondary: Color(0xFF7ABF88),
        angleSeed: 0.3,
      );

      expect(
        painter.shouldRepaint(
          const LinearTexturePainter(
            primary: Color(0xFF000000),
            secondary: Color(0xFF7ABF88),
            angleSeed: 0.3,
          ),
        ),
        isTrue,
      );
      expect(
        painter.shouldRepaint(
          const LinearTexturePainter(
            primary: Color(0xFFF46B40),
            secondary: Color(0xFF7ABF88),
            angleSeed: 0.6,
          ),
        ),
        isTrue,
      );
    });

    test('grid, arc and constellation repaint only when inputs change', () {
      const grid = GridTexturePainter(color: Color(0xFFF46B40));
      const arc = ArcTexturePainter(
        color: Color(0xFFF46B40),
        secondary: Color(0xFF7ABF88),
        mode: 'sunbeam',
      );
      const constellation = ConstellationTexturePainter(
        primary: Color(0xFFF46B40),
        secondary: Color(0xFF7ABF88),
      );

      expect(
        grid.shouldRepaint(
          const GridTexturePainter(color: Color(0xFFF46B40)),
        ),
        isFalse,
      );
      expect(
        arc.shouldRepaint(
          const ArcTexturePainter(
            color: Color(0xFFF46B40),
            secondary: Color(0xFF7ABF88),
            mode: 'moon-arc',
          ),
        ),
        isTrue,
      );
      expect(
        constellation.shouldRepaint(
          const ConstellationTexturePainter(
            primary: Color(0xFFF46B40),
            secondary: Color(0xFF7ABF88),
          ),
        ),
        isFalse,
      );
    });
  });
}
