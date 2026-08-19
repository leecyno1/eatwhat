import 'package:flutter/foundation.dart' show debugPrint;
import 'package:flutter_dotenv/flutter_dotenv.dart';

/// 环境变量配置管理类
/// 提供统一的环境变量访问接口
class EnvConfig {
  EnvConfig._();

  static const Map<String, String> _dartDefineEnv = {
    'SILICONFLOW_API_KEY': String.fromEnvironment('SILICONFLOW_API_KEY'),
    'SILICONFLOW_API_URL': String.fromEnvironment('SILICONFLOW_API_URL'),
    'MEITUAN_OPEN_BASE_URL': String.fromEnvironment('MEITUAN_OPEN_BASE_URL'),
    'MEITUAN_APP_KEY': String.fromEnvironment('MEITUAN_APP_KEY'),
    'MEITUAN_APP_SECRET': String.fromEnvironment('MEITUAN_APP_SECRET'),
    'MEITUAN_ACCESS_TOKEN': String.fromEnvironment('MEITUAN_ACCESS_TOKEN'),
    'ELEME_OPEN_BASE_URL': String.fromEnvironment('ELEME_OPEN_BASE_URL'),
    'ELEME_APP_KEY': String.fromEnvironment('ELEME_APP_KEY'),
    'ELEME_APP_SECRET': String.fromEnvironment('ELEME_APP_SECRET'),
    'ELEME_ACCESS_TOKEN': String.fromEnvironment('ELEME_ACCESS_TOKEN'),
    'DIANPING_OPEN_BASE_URL': String.fromEnvironment('DIANPING_OPEN_BASE_URL'),
    'DIANPING_APP_KEY': String.fromEnvironment('DIANPING_APP_KEY'),
    'DIANPING_APP_SECRET': String.fromEnvironment('DIANPING_APP_SECRET'),
    'DIANPING_ACCESS_TOKEN': String.fromEnvironment('DIANPING_ACCESS_TOKEN'),
    'EXECUTION_PROXY_BASE_URL':
        String.fromEnvironment('EXECUTION_PROXY_BASE_URL'),
    'EXECUTION_PROXY_AUTH_TOKEN':
        String.fromEnvironment('EXECUTION_PROXY_AUTH_TOKEN'),
    'EXECUTION_PROXY_HEALTH_PATH':
        String.fromEnvironment('EXECUTION_PROXY_HEALTH_PATH'),
    'MEITUAN_DELIVERY_MATCH_PATH':
        String.fromEnvironment('MEITUAN_DELIVERY_MATCH_PATH'),
    'MEITUAN_MERCHANT_SEARCH_PATH':
        String.fromEnvironment('MEITUAN_MERCHANT_SEARCH_PATH'),
    'MEITUAN_PRODUCT_SEARCH_PATH':
        String.fromEnvironment('MEITUAN_PRODUCT_SEARCH_PATH'),
    'MEITUAN_ORDER_PREVIEW_PATH':
        String.fromEnvironment('MEITUAN_ORDER_PREVIEW_PATH'),
    'MEITUAN_ORDER_SUBMIT_PATH':
        String.fromEnvironment('MEITUAN_ORDER_SUBMIT_PATH'),
    'MEITUAN_OAUTH_STATUS_PATH':
        String.fromEnvironment('MEITUAN_OAUTH_STATUS_PATH'),
    'MEITUAN_OAUTH_AUTHORIZE_PATH':
        String.fromEnvironment('MEITUAN_OAUTH_AUTHORIZE_PATH'),
    'MEITUAN_PAYMENT_SUCCESS_URL':
        String.fromEnvironment('MEITUAN_PAYMENT_SUCCESS_URL'),
    'MEITUAN_PAYMENT_FAILURE_URL':
        String.fromEnvironment('MEITUAN_PAYMENT_FAILURE_URL'),
    'ELEME_DELIVERY_MATCH_PATH':
        String.fromEnvironment('ELEME_DELIVERY_MATCH_PATH'),
    'DIANPING_DELIVERY_MATCH_PATH':
        String.fromEnvironment('DIANPING_DELIVERY_MATCH_PATH'),
    'DIANPING_DINE_IN_MATCH_PATH':
        String.fromEnvironment('DIANPING_DINE_IN_MATCH_PATH'),
    'JD_DELIVERY_MATCH_PATH': String.fromEnvironment('JD_DELIVERY_MATCH_PATH'),
    'EATWHAT_AUTH_BASE_URL': String.fromEnvironment('EATWHAT_AUTH_BASE_URL'),
    'PASSWORD_SALT': String.fromEnvironment('PASSWORD_SALT'),
    'JWT_SECRET': String.fromEnvironment('JWT_SECRET'),
    'ENCRYPTION_KEY': String.fromEnvironment('ENCRYPTION_KEY'),
    'AI_MODEL_NAME': String.fromEnvironment('AI_MODEL_NAME'),
    'AI_MAX_TOKENS': String.fromEnvironment('AI_MAX_TOKENS'),
    'AI_TEMPERATURE': String.fromEnvironment('AI_TEMPERATURE'),
    'AI_TOP_P': String.fromEnvironment('AI_TOP_P'),
    'AI_REQUEST_TIMEOUT': String.fromEnvironment('AI_REQUEST_TIMEOUT'),
    'AI_MAX_RETRIES': String.fromEnvironment('AI_MAX_RETRIES'),
    'AI_FALLBACK_MODEL': String.fromEnvironment('AI_FALLBACK_MODEL'),
    'AI_IMAGE_MODEL_NAME': String.fromEnvironment('AI_IMAGE_MODEL_NAME'),
    'AI_IMAGE_MODEL': String.fromEnvironment('AI_IMAGE_MODEL'),
    'MINIMAX_API_KEY': String.fromEnvironment('MINIMAX_API_KEY'),
    'MINIMAX_API_URL': String.fromEnvironment('MINIMAX_API_URL'),
    'MINIMAX_IMAGE_MODEL': String.fromEnvironment('MINIMAX_IMAGE_MODEL'),
    'PREBUILT_IMAGE_INDEX_URL':
        String.fromEnvironment('PREBUILT_IMAGE_INDEX_URL'),
    'PREBUILT_IMAGE_BASE_URL':
        String.fromEnvironment('PREBUILT_IMAGE_BASE_URL'),
    'ENABLE_LIVE_DISH_IMAGE_GENERATION':
        String.fromEnvironment('ENABLE_LIVE_DISH_IMAGE_GENERATION'),
    'APP_VERSION': String.fromEnvironment('APP_VERSION'),
    'DEBUG_MODE': String.fromEnvironment('DEBUG_MODE'),
    'ENABLE_AI_RECOMMENDATIONS':
        String.fromEnvironment('ENABLE_AI_RECOMMENDATIONS'),
    'V2_DEBUG_BOOTSTRAP': String.fromEnvironment('V2_DEBUG_BOOTSTRAP'),
    'AI_CACHE_DURATION': String.fromEnvironment('AI_CACHE_DURATION'),
    'MAX_RECOMMENDATION_CACHE':
        String.fromEnvironment('MAX_RECOMMENDATION_CACHE'),
  };

  static String _readEnv(String key, {String fallback = ''}) {
    final fromDartDefine = _dartDefineEnv[key] ?? '';
    if (fromDartDefine.isNotEmpty) {
      return fromDartDefine;
    }

    if (dotenv.isInitialized) {
      final fromDotenv = dotenv.env[key];
      if (fromDotenv != null && fromDotenv.isNotEmpty) {
        return fromDotenv;
      }
    }

    return fallback;
  }

  /// 初始化环境配置
  static Future<void> init() async {
    try {
      await dotenv.load(isOptional: true);
      debugPrint('Environment configuration loaded successfully');
    } catch (e) {
      debugPrint('Warning: Failed to load .env file: $e');
      debugPrint('Continuing with dart-define/default configuration...');
    }
  }

  // AI服务配置
  static String get siliconFlowApiKey => _readEnv('SILICONFLOW_API_KEY');

  static String get siliconFlowApiUrl => _readEnv('SILICONFLOW_API_URL',
      fallback: 'https://api.siliconflow.cn/v1');

  // 平台开放 API（到店/外卖）
  static String get meituanOpenBaseUrl => _readEnv('MEITUAN_OPEN_BASE_URL');
  static String get meituanAppKey => _readEnv('MEITUAN_APP_KEY');
  static String get meituanAppSecret => _readEnv('MEITUAN_APP_SECRET');
  static String get meituanAccessToken => _readEnv('MEITUAN_ACCESS_TOKEN');

  static String get elemeOpenBaseUrl => _readEnv('ELEME_OPEN_BASE_URL');
  static String get elemeAppKey => _readEnv('ELEME_APP_KEY');
  static String get elemeAppSecret => _readEnv('ELEME_APP_SECRET');
  static String get elemeAccessToken => _readEnv('ELEME_ACCESS_TOKEN');

  static String get dianpingOpenBaseUrl => _readEnv('DIANPING_OPEN_BASE_URL');
  static String get dianpingAppKey => _readEnv('DIANPING_APP_KEY');
  static String get dianpingAppSecret => _readEnv('DIANPING_APP_SECRET');
  static String get dianpingAccessToken => _readEnv('DIANPING_ACCESS_TOKEN');

  static String get executionProxyBaseUrl =>
      _readEnv('EXECUTION_PROXY_BASE_URL');

  static String get executionProxyAuthToken =>
      _readEnv('EXECUTION_PROXY_AUTH_TOKEN');

  static String get eatWhatAuthBaseUrl => _readEnv('EATWHAT_AUTH_BASE_URL');

  static String get executionProxyHealthPath => _readEnv(
        'EXECUTION_PROXY_HEALTH_PATH',
        fallback: '/health',
      );

  static String get meituanDeliveryMatchPath => _readEnv(
        'MEITUAN_DELIVERY_MATCH_PATH',
        fallback: '/v2/execution/meituan/delivery-match',
      );

  static String get meituanMerchantSearchPath => _readEnv(
        'MEITUAN_MERCHANT_SEARCH_PATH',
        fallback: '/api/v1/delivery/merchants/search',
      );

  static String get meituanProductSearchPath => _readEnv(
        'MEITUAN_PRODUCT_SEARCH_PATH',
        fallback: '/api/v1/delivery/products/search',
      );

  static String get meituanOrderPreviewPath => _readEnv(
        'MEITUAN_ORDER_PREVIEW_PATH',
        fallback: '/api/v1/delivery/order-previews',
      );

  static String get meituanOrderSubmitPath => _readEnv(
        'MEITUAN_ORDER_SUBMIT_PATH',
        fallback: '/api/v1/delivery/orders',
      );

  static String get meituanOAuthStatusPath => _readEnv(
        'MEITUAN_OAUTH_STATUS_PATH',
        fallback: '/api/v1/delivery/oauth/status',
      );

  static String get meituanOAuthAuthorizePath => _readEnv(
        'MEITUAN_OAUTH_AUTHORIZE_PATH',
        fallback: '/api/v1/delivery/oauth/authorize',
      );

  static String get meituanPaymentSuccessUrl =>
      _readEnv('MEITUAN_PAYMENT_SUCCESS_URL');

  static String get meituanPaymentFailureUrl =>
      _readEnv('MEITUAN_PAYMENT_FAILURE_URL');

  static String get elemeDeliveryMatchPath => _readEnv(
        'ELEME_DELIVERY_MATCH_PATH',
        fallback: '/v2/execution/eleme/delivery-match',
      );

  static String get dianpingDeliveryMatchPath => _readEnv(
        'DIANPING_DELIVERY_MATCH_PATH',
        fallback: '/v2/execution/dianping/delivery-match',
      );

  static String get dianpingDineInMatchPath => _readEnv(
        'DIANPING_DINE_IN_MATCH_PATH',
        fallback: '/v2/execution/dianping/dine-in-match',
      );

  static String get jdDeliveryMatchPath => _readEnv(
        'JD_DELIVERY_MATCH_PATH',
        fallback: '/v2/execution/jd-delivery/delivery-match',
      );

  // 安全配置
  static String get passwordSalt =>
      _readEnv('PASSWORD_SALT', fallback: 'default_salt_change_in_production');

  static String get jwtSecret => _readEnv('JWT_SECRET',
      fallback: 'default_jwt_secret_change_in_production');

  static String get encryptionKey => _readEnv(
        'ENCRYPTION_KEY',
        fallback: 'default_encryption_key_change_in_production',
      );

  // AI模型配置
  static String get aiModelName =>
      _readEnv('AI_MODEL_NAME', fallback: 'MiniMax-M2.7');

  static int get aiMaxTokens =>
      int.tryParse(_readEnv('AI_MAX_TOKENS', fallback: '2048')) ?? 2048;

  static double get aiTemperature =>
      double.tryParse(_readEnv('AI_TEMPERATURE', fallback: '0.7')) ?? 0.7;

  static double get aiTopP =>
      double.tryParse(_readEnv('AI_TOP_P', fallback: '0.9')) ?? 0.9;

  static int get aiRequestTimeoutSeconds =>
      int.tryParse(_readEnv('AI_REQUEST_TIMEOUT', fallback: '30')) ?? 30;

  static int get aiMaxRetries =>
      int.tryParse(_readEnv('AI_MAX_RETRIES', fallback: '3')) ?? 3;

  static String get aiFallbackModel =>
      _readEnv('AI_FALLBACK_MODEL', fallback: 'MiniMax-M2.7');

  static String get aiImageModelName =>
      _readEnv('AI_IMAGE_MODEL_NAME').isNotEmpty
          ? _readEnv('AI_IMAGE_MODEL_NAME')
          : _readEnv('AI_IMAGE_MODEL');

  static String get minimaxApiKey => _readEnv('MINIMAX_API_KEY');

  static String get minimaxApiUrl => _readEnv(
        'MINIMAX_API_URL',
        fallback: 'https://api.minimax.io/v1/image_generation',
      );

  static String get minimaxImageModel =>
      _readEnv('MINIMAX_IMAGE_MODEL', fallback: 'image-01');

  /// MiniMax OpenAI-compatible chat endpoint used for all text generation
  /// (recommendation refinement, intros, summaries).
  static String get minimaxChatApiUrl => _readEnv(
        'MINIMAX_CHAT_API_URL',
        fallback: 'https://api.minimaxi.com/v1',
      );

  static String get minimaxChatModel =>
      _readEnv('MINIMAX_CHAT_MODEL', fallback: 'MiniMax-M2.7');

  static String get prebuiltImageIndexUrl =>
      _readEnv('PREBUILT_IMAGE_INDEX_URL');

  static String get prebuiltImageBaseUrl => _readEnv('PREBUILT_IMAGE_BASE_URL');

  static bool get enableLiveDishImageGeneration =>
      _readEnv('ENABLE_LIVE_DISH_IMAGE_GENERATION').toLowerCase() == 'true';

  // 应用配置
  static String get appVersion => _readEnv('APP_VERSION', fallback: '1.0.0');

  static bool get debugMode => _readEnv('DEBUG_MODE').toLowerCase() == 'true';

  static bool get enableAiRecommendations =>
      _readEnv('ENABLE_AI_RECOMMENDATIONS').toLowerCase() == 'true';

  static String get v2DebugBootstrap =>
      _readEnv('V2_DEBUG_BOOTSTRAP', fallback: 'home').trim().toLowerCase();

  // 缓存配置
  static int get aiCacheDuration =>
      int.tryParse(_readEnv('AI_CACHE_DURATION', fallback: '300')) ?? 300;

  /// AI 缓存有效期（推荐用这个）
  ///
  /// `.env.example` 里 `AI_CACHE_DURATION` 的注释是“小时”，因此这里按小时解析。
  /// 如果你希望用秒级控制，请新增独立字段，避免歧义。
  static Duration get aiCacheMaxAge {
    final raw = _readEnv('AI_CACHE_DURATION', fallback: '24');
    final hours = int.tryParse(raw) ?? 24;
    return Duration(hours: hours.clamp(1, 24 * 30));
  }

  static int get maxRecommendationCache =>
      int.tryParse(_readEnv('MAX_RECOMMENDATION_CACHE', fallback: '50')) ?? 50;

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
      if (_readEnv(varName).isEmpty) {
        debugPrint('Missing required environment variable: $varName');
        return false;
      }
    }

    // 检查安全变量是否使用默认值
    for (final varName in securityVars) {
      final value = _readEnv(varName);
      if (value.isEmpty ||
          value.contains('default_') ||
          value.contains('change_in_production')) {
        debugPrint(
            'Security warning: $varName is using default value. Please set a secure value.');
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

  static bool get openPlatformSecretsPresent {
    final meituanOk = meituanOpenBaseUrl.isNotEmpty &&
        meituanAppKey.isNotEmpty &&
        meituanAppSecret.isNotEmpty &&
        meituanAccessToken.isNotEmpty;
    final elemeOk = elemeOpenBaseUrl.isNotEmpty &&
        elemeAppKey.isNotEmpty &&
        elemeAppSecret.isNotEmpty &&
        elemeAccessToken.isNotEmpty;
    final dianpingOk = dianpingOpenBaseUrl.isNotEmpty &&
        dianpingAppKey.isNotEmpty &&
        dianpingAppSecret.isNotEmpty &&
        dianpingAccessToken.isNotEmpty;

    return meituanOk || elemeOk || dianpingOk;
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
    debugPrint('Open Platform Configured: $openPlatformSecretsPresent');
    debugPrint('================');
  }
}
