import 'recipe_model.dart';

class DishModel {
  const DishModel({
    required this.id,
    required this.name,
    this.description = '',
    this.tags = const [],
    this.source = 'unknown',
    this.imageUrl,
  });

  factory DishModel.fromRecipe(RecipeModel recipe) {
    return DishModel(
      id: recipe.dishId,
      name: recipe.name,
      description: recipe.description,
      tags: recipe.tags,
      source: recipe.source,
      imageUrl: recipe.imageUrl,
    );
  }

  factory DishModel.fromUnifiedDbRow(Map<String, dynamic> row) {
    final tags = <String>{...List<String>.from(row['tags'] ?? const [])}
      ..addAll(List<String>.from(row['scenes'] ?? const []))
      ..addAll(List<String>.from(row['health_tags'] ?? const []));

    return DishModel(
      id: row['dish_id']?.toString() ?? '',
      name: row['dish_name']?.toString() ?? '',
      description: row['recipe_description']?.toString() ?? '',
      tags: tags.take(12).toList(),
      source: row['source']?.toString() ?? 'unified_db',
      imageUrl: row['cover_image_url']?.toString(),
    );
  }

  final String id;
  final String name;
  final String description;
  final List<String> tags;
  final String source;
  final String? imageUrl;
}

extension RecipeDishIdentity on RecipeModel {
  String get dishId => id;

  DishModel get dish => DishModel.fromRecipe(this);
}
