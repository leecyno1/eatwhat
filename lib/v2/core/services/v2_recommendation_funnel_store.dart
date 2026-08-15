import 'dart:convert';

import 'package:eatwhat_app/core/models/analytics_event.dart';
import 'package:eatwhat_app/v2/core/data/models/recommendation_funnel_snapshot.dart';
import 'package:shared_preferences/shared_preferences.dart';

typedef V2FunnelPreferencesLoader = Future<SharedPreferences> Function();

class V2RecommendationFunnelStore {
  V2RecommendationFunnelStore({
    V2FunnelPreferencesLoader? preferencesLoader,
    DateTime Function()? clock,
    this.retentionDays = 30,
  })  : assert(retentionDays > 0),
        _preferencesLoader = preferencesLoader ?? SharedPreferences.getInstance,
        _clock = clock ?? DateTime.now;

  static final V2RecommendationFunnelStore instance =
      V2RecommendationFunnelStore();

  static const String schemaVersion = 'v1';
  static const String _storageKey = 'v2_recommendation_funnel_aggregates_v1';

  final V2FunnelPreferencesLoader _preferencesLoader;
  final DateTime Function() _clock;
  final int retentionDays;
  Future<void> _pendingOperation = Future<void>.value();

  Future<void> record(
    AnalyticsEventType eventType,
    Map<String, dynamic> properties,
  ) {
    if (!_supportedEventTypes.contains(eventType)) {
      return Future<void>.value();
    }
    final cohort = _FunnelCohort.tryParse(properties, day: _clock());
    if (cohort == null) return Future<void>.value();

    return _enqueue(() async {
      final prefs = await _preferencesLoader();
      final snapshots = _decode(prefs.getString(_storageKey));
      _removeExpired(snapshots, now: _clock());

      final index = snapshots.indexWhere(
        (snapshot) => snapshot.belongsTo(
          day: cohort.day,
          schemaVersion: cohort.schemaVersion,
          algorithmVersion: cohort.algorithmVersion,
          primarySource: cohort.primarySource,
          resolutionStatus: cohort.resolutionStatus,
        ),
      );
      final current = index < 0 ? cohort.emptySnapshot : snapshots[index];
      final updated = _increment(current, eventType, properties);
      if (identical(updated, current)) return;
      if (index < 0) {
        snapshots.add(updated);
      } else {
        snapshots[index] = updated;
      }

      await _write(prefs, snapshots);
    });
  }

  Future<List<RecommendationFunnelSnapshot>> readSnapshots({
    DateTime? since,
  }) {
    return _enqueue(() async {
      final prefs = await _preferencesLoader();
      final snapshots = _decode(prefs.getString(_storageKey));
      final removedExpired = _removeExpired(snapshots, now: _clock());
      if (removedExpired) {
        await _write(prefs, snapshots);
      }

      final normalizedSince =
          since == null ? null : DateTime(since.year, since.month, since.day);
      final result = snapshots
          .where(
            (snapshot) =>
                normalizedSince == null ||
                !snapshot.day.isBefore(normalizedSince),
          )
          .toList()
        ..sort(_compareSnapshots);
      return List<RecommendationFunnelSnapshot>.unmodifiable(result);
    });
  }

  Future<void> clear() {
    return _enqueue(() async {
      final prefs = await _preferencesLoader();
      await prefs.remove(_storageKey);
    });
  }

  Future<T> _enqueue<T>(Future<T> Function() operation) {
    final result = _pendingOperation.then((_) => operation());
    _pendingOperation = result.then<void>(
      (_) {},
      onError: (_, __) {},
    );
    return result;
  }

  List<RecommendationFunnelSnapshot> _decode(String? raw) {
    if (raw == null || raw.trim().isEmpty) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map || decoded['schema_version'] != schemaVersion) {
        return [];
      }
      final rawSnapshots = decoded['snapshots'];
      if (rawSnapshots is! List) return [];
      return rawSnapshots
          .whereType<Map>()
          .map((item) => RecommendationFunnelSnapshot.tryFromJson(
                Map<String, dynamic>.from(item),
              ))
          .whereType<RecommendationFunnelSnapshot>()
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _write(
    SharedPreferences prefs,
    List<RecommendationFunnelSnapshot> snapshots,
  ) async {
    snapshots.sort(_compareSnapshots);
    await prefs.setString(
      _storageKey,
      jsonEncode({
        'schema_version': schemaVersion,
        'snapshots': snapshots.map((snapshot) => snapshot.toJson()).toList(),
      }),
    );
  }

  bool _removeExpired(
    List<RecommendationFunnelSnapshot> snapshots, {
    required DateTime now,
  }) {
    final today = DateTime(now.year, now.month, now.day);
    final earliest = today.subtract(Duration(days: retentionDays - 1));
    final before = snapshots.length;
    snapshots.removeWhere((snapshot) => snapshot.day.isBefore(earliest));
    return snapshots.length != before;
  }

  RecommendationFunnelSnapshot _increment(
    RecommendationFunnelSnapshot snapshot,
    AnalyticsEventType eventType,
    Map<String, dynamic> properties,
  ) {
    switch (eventType) {
      case AnalyticsEventType.recommendationShown:
        return snapshot.copyWith(exposures: snapshot.exposures + 1);
      case AnalyticsEventType.recommendationClicked:
        final action = properties['action']?.toString();
        if (action == 'confirm') {
          return snapshot.copyWith(
            confirmations: snapshot.confirmations + 1,
          );
        }
        if (action == 'reroll') return snapshot;
        if (action == 'candidate_tap') {
          return snapshot.copyWith(
            candidateSelections: snapshot.candidateSelections + 1,
          );
        }
        return snapshot;
      case AnalyticsEventType.recommendationSkipped:
        return snapshot.copyWith(rerolls: snapshot.rerolls + 1);
      case AnalyticsEventType.foodFavoriteToggled:
        final isFavorited = properties['is_favorited'];
        if (isFavorited == true) {
          return snapshot.copyWith(favoriteAdds: snapshot.favoriteAdds + 1);
        }
        if (isFavorited == false) {
          return snapshot.copyWith(
            favoriteRemovals: snapshot.favoriteRemovals + 1,
          );
        }
        return snapshot;
      case AnalyticsEventType.tasteFeedbackGiven:
        final isPositive = properties['is_positive'];
        if (isPositive == true) {
          return snapshot.copyWith(
            positiveFeedback: snapshot.positiveFeedback + 1,
          );
        }
        if (isPositive == false) {
          return snapshot.copyWith(
            negativeFeedback: snapshot.negativeFeedback + 1,
          );
        }
        return snapshot;
      case AnalyticsEventType.recommendationExecutionStarted:
        return snapshot.copyWith(
          executionStarts: snapshot.executionStarts + 1,
        );
      case AnalyticsEventType.recommendationExecutionCompleted:
        return snapshot.copyWith(
          executionCompletions: snapshot.executionCompletions + 1,
        );
      case AnalyticsEventType.recommendationExecutionDeferred:
        return snapshot.copyWith(
          executionDeferrals: snapshot.executionDeferrals + 1,
        );
      case _:
        return snapshot;
    }
  }

  int _compareSnapshots(
    RecommendationFunnelSnapshot left,
    RecommendationFunnelSnapshot right,
  ) {
    final dayComparison = right.day.compareTo(left.day);
    if (dayComparison != 0) return dayComparison;
    final algorithmComparison =
        left.algorithmVersion.compareTo(right.algorithmVersion);
    if (algorithmComparison != 0) return algorithmComparison;
    final sourceComparison = left.primarySource.compareTo(right.primarySource);
    if (sourceComparison != 0) return sourceComparison;
    return left.resolutionStatus.compareTo(right.resolutionStatus);
  }

  static const Set<AnalyticsEventType> _supportedEventTypes = {
    AnalyticsEventType.recommendationShown,
    AnalyticsEventType.recommendationClicked,
    AnalyticsEventType.recommendationSkipped,
    AnalyticsEventType.foodFavoriteToggled,
    AnalyticsEventType.tasteFeedbackGiven,
    AnalyticsEventType.recommendationExecutionStarted,
    AnalyticsEventType.recommendationExecutionCompleted,
    AnalyticsEventType.recommendationExecutionDeferred,
  };
}

class _FunnelCohort {
  const _FunnelCohort({
    required this.day,
    required this.schemaVersion,
    required this.algorithmVersion,
    required this.primarySource,
    required this.resolutionStatus,
  });

  final DateTime day;
  final String schemaVersion;
  final String algorithmVersion;
  final String primarySource;
  final String resolutionStatus;

  RecommendationFunnelSnapshot get emptySnapshot {
    return RecommendationFunnelSnapshot(
      day: day,
      schemaVersion: schemaVersion,
      algorithmVersion: algorithmVersion,
      primarySource: primarySource,
      resolutionStatus: resolutionStatus,
    );
  }

  static _FunnelCohort? tryParse(
    Map<String, dynamic> properties, {
    required DateTime day,
  }) {
    final schemaVersion = properties['schema_version']?.toString().trim() ?? '';
    final algorithmVersion =
        properties['algorithm_version']?.toString().trim() ?? '';
    final primarySource = properties['primary_source']?.toString().trim() ?? '';
    final resolutionStatus =
        properties['resolution_status']?.toString().trim() ?? '';
    if (schemaVersion.isEmpty ||
        algorithmVersion.isEmpty ||
        primarySource.isEmpty ||
        resolutionStatus.isEmpty) {
      return null;
    }

    return _FunnelCohort(
      day: DateTime(day.year, day.month, day.day),
      schemaVersion: schemaVersion,
      algorithmVersion: algorithmVersion,
      primarySource: primarySource,
      resolutionStatus: resolutionStatus,
    );
  }
}
