import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import '../config/env_config.dart';
import 'prompt_templates.dart';

/// AI服务类
/// 负责与SiliconFlow API通信，提供AI增强的推荐功能
class AiService {
  static final AiService _instance = AiService._internal();
  factory AiService() => _instance;
  AiService._internal();

  late final Dio _dio;
  final Map<String, dynamic> _cache = {};
  DateTime? _lastCacheClean;

  /// 初始化AI服务
  Future<void> init() async {
    _dio = Dio(BaseOptions(
      baseUrl: EnvConfig.siliconFlowApiUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 60),
      sendTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer ${EnvConfig.siliconFlowApiKey}',
      },
    ));

    // 添加请求拦截器
    _dio.interceptors.add(LogInterceptor(
      requestBody: EnvConfig.debugMode,
      responseBody: EnvConfig.debugMode,
      logPrint: (obj) => debugPrint(obj.toString()),
    ));

    // 验证配置
    if (!EnvConfig.validateConfig()) {
      throw Exception('AI服务配置不完整，请检查环境变量');
    }

    debugPrint('AI服务初始化完成');
  }

  /// 基于气泡关键词获取AI推荐
  Future<AiRecommendationResult> getBubbleRecommendations({
    required List<String> selectedBubbles,
    required List<String> availableFoods,
    String? userPreferences,
    String? timeOfDay,
    String? weather,
  }) async {
    if (!EnvConfig.enableAiRecommendations) {
      return _getFallbackRecommendation(selectedBubbles, availableFoods);
    }

    try {
      final cacheKey = _buildCacheKey('bubble', {
        'bubbles': selectedBubbles,
        'foods': availableFoods.take(20).toList(),
        'prefs': userPreferences,
        'time': timeOfDay,
        'weather': weather,
      });

      // 检查缓存
      if (_cache.containsKey(cacheKey)) {
        debugPrint('使用缓存的AI推荐结果');
        return _cache[cacheKey] as AiRecommendationResult;
      }

      final prompt = PromptTemplates.buildBubbleRecommendationPrompt(
        selectedBubbles: selectedBubbles,
        availableFoods: availableFoods,
        userPreferences: userPreferences,
        timeOfDay: timeOfDay,
        weather: weather,
      );

      final response = await _callAiApi(prompt);
      final result = _parseRecommendationResponse(response, selectedBubbles);

      // 缓存结果
      _cacheResult(cacheKey, result);
      
      return result;
    } catch (e) {
      debugPrint('AI推荐失败，使用备用推荐: $e');
      return _getFallbackRecommendation(selectedBubbles, availableFoods);
    }
  }

  /// 生成食物推荐解释
  Future<String> generateFoodExplanation({
    required String foodName,
    required List<String> matchedBubbles,
    required double score,
  }) async {
    if (!EnvConfig.enableAiRecommendations) {
      return _generateFallbackExplanation(foodName, matchedBubbles, score);
    }

    try {
      final cacheKey = _buildCacheKey('explanation', {
        'food': foodName,
        'bubbles': matchedBubbles,
        'score': score.toString(),
      });

      if (_cache.containsKey(cacheKey)) {
        return _cache[cacheKey] as String;
      }

      final prompt = PromptTemplates.buildMenuExplanationPrompt(
        foodName: foodName,
        matchedBubbles: matchedBubbles,
        score: score,
      );

      final response = await _callAiApi(prompt);
      final explanation = response.trim();

      _cacheResult(cacheKey, explanation);
      return explanation;
    } catch (e) {
      debugPrint('AI解释生成失败，使用备用解释: $e');
      return _generateFallbackExplanation(foodName, matchedBubbles, score);
    }
  }

  /// 分析用户偏好
  Future<UserPreferenceAnalysis> analyzeUserPreferences({
    required List<String> favoriteHistory,
    required List<String> dislikedHistory,
    required Map<String, int> bubbleInteractions,
  }) async {
    if (!EnvConfig.enableAiRecommendations) {
      return _getFallbackAnalysis();
    }

    try {
      final cacheKey = _buildCacheKey('analysis', {
        'favorites': favoriteHistory,
        'dislikes': dislikedHistory,
        'bubbles': bubbleInteractions,
      });

      if (_cache.containsKey(cacheKey)) {
        return _cache[cacheKey] as UserPreferenceAnalysis;
      }

      final prompt = PromptTemplates.buildPreferenceAnalysisPrompt(
        favoriteHistory: favoriteHistory,
        dislikedHistory: dislikedHistory,
        bubbleInteractions: bubbleInteractions,
      );

      final response = await _callAiApi(prompt);
      final analysis = _parsePreferenceAnalysis(response);

      _cacheResult(cacheKey, analysis);
      return analysis;
    } catch (e) {
      debugPrint('用户偏好分析失败，使用备用分析: $e');
      return _getFallbackAnalysis();
    }
  }

  /// 调用AI API的核心方法
  Future<String> _callAiApi(String prompt) async {
    final requestData = {
      'model': EnvConfig.aiModelName,
      'messages': [
        {
          'role': 'system',
          'content': '你是一个专业的美食推荐专家，具有丰富的饮食文化知识和个性化推荐经验。'
        },
        {
          'role': 'user',
          'content': prompt,
        }
      ],
      'max_tokens': EnvConfig.aiMaxTokens,
      'temperature': EnvConfig.aiTemperature,
      'top_p': EnvConfig.aiTopP,
      'stream': false,
    };

    debugPrint('发送AI请求: ${EnvConfig.aiModelName}');

    final response = await _dio.post(
      '/chat/completions',
      data: requestData,
    );

    if (response.statusCode == 200) {
      final data = response.data;
      final content = data['choices']?[0]?['message']?['content'] as String?;
      
      if (content == null || content.isEmpty) {
        throw Exception('AI返回内容为空');
      }

      debugPrint('AI响应成功，长度: ${content.length}');
      return content;
    } else {
      throw Exception('AI API调用失败: ${response.statusCode}');
    }
  }

  /// 解析推荐响应
  AiRecommendationResult _parseRecommendationResponse(
      String response, List<String> originalBubbles) {
    final parsed = PromptTemplates.parseRecommendationResponse(response);
    
    return AiRecommendationResult(
      recommendations: parsed['recommendations'] as List<String>,
      reasons: parsed['reasons'] as String,
      score: parsed['score'] as double,
      suggestions: parsed['suggestions'] as String,
      matchedBubbles: originalBubbles,
      rawResponse: response,
      timestamp: DateTime.now(),
    );
  }

  /// 解析偏好分析响应
  UserPreferenceAnalysis _parsePreferenceAnalysis(String response) {
    // 简单解析，实际可以更复杂
    return UserPreferenceAnalysis(
      tasteCharacteristics: _extractAnalysisItem(response, '口味偏好特征'),
      cuisinePreferences: _extractAnalysisItem(response, '菜系偏好'),
      ingredientPreferences: _extractAnalysisItem(response, '食材偏好'),
      avoidTypes: _extractAnalysisItem(response, '避免类型'),
      weightSuggestions: _extractAnalysisItem(response, '推荐权重建议'),
      rawResponse: response,
      timestamp: DateTime.now(),
    );
  }

  String _extractAnalysisItem(String response, String itemName) {
    final regex = RegExp('$itemName[：:]\\s*(.+?)(?=\\n\\d+\\.|\\n[^\\n]*[：:]|\\n\\n|\$)', 
        multiLine: true, dotAll: true);
    final match = regex.firstMatch(response);
    return match?.group(1)?.trim() ?? '';
  }

  /// 缓存管理
  String _buildCacheKey(String type, Map<String, dynamic> params) {
    final keyData = '$type:${params.values.join(':')}';
    return keyData.hashCode.toString();
  }

  void _cacheResult(String key, dynamic result) {
    _cleanCacheIfNeeded();
    _cache[key] = result;
  }

  void _cleanCacheIfNeeded() {
    final now = DateTime.now();
    if (_lastCacheClean == null || 
        now.difference(_lastCacheClean!).inSeconds > EnvConfig.aiCacheDuration) {
      _cache.clear();
      _lastCacheClean = now;
      debugPrint('AI缓存已清理');
    }
  }

  /// 备用推荐方法（AI不可用时）
  AiRecommendationResult _getFallbackRecommendation(
      List<String> bubbles, List<String> foods) {
    final recommendations = foods.take(2).toList();
    final bubbleText = bubbles.join('、');
    
    return AiRecommendationResult(
      recommendations: recommendations,
      reasons: '根据您选择的$bubbleText，为您推荐这些美食',
      score: 7.5,
      suggestions: '建议搭配时令蔬菜，注意营养均衡',
      matchedBubbles: bubbles,
      rawResponse: '备用推荐',
      timestamp: DateTime.now(),
    );
  }

  String _generateFallbackExplanation(String food, List<String> bubbles, double score) {
    final bubbleText = bubbles.isEmpty ? '' : '，符合您的${bubbles.join('、')}偏好';
    return '$food是一道经典美食$bubbleText，推荐指数${score.toStringAsFixed(1)}分';
  }

  UserPreferenceAnalysis _getFallbackAnalysis() {
    return UserPreferenceAnalysis(
      tasteCharacteristics: '偏好均衡口味',
      cuisinePreferences: '中式菜系为主',
      ingredientPreferences: '荤素搭配',
      avoidTypes: '暂无明显偏好',
      weightSuggestions: '建议均衡权重',
      rawResponse: '基础分析',
      timestamp: DateTime.now(),
    );
  }
}

/// AI推荐结果类
class AiRecommendationResult {
  final List<String> recommendations;
  final String reasons;
  final double score;
  final String suggestions;
  final List<String> matchedBubbles;
  final String rawResponse;
  final DateTime timestamp;

  AiRecommendationResult({
    required this.recommendations,
    required this.reasons,
    required this.score,
    required this.suggestions,
    required this.matchedBubbles,
    required this.rawResponse,
    required this.timestamp,
  });
}

/// 用户偏好分析结果类
class UserPreferenceAnalysis {
  final String tasteCharacteristics;
  final String cuisinePreferences;
  final String ingredientPreferences;
  final String avoidTypes;
  final String weightSuggestions;
  final String rawResponse;
  final DateTime timestamp;

  UserPreferenceAnalysis({
    required this.tasteCharacteristics,
    required this.cuisinePreferences,
    required this.ingredientPreferences,
    required this.avoidTypes,
    required this.weightSuggestions,
    required this.rawResponse,
    required this.timestamp,
  });
}

 