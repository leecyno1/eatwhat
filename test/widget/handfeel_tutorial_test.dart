import 'package:eatwhat_app/v2/features/onboarding/handfeel_tutorial.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('三步按顺序推进并回调完成', (tester) async {
    var finished = false;
    await tester.pumpWidget(
      MaterialApp(
        home: HandfeelTutorial(
          onFinished: () async {
            finished = true;
          },
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 600));

    expect(find.textContaining('收下这一口'), findsOneWidget);
    await tester.tap(
      find.byKey(const ValueKey('handfeel-tutorial-next')),
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.textContaining('上收下，下拉黑'), findsOneWidget);
    await tester.tap(
      find.byKey(const ValueKey('handfeel-tutorial-next')),
    );
    await tester.pump(const Duration(milliseconds: 300));

    expect(find.textContaining('让锅翻个身'), findsOneWidget);
    await tester.tap(
      find.byKey(const ValueKey('handfeel-tutorial-next')),
    );
    await tester.pumpAndSettle();

    expect(finished, isTrue);
  });

  testWidgets('跳过立即完成', (tester) async {
    var finished = false;
    await tester.pumpWidget(
      MaterialApp(
        home: HandfeelTutorial(
          onFinished: () async {
            finished = true;
          },
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 600));

    await tester.tap(
      find.byKey(const ValueKey('handfeel-tutorial-skip')),
    );
    await tester.pumpAndSettle();

    expect(finished, isTrue);
  });

  testWidgets('窄屏与 1.3 倍字号不产生布局异常', (tester) async {
    tester.view.physicalSize = const Size(320, 640);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(320, 640),
            textScaler: TextScaler.linear(1.3),
          ),
          child: HandfeelTutorial(onFinished: () async {}),
        ),
      ),
    );
    await tester.pump(const Duration(milliseconds: 600));

    final nextButton = find.byKey(
      const ValueKey('handfeel-tutorial-next'),
    );
    expect(nextButton, findsOneWidget);
    expect(tester.getRect(nextButton).bottom, lessThanOrEqualTo(640));
    expect(tester.takeException(), isNull);
  });

  testWidgets('系统减少动态效果时仍可按步骤完成', (tester) async {
    var finished = false;
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(
            size: Size(390, 844),
            disableAnimations: true,
          ),
          child: HandfeelTutorial(
            onFinished: () async {
              finished = true;
            },
          ),
        ),
      ),
    );
    await tester.pump();

    for (var i = 0; i < 3; i++) {
      await tester.tap(
        find.byKey(const ValueKey('handfeel-tutorial-next')),
      );
      await tester.pump();
    }

    expect(finished, isTrue);
    expect(tester.takeException(), isNull);
  });
}
