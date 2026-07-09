import 'package:eatwhat_app/v2/core/data/models/recipe_model.dart';

class HowToCookRecipeDetail {
  const HowToCookRecipeDetail({
    required this.id,
    required this.name,
    required this.description,
    required this.ingredients,
    required this.steps,
    required this.imageAssetUrls,
    required this.category,
    required this.subcategory,
    required this.difficulty,
    required this.cookingTimeMinutes,
    required this.servings,
    required this.githubUrl,
    required this.sourceProject,
    required this.markdownPath,
    this.aliases = const [],
  });

  final String id;
  final String name;
  final String description;
  final List<String> ingredients;
  final List<String> steps;
  final List<String> imageAssetUrls;
  final List<String> aliases;
  final String category;
  final String subcategory;
  final int difficulty;
  final int? cookingTimeMinutes;
  final int? servings;
  final String githubUrl;
  final String sourceProject;
  final String markdownPath;

  RecipeModel toRecipeModel({
    String? fallbackId,
    String? fallbackSource,
    List<String> extraTags = const [],
  }) {
    final tags = <String>[
      if (category.trim().isNotEmpty) category.trim(),
      if (subcategory.trim().isNotEmpty) subcategory.trim(),
      ...extraTags.where((item) => item.trim().isNotEmpty),
    ].toSet().toList();

    return RecipeModel(
      id: fallbackId ?? id,
      name: name,
      description: description,
      ingredients: ingredients,
      steps: steps,
      difficulty: difficulty.toString(),
      tags: tags,
      source: fallbackSource ?? 'HowToCook',
      imageUrl: imageAssetUrls.isNotEmpty ? imageAssetUrls.first : null,
    );
  }
}
