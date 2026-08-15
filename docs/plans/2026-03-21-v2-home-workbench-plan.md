# V2 Home Workbench Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 将首页下半区域升级为可切换的“偏好工作台”，支持 `气泡选味` 与 `文字要求` 两种入口，并扩大气泡操作容器以适配手机交互。

**Architecture:** 保留 `BubbleOcean` 的 Flame 物理层不动，在首页外层新增一个统一的 `PreferenceWorkbench` 容器，内部通过标签切换驱动两种模式。文字模式先采用“文本要求 -> 标签提取 -> 进入 DecisionPage”的稳妥方案，避免改动整条推荐主链；后续再把 `customRequirement` 深接到 AI 精排。

**Tech Stack:** Flutter, Material 3, Flame `GameWidget`, flutter_test

---

### Task 1: 首页工作台测试基线

**Files:**
- Modify: `test/widget/v2_home_page_redesign_test.dart`
- Modify: `lib/v2/features/home/home_page.dart`
- Create: `lib/v2/features/home/widgets/preference_workbench.dart`

**Step 1: Write the failing test**

```dart
testWidgets('首页展示模式标签并支持切换到文字要求', (tester) async {
  await tester.pumpWidget(const MaterialApp(home: HomePage()));

  expect(find.text('气泡选味'), findsOneWidget);
  expect(find.text('文字要求'), findsOneWidget);

  await tester.tap(find.text('文字要求'));
  await tester.pumpAndSettle();

  expect(find.text('今天有什么要求？'), findsOneWidget);
});
```

**Step 2: Run test to verify it fails**

Run: `flutter test test/widget/v2_home_page_redesign_test.dart`
Expected: FAIL because the home page does not yet expose mode tabs or the text entry panel.

**Step 3: Write minimal implementation**

新增工作台组件与顶部模式切换，并在文字模式中显示输入面板标题。

**Step 4: Run test to verify it passes**

Run: `flutter test test/widget/v2_home_page_redesign_test.dart`
Expected: PASS

**Step 5: Commit**

```bash
git add test/widget/v2_home_page_redesign_test.dart lib/v2/features/home/home_page.dart lib/v2/features/home/widgets/preference_workbench.dart
git commit -m "test: add home workbench coverage"
```

### Task 2: 双模式工作台

**Files:**
- Create: `lib/v2/features/home/widgets/preference_workbench.dart`
- Create: `lib/v2/features/home/widgets/requirement_input_panel.dart`
- Modify: `lib/v2/features/home/home_page.dart`
- Modify: `lib/v2/features/decision/decision_page.dart`

**Step 1: Write the failing test**

```dart
testWidgets('文字要求模式展示输入框和行动按钮', (tester) async {
  await tester.pumpWidget(const MaterialApp(home: HomePage()));
  await tester.tap(find.text('文字要求'));
  await tester.pumpAndSettle();

  expect(find.byType(TextField), findsOneWidget);
  expect(find.text('去决定口味'), findsOneWidget);
});
```

**Step 2: Run test to verify it fails**

Run: `flutter test test/widget/v2_home_page_redesign_test.dart`
Expected: FAIL until the input panel and CTA are added.

**Step 3: Write minimal implementation**

实现统一工作台，包含：
- 标签切换
- 更大的气泡模式容器
- 文字输入模式
- 从文字要求中提取标签并进入 `DecisionPage`

**Step 4: Run test to verify it passes**

Run: `flutter test test/widget/v2_home_page_redesign_test.dart`
Expected: PASS

**Step 5: Commit**

```bash
git add lib/v2/features/home/home_page.dart lib/v2/features/home/widgets/preference_workbench.dart lib/v2/features/home/widgets/requirement_input_panel.dart lib/v2/features/decision/decision_page.dart test/widget/v2_home_page_redesign_test.dart
git commit -m "feat: add home preference workbench"
```

### Task 3: 交互和适配精修

**Files:**
- Modify: `lib/v2/features/home/widgets/preference_workbench.dart`
- Modify: `lib/v2/features/home/widgets/requirement_input_panel.dart`
- Modify: `lib/v2/features/home/home_page.dart`
- Test: `test/widget/v2_home_page_redesign_test.dart`

**Step 1: Write the failing test**

```dart
testWidgets('首页工作台保留气泡模式并展示更大的操作容器', (tester) async {
  await tester.pumpWidget(const MaterialApp(home: HomePage()));

  expect(find.text('今日偏好工作台'), findsOneWidget);
  expect(find.text('今天想通过哪种方式缩小选择范围？'), findsOneWidget);
});
```

**Step 2: Run test to verify it fails**

Run: `flutter test test/widget/v2_home_page_redesign_test.dart`
Expected: FAIL until the final workbench文案与结构就位。

**Step 3: Write minimal implementation**

补齐：
- 更大的容器高度策略
- 模式说明文案
- 已提取标签预览
- 文本模式快捷建议 chip

**Step 4: Run test to verify it passes**

Run: `flutter test test/widget/v2_home_page_redesign_test.dart`
Expected: PASS

**Step 5: Commit**

```bash
git add lib/v2/features/home/home_page.dart lib/v2/features/home/widgets/preference_workbench.dart lib/v2/features/home/widgets/requirement_input_panel.dart test/widget/v2_home_page_redesign_test.dart
git commit -m "refactor: polish home workbench layout"
```

### Task 4: 验证与模拟器检查

**Files:**
- Modify: `lib/v2/features/home/home_page.dart`
- Modify: `test/widget/v2_home_page_redesign_test.dart`

**Step 1: Run formatter**

Run: `dart format lib/v2/features/home/home_page.dart lib/v2/features/home/widgets/*.dart test/widget/v2_home_page_redesign_test.dart`
Expected: files formatted cleanly.

**Step 2: Run focused tests**

Run: `flutter test test/widget/v2_home_page_redesign_test.dart`
Expected: PASS

**Step 3: Run file-scoped analysis**

Run: `flutter analyze lib/v2/features/home/home_page.dart lib/v2/features/home/widgets/preference_workbench.dart lib/v2/features/home/widgets/requirement_input_panel.dart test/widget/v2_home_page_redesign_test.dart`
Expected: no new analyzer errors.

**Step 4: Run simulator smoke**

Run: `flutter run -d 23951DB9-6EC9-4643-B739-FED62328C01D --debug --target lib/main.dart`
Expected: iPhone 16 Pro 上新工作台可正常切换且无纵向溢出。

**Step 5: Commit**

```bash
git add docs/plans/2026-03-21-v2-home-workbench-plan.md lib/v2/features/home/home_page.dart lib/v2/features/home/widgets/*.dart test/widget/v2_home_page_redesign_test.dart
git commit -m "docs: add home workbench plan"
```
