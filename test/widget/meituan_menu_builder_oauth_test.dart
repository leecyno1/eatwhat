import 'package:eatwhat_app/v2/core/data/models/recipe_model.dart';
import 'package:eatwhat_app/v2/core/external/platform/meituan_delivery_order_client.dart';
import 'package:eatwhat_app/v2/core/external/platform/platform_exceptions.dart';
import 'package:eatwhat_app/v2/core/external/platform/platform_types.dart';
import 'package:eatwhat_app/v2/features/execution/meituan_menu_builder_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/url_launcher'),
      (call) async => true,
    );
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(
      const MethodChannel('plugins.flutter.io/url_launcher'),
      null,
    );
  });

  testWidgets('授权回前台未连接时显性提示授权未完成', (tester) async {
    final client = _FakeMenuBuilderClient(authorizedOnReturn: false);
    await tester.pumpWidget(_page(client));
    await tester.pumpAndSettle();

    expect(find.text('首次点单需要绑定美团配送服务'), findsOneWidget);

    await tester.tap(find.text('一次授权，继续点单'));
    await tester.pumpAndSettle();

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();

    expect(
      find.text('授权未完成：请在美团授权页点「同意授权」；若授权页空白打不开，请返回后重试'),
      findsOneWidget,
    );
    // 仍停留在授权引导态，可重试。
    expect(find.text('首次点单需要绑定美团配送服务'), findsOneWidget);
  });

  testWidgets('授权回前台已连接则直接继续搜索门店', (tester) async {
    final client = _FakeMenuBuilderClient(authorizedOnReturn: true);
    await tester.pumpWidget(_page(client));
    await tester.pumpAndSettle();

    expect(find.text('首次点单需要绑定美团配送服务'), findsOneWidget);
    await tester.tap(find.text('一次授权，继续点单'));
    await tester.pumpAndSettle();

    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
    tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
    await tester.pumpAndSettle();

    expect(
      find.text('授权未完成：请在美团授权页点「同意授权」；若授权页空白打不开，请返回后重试'),
      findsNothing,
    );
    expect(find.text('锅气食堂'), findsOneWidget);
  });
}

Widget _page(_FakeMenuBuilderClient client) {
  return MaterialApp(
    home: MeituanMenuBuilderPage(
      intent: const ExecutionIntent(
        recipe: RecipeModel(
          id: 'r1',
          name: '麻婆豆腐',
          description: '麻辣下饭',
        ),
        pairings: [],
        sourceTags: ['麻辣'],
      ),
      client: client,
      locationResolver: () async =>
          const GeoPoint(latitude: 39.9042, longitude: 116.4074),
    ),
  );
}

class _FakeMenuBuilderClient extends MeituanDeliveryOrderClient {
  _FakeMenuBuilderClient({required this.authorizedOnReturn});

  /// 用户从外部浏览器回来时授权是否已完成。初始一律未连接（首搜必走
  /// 授权引导态）；调用 createOAuthAuthorizationUri 代表已跳去授权页，
  /// 仅当 authorizedOnReturn 为真时，此后状态查询才报已连接。
  final bool authorizedOnReturn;
  bool _connected = false;
  var searchCount = 0;

  @override
  bool get isConfigured => true;

  @override
  Future<MeituanMerchantSearchResult> searchMerchantResults({
    required String keyword,
    required GeoPoint location,
    int limit = 20,
  }) async {
    searchCount++;
    if (!_connected) {
      throw PlatformApiException('meituan', '需要完成美团配送授权',
          code: 'meituan_oauth_required');
    }
    return const MeituanMerchantSearchResult(
      merchants: [
        MeituanDeliveryMerchant(merchantId: 'm1', merchantName: '锅气食堂'),
      ],
      hasNextPage: false,
    );
  }

  @override
  Future<Uri> createOAuthAuthorizationUri() async {
    if (authorizedOnReturn) _connected = true;
    return Uri.parse('https://example.com/oauth/authorize');
  }

  @override
  Future<MeituanOAuthStatus> getOAuthStatus() async {
    return MeituanOAuthStatus(
      connected: _connected,
      requiresUserAuthorization: !_connected,
    );
  }
}
