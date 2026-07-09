import 'package:eatwhat_app/v2/features/home/controllers/home_appetite_preview_resolver.dart';
import 'package:eatwhat_app/v2/features/home/widgets/home_action_surfaces.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('Home action surfaces', () {
    testWidgets('recent success entry shows copy and handles tap',
        (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HomeRecentSuccessEntry(
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.byKey(const ValueKey('home-recent-success-entry')),
          findsOneWidget);
      expect(find.text('上次吃得很爽'), findsOneWidget);
      expect(find.text('再来一口'), findsOneWidget);

      await tester.tap(find.byKey(const ValueKey('home-recent-success-entry')));

      expect(tapped, isTrue);
    });

    testWidgets('start inference button exposes ready state copy',
        (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HomeStartInferenceButton(
              canStartInference: true,
              readySelectionCount: 3,
              onPressed: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.byKey(const ValueKey('home-start-inference-button')),
          findsOneWidget);
      expect(find.text('已收集 3 项'), findsOneWidget);
      expect(find.text('下一步：查看今日推荐'), findsOneWidget);

      await tester
          .tap(find.byKey(const ValueKey('home-start-inference-button')));

      expect(tapped, isTrue);
    });

    testWidgets('start inference button explains disabled state',
        (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HomeStartInferenceButton(
              canStartInference: false,
              readySelectionCount: 0,
              onPressed: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.text('步骤 2'), findsOneWidget);
      expect(find.text('先滑卡或补一句需求'), findsOneWidget);
      expect(find.text('至少确认 1 张卡，或补一句文字要求'), findsOneWidget);

      await tester
          .tap(find.byKey(const ValueKey('home-start-inference-button')));

      expect(tapped, isFalse);
    });

    testWidgets('appetite preview card shows dish signal and handles tap',
        (tester) async {
      var tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: HomeAppetitePreviewCard(
              preview: const HomeAppetitePreview(
                title: '番茄肥牛锅',
                chips: ['15 分钟', '热菜', '家常'],
                imageAsset:
                    'assets/images/prebuilt_dishes/dish-22-dish_768.jpg',
              ),
              onTap: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.byKey(const ValueKey('home-appetite-preview-card')),
          findsOneWidget);
      expect(find.text('今晚先看这口'), findsOneWidget);
      expect(find.text('番茄肥牛锅'), findsOneWidget);
      expect(find.text('15 分钟'), findsOneWidget);

      await tester
          .tap(find.byKey(const ValueKey('home-appetite-preview-card')));

      expect(tapped, isTrue);
    });
  });
}
