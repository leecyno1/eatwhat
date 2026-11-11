import 'package:eatwhat_app/v2/core/theme/app_theme_controller.dart';
import 'package:eatwhat_app/v2/features/home/widgets/pot_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pumpPot(WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: Center(
          child: PotButton(
            selectionCount: 0,
            enabled: true,
            onTap: () {},
          ),
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 60));
}

void main() {
  tearDown(() {
    AppThemeController.mode.value = AppThemeMode.cream;
  });

  testWidgets('image-backed skin renders the seal accessory', (tester) async {
    AppThemeController.mode.value = AppThemeMode.lacquer;
    await _pumpPot(tester);
    expect(find.byType(Image), findsOneWidget);
  });

  testWidgets('legacy painted skin renders no image accessory', (tester) async {
    AppThemeController.mode.value = AppThemeMode.cream;
    await _pumpPot(tester);
    expect(find.byType(Image), findsNothing);
  });
}