import 'package:eatwhat_app/v2/core/data/models/taste_selection_models.dart';

String tasteCardCategoryLabel(String category) {
  switch (category) {
    case 'flavor':
      return '口味';
    case 'ingredient':
      return '食材';
    case 'scene':
      return '场景';
    case 'cuisine':
      return '菜系';
    case 'staple':
      return '主食';
    case 'fortune':
      return '运势';
    case 'dietary':
      return '饮食';
    case 'meta':
      return '趣味';
    default:
      return '标签';
  }
}

String tasteCardDescriptor(TasteDeckCard card) {
  switch (card.category) {
    case 'flavor':
      return '锁定味型';
    case 'ingredient':
      return '聚焦食材';
    case 'scene':
      return '设定场景';
    case 'cuisine':
      return '切换菜系';
    case 'staple':
      return '补足主食';
    case 'fortune':
      return '加一点玄学';
    case 'dietary':
      return '调校结构';
    case 'meta':
      return '交给一点随机';
    default:
      return '加入今天的口味签名';
  }
}

String tasteCardRarityFor(TasteDeckCard card) {
  switch (card.category) {
    case 'fortune':
      return '史诗';
    case 'flavor':
    case 'ingredient':
      return '稀有';
    case 'scene':
    case 'cuisine':
      return '精良';
    default:
      return '普通';
  }
}

List<String> tasteCardAffixesFor(TasteDeckCard card) {
  switch (card.category) {
    case 'flavor':
      return ['浓烈', '味型', _compactAffix(card.label)];
    case 'ingredient':
      return ['主角', '饱足', _compactAffix(card.label)];
    case 'scene':
      return ['事件', '氛围', _compactAffix(card.label)];
    case 'cuisine':
      return ['流派', '地域', _compactAffix(card.label)];
    case 'staple':
      return ['底盘', '耐饿', _compactAffix(card.label)];
    case 'fortune':
      return ['奇遇', '加成', _compactAffix(card.label)];
    case 'dietary':
      return ['约束', '低负担', _compactAffix(card.label)];
    case 'meta':
      return ['变体', '随机', _compactAffix(card.label)];
    default:
      return ['构筑', _compactAffix(card.label)];
  }
}

String tasteCardEffectFor(TasteDeckCard card) {
  switch (card.category) {
    case 'flavor':
      return '加入构筑：提高 ${card.label} 味型权重，候选更有记忆点。';
    case 'ingredient':
      return '加入构筑：让 ${card.label} 更像主角，减少泛泛推荐。';
    case 'scene':
      return '加入构筑：把今天切到 ${card.label} 场景，推荐更会看气氛。';
    case 'cuisine':
      return '加入构筑：锁定 ${card.label} 流派，缩小摇摆范围。';
    case 'staple':
      return '加入构筑：用 ${card.label} 兜底饱足感，避免只给小菜。';
    case 'fortune':
      return '特殊事件：给本局叠一层 ${card.label} 趣味滤镜。';
    case 'dietary':
      return '加入构筑：按 ${card.label} 调低负担，筛掉冲突选择。';
    case 'meta':
      return '随机事件：保留一点 ${card.label}，让结果别太死板。';
    default:
      return '加入构筑：把 ${card.label} 写进今天的口味签名。';
  }
}

String tasteCardBackTitle(TasteDeckCard card) {
  if (card.backTitle?.trim().isNotEmpty ?? false) {
    return card.backTitle!.trim();
  }

  switch (card.category) {
    case 'flavor':
      return '辣度轮廓';
    case 'ingredient':
      return '食材角色';
    case 'scene':
      return '场景脚本';
    case 'cuisine':
      return '菜系方向';
    case 'fortune':
      return '趣味线索';
    default:
      return '偏好注释';
  }
}

List<String> tasteCardBackExamples(TasteDeckCard card) {
  if (card.examples.isNotEmpty) {
    return card.examples;
  }

  switch (card.category) {
    case 'flavor':
      return [card.label, '更热', '更醒'];
    case 'ingredient':
      return [card.label, '主角感', '好搭配'];
    case 'scene':
      return [card.label, '节奏稳', '氛围到'];
    case 'cuisine':
      return [card.label, '地域感', '风格强'];
    case 'fortune':
      return [card.label, '娱乐向', '轻玄学'];
    default:
      return [card.label, '今日签名'];
  }
}

String tasteCardDefaultBlurb(TasteDeckCard card) {
  switch (card.category) {
    case 'flavor':
      return '把 ${card.label} 放进今天的味型骨架，让模型更快收束候选菜。';
    case 'ingredient':
      return '围绕 ${card.label} 排布主角食材，减少推荐和实际口味脱节。';
    case 'scene':
      return '先定义 ${card.label} 的用餐氛围，再生成更对场的菜品方向。';
    case 'cuisine':
      return '用 ${card.label} 锁定地区风格，避免推荐跨度过大。';
    case 'fortune':
      return '给今天叠一点 ${card.label} 的趣味滤镜，保持轻松随机感。';
    default:
      return '把 ${card.label} 写进今天的口味签名。';
  }
}

String tasteCardMicroCode(String id) {
  final compact = id.replaceAll('_', '').toUpperCase();
  return compact.length <= 4 ? compact : compact.substring(0, 4);
}

String tasteCardArtCode(String artKey) {
  final compact = artKey
      .split('-')
      .where((segment) => segment.trim().isNotEmpty)
      .map((segment) => segment.trim().substring(0, 1).toUpperCase())
      .join();
  if (compact.isEmpty) {
    return 'ART';
  }
  return compact.length <= 4 ? compact : compact.substring(0, 4);
}

String _compactAffix(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty) return '今日';
  return trimmed.length <= 4 ? trimmed : trimmed.substring(0, 4);
}
