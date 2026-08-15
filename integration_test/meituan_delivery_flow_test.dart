import 'package:eatwhat_app/core/config/env_config.dart';
import 'package:eatwhat_app/v2/core/data/models/recipe_model.dart';
import 'package:eatwhat_app/v2/core/external/platform/platform_types.dart';
import 'package:eatwhat_app/v2/features/execution/meituan_menu_builder_page.dart';
import 'package:eatwhat_app/v2/features/execution/meituan_order_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('推荐到美团收银台完整链路', (tester) async {
    await EnvConfig.init();
    Uri? paymentUri;
    await tester.pumpWidget(
      MaterialApp(
        home: MeituanMenuBuilderPage(
          intent: const ExecutionIntent(
            recipe: RecipeModel(
              id: 'delivery-e2e',
              name: '麻婆豆腐',
              description: '麻辣下饭',
            ),
            pairings: [
              PairingSelection(
                category: '主食',
                title: '米饭',
                subtitle: '吸住汤汁',
              ),
              PairingSelection(
                category: '饮品',
                title: '冰镇乌龙茶',
                subtitle: '清爽解腻',
              ),
            ],
            sourceTags: ['麻辣', '热菜', '下饭'],
            preferredPath: ExecutionPath.delivery,
          ),
          locationResolver: () async =>
              const GeoPoint(latitude: 22.5431, longitude: 114.0579),
          paymentLauncher: (uri) async {
            paymentUri = uri;
            return true;
          },
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('生成外卖菜单'), findsOneWidget);
    await tester.tap(
      find.byKey(const ValueKey('meituan-merchant-mock-merchant-001')),
    );
    await tester.pumpAndSettle();

    expect(find.byType(MeituanOrderPage), findsOneWidget);
    expect(find.text('菜单已选 3 份'), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('meituan-recipient-name')),
      500,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.enterText(
      find.byKey(const ValueKey('meituan-recipient-name')),
      '联调用户',
    );
    await tester.enterText(
      find.byKey(const ValueKey('meituan-recipient-phone')),
      '13800000000',
    );
    await tester.enterText(
      find.byKey(const ValueKey('meituan-recipient-address')),
      '深圳市南山区联调地址 1 号',
    );
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('meituan-preview-order')),
      500,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const ValueKey('meituan-preview-order')));
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('meituan-order-preview')), findsOneWidget);
    await tester.scrollUntilVisible(
      find.byKey(const ValueKey('meituan-submit-order')),
      300,
      scrollable: find.byType(Scrollable).first,
    );
    await tester.tap(find.byKey(const ValueKey('meituan-submit-order')));
    await tester.pumpAndSettle();

    expect(paymentUri, isNotNull);
    expect(paymentUri!.path, '/mock/meituan/cashier');
    expect(paymentUri!.queryParameters['orderId'], 'mock-order-20260812');
  });
}
