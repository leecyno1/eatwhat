import 'package:eatwhat_app/v2/core/theme/app_colors.dart';
import 'package:eatwhat_app/v2/core/theme/app_tokens.dart';
import 'package:eatwhat_app/v2/core/theme/fluid_theme.dart';
import 'package:eatwhat_app/v2/features/home/widgets/floating_editorial_background.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('garden palette keeps the translucent surface language', () {
    final theme = FluidTheme.lightTheme;

    expect(theme.scaffoldBackgroundColor, AppColors.lightBackground);
    expect(theme.colorScheme.primary, AppPalette.garden);
    expect(theme.colorScheme.surface, AppPalette.surface);
    expect(AppSurfaces.glass.a, lessThan(1));
    expect(AppSurfaces.glassSoft.a, lessThan(1));
  });

  testWidgets('garden palette background keeps the floating motion composition',
      (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: FloatingEditorialBackground(),
        ),
      ),
    );

    final background = find.byKey(
      const ValueKey('warm-palette-motion-background'),
    );
    expect(background, findsOneWidget);
    expect(tester.widget(background), isA<Stack>());
    expect(
      find.ancestor(of: background, matching: find.byType(AnimatedBuilder)),
      findsAtLeastNWidgets(1),
    );
  });
}
