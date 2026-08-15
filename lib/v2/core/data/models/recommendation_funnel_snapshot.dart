class RecommendationFunnelSnapshot {
  const RecommendationFunnelSnapshot({
    required this.day,
    required this.schemaVersion,
    required this.algorithmVersion,
    required this.primarySource,
    required this.resolutionStatus,
    this.exposures = 0,
    this.candidateSelections = 0,
    this.confirmations = 0,
    this.rerolls = 0,
    this.favoriteAdds = 0,
    this.favoriteRemovals = 0,
    this.positiveFeedback = 0,
    this.negativeFeedback = 0,
    this.executionStarts = 0,
    this.executionCompletions = 0,
    this.executionDeferrals = 0,
  });

  final DateTime day;
  final String schemaVersion;
  final String algorithmVersion;
  final String primarySource;
  final String resolutionStatus;
  final int exposures;
  final int candidateSelections;
  final int confirmations;
  final int rerolls;
  final int favoriteAdds;
  final int favoriteRemovals;
  final int positiveFeedback;
  final int negativeFeedback;
  final int executionStarts;
  final int executionCompletions;
  final int executionDeferrals;

  int get selectionActions => candidateSelections + confirmations;

  double get selectionActionsPerExposure => _ratio(selectionActions, exposures);

  double get rerollsPerExposure => _ratio(rerolls, exposures);

  double get executionStartRate => _ratio(executionStarts, exposures);

  double get executionCompletionRate =>
      _ratio(executionCompletions, executionStarts);

  double get executionDeferralRate =>
      _ratio(executionDeferrals, executionStarts);

  bool belongsTo({
    required DateTime day,
    required String schemaVersion,
    required String algorithmVersion,
    required String primarySource,
    required String resolutionStatus,
  }) {
    return _dayKey(this.day) == _dayKey(day) &&
        this.schemaVersion == schemaVersion &&
        this.algorithmVersion == algorithmVersion &&
        this.primarySource == primarySource &&
        this.resolutionStatus == resolutionStatus;
  }

  RecommendationFunnelSnapshot copyWith({
    int? exposures,
    int? candidateSelections,
    int? confirmations,
    int? rerolls,
    int? favoriteAdds,
    int? favoriteRemovals,
    int? positiveFeedback,
    int? negativeFeedback,
    int? executionStarts,
    int? executionCompletions,
    int? executionDeferrals,
  }) {
    return RecommendationFunnelSnapshot(
      day: day,
      schemaVersion: schemaVersion,
      algorithmVersion: algorithmVersion,
      primarySource: primarySource,
      resolutionStatus: resolutionStatus,
      exposures: exposures ?? this.exposures,
      candidateSelections: candidateSelections ?? this.candidateSelections,
      confirmations: confirmations ?? this.confirmations,
      rerolls: rerolls ?? this.rerolls,
      favoriteAdds: favoriteAdds ?? this.favoriteAdds,
      favoriteRemovals: favoriteRemovals ?? this.favoriteRemovals,
      positiveFeedback: positiveFeedback ?? this.positiveFeedback,
      negativeFeedback: negativeFeedback ?? this.negativeFeedback,
      executionStarts: executionStarts ?? this.executionStarts,
      executionCompletions: executionCompletions ?? this.executionCompletions,
      executionDeferrals: executionDeferrals ?? this.executionDeferrals,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'day': _dayKey(day),
      'schema_version': schemaVersion,
      'algorithm_version': algorithmVersion,
      'primary_source': primarySource,
      'resolution_status': resolutionStatus,
      'exposures': exposures,
      'candidate_selections': candidateSelections,
      'confirmations': confirmations,
      'rerolls': rerolls,
      'favorite_adds': favoriteAdds,
      'favorite_removals': favoriteRemovals,
      'positive_feedback': positiveFeedback,
      'negative_feedback': negativeFeedback,
      'execution_starts': executionStarts,
      'execution_completions': executionCompletions,
      'execution_deferrals': executionDeferrals,
    };
  }

  static RecommendationFunnelSnapshot? tryFromJson(
    Map<String, dynamic> json,
  ) {
    final day = DateTime.tryParse(json['day']?.toString() ?? '');
    final schemaVersion = json['schema_version']?.toString().trim() ?? '';
    final algorithmVersion = json['algorithm_version']?.toString().trim() ?? '';
    final primarySource = json['primary_source']?.toString().trim() ?? '';
    final resolutionStatus = json['resolution_status']?.toString().trim() ?? '';
    if (day == null ||
        schemaVersion.isEmpty ||
        algorithmVersion.isEmpty ||
        primarySource.isEmpty ||
        resolutionStatus.isEmpty) {
      return null;
    }

    return RecommendationFunnelSnapshot(
      day: DateTime(day.year, day.month, day.day),
      schemaVersion: schemaVersion,
      algorithmVersion: algorithmVersion,
      primarySource: primarySource,
      resolutionStatus: resolutionStatus,
      exposures: _count(json['exposures']),
      candidateSelections: _count(json['candidate_selections']),
      confirmations: _count(json['confirmations']),
      rerolls: _count(json['rerolls']),
      favoriteAdds: _count(json['favorite_adds']),
      favoriteRemovals: _count(json['favorite_removals']),
      positiveFeedback: _count(json['positive_feedback']),
      negativeFeedback: _count(json['negative_feedback']),
      executionStarts: _count(json['execution_starts']),
      executionCompletions: _count(json['execution_completions']),
      executionDeferrals: _count(json['execution_deferrals']),
    );
  }

  static double _ratio(int numerator, int denominator) {
    if (denominator <= 0) return 0;
    return numerator / denominator;
  }

  static int _count(dynamic value) {
    final parsed = value is int ? value : int.tryParse(value?.toString() ?? '');
    if (parsed == null || parsed < 0) return 0;
    return parsed;
  }

  static String _dayKey(DateTime value) {
    final month = value.month.toString().padLeft(2, '0');
    final day = value.day.toString().padLeft(2, '0');
    return '${value.year}-$month-$day';
  }
}
