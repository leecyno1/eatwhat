import 'package:eatwhat_app/v2/core/data/models/recipe_model.dart';
import 'package:eatwhat_app/v2/core/data/models/recommendation_resolution.dart';
import 'package:eatwhat_app/v2/core/data/models/taste_inference_input.dart';
import 'package:eatwhat_app/v2/core/services/v2_phase2_recommendation_service.dart';

typedef V2RecommendationEvalRunner = Future<Phase2RecommendationBundle>
    Function(
  TasteInferenceInput input,
);

class V2RecommendationEvalCase {
  const V2RecommendationEvalCase({
    required this.id,
    required this.label,
    required this.input,
    this.minResults = 3,
    this.minDiversity = 0.4,
    this.forbiddenTerms = const [],
    this.relevantTerms = const [],
    this.expectedConstraints = const [],
    this.critical = false,
  });

  final String id;
  final String label;
  final TasteInferenceInput input;
  final int minResults;
  final double minDiversity;
  final List<String> forbiddenTerms;
  final List<String> relevantTerms;
  final List<String> expectedConstraints;
  final bool critical;
}

class V2RecommendationEvalObservation {
  const V2RecommendationEvalObservation({
    required this.evalCase,
    required this.bundle,
    required this.latencyBudget,
  });

  final V2RecommendationEvalCase evalCase;
  final Phase2RecommendationBundle bundle;
  final Duration latencyBudget;

  List<String> get recipeIds =>
      bundle.finalRecommendations.map((recipe) => recipe.id).toList();

  bool get hasCanonicalIdentity {
    final recipes = bundle.finalRecommendations;
    final ids = recipes.map((recipe) => recipe.id.trim()).toList();
    final normalizedNames = recipes
        .map((recipe) => recipe.name.trim().toLowerCase())
        .where((name) => name.isNotEmpty)
        .toList();
    return bundle.primarySource == 'unified_db' &&
        bundle.algorithmVersion ==
            V2Phase2RecommendationService.algorithmVersion &&
        bundle.resolutionStatus == RecommendationResolutionStatus.dbResolved &&
        recipes.isNotEmpty &&
        ids.every((id) => int.tryParse(id) != null) &&
        ids.toSet().length == ids.length &&
        normalizedNames.toSet().length == normalizedNames.length &&
        recipes.every(
          (recipe) =>
              recipe.name.trim().isNotEmpty && !_isPlaceholderRecipe(recipe),
        );
  }

  bool get hasEnoughResults =>
      bundle.finalRecommendations.length >= evalCase.minResults;

  bool get passesHardConstraints {
    if (evalCase.forbiddenTerms.isEmpty) return true;
    return bundle.finalRecommendations.every(
      (recipe) => !_containsAny(_recipeText(recipe), evalCase.forbiddenTerms),
    );
  }

  bool get reportsExpectedConstraints => evalCase.expectedConstraints.every(
        bundle.appliedConstraints.contains,
      );

  bool get hasRelevantCandidate {
    if (evalCase.relevantTerms.isEmpty) return true;
    return bundle.finalRecommendations.any(
      (recipe) => _containsAny(_recipeText(recipe), evalCase.relevantTerms),
    );
  }

  bool get passesDiversity => bundle.diversityScore >= evalCase.minDiversity;

  bool get passesLatency => bundle.latency < latencyBudget;

  bool get passed => failures.isEmpty;

  List<String> get failures => [
        if (!hasCanonicalIdentity) 'canonical_identity',
        if (!hasEnoughResults)
          'coverage(${bundle.finalRecommendations.length}/${evalCase.minResults})',
        if (!passesHardConstraints)
          'hard_constraint(${_violatingTerms().join(',')})',
        if (!reportsExpectedConstraints) 'constraint_reporting',
        if (!hasRelevantCandidate) 'relevance',
        if (!passesDiversity)
          'diversity(${bundle.diversityScore.toStringAsFixed(2)}/${evalCase.minDiversity.toStringAsFixed(2)})',
        if (!passesLatency)
          'latency(${bundle.latency.inMilliseconds}ms/${latencyBudget.inMilliseconds}ms)',
      ];

  Set<String> _violatingTerms() {
    final terms = <String>{};
    for (final recipe in bundle.finalRecommendations) {
      final text = _recipeText(recipe);
      terms.addAll(evalCase.forbiddenTerms.where(text.contains));
    }
    return terms;
  }
}

class V2RecommendationEvalReport {
  const V2RecommendationEvalReport(this.observations);

  final List<V2RecommendationEvalObservation> observations;

  double get passAt1 => _rate(observations.where((item) => item.passed).length);

  double get canonicalIdentityRate =>
      _rate(observations.where((item) => item.hasCanonicalIdentity).length);

  double get hardConstraintPassRate =>
      _rate(observations.where((item) => item.passesHardConstraints).length);

  double get coverageRate =>
      _rate(observations.where((item) => item.hasEnoughResults).length);

  double get averageDiversity {
    if (observations.isEmpty) return 0;
    final total = observations.fold<double>(
      0,
      (sum, item) => sum + item.bundle.diversityScore,
    );
    return total / observations.length;
  }

  Duration get p95Latency {
    if (observations.isEmpty) return Duration.zero;
    final values = observations.map((item) => item.bundle.latency).toList()
      ..sort();
    final index =
        ((values.length * 0.95).ceil() - 1).clamp(0, values.length - 1);
    return values[index];
  }

  List<V2RecommendationEvalObservation> get failedObservations =>
      observations.where((item) => !item.passed).toList();

  String format() {
    final cases = observations.map((item) {
      final status = item.passed ? 'PASS' : 'FAIL:${item.failures.join('|')}';
      return '${item.evalCase.id}=$status/'
          '${item.bundle.finalRecommendations.length}results/'
          '${item.bundle.diversityScore.toStringAsFixed(2)}div/'
          '${item.bundle.latency.inMilliseconds}ms';
    }).join('; ');
    return 'pass@1=${_percent(passAt1)}, '
        'canonical=${_percent(canonicalIdentityRate)}, '
        'constraints=${_percent(hardConstraintPassRate)}, '
        'coverage=${_percent(coverageRate)}, '
        'avgDiversity=${averageDiversity.toStringAsFixed(2)}, '
        'p95=${p95Latency.inMilliseconds}ms | $cases';
  }

  double _rate(int passedCount) {
    if (observations.isEmpty) return 0;
    return passedCount / observations.length;
  }

  String _percent(double value) => '${(value * 100).toStringAsFixed(0)}%';
}

class V2RecommendationEvalHarness {
  const V2RecommendationEvalHarness({
    required V2RecommendationEvalRunner runner,
    this.latencyBudget = const Duration(seconds: 3),
  }) : _runner = runner;

  final V2RecommendationEvalRunner _runner;
  final Duration latencyBudget;

  Future<V2RecommendationEvalReport> run(
    List<V2RecommendationEvalCase> cases,
  ) async {
    final observations = <V2RecommendationEvalObservation>[];
    for (final evalCase in cases) {
      observations.add(await runCase(evalCase));
    }
    return V2RecommendationEvalReport(observations);
  }

  Future<V2RecommendationEvalObservation> runCase(
    V2RecommendationEvalCase evalCase,
  ) async {
    final bundle = await _runner(evalCase.input);
    return V2RecommendationEvalObservation(
      evalCase: evalCase,
      bundle: bundle,
      latencyBudget: latencyBudget,
    );
  }
}

String _recipeText(RecipeModel recipe) {
  return [
    recipe.name,
    recipe.description,
    ...recipe.ingredients,
    ...recipe.tags,
  ].join('|');
}

bool _containsAny(String text, Iterable<String> terms) {
  return terms.any(text.contains);
}

bool _isPlaceholderRecipe(RecipeModel recipe) {
  final name = recipe.name.trim().toLowerCase();
  return name.contains('示例菜谱') ||
      name.startsWith('soup_') ||
      name.startsWith('dessert_') ||
      name.startsWith('drink_') ||
      name.startsWith('condiment_') ||
      name.startsWith('semi-finished_') ||
      name.startsWith('aquatic_');
}
