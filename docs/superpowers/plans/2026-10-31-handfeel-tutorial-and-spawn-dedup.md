# 首启手感教学与气泡发放去重 Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** 修复核心气泡容器中同 ID 实体重复发放，并用唯一的“开席三式”首启教学替换两套旧引导。

**Architecture:** 在 `BubbleGame` 内建立独立的发放台账，实体入队前即占位，分类重载用代次号淘汰未挂载旧实体。首启教学收敛到 HomePage 内的一层全屏动画，不再由 AppV2 和 HomePage 各自弹出一套说明；核心容器的布局、物理参数与视觉皮肤保持不变。

**Tech Stack:** Flutter 3.32、Flame 1.34、Forge2D、SharedPreferences、Flutter Test、iOS Simulator。

---

## 文件结构

| 动作 | 文件 | 责任 |
| --- | --- | --- |
| 新建 | `lib/v2/features/home/game/bubble_spawn_ledger.dart` | 纯 Dart 发放台账：占位、去重、代次切换 |
| 修改 | `lib/v2/features/home/game/bubble_body.dart` | 接受可注入轮廓加载器和发放代次 |
| 修改 | `lib/v2/features/home/game/bubble_game.dart` | 入队前占位、待挂载计数、重载淘汰旧代次 |
| 新建 | `test/unit/bubble_spawn_ledger_test.dart` | 台账纯逻辑回归 |
| 新建 | `test/unit/bubble_game_spawn_dedup_test.dart` | 延迟加载下的运行时重复回归 |
| 修改 | `lib/v2/features/onboarding/onboarding_service.dart` | 新教学标记、旧标记兼容、重置 |
| 新建 | `test/unit/onboarding_service_test.dart` | 首启状态回归 |
| 新建 | `lib/v2/features/onboarding/tutorial_gesture_stage.dart` | 点按/拖拽/摇晃三式动画舞台 |
| 新建 | `test/widget/tutorial_gesture_stage_test.dart` | 三式舞台渲染与减动效回归 |
| 新建 | `lib/v2/features/onboarding/handfeel_tutorial.dart` | 唯一首启教学层与完成后回调 |
| 新建 | `test/widget/handfeel_tutorial_test.dart` | 三步推进、跳过、窄屏与减动效回归 |
| 修改 | `lib/v2/features/home/home_page.dart` | 唯一触发点、教学层接入、删除旧说明卡流程 |
| 修改 | `lib/v2/features/home/widgets/home_overlays.dart` | 删除 `HomeFirstUseGuideCard` |
| 修改 | `lib/v2/app_v2.dart` | 移除启动期旧引导入口 |
| 删除 | `lib/v2/features/onboarding/onboarding_overlay.dart` | 删除四步错误教学 |
| 新建 | `test/widget/v2_home_tutorial_trigger_test.dart` | 首启显示、跳过持久化、二次启动不显示 |

## Task 1: 建立气泡发放台账

**Files:**
- Create: `test/unit/bubble_spawn_ledger_test.dart`
- Create: `lib/v2/features/home/game/bubble_spawn_ledger.dart`

- [ ] **Step 1: 写失败测试**

```dart
import 'package:eatwhat_app/v2/features/home/game/bubble_spawn_ledger.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('BubbleSpawnLedger', () {
    test('同一 ID 只能占位一次', () {
      final ledger = BubbleSpawnLedger();

      expect(ledger.reserve('f_spicy'), isTrue);
      expect(ledger.reserve('f_spicy'), isFalse);
      expect(ledger.reserve('i_egg'), isTrue);
      expect(ledger.issuedIds, {'f_spicy', 'i_egg'});
    });

    test('排除集合同时包含已发放和额外已选 ID', () {
      final ledger = BubbleSpawnLedger()
        ..reserve('f_spicy')
        ..reserve('i_egg');

      expect(
        ledger.exclusions({'c_hotpot', 'i_egg'}),
        {'f_spicy', 'i_egg', 'c_hotpot'},
      );
    });

    test('新代次清空旧占位并保留显式保留项', () {
      final ledger = BubbleSpawnLedger()
        ..reserve('f_spicy')
        ..reserve('i_egg');

      final previous = ledger.generation;
      ledger.beginGeneration(preserve: {'f_spicy'});

      expect(ledger.generation, previous + 1);
      expect(ledger.issuedIds, {'f_spicy'});
      expect(ledger.reserve('i_egg'), isTrue);
    });
  });
}
```

- [ ] **Step 2: 运行测试，确认红灯**

Run:

```bash
flutter test test/unit/bubble_spawn_ledger_test.dart
```

Expected: FAIL，提示 `bubble_spawn_ledger.dart` 不存在。

- [ ] **Step 3: 写最小实现**

创建 `lib/v2/features/home/game/bubble_spawn_ledger.dart`：

```dart
class BubbleSpawnLedger {
  final Set<String> _issuedIds = <String>{};
  int _generation = 0;

  int get generation => _generation;

  Set<String> get issuedIds => Set<String>.unmodifiable(_issuedIds);

  bool reserve(String id) {
    if (id.isEmpty) return false;
    return _issuedIds.add(id);
  }

  Set<String> exclusions(Iterable<String> additionallyExcluded) {
    return <String>{
      ..._issuedIds,
      ...additionallyExcluded.where((id) => id.isNotEmpty),
    };
  }

  void beginGeneration({
    Iterable<String> preserve = const <String>[],
  }) {
    _generation += 1;
    _issuedIds
      ..clear()
      ..addAll(preserve.where((id) => id.isNotEmpty));
  }
}
```

- [ ] **Step 4: 运行测试，确认绿灯**

Run:

```bash
flutter test test/unit/bubble_spawn_ledger_test.dart
```

Expected: `All tests passed!`

- [ ] **Step 5: 静态检查**

Run:

```bash
flutter analyze
```

Expected: `No issues found!`

- [ ] **Step 6: 提交**

```bash
git add lib/v2/features/home/game/bubble_spawn_ledger.dart test/unit/bubble_spawn_ledger_test.dart
git commit -m "fix: 增加气泡发放台账"
```

## Task 2: 接入 BubbleGame 并阻止待挂载重复

**Files:**
- Create: `test/unit/bubble_game_spawn_dedup_test.dart`
- Modify: `lib/v2/features/home/game/bubble_body.dart:29-138`
- Modify: `lib/v2/features/home/game/bubble_game.dart:20-31,68-100,247-307,360-469`

- [ ] **Step 1: 写失败测试**

创建 `test/unit/bubble_game_spawn_dedup_test.dart`：

```dart
import 'dart:async';

import 'package:eatwhat_app/v2/core/data/schema/unified_tag_model.dart';
import 'package:eatwhat_app/v2/features/home/game/bubble_data_manager.dart';
import 'package:eatwhat_app/v2/features/home/game/bubble_game.dart';
import 'package:flame/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('待挂载实体也参与去重，两波投放不产生重复 ID', (tester) async {
    final gate = Completer<void>();
    final game = BubbleGame(
      dataManagerOverride: _FixedBubbleDataManager(),
      geometryLoader: (_, __) async {
        await gate.future;
        return null;
      },
    );

    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: GameWidget(game: game))),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 700));

    gate.complete();
    await tester.pump();
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    final ids = game.entities.map((entity) => entity.data.id).toList();
    expect(ids, hasLength(2));
    expect(ids.toSet().length, ids.length);
    expect(game.issuedTagIds, ids.toSet());

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });

  testWidgets('快速切换分类后旧代次实体不会留在舞台', (tester) async {
    final gate = Completer<void>();
    final game = BubbleGame(
      dataManagerOverride: _FixedBubbleDataManager(),
      geometryLoader: (_, __) async {
        await gate.future;
        return null;
      },
    );

    await tester.pumpWidget(
      MaterialApp(home: Scaffold(body: GameWidget(game: game))),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    game.setCategory('cuisine');
    gate.complete();
    await tester.pump();
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    final ids = game.entities.map((entity) => entity.data.id).toList();
    expect(ids, isNotEmpty);
    expect(ids.toSet().length, ids.length);
    expect(ids.every((id) => id == 'c_hotpot'), isTrue);

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
  });
}

class _FixedBubbleDataManager extends BubbleDataManager {
  @override
  Future<void> initialize() async {}

  @override
  List<BubbleData> getInitialBubbles(
    int count, {
    String? category,
    Set<String> excludedTagIds = const {},
  }) {
    if (category == 'cuisine') {
      return [BubbleData(tag: _hotpot())];
    }
    return [
      BubbleData(tag: _spicy()),
      BubbleData(tag: _egg()),
    ];
  }

  UnifiedTagModel _spicy() => const UnifiedTagModel(
        id: 'f_spicy',
        label: '辣',
        category: 'flavor',
        iconAsset: 'local_fire_department',
        visual: VisualConfig(
          shapeType: 'chili',
          colors: ['0xFFF45B33', '0xFFFFB545'],
        ),
      );

  UnifiedTagModel _egg() => const UnifiedTagModel(
        id: 'i_egg',
        label: '鸡蛋',
        category: 'ingredient',
        iconAsset: 'egg',
        visual: VisualConfig(
          shapeType: 'circle',
          colors: ['0xFFFFB545', '0xFFFFE0A3'],
        ),
      );

  UnifiedTagModel _hotpot() => const UnifiedTagModel(
        id: 'c_hotpot',
        label: '火锅',
        category: 'cuisine',
        iconAsset: 'soup_kitchen',
        visual: VisualConfig(
          shapeType: 'pot',
          colors: ['0xFFC94B2C', '0xFFFF8A65'],
        ),
      );
}
```

- [ ] **Step 2: 运行测试，确认红灯**

Run:

```bash
flutter test test/unit/bubble_game_spawn_dedup_test.dart
```

Expected: FAIL，`BubbleGame` 没有 `dataManagerOverride` 与 `geometryLoader` 参数。

- [ ] **Step 3: 给 BubbleBody 增加测试缝和代次字段**

在 `lib/v2/features/home/game/bubble_body.dart` 顶部加入：

```dart
typedef BubbleGeometryLoader = Future<EntityGeometry?> Function(
  String assetName,
  String assetPath,
);
```

修改构造函数：

```dart
  BubbleBody({
    required this.data,
    required this.targetLongSide,
    required this.initialPosition,
    required this.layerIndex,
    this.isGolden = false,
    this.initialHorizontalImpulse = 0,
    this.spawnGeneration = 0,
    this.geometryLoader,
  });
```

增加字段：

```dart
  final int spawnGeneration;
  final BubbleGeometryLoader? geometryLoader;
```

把 `onLoad` 中的固定调用改为可注入，并在 await 后同时检查父节点是否已被重载摘除：

```dart
    final loader = geometryLoader ?? EntityGeometry.load;
    final geometry = await loader(data.assetName, data.assetPath);
    // 分类重载会在加载中途 dequeue 尚未挂载的实体：此时 parent 已置空，
    // 必须直接返回，避免异步加载结束后仍创建出看不见的物理刚体。
    if (isRemoved || parent == null) return;
```

原始代码中的 `if (isRemoved) return;` 由上面这行替换。

- [ ] **Step 4: 在 BubbleGame 中接入台账与代次**

在 `lib/v2/features/home/game/bubble_game.dart` 增加 import：

```dart
import 'bubble_spawn_ledger.dart';
```

构造函数改为：

```dart
  BubbleGame({
    String? initialCategory,
    Map<String, String> initialLikedTags = const {},
    Map<String, String> initialBlockedTags = const {},
    @visibleForTesting BubbleDataManager? dataManagerOverride,
    @visibleForTesting BubbleGeometryLoader? geometryLoader,
  })  : _category = initialCategory,
        _dataManagerOverride = dataManagerOverride,
        _geometryLoader = geometryLoader,
        super(gravity: Vector2(0, gravityY), zoom: 1.0) {
    _replaceSelections(
      likedTags: initialLikedTags,
      blockedTags: initialBlockedTags,
    );
  }
```

增加字段：

```dart
  final BubbleDataManager? _dataManagerOverride;
  final BubbleGeometryLoader? _geometryLoader;
  final BubbleSpawnLedger _spawnLedger = BubbleSpawnLedger();
  final Set<BubbleBody> _pendingBubbles = <BubbleBody>{};
```

增加测试可读状态：

```dart
  @visibleForTesting
  Set<String> get issuedTagIds => _spawnLedger.issuedIds;
```

`onLoad` 初始化数据管理器改为：

```dart
    _dataManager = _dataManagerOverride ?? BubbleDataManager();
```

`update` 中的补充条件改为：

```dart
      if (entities.length + _pendingBubbles.length < visibleBubbleCount) {
        _addBubbles(count: 1, replenish: true);
      }
```

用下面的完整实现替换原 `_addBubbles`（保留原有尺寸分层与散布逻辑，只改变 ID 来源、占位时机和实体构造参数）：

```dart
  void _addBubbles({int count = visibleBubbleCount, bool replenish = false}) {
    final rand = Random();
    final bubbles = _dataManager.getInitialBubbles(
      count,
      category: _category,
      excludedTagIds: _spawnLedger.exclusions({
        ...selectedTagIds,
        ...blockedTagIds,
      }),
    );

    final accepted = <BubbleData>[];
    for (final data in bubbles) {
      if (_spawnLedger.reserve(data.id)) {
        accepted.add(data);
      }
    }

    final visibleWidth = max(size.x / worldScale, 8.0);
    final visibleHeight = max(size.y / worldScale, 12.0);
    final placements = <({Vector2 center, double span})>[];

    // Scatter entities across the upper region so they rain down and settle
    // into a natural pile instead of hovering like bubbles. Replenished
    // entities spawn from a narrow band at the very top and drift in with
    // a little sideways velocity so they visibly fall onto the pile.
    const spawnBandTop = 1.1;
    final spawnBandHeight =
        replenish ? 0.4 : max(1.0, visibleHeight * 0.42 - spawnBandTop - 2.4);

    for (var i = 0; i < accepted.length; i++) {
      final data = accepted[i];
      // Size tiers keep the pile varied, and history-driven sizeMultiplier
      // makes frequently chosen preferences visibly larger over time. The
      // whole scale was bumped ~30% so entities read clearly and are easy
      // to sweep with a finger path.
      final tierSpan = switch (i % 8) {
        0 || 5 => 3.45 + rand.nextDouble() * 0.65,
        1 || 3 || 6 => 2.8 + rand.nextDouble() * 0.65,
        _ => 2.41 + rand.nextDouble() * 0.59,
      };
      final span =
          (tierSpan * data.sizeMultiplier).clamp(2.28, 4.42).toDouble();
      final reach = span * 0.55;

      Vector2? chosen;
      var bestClearance = -double.infinity;
      Vector2? bestCandidate;
      for (var attempt = 0; attempt < 72; attempt++) {
        final candidate = Vector2(
          reach +
              0.3 +
              rand.nextDouble() * max(0.1, visibleWidth - reach * 2 - 0.6),
          spawnBandTop + reach + rand.nextDouble() * spawnBandHeight,
        );
        var clearance = double.infinity;
        for (final placed in placements) {
          final gap = candidate.distanceTo(placed.center) -
              (reach + placed.span) * 0.82;
          clearance = min(clearance, gap);
        }
        if (clearance > bestClearance) {
          bestClearance = clearance;
          bestCandidate = candidate;
        }
        if (clearance >= 0) {
          chosen = candidate;
          break;
        }
      }
      chosen ??=
          bestCandidate ?? Vector2(visibleWidth / 2, spawnBandTop + reach);
      placements.add((center: chosen, span: reach));

      final bubble = BubbleBody(
        data: data,
        targetLongSide: span,
        initialPosition: chosen,
        layerIndex: _nextSpawnLayer++ % potLayerCount,
        isGolden: rand.nextDouble() < goldenEntityChance,
        initialHorizontalImpulse:
            replenish ? (rand.nextDouble() - 0.5) * 2.4 : 0,
        spawnGeneration: _spawnLedger.generation,
        geometryLoader: _geometryLoader,
      );
      _pendingBubbles.add(bubble);
      async.unawaited(
        bubble.mounted.then((_) => _handleMountedBubble(bubble)),
      );
      world.add(bubble);
    }
  }
```

增加方法：

```dart
  void _handleMountedBubble(BubbleBody bubble) {
    _pendingBubbles.remove(bubble);
    if (bubble.isRemoved) return;
    if (bubble.spawnGeneration != _spawnLedger.generation) {
      bubble.removeFromParent();
    }
  }
```

`_reloadBubbles` 改为：

```dart
  void _reloadBubbles() {
    _spawnLedger.beginGeneration(
      preserve: {...selectedTagIds, ...blockedTagIds},
    );

    for (final bubble in _pendingBubbles.toList()) {
      bubble.removeFromParent();
    }
    _pendingBubbles.clear();

    for (final bubble
        in world.children.whereType<BubbleBody>().toList()) {
      bubble.removeFromParent();
    }

    _addBubbles(count: _initialDropWaveSize);
    _pendingWaveDelay = _initialWaveGapSec;
  }
```

- [ ] **Step 5: 运行测试，确认绿灯**

Run:

```bash
flutter test test/unit/bubble_spawn_ledger_test.dart test/unit/bubble_game_spawn_dedup_test.dart test/unit/v2_physical_preference_system_test.dart
```

Expected: `All tests passed!`

- [ ] **Step 6: 静态检查**

Run:

```bash
flutter analyze
```

Expected: `No issues found!`

- [ ] **Step 7: 提交**

```bash
git add lib/v2/features/home/game/bubble_spawn_ledger.dart lib/v2/features/home/game/bubble_body.dart lib/v2/features/home/game/bubble_game.dart test/unit/bubble_spawn_ledger_test.dart test/unit/bubble_game_spawn_dedup_test.dart
git commit -m "fix: 阻止气泡在挂载前重复发放"
```

## Task 3: 更新首启教学状态接口

**Files:**
- Create: `test/unit/onboarding_service_test.dart`
- Modify: `lib/v2/features/onboarding/onboarding_service.dart`

- [ ] **Step 1: 写失败测试**

```dart
import 'package:eatwhat_app/v2/features/onboarding/onboarding_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('全新安装显示手感教学', () async {
    expect(
      await OnboardingService().shouldShowHandfeelTutorial(),
      isTrue,
    );
  });

  test('任一旧引导标记都会抑制新教学', () async {
    SharedPreferences.setMockInitialValues({
      'has_seen_onboarding_v2': true,
    });
    expect(
      await OnboardingService().shouldShowHandfeelTutorial(),
      isFalse,
    );

    SharedPreferences.setMockInitialValues({
      'v2_home_generation_guide_seen': true,
    });
    expect(
      await OnboardingService().shouldShowHandfeelTutorial(),
      isFalse,
    );
  });

  test('完成与重置会正确更新新标记', () async {
    final service = OnboardingService();
    await service.markHandfeelTutorialSeen();
    expect(await service.shouldShowHandfeelTutorial(), isFalse);

    await service.resetHandfeelTutorial();
    expect(await service.shouldShowHandfeelTutorial(), isTrue);
  });
}
```

- [ ] **Step 2: 运行测试，确认红灯**

Run:

```bash
flutter test test/unit/onboarding_service_test.dart
```

Expected: FAIL，缺少 `shouldShowHandfeelTutorial` 等成员。

- [ ] **Step 3: 扩展服务**

修改 `lib/v2/features/onboarding/onboarding_service.dart`：

```dart
class OnboardingService {
  factory OnboardingService() => _instance;
  OnboardingService._internal();

  static const String handfeelTutorialSeenKey =
      'handfeel_tutorial_v1_seen';
  static const List<String> _legacySeenKeys = [
    'has_seen_onboarding_v2',
    'v2_home_generation_guide_seen',
  ];

  static final OnboardingService _instance = OnboardingService._internal();

  Future<bool> shouldShowHandfeelTutorial() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      if (prefs.getBool(handfeelTutorialSeenKey) ?? false) return false;
      for (final key in _legacySeenKeys) {
        if (prefs.getBool(key) ?? false) return false;
      }
      return true;
    } catch (error) {
      debugPrint('OnboardingService: 读取教学状态失败 - $error');
      return false;
    }
  }

  Future<void> markHandfeelTutorialSeen() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(handfeelTutorialSeenKey, true);
    } catch (error) {
      debugPrint('OnboardingService: 写入教学状态失败 - $error');
    }
  }

  Future<void> resetHandfeelTutorial() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(handfeelTutorialSeenKey);
      for (final key in _legacySeenKeys) {
        await prefs.remove(key);
      }
    } catch (error) {
      debugPrint('OnboardingService: 重置教学状态失败 - $error');
    }
  }

  // 旧接口暂留到旧 overlay 删除，行为已指向新标记。
  Future<bool> shouldShowOnboarding() => shouldShowHandfeelTutorial();

  Future<void> markOnboardingAsSeen() => markHandfeelTutorialSeen();

  Future<void> resetOnboardingStatus() => resetHandfeelTutorial();
}
```

- [ ] **Step 4: 运行测试，确认绿灯**

Run:

```bash
flutter test test/unit/onboarding_service_test.dart
```

Expected: `All tests passed!`

- [ ] **Step 5: 提交**

```bash
git add lib/v2/features/onboarding/onboarding_service.dart test/unit/onboarding_service_test.dart
git commit -m "refactor: 统一首启教学状态"
```

## Task 4: 实现三式手势教学舞台

**Files:**
- Create: `test/widget/tutorial_gesture_stage_test.dart`
- Create: `lib/v2/features/onboarding/tutorial_gesture_stage.dart`

- [ ] **Step 1: 写失败测试**

```dart
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
```

- [ ] **Step 2: 运行测试，确认红灯**

Run:

```bash
flutter test test/widget/tutorial_gesture_stage_test.dart
```

Expected: FAIL，`tutorial_gesture_stage.dart` 不存在。

- [ ] **Step 3: 实现教学舞台**

创建 `lib/v2/features/onboarding/tutorial_gesture_stage.dart`：

```dart
import 'dart:math' as math;

import 'package:eatwhat_app/v2/core/theme/app_tokens.dart';
import 'package:flutter/material.dart';

enum TutorialGesture { tap, drag, shake }

class TutorialGestureStage extends StatefulWidget {
  const TutorialGestureStage({
    super.key,
    required this.gesture,
    required this.animationsEnabled,
  });

  final TutorialGesture gesture;
  final bool animationsEnabled;

  @override
  State<TutorialGestureStage> createState() =>
      _TutorialGestureStageState();
}

class _TutorialGestureStageState extends State<TutorialGestureStage>
    with SingleTickerProviderStateMixin {
  /// 教学固定黑金，不随米色主题分发，避免浅底金字失去对比。
  static const Color _leafGreen = Color(0xFF7ABF88);

  late final AnimationController _controller;

  Duration get _duration => switch (widget.gesture) {
        TutorialGesture.tap => const Duration(milliseconds: 700),
        TutorialGesture.drag => const Duration(milliseconds: 1800),
        TutorialGesture.shake => const Duration(milliseconds: 2000),
      };

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: _duration);
    _restart();
  }

  @override
  void didUpdateWidget(covariant TutorialGestureStage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.gesture != widget.gesture ||
        oldWidget.animationsEnabled != widget.animationsEnabled) {
      _controller.duration = _duration;
      _restart();
    }
  }

  void _restart() {
    _controller.stop();
    if (widget.animationsEnabled) {
      _controller.forward(from: 0);
    } else {
      _controller.value = 0;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = math.min(constraints.maxWidth, 340.0);
        final height = math.min(constraints.maxHeight, 320.0);
        return Center(
          child: SizedBox(
            width: width,
            height: height,
            child: RepaintBoundary(
              key: ValueKey('tutorial-stage-${widget.gesture.name}'),
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, child) {
                  return _buildStage(width, height, _controller.value);
                },
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStage(double width, double height, double rawProgress) {
    final staticProgress = switch (widget.gesture) {
      TutorialGesture.tap => 0.34,
      TutorialGesture.drag => 0.48,
      TutorialGesture.shake => 0.15,
    };
    final t = widget.animationsEnabled
        ? Curves.easeInOutCubic.transform(rawProgress)
        : staticProgress;
    var mainOffsetY = 0.0;
    var mainScale = 1.0;
    var stageRotation = 0.0;
    var handOpacity = 0.0;
    var handOffsetY = 20.0;
    var topGlow = 0.0;
    var bottomGlow = 0.0;
    var ripple = 0.0;

    switch (widget.gesture) {
      case TutorialGesture.tap:
        final press = _bell(t, 0.20, 0.48);
        mainScale = 1 - press * 0.055;
        handOpacity = 1 - _phase(t, 0.64, 1.0);
        handOffsetY = 18 + press * 8;
        ripple = _phase(t, 0.38, 1.0);
        break;
      case TutorialGesture.drag:
        // Lift the card slightly while dragging so it stays inside the
        // mini stage even at the 190px floor height.
        mainScale = 0.88;
        handOpacity = 1 - _phase(t, 0.92, 1.0);
        if (t < 0.42) {
          final p = _smooth(_phase(t, 0, 0.42));
          mainOffsetY = -height * 0.24 * p;
          topGlow = p;
        } else if (t < 0.54) {
          mainOffsetY = -height * 0.24;
          topGlow = 1;
        } else if (t < 0.66) {
          final p = _smooth(_phase(t, 0.54, 0.66));
          mainOffsetY = -height * 0.24 * (1 - p);
          topGlow = 1 - p;
        } else if (t < 0.90) {
          final p = _smooth(_phase(t, 0.66, 0.90));
          mainOffsetY = height * 0.24 * p;
          bottomGlow = p;
        } else {
          final p = _smooth(_phase(t, 0.90, 1.0));
          mainOffsetY = height * 0.24 * (1 - p);
          bottomGlow = 1 - p;
        }
        handOffsetY = mainOffsetY + 22;
        break;
      case TutorialGesture.shake:
        mainOffsetY = math.sin(t * math.pi * 8) * (1 - t) * 6;
        stageRotation = math.sin(t * math.pi * 10) * (1 - t) * 0.06;
        break;
    }

    return Transform.rotate(
      angle: stageRotation,
      child: Stack(
        clipBehavior: Clip.none,
        alignment: Alignment.center,
        children: [
          _ambientOrb(width, height),
          _dropZone(
            alignment: Alignment.topCenter,
            color: _leafGreen,
            label: '顶部 · 收下',
            opacity: widget.gesture == TutorialGesture.drag
                ? 0.24 + topGlow * 0.76
                : 0.12,
          ),
          _dropZone(
            alignment: Alignment.bottomCenter,
            color: AppPalette.tomato,
            label: '底部 · 拉黑',
            opacity: widget.gesture == TutorialGesture.drag
                ? 0.24 + bottomGlow * 0.76
                : 0.12,
          ),
          if (widget.gesture == TutorialGesture.tap && ripple > 0)
            IgnorePointer(
              child: Container(
                width: 100 + ripple * 110,
                height: 100 + ripple * 110,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: GoldPalette.gold.withValues(
                      alpha: (1 - ripple) * 0.55,
                    ),
                  ),
                ),
              ),
            ),
          Transform.rotate(
            angle: -0.13,
            child: Transform.translate(
              offset: const Offset(-34, 8),
              child: _entityCard(
                width: 90,
                height: 112,
                asset: 'assets/images/preference_entities/c_hotpot.webp',
                opacity: 0.65,
              ),
            ),
          ),
          Transform.rotate(
            angle: 0.12,
            child: Transform.translate(
              offset: const Offset(36, 14),
              child: _entityCard(
                width: 84,
                height: 104,
                asset: 'assets/images/preference_entities/i_egg.webp',
                opacity: 0.52,
              ),
            ),
          ),
          Transform.translate(
            offset: Offset(0, mainOffsetY),
            child: Transform.scale(
              scale: mainScale,
              child: _entityCard(
                width: 116,
                height: 144,
                asset: 'assets/images/preference_entities/i_beef.webp',
                label: '今晚这一口',
              ),
            ),
          ),
          if (handOpacity > 0)
            Positioned(
              left: width / 2 + 32,
              top: height / 2 + handOffsetY,
              child: Opacity(
                opacity: handOpacity,
                child: const Icon(
                  Icons.touch_app_rounded,
                  size: 42,
                  color: GoldPalette.goldSoft,
                ),
              ),
            ),
          if (widget.gesture == TutorialGesture.shake) ...[
            _spark(width * 0.30, height * 0.34, t),
            _spark(width * 0.72, height * 0.31, t + 0.22),
            _spark(width * 0.27, height * 0.68, t + 0.41),
            _spark(width * 0.74, height * 0.70, t + 0.63),
          ],
        ],
      ),
    );
  }

  Widget _ambientOrb(double width, double height) {
    return IgnorePointer(
      child: Container(
        width: math.min(width, height) * 0.9,
        height: math.min(width, height) * 0.9,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [
              GoldPalette.gold.withValues(alpha: 0.12),
              GoldPalette.nightDeep.withValues(alpha: 0),
            ],
          ),
          border: Border.all(
            color: GoldPalette.goldHairline.withValues(alpha: 0.55),
          ),
        ),
      ),
    );
  }

  Widget _dropZone({
    required Alignment alignment,
    required Color color,
    required String label,
    required double opacity,
  }) {
    return Align(
      alignment: alignment,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: opacity * 0.12),
          borderRadius: AppRadii.capsule,
          border: Border.all(
            color: color.withValues(alpha: opacity * 0.72),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: color.withValues(alpha: 0.55 + opacity * 0.45),
            fontSize: 10,
            fontWeight: FontWeight.w800,
            letterSpacing: 0.8,
          ),
        ),
      ),
    );
  }

  Widget _entityCard({
    required double width,
    required double height,
    required String asset,
    String? label,
    double opacity = 1,
  }) {
    return Opacity(
      opacity: opacity,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: GoldPalette.panel,
          borderRadius: AppRadii.card,
          border: Border.all(color: GoldPalette.goldHairline),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.45),
              blurRadius: 24,
              offset: const Offset(0, 14),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              asset,
              fit: BoxFit.cover,
              filterQuality: FilterQuality.medium,
              cacheWidth: (width * 3).round(),
              errorBuilder: (_, __, ___) => const Center(
                child: Icon(
                  Icons.restaurant_rounded,
                  color: GoldPalette.goldSoft,
                ),
              ),
            ),
            const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.transparent, Color(0xCC0B0B0E)],
                ),
              ),
            ),
            if (label != null)
              Positioned(
                left: 12,
                right: 12,
                bottom: 11,
                child: Text(
                  label,
                  style: const TextStyle(
                    color: GoldPalette.creamText,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _spark(double left, double top, double phase) {
    final value = math.sin(phase * math.pi * 2).abs();
    return Positioned(
      left: left,
      top: top,
      child: Container(
        width: 4 + value * 4,
        height: 4 + value * 4,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: GoldPalette.gold.withValues(alpha: 0.25 + value * 0.45),
        ),
      ),
    );
  }

  static double _phase(double value, double begin, double end) {
    if (end <= begin) return 0;
    return ((value - begin) / (end - begin)).clamp(0.0, 1.0);
  }

  static double _smooth(double value) {
    return Curves.easeInOutCubic.transform(value);
  }

  static double _bell(double value, double begin, double peak) {
    if (value <= begin || value >= peak) return 0;
    final progress = (value - begin) / (peak - begin);
    return math.sin(progress * math.pi);
  }
}
```

- [ ] **Step 4: 运行测试，确认绿灯**

Run:

```bash
flutter test test/widget/tutorial_gesture_stage_test.dart
```

Expected: `All tests passed!`

- [ ] **Step 5: 静态检查**

Run:

```bash
flutter analyze
```

Expected: `No issues found!`

- [ ] **Step 6: 提交**

```bash
git add lib/v2/features/onboarding/tutorial_gesture_stage.dart test/widget/tutorial_gesture_stage_test.dart
git commit -m "feat: 新增三式手感教学舞台"
```

## Task 5: 组装唯一首启教学层

**Files:**
- Create: `test/widget/handfeel_tutorial_test.dart`
- Create: `lib/v2/features/onboarding/handfeel_tutorial.dart`

- [ ] **Step 1: 写失败测试**

```dart
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
```

- [ ] **Step 2: 运行测试，确认红灯**

Run:

```bash
flutter test test/widget/handfeel_tutorial_test.dart
```

Expected: FAIL，`handfeel_tutorial.dart` 不存在。

- [ ] **Step 3: 实现教学层**

创建 `lib/v2/features/onboarding/handfeel_tutorial.dart`：

```dart
import 'dart:async';

import 'package:eatwhat_app/v2/core/theme/app_tokens.dart';
import 'package:eatwhat_app/v2/features/onboarding/tutorial_gesture_stage.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class HandfeelTutorial extends StatefulWidget {
  const HandfeelTutorial({
    super.key,
    required this.onFinished,
  });

  final Future<void> Function() onFinished;

  @override
  State<HandfeelTutorial> createState() => _HandfeelTutorialState();
}

class _HandfeelTutorialState extends State<HandfeelTutorial>
    with TickerProviderStateMixin {
  static const _steps = <_TutorialStepData>[
    _TutorialStepData(
      gesture: TutorialGesture.tap,
      title: '轻点\n收下这一口',
      description: '喜欢的气泡，点一下就会进锅。',
    ),
    _TutorialStepData(
      gesture: TutorialGesture.drag,
      title: '按住，拖一拖\n上收下，下拉黑',
      description: '拖到顶部收下；拖到底部，就暂时不选它。',
    ),
    _TutorialStepData(
      gesture: TutorialGesture.shake,
      title: '摇一摇\n让锅翻个身',
      description: '堆叠的食材会重新散开，再看看有没有新灵感。',
    ),
  ];

  late final AnimationController _entryController;
  late final AnimationController _exitController;
  int _index = 0;
  bool _started = false;
  bool _finishing = false;

  _TutorialStepData get _step => _steps[_index];

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 520),
    );
    _exitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 360),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_started) return;
    _started = true;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    _entryController.duration = reduceMotion
        ? Duration.zero
        : const Duration(milliseconds: 520);
    _exitController.duration = reduceMotion
        ? Duration.zero
        : const Duration(milliseconds: 360);
    if (reduceMotion) {
      _entryController.value = 1;
    } else {
      _entryController.forward();
    }
    unawaited(HapticFeedback.selectionClick());
  }

  @override
  void dispose() {
    _entryController.dispose();
    _exitController.dispose();
    super.dispose();
  }

  void _advance() {
    if (_finishing) return;
    if (_index == _steps.length - 1) {
      unawaited(_finish(lightHaptic: true));
      return;
    }
    unawaited(HapticFeedback.selectionClick());
    setState(() => _index += 1);
  }

  Future<void> _finish({bool lightHaptic = false}) async {
    if (_finishing) return;
    _finishing = true;
    if (lightHaptic) {
      unawaited(HapticFeedback.lightImpact());
    }
    if (_exitController.duration != Duration.zero) {
      await _exitController.forward();
    }
    await widget.onFinished();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    return Material(
      key: const ValueKey('handfeel-tutorial'),
      type: MaterialType.transparency,
      // 整层吸收触摸，避免点穿到真实气泡舞台；舞台与说明卡自身可点推进。
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        excludeFromSemantics: true,
        onTap: () {},
        child: AnimatedBuilder(
          animation: Listenable.merge([
            _entryController,
            _exitController,
          ]),
          builder: (context, child) {
            final entry = _entryController.value;
            final exit = _exitController.value;
            return Opacity(
              opacity: (entry * (1 - exit)).clamp(0.0, 1.0),
              child: Transform.translate(
                offset: Offset(0, 16 * (1 - entry)),
                child: child,
              ),
            );
          },
          child: Stack(
            children: [
              const Positioned.fill(child: _TutorialScrim()),
              SafeArea(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final stageHeight =
                        (constraints.maxHeight * 0.38).clamp(190.0, 310.0);
                    return SingleChildScrollView(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight - 32,
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            _buildHeader(),
                            GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              excludeFromSemantics: true,
                              onTap: _advance,
                              child: SizedBox(
                                height: stageHeight,
                                child: Semantics(
                                  label:
                                      '当前教学：${_step.title.replaceAll('\n', '')}',
                                  child: AnimatedSwitcher(
                                    duration: reduceMotion
                                        ? Duration.zero
                                        : const Duration(milliseconds: 280),
                                    switchInCurve: Curves.easeOutCubic,
                                    switchOutCurve: Curves.easeInCubic,
                                    child: TutorialGestureStage(
                                      key: ValueKey(_step.gesture),
                                      gesture: _step.gesture,
                                      animationsEnabled: !reduceMotion,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 8),
                            GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              excludeFromSemantics: true,
                              onTap: _advance,
                              child: _buildInstruction(reduceMotion),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Row(
      children: [
        Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            border: Border.all(color: GoldPalette.goldHairline),
          ),
          child: const Icon(
            Icons.dinner_dining_rounded,
            size: 16,
            color: GoldPalette.goldSoft,
          ),
        ),
        const SizedBox(width: 10),
        const Expanded(
          child: Text(
            '开席之前 · 三式就够',
            style: TextStyle(
              color: GoldPalette.gold,
              fontSize: 11,
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
            ),
          ),
        ),
        TextButton(
          key: const ValueKey('handfeel-tutorial-skip'),
          style: TextButton.styleFrom(
            minimumSize: const Size(64, 48),
            padding: const EdgeInsets.symmetric(horizontal: 8),
          ),
          onPressed: _finishing
              ? null
              : () => unawaited(_finish()),
          child: const Text(
            '跳过',
            style: TextStyle(
              color: GoldPalette.creamMuted,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildInstruction(bool reduceMotion) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
      decoration: AppDecorations.nightCard(
        color: GoldPalette.panel,
        borderColor: GoldPalette.goldHairline,
        radius: AppRadii.lg,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedSwitcher(
            duration: reduceMotion
                ? Duration.zero
                : const Duration(milliseconds: 280),
            child: Column(
              key: ValueKey(_index),
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _step.title,
                  style: const TextStyle(
                    color: GoldPalette.creamText,
                    fontFamily: 'serif',
                    fontSize: 27,
                    height: 1.18,
                    fontWeight: FontWeight.w700,
                    letterSpacing: -0.6,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  _step.description,
                  style: const TextStyle(
                    color: GoldPalette.creamMuted,
                    fontSize: 13,
                    height: 1.65,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              for (var index = 0; index < _steps.length; index++)
                AnimatedContainer(
                  duration: reduceMotion
                      ? Duration.zero
                      : const Duration(milliseconds: 220),
                  width: index == _index ? 28 : 8,
                  height: 3,
                  margin: const EdgeInsets.only(right: 5),
                  decoration: BoxDecoration(
                    color: index == _index
                        ? GoldPalette.gold
                        : GoldPalette.goldHairline,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              const Spacer(),
              Text(
                '${_index + 1} / ${_steps.length}',
                style: const TextStyle(
                  color: GoldPalette.creamMuted,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          SizedBox(
            width: double.infinity,
            height: 48,
            child: FilledButton(
              key: const ValueKey('handfeel-tutorial-next'),
              onPressed: _finishing ? null : _advance,
              style: FilledButton.styleFrom(
                backgroundColor: GoldPalette.gold,
                foregroundColor: GoldPalette.nightDeep,
                shape: const StadiumBorder(),
              ),
              child: Text(
                _index == _steps.length - 1 ? '开始挑第一口' : '下一步',
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.6,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _TutorialScrim extends StatelessWidget {
  const _TutorialScrim();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            GoldPalette.nightDeep.withValues(alpha: 0.90),
            GoldPalette.nightDeep.withValues(alpha: 0.76),
            GoldPalette.nightDeep.withValues(alpha: 0.95),
          ],
          stops: const [0, 0.48, 1],
        ),
      ),
      child: const DecoratedBox(
        decoration: BoxDecoration(
          gradient: RadialGradient(
            center: Alignment(0, -0.1),
            radius: 0.8,
            colors: [Color(0x1634D277), Color(0x00000000)],
          ),
        ),
      ),
    );
  }
}

class _TutorialStepData {
  const _TutorialStepData({
    required this.gesture,
    required this.title,
    required this.description,
  });

  final TutorialGesture gesture;
  final String title;
  final String description;
}
```

- [ ] **Step 4: 运行测试，确认绿灯**

Run:

```bash
flutter test test/widget/tutorial_gesture_stage_test.dart test/widget/handfeel_tutorial_test.dart
```

Expected: `All tests passed!`

- [ ] **Step 5: 静态检查**

Run:

```bash
flutter analyze
```

Expected: `No issues found!`

- [ ] **Step 6: 提交**

```bash
git add lib/v2/features/onboarding/handfeel_tutorial.dart test/widget/handfeel_tutorial_test.dart
git commit -m "feat: 重做首启三式教学动画"
```

## Task 6: 接入 HomePage 并移除两套旧引导

**Files:**
- Create: `test/widget/v2_home_tutorial_trigger_test.dart`
- Modify: `lib/v2/features/home/home_page.dart:3,29,63-112,250-277,608-667`
- Modify: `lib/v2/features/home/widgets/home_overlays.dart:190-231`
- Modify: `lib/v2/features/onboarding/onboarding_service.dart`
- Modify: `lib/v2/app_v2.dart:8-68`
- Delete: `lib/v2/features/onboarding/onboarding_overlay.dart`

- [ ] **Step 1: 写失败测试**

创建 `test/widget/v2_home_tutorial_trigger_test.dart`：

```dart
import 'package:eatwhat_app/v2/core/data/models/taste_selection_models.dart';
import 'package:eatwhat_app/v2/core/services/v2_speech_input_service.dart';
import 'package:eatwhat_app/v2/features/home/home_page.dart';
import 'package:eatwhat_app/v2/features/onboarding/onboarding_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../test_bootstrap.dart';

void main() {
  setUpAll(() async {
    await bootstrapTestEnvironment();
  });

  testWidgets('首次进入显示新教学，跳过后持久化且不再出现', (tester) async {
    SharedPreferences.setMockInitialValues({});

    await tester.pumpWidget(
      MaterialApp(
        home: HomePage(
          initialCards: _cards,
          speechInputService: _FakeSpeechInputService(),
        ),
      ),
    );
    await _pumpFrames(tester);

    expect(
      find.byKey(const ValueKey('handfeel-tutorial')),
      findsOneWidget,
    );
    expect(find.text('选出今天想吃的方向'), findsNothing);

    await tester.tap(
      find.byKey(const ValueKey('handfeel-tutorial-skip')),
    );
    // 首页物理舞台会持续调度帧，不能用 pumpAndSettle。
    await _pumpFrames(tester);

    expect(
      find.byKey(const ValueKey('handfeel-tutorial')),
      findsNothing,
    );
    final prefs = await SharedPreferences.getInstance();
    expect(
      prefs.getBool(OnboardingService.handfeelTutorialSeenKey),
      isTrue,
    );

    await tester.pumpWidget(const SizedBox.shrink());
    await tester.pump();
    await tester.pumpWidget(
      MaterialApp(
        home: HomePage(
          initialCards: _cards,
          speechInputService: _FakeSpeechInputService(),
        ),
      ),
    );
    await _pumpFrames(tester);

    expect(
      find.byKey(const ValueKey('handfeel-tutorial')),
      findsNothing,
    );
  });
}

Future<void> _pumpFrames(WidgetTester tester, {int frames = 12}) async {
  for (var i = 0; i < frames; i++) {
    await tester.pump(const Duration(milliseconds: 80));
  }
}

const _cards = [
  TasteDeckCard(
    id: 'f_spicy',
    label: '辣',
    category: 'flavor',
    accentHexes: ['0xFFF45B33', '0xFFFFB545'],
    iconName: 'local_fire_department',
  ),
];

class _FakeSpeechInputService implements V2SpeechInputService {
  @override
  bool get isListening => false;

  @override
  Future<bool> initialize() async => false;

  @override
  Future<void> startListening({
    required void Function(String transcript, bool isFinal) onResult,
  }) async {}

  @override
  Future<String> stopListening() async => '';
}
```

现有首页测试都已在 `setUp` 写入 `v2_home_generation_guide_seen: true`，旧标记兼容逻辑会让这些测试继续跳过新教学，无需改动。

- [ ] **Step 2: 运行测试，确认红灯**

Run:

```bash
flutter test test/widget/v2_home_tutorial_trigger_test.dart
```

Expected: FAIL，找不到 `handfeel-tutorial`。

- [ ] **Step 3: 修改 HomePage 为唯一触发点**

在 `lib/v2/features/home/home_page.dart` 增加 import：

```dart
import 'package:eatwhat_app/v2/features/onboarding/handfeel_tutorial.dart';
import 'package:eatwhat_app/v2/features/onboarding/onboarding_service.dart';
```

删除只被旧说明卡使用的 import：

```dart
import 'package:eatwhat_app/core/config/env_config.dart';
import 'package:shared_preferences/shared_preferences.dart';
```

删除字段：

```dart
  static const _guideSeenKey = 'v2_home_generation_guide_seen';
```

增加状态：

```dart
  bool _showHandfeelTutorial = false;
```

把 `initState` 的 post-frame 调用改为：

```dart
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _maybeShowHandfeelTutorial();
    });
```

删除整个 `_showFirstUseGuideIfNeeded` 方法，替换为：

```dart
  Future<void> _maybeShowHandfeelTutorial() async {
    if (!mounted) return;
    final shouldShow =
        await OnboardingService().shouldShowHandfeelTutorial();
    if (!mounted || !shouldShow) return;
    setState(() => _showHandfeelTutorial = true);
  }

  Future<void> _finishHandfeelTutorial() async {
    await OnboardingService().markHandfeelTutorialSeen();
    if (!mounted) return;
    setState(() => _showHandfeelTutorial = false);
  }
```

在 `build` 的 Stack 最末尾加入：

```dart
          if (_showHandfeelTutorial)
            Positioned.fill(
              child: HandfeelTutorial(
                onFinished: _finishHandfeelTutorial,
              ),
            ),
```

- [ ] **Step 4: 删除首页第二套说明卡**

从 `lib/v2/features/home/widgets/home_overlays.dart` 删除 `HomeFirstUseGuideCard` 整个类（当前 190-231 行），保留语音覆盖层和生成转场层。

- [ ] **Step 5: 移除 AppV2 启动期旧引导**

在 `lib/v2/app_v2.dart`：

- 删除 `onboarding_overlay.dart` 与 `onboarding_service.dart` import。
- 删除 `initState` 中的 `_checkInitialStatus();`。
- 删除 `_checkInitialStatus` 与 `_checkOnboardingStatus` 两个方法。

- [ ] **Step 6: 删除旧四步教学与旧服务包装**

```bash
git rm lib/v2/features/onboarding/onboarding_overlay.dart
```

在 `lib/v2/features/onboarding/onboarding_service.dart` 删除已无调用方的 `shouldShowOnboarding`、`markOnboardingAsSeen`、`resetOnboardingStatus` 三个旧包装方法；保留 `_legacySeenKeys` 兼容读取。

- [ ] **Step 7: 检查残留引用**

Run:

```bash
rg -n "OnboardingOverlay|HomeFirstUseGuideCard|home-guide-dismiss-button|_showFirstUseGuideIfNeeded|shouldShowOnboarding|markOnboardingAsSeen|resetOnboardingStatus|_guideSeenKey" lib test integration_test
```

Expected: 无输出。

- [ ] **Step 8: 运行定向测试**

Run:

```bash
flutter test test/unit/onboarding_service_test.dart test/widget/handfeel_tutorial_test.dart test/widget/tutorial_gesture_stage_test.dart test/widget/v2_home_tutorial_trigger_test.dart test/widget/v2_home_page_redesign_test.dart test/widget/v2_home_generate_hint_test.dart test/widget/v2_home_to_result_flow_test.dart test/widget_test.dart
```

Expected: `All tests passed!`

- [ ] **Step 9: 静态检查**

Run:

```bash
flutter analyze
```

Expected: `No issues found!`

- [ ] **Step 10: 提交**

```bash
git add lib/v2/features/home/home_page.dart lib/v2/features/home/widgets/home_overlays.dart lib/v2/features/onboarding/onboarding_service.dart lib/v2/app_v2.dart test/widget/v2_home_tutorial_trigger_test.dart
git commit -m "refactor: 合并两套首启引导"
```

## Task 7: 全量回归与模拟器验收

**Files:**
- Verify only; fix issues if tests expose them.

- [ ] **Step 1: 格式检查**

Run:

```bash
dart format --output=none --set-exit-if-changed .
```

Expected: `Formatted 272 files (0 changed)`；文件计数以实际输出为准，但必须为 `0 changed`。

- [ ] **Step 2: 静态检查**

Run:

```bash
flutter analyze
```

Expected: `No issues found!`

- [ ] **Step 3: 全量测试**

Run:

```bash
flutter test
```

Expected: 所有测试通过，数量不少于 580 项（当前 565 + 本次新增 15）。

- [ ] **Step 4: 启动模拟器并安装全新构建**

Run:

```bash
xcrun simctl boot ACCF0D7B-1E85-44F5-899D-459E3CDC507A 2>/dev/null || true
open -a Simulator
xcrun simctl bootstatus ACCF0D7B-1E85-44F5-899D-459E3CDC507A -b
xcrun simctl uninstall ACCF0D7B-1E85-44F5-899D-459E3CDC507A com.eatwhat.eatwhatApp
flutter run --no-resident -d ACCF0D7B-1E85-44F5-899D-459E3CDC507A
```

Expected: 应用启动并显示唯一的“开席三式”教学。全新安装清空了 SharedPreferences，旧标记兼容逻辑不会生效。

- [ ] **Step 5: 模拟器逐项验收**

人工确认：

1. 首屏只出现一套教学，没有旧四步遮罩或“选出今天想吃的方向”说明卡。
2. 三章分别为点按、按住拖动、摇一摇；切换无跳帧，文案与真实交互一致。
3. 先点“跳过”进入真实舞台，再验收：连续观察核心容器 15 秒，无同图重复。
4. 连续切换“全部 / 食材健康 / 口味主食 / 菜系 / 场景趣味”各两次，无旧分类残留、无同 ID 双份。
5. 点选、按住抓起、顶部收下、底部拉黑、摇一摇全部保持原样。
6. 终止并重新启动应用，教学不再出现：

```bash
xcrun simctl terminate ACCF0D7B-1E85-44F5-899D-459E3CDC507A com.eatwhat.eatwhatApp
xcrun simctl launch ACCF0D7B-1E85-44F5-899D-459E3CDC507A com.eatwhat.eatwhatApp
```

- [ ] **Step 6: 提交设计与计划文档**

```bash
git add docs/superpowers/specs/2026-10-31-handfeel-tutorial-and-spawn-dedup-design.md docs/superpowers/plans/2026-10-31-handfeel-tutorial-and-spawn-dedup.md
git commit -m "docs: 记录首启教学与发放去重方案"
```

- [ ] **Step 7: 最终状态检查**

Run:

```bash
git status --short
git log -10 --oneline --decorate
```

Expected: 工作区干净，提交历史包含 Task 1–7 的各任务提交、首启教学视觉收尾与文档提交；不 push。

## 自检

- 规格 §3 的发放台账、代次淘汰、待挂载计数与两层测试映射到 Task 1–2。
- 规格 §4 的统一入口、三步真实动作、固定黑金视觉、520/280/700/1800/2000/360ms 节奏、点击内容区推进、触摸吸收、48dp、减动效、语义与窄屏映射到 Task 3–6。
- 规格 §5 的版本化标记、旧标记兼容、首帧后触发与本地隐私承诺映射到 Task 3、Task 6。
- 规格 §6 的三步推进、跳过、二次启动、减动效完成、窄屏 1.3 倍字号与回归映射到 Task 4–7。
- 未修改核心容器布局、物理参数和视觉皮肤；教学使用固定黑金 token，不随米色主题漂移。
- 未新增第三方依赖，未修改数据库、服务端、支付、外卖或账号。
- 所有实现步骤均给出实际代码；所有验证步骤均给出命令与预期结果。
