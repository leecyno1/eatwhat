# 自动主题（昼夜偏好记忆）设计

日期：2026-11-11 · 状态：已确认开工

## 目标

让 9 套主题 + 2 个基础底色能按「用户选择习惯 + 系统白天黑夜」自动切换，
手动选择永远优先并被记忆为对应时段的偏好。

## 机制

- 新增独立开关 `autoEnabled`（不污染 `AppThemeMode` 皮肤枚举）。
- 昼夜信号：`PlatformDispatcher.platformBrightness` +
  `onPlatformBrightnessChanged`，在 `main.dart` 接线到
  `AppThemeController.applyBrightness`。
- 解析规则：auto 开启时，系统白天 → `dayPreference`，系统夜晚 →
  `nightPreference`；`mode` 始终保存解析后的皮肤，下游（AppPalette /
  FluidTheme / AppV2 themeMode）零改动。
- 习惯记忆：auto 开启时手动 `setMode(x)` 把 x 记入当前时段槽位并立即生效；
  `setAuto(true)` 时把当前手动主题记入当前时段槽位。
- 关闭 auto：保留当前解析皮肤为手动模式，完全回到旧行为。

## 默认值与兼容

- 持久化键：`v2_theme_auto`(bool)、`v2_theme_day`(name)、`v2_theme_night`(name)，
  沿用 `v2_app_theme_mode` 记录当前皮肤。
- 新用户（无任何存储）：auto 默认开启，白天米白 / 夜晚墨夜。
- 老用户（已存手动主题、无 auto 键）：保持手动，不强制改变。

## 面板

外观面板顶部新增整行「自动 · 跟随昼夜」卡片：副标题动态显示
「白天 X · 夜晚 Y」与当前时段；点按切换 auto。下方 2 基础卡 + 9 美学卡
保持原样；auto 开启时点选即「设置当前时段偏好」，并显示一行提示。

## 测试

- 单元：昼夜解析、槽位记忆、开关往返、持久化往返、新老用户默认值。
- Widget：面板自动卡片渲染与切换。
- 全量回归 + 模拟器 `simctl ui appearance` 昼夜验收。