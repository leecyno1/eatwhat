# Recommendation Engine V2

> 个性化 + 多样性 + 透明可解释 + 可配置权重 + 轻量缓存

## 1. 总体目标
在保证核心个性化精度的基础上：
- 提供可解释的打分分解（前端用于展示 Score Breakdown）
- 融合多种信号（历史、菜系、口味语义、气泡交互、质量、新颖度）
- 通过简化版 MMR(Maximal Marginal Relevance) 引入多样性，防止结果同质化
- 允许通过 `RecommendationConfig` 注入权重进行 A/B 调优
- 引入 LRU 近似缓存，避免同一会话频繁重复计算

## 2. 架构概览
核心文件：`lib/core/services/recommendation_engine.dart`

主要职责：
- 评分阶段：遍历所有食物，计算 `_ScoreBreakdown`（各组件 0~1 或 -1~1 规范化）
- 排序阶段：按总分降序排序
- 多样性阶段：可选执行 `_applyMMRDiversity` 进行去冗余
- 缓存阶段：按用户 + 权重配置 + 最近偏好更新时间 生成 key 存储结果

数据流：
```
UserPreference --> Scoring Components --> Sorted List --> (MMR) --> Top-K --> Cache --> UI Showcase
```

## 3. 评分组成 (Score Breakdown)
| 组件 | 权重默认值 | 说明 | 取值范围 | 设计要点 |
|------|-----------|------|----------|----------|
| history | 0.40 | 收藏 +1，不喜欢 -1.2 (惩罚放大) | [-1.2,1] | 强化用户显式反馈 |
| cuisine | 0.20 | 菜系偏好分值 /10 | [-1,1] | 支持正负偏好 |
| taste | 0.20 | 口味偏好加权 + 语义相似度 | ~[-1,1] | 语义相似度将近义味道吸入推荐 |
| bubble | 0.10 | 交互型偏好(气泡操作累积) | [-1,1] | 促进探索界面与推荐协同 |
| quality | 0.07 | 食物评分 /5 | [0,1] | 保持整体质量下限 |
| novelty | 0.03 | 未交互过的菜，偏好多样性鼓励 | [0,1] | 减少“信息茧房” |

公式（加权线性）：
$$Score = \sum_{c \in Components} w_c * value_c$$

语义相似度：基于一个小型手动近似映射（如 “辣” -> [微辣, 中辣, 麻辣...]），若完全匹配给 1.0，相似给 0.6，再归一化叠加。

## 4. 多样性 (MMR 简化)
对初步排好序的列表执行迭代选择：
```
score_MMR = (1-λ)*relevance - λ * max(sim(candidate, selected)) * relevance
```
- λ = 0.30（可放大以提高多样性）
- 相似度 sim：菜系相同 + 口味集合 Jaccard 合并（加权 0.4 + 0.6*jaccard）
- 复杂度：O(K*N)（K << N，数据集规模适中）

## 5. 缓存策略
Key 结构：
```
{userId}|{limit}|{w1,w2,w3,w4,w5,w6}|{diversityFlag}|{userPref.lastUpdatedEpoch}
```
策略：
- 命中即直接返回同一 List 引用（测试中对身份相等进行验证）
- 超过 `_maxCacheEntries` (50) 即删除最旧条目（LinkedHashMap FIFO 近似 LRU）

注意：如果未来需要防御外部修改，可改为返回 `UnmodifiableListView` 或深拷贝。

## 6. 可配置权重
通过 `RecommendationConfig` 注入：
```dart
final engine = RecommendationEngine();
final scored = engine.getPersonalizedScoredRecommendations(
  userPref,
  limit: 12,
  config: const RecommendationConfig(weightTaste: 0.3, weightNovelty: 0.05),
);
```
所有字段有默认值，未指定则使用默认常量。支持进行 A/B 或个性化实验。

## 7. 扩展点
| 扩展点 | 建议方式 | 说明 |
|--------|----------|------|
| 新增评分信号 | 添加字段到 `_ScoreBreakdown` + `RecommendationConfig` | 保持线性可解释性 |
| 改进多样性 | 替换 `_applyMMRDiversity` | 可引入基于聚类或 Gumbel Top-k |
| 多轮会话特征 | 在缓存 key 中加入 sessionId | 提升跨页一致性 |
| 语义相似度 | 接入向量检索 (embeddings) | 当前为静态近似映射 |
| 探索/利用 | 动态调整 `weightNovelty` | 根据用户反馈实时调参 |

## 8. 测试策略 (已覆盖)
- 分数排序正确性：高分在前
- 不喜欢惩罚：被标记不喜欢的菜品降序后排位靠后
- 缓存同一实例返回：缓存命中返回相同引用（identity）
- 多样性：结果菜系/口味集合更分散（启发式验证）
- 链接 Showcase UI：前端展示 `scoreBreakdown` 字段各组件

## 9. 性能与复杂度
- 单次全量评分：O(N * T) （T 为口味数量常数级）
- 多样性阶段：O(K*N)
- 典型数据量 (< 1k foods) 下帧间调用保持 <10ms（实际取决于设备）
- 缓存命中：O(1) 返回

## 10. 常见问题 (FAQ)
| 问题 | 解答 |
|------|------|
| 为什么 history 惩罚比奖励大？ | 惩罚放大帮助更快排除用户明确拒绝内容。 |
| 为什么 novelty 权重低？ | 控制探索带来的潜在劣质结果；可在冷启动阶段调高。 |
| 为什么返回 List 非拷贝？ | 为了在测试确认缓存是否复用；如有外部修改风险再改。 |
| 为什么不用协同过滤？ | 当前数据规模不足；后期可在 score 中加入 CF 子模型分量。 |

## 11. 前端展示建议
显示：综合分 + 动画化条形图 (history/cuisine/taste/bubble/quality/novelty)，并附上“多样性增强”提示徽章（当 diversity ON）。

## 12. 后续优化路线 (Roadmap)
1. 引入用户时间段偏好（早餐/夜宵）特征
2. 向量语义（味道/描述 embedding）替换手工映射
3. 评分正则化：不同来源信号区间对齐 + Z-score
4. 在线学习：根据即时选择提升对应分量权重
5. 召回/排序两阶段拆分（粗召回 + 精排序），便于扩展规模

---
若需新增信号或实验权重，请在提交前更新本文件保持文档同步。
