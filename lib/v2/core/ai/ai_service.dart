import 'dart:convert';
import 'dart:developer' as developer;
import 'package:dio/dio.dart';
import 'package:eatwhat_app/core/config/env_config.dart';
import '../data/models/recipe_model.dart';

class AiService {
  AiService(this._dio);

  final Dio _dio;

  String get _baseUrl => EnvConfig.siliconFlowApiUrl;
  String get _apiKey => EnvConfig.siliconFlowApiKey;
  String get _model => EnvConfig.aiModelName;
  int get _timeoutSeconds => EnvConfig.aiRequestTimeoutSeconds;
  int get _maxRetries => EnvConfig.aiMaxRetries;
  double get _temperature => EnvConfig.aiTemperature;

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

  Future<Response<dynamic>> _postChatCompletions({
    required String system,
    required String user,
    required bool includeResponseFormat,
  }) async {
    final data = <String, dynamic>{
      'model': _model,
      'messages': [
        {'role': 'system', 'content': system},
        {'role': 'user', 'content': user},
      ],
      'temperature': _temperature,
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
          text.contains('invalid');
    }
    return error.toString().toLowerCase().contains('response_format');
  }

  Future<List<RecipeModel>> recommendRecipes({
    required List<String> tags,
    required String userProfile,
  }) async {
    if (_apiKey.isEmpty) return [];

    Object? lastError;
    for (var attempt = 0; attempt < _maxRetries; attempt++) {
      try {
        final prompt = _buildRecommendationPrompt(tags, userProfile);

        final response = await _postChatCompletions(
          system: '你是一个专业的AI营养师和美食家。请根据用户的标签和偏好推荐菜品。返回JSON格式。',
          user: prompt,
          includeResponseFormat: true,
        );

        if (response.statusCode != 200) continue;

        final content = response.data['choices'][0]['message']['content'];
        final jsonMap = _parseJsonFromModelContent(content?.toString() ?? '');
        final List<dynamic> recipesJson = jsonMap['recipes'] ?? const [];

        return _mapRecipes(recipesJson);
      } catch (e) {
        lastError = e;

        if (_shouldRetryWithoutResponseFormat(e)) {
          try {
            final prompt = _buildRecommendationPrompt(tags, userProfile);
            final response = await _postChatCompletions(
              system: '你是一个专业的AI营养师和美食家。请根据用户的标签和偏好推荐菜品。返回JSON格式。',
              user: prompt,
              includeResponseFormat: false,
            );
            if (response.statusCode != 200) continue;
            final content = response.data['choices'][0]['message']['content'];
            final jsonMap =
                _parseJsonFromModelContent(content?.toString() ?? '');
            final List<dynamic> recipesJson = jsonMap['recipes'] ?? const [];

            return _mapRecipes(recipesJson);
          } catch (e2) {
            lastError = e2;
          }
        }
      }
    }
    if (lastError != null) {
      developer.log('AI Recommendation Error', error: lastError);
    }

    return [];
  }

  List<RecipeModel> _mapRecipes(List<dynamic> recipesJson) {
    final now = DateTime.now().millisecondsSinceEpoch;
    return recipesJson
        .whereType<Map>()
        .map((raw) {
          final json = raw.map((key, value) => MapEntry(key.toString(), value));
          final name = json['name']?.toString().trim() ?? '';
          final reason = json['reason']?.toString().trim() ?? '';
          final description = json['description']?.toString().trim() ?? '';
          return RecipeModel(
            id: 'ai_${now}_${name.hashCode}',
            name: name,
            description: reason.isNotEmpty ? reason : description,
            ingredients: _stringList(json['ingredients']).take(10).toList(),
            steps: _stringList(json['steps']).take(8).toList(),
            difficulty: json['difficulty']?.toString().trim().isNotEmpty == true
                ? json['difficulty'].toString().trim()
                : 'medium',
            tags: _stringList(json['tags']).take(10).toList(),
            source: 'AI Recommendation',
          );
        })
        .where((recipe) => recipe.name.trim().isNotEmpty)
        .toList();
  }

  List<String> _stringList(dynamic value) {
    if (value is! List) return const [];
    return value
        .map((item) => item.toString().trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }

  Map<String, dynamic> _parseJsonFromModelContent(String raw) {
    var text = raw.trim();
    if (text.startsWith('```json')) {
      text = text.replaceFirst(RegExp(r'^```json\\s*'), '');
      text = text.replaceFirst(RegExp(r'```\\s*$'), '');
    } else if (text.startsWith('```')) {
      text = text.replaceFirst(RegExp(r'^```\\s*'), '');
      text = text.replaceFirst(RegExp(r'```\\s*$'), '');
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

  String _buildRecommendationPrompt(List<String> tags, String userProfile) {
    return '''
    用户偏好标签: ${tags.join(', ')}
    用户画像: $userProfile

    请直接生成5道真实存在、用户能理解和执行的菜品。菜品必须由你根据偏好推理得出，不要返回“推荐菜”“今日菜谱”“示例菜谱”等泛化名称。
    每道菜需要说明它为什么贴合本轮口味，并给出主要食材、简短步骤、难度和标签。
    请严格按照以下JSON格式返回：
    {
      "recipes": [
        {
          "name": "菜名",
          "description": "简介",
          "reason": "为什么适合本轮口味签名",
          "ingredients": ["食材1", "食材2"],
          "steps": ["关键步骤1", "关键步骤2"],
          "difficulty": "easy | medium | hard",
          "tags": ["口味", "场景", "约束"]
        }
      ]
    }
    ''';
  }

  Future<RecipeModel> generateRecipe(String dishName) async {
    // ... existing code ...
    return RecipeModel(
      id: 'ai_${DateTime.now().millisecondsSinceEpoch}',
      name: dishName,
      description: 'AI生成的美味$dishName',
      ingredients: ['神秘食材A', '神秘食材B'],
      steps: ['第一步：打开AI', '第二步：生成菜谱', '第三步：享用'],
      source: 'AI Chef',
    );
  }

  Future<String> generateImage(String prompt) async {
    // SiliconFlow might support image generation or we use another service
    // For now, keep mock or implement if API supports it
    await Future.delayed(const Duration(seconds: 2));
    return 'https://via.placeholder.com/512?text=$prompt';
  }
}
