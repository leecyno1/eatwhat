// 结果页视觉基线：黑金单屏舞台 375x812。
//
// 测试环境无 assets manifest，候选图走 FallbackDishArtwork 黑金花字盘，
// 恰好锁定舞台氛围、品牌 header、N°编号、rail 暗化与金线理由行这些
// 不依赖摄影图的版式骨架；真实菜品摄影由运行时的预制图库提供。
import 'dart:io';

import 'package:eatwhat_app/v2/core/data/models/recipe_model.dart';
import 'package:eatwhat_app/v2/core/data/models/taste_inference_input.dart';
import 'package:eatwhat_app/v2/features/result/result_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUpAll(() async {
    // Favorites/feedback services read SharedPreferences; telemetry flows
    // into the Hive-backed metrics store. Give both a test-zone home.
    final dir = await Directory.systemTemp.createTemp('result_gold_golden');
    Hive.init(dir.path);
  });

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });
  testWidgets('result gold stage 375x812 visual check', (tester) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: ResultPage(
          recommendations: [
            RecipeModel(
              id: 'r1',
              name: '黑松露红烧肉',
              description: '浓油赤酱，胶质黏唇。',
              ingredients: ['五花肉', '黑松露'],
              tags: ['荤菜', '浓油赤酱', '下饭'],
            ),
            RecipeModel(
              id: 'r2',
              name: '麻辣冒菜',
              description: '辣味直接。',
              ingredients: ['牛肉', '辣椒'],
              tags: ['辣', '冒菜'],
            ),
            RecipeModel(
              id: 'r3',
              name: '番茄肥牛锅',
              description: '热一点，有锅气。',
              ingredients: ['番茄', '肥牛'],
              tags: ['热菜', '汤锅'],
            ),
          ],
          inferenceInput: TasteInferenceInput(
            likedTagIds: ['f_hot'],
            likedTagLabels: ['热菜'],
            dislikedTagIds: [],
            dislikedTagLabels: [],
            skippedTagIds: [],
            skippedTagLabels: [],
            freeformRequirement: '今晚想吃热一点',
            historyPreferenceSummary: {},
          ),
          aiSummary: '浓油赤酱打头阵，辣意随后，正好接住今晚想吃点热的你。',
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 900));

    await expectLater(
      find.byType(ResultPage),
      matchesGoldenFile('result_gold_stage_375x812.png'),
    );
  });

  testWidgets('result gold stage empty state 375x812 golden', (tester) async {
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: ResultPage(
          recommendations: [],
          fallbackTags: ['热菜'],
        ),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 400));

    await expectLater(
      find.byType(ResultPage),
      matchesGoldenFile('result_gold_stage_empty_375x812.png'),
    );
  });
}
