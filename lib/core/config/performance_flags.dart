/// 全局性能/特效开关集中管理
class PerformanceFlags {
  PerformanceFlags._();

  /// 是否启用动态气泡动画（环境漂浮 + 空闲脉冲）
  static bool enableDynamicBubbleAnimations = true;

  /// 运行时可在设置页或调试入口修改，必要时可加监听/通知机制
}
