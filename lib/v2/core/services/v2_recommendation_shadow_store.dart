import 'dart:convert';

import 'package:eatwhat_app/v2/core/data/models/recommendation_shadow_snapshot.dart';
import 'package:shared_preferences/shared_preferences.dart';

typedef V2ShadowPreferencesLoader = Future<SharedPreferences> Function();

class V2RecommendationShadowStore {
  V2RecommendationShadowStore({
    V2ShadowPreferencesLoader? preferencesLoader,
    DateTime Function()? clock,
    this.retentionDays = 30,
  })  : assert(retentionDays > 0),
        _preferencesLoader = preferencesLoader ?? SharedPreferences.getInstance,
        _clock = clock ?? DateTime.now;

  static final V2RecommendationShadowStore instance =
      V2RecommendationShadowStore();

  static const String schemaVersion = 'v1';
  static const String _storageKey = 'v2_recommendation_shadow_aggregates_v1';

  final V2ShadowPreferencesLoader _preferencesLoader;
  final DateTime Function() _clock;
  final int retentionDays;
  Future<void> _pendingOperation = Future<void>.value();

  Future<void> record(Map<String, dynamic> properties) {
    final observation = _ShadowObservation.tryParse(
      properties,
      day: _clock(),
    );
    if (observation == null) return Future<void>.value();

    return _enqueue(() async {
      final prefs = await _preferencesLoader();
      final snapshots = _decode(prefs.getString(_storageKey));
      _removeExpired(snapshots, now: _clock());
      final index = snapshots.indexWhere(
        (snapshot) => snapshot.belongsTo(
          day: observation.day,
          schemaVersion: observation.schemaVersion,
          baselineVersion: observation.baselineVersion,
          experimentVersion: observation.experimentVersion,
          recallPath: observation.recallPath,
        ),
      );
      final current = index < 0 ? observation.emptySnapshot : snapshots[index];
      final updated = current.addObservation(
        candidateCount: observation.candidateCount,
        comparisonDepth: observation.comparisonDepth,
        top1Changed: observation.top1Changed,
        topKOverlap: observation.topKOverlap,
        meanAbsoluteRankDisplacement: observation.meanAbsoluteRankDisplacement,
        observationMaxAbsoluteRankDisplacement:
            observation.maxAbsoluteRankDisplacement,
        baselineDiversity: observation.baselineDiversity,
        experimentDiversity: observation.experimentDiversity,
      );
      if (index < 0) {
        snapshots.add(updated);
      } else {
        snapshots[index] = updated;
      }
      await _write(prefs, snapshots);
    });
  }

  Future<List<RecommendationShadowSnapshot>> readSnapshots({
    DateTime? since,
  }) {
    return _enqueue(() async {
      final prefs = await _preferencesLoader();
      final snapshots = _decode(prefs.getString(_storageKey));
      final removedExpired = _removeExpired(snapshots, now: _clock());
      if (removedExpired) await _write(prefs, snapshots);

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
      return List<RecommendationShadowSnapshot>.unmodifiable(result);
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

  List<RecommendationShadowSnapshot> _decode(String? raw) {
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
          .map(
            (item) => RecommendationShadowSnapshot.tryFromJson(
              Map<String, dynamic>.from(item),
            ),
          )
          .whereType<RecommendationShadowSnapshot>()
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _write(
    SharedPreferences prefs,
    List<RecommendationShadowSnapshot> snapshots,
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
    List<RecommendationShadowSnapshot> snapshots, {
    required DateTime now,
  }) {
    final today = DateTime(now.year, now.month, now.day);
    final earliest = today.subtract(Duration(days: retentionDays - 1));
    final before = snapshots.length;
    snapshots.removeWhere((snapshot) => snapshot.day.isBefore(earliest));
    return before != snapshots.length;
  }

  int _compareSnapshots(
    RecommendationShadowSnapshot left,
    RecommendationShadowSnapshot right,
  ) {
    final dayComparison = right.day.compareTo(left.day);
    if (dayComparison != 0) return dayComparison;
    final baselineComparison =
        left.baselineVersion.compareTo(right.baselineVersion);
    if (baselineComparison != 0) return baselineComparison;
    final experimentComparison =
        left.experimentVersion.compareTo(right.experimentVersion);
    if (experimentComparison != 0) return experimentComparison;
    return left.recallPath.compareTo(right.recallPath);
  }
}

class _ShadowObservation {
  const _ShadowObservation({
    required this.day,
    required this.schemaVersion,
    required this.baselineVersion,
    required this.experimentVersion,
    required this.recallPath,
    required this.candidateCount,
    required this.comparisonDepth,
    required this.top1Changed,
    required this.topKOverlap,
    required this.meanAbsoluteRankDisplacement,
    required this.maxAbsoluteRankDisplacement,
    required this.baselineDiversity,
    required this.experimentDiversity,
  });

  final DateTime day;
  final String schemaVersion;
  final String baselineVersion;
  final String experimentVersion;
  final String recallPath;
  final int candidateCount;
  final int comparisonDepth;
  final bool top1Changed;
  final double topKOverlap;
  final double meanAbsoluteRankDisplacement;
  final int maxAbsoluteRankDisplacement;
  final double baselineDiversity;
  final double experimentDiversity;

  RecommendationShadowSnapshot get emptySnapshot {
    return RecommendationShadowSnapshot(
      day: day,
      schemaVersion: schemaVersion,
      baselineVersion: baselineVersion,
      experimentVersion: experimentVersion,
      recallPath: recallPath,
    );
  }

  static _ShadowObservation? tryParse(
    Map<String, dynamic> properties, {
    required DateTime day,
  }) {
    final schemaVersion = properties['schema_version']?.toString().trim() ?? '';
    final baselineVersion =
        properties['baseline_version']?.toString().trim() ?? '';
    final experimentVersion =
        properties['experiment_version']?.toString().trim() ?? '';
    final recallPath = properties['recall_path']?.toString().trim() ?? '';
    final candidateCount = _count(properties['candidate_count']);
    final comparisonDepth = _count(properties['comparison_depth']);
    final top1Changed = properties['top1_changed'];
    final topKOverlap = _rate(properties['top_k_overlap']);
    final meanDisplacement =
        _finiteNonNegative(properties['mean_absolute_rank_displacement']);
    final maxDisplacement =
        _count(properties['max_absolute_rank_displacement']);
    final baselineDiversity = _rate(properties['baseline_diversity']);
    final experimentDiversity = _rate(properties['experiment_diversity']);

    if (schemaVersion != V2RecommendationShadowStore.schemaVersion ||
        !_safeVersion.hasMatch(baselineVersion) ||
        !_safeVersion.hasMatch(experimentVersion) ||
        !_supportedRecallPaths.contains(recallPath) ||
        candidateCount == null ||
        candidateCount == 0 ||
        comparisonDepth == null ||
        comparisonDepth == 0 ||
        comparisonDepth > candidateCount ||
        top1Changed is! bool ||
        topKOverlap == null ||
        meanDisplacement == null ||
        maxDisplacement == null ||
        baselineDiversity == null ||
        experimentDiversity == null) {
      return null;
    }

    return _ShadowObservation(
      day: DateTime(day.year, day.month, day.day),
      schemaVersion: schemaVersion,
      baselineVersion: baselineVersion,
      experimentVersion: experimentVersion,
      recallPath: recallPath,
      candidateCount: candidateCount,
      comparisonDepth: comparisonDepth,
      top1Changed: top1Changed,
      topKOverlap: topKOverlap,
      meanAbsoluteRankDisplacement: meanDisplacement,
      maxAbsoluteRankDisplacement: maxDisplacement,
      baselineDiversity: baselineDiversity,
      experimentDiversity: experimentDiversity,
    );
  }

  static int? _count(dynamic value) {
    final parsed = value is int ? value : int.tryParse(value?.toString() ?? '');
    if (parsed == null || parsed < 0) return null;
    return parsed;
  }

  static double? _rate(dynamic value) {
    final parsed = _finiteNonNegative(value);
    if (parsed == null || parsed > 1) return null;
    return parsed;
  }

  static double? _finiteNonNegative(dynamic value) {
    final parsed = value is num
        ? value.toDouble()
        : double.tryParse(value?.toString() ?? '');
    if (parsed == null || !parsed.isFinite || parsed < 0) return null;
    return parsed;
  }

  static const Set<String> _supportedRecallPaths = {
    'direct',
    'defaultPool',
  };
  static final RegExp _safeVersion = RegExp(r'^[a-zA-Z0-9_.-]{1,64}$');
}
