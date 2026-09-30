import 'package:eatwhat_app/v2/features/home/widgets/pantry_ingredient_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('PantryIngredientSheet', () {
    testWidgets('快捷食材点选后确认可用这些找菜', (tester) async {
      final confirmed = <List<String>>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PantryIngredientSheet(
              onConfirm: confirmed.add,
            ),
          ),
        ),
      );

      expect(find.text('冰箱找菜'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('pantry-ingredient-confirm')),
        findsOneWidget,
      );

      // 未选食材时按钮禁用
      expect(
        tester
            .widget<FilledButton>(
              find.byKey(const ValueKey('pantry-ingredient-confirm')),
            )
            .onPressed,
        isNull,
      );

      await tester.tap(find.byKey(const ValueKey('pantry-chip-鸡蛋')));
      await tester.tap(find.byKey(const ValueKey('pantry-chip-番茄')));
      await tester.pump();

      await tester.tap(find.byKey(const ValueKey('pantry-ingredient-confirm')));
      await tester.pumpAndSettle();

      expect(confirmed, [
        containsAll(['鸡蛋', '番茄']),
      ]);
    });

    testWidgets('手动输入自定义食材并加入', (tester) async {
      final confirmed = <List<String>>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PantryIngredientSheet(onConfirm: confirmed.add),
          ),
        ),
      );

      await tester.enterText(
        find.byKey(const ValueKey('pantry-ingredient-input')),
        '鸡翅',
      );
      await tester.tap(find.byKey(const ValueKey('pantry-ingredient-add')));
      await tester.pump();

      expect(find.byKey(const ValueKey('pantry-chip-鸡翅')), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('pantry-ingredient-confirm')));
      await tester.pumpAndSettle();

      expect(confirmed.single, contains('鸡翅'));
    });

    testWidgets('再次点选已选食材会取消选择', (tester) async {
      final confirmed = <List<String>>[];
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: PantryIngredientSheet(onConfirm: confirmed.add),
          ),
        ),
      );

      await tester.tap(find.byKey(const ValueKey('pantry-chip-豆腐')));
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('pantry-chip-豆腐')));
      await tester.pump();

      expect(
        tester
            .widget<FilledButton>(
              find.byKey(const ValueKey('pantry-ingredient-confirm')),
            )
            .onPressed,
        isNull,
      );
    });
  });
}
