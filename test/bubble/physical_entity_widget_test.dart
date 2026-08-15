import 'package:eatwhat_app/core/models/physical_entity.dart';
import 'package:eatwhat_app/features/bubble/widgets/physical_entity_widget.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PhysicalEntityWidget animations', () {
    testWidgets('selected entity renders selected glow', (tester) async {
      final entity = PhysicalEntity(
        id: 'e1',
        name: '辣',
        description: 'test',
        type: PhysicalEntityType.taste,
        emoji: '🌶️',
        primaryColor: Colors.red,
        secondaryColor: Colors.orange,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: PhysicalEntityWidget(
                entity: entity,
              ),
            ),
          ),
        ),
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: PhysicalEntityWidget(
                entity: entity.copyWith(isSelected: true),
                isSelected: true,
              ),
            ),
          ),
        ),
      );

      await tester.pump(const Duration(milliseconds: 50));

      final selectedGlowFinder = find.descendant(
        of: find.byType(PhysicalEntityWidget),
        matching: find.byWidgetPredicate((widget) {
          if (widget is! Container) return false;
          final decoration = widget.decoration;
          if (decoration is! BoxDecoration) return false;
          return decoration.shape == BoxShape.circle &&
              (decoration.boxShadow?.length ?? 0) >= 3;
        }),
      );

      expect(selectedGlowFinder, findsWidgets);
    });
  });
}
