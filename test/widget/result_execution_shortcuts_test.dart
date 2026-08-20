import 'package:eatwhat_app/v2/core/external/platform/platform_types.dart';
import 'package:eatwhat_app/v2/core/theme/app_tokens.dart';
import 'package:eatwhat_app/v2/features/result/widgets/result_execution_shortcuts.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('结果页执行快捷入口展示三条路径并突出推荐路径', (tester) async {
    var selectedPath = ExecutionPath.any;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ResultExecutionShortcuts(
            preferredPath: ExecutionPath.delivery,
            onCook: () => selectedPath = ExecutionPath.cook,
            onDelivery: () => selectedPath = ExecutionPath.delivery,
            onDineIn: () => selectedPath = ExecutionPath.dineIn,
          ),
        ),
      ),
    );

    expect(find.byKey(const ValueKey('result-execution-shortcuts')),
        findsOneWidget);
    expect(find.text('自己做'), findsOneWidget);
    expect(find.text('叫外卖'), findsOneWidget);
    expect(find.text('去堂食'), findsOneWidget);
    expect(find.text('优先'), findsOneWidget);
    expect(
      tester
          .widget<Icon>(
            find.byKey(const ValueKey('result-execution-cook-icon')),
          )
          .color,
      AppPalette.moonMuted,
    );
    expect(
      tester
          .widget<Icon>(
            find.byKey(const ValueKey('result-execution-delivery-icon')),
          )
          .color,
      AppPalette.leaf,
    );
    expect(
      tester
          .widget<Icon>(
            find.byKey(const ValueKey('result-execution-dine-in-icon')),
          )
          .color,
      AppPalette.moonMuted,
    );

    await tester.tap(find.byKey(const ValueKey('result-execution-delivery')));
    await tester.pump();

    expect(selectedPath, ExecutionPath.delivery);
  });

  testWidgets('未指定偏好时三条执行路径都可以直接点击', (tester) async {
    final selected = <ExecutionPath>[];

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ResultExecutionShortcuts(
            preferredPath: ExecutionPath.any,
            onCook: () => selected.add(ExecutionPath.cook),
            onDelivery: () => selected.add(ExecutionPath.delivery),
            onDineIn: () => selected.add(ExecutionPath.dineIn),
          ),
        ),
      ),
    );

    await tester.tap(find.byKey(const ValueKey('result-execution-cook')));
    await tester.tap(find.byKey(const ValueKey('result-execution-delivery')));
    await tester.tap(find.byKey(const ValueKey('result-execution-dine-in')));
    await tester.pump();

    expect(selected, [
      ExecutionPath.cook,
      ExecutionPath.delivery,
      ExecutionPath.dineIn,
    ]);
  });

  testWidgets('小屏宽度下执行快捷入口不应溢出', (tester) async {
    tester.view.physicalSize = const Size(1179, 2556);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 44),
            child: ResultExecutionShortcuts(
              preferredPath: ExecutionPath.any,
              onCook: () {},
              onDelivery: () {},
              onDineIn: () {},
            ),
          ),
        ),
      ),
    );

    await tester.pump();

    expect(find.byKey(const ValueKey('result-execution-shortcuts')),
        findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
