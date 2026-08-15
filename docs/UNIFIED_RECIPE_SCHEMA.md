# 统一菜谱数据库设计（HowToCook）

> 当前实现状态：V2 主链路已废弃下厨房数据源，`build_unified_recipes_db.py` 只从本地 HowToCook markdown / HowToCook SQLite 兜底源构建 `unified_recipes.db`。
>
> 目标：在 HowToCook 真实菜谱基础上，设计一套统一的菜谱数据库结构，作为《吃什么》项目的底层核心之一。

---

## 1. 设计目标与原则

- **统一抽象**：以 HowToCook 真实菜谱作为唯一主数据源，在统一的菜品 / 菜谱结构下支撑推荐、详情和执行页。
- **标签化 + 可向量化**：所有重要维度（菜系、口味、食材、做法、场景、营养、健康标签等）都能映射到标准标签和/或数值向量，支撑推荐和 AI 推理。
- **主源可信**：菜品展示、详情页食材/步骤、图片 manifest 优先使用可追溯到 HowToCook 的真实内容。
- **可扩展**：结构上保留 `source` 字段，但当前正式库只允许 `source='howtocook'`。

现有参考：

- `DB_SCHEMA.md` 中已有初版 `recipes.db` 设计（`dish` / `ingredient` / `recipe`）。
- `HOWTOCOOK_ENHANCED_INTEGRATION_COMPLETE_REPORT.md` 描述了 HowToCook 增强版数据库的字段与分类。

下面的设计在此基础上做统一与升级。

---

## 2. 核心概念与实体

### 2.1 Dish（菜品概念）

> 一道菜的「抽象概念」，不绑定具体做法。

关键字段：

- `id`：内部统一 ID。
- `name_cn` / `name_en` / `canonical_name`：名称及规范化名字。
- `cuisine`：菜系（川 / 粤 / 湘 / 鲁 / 苏 / 浙 / 闽 / 徽 / 国际等）。
- `taste_profile`：口味特征向量 JSON（甜/酸/苦/辣/咸/鲜/香/麻）。
- `main_ingredients`：主要食材列表（JSON）。
- `cooking_methods`：烹饪方式集合（炒/煮/蒸/炸/烤/炖/凉拌/烘焙等）。
- `scenes`：适用场景（早餐/夜宵/聚餐/减脂/暖胃等）。
- `health_tags`：健康标签（低脂/高蛋白/素食/儿童友好等）。
- `seasonality`：季节性（春/夏/秋/冬）。
- `popularity_score`：综合人气（评分 / 收藏 / 制作次数等归一化后的结果）。

### 2.2 RecipeVariant（菜谱变体）

> 某一道菜的一个具体做法（1: 多）。

关键字段：

- `dish_id`：关联到 Dish。
- `source`：数据来源；当前正式库只使用 `howtocook`。
- `source_recipe_id`：来源内部 ID（字符串）。
- `title` / `description`：标题、简介（可与 Dish 不同）。
- `difficulty`：难度（1–5 星）。
- `total_time_minutes`：总耗时（准备 + 烹饪）。
- `servings`：几人份。
- `cover_image_url` / `cover_image_attribution`：封面图及版权信息。
- `language`：菜谱语言（`zh-CN` 等）。

### 2.3 Ingredient 与 RecipeIngredient（食材）

- `Ingredient`：统一的食材词典（含别名、分类、营养属性）。  
- `RecipeIngredient`：某个菜谱中具体使用的食材及用量。

典型字段：

- `Ingredient.name_cn` / `name_en` / `canonical_name` / `category` / `aliases`。
- `RecipeIngredient.recipe_id` / `ingredient_id?` / `name_override` / `quantity` / `unit` / `preparation` / `is_main`。

### 2.4 RecipeStep（制作步骤）

> 有序的制作流程。

- `recipe_id`：关联菜谱。
- `step_index`：步骤序号。
- `instruction`：文字指引。
- `image_url`：步骤图片（可选）。
- `duration_seconds`：预计时间。
- `tips`：该步骤的技巧/注意事项。

### 2.5 NutritionProfile（营养信息）

> 针对 Dish / Recipe / Ingredient 的营养数据。

字段示例：

- `target_type`：`dish` / `recipe` / `ingredient`。
- `target_id`：对应 ID。
- `calories` / `protein` / `fat` / `carbs` / `fiber` / `sugar` / `sodium` 等。
- `per`：`serving` / `100g`。
- `data_source`：`source_db` / `estimated` / `ai`。

### 2.6 Tag & DishTag（标签体系）

> 用统一标签体系来表达菜系、口味、做法、场景、健康标签、质感、节日、趣味占卜等。

- `Tag`：标签词典。  
- `DishTag`：菜与标签的多对多关系。

Tag 核心字段：

- `category`：`cuisine` / `taste` / `method` / `scene` / `health` / `texture` / `occasion` / `fortune` / `howtocook_category` 等。
- `key`：规范化 key（如 `sichuan`, `spicy`, `breakfast`）。
- `name_cn` / `name_en`。
- `description`。
- `icon_key`：与 UI 气泡实体对应的图标标识。

### 2.7 Pairing（搭配关系）

> 对应「饮品/配菜/主食搭配」等需求。

- `dish_id`：主菜。
- `type`：`drink` / `side` / `staple` 等。
- `target_dish_id`（可选）：如果搭配的是另一道 Dish。
- `name`：自由文案名称（比如具体酒款/饮品）。
- `description`：说明/理由。
- `strength`：推荐强度（0–1）。
- `source`：`rule` / `ai` / `manual`。

---

## 3. SQLite 表结构（DDL 草案）

> 注意：本 DDL 面向独立的 `unified_recipes.db`。后续导入脚本会负责从现有数据库写入该库。

```sql
-- 菜品（统一概念）
CREATE TABLE dish (
  id                    INTEGER PRIMARY KEY AUTOINCREMENT,
  slug                  TEXT UNIQUE,             -- 稳定标识（可选，用于跨库同步）
  name_cn               TEXT NOT NULL,
  name_en               TEXT,
  canonical_name        TEXT,                    -- 规范化名称（用于去重）

  cuisine               TEXT,                    -- 主要菜系（冗余字段，详细信息在 tag/dish_tag 中）
  main_ingredients      TEXT,                    -- JSON 数组：主要食材名称或 ingredient_id
  taste_profile         TEXT,                    -- JSON：{sweet:0.2, sour:0.1, spicy:0.8, ...}
  cooking_methods       TEXT,                    -- JSON 数组：["炒","炖",...]
  scenes                TEXT,                    -- JSON 数组：["早餐","夜宵",...]
  health_tags           TEXT,                    -- JSON 数组：["低脂","高蛋白",...]
  seasonality           TEXT,                    -- JSON 数组：["冬", "秋"]

  popularity_score      REAL,                    -- 综合人气得分
  average_rating        REAL,                    -- 1~5
  rating_count          INTEGER,
  source_count          INTEGER,                 -- 变体数量

  created_at            INTEGER,                 -- 统一库创建时间 (epoch ms)
  updated_at            INTEGER                  -- 最近一次更新
);

CREATE INDEX idx_dish_cuisine ON dish(cuisine);


-- 菜谱变体（来源：下厨房 / HowToCook / AI 等）
CREATE TABLE recipe_variant (
  id                    INTEGER PRIMARY KEY AUTOINCREMENT,
  dish_id               INTEGER NOT NULL REFERENCES dish(id) ON DELETE CASCADE,

  source                TEXT NOT NULL,          -- 'xiachufang' | 'howtocook' | 'ai' | ...
  source_recipe_id      TEXT,                   -- 原库中的 recipe id

  title                 TEXT,                   -- 变体标题（可与 dish.name 不同）
  description           TEXT,
  difficulty            INTEGER,                -- 1~5 星
  total_time_minutes    INTEGER,
  prep_time_minutes     INTEGER,
  cook_time_minutes     INTEGER,
  servings              INTEGER,

  cover_image_url       TEXT,
  cover_image_attribution TEXT,
  language              TEXT,                   -- 'zh-CN' 等

  is_structured         INTEGER NOT NULL DEFAULT 1,  -- 是否已结构化（步骤/食材完整）

  created_at            INTEGER,
  updated_at            INTEGER
);

CREATE INDEX idx_recipe_variant_dish ON recipe_variant(dish_id);
CREATE INDEX idx_recipe_variant_source ON recipe_variant(source, source_recipe_id);


-- 统一食材词典
CREATE TABLE ingredient (
  id                    INTEGER PRIMARY KEY AUTOINCREMENT,
  name_cn               TEXT NOT NULL,
  name_en               TEXT,
  canonical_name        TEXT,                  -- 规范化名称，用于别名归一
  category              TEXT,                  -- 'meat' | 'vegetable' | 'staple' | 'seasoning' | ...
  aliases               TEXT,                  -- JSON 数组：["青椒","柿子椒",...]

  created_at            INTEGER,
  updated_at            INTEGER
);

CREATE INDEX idx_ingredient_canonical ON ingredient(canonical_name);


-- 菜谱-食材关系
CREATE TABLE recipe_ingredient (
  id                    INTEGER PRIMARY KEY AUTOINCREMENT,
  recipe_id             INTEGER NOT NULL REFERENCES recipe_variant(id) ON DELETE CASCADE,
  ingredient_id         INTEGER REFERENCES ingredient(id),

  name_override         TEXT,                  -- 源数据中的原始名字（便于追溯）
  quantity              REAL,                  -- 数值部分
  unit                  TEXT,                  -- g / ml / 个 / 勺 等
  preparation           TEXT,                  -- 切片 / 去皮 / 焯水 等
  is_main               INTEGER NOT NULL DEFAULT 1,

  display_order         INTEGER
);

CREATE INDEX idx_recipe_ingredient_recipe ON recipe_ingredient(recipe_id);


-- 制作步骤
CREATE TABLE recipe_step (
  id                    INTEGER PRIMARY KEY AUTOINCREMENT,
  recipe_id             INTEGER NOT NULL REFERENCES recipe_variant(id) ON DELETE CASCADE,
  step_index            INTEGER NOT NULL,
  instruction           TEXT NOT NULL,
  image_url             TEXT,
  duration_seconds      INTEGER,
  tips                  TEXT
);

CREATE UNIQUE INDEX idx_recipe_step_unique ON recipe_step(recipe_id, step_index);


-- 营养信息（每份或每 100g）
CREATE TABLE nutrition_profile (
  id                    INTEGER PRIMARY KEY AUTOINCREMENT,
  target_type           TEXT NOT NULL,         -- 'dish' | 'recipe' | 'ingredient'
  target_id             INTEGER NOT NULL,

  calories              REAL,
  protein               REAL,
  fat                   REAL,
  carbs                 REAL,
  fiber                 REAL,
  sugar                 REAL,
  sodium                REAL,

  per                   TEXT NOT NULL DEFAULT 'serving',   -- 'serving' | '100g'
  data_source           TEXT,                               -- 'source_db' | 'estimated' | 'ai'

  created_at            INTEGER,
  updated_at            INTEGER,

  UNIQUE(target_type, target_id)
);

CREATE INDEX idx_nutrition_target ON nutrition_profile(target_type, target_id);


-- 标签词典
CREATE TABLE tag (
  id                    INTEGER PRIMARY KEY AUTOINCREMENT,
  category              TEXT NOT NULL,         -- 'cuisine' | 'taste' | 'method' | 'scene' | 'health' | 'texture' | 'occasion' | 'fortune' | 'howtocook_category' | ...
  key                   TEXT NOT NULL,         -- 规范化 key，如 'sichuan', 'spicy'
  name_cn               TEXT NOT NULL,
  name_en               TEXT,
  description           TEXT,
  icon_key              TEXT,                  -- 与 UI 气泡实体的 icon/动画对应

  created_at            INTEGER,
  updated_at            INTEGER,

  UNIQUE(category, key)
);

CREATE INDEX idx_tag_category ON tag(category);


-- 菜品-标签多对多映射
CREATE TABLE dish_tag (
  dish_id               INTEGER NOT NULL REFERENCES dish(id) ON DELETE CASCADE,
  tag_id                INTEGER NOT NULL REFERENCES tag(id) ON DELETE CASCADE,
  weight                REAL DEFAULT 1.0,      -- 某标签在该菜品上的权重（0~1）

  PRIMARY KEY (dish_id, tag_id)
);

CREATE INDEX idx_dish_tag_tag ON dish_tag(tag_id);


-- 搭配关系：饮品 / 配菜 / 主食等
CREATE TABLE pairing (
  id                    INTEGER PRIMARY KEY AUTOINCREMENT,
  dish_id               INTEGER NOT NULL REFERENCES dish(id) ON DELETE CASCADE,
  type                  TEXT NOT NULL,         -- 'drink' | 'side' | 'staple' | ...

  target_dish_id        INTEGER,               -- 如果搭配的是另一道内部菜品
  name                  TEXT,                  -- 自由名称（外部对象）
  description           TEXT,
  strength              REAL,                  -- 推荐强度 0~1
  source                TEXT,                  -- 'rule' | 'ai' | 'manual'

  created_at            INTEGER,
  updated_at            INTEGER
);

CREATE INDEX idx_pairing_dish ON pairing(dish_id);


-- 全文检索（名称 / 标签 / 食材关键字）
CREATE VIRTUAL TABLE dish_fts USING fts5(
  name_cn,
  name_en,
  tags,
  ingredients,
  content='',
  tokenize='unicode61'
);

-- dish / dish_tag / recipe_ingredient 更新时，可由导入脚本或触发器维护 dish_fts。
```

---

## 4. 与现有数据库的映射思路（高层）

具体导入脚本会在后续任务实现，这里先给高层映射规则：

### 4.1 HowToCook → 统一库

- 分类：
  - 原有分类（荤菜/素菜/早餐/主食/汤羹/甜品/饮品/调料等） → 映射到 `tag(category='howtocook_category')` 和/或 `scene` / `health` 标签。

- 菜谱：
  - 增强版数据库里的菜谱 ID → `recipe_variant.source_recipe_id`，`source='howtocook'`。
  - 名称 / 描述 / 难度 / 时间 / 份量 → 映射到 `dish` + `recipe_variant`。
  - 食材 / 步骤 → 填入 `recipe_ingredient` / `recipe_step`。

- 口味与营养：
  - 如果增强脚本已经对难度/时间做了推理，可直接填入对应字段。
  - 若无营养信息，可后续通过 AI 批量估算写入 `nutrition_profile`（`data_source='estimated'` / `ai`）。

---

## 5. 后续扩展与注意事项

1. **AI 生成菜谱**  
   - 新增 `source='ai'` 的 `recipe_variant`，并标记在 `dish` 或 `recipe_variant` 上的来源信息，便于前端区分真实菜谱与 AI 菜谱。

2. **趣味占卜与气泡元素映射**  
   - 所有「用户偏好元素（气泡）」都应指向 `tag` 或成组的 `tag`（例如「打工人回血菜」对应一组高油脂+重口味+高热量标签），方便在推荐与查询上复用。

3. **触发器 vs. 离线构建**  
   - `dish_fts` 更新可以使用 SQLite 触发器，也可以在导入脚本中手工维护。考虑到导入过程多为离线批处理，倾向于在导入脚本中维护，避免复杂触发器。

4. **与现有 `recipes.db` 的关系**  
   - 当前设计面向新的统一库 `unified_recipes.db`。  
   - 原有 `recipes.db` 可作为过渡期兼容层，待统一库稳定后迁移相关代码使用新结构。

5. **性能与容量**  
   - 目标规模：1 万级菜谱、数千级 Dish、万级 Ingredient；在移动端 SQLite 下完全可行。  
   - 必要时可增加更多索引（如 `idx_recipe_variant_difficulty` / `idx_dish_popularity` 等）。

---

> 下一步（任务 A2/A3）：在此 schema 基础上，编写导入脚本，从
> `xiachufang_complete_database.db` 和 `howtocook_complete_recipes.db` / `howtocook_enhanced_recipes.db`
> 生成 `unified_recipes.db` 的首版数据集。***
