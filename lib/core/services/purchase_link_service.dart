// Removed unused import 'dart:convert';

/// 支持的平台类型
enum PurchasePlatform { eleme, meituan, dianping, snacks }

/// 购买/跳转链接生成结果
class PurchaseLinkResult {
  final String platform;
  final String keyword;
  final Uri url;
  final bool isFallback;
  final DateTime generatedAt;
  final Map<String, dynamic> meta;

  PurchaseLinkResult({
    required this.platform,
    required this.keyword,
    required this.url,
    required this.isFallback,
    required this.generatedAt,
    this.meta = const {},
  });
}

/// 购买跳转服务
/// 目标：为外卖/点评/零食(通用) 生成深链接或搜索链接。
/// 说明：真实 App 中不同平台会有各自 URL Scheme / H5 路径，
/// 此处构造统一抽象，便于后续集成或替换成实际 scheme。
class PurchaseLinkService {
  static final PurchaseLinkService _instance = PurchaseLinkService._internal();
  factory PurchaseLinkService() => _instance;
  PurchaseLinkService._internal();

  /// 平台基础 URL / Scheme 占位
  /// 真实项目可替换为：eleme://food_search?keyword=xxx
  static const Map<PurchasePlatform, String> _platformBase = {
    PurchasePlatform.eleme: 'https://h5.ele.me/search',
    PurchasePlatform.meituan: 'https://i.meituan.com/search',
    PurchasePlatform.dianping: 'https://m.dianping.com/search',
    PurchasePlatform.snacks: 'https://www.baidu.com/s', // 通用搜索占位
  };

  /// 生成链接（自动根据平台构建 URL）
  PurchaseLinkResult generateLink({
    required PurchasePlatform platform,
    required String keyword,
    Map<String, String>? extraParams,
    bool enableFallback = true,
  }) {
    final sanitized = keyword.trim();
    if (sanitized.isEmpty) {
      throw ArgumentError('keyword 不能为空');
    }

    try {
      final url = _buildPlatformUrl(platform, sanitized, extraParams: extraParams);
      return PurchaseLinkResult(
        platform: platform.name,
        keyword: sanitized,
        url: url,
        isFallback: false,
        generatedAt: DateTime.now(),
      );
    } catch (e) {
      if (!enableFallback) rethrow;
      final fallback = _fallbackSearch(keyword: sanitized);
      return fallback.copyWith(meta: {
        'error': e.toString(),
        'originalPlatform': platform.name,
      });
    }
  }

  /// 构建平台 URL
  Uri _buildPlatformUrl(PurchasePlatform platform, String keyword,
      {Map<String, String>? extraParams}) {
    final base = _platformBase[platform];
    if (base == null) {
      throw UnsupportedError('未支持的平台: ${platform.name}');
    }
    final params = <String, String>{
      'keyword': keyword,
      ...?extraParams,
    };

    return Uri.parse(base).replace(queryParameters: params);
  }

  /// 回退通用搜索 (默认使用 Baidu)
  PurchaseLinkResult _fallbackSearch({required String keyword}) {
    final uri = Uri.parse(_platformBase[PurchasePlatform.snacks]!).replace(
      queryParameters: {
        'wd': keyword,
        'from': 'fallback',
      },
    );
    return PurchaseLinkResult(
      platform: PurchasePlatform.snacks.name,
      keyword: keyword,
      url: uri,
      isFallback: true,
      generatedAt: DateTime.now(),
    );
  }
}

extension on PurchaseLinkResult {
  PurchaseLinkResult copyWith({
    String? platform,
    String? keyword,
    Uri? url,
    bool? isFallback,
    DateTime? generatedAt,
    Map<String, dynamic>? meta,
  }) {
    return PurchaseLinkResult(
      platform: platform ?? this.platform,
      keyword: keyword ?? this.keyword,
      url: url ?? this.url,
      isFallback: isFallback ?? this.isFallback,
      generatedAt: generatedAt ?? this.generatedAt,
      meta: meta ?? this.meta,
    );
  }
}
