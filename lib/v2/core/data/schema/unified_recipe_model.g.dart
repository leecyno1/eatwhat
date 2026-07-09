// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'unified_recipe_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$UnifiedRecipeModelImpl _$$UnifiedRecipeModelImplFromJson(
        Map<String, dynamic> json) =>
    _$UnifiedRecipeModelImpl(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      images: (json['images'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      tagIds: (json['tagIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      ingredients: (json['ingredients'] as List<dynamic>?)
              ?.map((e) => RecipeIngredient.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      seasonings: (json['seasonings'] as List<dynamic>?)
              ?.map((e) => RecipeIngredient.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      steps: (json['steps'] as List<dynamic>?)
              ?.map((e) => RecipeStep.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      restaurants: (json['restaurants'] as List<dynamic>?)
              ?.map((e) => RestaurantLink.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      deliveryOptions: (json['deliveryOptions'] as List<dynamic>?)
              ?.map((e) => DeliveryLink.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      nutrition: json['nutrition'] == null
          ? null
          : NutritionInfo.fromJson(json['nutrition'] as Map<String, dynamic>),
      pairingIds: (json['pairingIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
    );

Map<String, dynamic> _$$UnifiedRecipeModelImplToJson(
        _$UnifiedRecipeModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'images': instance.images,
      'tagIds': instance.tagIds,
      'ingredients': instance.ingredients,
      'seasonings': instance.seasonings,
      'steps': instance.steps,
      'restaurants': instance.restaurants,
      'deliveryOptions': instance.deliveryOptions,
      'nutrition': instance.nutrition,
      'pairingIds': instance.pairingIds,
    };

_$RecipeIngredientImpl _$$RecipeIngredientImplFromJson(
        Map<String, dynamic> json) =>
    _$RecipeIngredientImpl(
      name: json['name'] as String,
      amount: json['amount'] as String,
      note: json['note'] as String?,
    );

Map<String, dynamic> _$$RecipeIngredientImplToJson(
        _$RecipeIngredientImpl instance) =>
    <String, dynamic>{
      'name': instance.name,
      'amount': instance.amount,
      'note': instance.note,
    };

_$RecipeStepImpl _$$RecipeStepImplFromJson(Map<String, dynamic> json) =>
    _$RecipeStepImpl(
      index: (json['index'] as num).toInt(),
      description: json['description'] as String,
      imageUrl: json['imageUrl'] as String?,
      durationSeconds: (json['durationSeconds'] as num?)?.toInt(),
    );

Map<String, dynamic> _$$RecipeStepImplToJson(_$RecipeStepImpl instance) =>
    <String, dynamic>{
      'index': instance.index,
      'description': instance.description,
      'imageUrl': instance.imageUrl,
      'durationSeconds': instance.durationSeconds,
    };

_$RestaurantLinkImpl _$$RestaurantLinkImplFromJson(Map<String, dynamic> json) =>
    _$RestaurantLinkImpl(
      name: json['name'] as String,
      platform: json['platform'] as String,
      url: json['url'] as String,
      rating: (json['rating'] as num?)?.toDouble(),
      pricePerPerson: (json['pricePerPerson'] as num?)?.toDouble(),
    );

Map<String, dynamic> _$$RestaurantLinkImplToJson(
        _$RestaurantLinkImpl instance) =>
    <String, dynamic>{
      'name': instance.name,
      'platform': instance.platform,
      'url': instance.url,
      'rating': instance.rating,
      'pricePerPerson': instance.pricePerPerson,
    };

_$DeliveryLinkImpl _$$DeliveryLinkImplFromJson(Map<String, dynamic> json) =>
    _$DeliveryLinkImpl(
      storeName: json['storeName'] as String,
      platform: json['platform'] as String,
      url: json['url'] as String,
      deliveryTimeMinutes: (json['deliveryTimeMinutes'] as num?)?.toInt(),
    );

Map<String, dynamic> _$$DeliveryLinkImplToJson(_$DeliveryLinkImpl instance) =>
    <String, dynamic>{
      'storeName': instance.storeName,
      'platform': instance.platform,
      'url': instance.url,
      'deliveryTimeMinutes': instance.deliveryTimeMinutes,
    };

_$NutritionInfoImpl _$$NutritionInfoImplFromJson(Map<String, dynamic> json) =>
    _$NutritionInfoImpl(
      calories: (json['calories'] as num).toInt(),
      protein: (json['protein'] as num).toDouble(),
      fat: (json['fat'] as num).toDouble(),
      carbs: (json['carbs'] as num).toDouble(),
      analysis: json['analysis'] as String?,
    );

Map<String, dynamic> _$$NutritionInfoImplToJson(_$NutritionInfoImpl instance) =>
    <String, dynamic>{
      'calories': instance.calories,
      'protein': instance.protein,
      'fat': instance.fat,
      'carbs': instance.carbs,
      'analysis': instance.analysis,
    };
