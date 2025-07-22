/// API配置类 - 统一管理所有外卖平台API配置
class ApiConfig {
  ApiConfig._();

  // 基础配置
  static const String version = 'v1';
  static const bool useMockData = true; // 开发阶段使用模拟数据
  static const int mockDataDelay = 800; // 模拟网络延迟(ms)
  
  // 网络配置
  static const int connectTimeout = 15000; // 连接超时(ms)
  static const int receiveTimeout = 20000; // 接收超时(ms)
  static const int sendTimeout = 15000; // 发送超时(ms)
  
  // 缓存配置
  static const int cacheMaxAge = 300; // 缓存时间(秒)
  static const int maxCacheSize = 100; // 最大缓存条目数
  
  // 美团API配置
  static const String meiTuanBaseUrl = 'https://api.meituan.com';
  static const String meiTuanAppKey = 'your_meituan_app_key';
  static const String meiTuanAppSecret = 'your_meituan_app_secret';
  
  // 饿了么API配置
  static const String elemeBaseUrl = 'https://open-api.shop.ele.me';
  static const String elemeAppKey = 'your_eleme_app_key';
  static const String elemeAppSecret = 'your_eleme_app_secret';
  
  // API路径
  static const String restaurantSearchPath = '/restaurants/search';
  static const String menuPath = '/restaurants/menu';
  static const String orderPath = '/orders';
  static const String userPath = '/users';
  
  // 请求头
  static Map<String, String> get defaultHeaders => {
    'Content-Type': 'application/json',
    'Accept': 'application/json',
    'User-Agent': 'EatWhat-App/$version',
    'X-App-Version': version,
  };
  
  static Map<String, String> get meiTuanHeaders => {
    ...defaultHeaders,
    'X-MeiTuan-AppKey': meiTuanAppKey,
    'X-Platform': 'meituan',
  };
  
  static Map<String, String> get elemeHeaders => {
    ...defaultHeaders,
    'X-Eleme-AppKey': elemeAppKey,
    'X-Platform': 'eleme',
  };
  
  // 获取平台基础URL
  static String getBaseUrlForPlatform(String platform) {
    switch (platform.toLowerCase()) {
      case 'meituan':
        return meiTuanBaseUrl;
      case 'eleme':
        return elemeBaseUrl;
      default:
        return 'https://mock-api.eatwhat.com'; // 模拟API地址
    }
  }
  
  // 获取平台请求头
  static Map<String, String> getHeadersForPlatform(String platform) {
    switch (platform.toLowerCase()) {
      case 'meituan':
        return meiTuanHeaders;
      case 'eleme':
        return elemeHeaders;
      default:
        return defaultHeaders;
    }
  }
  
  // 构建完整API URL
  static String buildApiUrl(String platform, String path) {
    final baseUrl = getBaseUrlForPlatform(platform);
    return '$baseUrl/$version$path';
  }
  
  // 地理位置配置
  static const double defaultLatitude = 39.9042; // 北京天安门
  static const double defaultLongitude = 116.4074;
  static const double maxSearchRadius = 10000; // 最大搜索半径(米)
  static const double minSearchRadius = 500; // 最小搜索半径(米)
  
  // 分页配置
  static const int defaultPageSize = 20;
  static const int maxPageSize = 50;
  static const int minPageSize = 5;
  
  // 错误码映射
  static const Map<int, String> errorMessages = {
    400: '请求参数错误',
    401: '未授权访问',
    403: '访问被禁止',
    404: '资源不存在',
    429: '请求过于频繁',
    500: '服务器内部错误',
    502: '网关错误',
    503: '服务不可用',
    504: '网关超时',
  };
  
  // 获取错误信息
  static String getErrorMessage(int statusCode) {
    return errorMessages[statusCode] ?? '网络请求失败($statusCode)';
  }
  
  // 重试配置
  static const int maxRetryAttempts = 3;
  static const int retryDelayMs = 1000;
  static const List<int> retryableStatusCodes = [408, 429, 500, 502, 503, 504];
  
  // 是否可重试的状态码
  static bool isRetryableStatusCode(int statusCode) {
    return retryableStatusCodes.contains(statusCode);
  }
  
  // 调试配置
  static const bool enableLogging = true;
  static const bool enableNetworkLogging = true;
  static const bool enableCacheLogging = false;
}
