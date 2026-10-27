import 'package:eatwhat_app/v2/core/data/models/recipe_model.dart';

class GenerationPrompt {
  const GenerationPrompt({
    required this.system,
    required this.user,
    required this.temperature,
  });

  final String system;
  final String user;
  final double temperature;
}

class GenerationPrompts {
  const GenerationPrompts._();

  static String image(RecipeModel recipe) {
    final ingredients =
        recipe.ingredients.isEmpty ? '家常食材' : recipe.ingredients.join('、');
    return '一道精美的家常菜肴：${recipe.name}，主要食材包括$ingredients。'
        '菜品摆盘精致，色彩丰富，光线柔和，专业美食摄影风格，高清画质，餐厅级别的视觉效果。'
        '背景简洁，突出菜品本身的美感。';
  }

  static GenerationPrompt dishIntroduction(
    RecipeModel recipe, {
    required String recommendationReason,
    required String userRequirement,
  }) {
    final ingredients = recipe.ingredients.isEmpty
        ? '家常食材'
        : recipe.ingredients.take(6).join('、');
    return GenerationPrompt(
      system: '你是一个会写美食编辑文案的助手，只输出合法 JSON。',
      user: '菜名：${recipe.name}\n'
          '简介参考：${recipe.description.trim().isEmpty ? '无' : recipe.description.trim()}\n'
          '推荐理由：${recommendationReason.isEmpty ? '无' : recommendationReason}\n'
          '用户要求：${userRequirement.isEmpty ? '无' : userRequirement}\n'
          '主要食材：$ingredients\n\n'
          '请写一句自然、像编辑写的菜品简介，18 到 36 个汉字，不要标题，不要序号，不要夸张营销词。'
          '只返回 JSON：{"intro":"一句话简介"}',
      temperature: 0.7,
    );
  }

  static GenerationPrompt fusion({
    required List<String> cleanedTags,
    required int count,
    String? customRequirement,
  }) {
    final requirement = (customRequirement?.trim().isNotEmpty ?? false)
        ? '\n补充要求：${customRequirement!.trim()}'
        : '';
    return GenerationPrompt(
      system: '你是创意主厨，擅长把给定食材组合成真实可做的融合菜。只输出 JSON。',
      user: '用户想吃：${cleanedTags.join('、')}。$requirement\n'
          '生成 $count 道把这些食材/口味融合在一起的创意菜'
          '（必须是把它们组合成一道菜，不是各做一道）。\n'
          '只输出 JSON：{"dishes":[{"name":"菜名",'
          '"reason":"一句话为什么这样搭（20字内）",'
          '"ingredients":["主料"],"tags":["口味"],'
          '"steps":["第一步做法","第二步做法","……4到6步，每步一句具体可执行的话"]}]}',
      temperature: 0.7,
    );
  }

  static GenerationPrompt nutrition(RecipeModel recipe) {
    return GenerationPrompt(
      system: '你是一位专业营养师，请根据菜谱信息生成营养分析。只输出 JSON，不要输出解释。请务必用中文。',
      user: '请为以下菜谱生成详细的营养分析：\n'
          '菜名：${recipe.name}\n'
          '食材：${recipe.ingredients.join('、')}\n'
          '烹饪方法：${recipe.steps.join('，')}\n\n'
          '请按照以下 JSON 格式返回营养分析：\n'
          '{\n'
          '  "nutrition": {\n'
          '    "calories": 350,\n'
          '    "protein": 25,\n'
          '    "carbs": 45,\n'
          '    "fat": 12,\n'
          '    "fiber": 8,\n'
          '    "sodium": 800,\n'
          '    "sugar": 6,\n'
          '    "vitaminC": 30,\n'
          '    "calcium": 150,\n'
          '    "iron": 3\n'
          '  },\n'
          '  "healthScore": 8,\n'
          '  "balanceAdvice": ["建议搭配蔬菜沙拉增加维生素"],\n'
          '  "dietaryTags": ["高蛋白", "低脂"],\n'
          '  "servingSize": "1人份"\n'
          '}',
      temperature: 0.5,
    );
  }

  static GenerationPrompt wine(RecipeModel recipe) {
    return GenerationPrompt(
      system: '你是一位专业饮品搭配师，请推荐普通人买得到、喝得惯的饮品搭配。只输出 JSON。',
      user: '请为以下菜谱推荐合适的饮品搭配：\n'
          '菜名：${recipe.name}\n'
          '食材：${recipe.ingredients.join('、')}\n\n'
          '优先推荐接地气饮品（可乐/雪碧/酸梅汤/茶饮/果汁/气泡水/豆浆等）。\n'
          '请严格按 JSON 返回：\n'
          '{\n'
          '  "name": "推荐饮品名称",\n'
          '  "type": "soft_drink/tea/juice/alcoholic/dairy/other",\n'
          '  "reason": "搭配理由说明",\n'
          '  "servingTemperature": "冰镇/常温/热饮",\n'
          '  "glassType": "杯子类型（可选）",\n'
          '  "alcoholContent": "酒精度（无酒精填0%）",\n'
          '  "flavor": "口感描述",\n'
          '  "origin": "品牌或产地（可选）"\n'
          '}',
      temperature: 0.7,
    );
  }

  static GenerationPrompt fortune({
    required RecipeModel recipe,
    required String fortuneType,
    required String date,
  }) {
    return GenerationPrompt(
      system: '你是一个有趣但不迷信的占卜师，用中文输出，只输出 JSON，不要输出任何解释。',
      user: '请为这道菜做一个轻松幽默的“吃饭占卜”（仅供娱乐，不要迷信）：\n'
          '类型：$fortuneType\n'
          '日期：$date\n'
          '菜名：${recipe.name}\n\n'
          '请严格按 JSON 返回：\n'
          '{\n'
          '  "id": "fortune-xxx",\n'
          '  "type": "$fortuneType",\n'
          '  "date": "$date",\n'
          '  "dishName": "${recipe.name}",\n'
          '  "reason": "为什么今天适合吃它",\n'
          '  "luckyIndex": 1,\n'
          '  "description": "今日运势描述",\n'
          '  "tips": ["一句小建议"],\n'
          '  "difficulty": "easy/medium/hard",\n'
          '  "cookingTime": 25,\n'
          '  "mysticalMessage": "一句神秘话语"\n'
          '}',
      temperature: 0.8,
    );
  }
}
