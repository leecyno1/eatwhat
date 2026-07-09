import 'package:freezed_annotation/freezed_annotation.dart';

part 'unified_recipe_model.freezed.dart';
part 'unified_recipe_model.g.dart';

@freezed
class UnifiedRecipeModel with _$UnifiedRecipeModel {
  const factory UnifiedRecipeModel({
    required String id,
    required String name,
    required String description,
    @Default([]) List<String> images,
    @Default([]) List<String> tagIds,

    // Home Cooking Details
    @Default([]) List<RecipeIngredient> ingredients,
    @Default([]) List<RecipeIngredient> seasonings,
    @Default([]) List<RecipeStep> steps,

    // External Links
    @Default([]) List<RestaurantLink> restaurants,
    @Default([]) List<DeliveryLink> deliveryOptions,

    // AI Analysis
    NutritionInfo? nutrition,
    @Default([]) List<String> pairingIds,
  }) = _UnifiedRecipeModel;

  factory UnifiedRecipeModel.fromJson(Map<String, dynamic> json) =>
      _$UnifiedRecipeModelFromJson(json);
}

@freezed
class RecipeIngredient with _$RecipeIngredient {
  const factory RecipeIngredient({
    required String name,
    required String amount,
    String? note,
  }) = _RecipeIngredient;

  factory RecipeIngredient.fromJson(Map<String, dynamic> json) =>
      _$RecipeIngredientFromJson(json);
}

@freezed
class RecipeStep with _$RecipeStep {
  const factory RecipeStep({
    required int index,
    required String description,
    String? imageUrl,
    int? durationSeconds,
  }) = _RecipeStep;

  factory RecipeStep.fromJson(Map<String, dynamic> json) =>
      _$RecipeStepFromJson(json);
}

@freezed
class RestaurantLink with _$RestaurantLink {
  const factory RestaurantLink({
    required String name,
    required String platform, // dianping, meituan
    required String url,
    double? rating,
    double? pricePerPerson,
  }) = _RestaurantLink;

  factory RestaurantLink.fromJson(Map<String, dynamic> json) =>
      _$RestaurantLinkFromJson(json);
}

@freezed
class DeliveryLink with _$DeliveryLink {
  const factory DeliveryLink({
    required String storeName,
    required String platform, // meituan, eleme
    required String url,
    int? deliveryTimeMinutes,
  }) = _DeliveryLink;

  factory DeliveryLink.fromJson(Map<String, dynamic> json) =>
      _$DeliveryLinkFromJson(json);
}

@freezed
class NutritionInfo with _$NutritionInfo {
  const factory NutritionInfo({
    required int calories,
    required double protein,
    required double fat,
    required double carbs,
    String? analysis,
  }) = _NutritionInfo;

  factory NutritionInfo.fromJson(Map<String, dynamic> json) =>
      _$NutritionInfoFromJson(json);
}
