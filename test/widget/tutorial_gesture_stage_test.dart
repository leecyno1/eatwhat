import 'package:eatwhat_app/v2/features/onboarding/tutorial_gesture_stage.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('点按、拖拽、摇晃三种舞台都能渲染', (tester) async {
    for (final gesture in TutorialGesture.values) {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: SizedBox(
                width: 320,
                height: 300,
                child: TutorialGestureStage(
                  gesture: gesture,
                  animationsEnabled: true,
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pump(const Duration(milliseconds: 120));

      expect(
        find.byKey(ValueKey('tutorial-stage-${gesture.name}')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    }

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('关闭动画时舞台仍可静态渲染', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 320,
            height: 300,
            child: TutorialGestureStage(
              gesture: TutorialGesture.drag,
              animationsEnabled: false,
            ),
          ),
        ),
      ),
    );
    await tester.pump();

    expect(
      find.byKey(const ValueKey('tutorial-stage-drag')),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}
