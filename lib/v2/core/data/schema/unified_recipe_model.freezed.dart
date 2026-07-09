// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'unified_recipe_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

UnifiedRecipeModel _$UnifiedRecipeModelFromJson(Map<String, dynamic> json) {
  return _UnifiedRecipeModel.fromJson(json);
}

/// @nodoc
mixin _$UnifiedRecipeModel {
  String get id => throw _privateConstructorUsedError;
  String get name => throw _privateConstructorUsedError;
  String get description => throw _privateConstructorUsedError;
  List<String> get images => throw _privateConstructorUsedError;
  List<String> get tagIds =>
      throw _privateConstructorUsedError; // Home Cooking Details
  List<RecipeIngredient> get ingredients => throw _privateConstructorUsedError;
  List<RecipeIngredient> get seasonings => throw _privateConstructorUsedError;
  List<RecipeStep> get steps =>
      throw _privateConstructorUsedError; // External Links
  List<RestaurantLink> get restaurants => throw _privateConstructorUsedError;
  List<DeliveryLink> get deliveryOptions =>
      throw _privateConstructorUsedError; // AI Analysis
  NutritionInfo? get nutrition => throw _privateConstructorUsedError;
  List<String> get pairingIds => throw _privateConstructorUsedError;

  /// Serializes this UnifiedRecipeModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of UnifiedRecipeModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $UnifiedRecipeModelCopyWith<UnifiedRecipeModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UnifiedRecipeModelCopyWith<$Res> {
  factory $UnifiedRecipeModelCopyWith(
          UnifiedRecipeModel value, $Res Function(UnifiedRecipeModel) then) =
      _$UnifiedRecipeModelCopyWithImpl<$Res, UnifiedRecipeModel>;
  @useResult
  $Res call(
      {String id,
      String name,
      String description,
      List<String> images,
      List<String> tagIds,
      List<RecipeIngredient> ingredients,
      List<RecipeIngredient> seasonings,
      List<RecipeStep> steps,
      List<RestaurantLink> restaurants,
      List<DeliveryLink> deliveryOptions,
      NutritionInfo? nutrition,
      List<String> pairingIds});

  $NutritionInfoCopyWith<$Res>? get nutrition;
}

/// @nodoc
class _$UnifiedRecipeModelCopyWithImpl<$Res, $Val extends UnifiedRecipeModel>
    implements $UnifiedRecipeModelCopyWith<$Res> {
  _$UnifiedRecipeModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of UnifiedRecipeModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? description = null,
    Object? images = null,
    Object? tagIds = null,
    Object? ingredients = null,
    Object? seasonings = null,
    Object? steps = null,
    Object? restaurants = null,
    Object? deliveryOptions = null,
    Object? nutrition = freezed,
    Object? pairingIds = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      images: null == images
          ? _value.images
          : images // ignore: cast_nullable_to_non_nullable
              as List<String>,
      tagIds: null == tagIds
          ? _value.tagIds
          : tagIds // ignore: cast_nullable_to_non_nullable
              as List<String>,
      ingredients: null == ingredients
          ? _value.ingredients
          : ingredients // ignore: cast_nullable_to_non_nullable
              as List<RecipeIngredient>,
      seasonings: null == seasonings
          ? _value.seasonings
          : seasonings // ignore: cast_nullable_to_non_nullable
              as List<RecipeIngredient>,
      steps: null == steps
          ? _value.steps
          : steps // ignore: cast_nullable_to_non_nullable
              as List<RecipeStep>,
      restaurants: null == restaurants
          ? _value.restaurants
          : restaurants // ignore: cast_nullable_to_non_nullable
              as List<RestaurantLink>,
      deliveryOptions: null == deliveryOptions
          ? _value.deliveryOptions
          : deliveryOptions // ignore: cast_nullable_to_non_nullable
              as List<DeliveryLink>,
      nutrition: freezed == nutrition
          ? _value.nutrition
          : nutrition // ignore: cast_nullable_to_non_nullable
              as NutritionInfo?,
      pairingIds: null == pairingIds
          ? _value.pairingIds
          : pairingIds // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ) as $Val);
  }

  /// Create a copy of UnifiedRecipeModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $NutritionInfoCopyWith<$Res>? get nutrition {
    if (_value.nutrition == null) {
      return null;
    }

    return $NutritionInfoCopyWith<$Res>(_value.nutrition!, (value) {
      return _then(_value.copyWith(nutrition: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$UnifiedRecipeModelImplCopyWith<$Res>
    implements $UnifiedRecipeModelCopyWith<$Res> {
  factory _$$UnifiedRecipeModelImplCopyWith(_$UnifiedRecipeModelImpl value,
          $Res Function(_$UnifiedRecipeModelImpl) then) =
      __$$UnifiedRecipeModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String name,
      String description,
      List<String> images,
      List<String> tagIds,
      List<RecipeIngredient> ingredients,
      List<RecipeIngredient> seasonings,
      List<RecipeStep> steps,
      List<RestaurantLink> restaurants,
      List<DeliveryLink> deliveryOptions,
      NutritionInfo? nutrition,
      List<String> pairingIds});

  @override
  $NutritionInfoCopyWith<$Res>? get nutrition;
}

/// @nodoc
class __$$UnifiedRecipeModelImplCopyWithImpl<$Res>
    extends _$UnifiedRecipeModelCopyWithImpl<$Res, _$UnifiedRecipeModelImpl>
    implements _$$UnifiedRecipeModelImplCopyWith<$Res> {
  __$$UnifiedRecipeModelImplCopyWithImpl(_$UnifiedRecipeModelImpl _value,
      $Res Function(_$UnifiedRecipeModelImpl) _then)
      : super(_value, _then);

  /// Create a copy of UnifiedRecipeModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? name = null,
    Object? description = null,
    Object? images = null,
    Object? tagIds = null,
    Object? ingredients = null,
    Object? seasonings = null,
    Object? steps = null,
    Object? restaurants = null,
    Object? deliveryOptions = null,
    Object? nutrition = freezed,
    Object? pairingIds = null,
  }) {
    return _then(_$UnifiedRecipeModelImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      images: null == images
          ? _value._images
          : images // ignore: cast_nullable_to_non_nullable
              as List<String>,
      tagIds: null == tagIds
          ? _value._tagIds
          : tagIds // ignore: cast_nullable_to_non_nullable
              as List<String>,
      ingredients: null == ingredients
          ? _value._ingredients
          : ingredients // ignore: cast_nullable_to_non_nullable
              as List<RecipeIngredient>,
      seasonings: null == seasonings
          ? _value._seasonings
          : seasonings // ignore: cast_nullable_to_non_nullable
              as List<RecipeIngredient>,
      steps: null == steps
          ? _value._steps
          : steps // ignore: cast_nullable_to_non_nullable
              as List<RecipeStep>,
      restaurants: null == restaurants
          ? _value._restaurants
          : restaurants // ignore: cast_nullable_to_non_nullable
              as List<RestaurantLink>,
      deliveryOptions: null == deliveryOptions
          ? _value._deliveryOptions
          : deliveryOptions // ignore: cast_nullable_to_non_nullable
              as List<DeliveryLink>,
      nutrition: freezed == nutrition
          ? _value.nutrition
          : nutrition // ignore: cast_nullable_to_non_nullable
              as NutritionInfo?,
      pairingIds: null == pairingIds
          ? _value._pairingIds
          : pairingIds // ignore: cast_nullable_to_non_nullable
              as List<String>,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$UnifiedRecipeModelImpl implements _UnifiedRecipeModel {
  const _$UnifiedRecipeModelImpl(
      {required this.id,
      required this.name,
      required this.description,
      final List<String> images = const [],
      final List<String> tagIds = const [],
      final List<RecipeIngredient> ingredients = const [],
      final List<RecipeIngredient> seasonings = const [],
      final List<RecipeStep> steps = const [],
      final List<RestaurantLink> restaurants = const [],
      final List<DeliveryLink> deliveryOptions = const [],
      this.nutrition,
      final List<String> pairingIds = const []})
      : _images = images,
        _tagIds = tagIds,
        _ingredients = ingredients,
        _seasonings = seasonings,
        _steps = steps,
        _restaurants = restaurants,
        _deliveryOptions = deliveryOptions,
        _pairingIds = pairingIds;

  factory _$UnifiedRecipeModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$UnifiedRecipeModelImplFromJson(json);

  @override
  final String id;
  @override
  final String name;
  @override
  final String description;
  final List<String> _images;
  @override
  @JsonKey()
  List<String> get images {
    if (_images is EqualUnmodifiableListView) return _images;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_images);
  }

  final List<String> _tagIds;
  @override
  @JsonKey()
  List<String> get tagIds {
    if (_tagIds is EqualUnmodifiableListView) return _tagIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_tagIds);
  }

// Home Cooking Details
  final List<RecipeIngredient> _ingredients;
// Home Cooking Details
  @override
  @JsonKey()
  List<RecipeIngredient> get ingredients {
    if (_ingredients is EqualUnmodifiableListView) return _ingredients;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_ingredients);
  }

  final List<RecipeIngredient> _seasonings;
  @override
  @JsonKey()
  List<RecipeIngredient> get seasonings {
    if (_seasonings is EqualUnmodifiableListView) return _seasonings;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_seasonings);
  }

  final List<RecipeStep> _steps;
  @override
  @JsonKey()
  List<RecipeStep> get steps {
    if (_steps is EqualUnmodifiableListView) return _steps;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_steps);
  }

// External Links
  final List<RestaurantLink> _restaurants;
// External Links
  @override
  @JsonKey()
  List<RestaurantLink> get restaurants {
    if (_restaurants is EqualUnmodifiableListView) return _restaurants;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_restaurants);
  }

  final List<DeliveryLink> _deliveryOptions;
  @override
  @JsonKey()
  List<DeliveryLink> get deliveryOptions {
    if (_deliveryOptions is EqualUnmodifiableListView) return _deliveryOptions;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_deliveryOptions);
  }

// AI Analysis
  @override
  final NutritionInfo? nutrition;
  final List<String> _pairingIds;
  @override
  @JsonKey()
  List<String> get pairingIds {
    if (_pairingIds is EqualUnmodifiableListView) return _pairingIds;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_pairingIds);
  }

  @override
  String toString() {
    return 'UnifiedRecipeModel(id: $id, name: $name, description: $description, images: $images, tagIds: $tagIds, ingredients: $ingredients, seasonings: $seasonings, steps: $steps, restaurants: $restaurants, deliveryOptions: $deliveryOptions, nutrition: $nutrition, pairingIds: $pairingIds)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UnifiedRecipeModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.description, description) ||
                other.description == description) &&
            const DeepCollectionEquality().equals(other._images, _images) &&
            const DeepCollectionEquality().equals(other._tagIds, _tagIds) &&
            const DeepCollectionEquality()
                .equals(other._ingredients, _ingredients) &&
            const DeepCollectionEquality()
                .equals(other._seasonings, _seasonings) &&
            const DeepCollectionEquality().equals(other._steps, _steps) &&
            const DeepCollectionEquality()
                .equals(other._restaurants, _restaurants) &&
            const DeepCollectionEquality()
                .equals(other._deliveryOptions, _deliveryOptions) &&
            (identical(other.nutrition, nutrition) ||
                other.nutrition == nutrition) &&
            const DeepCollectionEquality()
                .equals(other._pairingIds, _pairingIds));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(
      runtimeType,
      id,
      name,
      description,
      const DeepCollectionEquality().hash(_images),
      const DeepCollectionEquality().hash(_tagIds),
      const DeepCollectionEquality().hash(_ingredients),
      const DeepCollectionEquality().hash(_seasonings),
      const DeepCollectionEquality().hash(_steps),
      const DeepCollectionEquality().hash(_restaurants),
      const DeepCollectionEquality().hash(_deliveryOptions),
      nutrition,
      const DeepCollectionEquality().hash(_pairingIds));

  /// Create a copy of UnifiedRecipeModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$UnifiedRecipeModelImplCopyWith<_$UnifiedRecipeModelImpl> get copyWith =>
      __$$UnifiedRecipeModelImplCopyWithImpl<_$UnifiedRecipeModelImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$UnifiedRecipeModelImplToJson(
      this,
    );
  }
}

abstract class _UnifiedRecipeModel implements UnifiedRecipeModel {
  const factory _UnifiedRecipeModel(
      {required final String id,
      required final String name,
      required final String description,
      final List<String> images,
      final List<String> tagIds,
      final List<RecipeIngredient> ingredients,
      final List<RecipeIngredient> seasonings,
      final List<RecipeStep> steps,
      final List<RestaurantLink> restaurants,
      final List<DeliveryLink> deliveryOptions,
      final NutritionInfo? nutrition,
      final List<String> pairingIds}) = _$UnifiedRecipeModelImpl;

  factory _UnifiedRecipeModel.fromJson(Map<String, dynamic> json) =
      _$UnifiedRecipeModelImpl.fromJson;

  @override
  String get id;
  @override
  String get name;
  @override
  String get description;
  @override
  List<String> get images;
  @override
  List<String> get tagIds; // Home Cooking Details
  @override
  List<RecipeIngredient> get ingredients;
  @override
  List<RecipeIngredient> get seasonings;
  @override
  List<RecipeStep> get steps; // External Links
  @override
  List<RestaurantLink> get restaurants;
  @override
  List<DeliveryLink> get deliveryOptions; // AI Analysis
  @override
  NutritionInfo? get nutrition;
  @override
  List<String> get pairingIds;

  /// Create a copy of UnifiedRecipeModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$UnifiedRecipeModelImplCopyWith<_$UnifiedRecipeModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

RecipeIngredient _$RecipeIngredientFromJson(Map<String, dynamic> json) {
  return _RecipeIngredient.fromJson(json);
}

/// @nodoc
mixin _$RecipeIngredient {
  String get name => throw _privateConstructorUsedError;
  String get amount => throw _privateConstructorUsedError;
  String? get note => throw _privateConstructorUsedError;

  /// Serializes this RecipeIngredient to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of RecipeIngredient
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $RecipeIngredientCopyWith<RecipeIngredient> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RecipeIngredientCopyWith<$Res> {
  factory $RecipeIngredientCopyWith(
          RecipeIngredient value, $Res Function(RecipeIngredient) then) =
      _$RecipeIngredientCopyWithImpl<$Res, RecipeIngredient>;
  @useResult
  $Res call({String name, String amount, String? note});
}

/// @nodoc
class _$RecipeIngredientCopyWithImpl<$Res, $Val extends RecipeIngredient>
    implements $RecipeIngredientCopyWith<$Res> {
  _$RecipeIngredientCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of RecipeIngredient
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? amount = null,
    Object? note = freezed,
  }) {
    return _then(_value.copyWith(
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      amount: null == amount
          ? _value.amount
          : amount // ignore: cast_nullable_to_non_nullable
              as String,
      note: freezed == note
          ? _value.note
          : note // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$RecipeIngredientImplCopyWith<$Res>
    implements $RecipeIngredientCopyWith<$Res> {
  factory _$$RecipeIngredientImplCopyWith(_$RecipeIngredientImpl value,
          $Res Function(_$RecipeIngredientImpl) then) =
      __$$RecipeIngredientImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String name, String amount, String? note});
}

/// @nodoc
class __$$RecipeIngredientImplCopyWithImpl<$Res>
    extends _$RecipeIngredientCopyWithImpl<$Res, _$RecipeIngredientImpl>
    implements _$$RecipeIngredientImplCopyWith<$Res> {
  __$$RecipeIngredientImplCopyWithImpl(_$RecipeIngredientImpl _value,
      $Res Function(_$RecipeIngredientImpl) _then)
      : super(_value, _then);

  /// Create a copy of RecipeIngredient
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? amount = null,
    Object? note = freezed,
  }) {
    return _then(_$RecipeIngredientImpl(
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      amount: null == amount
          ? _value.amount
          : amount // ignore: cast_nullable_to_non_nullable
              as String,
      note: freezed == note
          ? _value.note
          : note // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$RecipeIngredientImpl implements _RecipeIngredient {
  const _$RecipeIngredientImpl(
      {required this.name, required this.amount, this.note});

  factory _$RecipeIngredientImpl.fromJson(Map<String, dynamic> json) =>
      _$$RecipeIngredientImplFromJson(json);

  @override
  final String name;
  @override
  final String amount;
  @override
  final String? note;

  @override
  String toString() {
    return 'RecipeIngredient(name: $name, amount: $amount, note: $note)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RecipeIngredientImpl &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.amount, amount) || other.amount == amount) &&
            (identical(other.note, note) || other.note == note));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, name, amount, note);

  /// Create a copy of RecipeIngredient
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$RecipeIngredientImplCopyWith<_$RecipeIngredientImpl> get copyWith =>
      __$$RecipeIngredientImplCopyWithImpl<_$RecipeIngredientImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$RecipeIngredientImplToJson(
      this,
    );
  }
}

abstract class _RecipeIngredient implements RecipeIngredient {
  const factory _RecipeIngredient(
      {required final String name,
      required final String amount,
      final String? note}) = _$RecipeIngredientImpl;

  factory _RecipeIngredient.fromJson(Map<String, dynamic> json) =
      _$RecipeIngredientImpl.fromJson;

  @override
  String get name;
  @override
  String get amount;
  @override
  String? get note;

  /// Create a copy of RecipeIngredient
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$RecipeIngredientImplCopyWith<_$RecipeIngredientImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

RecipeStep _$RecipeStepFromJson(Map<String, dynamic> json) {
  return _RecipeStep.fromJson(json);
}

/// @nodoc
mixin _$RecipeStep {
  int get index => throw _privateConstructorUsedError;
  String get description => throw _privateConstructorUsedError;
  String? get imageUrl => throw _privateConstructorUsedError;
  int? get durationSeconds => throw _privateConstructorUsedError;

  /// Serializes this RecipeStep to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of RecipeStep
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $RecipeStepCopyWith<RecipeStep> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RecipeStepCopyWith<$Res> {
  factory $RecipeStepCopyWith(
          RecipeStep value, $Res Function(RecipeStep) then) =
      _$RecipeStepCopyWithImpl<$Res, RecipeStep>;
  @useResult
  $Res call(
      {int index, String description, String? imageUrl, int? durationSeconds});
}

/// @nodoc
class _$RecipeStepCopyWithImpl<$Res, $Val extends RecipeStep>
    implements $RecipeStepCopyWith<$Res> {
  _$RecipeStepCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of RecipeStep
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? index = null,
    Object? description = null,
    Object? imageUrl = freezed,
    Object? durationSeconds = freezed,
  }) {
    return _then(_value.copyWith(
      index: null == index
          ? _value.index
          : index // ignore: cast_nullable_to_non_nullable
              as int,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      imageUrl: freezed == imageUrl
          ? _value.imageUrl
          : imageUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      durationSeconds: freezed == durationSeconds
          ? _value.durationSeconds
          : durationSeconds // ignore: cast_nullable_to_non_nullable
              as int?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$RecipeStepImplCopyWith<$Res>
    implements $RecipeStepCopyWith<$Res> {
  factory _$$RecipeStepImplCopyWith(
          _$RecipeStepImpl value, $Res Function(_$RecipeStepImpl) then) =
      __$$RecipeStepImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int index, String description, String? imageUrl, int? durationSeconds});
}

/// @nodoc
class __$$RecipeStepImplCopyWithImpl<$Res>
    extends _$RecipeStepCopyWithImpl<$Res, _$RecipeStepImpl>
    implements _$$RecipeStepImplCopyWith<$Res> {
  __$$RecipeStepImplCopyWithImpl(
      _$RecipeStepImpl _value, $Res Function(_$RecipeStepImpl) _then)
      : super(_value, _then);

  /// Create a copy of RecipeStep
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? index = null,
    Object? description = null,
    Object? imageUrl = freezed,
    Object? durationSeconds = freezed,
  }) {
    return _then(_$RecipeStepImpl(
      index: null == index
          ? _value.index
          : index // ignore: cast_nullable_to_non_nullable
              as int,
      description: null == description
          ? _value.description
          : description // ignore: cast_nullable_to_non_nullable
              as String,
      imageUrl: freezed == imageUrl
          ? _value.imageUrl
          : imageUrl // ignore: cast_nullable_to_non_nullable
              as String?,
      durationSeconds: freezed == durationSeconds
          ? _value.durationSeconds
          : durationSeconds // ignore: cast_nullable_to_non_nullable
              as int?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$RecipeStepImpl implements _RecipeStep {
  const _$RecipeStepImpl(
      {required this.index,
      required this.description,
      this.imageUrl,
      this.durationSeconds});

  factory _$RecipeStepImpl.fromJson(Map<String, dynamic> json) =>
      _$$RecipeStepImplFromJson(json);

  @override
  final int index;
  @override
  final String description;
  @override
  final String? imageUrl;
  @override
  final int? durationSeconds;

  @override
  String toString() {
    return 'RecipeStep(index: $index, description: $description, imageUrl: $imageUrl, durationSeconds: $durationSeconds)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RecipeStepImpl &&
            (identical(other.index, index) || other.index == index) &&
            (identical(other.description, description) ||
                other.description == description) &&
            (identical(other.imageUrl, imageUrl) ||
                other.imageUrl == imageUrl) &&
            (identical(other.durationSeconds, durationSeconds) ||
                other.durationSeconds == durationSeconds));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, index, description, imageUrl, durationSeconds);

  /// Create a copy of RecipeStep
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$RecipeStepImplCopyWith<_$RecipeStepImpl> get copyWith =>
      __$$RecipeStepImplCopyWithImpl<_$RecipeStepImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$RecipeStepImplToJson(
      this,
    );
  }
}

abstract class _RecipeStep implements RecipeStep {
  const factory _RecipeStep(
      {required final int index,
      required final String description,
      final String? imageUrl,
      final int? durationSeconds}) = _$RecipeStepImpl;

  factory _RecipeStep.fromJson(Map<String, dynamic> json) =
      _$RecipeStepImpl.fromJson;

  @override
  int get index;
  @override
  String get description;
  @override
  String? get imageUrl;
  @override
  int? get durationSeconds;

  /// Create a copy of RecipeStep
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$RecipeStepImplCopyWith<_$RecipeStepImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

RestaurantLink _$RestaurantLinkFromJson(Map<String, dynamic> json) {
  return _RestaurantLink.fromJson(json);
}

/// @nodoc
mixin _$RestaurantLink {
  String get name => throw _privateConstructorUsedError;
  String get platform =>
      throw _privateConstructorUsedError; // dianping, meituan
  String get url => throw _privateConstructorUsedError;
  double? get rating => throw _privateConstructorUsedError;
  double? get pricePerPerson => throw _privateConstructorUsedError;

  /// Serializes this RestaurantLink to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of RestaurantLink
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $RestaurantLinkCopyWith<RestaurantLink> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $RestaurantLinkCopyWith<$Res> {
  factory $RestaurantLinkCopyWith(
          RestaurantLink value, $Res Function(RestaurantLink) then) =
      _$RestaurantLinkCopyWithImpl<$Res, RestaurantLink>;
  @useResult
  $Res call(
      {String name,
      String platform,
      String url,
      double? rating,
      double? pricePerPerson});
}

/// @nodoc
class _$RestaurantLinkCopyWithImpl<$Res, $Val extends RestaurantLink>
    implements $RestaurantLinkCopyWith<$Res> {
  _$RestaurantLinkCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of RestaurantLink
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? platform = null,
    Object? url = null,
    Object? rating = freezed,
    Object? pricePerPerson = freezed,
  }) {
    return _then(_value.copyWith(
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      platform: null == platform
          ? _value.platform
          : platform // ignore: cast_nullable_to_non_nullable
              as String,
      url: null == url
          ? _value.url
          : url // ignore: cast_nullable_to_non_nullable
              as String,
      rating: freezed == rating
          ? _value.rating
          : rating // ignore: cast_nullable_to_non_nullable
              as double?,
      pricePerPerson: freezed == pricePerPerson
          ? _value.pricePerPerson
          : pricePerPerson // ignore: cast_nullable_to_non_nullable
              as double?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$RestaurantLinkImplCopyWith<$Res>
    implements $RestaurantLinkCopyWith<$Res> {
  factory _$$RestaurantLinkImplCopyWith(_$RestaurantLinkImpl value,
          $Res Function(_$RestaurantLinkImpl) then) =
      __$$RestaurantLinkImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String name,
      String platform,
      String url,
      double? rating,
      double? pricePerPerson});
}

/// @nodoc
class __$$RestaurantLinkImplCopyWithImpl<$Res>
    extends _$RestaurantLinkCopyWithImpl<$Res, _$RestaurantLinkImpl>
    implements _$$RestaurantLinkImplCopyWith<$Res> {
  __$$RestaurantLinkImplCopyWithImpl(
      _$RestaurantLinkImpl _value, $Res Function(_$RestaurantLinkImpl) _then)
      : super(_value, _then);

  /// Create a copy of RestaurantLink
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? name = null,
    Object? platform = null,
    Object? url = null,
    Object? rating = freezed,
    Object? pricePerPerson = freezed,
  }) {
    return _then(_$RestaurantLinkImpl(
      name: null == name
          ? _value.name
          : name // ignore: cast_nullable_to_non_nullable
              as String,
      platform: null == platform
          ? _value.platform
          : platform // ignore: cast_nullable_to_non_nullable
              as String,
      url: null == url
          ? _value.url
          : url // ignore: cast_nullable_to_non_nullable
              as String,
      rating: freezed == rating
          ? _value.rating
          : rating // ignore: cast_nullable_to_non_nullable
              as double?,
      pricePerPerson: freezed == pricePerPerson
          ? _value.pricePerPerson
          : pricePerPerson // ignore: cast_nullable_to_non_nullable
              as double?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$RestaurantLinkImpl implements _RestaurantLink {
  const _$RestaurantLinkImpl(
      {required this.name,
      required this.platform,
      required this.url,
      this.rating,
      this.pricePerPerson});

  factory _$RestaurantLinkImpl.fromJson(Map<String, dynamic> json) =>
      _$$RestaurantLinkImplFromJson(json);

  @override
  final String name;
  @override
  final String platform;
// dianping, meituan
  @override
  final String url;
  @override
  final double? rating;
  @override
  final double? pricePerPerson;

  @override
  String toString() {
    return 'RestaurantLink(name: $name, platform: $platform, url: $url, rating: $rating, pricePerPerson: $pricePerPerson)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$RestaurantLinkImpl &&
            (identical(other.name, name) || other.name == name) &&
            (identical(other.platform, platform) ||
                other.platform == platform) &&
            (identical(other.url, url) || other.url == url) &&
            (identical(other.rating, rating) || other.rating == rating) &&
            (identical(other.pricePerPerson, pricePerPerson) ||
                other.pricePerPerson == pricePerPerson));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, name, platform, url, rating, pricePerPerson);

  /// Create a copy of RestaurantLink
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$RestaurantLinkImplCopyWith<_$RestaurantLinkImpl> get copyWith =>
      __$$RestaurantLinkImplCopyWithImpl<_$RestaurantLinkImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$RestaurantLinkImplToJson(
      this,
    );
  }
}

abstract class _RestaurantLink implements RestaurantLink {
  const factory _RestaurantLink(
      {required final String name,
      required final String platform,
      required final String url,
      final double? rating,
      final double? pricePerPerson}) = _$RestaurantLinkImpl;

  factory _RestaurantLink.fromJson(Map<String, dynamic> json) =
      _$RestaurantLinkImpl.fromJson;

  @override
  String get name;
  @override
  String get platform; // dianping, meituan
  @override
  String get url;
  @override
  double? get rating;
  @override
  double? get pricePerPerson;

  /// Create a copy of RestaurantLink
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$RestaurantLinkImplCopyWith<_$RestaurantLinkImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

DeliveryLink _$DeliveryLinkFromJson(Map<String, dynamic> json) {
  return _DeliveryLink.fromJson(json);
}

/// @nodoc
mixin _$DeliveryLink {
  String get storeName => throw _privateConstructorUsedError;
  String get platform => throw _privateConstructorUsedError; // meituan, eleme
  String get url => throw _privateConstructorUsedError;
  int? get deliveryTimeMinutes => throw _privateConstructorUsedError;

  /// Serializes this DeliveryLink to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of DeliveryLink
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $DeliveryLinkCopyWith<DeliveryLink> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $DeliveryLinkCopyWith<$Res> {
  factory $DeliveryLinkCopyWith(
          DeliveryLink value, $Res Function(DeliveryLink) then) =
      _$DeliveryLinkCopyWithImpl<$Res, DeliveryLink>;
  @useResult
  $Res call(
      {String storeName,
      String platform,
      String url,
      int? deliveryTimeMinutes});
}

/// @nodoc
class _$DeliveryLinkCopyWithImpl<$Res, $Val extends DeliveryLink>
    implements $DeliveryLinkCopyWith<$Res> {
  _$DeliveryLinkCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of DeliveryLink
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? storeName = null,
    Object? platform = null,
    Object? url = null,
    Object? deliveryTimeMinutes = freezed,
  }) {
    return _then(_value.copyWith(
      storeName: null == storeName
          ? _value.storeName
          : storeName // ignore: cast_nullable_to_non_nullable
              as String,
      platform: null == platform
          ? _value.platform
          : platform // ignore: cast_nullable_to_non_nullable
              as String,
      url: null == url
          ? _value.url
          : url // ignore: cast_nullable_to_non_nullable
              as String,
      deliveryTimeMinutes: freezed == deliveryTimeMinutes
          ? _value.deliveryTimeMinutes
          : deliveryTimeMinutes // ignore: cast_nullable_to_non_nullable
              as int?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$DeliveryLinkImplCopyWith<$Res>
    implements $DeliveryLinkCopyWith<$Res> {
  factory _$$DeliveryLinkImplCopyWith(
          _$DeliveryLinkImpl value, $Res Function(_$DeliveryLinkImpl) then) =
      __$$DeliveryLinkImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String storeName,
      String platform,
      String url,
      int? deliveryTimeMinutes});
}

/// @nodoc
class __$$DeliveryLinkImplCopyWithImpl<$Res>
    extends _$DeliveryLinkCopyWithImpl<$Res, _$DeliveryLinkImpl>
    implements _$$DeliveryLinkImplCopyWith<$Res> {
  __$$DeliveryLinkImplCopyWithImpl(
      _$DeliveryLinkImpl _value, $Res Function(_$DeliveryLinkImpl) _then)
      : super(_value, _then);

  /// Create a copy of DeliveryLink
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? storeName = null,
    Object? platform = null,
    Object? url = null,
    Object? deliveryTimeMinutes = freezed,
  }) {
    return _then(_$DeliveryLinkImpl(
      storeName: null == storeName
          ? _value.storeName
          : storeName // ignore: cast_nullable_to_non_nullable
              as String,
      platform: null == platform
          ? _value.platform
          : platform // ignore: cast_nullable_to_non_nullable
              as String,
      url: null == url
          ? _value.url
          : url // ignore: cast_nullable_to_non_nullable
              as String,
      deliveryTimeMinutes: freezed == deliveryTimeMinutes
          ? _value.deliveryTimeMinutes
          : deliveryTimeMinutes // ignore: cast_nullable_to_non_nullable
              as int?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$DeliveryLinkImpl implements _DeliveryLink {
  const _$DeliveryLinkImpl(
      {required this.storeName,
      required this.platform,
      required this.url,
      this.deliveryTimeMinutes});

  factory _$DeliveryLinkImpl.fromJson(Map<String, dynamic> json) =>
      _$$DeliveryLinkImplFromJson(json);

  @override
  final String storeName;
  @override
  final String platform;
// meituan, eleme
  @override
  final String url;
  @override
  final int? deliveryTimeMinutes;

  @override
  String toString() {
    return 'DeliveryLink(storeName: $storeName, platform: $platform, url: $url, deliveryTimeMinutes: $deliveryTimeMinutes)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$DeliveryLinkImpl &&
            (identical(other.storeName, storeName) ||
                other.storeName == storeName) &&
            (identical(other.platform, platform) ||
                other.platform == platform) &&
            (identical(other.url, url) || other.url == url) &&
            (identical(other.deliveryTimeMinutes, deliveryTimeMinutes) ||
                other.deliveryTimeMinutes == deliveryTimeMinutes));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, storeName, platform, url, deliveryTimeMinutes);

  /// Create a copy of DeliveryLink
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$DeliveryLinkImplCopyWith<_$DeliveryLinkImpl> get copyWith =>
      __$$DeliveryLinkImplCopyWithImpl<_$DeliveryLinkImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$DeliveryLinkImplToJson(
      this,
    );
  }
}

abstract class _DeliveryLink implements DeliveryLink {
  const factory _DeliveryLink(
      {required final String storeName,
      required final String platform,
      required final String url,
      final int? deliveryTimeMinutes}) = _$DeliveryLinkImpl;

  factory _DeliveryLink.fromJson(Map<String, dynamic> json) =
      _$DeliveryLinkImpl.fromJson;

  @override
  String get storeName;
  @override
  String get platform; // meituan, eleme
  @override
  String get url;
  @override
  int? get deliveryTimeMinutes;

  /// Create a copy of DeliveryLink
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$DeliveryLinkImplCopyWith<_$DeliveryLinkImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

NutritionInfo _$NutritionInfoFromJson(Map<String, dynamic> json) {
  return _NutritionInfo.fromJson(json);
}

/// @nodoc
mixin _$NutritionInfo {
  int get calories => throw _privateConstructorUsedError;
  double get protein => throw _privateConstructorUsedError;
  double get fat => throw _privateConstructorUsedError;
  double get carbs => throw _privateConstructorUsedError;
  String? get analysis => throw _privateConstructorUsedError;

  /// Serializes this NutritionInfo to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of NutritionInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $NutritionInfoCopyWith<NutritionInfo> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $NutritionInfoCopyWith<$Res> {
  factory $NutritionInfoCopyWith(
          NutritionInfo value, $Res Function(NutritionInfo) then) =
      _$NutritionInfoCopyWithImpl<$Res, NutritionInfo>;
  @useResult
  $Res call(
      {int calories,
      double protein,
      double fat,
      double carbs,
      String? analysis});
}

/// @nodoc
class _$NutritionInfoCopyWithImpl<$Res, $Val extends NutritionInfo>
    implements $NutritionInfoCopyWith<$Res> {
  _$NutritionInfoCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of NutritionInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? calories = null,
    Object? protein = null,
    Object? fat = null,
    Object? carbs = null,
    Object? analysis = freezed,
  }) {
    return _then(_value.copyWith(
      calories: null == calories
          ? _value.calories
          : calories // ignore: cast_nullable_to_non_nullable
              as int,
      protein: null == protein
          ? _value.protein
          : protein // ignore: cast_nullable_to_non_nullable
              as double,
      fat: null == fat
          ? _value.fat
          : fat // ignore: cast_nullable_to_non_nullable
              as double,
      carbs: null == carbs
          ? _value.carbs
          : carbs // ignore: cast_nullable_to_non_nullable
              as double,
      analysis: freezed == analysis
          ? _value.analysis
          : analysis // ignore: cast_nullable_to_non_nullable
              as String?,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$NutritionInfoImplCopyWith<$Res>
    implements $NutritionInfoCopyWith<$Res> {
  factory _$$NutritionInfoImplCopyWith(
          _$NutritionInfoImpl value, $Res Function(_$NutritionInfoImpl) then) =
      __$$NutritionInfoImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {int calories,
      double protein,
      double fat,
      double carbs,
      String? analysis});
}

/// @nodoc
class __$$NutritionInfoImplCopyWithImpl<$Res>
    extends _$NutritionInfoCopyWithImpl<$Res, _$NutritionInfoImpl>
    implements _$$NutritionInfoImplCopyWith<$Res> {
  __$$NutritionInfoImplCopyWithImpl(
      _$NutritionInfoImpl _value, $Res Function(_$NutritionInfoImpl) _then)
      : super(_value, _then);

  /// Create a copy of NutritionInfo
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? calories = null,
    Object? protein = null,
    Object? fat = null,
    Object? carbs = null,
    Object? analysis = freezed,
  }) {
    return _then(_$NutritionInfoImpl(
      calories: null == calories
          ? _value.calories
          : calories // ignore: cast_nullable_to_non_nullable
              as int,
      protein: null == protein
          ? _value.protein
          : protein // ignore: cast_nullable_to_non_nullable
              as double,
      fat: null == fat
          ? _value.fat
          : fat // ignore: cast_nullable_to_non_nullable
              as double,
      carbs: null == carbs
          ? _value.carbs
          : carbs // ignore: cast_nullable_to_non_nullable
              as double,
      analysis: freezed == analysis
          ? _value.analysis
          : analysis // ignore: cast_nullable_to_non_nullable
              as String?,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$NutritionInfoImpl implements _NutritionInfo {
  const _$NutritionInfoImpl(
      {required this.calories,
      required this.protein,
      required this.fat,
      required this.carbs,
      this.analysis});

  factory _$NutritionInfoImpl.fromJson(Map<String, dynamic> json) =>
      _$$NutritionInfoImplFromJson(json);

  @override
  final int calories;
  @override
  final double protein;
  @override
  final double fat;
  @override
  final double carbs;
  @override
  final String? analysis;

  @override
  String toString() {
    return 'NutritionInfo(calories: $calories, protein: $protein, fat: $fat, carbs: $carbs, analysis: $analysis)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$NutritionInfoImpl &&
            (identical(other.calories, calories) ||
                other.calories == calories) &&
            (identical(other.protein, protein) || other.protein == protein) &&
            (identical(other.fat, fat) || other.fat == fat) &&
            (identical(other.carbs, carbs) || other.carbs == carbs) &&
            (identical(other.analysis, analysis) ||
                other.analysis == analysis));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, calories, protein, fat, carbs, analysis);

  /// Create a copy of NutritionInfo
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$NutritionInfoImplCopyWith<_$NutritionInfoImpl> get copyWith =>
      __$$NutritionInfoImplCopyWithImpl<_$NutritionInfoImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$NutritionInfoImplToJson(
      this,
    );
  }
}

abstract class _NutritionInfo implements NutritionInfo {
  const factory _NutritionInfo(
      {required final int calories,
      required final double protein,
      required final double fat,
      required final double carbs,
      final String? analysis}) = _$NutritionInfoImpl;

  factory _NutritionInfo.fromJson(Map<String, dynamic> json) =
      _$NutritionInfoImpl.fromJson;

  @override
  int get calories;
  @override
  double get protein;
  @override
  double get fat;
  @override
  double get carbs;
  @override
  String? get analysis;

  /// Create a copy of NutritionInfo
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$NutritionInfoImplCopyWith<_$NutritionInfoImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
