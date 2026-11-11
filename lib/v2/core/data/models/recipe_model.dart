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
    // 0 means unknown. Only fill from checked structured metadata; never
    // substitute an AI estimate for a verified cooking time.
    @Default(0) int totalTimeMinutes,
    // 1 means unknown or a single portion. Only values above 1 are treated
    // as a verified multi-serving quantity by the UI.
    @Default(1) int servings,
  }) = _RecipeModel;

  factory RecipeModel.fromJson(Map<String, dynamic> json) =>
      _$RecipeModelFromJson(json);

  factory RecipeModel.fromUnifiedDbRow(Map<String, dynamic> row) {
    final ingredients = (row['ingredients'] as List<dynamic>? ?? const [])
        .whereType<Map>()
        .map(
          (e) => _ingredientLine(
            e['name']?.toString() ?? '',
            e['amount']?.toString() ?? '',
            e['unit']?.toString() ?? '',
          ),
        )
        .where((line) => line.isNotEmpty)
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
      // Keep source data complete for ingredient checks and cooking. Preview
      // limits belong in widgets, not in the recipe used for execution.
      ingredients: ingredients,
      steps: steps,
      difficulty: (row['difficulty'] ?? 3).toString(),
      tags: tags.toList(),
      source: row['source']?.toString() ?? 'unified_db',
      imageUrl: row['cover_image_url']?.toString(),
      totalTimeMinutes: _positiveInt(row['total_time_minutes']),
      servings: _positiveInt(row['servings']).clamp(1, 99),
    );
  }
}

int _positiveInt(dynamic value) {
  final number =
      value is num ? value.toInt() : int.tryParse(value?.toString() ?? '');
  return number != null && number > 0 ? number : 0;
}

/// Keep amounts adjacent to their unit (`2只`) so the detail page can scale
/// lines reliably; the scaler expects a number followed by a non-space unit.
String _ingredientLine(String name, String amount, String unit) {
  final cleanName = name.trim();
  final quantity = '${amount.trim()}${unit.trim()}';
  return [cleanName, quantity].where((part) => part.isNotEmpty).join(' ');
}
