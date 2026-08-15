class TasteEntityConcept {
  const TasteEntityConcept({
    required this.name,
    required this.glyph,
  });

  final String name;
  final String glyph;
}

class TasteEntityVisualCatalog {
  const TasteEntityVisualCatalog._();

  static const Map<String, TasteEntityConcept> _concepts = {
    '辣': TasteEntityConcept(name: '辣椒', glyph: '🌶️'),
    '甜': TasteEntityConcept(name: '蜂蜜', glyph: '🍯'),
    '酸': TasteEntityConcept(name: '柠檬', glyph: '🍋'),
    '咸': TasteEntityConcept(name: '海盐', glyph: '🧂'),
    '鲜': TasteEntityConcept(name: '鲜鱼', glyph: '🐟'),
    '麻': TasteEntityConcept(name: '花椒', glyph: '🫛'),
    '蒜香': TasteEntityConcept(name: '大蒜', glyph: '🧄'),
    '苦': TasteEntityConcept(name: '咖啡', glyph: '☕'),
    '奶香': TasteEntityConcept(name: '牛奶', glyph: '🥛'),
    '酥脆': TasteEntityConcept(name: '脆饼', glyph: '🍪'),
    '清淡': TasteEntityConcept(name: '青菜', glyph: '🥬'),
    '浓郁': TasteEntityConcept(name: '浓汤', glyph: '🍲'),
    '烟熏': TasteEntityConcept(name: '烟熏肉', glyph: '🥓'),
    '药膳': TasteEntityConcept(name: '香草', glyph: '🌿'),
    '咖喱': TasteEntityConcept(name: '咖喱饭', glyph: '🍛'),
    '牛肉': TasteEntityConcept(name: '牛排', glyph: '🥩'),
    '猪肉': TasteEntityConcept(name: '猪肉', glyph: '🥓'),
    '鸡肉': TasteEntityConcept(name: '鸡腿', glyph: '🍗'),
    '羊肉': TasteEntityConcept(name: '羊排', glyph: '🥩'),
    '鸭肉': TasteEntityConcept(name: '烤鸭', glyph: '🦆'),
    '鹅肉': TasteEntityConcept(name: '鹅肉', glyph: '🪿'),
    '内脏': TasteEntityConcept(name: '内脏', glyph: '🫀'),
    '海鲜': TasteEntityConcept(name: '海鲜', glyph: '🦞'),
    '鱼': TasteEntityConcept(name: '鱼', glyph: '🐟'),
    '虾': TasteEntityConcept(name: '虾', glyph: '🦐'),
    '蟹': TasteEntityConcept(name: '螃蟹', glyph: '🦀'),
    '贝类': TasteEntityConcept(name: '贝类', glyph: '🦪'),
    '蔬菜': TasteEntityConcept(name: '西兰花', glyph: '🥦'),
    '菌菇': TasteEntityConcept(name: '蘑菇', glyph: '🍄'),
    '豆腐': TasteEntityConcept(name: '豆腐', glyph: '⬜'),
    '土豆': TasteEntityConcept(name: '土豆', glyph: '🥔'),
    '番茄': TasteEntityConcept(name: '番茄', glyph: '🍅'),
    '茄子': TasteEntityConcept(name: '茄子', glyph: '🍆'),
    '玉米': TasteEntityConcept(name: '玉米', glyph: '🌽'),
    '鸡蛋': TasteEntityConcept(name: '鸡蛋', glyph: '🍳'),
    '芝士': TasteEntityConcept(name: '芝士', glyph: '🧀'),
    '米饭': TasteEntityConcept(name: '米饭', glyph: '🍚'),
    '面条': TasteEntityConcept(name: '面条', glyph: '🍜'),
    '面包': TasteEntityConcept(name: '面包', glyph: '🍞'),
    '饺子': TasteEntityConcept(name: '饺子', glyph: '🥟'),
    '意面': TasteEntityConcept(name: '意面', glyph: '🍝'),
    '披萨': TasteEntityConcept(name: '披萨', glyph: '🍕'),
    '汉堡': TasteEntityConcept(name: '汉堡', glyph: '🍔'),
    '粥': TasteEntityConcept(name: '粥', glyph: '🥣'),
    '川菜': TasteEntityConcept(name: '川味辣椒', glyph: '🌶️'),
    '粤菜': TasteEntityConcept(name: '广式点心', glyph: '🥟'),
    '湘菜': TasteEntityConcept(name: '湘味辣椒', glyph: '🌶️'),
    '鲁菜': TasteEntityConcept(name: '鲁菜鲜鱼', glyph: '🐟'),
    '苏菜': TasteEntityConcept(name: '苏式河鲜', glyph: '🐠'),
    '浙菜': TasteEntityConcept(name: '浙味鲜虾', glyph: '🦐'),
    '闽菜': TasteEntityConcept(name: '闽味汤羹', glyph: '🍲'),
    '徽菜': TasteEntityConcept(name: '徽州菌菇', glyph: '🍄'),
    '东北菜': TasteEntityConcept(name: '东北饺子', glyph: '🥟'),
    '西北菜': TasteEntityConcept(name: '西北面食', glyph: '🍜'),
    '云南菜': TasteEntityConcept(name: '云南菌菇', glyph: '🍄'),
    '京菜': TasteEntityConcept(name: '北京烤鸭', glyph: '🦆'),
    '本帮菜': TasteEntityConcept(name: '本帮红烧肉', glyph: '🍖'),
    '台湾菜': TasteEntityConcept(name: '台湾卤肉饭', glyph: '🍛'),
    '港式': TasteEntityConcept(name: '港式点心', glyph: '🥮'),
    '日料': TasteEntityConcept(name: '寿司', glyph: '🍣'),
    '韩餐': TasteEntityConcept(name: '韩式拌饭', glyph: '🍚'),
    '泰餐': TasteEntityConcept(name: '冬阴功', glyph: '🍲'),
    '越南菜': TasteEntityConcept(name: '越南粉', glyph: '🍜'),
    '印度菜': TasteEntityConcept(name: '印度咖喱', glyph: '🍛'),
    '东南亚': TasteEntityConcept(name: '椰子', glyph: '🥥'),
    '西餐': TasteEntityConcept(name: '西式牛排', glyph: '🥩'),
    '法餐': TasteEntityConcept(name: '法式可颂', glyph: '🥐'),
    '意餐': TasteEntityConcept(name: '意式披萨', glyph: '🍕'),
    '美式': TasteEntityConcept(name: '美式汉堡', glyph: '🍔'),
    '墨西哥': TasteEntityConcept(name: '墨西哥卷', glyph: '🌮'),
    '火锅': TasteEntityConcept(name: '火锅', glyph: '🍲'),
    '烧烤': TasteEntityConcept(name: '烤串', glyph: '🍢'),
    '清真': TasteEntityConcept(name: '清真烤肉', glyph: '🍢'),
    '早餐': TasteEntityConcept(name: '早餐吐司', glyph: '🍞'),
    '午餐': TasteEntityConcept(name: '午餐饭碗', glyph: '🍱'),
    '晚餐': TasteEntityConcept(name: '晚餐主菜', glyph: '🍽️'),
    '夜宵': TasteEntityConcept(name: '夜宵烤串', glyph: '🍢'),
    '早午餐': TasteEntityConcept(name: '早午餐', glyph: '🥞'),
    '下午茶': TasteEntityConcept(name: '下午茶', glyph: '🍰'),
    '聚餐': TasteEntityConcept(name: '聚餐碰杯', glyph: '🥂'),
    '一人食': TasteEntityConcept(name: '一人食面碗', glyph: '🍜'),
    '约会': TasteEntityConcept(name: '约会甜点', glyph: '🍓'),
    '商务': TasteEntityConcept(name: '商务咖啡', glyph: '☕'),
    '健康': TasteEntityConcept(name: '健康沙拉', glyph: '🥗'),
    '治愈': TasteEntityConcept(name: '治愈热汤', glyph: '🍲'),
    '路边摊': TasteEntityConcept(name: '路边摊烤串', glyph: '🍢'),
    '自助': TasteEntityConcept(name: '自助餐盘', glyph: '🍽️'),
    '素食': TasteEntityConcept(name: '绿叶菜', glyph: '🥬'),
    '轻食': TasteEntityConcept(name: '轻食沙拉', glyph: '🥗'),
    '低碳': TasteEntityConcept(name: '牛油果', glyph: '🥑'),
    '高蛋白': TasteEntityConcept(name: '鸡蛋', glyph: '🥚'),
    '随便': TasteEntityConcept(name: '骰子', glyph: '🎲'),
    '惊喜': TasteEntityConcept(name: '惊喜盒', glyph: '🎁'),
    '便宜': TasteEntityConcept(name: '硬币', glyph: '🪙'),
    '恋爱运': TasteEntityConcept(name: '爱心', glyph: '💗'),
    '财运': TasteEntityConcept(name: '金币', glyph: '🪙'),
    '事业运': TasteEntityConcept(name: '公文包', glyph: '💼'),
    '健康运': TasteEntityConcept(name: '青苹果', glyph: '🍏'),
    '社交运': TasteEntityConcept(name: '碰杯', glyph: '🥂'),
    '奇遇运': TasteEntityConcept(name: '指南针', glyph: '🧭'),
    '专注运': TasteEntityConcept(name: '靶心', glyph: '🎯'),
    '平静运': TasteEntityConcept(name: '莲花', glyph: '🪷'),
  };

  static bool hasExplicitMapping(String label) => _concepts.containsKey(label);

  static TasteEntityConcept conceptFor(String label) {
    final exact = _concepts[label];
    if (exact != null) return exact;

    if (label.contains('辣')) {
      return const TasteEntityConcept(name: '辣椒', glyph: '🌶️');
    }
    if (label.contains('蛋')) {
      return const TasteEntityConcept(name: '鸡蛋', glyph: '🥚');
    }
    if (label.contains('菜') || label.contains('素')) {
      return const TasteEntityConcept(name: '蔬菜', glyph: '🥬');
    }
    if (label.contains('鱼') || label.contains('水产')) {
      return const TasteEntityConcept(name: '鲜鱼', glyph: '🐟');
    }
    if (label.contains('肉') || label.contains('荤')) {
      return const TasteEntityConcept(name: '肉类', glyph: '🥩');
    }
    if (label.contains('汤') || label.contains('羹')) {
      return const TasteEntityConcept(name: '热汤', glyph: '🍲');
    }
    if (label.contains('甜')) {
      return const TasteEntityConcept(name: '甜点', glyph: '🍰');
    }
    if (label.contains('饭') || label.contains('主食')) {
      return const TasteEntityConcept(name: '饭碗', glyph: '🍚');
    }
    if (label.contains('面')) {
      return const TasteEntityConcept(name: '面条', glyph: '🍜');
    }
    if (label.contains('饮')) {
      return const TasteEntityConcept(name: '饮品', glyph: '🥤');
    }
    return const TasteEntityConcept(name: '餐食', glyph: '🍽️');
  }
}
