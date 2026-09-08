// 首页视觉基线：garden 调色板的动态背景层。
//
// 完整 HomePage 无法做像素级 golden：
// 1. 气泡舞台（BubbleGame）固定生成 32 个气泡，布局来自未播种的 Random，
//    且 Forge2D 物理逐帧演化，截屏不可复现；
// 2. BubbleBody 通过 google_fonts 运行时拉取 Noto Sans/Serif SC，
//    widget 测试环境 HTTP 一律返回 400，异步错误会在 golden 比对的
//    runAsync 窗口内浮现，导致测试不稳定。
// 因此基线锁定在测试环境下完全确定性的背景层
// （FloatingEditorialBackground 在测试 binding 下固定动画相位）。
import 'package:eatwhat_app/v2/core/theme/app_theme_controller.dart';
import 'package:eatwhat_app/v2/features/home/widgets/floating_editorial_background.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('cream 纸感动态背景 375x812 golden', (tester) async {
    AppThemeController.mode.value = AppThemeMode.cream;
    addTearDown(() => AppThemeController.mode.value = AppThemeMode.dark);
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: FloatingEditorialBackground(),
        ),
      ),
    );
    await tester.pump();

    await expectLater(
      find.byType(FloatingEditorialBackground),
      matchesGoldenFile('garden_motion_background_375x812.png'),
    );
  });

  testWidgets('夜场金色光斑动态背景 375x812 golden', (tester) async {
    AppThemeController.mode.value = AppThemeMode.dark;
    tester.view.physicalSize = const Size(375, 812);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(
          body: FloatingEditorialBackground(),
        ),
      ),
    );
    await tester.pump();

    await expectLater(
      find.byType(FloatingEditorialBackground),
      matchesGoldenFile('night_motion_background_375x812.png'),
    );
  });
}
