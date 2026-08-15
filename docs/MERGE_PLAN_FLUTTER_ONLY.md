# 合并方案：HowToCook + what-to-eat → Flutter V2（唯一前端）

> 目标：不再维护 Web 前端（`what-to-eat`），以 **Flutter App（V2）** 作为唯一用户入口；同时吸收：
> - **HowToCook**：确定性菜谱底座（离线稳定、可检索）
> - **what-to-eat**：AI 生成工作流（菜谱 JSON/图片/营养/搭配/占卜/动态配置）

---

## 0. 一句话结论

- **HowToCook 变成数据库“原料”**（导入到 `unified_recipes.db`，用于自制步骤/食材/分类标签）。
- **what-to-eat 变成 Flutter 的“生成引擎参考实现”**（提示词、JSON 清洗、扩展能力与配置体系迁移到 V2）。
- **Flutter V2 负责把“决定 → 生成/解释 → 执行（自制/到店/外卖）→ 收藏/学习”串成闭环**。

---

## 1. 四模块产品框架（与代码落点对应）

### 模块 1：气泡偏好首屏 + 老虎机（已存在，V2 主线）
- 目标：让用户“快速表达偏好”，避免复杂表单。
- 数据：偏好标签（上百个）+ 学习权重（正/负反馈）+ 收藏注入。
- 代码入口：
  - `lib/v2/features/home/widgets/bubble_ocean.dart`
  - `lib/v2/features/decision/decision_page.dart`
  - `lib/v2/features/home/game/`（物理气泡）

### 模块 2：大模型生成（从 what-to-eat 吸收）
- 能力包（按优先级迭代）：
  1) 生成“推荐菜品解释/卖点文案”（低成本，提升沉浸感）
  2) 生成菜品图片（生成/缓存/重生成）
  3) 营养分析（结构化 JSON）
  4) 饮品/酱汁/主食/配菜搭配（结构化 JSON）
  5) 趣味占卜（结构化 JSON + 轻动画呈现）
- 代码落点（建议）：
  - `lib/v2/core/services/generation_service.dart`（统一入口）
  - `lib/v2/core/services/v2_ai_cache_service.dart`（本地缓存）
  - UI：`lib/v2/features/details/recipe_detail_page.dart`

### 模块 3：执行闭环（自制 / 到店 / 外卖）
- 自制：走 **unified_recipes.db** 的步骤/食材，离线可用。
- 到店/外卖：先做“跳转 + 复制菜名/关键词”，后续接平台 **openH5/Opensite**（合规）。
- 代码入口：
  - `lib/v2/features/execution/execution_sheet.dart`
  - `lib/v2/core/external/platform/`（预留：openH5/签名/回跳）

### 模块 4：收藏/历史/偏好学习（贯穿全流程）
- 收藏对象：偏好标签、菜品、（后续）餐厅/外卖店/套餐。
- 学习对象：标签正负反馈、最近选择菜品去重、偏好漂移（正向偏移/逆向探索）。
- 代码入口：
  - `lib/v2/core/services/v2_favorites_service.dart`
  - `lib/v2/core/services/v2_preference_feedback_service.dart`
  - `lib/v2/features/favorites/favorites_page.dart`

---

## 2. 数据底座：HowToCook 与下厨房统一到 unified_recipes.db

### 2.1 统一库定位
- `assets/data/unified_recipes.db`：Flutter 端离线召回与详情展示的“单一真相来源”（SSOT）。
- 内容：菜品（dish）+ 变体（recipe_variant/source）+ 食材/步骤 + 标签（tag）+ 菜品标签关系（dish_tag）。

### 2.2 构建工作流（离线可重复）
- 原始数据：
  - HowToCook：`HowToCook/`（Markdown + 资源）
  - 下厨房：`xiachufang_complete_database.db` 等
- 构建脚本：
  - `build_unified_recipes_db.py`（统一库构建）
  - `howtocook_database_builder.py` / `howtocook_enhanced_database_builder.py`（HowToCook 结构化）
- 产物：
  - `assets/data/unified_recipes.db`（随 App 打包）

> 注意：统一库 schema 以 `docs/UNIFIED_RECIPE_SCHEMA.md` 为设计参考，实际字段以代码与数据库为准（后续会把该文档更新为“设计 + 实际落地差异”）。

---

## 3. 生成能力迁移：把 what-to-eat 的“提示词 + 结构化 JSON”搬进 Flutter

### 3.1 迁移的“精华”（必须保留）
- **严格 JSON 输出**：system prompt 要求“只输出 JSON，不要多余文字”。
- **清洗 ```json``` 包裹**：容错处理（模型经常包代码块）。
- **动态配置**：baseUrl/model/timeout/temperature 可调（开发阶段走 `.env`，生产走后端下发非敏感策略）。
- **降级策略**：AI 失败时返回 fallback（比如营养分析/饮品搭配可给规则版兜底）。

### 3.2 统一的生成服务边界（Flutter 内部）
建议将“生成能力”拆成 1 个入口服务 + 多个子能力：
- `GenerationService`
  - `generateDishImage(dishName, tags, style)`
  - `generateNutrition(recipe)`
  - `generateDrinkPairing(recipe)`
  - `generateSauce(recipe, preference?)`
  - `generateFortune(params)`

### 3.3 生产环境的安全边界（非常重要）
- 客户端 **不应** 内置任何平台 secret / AI API key。
- 推荐做法：加一个极薄后端（仅做签名/换 token/代理请求/限流审计），Flutter 只拿“短期 token/一次性 URL”。
- 开发阶段可临时用 `.env` 直连（仅用于自测，不发布到商店）。

---

## 4. 标签系统（从硬编码 → DB 词典 + UI 视觉映射）

现状：
- V2 气泡标签主要来自 `TagRepositoryV2`（硬编码 + `VisualConfig`），利于快速出效果，但难以与统一库完全对齐。

目标：
- `unified_recipes.db.tag` 作为 SSOT（可扩展、可统计、可回溯）。
- Flutter 侧维护一份“视觉映射表”（`tag_id -> VisualConfig`），支持：
  - 没有配置的 tag 自动降级为默认样式
  - 后续把视觉配置做成可在线下发（非敏感配置）

落地路线：
1) **短期**：继续用 `TagRepositoryV2`，补足 ≥100 个元素，并加入 `fortune` 类别。
2) **中期**：实现 `TagRepositoryDb`（从 `unified_recipes.db` 读取 tags），并与 `VisualConfig` 映射合并。
3) **长期**：把视觉配置做成数据资产（JSON/DB 表），支持热更新与运营。

---

## 5. 代码层“最终形态”示意（推荐）

### 5.1 本地数据（稳定）
- `UnifiedRecipeDatabaseService`：本地 SQLite 查询/FTS
- `RecipeRepository`：封装“搜索/按 tag 召回/详情/随机/收藏列表”
- `UnifiedRecommendationServiceV2`：启发式打分（后续可替换）

### 5.2 在线增强（可选）
- `GenerationService`：LLM/图片生成（带缓存、超时、降级）
- `OpenPlatformClient`：平台 openH5（仅承载合规能力；需要后端签名支持）

---

## 6. 近期任务拆解（建议按 1～2 天一个里程碑）

### 里程碑 A（模块 2 MVP：详情页 AI 增强）
- [ ] 迁移 what-to-eat 的 JSON 清洗逻辑到 Flutter
- [ ] 新增 `GenerationService`：营养/饮品/占卜（先文本 JSON）
- [ ] 详情页增加“AI 工具栏”：一键生成 + 结果展示（底部抽屉）
- [ ] 加缓存（SharedPreferences/本地文件），避免重复请求

### 里程碑 B（标签库补齐 + 占卜入口）
- [ ] TagRepositoryV2 增加 `fortune` 类标签（保证总数 ≥100）
- [ ] 气泡池采样支持新类别（并保证类别多样性）

### 里程碑 C（统一库标签对齐）
- [ ] 从 `unified_recipes.db` 读 tag 列表（替代硬编码标签的“数据部分”）
- [ ] 实现 `tag_id -> VisualConfig` 映射表（UI 资产）

### 里程碑 D（模块 3：平台 openH5 接入前置）
- [ ] 完成平台能力申请（见 `docs/PLATFORM_OPENH5_APPLICATION_CHECKLIST.md`）
- [ ] 设计后端签名/回跳协议（Flutter deep link）
- [ ] 通过后接入“直达商品/预填购物车/结算页”

