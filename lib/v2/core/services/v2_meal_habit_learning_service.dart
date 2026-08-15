import 'dart:convert';

import 'package:eatwhat_app/v2/core/data/models/meal_planning_direction.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MealHabitSnapshot {
  const MealHabitSnapshot({
    required this.recommendedDirection,
    required this.evidenceCount,
    required this.confidence,
    required this.insight,
  });

  final MealPlanningDirection recommendedDirection;
  final int evidenceCount;
  final double confidence;
  final String insight;
}

class V2MealHabitLearningService {
  V2MealHabitLearningService._internal();

  static final V2MealHabitLearningService instance =
      V2MealHabitLearningService._internal();

  static const _directionScoresKey = 'v2_meal_direction_scores_json';

  static const _healthSignals = {
    'f_light',
    'i_vegetable',
    'i_fish',
    'i_egg',
    'i_tofu',
    'd_vegetarian',
    'd_light',
    'd_low_carb',
    'd_high_protein',
  };

  static const _experienceSignals = {
    'f_spicy',
    'f_numbing',
    'f_rich',
    'f_smoky',
    'f_curry',
    'c_hotpot',
    'c_bbq',
    'm_surprise',
  };

  Future<MealHabitSnapshot> buildSnapshot({
    required Map<String, int> tagScores,
  }) async {
    final stored = await _loadDirectionScores();
    var healthScore = stored[MealPlanningDirection.health.name] ?? 0;
    var experienceScore = stored[MealPlanningDirection.experience.name] ?? 0;
    final balancedScore = stored[MealPlanningDirection.balanced.name] ?? 0;
    var evidenceCount = stored.values.fold<int>(0, (sum, value) => sum + value);

    for (final entry in tagScores.entries) {
      if (entry.value <= 0) continue;
      final contribution = entry.value.clamp(0, 12);
      if (_healthSignals.contains(entry.key)) {
        healthScore += contribution;
        evidenceCount += 1;
      }
      if (_experienceSignals.contains(entry.key)) {
        experienceScore += contribution;
        evidenceCount += 1;
      }
    }

    final scores = <MealPlanningDirection, int>{
      MealPlanningDirection.balanced: balancedScore,
      MealPlanningDirection.health: healthScore,
      MealPlanningDirection.experience: experienceScore,
    };
    final ranked = scores.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final best = ranked.first;
    final total = scores.values.fold<int>(0, (sum, value) => sum + value);
    final recommended = total == 0 ? MealPlanningDirection.balanced : best.key;
    final confidence = total == 0 ? 0.0 : best.value / total;

    return MealHabitSnapshot(
      recommendedDirection: recommended,
      evidenceCount: evidenceCount,
      confidence: confidence,
      insight: evidenceCount == 0
          ? '还没有足够历史，先从均衡开始'
          : '根据最近习惯，今天更适合${recommended.label}',
    );
  }

  Future<void> recordDirection(MealPlanningDirection direction) async {
    final prefs = await SharedPreferences.getInstance();
    final scores = await _loadDirectionScores();
    final next = Map<String, int>.from(scores);
    next[direction.name] = ((next[direction.name] ?? 0) + 1).clamp(0, 200);
    await prefs.setString(_directionScoresKey, jsonEncode(next));
  }

  Future<Map<String, int>> _loadDirectionScores() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_directionScoresKey);
    if (raw == null || raw.trim().isEmpty) return {};
    try {
      final decoded = jsonDecode(raw);
      if (decoded is! Map) return {};
      return decoded.map(
        (key, value) => MapEntry(
          key.toString(),
          value is int ? value : int.tryParse(value.toString()) ?? 0,
        ),
      );
    } catch (_) {
      return {};
    }
  }
}
