import 'dart:io';

import 'package:eatwhat_app/v2/features/style_lab/young_food_style_lab_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

Future<ByteData> _readFont(String path) async {
  final bytes = await File(path).readAsBytes();
  return bytes.buffer.asByteData(bytes.offsetInBytes, bytes.lengthInBytes);
}

Future<void> _loadPreviewFonts() async {
  final sans = FontLoader('PingFang SC')
    ..addFont(_readFont('/System/Library/Fonts/Hiragino Sans GB.ttc'));
  final display = FontLoader('Hiragino Sans GB')
    ..addFont(_readFont('/System/Library/Fonts/Hiragino Sans GB.ttc'));
  final numbers = FontLoader('DIN Alternate')
    ..addFont(
      _readFont(
        '/System/Library/Fonts/Supplemental/DIN Alternate Bold.ttf',
      ),
    );
  final icons = FontLoader('MaterialIcons')
    ..addFont(
      _readFont(
        '/opt/homebrew/Caskroom/flutter/3.32.0/flutter/bin/cache/artifacts/material_fonts/MaterialIcons-Regular.otf',
      ),
    );
  await Future.wait([
    sans.load(),
    display.load(),
    numbers.load(),
    icons.load(),
  ]);
}

String _dishAssetFor(YoungFoodStyleConcept concept) {
  return switch (concept) {
    YoungFoodStyleConcept.mealFm =>
      'assets/images/prebuilt_dishes/dish-32-dish_768.jpg',
    YoungFoodStyleConcept.biteLab =>
      'assets/images/prebuilt_dishes/dish-23-dish_768.jpg',
    YoungFoodStyleConcept.biteClub =>
      'assets/images/prebuilt_dishes/dish-205-howtocook-real_768.jpg',
  };
}

void main() {
  setUpAll(_loadPreviewFonts);

  for (final concept in YoungFoodStyleConcept.values) {
    testWidgets('${concept.title}年轻品牌模板 golden', (tester) async {
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
          home: YoungFoodHomeConceptPage(concept: concept),
        ),
      );
      final pageContext = tester.element(
        find.byType(YoungFoodHomeConceptPage),
      );
      await tester.runAsync(
        () => precacheImage(
          AssetImage(_dishAssetFor(concept)),
          pageContext,
        ),
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(YoungFoodHomeConceptPage),
        matchesGoldenFile('young_food_style_${concept.name}.png'),
      );
    });
  }
}
