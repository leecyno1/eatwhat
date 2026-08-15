import 'package:url_launcher/url_launcher.dart';

typedef PlatformUrlLauncher = Future<bool> Function(Uri uri);

class V2PlatformJumpService {
  const V2PlatformJumpService({PlatformUrlLauncher? launcher})
      : _launcher = launcher ?? _launch;

  final PlatformUrlLauncher _launcher;

  Future<bool> openMeituanDelivery(String dishName) {
    final keyword = _keyword(dishName);
    return _openFirst([
      Uri(
        scheme: 'meituanwaimai',
        host: 'waimai.meituan.com',
        path: '/search',
        queryParameters: {'query': keyword},
      ),
      Uri.https(
        'h5.waimai.meituan.com',
        '/waimai/mindex/search',
        {'keyword': keyword},
      ),
    ]);
  }

  Future<bool> openDianpingDineIn(String dishName) {
    final keyword = _keyword(dishName);
    final encoded = Uri.encodeComponent(keyword);
    return _openFirst([
      Uri.parse(
        'dianping://searchshoplist?keyword=${Uri.encodeComponent(keyword)}',
      ),
      Uri.parse('https://m.dianping.com/search/keyword/1/0_$encoded'),
      Uri.https('maps.apple.com', '/', {'q': keyword}),
    ]);
  }

  Future<bool> _openFirst(List<Uri> urls) async {
    for (final uri in urls) {
      if (await _launcher(uri)) return true;
    }
    return false;
  }

  static Future<bool> _launch(Uri uri) {
    return launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  String _keyword(String value) {
    final keyword = value.trim();
    return keyword.isEmpty ? '附近美食' : keyword;
  }
}
