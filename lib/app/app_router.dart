import 'package:eatwhat_app/app/app_demo_routes.dart';
import 'package:eatwhat_app/app/app_dependencies.dart';
import 'package:eatwhat_app/features/auth/screens/login_screen.dart';
import 'package:eatwhat_app/features/auth/screens/register_screen.dart';
import 'package:eatwhat_app/v2/core/navigation/app_v2_routes.dart';
import 'package:eatwhat_app/v2/features/decision/decision_page.dart';
import 'package:eatwhat_app/v2/features/details/howtocook_library_page.dart';
import 'package:eatwhat_app/v2/features/details/recipe_detail_page.dart';
import 'package:eatwhat_app/v2/features/execution/execution_home_page.dart';
import 'package:eatwhat_app/v2/features/execution/meituan_menu_builder_page.dart';
import 'package:eatwhat_app/v2/features/favorites/favorites_page.dart';
import 'package:eatwhat_app/v2/features/home/home_page.dart';
import 'package:eatwhat_app/v2/features/result/result_page.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class AppV2Router {
  const AppV2Router._();

  static String initialLocationForBootstrap(String bootstrap) {
    switch (bootstrap.trim().toLowerCase()) {
      case 'decision_demo':
        return AppV2Routes.decisionDemo;
      case 'result_demo':
        return AppV2Routes.resultDemo;
      case 'execution_demo':
        return AppV2Routes.executionDemo;
      case 'delivery_demo':
        return AppV2Routes.deliveryDemo;
      case 'order_demo':
        return AppV2Routes.orderDemo;
      case 'home':
      default:
        return AppV2Routes.home;
    }
  }

  static GoRouter createRouter({
    required GlobalKey<NavigatorState> navigatorKey,
    String debugBootstrap = 'home',
    bool debugMode = false,
    AppDependencies? dependencies,
  }) {
    final resolvedDependencies = dependencies ?? AppDependencies.standard();
    return GoRouter(
      navigatorKey: navigatorKey,
      initialLocation: debugMode
          ? initialLocationForBootstrap(debugBootstrap)
          : AppV2Routes.home,
      routes: [
        GoRoute(
          path: AppV2Routes.home,
          name: 'v2_home',
          builder: (context, state) => const HomePage(),
        ),
        GoRoute(
          path: AppV2Routes.login,
          name: 'v2_login',
          builder: (context, state) => const LoginScreen(),
        ),
        GoRoute(
          path: AppV2Routes.register,
          name: 'v2_register',
          builder: (context, state) => const RegisterScreen(),
        ),
        GoRoute(
          path: AppV2Routes.decision,
          name: 'v2_decision',
          builder: (context, state) {
            final data = state.extra;
            if (data is! AppV2DecisionRouteData) {
              return const HomePage();
            }
            return DecisionPage(
              input: data.input,
              recommendationFlowService: data.recommendationFlowService ??
                  resolvedDependencies.recommendationFlowService,
              autoNavigateToResult: data.autoNavigateToResult,
            );
          },
        ),
        GoRoute(
          path: AppV2Routes.result,
          name: 'v2_result',
          builder: (context, state) {
            final data = state.extra;
            if (data is! AppV2ResultRouteData) {
              return const HomePage();
            }
            return ResultPage(
              recommendations: data.recommendations,
              inferenceInput: data.inferenceInput,
              fallbackTags: data.fallbackTags,
              recallLabels: data.recallLabels,
              recalledCount: data.recalledCount,
              aiReasonsByRecipeId: data.aiReasonsByRecipeId,
              aiSummary: data.aiSummary,
              resolutionStatus: data.resolutionStatus,
              primarySource: data.primarySource,
              recommendationContext: data.recommendationContext,
              aiEnhancement: data.aiEnhancement,
              cancelAiEnhancement: data.cancelAiEnhancement,
              generationService: resolvedDependencies.generationService,
              howToCookRecipeService:
                  resolvedDependencies.howToCookRecipeService,
            );
          },
        ),
        GoRoute(
          path: AppV2Routes.recipeDetail,
          name: 'v2_recipe_detail',
          builder: (context, state) {
            final data = state.extra;
            if (data is! AppV2RecipeDetailRouteData) {
              return const HomePage();
            }
            return RecipeDetailPage(
              recipe: data.recipe,
              generationService: resolvedDependencies.generationService,
              howToCookRecipeService: data.howToCookRecipeService ??
                  resolvedDependencies.howToCookRecipeService,
              startInCookingMode: data.startInCookingMode,
            );
          },
        ),
        GoRoute(
          path: AppV2Routes.execution,
          name: 'v2_execution',
          builder: (context, state) {
            final data = state.extra;
            if (data is! AppV2ExecutionRouteData) {
              return const HomePage();
            }
            return ExecutionHomePage(intent: data.intent);
          },
        ),
        GoRoute(
          path: AppV2Routes.executionDelivery,
          name: 'v2_execution_delivery',
          builder: (context, state) {
            final data = state.extra;
            if (data is! AppV2DeliveryExecutionRouteData) {
              return const HomePage();
            }
            return MeituanMenuBuilderPage(
              intent: data.intent,
              client: data.meituanOrderClient,
              locationResolver: data.locationResolver,
            );
          },
        ),
        GoRoute(
          path: AppV2Routes.executionDineIn,
          name: 'v2_execution_dine_in',
          builder: (context, state) {
            final data = state.extra;
            if (data is! AppV2DineInExecutionRouteData) {
              return const HomePage();
            }
            return DineInExecutionPage(
              intent: data.intent,
              snapshot: data.snapshot,
            );
          },
        ),
        GoRoute(
          path: AppV2Routes.favorites,
          name: 'v2_favorites',
          builder: (context, state) => const FavoritesPageV2(),
        ),
        GoRoute(
          path: AppV2Routes.howtocookLibrary,
          name: 'v2_howtocook_library',
          builder: (context, state) {
            final data = state.extra;
            if (data is AppV2HowToCookLibraryRouteData) {
              return HowToCookLibraryPage(
                service:
                    data.service ?? resolvedDependencies.howToCookRecipeService,
                initialCategory: data.initialCategory,
                initialQuery: data.initialQuery,
              );
            }
            return HowToCookLibraryPage(
              service: resolvedDependencies.howToCookRecipeService,
            );
          },
        ),
        if (!kReleaseMode) ...buildAppV2DemoRoutes(resolvedDependencies),
      ],
    );
  }
}
