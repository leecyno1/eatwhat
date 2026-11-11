/// 推荐模块的确定性约束。仅检查已提供的文本与有限常见食材词表，
/// 不验证配方完整性、交叉污染、清真认证，也不提供医学过敏安全保证。
/// 不依赖 Flutter、数据库或 AI 服务。
class RecipeEligibility {
  RecipeEligibility({
    Iterable<String> dietaryRestrictions = const [],
    Iterable<String> dislikedLabels = const [],
    String freeformRequirement = '',
    Iterable<String> explicitRequestLabels = const [],
    this.maxTimeMinutes,
  })  : _allowDesserts = _explicitlyRequests(
          explicitRequestLabels,
          freeformRequirement,
          _dessertRequestLabels,
        ),
        _allowDrinks = _explicitlyRequests(
          explicitRequestLabels,
          freeformRequirement,
          _drinkRequestLabels,
        ),
        _hasDeclaredDietaryRestrictions = dietaryRestrictions.any(
          (label) => label.trim().isNotEmpty && label.trim() != '无忌口',
        ),
        dislikedLabels = dislikedLabels
            .map((label) => label.trim())
            .where((label) => label.isNotEmpty)
            .toList() {
    for (final label in [
      ...dietaryRestrictions,
      // 不喜欢某种饮食方式不等于要求遵守它；仍按原标签当餐排除。
      ...this
          .dislikedLabels
          .where((label) => !_dietModes.contains(label.toLowerCase())),
    ]) {
      for (final token in label.split(RegExp(r'[、,，;/；]+'))) {
        final normalized = token
            .trim()
            .toLowerCase()
            .replaceFirst(RegExp(r'^(?:不要|不吃|不喝|不含|避免|忌口[:：]?|无)'), '')
            .replaceFirst(RegExp(r'(?:过敏|不耐受|忌口)$'), '');
        _addRestriction(normalized);
      }
    }
    // 只解析明确的否定指令和过敏声明，不扫描 liked/skip 或正向喜欢。
    final foods = _aliases.keys
        .where((key) => !_dietModes.contains(key))
        .toList()
      ..sort((a, b) => b.length.compareTo(a.length));
    final alternatives = foods.map((food) {
      // 成员词不能从植物复合词或英文长词中截取出来。
      final escaped = RegExp.escape(food);
      return switch (food) {
        '鱼' => '$escaped(?!香|腥草)',
        '海鲜' => '$escaped(?!菇)',
        '蟹' => '$escaped(?!味菇)',
        _ => RegExp(r'^[a-z]+$').hasMatch(food) ? '\\b$escaped\\b' : escaped,
      };
    }).join('|');
    final dietAlternatives = _dietModes.map(RegExp.escape).join('|');
    final negative = RegExp(
      '(?:不要|不吃|不喝|不能吃|别放|别加|别有|避免)\\s*'
      '(?!(?:$dietAlternatives))'
      '((?:$alternatives)(?:\\s*[、和及与]\\s*(?:$alternatives))*)',
      caseSensitive: false,
    );
    for (final match in negative.allMatches(freeformRequirement)) {
      for (final token in match.group(1)!.split(RegExp(r'[、和及与]'))) {
        _addRestriction(token.trim().toLowerCase());
      }
    }
    for (final match
        in RegExp('($alternatives)(?:过敏|不耐受)', caseSensitive: false)
            .allMatches(freeformRequirement)) {
      _addRestriction(match.group(1)!.toLowerCase());
    }
    for (final match in RegExp(
      r'(?:^|[，,。;；\s]|今天|今晚|想|要|只|我)(吃素食|吃素|纯素食|纯素|严格素食|蛋奶素食|蛋奶素|素食|清真)',
    ).allMatches(freeformRequirement)) {
      final prefix = freeformRequirement.substring(0, match.start);
      if (RegExp(r'(?:不|别|非)(?:想|要|吃)*\s*$').hasMatch(prefix)) {
        continue;
      }
      _addRestriction(match.group(1)!);
    }
  }

  final List<String> dislikedLabels;
  final int? maxTimeMinutes;
  final Set<String> _restrictions = {};
  final bool _hasDeclaredDietaryRestrictions;
  final bool _allowDesserts;
  final bool _allowDrinks;

  bool get hasDietaryRestrictions =>
      _hasDeclaredDietaryRestrictions || _restrictions.isNotEmpty;
  bool get hasExclusions => hasDietaryRestrictions || dislikedLabels.isNotEmpty;

  static const safetyNotice = '仅按已提供食材和常见忌口词筛选，不代表医学过敏安全保证。';
  static const unverifiedTimeNote = '耗时未核验，不能确认满足时限';
  static const unverifiedBudgetNote = '预算为估算，以实际采购/平台价格为准。';

  void _addRestriction(String label) {
    if (label.isEmpty || label == '无忌口' || label == '忌口') return;
    // 未知结构化项只做保守字面匹配，不推断同义食材或宣称全面核验。
    _restrictions.addAll(_aliases[label] ?? [label]);
  }

  RecipeEligibilityResult evaluate({
    required String name,
    String description = '',
    String category = '',
    Iterable<String> ingredients = const [],
    Iterable<String> tags = const [],
    int? totalTimeMinutes,
    bool requireIngredients = false,
  }) {
    final ingredientNames =
        ingredients.where((item) => item.trim().isNotEmpty).toList();
    final text = [name, description, ...ingredientNames, ...tags]
        .join('|')
        .toLowerCase();
    for (final restriction in _restrictions) {
      final pattern =
          _patterns[restriction] ?? RegExp(RegExp.escape(restriction));
      if (pattern.hasMatch(text)) {
        return RecipeEligibilityResult('命中忌口：$restriction');
      }
    }
    for (final label in dislikedLabels) {
      if (text.contains(label.toLowerCase())) {
        return RecipeEligibilityResult('命中当餐排除：$label');
      }
    }
    if (requireIngredients &&
        hasDietaryRestrictions &&
        ingredientNames.isEmpty) {
      return const RecipeEligibilityResult('食材缺失，无法核验忌口');
    }
    if (maxTimeMinutes != null &&
        totalTimeMinutes != null &&
        totalTimeMinutes > maxTimeMinutes!) {
      return const RecipeEligibilityResult('超过时间约束');
    }
    return RecipeEligibilityResult(
      _mealRejectionReason(name, category, tags, ingredientNames),
    );
  }

  /// 餐食入口只放行菜、主食和汤；甜品/非酒精饮品需本轮明确请求。
  /// 不把召回扩词、历史偏好、skip 或“甜/清爽/夜宵”当作请求。
  /// 仅识别完整类别词或简单肯定句，不从否定句中截取类别。
  static bool _explicitlyRequests(
    Iterable<String> labels,
    String freeform,
    Set<String> categories,
  ) {
    if (labels
        .any((label) => categories.contains(label.trim().toLowerCase()))) {
      return true;
    }
    final alternatives = categories.map(RegExp.escape).join('|');
    final request = RegExp(
      '^(?:我)?(?:今天|今晚|现在)?(?:想要|想|要|来|推荐)?'
      '(?:吃|喝|做)?(?:点|些|一份|一杯)?\\s*'
      '(?:$alternatives)(?:吧|呀|啊)?\$',
      caseSensitive: false,
    );
    return freeform.split(RegExp(r'[，,。；;!！？?\n]')).any(
          (clause) => request.hasMatch(clause.trim()),
        );
  }

  String? _mealRejectionReason(
    String name,
    String category,
    Iterable<String> tags,
    List<String> ingredients,
  ) {
    final normalizedName = name.trim().toLowerCase();
    final categories = {
      category.trim().toLowerCase(),
      ...tags.map((tag) => tag.trim().toLowerCase())
    };
    bool hasCategory(Set<String> values) => categories.any(values.contains);

    // 真实库“调味蘸料”是派生脏标签，蒜蓉虾、宫保鸡丁、啤酒鸭等也有。
    // 不用它或“酱/酒/糖”单字过滤；以来源分类和有限精确菜名为边界。
    if (hasCategory(_preparationCategories) ||
        _preparationNames.contains(normalizedName)) {
      return '非餐食候选：调味酱汁或基础食材加工';
    }
    final isDrink =
        hasCategory(_drinkCategories) || _drinkNames.contains(normalizedName);
    if (hasCategory(_alcoholCategories) ||
        _alcoholNames.contains(normalizedName) ||
        (isDrink && ingredients.any(_alcoholIngredients.hasMatch))) {
      // 当前是决定一餐的入口，不开放酒类；“想喝饮品”也不等于想喝酒。
      // 酒作为正常菜的调味食材不触发这一条，例如啤酒鸭、醉排骨。
      return '非餐食候选：酒类';
    }
    if (isDrink) return _allowDrinks ? null : '非餐食候选：饮品需明确请求';
    if (hasCategory(_dessertCategories) ||
        _dessertNames.contains(normalizedName)) {
      return _allowDesserts ? null : '非餐食候选：甜品需明确请求';
    }
    if (hasCategory(_semiFinishedCategories) &&
        !_preparedMealNames.contains(normalizedName)) {
      return '非餐食候选：半成品加工尚未确认为餐食';
    }
    return null;
  }

  static const _preparationCategories = {
    '调料',
    '调味品',
    '调味料',
    '酱汁',
    '酱料',
    '基础食材加工',
    '食材加工',
    'condiment',
    'condiments',
    'sauce',
  };
  static const _semiFinishedCategories = {'半成品加工', '半成品', 'semi-finished'};
  static const _dessertCategories = {'甜品', '甜点', '甜食', 'dessert'};
  static const _dessertRequestLabels = {
    ..._dessertCategories,
    // Afternoon tea explicitly requests sweet and drinkable items.
    '下午茶',
  };
  static const _drinkCategories = {
    '饮品',
    '饮料',
    '咖啡',
    '茶饮',
    'drink',
    'beverage',
    'coffee'
  };
  static const _drinkRequestLabels = {
    ..._drinkCategories,
    '奶茶',
    '下午茶',
  };
  static const _alcoholCategories = {
    '酒类',
    '酒精饮品',
    '含酒精饮品',
    '鸡尾酒',
    'alcohol',
    'cocktail'
  };
  static final _alcoholIngredients = RegExp(
    r'啤酒|白酒|葡萄酒|红酒|黄酒|米酒|咖啡酒|甜酒|金酒|朗姆|伏特加|威士忌|白兰地|龙舌兰|利口酒|百利|酒酿|醪糟|\b(?:beer|wine|rum|vodka|whisky|whiskey|gin|liqueur)\b',
    caseSensitive: false,
  );

  // 已核对 unified_recipes.db：番茄红酱(id152)被归为荤菜，但仅是拌面酱；
  // 牛油火锅底料(id203)属于半成品加工，不是可直接作为一餐的火锅。
  static const _preparationNames = {
    '油泼辣子',
    '油酥',
    '炸串酱料',
    '简易版炒糖色',
    '糖醋汁',
    '草莓酱',
    '葱油',
    '蒜香酱油',
    '蔗糖糖浆',
    '番茄红酱',
    '牛油火锅底料',
  };
  static const _alcoholNames = {
    'b52轰炸机',
    'mojito莫吉托',
    'mojito',
    '莫吉托',
    '可乐桶',
    '海边落日',
    '酒酿醪糟',
    '金汤力',
    '金菲士',
    '长岛冰茶',
    '啤酒',
  };
  // 精确名补足 AI 未携带类别的常见情况，不按子串误杀奶茶味菜或糖醋菜。
  static const _drinkNames = {'奶茶', '柠檬水', '冬瓜茶', '酸梅汤', '咖啡'};
  static const _dessertNames = {'提拉米苏', '懒人蛋挞'};
  // “半成品加工”混有实际成餐做法，不整类误杀速冻水饺等便捷餐。
  static const _preparedMealNames = {
    '凉皮',
    '半成品意面',
    '空气炸锅羊排',
    '空气炸锅鸡翅中',
    '速冻水饺',
    '速冻汤圆',
    '速冻馄饨',
  };

  List<String> timeNotes(int? totalTimeMinutes) {
    if (maxTimeMinutes == null) return const [];
    if (totalTimeMinutes == null || totalTimeMinutes <= 0) {
      return const [unverifiedTimeNote];
    }
    return totalTimeMinutes <= maxTimeMinutes!
        ? ['$maxTimeMinutes 分钟内可完成']
        : const [];
  }

  static int? parseMaxTimeMinutes(String text) {
    final normalized = text.replaceAll(' ', '').toLowerCase();
    final match =
        RegExp(r'(\d+)(?:分钟|分|min|m)(?:内|以内)?').firstMatch(normalized);
    if (match != null) return int.tryParse(match.group(1)!);
    if (normalized.contains('快手') || normalized.contains('马上')) return 20;
    return null;
  }

  static int? parseMaxBudgetYuan(String text) {
    final normalized = text.replaceAll(' ', '');
    final match = RegExp(r'(\d+)(?:元|块|rmb|¥)(?:内|以内)?').firstMatch(
      normalized.toLowerCase(),
    );
    if (match != null) return int.tryParse(match.group(1)!);
    if (normalized.contains('经济') || normalized.contains('便宜')) return 30;
    if (normalized.contains('想吃好一点')) return 100;
    return null;
  }

  // 中文按明确食材复合词匹配；英文使用单词边界，避免 egg 命中 eggplant。
  // 不用“鸡/牛/羊”单字排除肉类，保留鸡蛋、牛奶、鸡腿菇等蛋奶素食材。
  static const _shrimp = r'虾|\b(?:shrimp|prawn)\b';
  static const _fish = r'鱼(?!香|腥草)|\b(?:fish|salmon|tuna)\b';
  static const _crab = r'蟹(?!味菇)|\bcrab\b';
  static const _shellfish =
      r'贝类|扇贝|干贝|贻贝|青口|蛤蜊|蛏|蚝|牡蛎|\b(?:clam|oyster|scallop)\b';
  static const _seafood =
      '海鲜(?!菇)|水产|$_shrimp|$_fish|$_crab|$_shellfish|鱿|章鱼|墨鱼|海参|海蜇|\\bseafood\\b';
  static const _pork =
      r'猪|五花肉|排骨|里脊|培根|火腿|香肠|腊肉|肥肉|午餐肉|\b(?:pork|bacon|ham|lard)\b';
  static const _meat =
      r'牛肉|牛腩|肥牛|牛排|牛骨|牛筋|牛肚|牛尾|牛油|羊肉|羊排|羊腿|羊杂|羊蝎子|鸡肉|鸡胸|鸡腿(?!菇)|鸡翅|鸡爪|鸡胗|鸡肝|鸡汤|鸡精|整鸡|全鸡|三黄鸡|童子鸡|辣子鸡|黄焖鸡|炸鸡|烤鸡|鸭肉|鸭腿|鸭胸|鸭血|烤鸭|鹅肉|鹅肝|兔肉|肉末|肉丝|肉馅|肉丸|荤菜|(?:^|[|\s])(?:鸡|鸭|鹅|肉)(?:$|[|\s\d])|\b(?:meat|beef|lamb|mutton|chicken|duck|goose)\b';
  static const _dairy =
      r'牛奶|羊奶|奶粉|奶油|奶酪|乳酪|芝士|黄油|酸奶|炼乳|乳清|乳糖|干酪|奶茶|乳制品|(?:^|[|\s])奶(?:$|[|\s\d])|\b(?:milk|cream|cheese|butter|yogurt|whey|dairy)\b';
  static const _egg =
      r'鸡蛋|鸭蛋|鹅蛋|鹌鹑蛋|蛋清|蛋黄|蛋液|蒸蛋|炒蛋|煎蛋|荷包蛋|蛋花|蛋饼|蛋炒|蛋羹|蛋挞|蛋糕|蛋黄酱|美乃滋|(?:^|[|\s])(?:蛋白|蛋)(?:$|[|\s\d])|\beggs?\b|\bmayonnaise\b';
  static final Map<String, RegExp> _patterns = {
    '海鲜': RegExp(_seafood),
    '虾': RegExp(_shrimp),
    '鱼': RegExp(_fish),
    '蟹': RegExp(_crab),
    '贝类': RegExp(_shellfish),
    '香菜': RegExp(r'香菜|芫荽|\b(?:cilantro|coriander)\b'),
    '番茄': RegExp(r'番茄|西红柿'),
    '土豆': RegExp(r'土豆|马铃薯'),
    '花生': RegExp(r'花生|\bpeanuts?\b'),
    '坚果': RegExp(
        r'坚果|花生|核桃|腰果|杏仁|扁桃仁|榛子|开心果|碧根果|夏威夷果|松子|\b(?:nuts?|peanuts?|walnuts?|cashews?|almonds?|hazelnuts?|pistachios?)\b'),
    '奶': RegExp(_dairy),
    '鸡蛋': RegExp(_egg),
    '猪肉': RegExp(_pork),
    '鸡肉': RegExp(
        r'鸡肉|鸡胸|鸡腿(?!菇)|鸡翅|鸡爪|鸡胗|鸡肝|鸡汤|鸡精|整鸡|全鸡|三黄鸡|童子鸡|辣子鸡|黄焖鸡|炸鸡|烤鸡|(?:^|[|\s])鸡(?:$|[|\s\d])|\bchicken\b'),
    '素食': RegExp('$_pork|$_meat|$_seafood'),
    '芒果': RegExp(r'芒果|\bmango\b'),
    '辣': RegExp(r'辣|\bchili\b'),
  };
  static const _dietModes = {
    '素食',
    '蛋奶素',
    '蛋奶素食',
    '吃素',
    '吃素食',
    '纯素',
    '纯素食',
    '严格素食',
    '清真',
    'vegetarian',
    'vegan'
  };
  static const Map<String, List<String>> _aliases = {
    '海鲜': ['海鲜'],
    '水产': ['海鲜'],
    '海产品': ['海鲜'],
    'seafood': ['海鲜'],
    // 单项忌口不擅自扩大为所有海鲜。
    '虾': ['虾'],
    '虾仁': ['虾'],
    'shrimp': ['虾'],
    'prawn': ['虾'],
    '鱼': ['鱼'],
    '鱼类': ['鱼'],
    'fish': ['鱼'],
    '蟹': ['蟹'],
    '螃蟹': ['蟹'],
    'crab': ['蟹'],
    '贝类': ['贝类'],
    // Keep pantry-equivalent ingredients equivalent for exclusions too.
    // Unlike positive pantry matching, exclusions also cover derived products.
    '番茄': ['番茄'],
    '西红柿': ['番茄'],
    '土豆': ['土豆'],
    '马铃薯': ['土豆'],
    '香菜': ['香菜'],
    '芫荽': ['香菜'],
    'cilantro': ['香菜'],
    'coriander': ['香菜'],
    '坚果': ['坚果'],
    '坚果花生': ['坚果'],
    '坚果及花生': ['坚果'],
    'nuts': ['坚果'],
    '花生': ['花生'],
    'peanut': ['花生'],
    'peanuts': ['花生'],
    '奶': ['奶'],
    '牛奶': ['奶'],
    '奶制品': ['奶'],
    '乳制品': ['奶'],
    '乳糖': ['奶'],
    'dairy': ['奶'],
    '鸡蛋': ['鸡蛋'],
    '蛋': ['鸡蛋'],
    '蛋类': ['鸡蛋'],
    'egg': ['鸡蛋'],
    'eggs': ['鸡蛋'],
    '猪肉': ['猪肉'],
    '猪': ['猪肉'],
    '清真': ['猪肉'],
    'pork': ['猪肉'],
    '素食': ['素食'],
    '蛋奶素': ['素食'],
    '蛋奶素食': ['素食'],
    '鸡肉': ['鸡肉'],
    'chicken': ['鸡肉'],
    '吃素': ['素食'],
    '吃素食': ['素食'],
    '肉': ['素食'],
    '肉类': ['素食'],
    'vegetarian': ['素食'],
    '纯素': ['素食', '奶', '鸡蛋'],
    '纯素食': ['素食', '奶', '鸡蛋'],
    '严格素食': ['素食', '奶', '鸡蛋'],
    'vegan': ['素食', '奶', '鸡蛋'],
    '芒果': ['芒果'],
    '辣': ['辣'],
  };
}

class RecipeEligibilityResult {
  const RecipeEligibilityResult(this.rejectionReason);
  final String? rejectionReason;
  bool get allowed => rejectionReason == null;
}
