import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:eatwhat_app/core/config/env_config.dart';
import 'package:eatwhat_app/v2/core/data/models/ai_generation_models.dart';
import 'package:eatwhat_app/v2/core/data/models/recipe_model.dart';
import 'package:eatwhat_app/v2/core/services/v2_ai_cache_service.dart';
import 'package:flutter/foundation.dart';

/// V2 生成服务（模块 2）
///
/// 说明：
/// - 开发阶段可用 `.env` 直连（不建议发布到商店）。
/// - 生产阶段建议走后端代理/短期 token，客户端不放 secret。
class GenerationService {
  GenerationService._internal();
  static final GenerationService instance = GenerationService._internal();

  final Dio _dio = Dio();
  final V2AiCacheService _cache = V2AiCacheService.instance;

  String get _baseUrl => EnvConfig.minimaxChatApiUrl;
  String get _apiKey => EnvConfig.minimaxApiKey;
  String get _textModel => EnvConfig.minimaxChatModel;

  String get _imageModel => EnvConfig.aiImageModelName;
  String get _miniMaxImageModel => EnvConfig.minimaxImageModel.trim().isNotEmpty
      ? EnvConfig.minimaxImageModel
      : (_imageModel.trim().isNotEmpty ? _imageModel : 'image-01');
  String get _imageApiKey => EnvConfig.minimaxApiKey.trim().isNotEmpty
      ? EnvConfig.minimaxApiKey
      : _apiKey;
  String get _imageApiUrl => EnvConfig.minimaxApiUrl;

  int get _timeoutSeconds => EnvConfig.aiRequestTimeoutSeconds;

  int get _maxRetries => EnvConfig.aiMaxRetries;

  double get _temperature => EnvConfig.aiTemperature;

  bool get isConfigured => _apiKey.trim().isNotEmpty;
  bool get _isMiniMaxTextApi =>
      _baseUrl.contains('api.minimaxi.com') ||
      _baseUrl.contains('api.minimax.io');

  Options _options() {
    return Options(
      headers: {
        'Authorization': 'Bearer $_apiKey',
        'Content-Type': 'application/json',
      },
      sendTimeout: Duration(seconds: _timeoutSeconds),
      receiveTimeout: Duration(seconds: _timeoutSeconds),
    );
  }

  Options _imageOptions() {
    return Options(
      headers: {
        'Authorization': 'Bearer $_imageApiKey',
        'Content-Type': 'application/json',
      },
      sendTimeout: Duration(seconds: _timeoutSeconds),
      receiveTimeout: Duration(seconds: _timeoutSeconds),
    );
  }

  Future<Map<String, dynamic>> _chatJson({
    required String system,
    required String user,
    double? temperature,
  }) async {
    if (!isConfigured) {
      throw StateError('AI 未配置：缺少 MINIMAX_API_KEY');
    }

    Object? lastError;
    for (var attempt = 0; attempt < _maxRetries; attempt++) {
      try {
        final response = await _postChatCompletions(
          system: system,
          user: user,
          temperature: temperature ?? _temperature,
          includeResponseFormat: true,
        );

        final content = response.data['choices'][0]['message']['content'];
        return _parseJsonFromModelContent(content?.toString() ?? '');
      } catch (e) {
        lastError = e;

        if (_shouldRetryWithoutResponseFormat(e)) {
          try {
            final response = await _postChatCompletions(
              system: system,
              user: user,
              temperature: temperature ?? _temperature,
              includeResponseFormat: false,
            );
            final content = response.data['choices'][0]['message']['content'];
            return _parseJsonFromModelContent(content?.toString() ?? '');
          } catch (e2) {
            lastError = e2;
          }
        }
      }
    }
    throw Exception('AI 请求失败：$lastError');
  }

  Future<Response<dynamic>> _postChatCompletions({
    required String system,
    required String user,
    required double temperature,
    required bool includeResponseFormat,
  }) async {
    final data = <String, dynamic>{
      'model': _textModel,
      'messages': [
        {'role': 'system', 'content': system},
        {'role': 'user', 'content': user},
      ],
      'temperature': temperature,
      'stream': false,
    };
    if (includeResponseFormat) {
      data['response_format'] = {'type': 'json_object'};
    }

    return _dio.post(
      '$_baseUrl/chat/completions',
      options: _options(),
      data: data,
    );
  }

  bool _shouldRetryWithoutResponseFormat(Object error) {
    if (error is DioException) {
      final status = error.response?.statusCode;
      if (status != 400) return false;
      final body = error.response?.data?.toString() ?? '';
      final msg = error.message ?? '';
      final text = '$msg\n$body'.toLowerCase();
      return text.contains('response_format') ||
          text.contains('unknown parameter') ||
          text.contains('unexpected') ||
          text.contains('invalid');
    }
    final text = error.toString().toLowerCase();
    return text.contains('response_format');
  }

  Map<String, dynamic> _parseJsonFromModelContent(String raw) {
    var text = raw.trim();
    // MiniMax-M2.7 is a reasoning model: the content arrives wrapped in a
    // <think>…</think> segment followed by the answer. Any braces inside the
    // reasoning would corrupt the JSON boundary detection below, so strip
    // the whole segment first (and anything after an unterminated <think>,
    // which means the answer itself was never produced).
    text = text.replaceAll(RegExp(r'<think>[\s\S]*?</think>'), '');
    final unclosedThink = text.indexOf('<think>');
    if (unclosedThink >= 0) {
      text = text.substring(0, unclosedThink);
    }
    if (text.startsWith('```json')) {
      text = text.replaceFirst(RegExp(r'^```json\s*'), '');
      text = text.replaceFirst(RegExp(r'```\s*$'), '');
    } else if (text.startsWith('```')) {
      text = text.replaceFirst(RegExp(r'^```\s*'), '');
      text = text.replaceFirst(RegExp(r'```\s*$'), '');
    }

    final start = text.indexOf('{');
    final end = text.lastIndexOf('}');
    if (start >= 0 && end >= 0 && end > start) {
      text = text.substring(start, end + 1);
    }

    final decoded = jsonDecode(text);
    if (decoded is Map<String, dynamic>) return decoded;
    if (decoded is Map) {
      return decoded.map((k, v) => MapEntry(k.toString(), v));
    }
    throw const FormatException('AI 返回不是 JSON 对象');
  }

  String _buildImagePrompt(RecipeModel recipe) {
    final ingredients =
        recipe.ingredients.isEmpty ? '家常食材' : recipe.ingredients.join('、');
    return '一道精美的家常菜肴：${recipe.name}，主要食材包括$ingredients。'
        '菜品摆盘精致，色彩丰富，光线柔和，专业美食摄影风格，高清画质，餐厅级别的视觉效果。'
        '背景简洁，突出菜品本身的美感。';
  }

  Future<String?> generateRecipeImageUrl(RecipeModel recipe) async {
    if (!EnvConfig.enableLiveDishImageGeneration) {
      return null;
    }

    final cacheKey = 'image:${recipe.id}';
    final cached = await _cache.getString(cacheKey);
    if (cached != null && cached.trim().isNotEmpty) return cached;

    if ((!isConfigured && _imageApiKey.trim().isEmpty) ||
        (_imageModel.trim().isEmpty && _miniMaxImageModel.trim().isEmpty)) {
      return null;
    }

    Object? lastError;
    for (var attempt = 0; attempt < _maxRetries; attempt++) {
      try {
        if (_isMiniMaxTextApi || _imageApiUrl.contains('api.minimaxi.com')) {
          final imageLocation = await _generateMiniMaxImageLocation(recipe);
          if (imageLocation != null && imageLocation.isNotEmpty) {
            await _cache.setString(cacheKey, imageLocation);
            return imageLocation;
          }
          return null;
        }

        final response = await _dio.post(
          '$_baseUrl/images/generations',
          options: _options(),
          data: {
            'model': _imageModel,
            'prompt': _buildImagePrompt(recipe),
            'size': '1024x1024',
            'n': 1,
            'style': 'vivid',
            'quality': 'hd',
          },
        );

        final data = response.data;
        final list = data['data'];
        if (list is List && list.isNotEmpty) {
          final url = list.first['url']?.toString();
          if (url != null && url.isNotEmpty) {
            await _cache.setString(cacheKey, url);
            return url;
          }
        }
        return null;
      } catch (e) {
        lastError = e;
      }
    }
    throw Exception('图片生成失败：$lastError');
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
      final ingredients = recipe.ingredients.isEmpty
          ? '家常食材'
          : recipe.ingredients.take(6).join('、');
      final prompt = '菜名：${recipe.name}\n'
          '简介参考：${recipe.description.trim().isEmpty ? '无' : recipe.description.trim()}\n'
          '推荐理由：${reason.isEmpty ? '无' : reason}\n'
          '用户要求：${requirement.isEmpty ? '无' : requirement}\n'
          '主要食材：$ingredients\n\n'
          '请写一句自然、像编辑写的菜品简介，18 到 36 个汉字，不要标题，不要序号，不要夸张营销词。'
          '只返回 JSON：{"intro":"一句话简介"}';
      final jsonMap = await _chatJson(
        system: '你是一个会写美食编辑文案的助手，只输出合法 JSON。',
        user: prompt,
        temperature: 0.7,
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

  Future<String?> _generateMiniMaxImageLocation(RecipeModel recipe) async {
    if (_imageApiKey.trim().isEmpty) {
      return null;
    }

    final response = await _dio.post(
      _imageApiUrl,
      options: _imageOptions(),
      data: {
        'model': _miniMaxImageModel,
        'prompt': _buildImagePrompt(recipe),
        'aspect_ratio': '4:3',
        'response_format': 'url',
        'n': 1,
        'prompt_optimizer': false,
      },
    );

    final miniMaxError = _extractMiniMaxError(response.data);
    if (miniMaxError != null) {
      final normalized = miniMaxError.toLowerCase();
      final isAuthIssue = normalized.contains('status_code=1004') ||
          normalized.contains('authorization') ||
          normalized.contains('secret key');
      if (isAuthIssue) {
        throw Exception(
          'MiniMax 图片接口鉴权失败，请检查当前 API Key、'
          'Authorization 请求头以及本地 .env 配置。'
          '官方返回：$miniMaxError',
        );
      }
      throw Exception('MiniMax 图片接口返回错误：$miniMaxError');
    }

    final url = extractMiniMaxImageUrl(response.data);
    if (url != null && url.isNotEmpty) {
      return url;
    }

    final base64Payload = extractMiniMaxImageBase64(response.data);
    if (base64Payload == null || base64Payload.isEmpty) {
      return null;
    }
    return 'data:image/jpeg;base64,$base64Payload';
  }

  @visibleForTesting
  static String? extractMiniMaxImageBase64(dynamic payload) {
    String? pickFirstString(dynamic candidate) {
      if (candidate is String) {
        final value = candidate.trim();
        return value.isEmpty ? null : value;
      }
      if (candidate is List) {
        for (final item in candidate) {
          final value = pickFirstString(item);
          if (value != null) {
            return value;
          }
        }
      }
      return null;
    }

    if (payload is Map) {
      final directCandidates = [
        payload['base64'],
        payload['image_base64'],
        payload['base64_data'],
        payload['b64_json'],
      ];
      for (final candidate in directCandidates) {
        final value = pickFirstString(candidate);
        if (value != null) {
          return value;
        }
      }

      final data = payload['data'];
      if (data is Map) {
        return extractMiniMaxImageBase64(data);
      }
      if (data is List && data.isNotEmpty) {
        return extractMiniMaxImageBase64(data.first);
      }
    }
    return null;
  }

  @visibleForTesting
  static String? extractMiniMaxImageUrl(dynamic payload) {
    String? pickFirstString(dynamic candidate) {
      if (candidate is String) {
        final value = candidate.trim();
        return value.isEmpty ? null : value;
      }
      if (candidate is List) {
        for (final item in candidate) {
          final value = pickFirstString(item);
          if (value != null) {
            return value;
          }
        }
      }
      return null;
    }

    if (payload is Map) {
      final directCandidates = [
        payload['url'],
        payload['image_url'],
        payload['image_urls'],
      ];
      for (final candidate in directCandidates) {
        final value = pickFirstString(candidate);
        if (value != null) {
          return value;
        }
      }

      final data = payload['data'];
      if (data is Map) {
        return extractMiniMaxImageUrl(data);
      }
      if (data is List && data.isNotEmpty) {
        return extractMiniMaxImageUrl(data.first);
      }
    }
    return null;
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

  String? _extractMiniMaxError(dynamic payload) {
    if (payload is Map) {
      final baseResp = payload['base_resp'];
      if (baseResp is Map) {
        final statusCode = baseResp['status_code']?.toString() ?? '';
        final statusMsg = baseResp['status_msg']?.toString() ?? '';
        final normalizedMsg = statusMsg.trim().toLowerCase();
        const successMessages = {'', 'success', 'ok'};
        if ((statusCode.isNotEmpty && statusCode != '0') ||
            !successMessages.contains(normalizedMsg)) {
          return 'status_code=$statusCode, status_msg=$statusMsg';
        }
      }
    }
    return null;
  }

  /// 创意融合生成：把用户选出的食材/口味标签交给模型组合成新菜，
  /// 而不是在本地候选里各挑一道。提示词刻意简短，组合创意交给模型。
  Future<List<RecipeModel>> generateFusionDishes({
    required List<String> tags,
    String? customRequirement,
    int count = 4,
  }) async {
    final cleanedTags = tags
        .map((t) => t.trim())
        .where((t) => t.isNotEmpty)
        .toSet()
        .toList(growable: false);
    if (cleanedTags.isEmpty || !isConfigured) return const [];

    final requirement = (customRequirement?.trim().isNotEmpty ?? false)
        ? '\n补充要求：${customRequirement!.trim()}'
        : '';
    final prompt = '用户想吃：${cleanedTags.join('、')}。$requirement\n'
        '生成 $count 道把这些食材/口味融合在一起的创意菜'
        '（必须是把它们组合成一道菜，不是各做一道）。\n'
        '只输出 JSON：{"dishes":[{"name":"菜名",'
        '"reason":"一句话为什么这样搭（20字内）",'
        '"ingredients":["主料"],"tags":["口味"]}]}';

    try {
      final jsonMap = await _chatJson(
        system: '你是创意主厨，擅长把给定食材组合成真实可做的融合菜。只输出 JSON。',
        user: prompt,
        temperature: 0.7,
      );
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
    } catch (_) {
      return const [];
    }
  }

  Future<RecipeModel> generateRecipeForDish({
    required RecipeModel base,
    String? customRequirement,
  }) async {
    final cacheKey = 'recipe:${base.id}:${customRequirement ?? ''}';
    final cached = await _cache.getJson(cacheKey);
    if (cached != null) {
      final cachedDescription =
          (cached['description']?.toString() ?? '').trim();
      final ingredients = (cached['ingredients'] is List)
          ? (cached['ingredients'] as List)
              .map((e) => e.toString())
              .where((e) => e.isNotEmpty)
              .toList()
          : const <String>[];
      final steps = (cached['steps'] is List)
          ? (cached['steps'] as List)
              .map((e) {
                if (e is Map && e['description'] != null) {
                  return e['description'].toString();
                }
                return e.toString();
              })
              .where((e) => e.isNotEmpty)
              .toList()
          : const <String>[];

      return base.copyWith(
        description:
            cachedDescription.isNotEmpty ? cachedDescription : base.description,
        ingredients: ingredients.isEmpty ? base.ingredients : ingredients,
        steps: steps.isEmpty ? base.steps : steps,
        difficulty: cached['difficulty']?.toString() ?? base.difficulty,
      );
    }

    if (!isConfigured) return base;

    final ingredientsHint =
        base.ingredients.isEmpty ? '（未知，可自行发挥）' : base.ingredients.join('、');

    var prompt = '请为以下菜品生成详细的家常菜谱：\n'
        '菜名：${base.name}\n'
        '已知/偏好食材：$ingredientsHint\n';

    if (customRequirement != null && customRequirement.trim().isNotEmpty) {
      prompt += '\n用户的特殊要求：${customRequirement.trim()}\n';
    }

    prompt += '\n请严格按照以下 JSON 返回（不要输出任何多余文字）：\n'
        '{\n'
        '  \"name\": \"菜品名称\",\n'
        '  \"description\": \"一句话简介\",\n'
        '  \"ingredients\": [\"食材1\", \"食材2\"],\n'
        '  \"steps\": [\n'
        '    {\"step\": 1, \"description\": \"步骤描述\", \"time\": 5, \"temperature\": \"中火\"}\n'
        '  ],\n'
        '  \"cookingTime\": 30,\n'
        '  \"difficulty\": \"easy/medium/hard\",\n'
        '  \"tips\": [\"技巧1\", \"技巧2\"]\n'
        '}';

    final jsonMap = await _chatJson(
      system: '你是一位专业厨师，请根据用户给出的菜名与食材提示生成可执行的菜谱。只输出 JSON，不要输出解释。',
      user: prompt,
      temperature: 0.7,
    );

    await _cache.setJson(cacheKey, jsonMap);

    final generatedDescription =
        (jsonMap['description']?.toString() ?? '').trim();
    final ingredients = (jsonMap['ingredients'] is List)
        ? (jsonMap['ingredients'] as List)
            .map((e) => e.toString())
            .where((e) => e.isNotEmpty)
            .toList()
        : const <String>[];
    final steps = (jsonMap['steps'] is List)
        ? (jsonMap['steps'] as List)
            .map((e) {
              if (e is Map && e['description'] != null) {
                return e['description'].toString();
              }
              return e.toString();
            })
            .where((e) => e.isNotEmpty)
            .toList()
        : const <String>[];

    return base.copyWith(
      description: generatedDescription.isNotEmpty
          ? generatedDescription
          : base.description,
      ingredients: ingredients.isEmpty ? base.ingredients : ingredients,
      steps: steps.isEmpty ? base.steps : steps,
      difficulty: jsonMap['difficulty']?.toString() ?? base.difficulty,
    );
  }

  Future<AiRefinedRecommendations> refineRecommendations({
    required List<String> selectedTags,
    required List<RecipeModel> candidates,
    int limit = 5,
    String? customRequirement,
  }) async {
    final cleanedTags =
        selectedTags.map((e) => e.trim()).where((e) => e.isNotEmpty).toList();
    final cleanedCandidates =
        candidates.where((e) => e.name.trim().isNotEmpty).toList();

    if (cleanedCandidates.isEmpty) {
      return const AiRefinedRecommendations(
        recipeIds: [],
        reasonsById: {},
        summary: null,
        isEstimated: true,
      );
    }

    final candidateIds = cleanedCandidates.map((e) => e.id).toList();
    final keyBase =
        'rerank:${cleanedTags.join(',')}:${candidateIds.join(',')}:$limit:${customRequirement ?? ''}';
    final cacheKey = 'rerank:${keyBase.hashCode.toRadixString(16)}';
    final cached = await _cache.getJson(cacheKey);
    if (cached != null) return AiRefinedRecommendations.fromJson(cached);

    if (!isConfigured) {
      final fallback = AiRefinedRecommendations(
        recipeIds: candidateIds.take(limit).toList(),
        reasonsById: const {},
        summary: null,
        isEstimated: true,
      );
      await _cache.setJson(cacheKey, fallback.toJson());
      return fallback;
    }

    // Compact candidate cards keep the reasoning model fast: 10 candidates,
    // 5 tags + 5 ingredients each is all the signal the pick needs.
    final candidatesText = cleanedCandidates.take(10).map((r) {
      final tags = r.tags.take(5).join('、');
      final ings = r.ingredients.take(5).join('、');
      return '- dishId=${r.id}｜菜名=${r.name}｜标签=${tags.isEmpty ? '无' : tags}｜食材=${ings.isEmpty ? '无' : ings}';
    }).join('\n');

    final requirementText = (customRequirement?.trim().isNotEmpty ?? false)
        ? '【用户补充要求】${customRequirement!.trim()}\n\n'
        : '';

    final prompt = '【用户本轮偏好标签】${cleanedTags.join('、')}\n\n'
        '$requirementText'
        '【候选菜品】（必须只从此列表中选择，不得编造新的 dishId）：\n'
        '$candidatesText\n\n'
        '【任务】你是私人点菜师，从候选中挑 $limit 道组成一桌：'
        '既要单道匹配偏好，更要整桌成立——口味有层次、荤素主食有结构、场景对得上。\n'
        '请严格按 JSON 输出（不要任何多余文字）：\n'
        '{\n'
        '  \"recommendations\": [\n'
        '    {\"dishId\": \"123\", \"dishName\": \"菜品名\", \"reason\": \"一句话说明入选理由，具体到口味/食材/场景（20字内）\", \"confidence\": 0.86}\n'
        '  ],\n'
        '  \"summary\": \"一句话解释这组菜为什么搭在一起：口味层次、荤素结构、场景契合（40字内）\"\n'
        '}';

    try {
      final jsonMap = await _chatJson(
        system: '你是《吃什么》应用的私人点菜师，任务是替用户组一桌好菜。\n'
            '规则：\n'
            '1. 只能从候选列表中选择 dishId，禁止编造。\n'
            '2. 每道菜的 reason 一句话、20 字内，必须具体（点名口味、食材或场景），禁止空话（如“很美味”“适合您”）。\n'
            '3. summary 解释整组搭配逻辑（口味层次/荤素主食结构/场景契合），一句话 40 字内。\n'
            '4. dishId 与 dishName 必须成对输出且指向同一道候选菜。\n'
            '5. 只输出 JSON，用中文。',
        user: prompt,
        temperature: 0.4,
      );

      final recsRaw = jsonMap['recommendations'];
      final recs = <Map<String, dynamic>>[];
      if (recsRaw is List) {
        for (final it in recsRaw) {
          if (it is Map<String, dynamic>) {
            recs.add(it);
          } else if (it is Map) {
            recs.add(it.map((k, v) => MapEntry(k.toString(), v)));
          }
        }
      }

      final allowedIds = candidateIds.toSet();
      final orderedIds = <String>[];
      final reasonsById = <String, String>{};

      String? tryResolveId(Map<String, dynamic> item) {
        final rawId = item['dishId'] ?? item['dish_id'] ?? item['id'];
        String? id;
        if (rawId != null) {
          final s = rawId.toString().trim();
          if (s.isNotEmpty) id = s;
        }

        final name =
            ((item['dishName'] ?? item['name'])?.toString() ?? '').trim();

        if (id != null && name.isNotEmpty) {
          // Dual-key cross-check: the echoed dishName must agree with the
          // candidate the dishId points at, so a hallucinated or swapped
          // id can never surface a mismatched dish (and its image).
          final agreeing = cleanedCandidates
              .where((c) => _dishNameMatches(c.name, name))
              .map((c) => c.id)
              .toSet();
          if (agreeing.isNotEmpty && !agreeing.contains(id)) {
            // id and name disagree: trust the name only when unique.
            return agreeing.length == 1 ? agreeing.first : null;
          }
        }
        if (id != null) return id;

        if (name.isEmpty) return null;
        final match = cleanedCandidates
            .where((c) => _dishNameMatches(c.name, name))
            .toList();
        if (match.length == 1) return match.first.id;
        if (match.isNotEmpty) {
          final exact = match.where((c) => c.name == name).toList();
          if (exact.isNotEmpty) return exact.first.id;
        }
        return null;
      }

      for (final item in recs) {
        final id = tryResolveId(item);
        if (id == null) continue;
        if (!allowedIds.contains(id)) continue;
        if (orderedIds.contains(id)) continue;
        orderedIds.add(id);

        final reason = (item['reason']?.toString() ?? '').trim();
        if (reason.isNotEmpty) reasonsById[id] = reason;
      }

      for (final id in candidateIds) {
        if (orderedIds.length >= limit) break;
        if (!orderedIds.contains(id)) orderedIds.add(id);
      }

      final summary = (jsonMap['summary']?.toString() ?? '').trim();
      final result = AiRefinedRecommendations(
        recipeIds: orderedIds.take(limit).toList(),
        reasonsById: reasonsById,
        summary: summary.isEmpty ? null : summary,
        isEstimated: false,
      );

      await _cache.setJson(cacheKey, result.toJson());
      return result;
    } catch (_) {
      final fallback = AiRefinedRecommendations(
        recipeIds: candidateIds.take(limit).toList(),
        reasonsById: const {},
        summary: null,
        isEstimated: true,
      );
      await _cache.setJson(cacheKey, fallback.toJson());
      return fallback;
    }
  }

  /// Fuzzy dish-name agreement used for the dishId/dishName dual-key
  /// cross-check: exact after normalization, or one containing the other
  /// (the model often echoes a shortened name like 麻婆豆腐 vs 麻婆豆腐(家常)).
  static bool _dishNameMatches(String candidateName, String echoedName) {
    String normalize(String value) => value
        .trim()
        .toLowerCase()
        .replaceAll(RegExp(r'[\s\-_·•,，。.!！？?、（）()：:]'), '');
    final a = normalize(candidateName);
    final b = normalize(echoedName);
    if (a.isEmpty || b.isEmpty) return false;
    return a == b || a.contains(b) || b.contains(a);
  }

  Future<NutritionAnalysis> getNutritionAnalysis(RecipeModel recipe) async {
    final cacheKey = 'nutrition:${recipe.id}';
    final cached = await _cache.getJson(cacheKey);
    if (cached != null) return NutritionAnalysis.fromJson(cached);

    if (!isConfigured) {
      final fallback = _fallbackNutrition(recipe.ingredients);
      await _cache.setJson(cacheKey, fallback.toJson());
      return fallback;
    }

    final prompt = '请为以下菜谱生成详细的营养分析：\n'
        '菜名：${recipe.name}\n'
        '食材：${recipe.ingredients.join('、')}\n'
        '烹饪方法：${recipe.steps.join('，')}\n\n'
        '请按照以下 JSON 格式返回营养分析：\n'
        '{\n'
        '  \"nutrition\": {\n'
        '    \"calories\": 350,\n'
        '    \"protein\": 25,\n'
        '    \"carbs\": 45,\n'
        '    \"fat\": 12,\n'
        '    \"fiber\": 8,\n'
        '    \"sodium\": 800,\n'
        '    \"sugar\": 6,\n'
        '    \"vitaminC\": 30,\n'
        '    \"calcium\": 150,\n'
        '    \"iron\": 3\n'
        '  },\n'
        '  \"healthScore\": 8,\n'
        '  \"balanceAdvice\": [\"建议搭配蔬菜沙拉增加维生素\"],\n'
        '  \"dietaryTags\": [\"高蛋白\", \"低脂\"],\n'
        '  \"servingSize\": \"1人份\"\n'
        '}';

    try {
      final jsonMap = await _chatJson(
        system: '你是一位专业营养师，请根据菜谱信息生成营养分析。只输出 JSON，不要输出解释。请务必用中文。',
        user: prompt,
        temperature: 0.5,
      );
      await _cache.setJson(cacheKey, jsonMap);
      return NutritionAnalysis.fromJson(jsonMap);
    } catch (_) {
      final fallback = _fallbackNutrition(recipe.ingredients);
      await _cache.setJson(cacheKey, fallback.toJson());
      return fallback;
    }
  }

  Future<WinePairing> getWinePairing(RecipeModel recipe) async {
    final cacheKey = 'wine:${recipe.id}';
    final cached = await _cache.getJson(cacheKey);
    if (cached != null) return WinePairing.fromJson(cached);

    if (!isConfigured) {
      final fallback = _fallbackWinePairing(recipe.ingredients);
      await _cache.setJson(cacheKey, fallback.toJson());
      return fallback;
    }

    final prompt = '请为以下菜谱推荐合适的饮品搭配：\n'
        '菜名：${recipe.name}\n'
        '食材：${recipe.ingredients.join('、')}\n\n'
        '优先推荐接地气饮品（可乐/雪碧/酸梅汤/茶饮/果汁/气泡水/豆浆等）。\n'
        '请严格按 JSON 返回：\n'
        '{\n'
        '  \"name\": \"推荐饮品名称\",\n'
        '  \"type\": \"soft_drink/tea/juice/alcoholic/dairy/other\",\n'
        '  \"reason\": \"搭配理由说明\",\n'
        '  \"servingTemperature\": \"冰镇/常温/热饮\",\n'
        '  \"glassType\": \"杯子类型（可选）\",\n'
        '  \"alcoholContent\": \"酒精度（无酒精填0%）\",\n'
        '  \"flavor\": \"口感描述\",\n'
        '  \"origin\": \"品牌或产地（可选）\"\n'
        '}';

    try {
      final jsonMap = await _chatJson(
        system: '你是一位专业饮品搭配师，请推荐普通人买得到、喝得惯的饮品搭配。只输出 JSON。',
        user: prompt,
        temperature: 0.7,
      );
      await _cache.setJson(cacheKey, jsonMap);
      return WinePairing.fromJson(jsonMap);
    } catch (_) {
      final fallback = _fallbackWinePairing(recipe.ingredients);
      await _cache.setJson(cacheKey, fallback.toJson());
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
      await _cache.setJson(cacheKey, fallback.toJson());
      return fallback;
    }

    final prompt = '请为这道菜做一个轻松幽默的“吃饭占卜”（仅供娱乐，不要迷信）：\n'
        '类型：$fortuneType\n'
        '日期：$date\n'
        '菜名：${recipe.name}\n\n'
        '请严格按 JSON 返回：\n'
        '{\n'
        '  \"id\": \"fortune-xxx\",\n'
        '  \"type\": \"$fortuneType\",\n'
        '  \"date\": \"$date\",\n'
        '  \"dishName\": \"${recipe.name}\",\n'
        '  \"reason\": \"为什么今天适合吃它\",\n'
        '  \"luckyIndex\": 1,\n'
        '  \"description\": \"今日运势描述\",\n'
        '  \"tips\": [\"一句小建议\"],\n'
        '  \"difficulty\": \"easy/medium/hard\",\n'
        '  \"cookingTime\": 25,\n'
        '  \"mysticalMessage\": \"一句神秘话语\"\n'
        '}';

    try {
      final jsonMap = await _chatJson(
        system: '你是一个有趣但不迷信的占卜师，用中文输出，只输出 JSON，不要输出任何解释。',
        user: prompt,
        temperature: 0.8,
      );
      await _cache.setJson(cacheKey, jsonMap);
      return FortuneResult.fromJson(jsonMap);
    } catch (_) {
      final fallback = _fallbackFortune(
        dishName: recipe.name,
        type: fortuneType,
        date: date,
      );
      await _cache.setJson(cacheKey, fallback.toJson());
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
