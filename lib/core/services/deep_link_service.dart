import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:eatwhat_app/core/models/cart_item.dart';

/// 配送平台枚举
enum DeliveryPlatform {
  meituan('meituan', '美团外卖', 'meituan://', 'https://i.meituan.com/search'),
  eleme('eleme', '饿了么', 'ele://', 'https://h5.ele.me/search'),
  dianping('dianping', '大众点评', 'dianping://', 'https://m.dianping.com/search');

  final String code;
  final String displayName;
  final String urlScheme;
  final String h5BaseUrl;

  const DeliveryPlatform(this.code, this.displayName, this.urlScheme, this.h5BaseUrl);

  static DeliveryPlatform? fromCode(String code) {
    return DeliveryPlatform.values.cast<DeliveryPlatform?>().firstWhere(
      (p) => p?.code == code,
      orElse: () => null,
    );
  }
}

/// 深度链接服务
///
/// 提供跨平台外卖App深度链接生成和跳转功能，支持：
/// - App安装检测
/// - 深度链接生成（App URL Scheme）
/// - H5降级方案
/// - 购物车预填
class DeepLinkService {
  static final DeepLinkService _instance = DeepLinkService._internal();
  factory DeepLinkService() => _instance;
  DeepLinkService._internal();

  static const _channel = MethodChannel('app.channel.platform');

  /// 检测指定平台 App 是否已安装
  Future<bool> isAppInstalled(DeliveryPlatform platform) async {
    try {
      final scheme = platform.urlScheme;
      final uri = Uri.parse(scheme);

      // 使用 url_launcher 的 canLaunchUrl 检测
      final canLaunch = await canLaunchUrl(uri);
      if (canLaunch) {
        debugPrint('[DeepLinkService] ${platform.displayName} App 已安装');
        return true;
      }

      // 备用方案：尝试通过平台特定方法检测
      final result = await _channel.invokeMethod<bool>('isAppInstalled', {
        'platform': platform.code,
      }).catchError((_) => false);

      debugPrint('[DeepLinkService] ${platform.displayName} App 安装状态: $result');
      return result ?? false;
    } catch (e) {
      debugPrint('[DeepLinkService] 检测 ${platform.displayName} 安装状态失败: $e');
      return false;
    }
  }

  /// 生成深度链接
  ///
  /// 根据平台和商品列表生成对应的深度链接
  /// 如果无法生成App链接，返回H5降级链接
  Future<String> generateDeepLink(
    DeliveryPlatform platform,
    List<CartItem> items,
  ) async {
    if (items.isEmpty) {
      throw ArgumentError('商品列表不能为空');
    }

    try {
      final keyword = _buildSearchKeyword(items);
      final link = _buildPlatformDeepLink(platform, keyword, items);
      debugPrint('[DeepLinkService] 生成 ${platform.displayName} 深度链接: $link');
      return link;
    } catch (e) {
      debugPrint('[DeepLinkService] 生成深度链接失败，降级到H5: $e');
      return getH5Url(platform, items);
    }
  }

  /// 构建搜索关键词
  String _buildSearchKeyword(List<CartItem> items) {
    if (items.isEmpty) return '';

    // 如果只有一件商品，直接用商品名称
    if (items.length == 1) {
      return items.first.name;
    }

    // 多件商品用第一个商品名称 + "等"
    return '${items.first.name}等${items.length}件';
  }

  /// 构建平台深度链接
  String _buildPlatformDeepLink(
    DeliveryPlatform platform,
    String keyword,
    List<CartItem> items,
  ) {
    switch (platform) {
      case DeliveryPlatform.meituan:
        return _buildMeituanLink(keyword, items);
      case DeliveryPlatform.eleme:
        return _buildElemeLink(keyword, items);
      case DeliveryPlatform.dianping:
        return _buildDianpingLink(keyword, items);
    }
  }

  /// 构建美团深度链接
  /// 格式: meituan://www.meituan.com/search?keyword=xxx
  String _buildMeituanLink(String keyword, List<CartItem> items) {
    final encodedKeyword = Uri.encodeComponent(keyword);
    // 美团App URL Scheme
    final appLink = 'meituan://www.meituan.com/search?keyword=$encodedKeyword';

    // 如果支持预填，添加商品信息
    if (items.length == 1) {
      final item = items.first;
      final productId = item.foodId;
      if (productId.isNotEmpty) {
        return '$appLink&product_id=$productId';
      }
    }

    return appLink;
  }

  /// 构建饿了么深度链接
  /// 格式: ele://search?keyword=xxx 或 taobao:// 跳转淘宝/饿了么
  String _buildElemeLink(String keyword, List<CartItem> items) {
    final encodedKeyword = Uri.encodeComponent(keyword);

    // 饿了么主要使用淘宝/支付宝Scheme跳转
    // ele:// URL Scheme 可能不完全支持所有功能
    final appLink = 'ele://search?query=$encodedKeyword';

    // 备用方案：淘宝Scheme (保留用于降级)
    // final taobaoLink = 'taobao://s.taobao.com/search?q=$encodedKeyword';

    // 优先使用饿了么Scheme
    return appLink;
  }

  /// 构建大众点评深度链接
  /// 格式: dianping://search?keyword=xxx
  String _buildDianpingLink(String keyword, List<CartItem> items) {
    final encodedKeyword = Uri.encodeComponent(keyword);
    final appLink = 'dianping://search?keyword=$encodedKeyword';

    if (items.length == 1) {
      final item = items.first;
      final productId = item.foodId;
      if (productId.isNotEmpty) {
        return '$appLink&shopid=$productId';
      }
    }

    return appLink;
  }

  /// 获取H5降级链接
  String getH5Url(DeliveryPlatform platform, List<CartItem> items) {
    if (items.isEmpty) {
      return platform.h5BaseUrl;
    }

    final keyword = _buildSearchKeyword(items);
    final encodedKeyword = Uri.encodeComponent(keyword);

    switch (platform) {
      case DeliveryPlatform.meituan:
        return '${platform.h5BaseUrl}?keyword=$encodedKeyword';
      case DeliveryPlatform.eleme:
        return '${platform.h5BaseUrl}?query=$encodedKeyword';
      case DeliveryPlatform.dianping:
        return '${platform.h5BaseUrl}?keyword=$encodedKeyword';
    }
  }

  /// 跳转并预填购物车
  ///
  /// [platform] 目标平台
  /// [items] 商品列表
  /// [forceH5] 是否强制使用H5（跳过App检测）
  ///
  /// 返回是否成功跳转（App安装且成功打开返回true，H5降级返回false）
  Future<bool> openPlatformWithCart(
    DeliveryPlatform platform,
    List<CartItem> items, {
    bool forceH5 = false,
  }) async {
    if (items.isEmpty) {
      throw ArgumentError('商品列表不能为空');
    }

    try {
      String link;
      bool usedApp = false;

      if (forceH5) {
        link = getH5Url(platform, items);
        debugPrint('[DeepLinkService] 强制使用H5: $link');
      } else if (await isAppInstalled(platform)) {
        // App已安装，尝试打开App
        link = await generateDeepLink(platform, items);
        usedApp = true;
        debugPrint('[DeepLinkService] 使用App深度链接: $link');
      } else {
        // App未安装，降级到H5
        link = getH5Url(platform, items);
        debugPrint('[DeepLinkService] App未安装，降级到H5: $link');
      }

      // 跳转
      final uri = Uri.parse(link);
      final launched = await launchUrl(
        uri,
        mode: usedApp ? LaunchMode.externalApplication : LaunchMode.inAppWebView,
      ).timeout(
        const Duration(seconds: 3),
        onTimeout: () {
          debugPrint('[DeepLinkService] 跳转超时');
          return false;
        },
      );

      if (!launched) {
        // 跳转失败，尝试H5降级
        debugPrint('[DeepLinkService] App跳转失败，尝试H5降级');
        link = getH5Url(platform, items);
        await launchUrl(
          Uri.parse(link),
          mode: LaunchMode.inAppWebView,
        );
        return false;
      }

      return usedApp;
    } catch (e) {
      debugPrint('[DeepLinkService] 跳转失败: $e');
      // 发生异常，尝试H5降级
      final h5Url = getH5Url(platform, items);
      try {
        await launchUrl(
          Uri.parse(h5Url),
          mode: LaunchMode.inAppWebView,
        );
      } catch (_) {}
      return false;
    }
  }

  /// 批量检测多个平台的App安装状态
  Future<Map<DeliveryPlatform, bool>> checkPlatformsAvailability() async {
    final results = <DeliveryPlatform, bool>{};

    for (final platform in DeliveryPlatform.values) {
      results[platform] = await isAppInstalled(platform);
    }

    return results;
  }

  /// 获取已安装的平台列表
  Future<List<DeliveryPlatform>> getInstalledPlatforms() async {
    final availability = await checkPlatformsAvailability();
    return availability.entries
        .where((e) => e.value)
        .map((e) => e.key)
        .toList();
  }
}
