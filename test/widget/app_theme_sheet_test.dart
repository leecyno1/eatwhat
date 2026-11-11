import 'package:eatwhat_app/v2/core/theme/app_theme_controller.dart';
import 'package:eatwhat_app/v2/features/home/widgets/theme_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('外观面板在米白与墨夜之间切换', (tester) async {
    SharedPreferences.setMockInitialValues({});
    AppThemeController.mode.value = AppThemeMode.cream;
    addTearDown(() => AppThemeController.mode.value = AppThemeMode.cream);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showAppThemeSheet(context),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('app-theme-sheet')), findsOneWidget);
    expect(find.text('米白 · 日间'), findsOneWidget);
    expect(find.text('墨夜 · 夜间'), findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('theme-option-dark')));
    await tester.pumpAndSettle();

    expect(AppThemeController.mode.value, AppThemeMode.dark);
  });
}
