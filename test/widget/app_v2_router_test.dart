import 'package:eatwhat_app/v2/core/data/models/recipe_model.dart';
import 'package:eatwhat_app/v2/core/data/models/taste_inference_input.dart';
import 'package:eatwhat_app/v2/core/external/platform/platform_types.dart';
import 'package:eatwhat_app/v2/core/navigation/app_v2_router.dart';
import 'package:eatwhat_app/v2/features/decision/decision_page.dart';
import 'package:eatwhat_app/v2/features/details/recipe_detail_page.dart';
import 'package:eatwhat_app/v2/features/execution/execution_home_page.dart';
import 'package:eatwhat_app/v2/features/home/home_page.dart';
import 'package:eatwhat_app/v2/features/result/result_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AppV2Router', () {
    test('resolves debug bootstrap values to V2 initial locations', () {
      expect(
        AppV2Router.initialLocationForBootstrap('decision_demo'),
        AppV2Routes.decisionDemo,
      );
      expect(
        AppV2Router.initialLocationForBootstrap('result_demo'),
        AppV2Routes.resultDemo,
      );
      expect(
        AppV2Router.initialLocationForBootstrap('HOME'),
        AppV2Routes.home,
      );
      expect(
        AppV2Router.initialLocationForBootstrap('unexpected'),
        AppV2Routes.home,
      );
    });

    testWidgets('starts on V2 home by default', (tester) async {
      final navigatorKey = GlobalKey<NavigatorState>();
      final router = AppV2Router.createRouter(navigatorKey: navigatorKey);

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byType(HomePage), findsOneWidget);
      expect(navigatorKey.currentState, isNotNull);
    });

    testWidgets('starts on decision demo when debug bootstrap asks for it',
        (tester) async {
      final router = AppV2Router.createRouter(
        navigatorKey: GlobalKey<NavigatorState>(),
        debugMode: true,
        debugBootstrap: 'decision_demo',
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byType(DecisionPage), findsOneWidget);
    });

    testWidgets('starts on result demo when debug bootstrap asks for it',
        (tester) async {
      final router = AppV2Router.createRouter(
        navigatorKey: GlobalKey<NavigatorState>(),
        debugMode: true,
        debugBootstrap: 'result_demo',
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.byType(ResultPage), findsOneWidget);
    });

    testWidgets('renders decision route from route data', (tester) async {
      final router = AppV2Router.createRouter(
        navigatorKey: GlobalKey<NavigatorState>(),
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      router.go(
        AppV2Routes.decision,
        extra: const AppV2DecisionRouteData(
          input: TasteInferenceInput(
            likedTagIds: ['flavor_spicy'],
            likedTagLabels: ['辣'],
            dislikedTagIds: [],
            dislikedTagLabels: [],
            skippedTagIds: [],
            skippedTagLabels: [],
            freeformRequirement: '想吃热菜',
            historyPreferenceSummary: {},
          ),
          autoNavigateToResult: false,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(DecisionPage), findsOneWidget);
      expect(find.text('辣'), findsWidgets);
    });

    testWidgets('renders result route from route data', (tester) async {
      final router = AppV2Router.createRouter(
        navigatorKey: GlobalKey<NavigatorState>(),
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      router.go(
        AppV2Routes.result,
        extra: const AppV2ResultRouteData(
          recommendations: [
            RecipeModel(
              id: 'route_result_1',
              name: '番茄肥牛锅',
              description: '热一点，汤底浓，适合收口。',
              ingredients: ['番茄', '肥牛'],
            ),
          ],
          inferenceInput: TasteInferenceInput(
            likedTagIds: ['style_hot'],
            likedTagLabels: ['热菜'],
            dislikedTagIds: [],
            dislikedTagLabels: [],
            skippedTagIds: [],
            skippedTagLabels: [],
            freeformRequirement: '想吃热一点',
            historyPreferenceSummary: {},
          ),
          aiReasonsByRecipeId: {
            'route_result_1': '热菜信号最集中。',
          },
          aiSummary: '路由载荷已进入结果页。',
          recallLabels: ['热菜'],
          recalledCount: 1,
          primarySource: 'unified_db',
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(ResultPage), findsOneWidget);
      expect(find.text('番茄肥牛锅'), findsWidgets);
      expect(find.textContaining('路由载荷已进入结果页'), findsOneWidget);
    });

    testWidgets('renders recipe detail route from route data', (tester) async {
      final router = AppV2Router.createRouter(
        navigatorKey: GlobalKey<NavigatorState>(),
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      router.go(
        AppV2Routes.recipeDetail,
        extra: const AppV2RecipeDetailRouteData(
          recipe: RecipeModel(
            id: 'route_recipe_1',
            name: '香辣干锅鸡',
            description: '锅气足，夜里吃更过瘾。',
            ingredients: ['鸡肉', '辣椒'],
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(RecipeDetailPage), findsOneWidget);
      expect(find.text('香辣干锅鸡'), findsWidgets);
    });

    testWidgets('renders execution route from route data', (tester) async {
      final router = AppV2Router.createRouter(
        navigatorKey: GlobalKey<NavigatorState>(),
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      router.go(
        AppV2Routes.execution,
        extra: const AppV2ExecutionRouteData(
          intent: ExecutionIntent(
            recipe: RecipeModel(
              id: 'route_execution_1',
              name: '麻婆豆腐',
              description: '麻辣下饭。',
            ),
            pairings: [
              PairingSelection(
                category: '主食',
                title: '米饭',
                subtitle: '吸住汤汁',
              ),
            ],
            sourceTags: ['麻辣'],
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(ExecutionHomePage), findsOneWidget);
      expect(find.textContaining('这道 麻婆豆腐'), findsOneWidget);
      expect(find.text('主食 · 米饭'), findsOneWidget);
    });

    testWidgets('renders delivery execution route from route data',
        (tester) async {
      final router = AppV2Router.createRouter(
        navigatorKey: GlobalKey<NavigatorState>(),
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      router.go(
        AppV2Routes.executionDelivery,
        extra: const AppV2DeliveryExecutionRouteData(
          intent: ExecutionIntent(
            recipe: RecipeModel(
              id: 'route_delivery_1',
              name: '番茄肥牛锅',
              description: '热一点。',
            ),
            pairings: [],
            sourceTags: ['热菜'],
          ),
          snapshot: DeliveryExecutionSnapshot(
            status: ExecutionAvailabilityStatus.unavailable,
            providerStates: [
              ProviderAvailability(
                platform: 'meituan',
                displayName: '美团外卖',
                capabilities: ProviderCapabilityMatrix.deliveryUnavailable,
                reason: '测试未开通',
              ),
            ],
            matches: [],
            message: '测试快照',
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(DeliveryExecutionPage), findsOneWidget);
      expect(find.text('外卖暂时找不到'), findsOneWidget);
      expect(find.textContaining('测试未开通'), findsWidgets);
    });

    testWidgets('renders dine-in execution route from route data',
        (tester) async {
      final router = AppV2Router.createRouter(
        navigatorKey: GlobalKey<NavigatorState>(),
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      router.go(
        AppV2Routes.executionDineIn,
        extra: const AppV2DineInExecutionRouteData(
          intent: ExecutionIntent(
            recipe: RecipeModel(
              id: 'route_dine_in_1',
              name: '番茄肥牛锅',
              description: '热一点。',
            ),
            pairings: [],
            sourceTags: ['热菜'],
          ),
          snapshot: DineInExecutionSnapshot(
            status: ExecutionAvailabilityStatus.available,
            providerStates: [
              ProviderAvailability(
                platform: 'dianping',
                displayName: '大众点评',
                capabilities: ProviderCapabilityMatrix(
                  supportsMerchantSearch: true,
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
              ),
            ],
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(DineInExecutionPage), findsOneWidget);
      expect(find.text('炉边小馆'), findsOneWidget);
      expect(find.text('打开大众点评'), findsOneWidget);
    });
  });
}
