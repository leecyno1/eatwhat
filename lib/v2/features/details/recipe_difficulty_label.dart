/// 把菜谱难度归一成中文展示文案。
///
/// 本地 HowToCook 数据给的是 1-5 档数字，AI 结果给的是 easy/medium/hard
/// 这类英文枚举，详情页直接渲染会出现「3」「medium」这类看不懂的 chip，
/// 统一在这里转成中文；无法识别的原始值保持原样，避免吞掉信息。
String recipeDifficultyLabel(String raw) {
  final value = raw.trim().toLowerCase();
  if (value.isEmpty) {
    return '难度未知';
  }

  const numericLabels = {
    '1': '很简单',
    '2': '简单',
    '3': '中等',
    '4': '较难',
    '5': '困难',
  };
  final numeric = numericLabels[value];
  if (numeric != null) {
    return numeric;
  }

  const textLabels = {
    'easy': '简单',
    'simple': '简单',
    'medium': '中等',
    'normal': '中等',
    'hard': '较难',
    'difficult': '较难',
    'expert': '困难',
  };
  return textLabels[value] ?? value;
}
