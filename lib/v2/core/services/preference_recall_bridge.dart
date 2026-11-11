/// Bridges the product preference vocabulary to what the local recipe corpus
/// can actually recall. Pure Dart: no Flutter, database, or network access.
///
/// The product deck mixes food preferences with channel, location, meta and
/// fortune cards. Only the former may influence food recall.
class PreferenceRecallBridge {
  PreferenceRecallBridge._();

  static const Set<String> nonFoodLabels = {
    // Execution and location conditions are hard constraints, not dishes.
    '都可以',
    '在家做',
    '叫外卖',
    '去店里',
    '不限位置',
    '附近',
    // Playful cards must not degrade the candidate pool into a random default.
    '随便',
    '惊喜',
    '便宜',
    '财运',
    '事业运',
    '社交运',
    '奇遇运',
    '专注运',
  };

  static bool isFoodLabel(String label) {
    final trimmed = label.trim();
    return trimmed.isNotEmpty && !nonFoodLabels.contains(trimmed);
  }

  static List<String> hintsFor(String label) =>
      _recallHints[label.trim()] ?? const [];

  /// Expands food labels in their original order, dropping duplicates and
  /// non-food conditions. The original label always stays available last for
  /// exact-name scoring.
  static List<String> expand(Iterable<String> labels) {
    final expanded = <String>[];
    for (final raw in labels) {
      final label = raw.trim();
      if (!isFoodLabel(label)) continue;
      for (final hint in hintsFor(label)) {
        if (hint.isEmpty || hint == label) continue;
        if (!expanded.contains(hint)) expanded.add(hint);
      }
      if (!expanded.contains(label)) expanded.add(label);
    }
    return expanded;
  }

  static const Map<String, List<String>> _recallHints = {
    // --- Flavors ---
    '奶香': ['奶油', '牛奶', '芝士', '黄油', '炼乳'],
    '清淡': ['清爽', '蒸', '煮', '汤羹', '素菜'],
    '烟熏': ['烟熏', '熏', '烤'],
    '药膳': ['药膳', '枸杞', '当归', '红枣', '炖'],
    '咖喱': ['咖喱'],

    // --- Ingredients ---
    '羊肉': ['羊肉', '羊排', '羊腿', '羊蝎子'],
    '鹅肉': ['鹅肉', '烧鹅', '鹅'],
    '内脏': ['肝', '肚', '肠', '腰', '胗', '肺'],
    '海鲜': ['水产', '海鲜', '虾', '鱼', '蟹', '贝', '鱿鱼', '蚝'],
    '蟹': ['蟹', '螃蟹'],
    '贝类': ['贝类', '蛤蜊', '扇贝', '蚝', '牡蛎', '蛏'],

    // --- Staples ---
    '面包': ['面包', '吐司', '三明治'],
    '意面': ['意面', '意大利面', '肉酱面'],
    '披萨': ['披萨', '比萨'],
    '汉堡': ['汉堡', '汉堡包'],
    '粥': ['粥', '稀饭'],

    // --- Cuisines: concrete dish-name vocabulary the local corpus uses. ---
    '川菜': [
      '宫保',
      '麻婆',
      '回锅',
      '鱼香',
      '水煮牛肉',
      '水煮鱼',
      '水煮肉片',
      '辣子鸡',
      '小炒',
      '川味',
      '川菜'
    ],
    '粤菜': ['粤菜', '粤式', '煲仔', '白灼', '烧腊', '叉烧', '汤羹', '蒸', '炖', '清淡'],
    '湘菜': ['湘菜', '小炒', '剁椒', '腊味', '湘味'],
    '鲁菜': ['鲁菜', '葱烧', '九转', '糖醋', '红烧', '炖'],
    '苏菜': ['苏菜', '苏式', '红烧', '清炖', '糖醋', '蒸'],
    '浙菜': ['浙菜', '西湖', '东坡', '清蒸', '糟', '笋'],
    '闽菜': ['闽菜', '佛跳墙', '荔枝肉', '海蛎', '汤羹'],
    '徽菜': ['徽菜', '臭鳜鱼', '毛豆腐', '烧', '炖'],
    '东北菜': ['东北', '锅包肉', '地三鲜', '炖菜', '酸菜', '猪肉炖粉条'],
    '西北菜': ['西北', '羊肉', '拉面', '臊子', '馍', '烤'],
    '云南菜': ['云南', '米线', '汽锅', '菌菇', '傣味'],
    '京菜': ['北京', '炸酱面', '烤鸭', '涮', '卤煮'],
    '本帮菜': ['本帮', '上海', '红烧', '糖醋', '油爆', '糟'],
    '台湾菜': ['台湾', '三杯', '卤肉饭', '蚵仔', '盐酥'],
    '港式': ['港式', '煲仔', '茶餐厅', '烧腊', '菠萝油'],
    '日料': ['日式', '日料', '寿司', '刺身', '照烧', '味噌', '丼', '咖喱'],
    '韩餐': ['韩式', '韩国', '拌饭', '泡菜', '部队锅', '年糕'],
    '泰餐': ['泰式', '泰国', '咖喱', '冬阴功', '打抛', '椰'],
    '越南菜': ['越南', '河粉', '春卷', '鱼露'],
    '印度菜': ['印度', '咖喱', '飞饼', '香料'],
    '西餐': ['西式', '意式', '意大利面', '肉酱面', '披萨', '牛排', '奶油', '罗宋', '法式', '焗', '西餐'],
    '法餐': ['法式', '法餐', '奶油', '红酒', '焗', '鹅肝'],
    '墨西哥': ['墨西哥', '塔可', '卷饼', '玉米饼'],
    '火锅': ['火锅', '涮', '锅底', '麻辣', '牛油'],
    '烧烤': ['烧烤', '烤', '串', '孜然', '炭火'],
    '清真': ['清真', '牛肉', '羊肉', '大盘鸡'],

    // --- Scenes ---
    '早餐': ['早餐', '粥', '包子', '馒头', '豆浆', '牛奶', '燕麦', '吐司', '面包', '蒸蛋', '馄饨'],
    '午餐': ['午餐', '盖饭', '炒饭', '米饭', '面', '快餐'],
    '晚餐': ['晚餐', '家常菜', '热菜', '荤菜', '素菜', '汤羹'],
    '早午餐': ['早午餐', '早餐', '面包', '吐司', '鸡蛋', '牛奶', '沙拉'],
    '下午茶': ['下午茶', '甜品', '饮品', '蛋糕', '奶茶', '咖啡', '面包'],
    '聚餐': ['聚餐', '宴客', '荤菜', '火锅', '下饭', '大盘'],
    '一人食': ['一人食', '快手', '盖饭', '面', '汤羹', '米饭'],
    '约会': ['约会', '西餐', '牛排', '意面', '甜品'],
    '商务': ['商务', '清淡', '蒸', '鱼', '汤羹'],
    '健康': ['健康', '轻食', '清淡', '高蛋白', '蔬菜', '蒸', '煮'],
    '治愈': ['治愈', '汤羹', '粥', '热乎', '家常菜'],
    '路边摊': ['路边摊', '烧烤', '串', '炸', '卤', '小吃'],
    '自助': ['自助', '聚餐', '火锅', '烧烤'],

    // --- Dietary ---
    '素食': ['素菜', '蔬菜', '豆腐', '菌菇', '素食友好'],
    '低碳': ['高蛋白', '荤菜', '牛肉', '鸡肉', '鱼', '鸡蛋', '豆腐'],
  };
}
