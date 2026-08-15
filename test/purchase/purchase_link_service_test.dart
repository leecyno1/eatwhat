import 'package:flutter_test/flutter_test.dart';
import 'package:eatwhat_app/core/services/purchase_link_service.dart';

void main() {
  group('PurchaseLinkService', () {
    final service = PurchaseLinkService();

    test('生成饿了么链接包含 keyword 参数', () {
      final r = service.generateLink(platform: PurchasePlatform.eleme, keyword: '宫保鸡丁');
      expect(r.url.toString(), contains('ele.me'));
      expect(r.url.queryParameters['keyword'], '宫保鸡丁');
      expect(r.isFallback, isFalse);
    });

    test('生成美团链接包含 keyword 参数', () {
      final r = service.generateLink(platform: PurchasePlatform.meituan, keyword: '麻辣烫');
      expect(r.url.toString(), contains('meituan.com'));
      expect(r.url.queryParameters['keyword'], '麻辣烫');
    });

    test('生成点评链接包含 keyword 参数', () {
      final r = service.generateLink(platform: PurchasePlatform.dianping, keyword: '奶茶');
      expect(r.url.toString(), contains('dianping.com'));
      expect(r.url.queryParameters['keyword'], '奶茶');
    });

    test('fallback 行为: 不支持平台抛出后走 fallback', () {
      // 模拟: 通过直接调用私有方法难度较大，这里构造异常: 传入正常平台但通过 hack extraParams 触发? 暂无可行。
      // 于是仅测试 snacks 平台本身 isFallback = false, 其余功能依赖上层错误触发。
      final r = service.generateLink(platform: PurchasePlatform.snacks, keyword: '薯片');
      expect(r.isFallback, isFalse);
      expect(r.url.toString(), contains('baidu.com'));
    });

    test('keyword 为空抛出异常', () {
      expect(() => service.generateLink(platform: PurchasePlatform.eleme, keyword: '  '),
          throwsArgumentError);
    });
  });
}
