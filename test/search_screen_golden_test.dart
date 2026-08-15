import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:eatwhat_app/core/theme/app_theme.dart';
import 'package:eatwhat_app/features/search/screens/search_screen.dart';

void main() {
  testWidgets('SearchScreen golden (empty state)', (tester) async {
    tester.binding.window.physicalSizeTestValue = const Size(375 * 3, 812 * 3);
    tester.binding.window.devicePixelRatioTestValue = 3.0;

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.roundedPastel,
        home: const SearchScreen(),
        debugShowCheckedModeBanner: false,
      ),
    );
    await tester.pumpAndSettle(const Duration(milliseconds: 300));

    await expectLater(find.byType(SearchScreen), matchesGoldenFile('goldens/search_screen.png'));

    addTearDown(() {
      tester.binding.window.clearPhysicalSizeTestValue();
      tester.binding.window.clearDevicePixelRatioTestValue();
    });
  });
}
