import 'package:eatwhat_app/v2/core/data/models/recipe_model.dart';
import 'package:eatwhat_app/v2/core/external/platform/platform_types.dart';
import 'package:eatwhat_app/v2/core/services/v2_preference_feedback_service.dart';
import 'package:eatwhat_app/v2/features/details/recipe_detail_page.dart';
import 'package:eatwhat_app/v2/features/execution/execution_home_page.dart';
import 'package:eatwhat_app/v2/features/execution/widgets/execution_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  testWidgets('执行主页展示三路径和语义色块', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ExecutionHomePage(
          intent: ExecutionIntent(
            recipe: RecipeModel(
              id: 'r1',
              name: '番茄肥牛锅',
              description: '热一点，有锅气，适合夜里吃。',
            ),
            pairings: [
              PairingSelection(
                category: '饮品',
                title: '酸梅汤',
                subtitle: '解腻',
              ),
            ],
            sourceTags: ['辣', '火锅'],
            preferredPath: ExecutionPath.delivery,
            locationPreference: ExecutionLocationPreference.nearby,
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('自己做'), findsOneWidget);
    expect(find.text('叫外卖'), findsOneWidget);
    expect(find.text('推荐'), findsOneWidget);
    expect(find.text('附近优先'), findsOneWidget);
    expect(find.text('饮品 · 酸梅汤'), findsOneWidget);
    expect(find.text('辣'), findsOneWidget);
    expect(find.text('火锅'), findsOneWidget);
    expect(find.byKey(const ValueKey('execution-home-page')), findsOneWidget);
    expect(find.text('开吃方式'), findsOneWidget);
    expect(find.text('暖食编辑部 · 开吃指南'), findsNothing);
    expect(find.byKey(const ValueKey('execution-open-howtocook-library')),
        findsOneWidget);

    await tester.drag(
      find.byKey(const ValueKey('execution-home-page')),
      const Offset(0, -240),
    );
    await tester.pumpAndSettle();
    expect(find.text('去堂食'), findsOneWidget);
  });

  testWidgets('点击执行路径会记录本轮最终开吃方式', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ExecutionHomePage(
          intent: ExecutionIntent(
            recipe: RecipeModel(
              id: 'r1',
              name: '番茄肥牛锅',
              description: '热一点，有锅气，适合夜里吃。',
            ),
            pairings: [],
            sourceTags: ['辣', '火锅'],
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('叫外卖'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 20));

    expect(
      await V2PreferenceFeedbackService.instance.getExecutionPathScore(
        ExecutionPath.delivery,
      ),
      1,
    );
  });

  testWidgets('从执行页选择自己做会进入做菜模式详情页', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: ExecutionHomePage(
          intent: ExecutionIntent(
            recipe: RecipeModel(
              id: 'r1',
              name: '番茄肥牛锅',
              description: '热一点，有锅气，适合夜里吃。',
              ingredients: ['番茄 2个', '肥牛 200g'],
              steps: ['番茄炒出沙。', '加入热水煮 8 分钟。'],
            ),
            pairings: [],
            sourceTags: ['辣', '火锅'],
            preferredPath: ExecutionPath.cook,
          ),
        ),
      ),
    );
    await tester.pump();

    await tester.tap(find.text('自己做'));
    await tester.pumpAndSettle();

    expect(find.byType(RecipeDetailPage), findsOneWidget);
    expect(find.text('做菜模式'), findsOneWidget);
    expect(
        find.byKey(const ValueKey('recipe-cooking-mode-page')), findsOneWidget);
    expect(
        find.byKey(const ValueKey('recipe-cooking-page-view')), findsOneWidget);
  });

  testWidgets('没有明确开吃方式时会用历史偏好推荐路径', (tester) async {
    await V2PreferenceFeedbackService.instance.recordExecutionPathChosen(
      ExecutionPath.delivery,
      delta: 3,
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: ExecutionHomePage(
          intent: ExecutionIntent(
            recipe: RecipeModel(
              id: 'r1',
              name: '番茄肥牛锅',
              description: '热一点，有锅气，适合夜里吃。',
            ),
            pairings: [],
            sourceTags: ['辣', '火锅'],
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    expect(find.text('叫外卖'), findsOneWidget);
    expect(find.text('推荐'), findsOneWidget);
  });

  testWidgets('明确开吃方式优先于历史偏好', (tester) async {
    await V2PreferenceFeedbackService.instance.recordExecutionPathChosen(
      ExecutionPath.delivery,
      delta: 3,
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: ExecutionHomePage(
          intent: ExecutionIntent(
            recipe: RecipeModel(
              id: 'r1',
              name: '番茄肥牛锅',
              description: '热一点，有锅气，适合夜里吃。',
            ),
            pairings: [],
            sourceTags: ['辣', '火锅'],
            preferredPath: ExecutionPath.cook,
          ),
        ),
      ),
    );

    await tester.pumpAndSettle();

    final recommendedLabel = tester.widget<Text>(find.text('推荐'));
    final recommendedCard = find.ancestor(
      of: find.byWidget(recommendedLabel),
      matching: find.byType(ExecutionPathCard),
    );

    expect(
      find.descendant(of: recommendedCard, matching: find.text('自己做')),
      findsOneWidget,
    );
  });

  testWidgets('外卖路径在平台未开通时明确展示状态', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: DeliveryExecutionPage(
          intent: ExecutionIntent(
            recipe: RecipeModel(
              id: 'r1',
              name: '番茄肥牛锅',
              description: '热一点，有锅气，适合夜里吃。',
            ),
            pairings: [],
            sourceTags: ['辣', '火锅'],
          ),
          snapshot: DeliveryExecutionSnapshot(
            status: ExecutionAvailabilityStatus.unavailable,
            providerStates: [
              ProviderAvailability(
                platform: 'meituan',
                displayName: '美团外卖',
                capabilities: ProviderCapabilityMatrix.deliveryUnavailable,
                reason: '未开通商品检索与预填购物车能力',
              ),
            ],
            matches: [],
            message: '外卖代理调用失败',
          ),
        ),
      ),
    );
    await tester.pump();

    expect(find.text('外卖暂时找不到'), findsOneWidget);
    expect(find.textContaining('预填购物车'), findsWidgets);
    expect(find.byKey(const ValueKey('execution-proxy-panel')), findsOneWidget);
    expect(find.text('外卖服务 · 可刷新'), findsOneWidget);
    expect(find.text('最近结果 · 外卖代理调用失败'), findsOneWidget);
  });

  testWidgets('外卖与堂食路径展示候选能力细节', (tester) async {
    const intent = ExecutionIntent(
      recipe: RecipeModel(
        id: 'r1',
        name: '番茄肥牛锅',
        description: '热一点，有锅气，适合夜里吃。',
      ),
      pairings: [],
      sourceTags: ['辣', '火锅'],
    );

    await tester.pumpWidget(
      const MaterialApp(
        home: DeliveryExecutionPage(
          intent: intent,
          snapshot: DeliveryExecutionSnapshot(
            status: ExecutionAvailabilityStatus.available,
            providerStates: [
              ProviderAvailability(
                platform: 'meituan',
                displayName: '美团外卖',
                capabilities: ProviderCapabilityMatrix(
                  supportsDishSearch: true,
                  supportsPrefillCart: true,
                ),
              ),
            ],
            matches: [
              DeliveryMatchResult(
                platform: 'meituan',
                providerDisplayName: '美团外卖',
                merchantId: 'm1',
                merchantName: '老地方砂锅',
                dishName: '番茄肥牛锅',
                url: 'https://example.com',
                price: Money(amount: 42),
                deliveryTimeMinutes: 28,
                supportsPrefillCart: true,
                note: '命中招牌锅物，适合今天这口。',
                source: 'proxy',
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('老地方砂锅'), findsOneWidget);
    expect(find.text('¥42'), findsOneWidget);
    expect(find.text('支持快速下单'), findsOneWidget);
    expect(find.text('去美团外卖下单'), findsOneWidget);
    expect(find.text('来源 · proxy'), findsOneWidget);
    expect(find.textContaining('命中招牌锅物'), findsOneWidget);

    await tester.pumpWidget(
      const MaterialApp(
        home: DineInExecutionPage(
          intent: intent,
          snapshot: DineInExecutionSnapshot(
            status: ExecutionAvailabilityStatus.available,
            providerStates: [
              ProviderAvailability(
                platform: 'dianping',
                displayName: '大众点评',
                capabilities: ProviderCapabilityMatrix(
                  supportsMerchantSearch: true,
                  supportsMerchantDetail: true,
                  supportsReservation: true,
                  supportsNavigation: true,
                ),
              ),
            ],
            matches: [
              DineInMatchResult(
                platform: 'dianping',
                providerDisplayName: '大众点评',
                merchantId: 'dp1',
                merchantName: '炉边小馆',
                matchedDishName: '番茄肥牛锅',
                url: 'https://example.com',
                rating: 4.7,
                pricePerPerson: Money(amount: 86),
                distanceMeters: 520,
                supportsMerchantDetail: true,
                supportsReservation: true,
                supportsNavigation: true,
                note: '命中招牌锅物，评分稳定。',
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('炉边小馆'), findsOneWidget);
    expect(find.text('¥86/人'), findsOneWidget);
    expect(find.text('支持导航'), findsOneWidget);
    expect(find.text('支持预约'), findsOneWidget);
    expect(find.text('打开大众点评'), findsOneWidget);
  });

  testWidgets('外卖候选在不支持预填购物车时仍展示平台跳转入口', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: DeliveryExecutionPage(
          intent: ExecutionIntent(
            recipe: RecipeModel(
              id: 'r1',
              name: '番茄肥牛锅',
              description: '热一点，有锅气，适合夜里吃。',
            ),
            pairings: [],
            sourceTags: ['辣', '火锅'],
          ),
          snapshot: DeliveryExecutionSnapshot(
            status: ExecutionAvailabilityStatus.available,
            providerStates: [
              ProviderAvailability(
                platform: 'meituan',
                displayName: '美团外卖',
                capabilities: ProviderCapabilityMatrix(
                  supportsDishSearch: true,
                ),
              ),
            ],
            matches: [
              DeliveryMatchResult(
                platform: 'meituan',
                providerDisplayName: '美团外卖',
                merchantId: 'm2',
                merchantName: '锅气食堂',
                dishName: '番茄肥牛锅',
                url: 'https://example.com/view',
                source: 'proxy',
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('打开美团外卖'), findsOneWidget);
  });

  testWidgets('实时执行页提供刷新入口', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: DeliveryExecutionPage(
          intent: ExecutionIntent(
            recipe: RecipeModel(
              id: 'r1',
              name: '番茄肥牛锅',
              description: '热一点，有锅气，适合夜里吃。',
            ),
            pairings: [],
            sourceTags: ['辣', '火锅'],
          ),
        ),
      ),
    );
    await tester.pump();

    expect(
        find.byKey(const ValueKey('execution-refresh-button')), findsOneWidget);
  });

  testWidgets('外卖执行页完成反馈会写回菜品、路径与本轮口味', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: DeliveryExecutionPage(
          intent: ExecutionIntent(
            recipe: RecipeModel(
              id: 'r-done',
              name: '椒麻鸡丝凉面',
              description: '省心外卖。',
            ),
            pairings: [],
            sourceTags: ['外卖', '凉面'],
          ),
          snapshot: DeliveryExecutionSnapshot(
            status: ExecutionAvailabilityStatus.available,
            providerStates: [
              ProviderAvailability(
                platform: 'meituan',
                displayName: '美团外卖',
                capabilities: ProviderCapabilityMatrix(
                  supportsDishSearch: true,
                ),
              ),
            ],
            matches: [
              DeliveryMatchResult(
                platform: 'meituan',
                providerDisplayName: '美团外卖',
                merchantId: 'm1',
                merchantName: '冷面小馆',
                dishName: '椒麻鸡丝凉面',
                url: 'https://example.com',
              ),
            ],
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byKey(const ValueKey('execution-completion-feedback')),
        findsOneWidget);

    await tester.tap(find.byKey(const ValueKey('execution-completion-done')));
    await tester.pumpAndSettle();

    expect(find.text('已记住这次开吃选择'), findsOneWidget);
    expect(
      await V2PreferenceFeedbackService.instance.getRecentRecipeIds(),
      contains('r-done'),
    );
    expect(
      await V2PreferenceFeedbackService.instance.getExecutionPathScore(
        ExecutionPath.delivery,
      ),
      2,
    );
    expect(await V2PreferenceFeedbackService.instance.getTagScore('外卖'), 0);
    expect(await V2PreferenceFeedbackService.instance.getTagScore('凉面'), 2);
  });

  test('执行平台名称会统一映射为开吃路径', () {
    expect(executionPathForPlatform('meituan'), ExecutionPath.delivery);
    expect(executionPathForPlatform('eleme'), ExecutionPath.delivery);
    expect(executionPathForPlatform('jd_delivery'), ExecutionPath.delivery);
    expect(executionPathForPlatform('delivery'), ExecutionPath.delivery);
    expect(executionPathForPlatform('dianping'), ExecutionPath.dineIn);
    expect(executionPathForPlatform('apple_maps'), ExecutionPath.dineIn);
    expect(executionPathForPlatform('unknown'), ExecutionPath.any);
  });
}
