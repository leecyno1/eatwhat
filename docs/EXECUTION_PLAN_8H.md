# 8 小时执行清单（首轮）

目标：打通“气泡滑动 → 偏好更新 → 候选生成 → 渠道跳转”的闭环，产出可测 Demo，并准备 iOS 提审所需要素。

## T0–T1（第 1–2 小时）：对齐与基线
- 开启分支：`feat/v2-preference-and-candidates`；
- 引入 Sentry Performance 采样（确保关键路径指标上报）；
- 补充 `Info.plist` 权限文案与 `LSApplicationQueriesSchemes`（仅本地）。

## T2–T4（第 3–4 小时）：偏好与候选
- 在 `RealtimeFeedbackService` → `UserPreferenceManager` 中实现正负反馈对权重的更新（指数平滑 + 边界裁剪）；
- 将 `BubbleController.handleBubbleGesture` 事件映射到 `AIPreferenceLearningEngine.recordUserBehavior`；
- 实现 `AIPreferenceLearningEngine` TODO：批学习、强化学习占位、上下文评分；
- `UnifiedFoodDataService`：召回 + 排序接入 AI 打分，保留 Vector 引擎为回退。

## T5–T6（第 5–6 小时）：UI 与交互
- 气泡页：加入撤销、进度、轻触权重调节；
- 候选页：卡片信息完善（口味标签、时长、价格、热量估算）。

## T7–T8（第 7–8 小时）：测试与打包
- 单测：偏好更新与打分函数、气泡手势到行为映射；
- 端到端冒烟：生成候选耗时 < 200ms；
- iOS 构建：`flutter build ios --no-codesign`，准备 TestFlight。

交付物：
- 可运行 Demo（首屏气泡 → 候选 → 菜谱/外链/附近）；
- 指标与日志；
- 提测包与变更文档。
