import 'package:eatwhat_app/v2/core/data/models/recipe_model.dart';

class ResultChoiceController {
  ResultChoiceController(List<RecipeModel> recommendations)
      : _availableChoices = List<RecipeModel>.from(recommendations),
        _currentChoice =
            recommendations.isNotEmpty ? recommendations.first : null;

  List<RecipeModel> _availableChoices;
  RecipeModel? _currentChoice;

  List<RecipeModel> get availableChoices =>
      List<RecipeModel>.unmodifiable(_availableChoices);

  RecipeModel? get currentChoice => _currentChoice;

  bool get hasCurrentChoice => _currentChoice != null;

  bool get canReroll => _currentChoice != null && _availableChoices.length > 1;

  RecipeModel? nextChoice() {
    final currentChoice = _currentChoice;
    if (currentChoice == null || _availableChoices.length <= 1) {
      return null;
    }
    final currentIndex = _availableChoices.indexWhere(
      (recipe) => recipe.id == currentChoice.id,
    );
    if (currentIndex == -1) return null;
    final nextIndex = (currentIndex + 1) % _availableChoices.length;
    return _availableChoices[nextIndex];
  }

  bool select(RecipeModel recipe) {
    if (recipe.id == _currentChoice?.id) return false;
    _currentChoice = recipe;
    return true;
  }

  void replaceCurrent(RecipeModel recipe) {
    _currentChoice = recipe;
    _availableChoices = _availableChoices.map((item) {
      return item.id == recipe.id ? recipe : item;
    }).toList();
  }

  /// Replaces the whole candidate list with an AI-refined ordering while
  /// keeping the currently-viewed dish selected when it survives the
  /// refinement (so an in-flight read isn't yanked away mid-look).
  void replaceAllPreserving(List<RecipeModel> next) {
    if (next.isEmpty) return;
    final currentId = _currentChoice?.id;
    _availableChoices = List<RecipeModel>.from(next);
    RecipeModel? preserved;
    if (currentId != null) {
      for (final recipe in next) {
        if (recipe.id == currentId) {
          preserved = recipe;
          break;
        }
      }
    }
    _currentChoice = preserved ?? next.first;
  }
}
