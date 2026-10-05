import 'dart:typed_data';

import 'package:eatwhat_app/v2/core/data/models/recipe_model.dart';
import 'package:eatwhat_app/v2/features/result/widgets/result_share_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('RecipeShareSheet', () {
    testWidgets('卡片渲染菜名、推荐语与品牌落款', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RecipeShareSheet(
              recipe: _recipe(),
              quote: '麻辣下饭的家常首选',
            ),
          ),
        ),
      );

      expect(find.text('麻婆豆腐'), findsOneWidget);
      expect(find.textContaining('麻辣下饭的家常首选'), findsOneWidget);
      expect(find.textContaining('吃什么'), findsWidgets);
    });

    testWidgets('点分享用捕获的图片字节调用分享器', (tester) async {
      var sharedBytes = Uint8List(0);
      var sharedText = '';
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RecipeShareSheet(
              recipe: _recipe(),
              quote: '麻辣下饭的家常首选',
              cardCapture: () async => Uint8List.fromList([1, 2, 3]),
              shareLauncher: (bytes, text) async {
                sharedBytes = bytes;
                sharedText = text;
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(const ValueKey('result-share-submit')));
      await tester.pumpAndSettle();

      expect(sharedBytes, [1, 2, 3]);
      expect(sharedText, contains('麻婆豆腐'));
    });

    testWidgets('分享失败时提示且不崩', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: RecipeShareSheet(
              recipe: _recipe(),
              quote: 'q',
              cardCapture: () async => Uint8List.fromList([1]),
              shareLauncher: (bytes, text) async {
                throw StateError('share channel unavailable');
              },
            ),
          ),
        ),
      );

      await tester.tap(find.byKey(const ValueKey('result-share-submit')));
      await tester.pumpAndSettle();

      expect(find.textContaining('分享失败'), findsOneWidget);
    });
  });
}

RecipeModel _recipe() {
  return const RecipeModel(
    id: 'dish-share-1',
    name: '麻婆豆腐',
    description: '经典川菜，麻辣鲜香。',
    tags: ['麻辣', '下饭'],
  );
}
