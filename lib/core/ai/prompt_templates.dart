/// AI提示词模板类
/// 负责生成各种AI推荐场景的提示词
class PromptTemplates {
  PromptTemplates._();

  /// 基于气泡关键词的推荐提示词
  static String buildBubbleRecommendationPrompt({
    required List<String> selectedBubbles,
    required List<String> availableFoods,
    String? userPreferences,
    String? timeOfDay,
    String? weather,
  }) {
    final bubbleText = selectedBubbles.join('、');
    final foodList = availableFoods.take(20).join('、'); // 限制食物列表长度

    return '''
你是一个专业的美食推荐专家，请根据用户选择的气泡关键词为用户推荐最合适的食物。

用户选择的气泡关键词：$bubbleText

可选择的食物列表：$foodList

${userPreferences != null ? '用户偏好：$userPreferences' : ''}
${timeOfDay != null ? '用餐时间：$timeOfDay' : ''}
${weather != null ? '天气情况：$weather' : ''}

请按照以下格式返回推荐结果：

1. 推荐食物：[从列表中选择1-3个最匹配的食物]
2. 推荐理由：[详细解释为什么推荐这些食物，需要结合气泡关键词]
3. 匹配度评分：[给出1-10分的匹配度评分]
4. 额外建议：[如搭配建议、制作方法等]

要求：
- 推荐必须基于提供的食物列表
- 推荐理由要具体、个性化
- 考虑气泡关键词的语义含义
- 回答要简洁明了，不超过200字
''';
  }

  /// 用户偏好分析提示词
  static String buildPreferenceAnalysisPrompt({
    required List<String> favoriteHistory,
    required List<String> dislikedHistory,
    required Map<String, int> bubbleInteractions,
  }) {
    final favoritesText = favoriteHistory.isEmpty ? '无' : favoriteHistory.join('、');
    final dislikedText = dislikedHistory.isEmpty ? '无' : dislikedHistory.join('、');

    return '''
请分析用户的饮食偏好模式，帮助改善推荐系统。

用户收藏历史：$favoritesText
用户不喜欢的食物：$dislikedText
气泡交互数据：${bubbleInteractions.entries.map((e) => '${e.key}: ${e.value}次').join('、')}

请分析并返回：
1. 口味偏好特征：[如酸甜、清淡、重口味等]
2. 菜系偏好：[如川菜、粤菜、日料等]
3. 食材偏好：[如蔬菜、肉类、海鲜等]
4. 避免类型：[用户可能不喜欢的食物类型]
5. 推荐权重建议：[为不同类别设置权重建议]

回答要简洁，每项不超过30字。
''';
  }

  /// 智能菜单解释提示词
  static String buildMenuExplanationPrompt({
    required String foodName,
    required List<String> matchedBubbles,
    required double score,
  }) {
    final bubblesText = matchedBubbles.join('、');

    return '''
请为推荐的食物生成一个吸引人的推荐解释。

推荐食物：$foodName
匹配的气泡关键词：$bubblesText
系统评分：${score.toStringAsFixed(1)}分

请生成一个30-50字的推荐理由，要求：
- 突出食物的特色和优点
- 结合气泡关键词的匹配点
- 语言生动有趣，能激发食欲
- 适合中国用户的表达习惯

直接返回推荐理由文本，无需其他格式。
''';
  }

  /// 情境化推荐提示词
  static String buildContextualRecommendationPrompt({
    required String context, // 如"加班夜宵"、"周末聚餐"、"健身后补充"
    required List<String> availableFoods,
    required String timeOfDay,
    String? weather,
    String? mood,
  }) {
    final foodList = availableFoods.take(15).join('、');

    return '''
用户场景：$context
当前时间：$timeOfDay
${weather != null ? '天气：$weather' : ''}
${mood != null ? '心情：$mood' : ''}

可选食物：$foodList

请根据具体场景推荐最合适的食物：

1. 推荐食物：[1-2个最适合的食物]
2. 场景匹配理由：[为什么这些食物适合当前场景]
3. 实用建议：[如份量、搭配、注意事项]

要求简洁实用，总计不超过150字。
''';
  }

  /// 创新搭配建议提示词
  static String buildPairingRecommendationPrompt({
    required String mainFood,
    required List<String> availableSides,
  }) {
    final sidesText = availableSides.join('、');

    return '''
主食：$mainFood
可搭配选项：$sidesText

请推荐2-3个最佳搭配组合：

1. 经典搭配：[传统经典的搭配方式]
2. 创新搭配：[有创意的新颖搭配]
3. 健康搭配：[营养均衡的搭配]

每个搭配请简要说明理由，总计不超过120字。
''';
  }

  /// 处理AI响应的通用方法
  static Map<String, dynamic> parseRecommendationResponse(String response) {
    // 简单的响应解析，可根据实际AI返回格式调整

    return {
      'fullResponse': response,
      'recommendations': _extractRecommendations(response),
      'reasons': _extractReasons(response),
      'score': _extractScore(response),
      'suggestions': _extractSuggestions(response),
    };
  }

  static List<String> _extractRecommendations(String response) {
    final regex = RegExp(r'推荐食物[：:]\s*(.+?)(?=\n|$)', multiLine: true);
    final match = regex.firstMatch(response);
    if (match != null) {
      return match.group(1)?.split('、').map((e) => e.trim()).toList() ?? [];
    }
    return [];
  }

  static String _extractReasons(String response) {
    final regex = RegExp(r'推荐理由[：:]\s*(.+?)(?=\n\d+\.|$)', multiLine: true, dotAll: true);
    final match = regex.firstMatch(response);
    return match?.group(1)?.trim() ?? '';
  }

  static double _extractScore(String response) {
    final regex = RegExp(r'匹配度评分[：:]\s*(\d+(?:\.\d+)?)', multiLine: true);
    final match = regex.firstMatch(response);
    if (match != null) {
      return double.tryParse(match.group(1) ?? '0') ?? 0.0;
    }
    return 0.0;
  }

  static String _extractSuggestions(String response) {
    final regex = RegExp(r'额外建议[：:]\s*(.+?)(?=\n|$)', multiLine: true);
    final match = regex.firstMatch(response);
    return match?.group(1)?.trim() ?? '';
  }
}
