# 需求/方案索引（仓库现存）

> 目的：把仓库内分散的“需求、设计、执行、算法、UI、测试、报告”统一索引，便于后续按 V2 主线持续迭代。
>
> 说明：本索引只做归纳与定位，不替代原文档；以文件路径为准。

---

## 1. 核心需求（V2 四模块闭环）

- `docs/A002_需求分析文档_V2.md`：V2 愿景与四大模块（偏好气泡/AI 决策/执行路径/收藏个性化）。
- `docs/REDESIGN_PLAN.md`：面向可上线 iOS 版本的重设计方案与里程碑（M0/M1/M2）。
- `docs/UI_FLOW.md`：关键界面与交互（Onboarding → 气泡 → 候选卡片 → 详情 → 附近餐馆）。
- `PHASE3_REQUIREMENTS_ANALYSIS.md`：Phase3 需求（搭配/趣味/三路径执行/收藏）。
- `CURRENT_DEVELOPMENT_REQUIREMENTS.md` / `docs/CURRENT_DEVELOPMENT_REQUIREMENTS.md`：当前开发需求汇总（随阶段变化）。

---

## 2. 数据底座（菜谱库/统一库/HowToCook）

- `docs/UNIFIED_RECIPE_SCHEMA.md`：统一菜谱库 schema（dish/variant/ingredient/tag/pairing/nutrition/FTS）。
- `build_unified_recipes_db.py`：统一库构建脚本（HowToCook → `unified_recipes.db`）。
- `docs/DB_SCHEMA.md`：旧版 recipes.db/FTS 设计草案（可对照迁移）。
- `XIACHUFANG_DATABASE_ANALYSIS.md`：历史参考；V2 主链路已不再使用下厨房源。
- `HOWTOCOOK_INTEGRATION_COMPLETE_REPORT.md`、`HOWTOCOOK_ENHANCED_INTEGRATION_COMPLETE_REPORT.md`：HowToCook 数据化集成报告。

---

## 3. 推荐与算法（可解释、多样性、偏好学习）

- `docs/RECOMMENDATION_ENGINE_V2.md`：推荐引擎 V2（可解释打分 + MMR 多样性 + 缓存 + 权重可配）。
- `docs/ALGORITHM_SPEC.md`：偏好学习（成对学习/探索利用）与召回排序流程。
- `docs/ANALYTICS_PLAN.md`：埋点/指标计划（用于“决策效率/满意度/转化”闭环）。

---

## 4. UI/视觉与交互系统

- `UI_DESIGN_PROPOSAL.md`：UI 设计提案（整体视觉与交互方向）。
- `docs/视觉设计规范.md`：视觉规范（色彩/排版/动效等）。
- `docs/BUBBLE_DYNAMIC_INTERACTION_COMPLETE_REPORT.md`、`docs/bubble_interaction_system.md`：气泡动态交互系统实现/修复记录。
- `docs/UI_UPGRADE_GUIDE.md`、`docs/UI_OPTIMIZATION_COMPLETE_REPORT.md`：UI 升级与优化报告。

---

## 5. 执行路径（自制/到店/外卖）与导流

- `PHASE3_TEST_GUIDE.md`：Phase3 测试指南（含下厨房同步/推荐/图片生成/外链等验证入口说明）。
- `lib/core/services/purchase_link_service.dart`：外卖/点评/通用搜索深链或网页 fallback（导流基础设施）。
- `lib/core/services/delivery_api_service.dart`、`lib/core/services/delivery_recommendation_service.dart`：外卖模拟数据/推荐服务（可迁移到 V2）。
- `lib/features/recommendation/widgets/channel_selector_dialog.dart`：渠道选择 UI（美团/饿了么/大众点评）。

---

## 6. 工程/架构/测试与运行

- `ARCHITECTURE_ANALYSIS_REPORT.md`、`architecture.md`、`docs/技术设计文档.md`：架构分析与技术设计。
- `XCODE_RUN_GUIDE.md`、`docs/XCODE_BUILD_STEPS.md` 等：iOS 构建/真机/模拟器指南。
- `docs/DEVICE_TESTING_GUIDE.md`、`REAL_DEVICE_TEST_GUIDE.md`：设备测试流程。
- `PHASE3_TASK_LIST.md`：阶段任务清单（Roadmap）。

---

## 7. 关键代码入口（与“V2 主线”最相关）

> 注：当前 app 入口以 V2 为主（`lib/main.dart` → `AppV2`）。

- V2 交互链路：
  - `lib/v2/features/home/home_page.dart`（首页/气泡入口）
  - `lib/v2/features/home/game/bubble_game.dart`、`lib/v2/features/home/game/bubble_data_manager.dart`
  - `lib/v2/features/decision/decision_page.dart`（老虎机/决策）
  - `lib/v2/features/result/result_page.dart`（结果/收藏）
  - `lib/v2/features/details/recipe_detail_page.dart`（详情）
- 统一菜谱库：
  - `assets/data/unified_recipes.db`
  - `lib/core/services/unified_recipe_database_service.dart`
  - `lib/v2/core/services/unified_recommendation_service_v2.dart`
- 收藏（V2）：
  - `lib/v2/core/services/v2_favorites_service.dart`
