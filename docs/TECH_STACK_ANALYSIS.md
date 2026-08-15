# 吃什么项目技术栈分析

## 结论

这是一个以 Flutter 为核心的多平台点餐与口味偏好应用。当前生产入口是 `lib/main.dart` -> `ProviderScope` -> `AppV2`，主流程已经集中到 V2：口味选择、推荐结果、菜谱详情、烹饪库、收藏和外卖执行。旧版气泡交互仍保留在代码库中，但不应直接替换当前入口。

## 技术栈

- **客户端框架**：Flutter，Dart SDK `>=3.4.4 <4.0.0`；目标覆盖 Android、iOS、Web、macOS、Windows、Linux。
- **界面与主题**：Material 3、`ThemeData`、`flutter_screenutil` 响应式适配；动画使用 `flutter_animate`、Lottie、Rive；图片使用 `cached_network_image` 和 `flutter_svg`。
- **导航**：`go_router`，路由集中在 `lib/v2/core/navigation/app_v2_router.dart`。
- **状态管理**：V2 主流程使用 Riverpod（`ProviderScope`）；旧功能仍有 Provider/ChangeNotifier，属于并存状态。
- **本地数据**：Hive 用于轻量状态和缓存，SQLite/sqflite 用于菜谱数据库，SharedPreferences 用于配置，FlutterSecureStorage 用于敏感凭据。
- **网络与同步**：Dio、缓存拦截器、智能重试和 `http`；平台执行通过统一代理适配美团、饿了么、大众点评和京东等渠道。
- **推荐与 AI**：口味选择模型 -> 推荐服务 -> AI 摘要/理由；数学计算使用 `vector_math`、`ml_linalg`。AI 服务由环境配置选择 SiliconFlow/Qwen、MiniMax 等后端。
- **工程化**：Freezed、json_serializable、Hive Generator、injectable/get_it；测试使用 `flutter_test`、Mockito、sqflite ffi 和 integration_test。
- **可观测性**：Sentry、AnalyticsHelper、性能监控与推荐漏斗/影子评估相关服务。

## 代码分层

```text
lib/main.dart
  └─ lib/v2/app_v2.dart
       ├─ v2/core/theme          设计令牌与主题
       ├─ v2/core/navigation     GoRouter 路由
       ├─ v2/core/data           菜谱、口味与推荐模型
       ├─ v2/core/services       推荐、执行、烹饪库服务
       └─ v2/features             home / decision / result / details / execution
lib/core                         认证、配置、基础服务和旧模块
assets/data                      菜谱数据库
assets/images                    菜品与界面资源
test                              单元、组件和集成测试
```

## UI 恢复策略

当前黑白感主要来自 V2 主题令牌、按钮/标签的中性色映射和首页背景。已恢复：

- 暖色背景与玻璃表面：`broth`、`cream`、半透明卡片和柔和阴影；
- 早期彩色强调色：辣椒橙、蛋黄、香草绿、葡萄紫、海蓝；
- 首页动态暖色背景；
- 首页“生成推荐”、口味签名、结果模式标签和外卖执行页的彩色主操作。

业务流程未被替换：仍使用 V2 的推荐、详情和执行路由。设计方案确认后，再把选定的位图方向转成 Flutter 组件和令牌，避免先做不可复用的静态页面。

## 当前限制

本会话没有暴露内置 `image_gen` 工具。根据 imagegen 规范，不能用代码截图、HTML/SVG 或旧缓存冒充真实位图；备用 CLI/API 需要用户明确授权和本机 `OPENAI_API_KEY`。因此 10 套真实设计图尚未生成。
