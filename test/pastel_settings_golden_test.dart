import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:eatwhat_app/core/theme/app_theme.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:eatwhat_app/features/settings/screens/pastel_settings_screen.dart';

void main() {
  testWidgets('PastelSettingsScreen golden', (tester) async {
    tester.binding.window.physicalSizeTestValue = const Size(375 * 3, 812 * 3);
    tester.binding.window.devicePixelRatioTestValue = 3.0;

    await tester.pumpWidget(ScreenUtilInit(
      designSize: const Size(375, 812),
      builder: (_, __) => MaterialApp(
        theme: AppTheme.roundedPastel,
        home: const PastelSettingsScreen(),
        debugShowCheckedModeBanner: false,
      ),
    ));
    await tester.pumpAndSettle(const Duration(milliseconds: 300));
    await expectLater(
        find.byType(PastelSettingsScreen), matchesGoldenFile('goldens/settings_pastel.png'));

    addTearDown(() {
      tester.binding.window.clearPhysicalSizeTestValue();
      tester.binding.window.clearDevicePixelRatioTestValue();
    });
  });
}
