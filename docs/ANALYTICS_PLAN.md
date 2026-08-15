# 指标与埋点方案

## 关键指标（北极星与子指标）
- 北极星：决策时间（打开到做出选择）↓。
- 子指标：放弃率、候选点击率、菜谱转化、外卖跳转、附近餐馆导航、次日留存、满意度（轻量问卷）。

## 事件埋点
- `onboarding_complete`：配置/禁忌；
- `bubble_swipe`：维度（口味/心情/方法）、方向（like/dislike/skip）、权重；
- `generate_candidates`：耗时、候选多样性指标；
- `candidate_action`：recipe/takeout/nearby；
- `feedback_submit`：打分、标签；
- 错误与性能：Sentry Performance + breadcrumbs。

## 数据治理
- 匿名化与最小化；
- 采样与上报策略（弱网/后台）；
- 合规与用户可选择退出。
