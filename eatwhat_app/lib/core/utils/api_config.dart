/// API配置管理类
/// 管理美团外卖和饿了么的API密钥和配置信息
class ApiConfig {
  // 美团外卖API配置
  final String meiTuanAppId;
  final String meiTuanAppSecret;
  
  // 饿了么API配置
  final String elemeAppKey;
  final String elemeAppSecret;
  
  // 请求配置
  final Duration requestTimeout;
  final int maxRetries;
  final bool enableLogging;
  
  const ApiConfig({
    this.meiTuanAppId = '',
    this.meiTuanAppSecret = '',
    this.elemeAppKey = '',
    this.elemeAppSecret = '',
    this.requestTimeout = const Duration(seconds: 10),
    this.maxRetries = 3,
    this.enableLogging = true,
  });
  
  /// 开发环境配置
  factory ApiConfig.development() {
    return const ApiConfig(
      meiTuanAppId: 'dev_meituan_app_id',
      meiTuanAppSecret: 'dev_meituan_app_secret',
      elemeAppKey: 'dev_eleme_app_key',
      elemeAppSecret: 'dev_eleme_app_secret',
      requestTimeout: Duration(seconds: 15),
      maxRetries: 2,
      enableLogging: true,
    );
  }
  
  /// 生产环境配置
  factory ApiConfig.production() {
    return const ApiConfig(
      meiTuanAppId: 'prod_meituan_app_id',
      meiTuanAppSecret: 'prod_meituan_app_secret',
      elemeAppKey: 'prod_eleme_app_key',
      elemeAppSecret: 'prod_eleme_app_secret',
      requestTimeout: Duration(seconds: 10),
      maxRetries: 3,
      enableLogging: false,
    );
  }
  
  /// 从环境变量加载配置
  factory ApiConfig.fromEnvironment() {
    return ApiConfig(
      meiTuanAppId: const String.fromEnvironment('MEITUAN_APP_ID', defaultValue: ''),
      meiTuanAppSecret: const String.fromEnvironment('MEITUAN_APP_SECRET', defaultValue: ''),
      elemeAppKey: const String.fromEnvironment('ELEME_APP_KEY', defaultValue: ''),
      elemeAppSecret: const String.fromEnvironment('ELEME_APP_SECRET', defaultValue: ''),
    );
  }
  
  /// 验证配置是否完整
  bool get isValid {
    return meiTuanAppId.isNotEmpty && 
           meiTuanAppSecret.isNotEmpty &&
           elemeAppKey.isNotEmpty &&
           elemeAppSecret.isNotEmpty;
  }
  
  /// 验证美团配置
  bool get isMeiTuanConfigValid {
    return meiTuanAppId.isNotEmpty && meiTuanAppSecret.isNotEmpty;
  }
  
  /// 验证饿了么配置
  bool get isElemeConfigValid {
    return elemeAppKey.isNotEmpty && elemeAppSecret.isNotEmpty;
  }
  
  /// 复制并修改配置
  ApiConfig copyWith({
    String? meiTuanAppId,
    String? meiTuanAppSecret,
    String? elemeAppKey,
    String? elemeAppSecret,
    Duration? requestTimeout,
    int? maxRetries,
    bool? enableLogging,
  }) {
    return ApiConfig(
      meiTuanAppId: meiTuanAppId ?? this.meiTuanAppId,
      meiTuanAppSecret: meiTuanAppSecret ?? this.meiTuanAppSecret,
      elemeAppKey: elemeAppKey ?? this.elemeAppKey,
      elemeAppSecret: elemeAppSecret ?? this.elemeAppSecret,
      requestTimeout: requestTimeout ?? this.requestTimeout,
      maxRetries: maxRetries ?? this.maxRetries,
      enableLogging: enableLogging ?? this.enableLogging,
    );
  }
  
  @override
  String toString() {
    return 'ApiConfig(';
        'meiTuanAppId: ${meiTuanAppId.isNotEmpty ? '***' : 'empty'}, '
        'meiTuanAppSecret: ${meiTuanAppSecret.isNotEmpty ? '***' : 'empty'}, '
        'elemeAppKey: ${elemeAppKey.isNotEmpty ? '***' : 'empty'}, '
        'elemeAppSecret: ${elemeAppSecret.isNotEmpty ? '***' : 'empty'}, '
        'requestTimeout: $requestTimeout, '
        'maxRetries: $maxRetries, '
        'enableLogging: $enableLogging'
        ')';
  }
}