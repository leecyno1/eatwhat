import 'package:eatwhat_app/v2/core/data/models/ai_generation_models.dart';

enum PairingLoadState { loading, loaded, fallback }

enum NutritionLoadState { loading, loaded, unavailable }

class ResultEnrichmentController<TPairing> {
  final Map<String, NutritionAnalysis> _nutritionByRecipeId = {};
  final Map<String, List<TPairing>> _pairingsByRecipeId = {};
  final Map<String, PairingLoadState> _pairingStateByRecipeId = {};
  final Map<String, NutritionLoadState> _nutritionStateByRecipeId = {};
  final Map<String, String> _introByRecipeId = {};
  final Map<String, bool> _introLoadingByRecipeId = {};

  String? introFor(String recipeId) {
    final intro = _introByRecipeId[recipeId]?.trim() ?? '';
    return intro.isEmpty ? null : intro;
  }

  bool isIntroLoading(String recipeId) {
    return _introLoadingByRecipeId[recipeId] == true;
  }

  void markIntroLoading(String recipeId) {
    _introLoadingByRecipeId[recipeId] = true;
  }

  void completeIntro(String recipeId, String? intro) {
    final normalized = intro?.trim() ?? '';
    if (normalized.isNotEmpty) {
      _introByRecipeId[recipeId] = normalized;
    }
    _introLoadingByRecipeId[recipeId] = false;
  }

  void failIntro(String recipeId) {
    _introLoadingByRecipeId[recipeId] = false;
  }

  List<TPairing>? pairingsFor(String recipeId) {
    final pairings = _pairingsByRecipeId[recipeId];
    if (pairings == null) return null;
    return List<TPairing>.unmodifiable(pairings);
  }

  bool hasPairings(String recipeId) {
    final pairings = _pairingsByRecipeId[recipeId];
    return pairings != null && pairings.isNotEmpty;
  }

  PairingLoadState pairingStateFor(String recipeId) {
    return _pairingStateByRecipeId[recipeId] ?? PairingLoadState.loading;
  }

  void markPairingsLoading(String recipeId) {
    _pairingStateByRecipeId[recipeId] = PairingLoadState.loading;
  }

  void completePairings(String recipeId, List<TPairing> pairings) {
    _pairingsByRecipeId[recipeId] = List<TPairing>.unmodifiable(pairings);
    _pairingStateByRecipeId[recipeId] = PairingLoadState.loaded;
  }

  void completeFallbackPairings(String recipeId, List<TPairing> pairings) {
    _pairingsByRecipeId[recipeId] = List<TPairing>.unmodifiable(pairings);
    _pairingStateByRecipeId[recipeId] = PairingLoadState.fallback;
  }

  NutritionAnalysis? nutritionFor(String recipeId) {
    return _nutritionByRecipeId[recipeId];
  }

  NutritionLoadState nutritionStateFor(String recipeId) {
    return _nutritionStateByRecipeId[recipeId] ?? NutritionLoadState.loading;
  }

  void markNutritionLoading(String recipeId) {
    _nutritionStateByRecipeId[recipeId] = NutritionLoadState.loading;
  }

  void completeNutrition(String recipeId, NutritionAnalysis nutrition) {
    _nutritionByRecipeId[recipeId] = nutrition;
    _nutritionStateByRecipeId[recipeId] = NutritionLoadState.loaded;
  }

  void markNutritionUnavailable(String recipeId) {
    _nutritionStateByRecipeId[recipeId] = NutritionLoadState.unavailable;
  }
}
