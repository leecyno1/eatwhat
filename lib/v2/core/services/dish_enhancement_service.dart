import 'package:dio/dio.dart';
import 'package:eatwhat_app/v2/core/config/client_config.dart';
import 'package:eatwhat_app/v2/core/data/models/ai_generation_models.dart';
import 'package:eatwhat_app/v2/core/data/models/recipe_model.dart';
import 'package:eatwhat_app/v2/core/ports/ai_gateway.dart';
import 'package:eatwhat_app/v2/core/services/generation_prompts.dart';
import 'package:eatwhat_app/v2/core/services/v2_ai_cache_service.dart';

class DishEnhancementService {
  DishEnhancementService({
    required AiGateway transport,
    required V2AiCacheService cache,
    ClientConfig? config,
  })  : _transport = transport,
        _cache = cache,
        _fixedConfig = config;

  final AiGateway _transport;
  final V2AiCacheService _cache;
  final ClientConfig? _fixedConfig;

  ClientConfig get _config => _fixedConfig ?? ClientConfig.fromEnvConfig();

  bool get isConfigured => _transport.isConfigured;

  Future<String?> generateRecipeImageUrl(
    RecipeModel recipe, {
    CancelToken? cancelToken,
  }) async {
    if (!_config.enableLiveDishImageGeneration) {
      return null;
    }

    final cacheKey = 'image:${recipe.id}';
    final cached = await _cache.getString(cacheKey);
    if (cached != null && cached.trim().isNotEmpty) return cached;

    final url = await _transport.generateImage(
      prompt: GenerationPrompts.image(recipe),
      cancelToken: cancelToken,
    );
    if (url == null || url.isEmpty) return null;
    await _cache.setString(cacheKey, url);
    return url;
  }

  Future<String?> generateDishIntroduction(
    RecipeModel recipe, {
    String? recommendationReason,
    String? userRequirement,
  }) async {
    final reason = recommendationReason?.trim() ?? '';
    final requirement = userRequirement?.trim() ?? '';
    final cacheKey =
        'dish_intro:${recipe.id}:${reason.hashCode}:${requirement.hashCode}';
    final cached = await _cache.getString(cacheKey);
    if (cached != null && cached.trim().isNotEmpty) {
      return cached.trim();
    }

    final fallback = _buildDishIntroductionFallback(recipe, reason);
    if (!isConfigured) {
      return fallback;
    }

    try {
      final prompt = GenerationPrompts.dishIntroduction(
        recipe,
        recommendationReason: reason,
        userRequirement: requirement,
      );
      final jsonMap = await _transport.chatJson(
        system: prompt.system,
        user: prompt.user,
        temperature: prompt.temperature,
      );
      final intro = _sanitizeDishIntroduction(
        jsonMap['intro']?.toString() ?? '',
        recipe.name,
      );
      if (intro.isEmpty) {
        return fallback;
      }
      await _cache.setString(cacheKey, intro);
      return intro;
    } catch (_) {
      return fallback;
    }
  }

  String _buildDishIntroductionFallback(
    RecipeModel recipe,
    String recommendationReason,
  ) {
    final description = recipe.description.trim();
    if (description.isNotEmpty && !_looksLikePlaceholderText(description)) {
      return _sanitizeDishIntroduction(description, recipe.name);
    }

    if (recommendationReason.isNotEmpty) {
      final cleanedReason =
          recommendationReason.replaceAll(RegExp(r'^[：:\-\s]+'), '').trim();
      if (cleanedReason.isNotEmpty) {
        return _sanitizeDishIntroduction(cleanedReason, recipe.name);
      }
    }

    final ingredients = recipe.ingredients.take(3).join('、');
    if (ingredients.isNotEmpty) {
      return '${recipe.name}以$ingredients撑起主体味道，适合这轮想吃得更对味的时候。';
    }
    return '${recipe.name}这道菜层次清楚、入口直接，适合作为今天这一轮的主选择。';
  }

  String _sanitizeDishIntroduction(String raw, String recipeName) {
    final compact = raw
        .replaceAll('\n', ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .replaceAll('简介：', '')
        .replaceAll('菜品简介：', '')
        .trim();
    if (compact.isEmpty) {
      return '';
    }
    if (_looksLikePlaceholderText(compact)) {
      return '';
    }
    if (compact == recipeName.trim()) {
      return '';
    }
    return compact;
  }

  bool _looksLikePlaceholderText(String value) {
    final normalized = value.trim().toLowerCase();
    return normalized.isEmpty ||
        normalized.contains('ai生成') ||
        normalized.contains('推荐理由') ||
        normalized.contains('一句话简介') ||
        normalized.contains('平平无奇');
  }

  Future<List<RecipeModel>> generateFusionDishes({
    required List<String> tags,
    String? customRequirement,
    int count = 4,
    CancelToken? cancelToken,
  }) async {
    final cleanedTags = tags
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toSet()
        .toList(growable: false);
    if (cleanedTags.isEmpty || !isConfigured) return const [];

    final prompt = GenerationPrompts.fusion(
      cleanedTags: cleanedTags,
      count: count,
      customRequirement: customRequirement,
    );

    try {
      final jsonMap = await _transport.chatJson(
        system: prompt.system,
        user: prompt.user,
        temperature: prompt.temperature,
        cancelToken: cancelToken,
      );
      return parseFusionDishes(jsonMap, cleanedTags);
    } catch (_) {
      return const [];
    }
  }

  static List<RecipeModel> parseFusionDishes(
    Map<String, dynamic> jsonMap,
    List<String> cleanedTags,
  ) {
    final raw = jsonMap['dishes'];
    if (raw is! List) return const [];
    final stamp = DateTime.now().millisecondsSinceEpoch;
    final dishes = <RecipeModel>[];
    var index = 0;
    for (final item in raw) {
      if (item is! Map) continue;
      final map = item.map((k, v) => MapEntry(k.toString(), v));
      final name = (map['name']?.toString() ?? '').trim();
      if (name.isEmpty) continue;
      final reason = (map['reason']?.toString() ?? '').trim();
      dishes.add(
        RecipeModel(
          id: 'ai_fusion_${stamp}_$index',
          name: name,
          description:
              reason.isEmpty ? '把${cleanedTags.join('、')}组合成的一道创意菜。' : reason,
          ingredients: (map['ingredients'] as List? ?? const [])
              .map((e) => e.toString())
              .where((e) => e.isNotEmpty)
              .take(8)
              .toList(),
          steps: (map['steps'] as List? ?? const [])
              .map((e) {
                if (e is Map && e['description'] != null) {
                  return e['description'].toString();
                }
                return e.toString();
              })
              .where((e) => e.trim().isNotEmpty)
              .take(8)
              .toList(),
          tags: (map['tags'] as List? ?? const [])
              .map((e) => e.toString())
              .where((e) => e.isNotEmpty)
              .take(6)
              .toList(),
          source: 'ai_fusion',
        ),
      );
      index++;
    }
    return dishes;
  }

  Future<NutritionAnalysis> getNutritionAnalysis(RecipeModel recipe) async {
    final cacheKey = 'nutrition:${recipe.id}';
    final cached = await _cache.getJson(cacheKey);
    if (cached != null) return NutritionAnalysis.fromJson(cached);

    if (!isConfigured) {
      final fallback = _fallbackNutrition(recipe.ingredients);
      return fallback;
    }

    final prompt = GenerationPrompts.nutrition(recipe);

    try {
      final jsonMap = await _transport.chatJson(
        system: prompt.system,
        user: prompt.user,
        temperature: prompt.temperature,
      );
      await _cache.setJson(cacheKey, jsonMap);
      return NutritionAnalysis.fromJson(jsonMap);
    } catch (_) {
      final fallback = _fallbackNutrition(recipe.ingredients);
      return fallback;
    }
  }

  Future<WinePairing> getWinePairing(RecipeModel recipe) async {
    final cacheKey = 'wine:${recipe.id}';
    final cached = await _cache.getJson(cacheKey);
    if (cached != null) return WinePairing.fromJson(cached);

    if (!isConfigured) {
      final fallback = _fallbackWinePairing(recipe.ingredients);
      return fallback;
    }

    final prompt = GenerationPrompts.wine(recipe);

    try {
      final jsonMap = await _transport.chatJson(
        system: prompt.system,
        user: prompt.user,
        temperature: prompt.temperature,
      );
      await _cache.setJson(cacheKey, jsonMap);
      return WinePairing.fromJson(jsonMap);
    } catch (_) {
      final fallback = _fallbackWinePairing(recipe.ingredients);
      return fallback;
    }
  }

  Future<FortuneResult> getFortune({
    required RecipeModel recipe,
    String fortuneType = 'daily',
  }) async {
    final cacheKey = 'fortune:${recipe.id}:$fortuneType';
    final cached = await _cache.getJson(cacheKey);
    if (cached != null) return FortuneResult.fromJson(cached);

    final today = DateTime.now();
    String two(int n) => n.toString().padLeft(2, '0');
    final date = '${today.year}-${two(today.month)}-${two(today.day)}';

    if (!isConfigured) {
      final fallback = _fallbackFortune(
        dishName: recipe.name,
        type: fortuneType,
        date: date,
      );
      return fallback;
    }

    final prompt = GenerationPrompts.fortune(
      recipe: recipe,
      fortuneType: fortuneType,
      date: date,
    );

    try {
      final jsonMap = await _transport.chatJson(
        system: prompt.system,
        user: prompt.user,
        temperature: prompt.temperature,
      );
      await _cache.setJson(cacheKey, jsonMap);
      return FortuneResult.fromJson(jsonMap);
    } catch (_) {
      final fallback = _fallbackFortune(
        dishName: recipe.name,
        type: fortuneType,
        date: date,
      );
      return fallback;
    }
  }

  NutritionAnalysis _fallbackNutrition(List<String> ingredients) {
    final text = ingredients.join('|');
    final seed = text.hashCode.abs();

    bool hasAny(List<String> keys) =>
        ingredients.any((i) => keys.any((k) => i.contains(k)));

    final hasMeat = hasAny(['肉', '鸡', '鱼', '虾', '牛', '猪', '羊', '蛋']);
    final hasVeg = hasAny(['菜', '青', '瓜', '菇', '豆', '番茄', '土豆', '萝卜']);
    final hasGrain = hasAny(['米', '面', '粉', '馒头', '饼', '玉米', '燕麦']);

    num jitter(int mod, {int base = 0}) => base + (seed % mod);

    final calories = 260 + jitter(220);
    final protein = hasMeat ? 18 + jitter(10) : 8 + jitter(8);
    final carbs = hasGrain ? 35 + jitter(18) : 15 + jitter(12);
    final fat = hasMeat ? 10 + jitter(8) : 5 + jitter(6);
    final fiber = hasVeg ? 6 + jitter(5) : 2 + jitter(3);
    final sodium = 550 + jitter(450);
    final sugar = 3 + jitter(6);

    final scoreBase = (hasVeg ? 6 : 4) + (hasMeat ? 1 : 0);
    final healthScore = (scoreBase + (seed % 3)).clamp(1, 10).toInt();

    final tags = <String>[];
    if (hasMeat) tags.add('高蛋白');
    if (!hasMeat) tags.add('素食友好');
    if (hasVeg) tags.add('含蔬菜');
    if (hasGrain) tags.add('含主食');
    if (tags.isEmpty) tags.add('家常菜');

    final advice = <String>[
      if (!hasVeg) '建议搭配一份蔬菜，营养更均衡',
      if (sodium > 900) '口味偏咸时可适当少放盐/酱油',
      if (fat > 16) '如在减脂期，可用少油烹饪或用空气炸锅替代',
    ];
    if (advice.isEmpty) advice.add('搭配合理，放心享用');

    return NutritionAnalysis(
      nutrition: NutritionInfo(
        calories: calories,
        protein: protein,
        carbs: carbs,
        fat: fat,
        fiber: fiber,
        sodium: sodium,
        sugar: sugar,
        vitaminC: hasVeg ? 15 + (seed % 35) : null,
        calcium: hasAny(['奶', '豆']) ? 100 + (seed % 120) : null,
        iron: hasMeat ? 2 + (seed % 4) : null,
      ),
      healthScore: healthScore,
      balanceAdvice: advice,
      dietaryTags: tags,
      servingSize: '1人份',
      isEstimated: true,
    );
  }

  WinePairing _fallbackWinePairing(List<String> ingredients) {
    bool hasAny(List<String> keys) =>
        ingredients.any((i) => keys.any((k) => i.contains(k)));
    final spicy = hasAny(['辣', '椒', '花椒', '胡椒', '麻辣', '咖喱']);
    final oily = hasAny(['油', '五花', '肥', '炸', '烤', '煎']);

    if (spicy) {
      return const WinePairing(
        name: '冰镇可乐',
        type: 'soft_drink',
        reason: '甜味和气泡能平衡辣感，清爽解辣。',
        servingTemperature: '冰镇',
        flavor: '甜味气泡，清爽解辣',
        origin: '可口可乐/百事可乐',
        alcoholContent: '0%',
        isEstimated: true,
      );
    }

    if (oily) {
      return const WinePairing(
        name: '乌龙茶',
        type: 'tea',
        reason: '茶香解腻，适合偏油的做法。',
        servingTemperature: '热饮或常温',
        flavor: '清香回甘，解腻',
        alcoholContent: '0%',
        isEstimated: true,
      );
    }

    return const WinePairing(
      name: '气泡水',
      type: 'other',
      reason: '清爽百搭，适合大多数家常菜。',
      servingTemperature: '冰镇',
      flavor: '清爽气泡，干净利落',
      alcoholContent: '0%',
      isEstimated: true,
    );
  }

  FortuneResult _fallbackFortune({
    required String dishName,
    required String type,
    required String date,
  }) {
    final seed = ('$dishName|$type|$date').hashCode.abs();
    final lucky = (seed % 10) + 1;
    final scoreText = lucky >= 8 ? '大吉' : (lucky >= 5 ? '小吉' : '平');
    final tips = <String>[
      if (lucky >= 8) '大胆加点喜欢的配料，今天很顺',
      if (lucky >= 5 && lucky < 8) '少纠结，按最想吃的来',
      if (lucky < 5) '别挑战太复杂的做法，稳一点更香',
      '喝口水再开火，心态决定火候',
    ];

    return FortuneResult(
      id: 'fortune_${seed.toRadixString(16)}',
      type: type,
      date: date,
      dishName: dishName,
      reason: '你今天的胃，偏爱“确定感”。',
      luckyIndex: lucky,
      description: '今日吃 $dishName：$scoreText（仅供娱乐）。',
      tips: tips,
      difficulty: lucky >= 8 ? 'medium' : 'easy',
      cookingTime: 15 + (seed % 25),
      mysticalMessage: '锅里翻滚的不是食材，是好运。',
      isEstimated: true,
    );
  }
}
