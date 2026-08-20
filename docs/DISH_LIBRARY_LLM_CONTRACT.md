# 菜品库 × LLM 生成匹配契约

> 版本：v1.1（2026-08-20）
> 变更：v1.1 新增标签体系盘点、LLM 菜品卡协议、dishId/dishName 双钥匙输出 schema
> 范围：unified_recipes.db 菜品库、预制图库、MiniMax 文本生成三方的对接规则

## 1. 设计原则

**LLM 是点菜员，不是厨师。** 所有菜品、图片、食材数据以本地菜品库为唯一事实源
（Single Source of Truth）；LLM 只负责在库内内容之间做选择、排序与解释，
任何库外内容不得进入生成结果。

三层角色分工：

| 层 | 职责 | 不允许 |
|---|---|---|
| 菜品库（SQLite + manifest） | 事实：菜名、菜系、食材、标签、图片 | — |
| 本地算法（hybrid_v3_0） | 召回 + 初排，划定 LLM 的候选池 | — |
| LLM（MiniMax-M2.7） | 库内选择、组合逻辑解释 | 编造菜品 / 编造 dishId / 库外知识补充 |

## 2. 硬约束（代码强制，违反即丢弃）

1. **dishId 白名单**：LLM 输出的 `dishId` 必须在候选列表中；
   编造 ID、重复 ID、库外 ID 一律过滤（`_validateRefinement`）。
2. **数量收敛**：不足 `limit` 个合法 ID 时，用本地排序候选补齐，结果永不超发。
3. **失败降级**：LLM 超时（2s）/异常/空返回 → 本地排序结果 + 显式降级标注
   （`local_fallback`，摘要明说"智能增强暂时不可用"），绝不静默冒充。
4. **未配置显性化**：无 key 时摘要明示"AI 点菜师未启用"。

## 3. 内容锚定（prompt 契约）

候选以结构化行喂给 LLM（每行一个菜品卡）：

```
- dishId=123｜菜名=X｜标签=a、b｜食材=c、d
```

标签与食材由【LLM 菜品卡查询】统一供给（见 §3.1），是 prompt 唯一的信息源。

- **reason 必须锚定字段**：一句话 ≤20 字，必须点名具体口味 / 食材 / 场景，
  禁止"很美味""适合您"类空话（system prompt 明令）。
- **summary 必须解释组合**：一句话 ≤40 字，从口味层次、荤素主食结构、
  场景契合三个维度解释这一组为什么成立。
- **JSON 严格输出**：解析失败自动重试（去掉 response_format 的兼容重试已内置）。

### 3.1 LLM 菜品卡（唯一数据供给协议）

每道菜的 LLM 可见信息由一条标准查询拼装，禁止从别处取数：

```sql
SELECT d.id, d.name_cn,
       GROUP_CONCAT(t.name_cn)        -- dish_tag ⋈ tag
FROM dish d LEFT JOIN dish_tag dt ON dt.dish_id = d.id
            LEFT JOIN tag t       ON t.id = dt.tag_id
GROUP BY d.id;
```

现行实现中该卡片已通过 `RecipeModel.fromUnifiedDbRow` 的
`tags`（含 taste/scene/method/texture/ingredient 多类标签）与
`ingredients` 进入 prompt 候选行。

### 3.2 输出 schema v2（双钥匙 → 菜品图）

```json
{
  "recommendations": [
    {"dishId": "193", "dishName": "麻婆豆腐",
     "reason": "麻辣下饭，豆腐嫩滑", "confidence": 0.9}
  ],
  "summary": "麻辣为主搭配清炒时蔬，一荤一素正合适"
}
```

- **dishId 是图片的钥匙**：app 拿 dishId（+菜名校验）查 dish_image_manifest
  → heroUrl 直接出图。全图库覆盖后，任何推荐结果都必然带图。
- **dishName 是第二把钥匙**：解析侧做交叉校验——模型回显的 dishName 必须与
  dishId 指向的候选菜名一致（归一化后相等或互合），不一致时仅在名字唯一
  匹配另一候选时纠偏，否则丢弃该条。幻觉 ID 无法带出错图。
- **confidence** 为模型自估置信度，当前仅透传，不作硬校验。

## 4. 标签体系盘点（v1.1 实测）

菜品的标签存于 `dish_tag ⋈ tag`，340 道菜全覆盖，每菜 4–21 个标签，
共 14 类：

| 类别 | 数量 | 示例 |
|---|---|---|
| ingredient | 609 | 大蒜、内脂豆腐、青蟹 |
| dish（菜型） | 15 | 猪肉菜、豆腐菜、米饭类 |
| taste（口味） | 15 | 麻辣、蒜香、咸 |
| method（做法） | 12 | 蒸、炖、炒 |
| cuisine（菜系） | 10 | 川菜、粤菜 |
| scene（场景） | 10 | 下饭 |
| texture（口感） | 6 | 软嫩 |
| diet/health/staple/execution… | 若干 | 高蛋白、主食、可做可点 |

该体系与首页偏好实体（94 个 taste entity）同源，用户选"辣"→
召回带"辣"标签的菜天然打通（hybrid_v3_0 即此机制）。

数据质量：ingredient 标签与实际食材逐一对账，除"蔬菜"这类
泛化大类标签外零脏数据，无需清洗。

## 5. 图库契约（全预制策略）

1. **零在线依赖**：所有菜品图预置在 `assets/images/prebuilt_dishes/`，
   运行时不调用生图 API（在线生图仅作为未来兜底能力保留在代码里）。
2. **图源优先级**：HowToCook 真实照片 > AI 生成图（风格统一批次）。
3. **manifest 是图库的索引**：
   - `dishId` 与当前 DB 对齐（重映射脚本：`remap_dish_manifest_ids.py`）
   - 新图入库：`build_missing_dish_images.py plan → 生成 → sync`
   - HowToCook 白嫖：`build_missing_dish_images.py salvage`
4. **命名规范**：`dish-<dbId>-<style>_<size>.<ext>`，
   style ∈ {howtocook-real2, ai-v2}，size ∈ {1280, 768}。
5. **schema 字段**：新条目携带 `ingredients`/`cuisine`，
   为未来"按食材搜图 / 按菜系换风格"留扩展点。

## 6. 补库管线（当前进行中）

| 状态 | 数量 | 说明 |
|---|---|---|
| ✅ 已覆盖 | 227/340 | 真图 167 + AI 三批 50 + 其他 10 |
| ⏳ 待生成 | 113 | 按 plan 逐批生成，每批交人工审核后入库 |

图库卫生：160 个未被 manifest 引用的历史游离文件已清除（减重 39MB），
目录内每个文件都被 manifest 条目引用。

审核规则：图与菜名不符 / 明显畸变 / 食欲感差 → 重新生成该张；
通过则保留并进入下一批。

## 7. 未来扩展点

- **稀有实体联动**：稀有菜（金光实体）在 prompt 里加"组合里解释为什么藏了这道菜"
- **图鉴文案**：LLM 为图鉴生成菜品介绍时，同样只允许引用库内字段
- **口味档案反馈**：LLM 的选择结果回写 tag scores，形成库 ↔ LLM 闭环
