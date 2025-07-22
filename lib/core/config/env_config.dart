import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart' show debugPrint;

/// 环境变量配置管理类
/// 提供统一的环境变量访问接口
class EnvConfig {
  EnvConfig._();

  /// 初始化环境配置
  static Future<void> init() async {
    try {
      await dotenv.load();
      debugPrint('Environment configuration loaded successfully');
    } catch (e) {
      debugPrint('Warning: Failed to load .env file: $e');
      debugPrint('Continuing with default configuration...');
      // Continue execution even if .env fails to load
    }
  }

  // AI服务配置
  static String get siliconFlowApiKey => 
      dotenv.env['SILICONFLOW_API_KEY'] ?? '';
  
  static String get siliconFlowApiUrl => 
      dotenv.env['SILICONFLOW_API_URL'] ?? 'https://api.siliconflow.cn/v1';
  
  // 安全配置
  static String get passwordSalt => 
      dotenv.env['PASSWORD_SALT'] ?? 'default_salt_change_in_production';
  
  static String get jwtSecret => 
      dotenv.env['JWT_SECRET'] ?? 'default_jwt_secret_change_in_production';
  
  static String get encryptionKey => 
      dotenv.env['ENCRYPTION_KEY'] ?? 'default_encryption_key_change_in_production';

  // AI模型配置
  static String get aiModelName => 
      dotenv.env['AI_MODEL_NAME'] ?? 'Qwen/Qwen3-30B-A3B';
  
  static int get aiMaxTokens => 
      int.tryParse(dotenv.env['AI_MAX_TOKENS'] ?? '2048') ?? 2048;
  
  static double get aiTemperature => 
      double.tryParse(dotenv.env['AI_TEMPERATURE'] ?? '0.7') ?? 0.7;
  
  static double get aiTopP => 
      double.tryParse(dotenv.env['AI_TOP_P'] ?? '0.9') ?? 0.9;

  // 应用配置
  static String get appVersion => 
      dotenv.env['APP_VERSION'] ?? '1.0.0';
  
  static bool get debugMode => 
      dotenv.env['DEBUG_MODE']?.toLowerCase() == 'true';
  
  static bool get enableAiRecommendations => 
      dotenv.env['ENABLE_AI_RECOMMENDATIONS']?.toLowerCase() == 'true';

  // 缓存配置
  static int get aiCacheDuration => 
      int.tryParse(dotenv.env['AI_CACHE_DURATION'] ?? '300') ?? 300;
  
  static int get maxRecommendationCache => 
      int.tryParse(dotenv.env['MAX_RECOMMENDATION_CACHE'] ?? '50') ?? 50;

  /// 验证必要的环境变量是否已配置
  static bool validateConfig() {
    final requiredVars = [
      'SILICONFLOW_API_KEY',
      'SILICONFLOW_API_URL',
    ];

    final securityVars = [
      'PASSWORD_SALT',
      'JWT_SECRET',
      'ENCRYPTION_KEY',
    ];

    // 检查必需变量
    for (final varName in requiredVars) {
      if (dotenv.env[varName]?.isEmpty ?? true) {
        debugPrint('Missing required environment variable: $varName');
        return false;
      }
    }

    // 检查安全变量是否使用默认值
    for (final varName in securityVars) {
      final value = dotenv.env[varName] ?? '';
      if (value.isEmpty || value.contains('default_') || value.contains('change_in_production')) {
        debugPrint('Security warning: $varName is using default value. Please set a secure value.');
      }
    }

    return true;
  }

  /// 验证API密钥是否安全
  static bool validateApiKeySecurity() {
    final apiKey = siliconFlowApiKey;
    
    // 检查API密钥是否为空
    if (apiKey.isEmpty) {
      debugPrint('Security Error: API key is empty');
      return false;
    }
    
    // 检查API密钥是否为示例值
    if (apiKey == 'your_api_key_here' || apiKey.contains('example')) {
      debugPrint('Security Error: API key appears to be placeholder');
      return false;
    }
    
    // 检查API密钥长度
    if (apiKey.length < 20) {
      debugPrint('Security Warning: API key seems too short');
      return false;
    }
    
    return true;
  }

  /// 打印配置信息（调试用）
  static void printConfig() {
    if (!debugMode) return;
    
    debugPrint('=== EnvConfig ===');
    debugPrint('API URL: $siliconFlowApiUrl');
    debugPrint('Model: $aiModelName');
    debugPrint('Max Tokens: $aiMaxTokens');
    debugPrint('Temperature: $aiTemperature');
    debugPrint('AI Recommendations: $enableAiRecommendations');
    debugPrint('================');
  }
}

 