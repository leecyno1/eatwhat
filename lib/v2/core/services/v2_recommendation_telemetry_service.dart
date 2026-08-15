import 'package:eatwhat_app/core/models/analytics_event.dart';
import 'package:eatwhat_app/core/services/analytics_service.dart';
import 'package:eatwhat_app/v2/core/data/models/recommendation_telemetry_context.dart';
import 'package:eatwhat_app/v2/core/services/v2_recommendation_funnel_store.dart';
import 'package:flutter/foundation.dart';

typedef V2RecommendationTelemetrySink = Future<void> Function(
  AnalyticsEventType eventType,
  Map<String, dynamic> properties,
);

class V2RecommendationTelemetryService {
  V2RecommendationTelemetryService({
    AnalyticsService? analyticsService,
    V2RecommendationTelemetrySink? sink,
    V2RecommendationFunnelStore? funnelStore,
    DateTime Function()? clock,
  })  : _sink = sink ??
            _buildDefaultSink(
              analyticsService ?? AnalyticsService(),
              funnelStore ?? V2RecommendationFunnelStore.instance,
            ),
        _clock = clock ?? DateTime.now;

  static final V2RecommendationTelemetryService instance =
      V2RecommendationTelemetryService();

  static const String schemaVersion = 'v1';

  final V2RecommendationTelemetrySink _sink;
  final DateTime Function() _clock;
  int _sequence = 0;

  static V2RecommendationTelemetrySink _buildDefaultSink(
    AnalyticsService analyticsService,
    V2RecommendationFunnelStore funnelStore,
  ) {
    return (eventType, properties) async {
      await Future.wait([
        _bestEffort(
          () => analyticsService.trackEvent(
            eventType.name,
            properties: properties,
            recordMetrics: !kDebugMode,
          ),
        ),
        _bestEffort(() => funnelStore.record(eventType, properties)),
      ]);
    };
  }

  static Future<void> _bestEffort(Future<void> Function() operation) async {
    try {
      await operation();
    } catch (_) {
      // Each telemetry adapter is isolated from the others.
    }
  }

  String createRecommendationId({required String algorithmVersion}) {
    final safeVersion =
        algorithmVersion.trim().replaceAll(RegExp(r'[^a-zA-Z0-9_\-]'), '_');
    final timestamp = _clock().microsecondsSinceEpoch;
    final sequence = _sequence++;
    return 'rec_${safeVersion}_${timestamp}_$sequence';
  }

  Future<void> recordExposure({
    required RecommendationTelemetryContext context,
    required List<String> recipeIds,
  }) {
    return _record(
      AnalyticsEventType.recommendationShown,
      context,
      {
        'candidate_ids': recipeIds.take(10).toList(),
        'candidate_count': recipeIds.length,
      },
    );
  }

  Future<void> recordSelection({
    required RecommendationTelemetryContext context,
    required String recipeId,
    required int position,
    required String action,
  }) {
    return _record(
      AnalyticsEventType.recommendationClicked,
      context,
      {
        'recipe_id': recipeId,
        'position': position,
        'action': action,
      },
    );
  }

  Future<void> recordReroll({
    required RecommendationTelemetryContext context,
    required String fromRecipeId,
    required String toRecipeId,
    required int fromPosition,
    required int toPosition,
  }) {
    return _record(
      AnalyticsEventType.recommendationSkipped,
      context,
      {
        'from_recipe_id': fromRecipeId,
        'to_recipe_id': toRecipeId,
        'from_position': fromPosition,
        'to_position': toPosition,
        'action': 'reroll',
      },
    );
  }

  Future<void> recordFavoriteToggled({
    required RecommendationTelemetryContext context,
    required String recipeId,
    required int position,
    required bool isFavorited,
  }) {
    return _record(
      AnalyticsEventType.foodFavoriteToggled,
      context,
      {
        'recipe_id': recipeId,
        'position': position,
        'is_favorited': isFavorited,
        'source': 'recommendation_result',
      },
    );
  }

  Future<void> recordTasteFeedback({
    required RecommendationTelemetryContext context,
    required String recipeId,
    required int position,
    required bool isPositive,
  }) {
    return _record(
      AnalyticsEventType.tasteFeedbackGiven,
      context,
      {
        'recipe_id': recipeId,
        'position': position,
        'is_positive': isPositive,
      },
    );
  }

  Future<void> recordExecutionStarted({
    required RecommendationTelemetryContext context,
    required String recipeId,
    required int position,
    required String executionPath,
  }) {
    return _record(
      AnalyticsEventType.recommendationExecutionStarted,
      context,
      {
        'recipe_id': recipeId,
        'position': position,
        'execution_path': executionPath,
      },
    );
  }

  Future<void> recordExecutionCompleted({
    required RecommendationTelemetryContext context,
    required String recipeId,
    required int position,
    required String executionPath,
  }) {
    return _record(
      AnalyticsEventType.recommendationExecutionCompleted,
      context,
      {
        'recipe_id': recipeId,
        'position': position,
        'execution_path': executionPath,
      },
    );
  }

  Future<void> recordExecutionDeferred({
    required RecommendationTelemetryContext context,
    required String recipeId,
    required int position,
    required String executionPath,
  }) {
    return _record(
      AnalyticsEventType.recommendationExecutionDeferred,
      context,
      {
        'recipe_id': recipeId,
        'position': position,
        'execution_path': executionPath,
      },
    );
  }

  Future<void> _record(
    AnalyticsEventType eventType,
    RecommendationTelemetryContext context,
    Map<String, dynamic> eventProperties,
  ) async {
    try {
      await _sink(
        eventType,
        {
          'schema_version': schemaVersion,
          ...context.toAnalyticsProperties(),
          ...eventProperties,
        },
      );
    } catch (_) {
      // Telemetry must never interrupt recommendation or execution flows.
    }
  }
}
