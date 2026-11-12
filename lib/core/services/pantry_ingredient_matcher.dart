/// Conservative pantry matching for shopping/recommendation, not allergy checks.
/// Only equivalent names and explicit quantity suffixes are normalized. A raw
/// ingredient never implies that a processed product (e.g. tomato sauce) exists.
class PantryIngredientMatcher {
  static const _aliasGroups = [
    ['番茄', '西红柿'],
    ['土豆', '马铃薯'],
    ['香菜', '芫荽'],
  ];

  static const _seasonings = {
    '盐',
    '食盐',
    '糖',
    '白糖',
    '白砂糖',
    '冰糖',
    '油',
    '食用油',
    '植物油',
    '橄榄油',
    '花生油',
    '香油',
    '芝麻油',
    '酱油',
    '生抽',
    '老抽',
    '蚝油',
    '醋',
    '陈醋',
    '白醋',
    '料酒',
    '胡椒粉',
    '白胡椒粉',
    '黑胡椒粉',
    '鸡精',
    '味精',
    '味素',
    '淀粉',
    '葱',
    '葱花',
    '香葱',
    '小葱',
    '姜',
    '生姜',
    '蒜',
    '大蒜',
    '蒜瓣',
    '水',
    '清水',
    '开水',
  };

  static const _quantity =
      r'(?:\d+(?:\.\d+)?|[一二三四五六七八九十两半]+)\s*(?:千克|公斤|毫升|kg|ml|克|g|个|只|枚|根|颗|块|片|把|勺|匙|杯|碗)';

  static String _name(String value) {
    var text = value.trim().toLowerCase();
    text = text.replaceFirst(RegExp('^$_quantity\\s*'), '');
    text = text.replaceFirst(RegExp('\\s*$_quantity\$'), '');
    return text.replaceFirst(RegExp(r'\s*(适量|少许|若干)$'), '').trim();
  }

  static String _canonical(String value) {
    final name = _name(value);
    for (final group in _aliasGroups) {
      if (group.contains(name)) return group.first;
    }
    return name;
  }

  static List<String> searchTerms(Iterable<String> pantry) {
    final terms = <String>{};
    for (final value in pantry) {
      final name = _canonical(value);
      if (name.isEmpty) continue;
      terms.add(name);
      for (final group in _aliasGroups) {
        if (group.first == name) terms.addAll(group);
      }
    }
    return terms.toList();
  }

  static PantryIngredientMatch match({
    required Iterable<String> pantry,
    required Iterable<String> ingredients,
  }) {
    // Preserve the first label the user entered rather than presenting an alias.
    final owned = <String, String>{};
    for (final item in pantry) {
      final name = _canonical(item);
      if (name.isNotEmpty) owned.putIfAbsent(name, item.trim);
    }
    final matched = <String>{};
    final missing = <String>{};
    final missingMain = <String>{};
    final missingSeasoning = <String>{};
    for (final line in ingredients) {
      final original = line.trim();
      if (original.isEmpty) continue;
      final parts = original.split(RegExp('[、，,]'));
      for (final part in parts) {
        final name = _canonical(part);
        if (name.isEmpty) continue;
        if (owned.containsKey(name)) {
          matched.add(name);
        } else {
          missing.add(original);
          (_seasonings.contains(name) ? missingSeasoning : missingMain)
              .add(name);
        }
      }
    }
    return PantryIngredientMatch(
      matchedPantry: [
        for (final key in owned.keys)
          if (matched.contains(key)) owned[key]!
      ],
      missingIngredients: missing.toList(),
      missingMainCount: missingMain.length,
      missingSeasoningCount: missingSeasoning.length,
    );
  }
}

class PantryIngredientMatch implements Comparable<PantryIngredientMatch> {
  const PantryIngredientMatch({
    required this.matchedPantry,
    required this.missingIngredients,
    required this.missingMainCount,
    required this.missingSeasoningCount,
  });

  final List<String> matchedPantry;
  final List<String> missingIngredients;
  final int missingMainCount;
  final int missingSeasoningCount;

  /// Prefer using more of what was explicitly supplied, then fewer extra main
  /// ingredients. Seasonings are lower priority, but never silently assumed owned.
  @override
  int compareTo(PantryIngredientMatch other) {
    final coverage = other.matchedPantry.length.compareTo(matchedPantry.length);
    if (coverage != 0) return coverage;
    final main = missingMainCount.compareTo(other.missingMainCount);
    if (main != 0) return main;
    return missingSeasoningCount.compareTo(other.missingSeasoningCount);
  }
}
