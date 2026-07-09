import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

class V2RecipeExecutionProgressService {
  V2RecipeExecutionProgressService._internal();

  static final V2RecipeExecutionProgressService instance =
      V2RecipeExecutionProgressService._internal();

  static const _keyPrefix = 'v2_recipe_execution_progress_';
  static const _keyShoppingPrefix = 'v2_recipe_shopping_';

  Future<Set<int>> getCompletedStepIndexes(String recipeId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyFor(recipeId));
    if (raw == null || raw.trim().isEmpty) return {};

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return {};
      return decoded
          .map((item) => item is int ? item : int.tryParse(item.toString()))
          .whereType<int>()
          .where((index) => index >= 0)
          .toSet();
    } catch (_) {
      return {};
    }
  }

  Future<void> saveCompletedStepIndexes(
    String recipeId,
    Set<int> completedStepIndexes,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final sorted = completedStepIndexes.toList()..sort();
    await prefs.setString(_keyFor(recipeId), jsonEncode(sorted));
  }

  String _keyFor(String recipeId) {
    return '$_keyPrefix${recipeId.trim()}';
  }

  Future<Set<int>> getCompletedShoppingIndexes(String recipeId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_shoppingKeyFor(recipeId));
    if (raw == null || raw.trim().isEmpty) return {};

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return {};
      return decoded
          .map((item) => item is int ? item : int.tryParse(item.toString()))
          .whereType<int>()
          .where((index) => index >= 0)
          .toSet();
    } catch (_) {
      return {};
    }
  }

  Future<void> saveCompletedShoppingIndexes(
    String recipeId,
    Set<int> completedShoppingIndexes,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final sorted = completedShoppingIndexes.toList()..sort();
    await prefs.setString(_shoppingKeyFor(recipeId), jsonEncode(sorted));
  }

  String _shoppingKeyFor(String recipeId) {
    return '$_keyShoppingPrefix${recipeId.trim()}';
  }
}
