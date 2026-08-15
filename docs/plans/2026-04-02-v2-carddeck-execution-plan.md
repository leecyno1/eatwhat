# V2 Card Deck And Execution Flow Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** 将 V2 从气泡主交互重构为卡牌首屏，并把结果页后的执行层升级为真正的三路径页面。

**Architecture:** 保留现有 `FloatingEditorialBackground`、`GenerationService`、`UnifiedRecommendationServiceV2` 和结果页的暖色玻璃视觉资产；输入层切换为新的卡牌会话状态与 `TasteInferenceInput`，执行层切换为 `ExecutionIntent + ProviderCapabilityMatrix` 驱动的页面导航。平台能力继续通过 Provider 骨架承载，但客户端必须显式展示“未开通/不可用”，不再沉默降级。

**Tech Stack:** Flutter, shared_preferences, sqflite, dio, freezed(json only on existing model), widget/unit tests

---

### Task 1: 建立新的 V2 领域模型

**Files:**
- Create: `lib/v2/core/data/models/taste_inference_input.dart`
- Create: `lib/v2/core/data/models/taste_selection_models.dart`
- Modify: `lib/v2/core/external/platform/platform_types.dart`
- Modify: `lib/v2/core/external/platform/platform_provider.dart`

**Step 1: 写测试**
- 首页卡牌状态能记录 `liked/disliked/skipped/freeform/faceStage`
- `TasteInferenceInput.fromSession(...)` 能正确输出 AI 输入
- Provider 能暴露能力矩阵

**Step 2: 运行失败测试**
- `flutter test test/unit/v2_taste_flow_models_test.dart`

**Step 3: 写最小实现**
- 新增卡牌会话状态、卡牌数据模型、推理入参模型
- 扩展平台类型：`ExecutionIntent`、`PairingSelection`、`ProviderCapabilityMatrix`、`DeliveryMatchResult`、`DineInMatchResult`

**Step 4: 重新跑测试**
- `flutter test test/unit/v2_taste_flow_models_test.dart`

### Task 2: 重构首页为卡牌桌游

**Files:**
- Modify: `lib/v2/features/home/home_page.dart`
- Create: `lib/v2/features/home/widgets/taste_card_deck.dart`
- Create: `lib/v2/features/home/widgets/taste_signature_panel.dart`

**Step 1: 写失败测试**
- 首页主舞台改为卡牌容器，不再以 `BubbleOcean` 为核心
- Face 1 能显示当前卡牌与收集进度
- Face 2 能显示已收集签名与进入推理按钮

**Step 2: 运行失败测试**
- `flutter test test/widget/v2_home_page_redesign_test.dart`

**Step 3: 写最小实现**
- 新首页保留弱化文本入口、收藏入口、首次引导
- 卡牌支持上滑喜欢、下滑讨厌、左右略过
- 完成若干张卡或手动点击后进入 Face 2

**Step 4: 重新跑测试**
- `flutter test test/widget/v2_home_page_redesign_test.dart`

### Task 3: 接入新的 AI 推理输入

**Files:**
- Modify: `lib/v2/features/decision/decision_page.dart`
- Modify: `lib/v2/core/services/unified_recommendation_service_v2.dart`

**Step 1: 写失败测试**
- `DecisionPage` 能接收 `TasteInferenceInput`
- 推理页文案改为“口味签名 -> 菜品收束”

**Step 2: 运行失败测试**
- `flutter test test/widget/v2_decision_page_continuity_test.dart`

**Step 3: 写最小实现**
- 本地召回优先使用 liked 标签和文本要求
- disliked/skipped 进入 AI 提示词与本地过滤
- 结果页继续输出 3-5 个候选

**Step 4: 重新跑测试**
- `flutter test test/widget/v2_decision_page_continuity_test.dart`

### Task 4: 重构结果页与执行入口

**Files:**
- Modify: `lib/v2/features/result/result_page.dart`
- Modify: `lib/v2/features/details/recipe_detail_page.dart`
- Replace: `lib/v2/features/execution/execution_sheet.dart`
- Create: `lib/v2/features/execution/execution_home_page.dart`
- Create: `lib/v2/features/execution/delivery_execution_page.dart`
- Create: `lib/v2/features/execution/dine_in_execution_page.dart`

**Step 1: 写失败测试**
- 结果页执行入口跳转到执行主页
- 执行主页展示三路径语义色卡
- 未配置平台时显示未开通，而非空白

**Step 2: 运行失败测试**
- `flutter test test/widget/v2_result_page_continuity_test.dart`
- `flutter test test/widget/v2_result_pairing_band_test.dart`
- `flutter test test/widget/v2_execution_flow_test.dart`

**Step 3: 写最小实现**
- `ExecutionSheet.show(...)` 升级为页面导航入口
- 自制跳 `RecipeDetailPage`
- 外卖/堂食页面消费能力矩阵与匹配结果

**Step 4: 重新跑测试**
- 上述测试全部通过

### Task 5: 平台能力矩阵与执行服务收口

**Files:**
- Modify: `lib/v2/core/services/v2_execution_service.dart`
- Modify: `lib/v2/core/external/platform/providers/meituan_provider.dart`
- Modify: `lib/v2/core/external/platform/providers/eleme_provider.dart`
- Modify: `lib/v2/core/external/platform/providers/dianping_provider.dart`

**Step 1: 写失败测试**
- 能读取每个平台能力矩阵
- 未配置时返回 unavailable 状态
- 配置存在但无具体实现时也要显式说明

**Step 2: 运行失败测试**
- `flutter test test/unit/v2_execution_service_test.dart`

**Step 3: 写最小实现**
- 统一平台状态对象
- 聚合 delivery/dine-in 结果
- 显式不可用原因

**Step 4: 重新跑测试**
- `flutter test test/unit/v2_execution_service_test.dart`

### Task 6: 整体验证

**Files:**
- Modify as needed based on failures

**Step 1: 运行关键测试**
- `flutter test test/unit/v2_taste_flow_models_test.dart`
- `flutter test test/unit/v2_execution_service_test.dart`
- `flutter test test/widget/v2_home_page_redesign_test.dart`
- `flutter test test/widget/v2_decision_page_continuity_test.dart`
- `flutter test test/widget/v2_result_page_continuity_test.dart`
- `flutter test test/widget/v2_result_pairing_band_test.dart`
- `flutter test test/widget/v2_execution_flow_test.dart`

**Step 2: 跑静态检查**
- `flutter analyze`

**Step 3: 记录结果**
- 在最终说明中列明哪些平台仍是“待开通能力”
