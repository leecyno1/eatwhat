import 'package:freezed_annotation/freezed_annotation.dart';

part 'recipe_model.freezed.dart';
part 'recipe_model.g.dart';

@freezed
class RecipeModel with _$RecipeModel {
  const factory RecipeModel({
    required String id,
    required String name,
    required String description,
    @Default([]) List<String> ingredients,
    @Default([]) List<String> steps,
    @Default('medium') String difficulty,
    @Default([]) List<String> tags,
    @Default('HowToCook') String source,
    String? imageUrl, // AI生成的图片URL
  }) = _RecipeModel;

  factory RecipeModel.fromJson(Map<String, dynamic> json) =>
      _$RecipeModelFromJson(json);

  factory RecipeModel.fromUnifiedDbRow(Map<String, dynamic> row) {
    final ingredients = (row['ingredients'] as List<dynamic>? ?? const [])
        .map((e) => (e as Map)['name']?.toString() ?? '')
        .where((e) => e.isNotEmpty)
        .toList();
    final steps = (row['steps'] as List<dynamic>? ?? const [])
        .map((e) => (e as Map)['description']?.toString() ?? '')
        .where((e) => e.isNotEmpty)
        .toList();

    final tags = <String>{...List<String>.from(row['tags'] ?? const [])}
      ..addAll(List<String>.from(row['scenes'] ?? const []))
      ..addAll(List<String>.from(row['health_tags'] ?? const []));

    return RecipeModel(
      id: row['dish_id'].toString(),
      name: row['dish_name']?.toString() ?? '',
      description: row['recipe_description']?.toString() ?? '',
      ingredients: ingredients.take(10).toList(),
      steps: steps.take(10).toList(),
      difficulty: (row['difficulty'] ?? 3).toString(),
      tags: tags.take(12).toList(),
      source: row['source']?.toString() ?? 'unified_db',
      imageUrl: row['cover_image_url']?.toString(),
    );
  }
}
