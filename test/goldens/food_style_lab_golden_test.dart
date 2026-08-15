import 'dart:io';

import 'package:eatwhat_app/v2/features/style_lab/food_style_lab_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Future<ByteData> _readFont(String path) async {
  final bytes = await File(path).readAsBytes();
  return bytes.buffer.asByteData(bytes.offsetInBytes, bytes.lengthInBytes);
}

Future<void> _loadChineseFonts() async {
  final sans = FontLoader('PingFang SC')
    ..addFont(_readFont('/System/Library/Fonts/Hiragino Sans GB.ttc'));
  final serif = FontLoader('Songti SC')
    ..addFont(_readFont('/System/Library/Fonts/Supplemental/Songti.ttc'));
  await Future.wait([sans.load(), serif.load()]);
}

String _dishAssetFor(FoodStyleConcept concept) {
  return switch (concept) {
    FoodStyleConcept.warmEditorial =>
      'assets/images/prebuilt_dishes/dish-1-dish_768.jpg',
    FoodStyleConcept.streetCanteen =>
      'assets/images/prebuilt_dishes/dish-13-dish_768.jpg',
    FoodStyleConcept.seasonalFresh =>
      'assets/images/prebuilt_dishes/dish-9-dish_768.jpg',
  };
}

void main() {
  setUpAll(_loadChineseFonts);

  for (final concept in FoodStyleConcept.values) {
    testWidgets('${concept.title}模板 golden', (tester) async {
      tester.view.physicalSize = const Size(375, 812);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            useMaterial3: true,
            fontFamily: 'PingFang SC',
          ),
          home: FoodHomeConceptPage(concept: concept),
        ),
      );
      final pageContext = tester.element(find.byType(FoodHomeConceptPage));
      await tester.runAsync(
        () => precacheImage(
          AssetImage(_dishAssetFor(concept)),
          pageContext,
        ),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(FoodHomeConceptPage),
        matchesGoldenFile('food_style_${concept.name}.png'),
      );
    });
  }
}
