import 'package:flutter/foundation.dart' show debugPrint;
import '../config/env_config.dart';
import 'ai_service.dart';

/// AI服务测试类
/// 用于验证AI服务的连接和功能是否正常
class AiServiceTest {
  static final AiService _aiService = AiService();

  /// 执行完整测试套件
  static Future<void> runFullTest() async {
    debugPrint('🧪 开始AI服务完整测试...');
    
    try {
      // 1. 配置验证测试
      await _testConfigValidation();
      
      // 2. AI推荐功能测试
      await _testRecommendationFunction();
      
      // 3. 推荐解释功能测试
      await _testExplanationFunction();
      
      // 4. 用户偏好分析测试
      await _testPreferenceAnalysis();
      
      debugPrint('✅ AI服务测试全部通过！');
      
    } catch (e) {
      debugPrint('❌ AI服务测试失败: $e');
      rethrow;
    }
  }

  /// 执行快速测试（仅基础连接）
  static Future<void> runQuickTest() async {
    debugPrint('⚡ 开始AI服务快速测试...');
    
    try {
      // 配置验证
      await _testConfigValidation();
      
      // 简单推荐测试
      await _testBasicRecommendation();
      
      debugPrint('✅ AI服务快速测试通过！');
      
    } catch (e) {
      debugPrint('❌ AI服务快速测试失败: $e');
      rethrow;
    }
  }

  /// 测试配置验证
  static Future<void> _testConfigValidation() async {
    debugPrint('📋 测试1: 配置验证...');
    
    if (!EnvConfig.validateConfig()) {
      throw Exception('环境配置验证失败');
    }
    
    debugPrint('✅ 配置验证通过');
  }

  /// 测试基础推荐功能
  static Future<void> _testBasicRecommendation() async {
    debugPrint('🍜 测试2: 基础推荐功能...');
    
    final testBubbles = ['香辣', '川菜'];
    final result = await _aiService.getBubbleRecommendations(
      selectedBubbles: testBubbles,
      availableFoods: ['宫保鸡丁', '麻婆豆腐', '水煮鱼'],
    );
    
    if (result.recommendations.isEmpty) {
      throw Exception('推荐结果为空');
    }
    
    debugPrint('✅ 基础推荐功能正常，推荐了${result.recommendations.length}个选项');
  }

  /// 测试推荐功能
  static Future<void> _testRecommendationFunction() async {
    debugPrint('🍜 测试2: AI推荐功能...');
    
    final testBubbles = ['香辣', '川菜', '下饭'];
    final testFoods = [
      '宫保鸡丁', '麻婆豆腐', '水煮鱼', '回锅肉', '鱼香肉丝',
      '小炒肉', '青椒土豆丝', '蒸蛋羹'
    ];
    
    final result = await _aiService.getBubbleRecommendations(
      selectedBubbles: testBubbles,
      availableFoods: testFoods,
    );
    
    if (result.recommendations.isEmpty) {
      throw Exception('AI推荐结果为空');
    }
    
    if (result.score < 0 || result.score > 10) {
      throw Exception('推荐评分异常: ${result.score}');
    }
    
    debugPrint('✅ AI推荐功能正常');
    debugPrint('   推荐菜品: ${result.recommendations.join(', ')}');
    debugPrint('   推荐理由: ${result.reasons}');
    debugPrint('   推荐评分: ${result.score}/10');
  }

  /// 测试推荐解释功能
  static Future<void> _testExplanationFunction() async {
    debugPrint('💬 测试3: 推荐解释功能...');
    
    final explanation = await _aiService.generateFoodExplanation(
      foodName: '宫保鸡丁',
      matchedBubbles: ['香辣', '川菜'],
      score: 8.5,
    );
    
    if (explanation.isEmpty) {
      throw Exception('推荐解释为空');
    }
    
    if (explanation.length < 20) {
      throw Exception('推荐解释过于简短');
    }
    
    debugPrint('✅ 推荐解释功能正常');
    debugPrint('   解释内容: $explanation');
  }

  /// 测试用户偏好分析
  static Future<void> _testPreferenceAnalysis() async {
    debugPrint('📊 测试4: 用户偏好分析...');
    
    final analysis = await _aiService.analyzeUserPreferences(
      favoriteHistory: ['宫保鸡丁', '水煮鱼', '麻婆豆腐'],
      dislikedHistory: ['甜品', '生鱼片'],
      bubbleInteractions: {
        '香辣': 10,
        '川菜': 8,
        '清淡': 2,
        '甜腻': 0,
      },
    );
    
    if (analysis.tasteCharacteristics.isEmpty) {
      throw Exception('偏好分析结果为空');
    }
    
    debugPrint('✅ 用户偏好分析功能正常');
    debugPrint('   口味特征: ${analysis.tasteCharacteristics}');
    debugPrint('   菜系偏好: ${analysis.cuisinePreferences}');
    debugPrint('   避免类型: ${analysis.avoidTypes}');
  }

} 