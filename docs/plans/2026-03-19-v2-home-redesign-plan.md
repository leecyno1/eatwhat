# V2 Home Redesign Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 将 V2 首页升级为“潮流卡牌 + 强动效 + 设计师签名感”的 iPhone 首屏，同时保留现有偏好气泡选择、收藏入口和进入推荐链路的能力。

**Architecture:** 保持 `BubbleOcean` 作为底层交互与物理层，不直接改动 Flame/Forge2D 逻辑；在 `HomePage` 外层增加分层背景、编辑感 Hero 区、手势提示区和底部行动面板，形成新的视觉容器。测试优先覆盖首页关键文案、收藏入口和气泡操作引导，再用最小实现让测试转绿。

**Tech Stack:** Flutter, Material 3, Flame `GameWidget`, flutter_test

---

### Task 1: 首页测试基线

**Files:**
- Create: `test/widget/v2_home_page_redesign_test.dart`
- Modify: `lib/v2/features/home/home_page.dart`
- Test: `test/widget/v2_home_page_redesign_test.dart`

**Step 1: Write the failing test**

```dart
testWidgets('home page shows editorial hero and gesture hints', (tester) async {
  await tester.pumpWidget(const MaterialApp(home: HomePage()));

  expect(find.text('EAT WHAT'), findsOneWidget);
  expect(find.text('今天想吃什么'), findsOneWidget);
  expect(find.text('上滑收进偏爱'), findsOneWidget);
  expect(find.text('下滑略过这味'), findsOneWidget);
});
```

**Step 2: Run test to verify it fails**

Run: `flutter test test/widget/v2_home_page_redesign_test.dart`
Expected: FAIL because the new hero copy and gesture hints do not exist yet.

**Step 3: Write minimal implementation**

在 `HomePage` 中加入新的标题层、手势提示层和可识别的按钮文案。

**Step 4: Run test to verify it passes**

Run: `flutter test test/widget/v2_home_page_redesign_test.dart`
Expected: PASS

**Step 5: Commit**

```bash
git add test/widget/v2_home_page_redesign_test.dart lib/v2/features/home/home_page.dart
git commit -m "test: add v2 home redesign coverage"
```

### Task 2: 首页视觉骨架

**Files:**
- Create: `lib/v2/features/home/widgets/floating_editorial_background.dart`
- Create: `lib/v2/features/home/widgets/home_hero_panel.dart`
- Create: `lib/v2/features/home/widgets/preference_gesture_hint.dart`
- Modify: `lib/v2/features/home/home_page.dart`
- Test: `test/widget/v2_home_page_redesign_test.dart`

**Step 1: Write the failing test**

```dart
testWidgets('home page keeps favorites entry and recommendation callout', (tester) async {
  await tester.pumpWidget(const MaterialApp(home: HomePage()));

  expect(find.text('偏爱档案'), findsOneWidget);
  expect(find.text('已选口味会进入老虎机推理'), findsOneWidget);
});
```

**Step 2: Run test to verify it fails**

Run: `flutter test test/widget/v2_home_page_redesign_test.dart`
Expected: FAIL because the new panel copy is not implemented.

**Step 3: Write minimal implementation**

拆出背景、Hero、手势提示组件；在首页中加入可点击收藏入口和底部推荐说明卡。

**Step 4: Run test to verify it passes**

Run: `flutter test test/widget/v2_home_page_redesign_test.dart`
Expected: PASS

**Step 5: Commit**

```bash
git add lib/v2/features/home/home_page.dart lib/v2/features/home/widgets/floating_editorial_background.dart lib/v2/features/home/widgets/home_hero_panel.dart lib/v2/features/home/widgets/preference_gesture_hint.dart test/widget/v2_home_page_redesign_test.dart
git commit -m "feat: redesign v2 home shell"
```

### Task 3: 视觉精修与适配

**Files:**
- Modify: `lib/v2/features/home/home_page.dart`
- Modify: `lib/v2/features/home/widgets/floating_editorial_background.dart`
- Modify: `lib/v2/features/home/widgets/home_hero_panel.dart`
- Modify: `lib/v2/features/home/widgets/preference_gesture_hint.dart`
- Test: `test/widget/v2_home_page_redesign_test.dart`

**Step 1: Write the failing test**

```dart
testWidgets('home page exposes action chips for current round', (tester) async {
  await tester.pumpWidget(const MaterialApp(home: HomePage()));

  expect(find.text('本轮偏好'), findsOneWidget);
  expect(find.text('收藏入口'), findsOneWidget);
});
```

**Step 2: Run test to verify it fails**

Run: `flutter test test/widget/v2_home_page_redesign_test.dart`
Expected: FAIL until the supporting copy is added.

**Step 3: Write minimal implementation**

补齐本轮偏好说明、胶囊式标签条、层次阴影、渐变与适配间距，确保 375pt 宽度下布局稳定。

**Step 4: Run test to verify it passes**

Run: `flutter test test/widget/v2_home_page_redesign_test.dart`
Expected: PASS

**Step 5: Commit**

```bash
git add lib/v2/features/home/home_page.dart lib/v2/features/home/widgets/floating_editorial_background.dart lib/v2/features/home/widgets/home_hero_panel.dart lib/v2/features/home/widgets/preference_gesture_hint.dart test/widget/v2_home_page_redesign_test.dart
git commit -m "refactor: polish v2 home layout and copy"
```

### Task 4: 验证与回归

**Files:**
- Modify: `lib/v2/features/home/home_page.dart`
- Modify: `test/widget/v2_home_page_redesign_test.dart`

**Step 1: Run formatter**

Run: `dart format lib/v2/features/home/home_page.dart lib/v2/features/home/widgets/*.dart test/widget/v2_home_page_redesign_test.dart`
Expected: files formatted with no syntax changes required afterwards.

**Step 2: Run focused tests**

Run: `flutter test test/widget/v2_home_page_redesign_test.dart`
Expected: PASS

**Step 3: Run broader smoke checks**

Run: `flutter analyze`
Expected: no new analyzer errors introduced by the redesign.

**Step 4: Run simulator build**

Run: `flutter build ios --simulator --debug`
Expected: build succeeds and redesigned home page can be launched in iOS simulator.

**Step 5: Commit**

```bash
git add docs/plans/2026-03-19-v2-home-redesign-plan.md lib/v2/features/home/home_page.dart lib/v2/features/home/widgets/*.dart test/widget/v2_home_page_redesign_test.dart
git commit -m "docs: add v2 home redesign plan"
```
