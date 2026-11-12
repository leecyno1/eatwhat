import 'package:eatwhat_app/v2/core/theme/app_theme_controller.dart';
import 'package:eatwhat_app/v2/features/home/widgets/home_storefront.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Future<void> _pumpStorefront(WidgetTester tester) async {
  await tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: HomeStorefront(
          stage: const ColoredBox(color: Color(0xFFDDDDDD)),
          selectionCount: 0,
          canGenerate: true,
          onGenerate: () {},
          requirementController: TextEditingController(),
          requirementFocusNode: FocusNode(),
          isListening: false,
          onPantry: () {},
          onVoiceStart: () {},
          onVoiceEnd: () {},
          onSubmitted: () {},
        ),
      ),
    ),
  );
  await tester.pump();
  await tester.pump(const Duration(milliseconds: 60));
}

int _imageDecorations(WidgetTester tester) {
  return tester
      .widgetList<DecoratedBox>(find.byType(DecoratedBox))
      .map((w) => w.decoration)
      .whereType<BoxDecoration>()
      .where((d) => d.image != null)
      .length;
}

void main() {
  tearDown(() {
    AppThemeController.mode.value = AppThemeMode.cream;
  });

  testWidgets('image-backed skin frames the stage and textures the well',
      (tester) async {
    AppThemeController.mode.value = AppThemeMode.lacquer;
    await _pumpStorefront(tester);

    // Frame ring + requirement well + pot cap face.
    expect(_imageDecorations(tester), 3);
    final root = tester.widget<Container>(
      find
          .descendant(
            of: find.byType(HomeStorefront),
            matching: find.byType(Container),
          )
          .first,
    );
    expect(root.padding, const EdgeInsets.all(16));
  });

  testWidgets('legacy skin paints the storefront without image accessories',
      (tester) async {
    AppThemeController.mode.value = AppThemeMode.cream;
    await _pumpStorefront(tester);

    expect(_imageDecorations(tester), 0);
  });
}