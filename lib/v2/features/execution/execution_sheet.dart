import 'package:eatwhat_app/v2/core/data/models/recipe_model.dart';
import 'package:eatwhat_app/v2/core/data/models/recommendation_telemetry_context.dart';
import 'package:eatwhat_app/v2/core/data/models/taste_selection_models.dart';
import 'package:eatwhat_app/v2/core/external/platform/platform_types.dart';
import 'package:eatwhat_app/v2/core/navigation/app_v2_router.dart';
import 'package:eatwhat_app/v2/features/execution/execution_home_page.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class ExecutionSheet {
  const ExecutionSheet._();

  static Future<void> show(
    BuildContext context, {
    String? dishName,
    RecipeModel? recipe,
    List<PairingSelection> pairings = const [],
    List<String> sourceTags = const [],
    TasteStructuredConstraints? structuredConstraints,
    RecommendationTelemetryContext? recommendationContext,
    int? recommendationPosition,
  }) async {
    final resolvedRecipe = recipe ??
        RecipeModel(
          id: 'execution_${dishName.hashCode}',
          name: dishName ?? '今天这一口',
          description: '从结果页进入的执行路径。',
        );
    final executionPreference = structuredConstraints?.executionPreference ??
        TasteExecutionPreference.any;
    final preferredPath = switch (executionPreference) {
      TasteExecutionPreference.cook => ExecutionPath.cook,
      TasteExecutionPreference.delivery => ExecutionPath.delivery,
      TasteExecutionPreference.dineIn => ExecutionPath.dineIn,
      TasteExecutionPreference.any => ExecutionPath.any,
    };
    final locationPreference = structuredConstraints?.locationPreference ??
        TasteLocationPreference.any;
    final executionLocationPreference = switch (locationPreference) {
      TasteLocationPreference.nearby => ExecutionLocationPreference.nearby,
      TasteLocationPreference.any => ExecutionLocationPreference.any,
    };

    final intent = ExecutionIntent(
      recipe: resolvedRecipe,
      pairings: pairings,
      sourceTags: sourceTags.isNotEmpty ? sourceTags : resolvedRecipe.tags,
      preferredPath: preferredPath,
      locationPreference: executionLocationPreference,
      recommendationContext: recommendationContext,
      recommendationPosition: recommendationPosition,
    );

    if (GoRouter.maybeOf(context) != null) {
      await context.push(
        AppV2Routes.execution,
        extra: AppV2ExecutionRouteData(intent: intent),
      );
      return;
    }

    await Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => ExecutionHomePage(intent: intent),
      ),
    );
  }
}
