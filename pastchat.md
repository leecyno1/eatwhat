# pastchat.md — 对话记录梳理（eatwhat）

> 本文件用于把本轮与 Codex 的关键对话、决策、产出与下一步行动沉淀下来，便于持续迭代与回溯。
>
> 时间：2025-12-14（以系统当前会话时间为准）

---

## 1. 会话背景与目标演进

### 1.1 初始诉求（UI 方案）

- 用户希望“搜集历史需求方案”，给出一个“炫酷、功能强大、完备、方便”的项目 UI 设计方案。
- 参考文档与线索主要来自仓库内文档（如 UX/视觉规范/UI flow/当前开发需求/推荐引擎等）。

### 1.2 深入分析子项目（HowToCook / what-to-eat）

- 用户要求深入分析两个子项目：
  - `HowToCook/`（菜谱内容仓库）
  - `what-to-eat/`（Vue + AI 的智能菜谱生成平台）
- 并与当前 Flutter 主工程现状比较，给出结论。

### 1.3 新目标（产品能力重构 + 数据底座升级）

用户提出更强的产品目标（概括）：

- **统一菜谱数据库**：基于下厨房 + HowToCook 的数据库，建立完备、标签化、多维度的统一菜谱数据库，作为项目底层核心之一。
- **学习 what-to-eat 能力**：AI 菜谱生成、菜图生成、酒水/酱汁搭配、趣味占卜、AI 推荐算法等。
- **全新用户流程**：
  1) 大规模“偏好元素气泡库”（≥100 个）供用户交互选择，结合用户行为正向/逆向偏移；
  2) 老虎机式滚动仪式感 + LLM 推理整合偏好，输出推荐菜品，并生成精美菜图；搭配推荐以小气泡出现；
  3) 选择制作路径：自制 / 到店 / 外卖，分别连接菜谱库或餐厅/外卖数据源；全流程收藏贯穿。

用户要求：对上述需求做完整分析、给任务表，并启动下一阶段开发；随后用户明确“开始 1”，再明确“1,2,3 都做”，最后要求构建/运行验证。

---

## 2. 关键结论（子项目对比）

### 2.1 HowToCook

- 定位：高质量、结构化的 Markdown 菜谱语料库；在本项目中更适合作为“精选教程/菜谱内容源”。
- 在当前 Flutter 项目中已经存在 HowToCook 数据库与 UI 集成路径（服务层与 screens），适合被纳入统一数据库底座的一部分数据源。

### 2.2 what-to-eat

- 定位：独立 Web 产品（Vue3 + TS + Tailwind + Vite），核心是 AI 菜谱生成/营养分析/图片生成/酱汁设计/酒水搭配/趣味模块。
- 在本 Flutter 主工程中并无直接技术集成；更适合作为“能力参考与接口抽象设计参考”，而非直接复用前端代码。

---

## 3. 已完成的产出（“1,2,3 都做”对应的落地）

> 这里的“1/2/3”对应用户指的：1）数据校验与去重优化；2）扩写导入脚本（营养/口味向量/场景标签/FTS 等）；3）Flutter 端接入统一数据库。

### 3.1 统一数据库 schema 文档

- 新增：`docs/UNIFIED_RECIPE_SCHEMA.md`
  - 定义统一库的核心表与扩展点：`dish` / `recipe_variant` / `ingredient` / `recipe_ingredient` / `recipe_step` / `nutrition_profile` / `tag` / `dish_tag` / `pairing` / `dish_fts`
  - 明确下厨房与 HowToCook 的映射思路。

### 3.2 统一数据库构建脚本（ETL + 校验）

- 新增：`build_unified_recipes_db.py`
  - 输入：
    - `xiachufang_complete_database.db`
    - `howtocook_complete_recipes.db`
  - 输出：
    - `unified_recipes.db`（并复制到 `assets/data/unified_recipes.db`）
  - 核心能力（本轮完成的重点）：
    - **去重/合并**：基于 `canonical_name + cuisine + main_ingredient` 的 key 做合并策略；并输出“潜在重复 canonical_name”的校验报告。
    - **标签推断**：从 tags/category 等字段推断 taste/method/scene/health（启发式规则），写入 `dish` 的 JSON 字段与 `dish_tag`。
    - **营养估算**：基于主要食材关键词启发式估算 `nutrition_profile`（标记 `data_source=estimated`），保证 dish 都有营养记录。
    - **FTS 构建**：填充 `dish_fts`，支持 name/tags/ingredients 的全文检索。
    - **验证报告**：输出 dish/variant 数量、无营养条目数、潜在重复等。
  - 运行方式：
    - `python build_unified_recipes_db.py`

### 3.3 Flutter 侧统一数据库访问服务

- 新增：`lib/core/services/unified_recipe_database_service.dart`
  - 首次运行自动从 assets 复制 `assets/data/unified_recipes.db` 到应用数据库目录。
  - 提供查询能力：
    - 热门列表（按人气排序）
    - 按菜系过滤
    - FTS 搜索（并带 LIKE fallback）
  - Hydration：为每条结果补齐 tags / ingredients / steps / nutrition，并解析 JSON 字段（taste_profile/cooking_methods/scenes/health_tags 等）。

### 3.4 现有 UI/控制器接入统一 DB（替换 mock）

- 修改：`lib/features/recipe/controllers/enhanced_recipe_controller.dart`
  - 初始化阶段确保统一库可用：`ensureInitialized()`
  - 推荐列表/分页/搜索从 `UnifiedRecipeDatabaseService` 拉取
  - 将 DB 行映射为 `EnhancedRecipe`（复用现有 UI 展示链路）
  - 移除 mock 生成逻辑（`_generateMockRecipes`、mock helper 等不再作为推荐来源）

### 3.5 决策更新：以 V2 为主线（接入统一库 + 推荐 + 收藏）

- 用户明确选择：以 V2 为主，把 `unified_recipes.db`、推荐引擎、收藏体系接入 V2 流程（首页气泡 → 老虎机 → 结果页 → 详情）。
- 背景：`lib/main.dart` 当前启动 `AppV2`，因此 `lib/features/*` 的旧页面链路在运行时不可达（除非切回旧入口）。

#### 3.5.1 V2 收藏体系（偏好标签 + 菜品）

- 新增：`lib/v2/core/services/v2_favorites_service.dart`
  - 基于 `SharedPreferences` 持久化：
    - `favoriteTagIds`：收藏偏好元素（如 `f_spicy`）
    - `favoriteRecipeIds`：收藏菜品（使用 `dish_id` 作为稳定 id）
  - 提供读取/切换/批量设置能力，便于后续“收藏偏好必出现”的采样逻辑。

#### 3.5.2 V2 推荐接入统一菜谱库（本地优先，AI 兜底）

- 新增：`lib/v2/core/services/unified_recommendation_service_v2.dart`
  - 使用 `UnifiedRecipeDatabaseService` 从 `unified_recipes.db` 搜索/取热门
  - 基于“标签命中数 + 人气 + 评分”的启发式打分排序，产出 V2 的 `RecipeModel`

#### 3.5.3 V2 决策页（老虎机阶段）改为优先统一库推荐

- 修改：`lib/v2/features/decision/decision_page.dart`
  - 先用 `UnifiedRecommendationServiceV2` 生成本地推荐列表
  - 再尝试走 `AiService`（若返回为空则保留本地推荐结果）

#### 3.5.4 V2 结果页加入“收藏菜品”按钮

- 修改：`lib/v2/features/result/result_page.dart`
  - 增加心形按钮：对当前展示的 `RecipeModel.id` 做收藏/取消收藏

#### 3.5.5 V2 首页气泡注入“收藏偏好必出现”

- 修改：`lib/v2/features/home/game/bubble_data_manager.dart`
  - 初始化时加载 `favoriteTagIds` 并在 `getInitialBubbles()` 首批气泡中优先注入

#### 3.5.6 AI 环境变量加载修复

- 修改：`lib/main.dart`
  - 在 `runApp` 前调用 `EnvConfig.init()`，确保 `AiService` 依赖的 `flutter_dotenv` 已加载 `.env`

---

## 4. 构建与运行验证记录

### 4.1 iOS 构建（Xcode）

- 执行：`flutter build ios`
- 结果：成功产出 `build/ios/iphoneos/Runner.app`

### 4.2 macOS 运行（用于快速验证）

- 执行：`flutter run -d macos`
- 结果：应用启动后抛出插件缺失异常：
  - `MissingPluginException`（`sensors_plus` 在 macOS 上无实现/未配置）
- 结论：macOS 端需对传感器能力做平台降级/条件编译；或改用 iOS/Android 真机/模拟器验证。

### 4.3 模拟器/真机测试现状

- `flutter devices`：仅检测到 macOS/Chrome；无线 iPad 连接因开发者模式/网络扫描失败导致不可用。
- `flutter emulators`：未发现 iOS Simulator/Android AVD（本机缺少模拟器运行时/AVD）。
- 结论：如需“模拟真机测试”，需先在 Xcode 安装 iOS Simulator runtime 或配置 Android AVD；或使用数据线连接真机并开启 Developer Mode。

### 4.4 本轮新增的验证诉求（待执行）

- 用户要求：打开 iOS 模拟器并运行应用进行测试（优先 iOS Simulator，其次 iOS 真机）。

---

## 5. 当前已知问题与风险（需后续处理）

1) **macOS 传感器插件崩溃**  
   - 需要对 `sensors_plus` 相关调用做平台判断（macOS/web 禁用或 fallback）。

2) **统一库数据规模仍偏小**  
   - 当前下厨房库在本地样本不大（导入脚本能跑通，但需扩容抓取/同步策略）。

3) **去重策略仍是启发式**  
   - 目前输出“潜在重复 canonical_name”提示；后续建议提升到“多信号合并”（菜名 + 主食材集合 + 口味向量 + tags 相似度）。

4) **现有 Recipe UI/模型字段与统一库字段不完全一致**  
   - 当前映射是“最小可用”，后续应在统一库里补齐更真实字段（评分/收藏/作者/原始链接/图片等），并在模型端完善展示。

5) **测试/静态分析健康度较低**  
   - `flutter analyze` 存在较多告警/问题（历史遗留），`test/widget_test.dart` 可能仍引用旧入口（如 `EatWhatApp`）。

---

## 6. 下一步建议（最短路径）

### 6.1 先让 iOS 真机/模拟器可跑通

- 优先：用 iOS 真机（数据线）跑 `flutter run -d <deviceId>`，验证统一库 UI 展示和搜索。
- 同时：对 macOS 传感器做条件禁用，确保桌面也能快速回归验证。

### 6.2 扩容统一数据库（向“底层核心”靠拢）

- 扩大下厨房抓取/同步量（目标：至少 1k+ 级别 recipes/dish）。
- 增强标签体系（菜系/口味/做法/场景/健康/营养等）与标准化 ingredient 词典（别名表）。
- 维护高质量 FTS：支持中文分词（如后续引入 tokenizer 或外部索引方案）。

### 6.3 启动“偏好元素气泡库（≥100）”的资源与配置工程

- 以 `tag` 词典为中心输出 `PreferenceElement` 配置（type/icon/色彩/动效 key）。
- 建立 UI 库（至少 100 个元素的图形化+动效规范），并把“收藏偏好必出现”纳入采样逻辑。

---

## 7. 本轮新增/修改文件清单（重点）

- `docs/UNIFIED_RECIPE_SCHEMA.md`
- `build_unified_recipes_db.py`
- `assets/data/unified_recipes.db`
- `lib/core/services/unified_recipe_database_service.dart`
- `lib/features/recipe/controllers/enhanced_recipe_controller.dart`
- `lib/v2/core/services/v2_favorites_service.dart`
- `lib/v2/core/services/unified_recommendation_service_v2.dart`
- `lib/v2/features/decision/decision_page.dart`
- `lib/v2/features/result/result_page.dart`
- `lib/v2/features/home/game/bubble_data_manager.dart`
- `lib/main.dart`

---

## 8. V2 新目标确认（补充）

### 8.1 四模块框架（用户侧链路）

- 模块 1（V2 已落地骨架）：**气泡偏好首屏 + 老虎机**（随机出现偏好元素，用户选择后进入老虎机，输出候选菜品）。
- 模块 2（AI）：基于大模型的**菜品/菜谱生成**（含图片生成、酒水/酱汁/主食/配菜搭配、趣味占卜等）。
- 模块 3（流量导出）：用户选择“自制 / 到店 / 外卖”三路径：
  - 自制：走本地菜谱库（统一库）+ 生成式补全（可选）。
  - 到店：跳转/对接点评/地图等承载，给出门店与导航。
  - 外卖：跳转/对接美团/饿了么等承载，完成下单。
- 模块 4（贯穿能力）：收藏体系、历史记录、偏好学习（正向偏移/逆向推荐）与全局配置。

### 8.2 外卖对接路线选择（合规约束明确）

- 用户明确选择更贴近 **B 路线**：**用户侧直接去平台下单**（不扮演商家，不做商家系统对接）。
- 关键约束：不做逆向抓包/私有接口“挖掘”/绕登录；只能基于**官方开放平台**与**官方承载方案**（如 openH5/SDK/官方 App 跳转）来实现“从推荐到下单”的通路。
