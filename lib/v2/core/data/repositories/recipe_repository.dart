import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import '../models/recipe_model.dart';
import '../models/tag_model.dart';

class RecipeRepository {
  List<RecipeModel> _recipes = [];
  List<TagModel> _tags = [];

  Future<void> initialize() async {
    await _loadTags();
    await _loadRecipes();
  }

  Future<void> _loadRecipes() async {
    try {
      final String jsonString =
          await rootBundle.loadString('assets/data/recipes.json');
      final List<dynamic> jsonList = json.decode(jsonString);
      _recipes = jsonList.map((json) => RecipeModel.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error loading recipes: $e');
      _recipes = [];
    }
  }

  Future<void> _loadTags() async {
    try {
      final String jsonString =
          await rootBundle.loadString('assets/data/tags.json');
      final List<dynamic> jsonList = json.decode(jsonString);
      _tags = jsonList.map((json) => TagModel.fromJson(json)).toList();
    } catch (e) {
      debugPrint('Error loading tags: $e');
      _tags = [];
    }
  }

  List<RecipeModel> getAllRecipes() => _recipes;
  List<TagModel> getAllTags() => _tags;

  List<RecipeModel> getRecipesByTag(String tagId) {
    return _recipes.where((r) => r.tags.contains(tagId)).toList();
  }

  // 模拟AI推荐算法 (简单版)
  List<RecipeModel> recommendRecipes(List<String> selectedTagIds) {
    if (selectedTagIds.isEmpty) return _recipes.take(5).toList();

    // 简单的加权匹配
    final scoredRecipes = _recipes.map((recipe) {
      int score = 0;
      for (final tag in selectedTagIds) {
        if (recipe.tags.contains(tag)) {
          score++;
        }
      }
      return MapEntry(recipe, score);
    }).toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    // 返回前5个
    return scoredRecipes.take(5).map((e) => e.key).toList();
  }
}
