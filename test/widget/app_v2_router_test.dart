import 'dart:async';

import 'package:eatwhat_app/app/app_dependencies.dart';
import 'package:eatwhat_app/app/app_router.dart';
import 'package:eatwhat_app/v2/core/data/models/ai_generation_models.dart';
import 'package:eatwhat_app/v2/core/data/models/recipe_model.dart';
import 'package:eatwhat_app/v2/core/data/models/taste_inference_input.dart';
import 'package:eatwhat_app/v2/core/external/platform/meituan_delivery_order_client.dart';
import 'package:eatwhat_app/v2/core/external/platform/platform_types.dart';
import 'package:eatwhat_app/v2/core/navigation/app_v2_routes.dart';
import 'package:eatwhat_app/v2/core/services/generation_service.dart';
import 'package:eatwhat_app/v2/core/services/v2_howtocook_recipe_service.dart';
import 'package:eatwhat_app/v2/core/services/v2_phase2_recommendation_service.dart';
import 'package:eatwhat_app/v2/features/decision/decision_page.dart';
import 'package:eatwhat_app/v2/features/details/howtocook_library_page.dart';
import 'package:eatwhat_app/v2/features/details/recipe_detail_page.dart';
import 'package:eatwhat_app/v2/features/execution/execution_home_page.dart';
import 'package:eatwhat_app/v2/features/execution/meituan_menu_builder_page.dart';
import 'package:eatwhat_app/v2/features/execution/meituan_order_page.dart';
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
        AppV2Router.initialLocationForBootstrap('execution_demo'),
        AppV2Routes.executionDemo,
      );
      expect(
        AppV2Router.initialLocationForBootstrap('delivery_demo'),
        AppV2Routes.deliveryDemo,
      );
      expect(
        AppV2Router.initialLocationForBootstrap('order_demo'),
        AppV2Routes.orderDemo,
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
      expect(
        find.byKey(const ValueKey('taste-card-stage-shell')),
        findsOneWidget,
      );
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

    testWidgets(
        'delivery demo provides reviewable merchants without API config',
        (tester) async {
      final router = AppV2Router.createRouter(
        navigatorKey: GlobalKey<NavigatorState>(),
        debugMode: true,
        debugBootstrap: 'delivery_demo',
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      expect(find.byType(MeituanMenuBuilderPage), findsOneWidget);
      expect(find.text('锅气食堂（福田店）'), findsOneWidget);
      expect(find.text('家常小馆（中心区店）'), findsOneWidget);
    });

    testWidgets('order demo provides reviewable products without API config',
        (tester) async {
      final router = AppV2Router.createRouter(
        navigatorKey: GlobalKey<NavigatorState>(),
        debugMode: true,
        debugBootstrap: 'order_demo',
      );

      await tester.pumpWidget(MaterialApp.router(routerConfig: router));
      await tester.pumpAndSettle();

      expect(find.byType(MeituanOrderPage), findsOneWidget);
      expect(find.text('麻婆豆腐'), findsOneWidget);
      expect(find.byKey(const ValueKey('meituan-order-flow')), findsOneWidget);
      expect(find.text('菜单已选 2 份'), findsOneWidget);
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

    testWidgets('injects AppDependencies into main route pages',
        (tester) async {
      final howToCook = _emptyRouterHowToCookService();
      final generation = _RouterGenerationService();
      final recommendationFlow = V2Phase2RecommendationService(
        enableAiEnhancement: false,
        howToCookRecipeService: howToCook,
      );
      final dependencies = AppDependencies(
        generationService: generation,
        howToCookRecipeService: howToCook,
        recommendationFlowService: recommendationFlow,
      );
      final router = AppV2Router.createRouter(
        navigatorKey: GlobalKey<NavigatorState>(),
        dependencies: dependencies,
      );
      const input = TasteInferenceInput(
        likedTagIds: ['flavor_spicy'],
        likedTagLabels: ['辣'],
        dislikedTagIds: [],
        dislikedTagLabels: [],
        skippedTagIds: [],
        skippedTagLabels: [],
        freeformRequirement: '想吃热菜',
        historyPreferenceSummary: {},
      );
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));

      router.go(
        AppV2Routes.decision,
        extra: const AppV2DecisionRouteData(
          input: input,
          autoNavigateToResult: false,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(
        tester
            .widget<DecisionPage>(find.byType(DecisionPage))
            .recommendationFlowService,
        same(recommendationFlow),
      );

      router.go(
        AppV2Routes.result,
        extra: const AppV2ResultRouteData(
          recommendations: [
            RecipeModel(
              id: 'route_result_1',
              name: '番茄肥牛锅',
              description: '热一点。',
            ),
          ],
          inferenceInput: input,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      final result = tester.widget<ResultPage>(find.byType(ResultPage));
      expect(result.generationService, same(generation));
      expect(result.howToCookRecipeService, same(howToCook));

      router.go(
        AppV2Routes.recipeDetail,
        extra: const AppV2RecipeDetailRouteData(
          recipe: RecipeModel(
            id: 'route_recipe_1',
            name: '香辣干锅鸡',
            description: '锅气足。',
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      final detail = tester.widget<RecipeDetailPage>(
        find.byType(RecipeDetailPage),
      );
      expect(detail.generationService, same(generation));
      expect(detail.howToCookRecipeService, same(howToCook));

      router.go(AppV2Routes.howtocookLibrary);
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));
      expect(
        tester
            .widget<HowToCookLibraryPage>(
              find.byType(HowToCookLibraryPage),
            )
            .service,
        same(howToCook),
      );
    });

    testWidgets('route data service overrides AppDependencies', (tester) async {
      final dependencies = AppDependencies(
        generationService: GenerationService.instance,
        howToCookRecipeService: V2HowToCookRecipeService.instance,
        recommendationFlowService: V2Phase2RecommendationService(
          enableAiEnhancement: false,
        ),
      );
      final override = V2Phase2RecommendationService(
        enableAiEnhancement: false,
      );
      final router = AppV2Router.createRouter(
        navigatorKey: GlobalKey<NavigatorState>(),
        dependencies: dependencies,
      );
      await tester.pumpWidget(MaterialApp.router(routerConfig: router));

      router.go(
        AppV2Routes.decision,
        extra: AppV2DecisionRouteData(
          input: const TasteInferenceInput(
            likedTagIds: ['flavor_spicy'],
            likedTagLabels: ['辣'],
            dislikedTagIds: [],
            dislikedTagLabels: [],
            skippedTagIds: [],
            skippedTagLabels: [],
            freeformRequirement: '',
            historyPreferenceSummary: {},
          ),
          recommendationFlowService: override,
          autoNavigateToResult: false,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 300));

      expect(
        tester
            .widget<DecisionPage>(find.byType(DecisionPage))
            .recommendationFlowService,
        same(override),
      );
    });

    testWidgets('forwards recommendation session cancellation to ResultPage',
        (tester) async {
      final refiner = Completer<AiRefinedRecommendations>();
      addTearDown(() {
        if (!refiner.isCompleted) {
          refiner.complete(
            const AiRefinedRecommendations(
              recipeIds: ['router_handoff_dish'],
              reasonsById: {},
            ),
          );
        }
      });
      final recommendationFlow = _TrackingRouterRecommendationService(
        refiner: refiner,
      );
      final router = AppV2Router.createRouter(
        navigatorKey: GlobalKey<NavigatorState>(),
        dependencies: AppDependencies(
          generationService: _RouterGenerationService(),
          howToCookRecipeService: _emptyRouterHowToCookService(),
          recommendationFlowService: recommendationFlow,
        ),
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
            freeformRequirement: '',
            historyPreferenceSummary: {},
          ),
        ),
      );
      for (var attempt = 0;
          attempt < 50 && find.byType(ResultPage).evaluate().isEmpty;
          attempt += 1) {
        await tester.pump(const Duration(milliseconds: 100));
      }

      expect(find.byType(ResultPage), findsOneWidget);
      final session = recommendationFlow.lastSession!;
      expect(session.isCancelled, isFalse);
      expect(
        tester.widget<ResultPage>(find.byType(ResultPage)).cancelAiEnhancement,
        isNotNull,
      );

      await tester.pumpWidget(const SizedBox.shrink());
      await tester.pump();

      expect(session.isCancelled, isTrue);
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
        extra: AppV2DeliveryExecutionRouteData(
          intent: const ExecutionIntent(
            recipe: RecipeModel(
              id: 'route_delivery_1',
              name: '番茄肥牛锅',
              description: '热一点。',
            ),
            pairings: [],
            sourceTags: ['热菜'],
          ),
          meituanOrderClient: _RouterMeituanMerchantClient(),
          locationResolver: _fixedLocation,
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 500));

      expect(find.byType(MeituanMenuBuilderPage), findsOneWidget);
      expect(find.text('生成外卖菜单'), findsOneWidget);
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

class _RouterGenerationService extends Fake implements GenerationService {}

V2HowToCookRecipeService _emptyRouterHowToCookService() {
  return V2HowToCookRecipeService(
    searchLoader: (_, __) async => const [],
    completeLoader: (_) async => null,
    allRecipesLoader: (_) async => const [],
    assetIndexLoader: () async => '{"items":[]}',
  );
}

Future<GeoPoint> _fixedLocation() async {
  return const GeoPoint(latitude: 39.9042, longitude: 116.4074);
}

class _TrackingRouterRecommendationService
    extends V2Phase2RecommendationService {
  _TrackingRouterRecommendationService({
    required Completer<AiRefinedRecommendations> refiner,
  }) : super(
          localRecommendationLoader: (_, __, ___) async => const [
            RecipeModel(
              id: 'router_handoff_dish',
              name: '路由交接番茄煲',
              description: '验证路由会话交接。',
              source: 'unified_db',
            ),
          ],
          recommendationRefiner: ({
            required selectedTags,
            required candidates,
            required limit,
            required customRequirement,
          }) =>
              refiner.future,
          howToCookRecipeService: _emptyRouterHowToCookService(),
        );

  RecommendationSession? lastSession;

  @override
  Future<RecommendationSession> startRecommendationSession({
    required TasteInferenceInput input,
    int recallLimit = 12,
    int finalLimit = 5,
    Duration? localTimeout,
  }) async {
    final session = await super.startRecommendationSession(
      input: input,
      recallLimit: recallLimit,
      finalLimit: finalLimit,
      localTimeout: localTimeout,
    );
    lastSession = session;
    return session;
  }
}

class _RouterMeituanMerchantClient extends MeituanDeliveryOrderClient {
  // Test environment has no proxy configured — mark the backend as wired
  // so the menu builder runs its normal flow.
  @override
  bool get isConfigured => true;

  @override
  Future<MeituanMerchantSearchResult> searchMerchantResults({
    required String keyword,
    required GeoPoint location,
    int limit = 10,
  }) async {
    return const MeituanMerchantSearchResult(
      hasNextPage: false,
      merchants: [
        MeituanDeliveryMerchant(
          merchantId: 'router-merchant',
          merchantName: '路由联调店',
        ),
      ],
    );
  }
}
