// coverage:ignore-file
// GENERATED CODE - DO NOT MODIFY BY HAND
// ignore_for_file: type=lint
// ignore_for_file: unused_element, deprecated_member_use, deprecated_member_use_from_same_package, use_function_type_syntax_for_parameters, unnecessary_const, avoid_init_to_null, invalid_override_different_default_values_named, prefer_expression_function_bodies, annotate_overrides, invalid_annotation_target, unnecessary_question_mark

part of 'unified_tag_model.dart';

// **************************************************************************
// FreezedGenerator
// **************************************************************************

T _$identity<T>(T value) => value;

final _privateConstructorUsedError = UnsupportedError(
    'It seems like you constructed your class using `MyClass._()`. This constructor is only meant to be used by freezed and you are not supposed to need it nor use it.\nPlease check the documentation here for more information: https://github.com/rrousselGit/freezed#adding-getters-and-methods-to-our-models');

UnifiedTagModel _$UnifiedTagModelFromJson(Map<String, dynamic> json) {
  return _UnifiedTagModel.fromJson(json);
}

/// @nodoc
mixin _$UnifiedTagModel {
  String get id => throw _privateConstructorUsedError;
  String get label => throw _privateConstructorUsedError;
  String get category =>
      throw _privateConstructorUsedError; // flavor, ingredient, cuisine, scene, nutrition, meta
  String get iconAsset => throw _privateConstructorUsedError;
  VisualConfig get visual => throw _privateConstructorUsedError;
  double get weight => throw _privateConstructorUsedError;

  /// Serializes this UnifiedTagModel to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of UnifiedTagModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $UnifiedTagModelCopyWith<UnifiedTagModel> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $UnifiedTagModelCopyWith<$Res> {
  factory $UnifiedTagModelCopyWith(
          UnifiedTagModel value, $Res Function(UnifiedTagModel) then) =
      _$UnifiedTagModelCopyWithImpl<$Res, UnifiedTagModel>;
  @useResult
  $Res call(
      {String id,
      String label,
      String category,
      String iconAsset,
      VisualConfig visual,
      double weight});

  $VisualConfigCopyWith<$Res> get visual;
}

/// @nodoc
class _$UnifiedTagModelCopyWithImpl<$Res, $Val extends UnifiedTagModel>
    implements $UnifiedTagModelCopyWith<$Res> {
  _$UnifiedTagModelCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of UnifiedTagModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? label = null,
    Object? category = null,
    Object? iconAsset = null,
    Object? visual = null,
    Object? weight = null,
  }) {
    return _then(_value.copyWith(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      label: null == label
          ? _value.label
          : label // ignore: cast_nullable_to_non_nullable
              as String,
      category: null == category
          ? _value.category
          : category // ignore: cast_nullable_to_non_nullable
              as String,
      iconAsset: null == iconAsset
          ? _value.iconAsset
          : iconAsset // ignore: cast_nullable_to_non_nullable
              as String,
      visual: null == visual
          ? _value.visual
          : visual // ignore: cast_nullable_to_non_nullable
              as VisualConfig,
      weight: null == weight
          ? _value.weight
          : weight // ignore: cast_nullable_to_non_nullable
              as double,
    ) as $Val);
  }

  /// Create a copy of UnifiedTagModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @pragma('vm:prefer-inline')
  $VisualConfigCopyWith<$Res> get visual {
    return $VisualConfigCopyWith<$Res>(_value.visual, (value) {
      return _then(_value.copyWith(visual: value) as $Val);
    });
  }
}

/// @nodoc
abstract class _$$UnifiedTagModelImplCopyWith<$Res>
    implements $UnifiedTagModelCopyWith<$Res> {
  factory _$$UnifiedTagModelImplCopyWith(_$UnifiedTagModelImpl value,
          $Res Function(_$UnifiedTagModelImpl) then) =
      __$$UnifiedTagModelImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call(
      {String id,
      String label,
      String category,
      String iconAsset,
      VisualConfig visual,
      double weight});

  @override
  $VisualConfigCopyWith<$Res> get visual;
}

/// @nodoc
class __$$UnifiedTagModelImplCopyWithImpl<$Res>
    extends _$UnifiedTagModelCopyWithImpl<$Res, _$UnifiedTagModelImpl>
    implements _$$UnifiedTagModelImplCopyWith<$Res> {
  __$$UnifiedTagModelImplCopyWithImpl(
      _$UnifiedTagModelImpl _value, $Res Function(_$UnifiedTagModelImpl) _then)
      : super(_value, _then);

  /// Create a copy of UnifiedTagModel
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? id = null,
    Object? label = null,
    Object? category = null,
    Object? iconAsset = null,
    Object? visual = null,
    Object? weight = null,
  }) {
    return _then(_$UnifiedTagModelImpl(
      id: null == id
          ? _value.id
          : id // ignore: cast_nullable_to_non_nullable
              as String,
      label: null == label
          ? _value.label
          : label // ignore: cast_nullable_to_non_nullable
              as String,
      category: null == category
          ? _value.category
          : category // ignore: cast_nullable_to_non_nullable
              as String,
      iconAsset: null == iconAsset
          ? _value.iconAsset
          : iconAsset // ignore: cast_nullable_to_non_nullable
              as String,
      visual: null == visual
          ? _value.visual
          : visual // ignore: cast_nullable_to_non_nullable
              as VisualConfig,
      weight: null == weight
          ? _value.weight
          : weight // ignore: cast_nullable_to_non_nullable
              as double,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$UnifiedTagModelImpl implements _UnifiedTagModel {
  const _$UnifiedTagModelImpl(
      {required this.id,
      required this.label,
      required this.category,
      required this.iconAsset,
      required this.visual,
      this.weight = 0.5});

  factory _$UnifiedTagModelImpl.fromJson(Map<String, dynamic> json) =>
      _$$UnifiedTagModelImplFromJson(json);

  @override
  final String id;
  @override
  final String label;
  @override
  final String category;
// flavor, ingredient, cuisine, scene, nutrition, meta
  @override
  final String iconAsset;
  @override
  final VisualConfig visual;
  @override
  @JsonKey()
  final double weight;

  @override
  String toString() {
    return 'UnifiedTagModel(id: $id, label: $label, category: $category, iconAsset: $iconAsset, visual: $visual, weight: $weight)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$UnifiedTagModelImpl &&
            (identical(other.id, id) || other.id == id) &&
            (identical(other.label, label) || other.label == label) &&
            (identical(other.category, category) ||
                other.category == category) &&
            (identical(other.iconAsset, iconAsset) ||
                other.iconAsset == iconAsset) &&
            (identical(other.visual, visual) || other.visual == visual) &&
            (identical(other.weight, weight) || other.weight == weight));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode =>
      Object.hash(runtimeType, id, label, category, iconAsset, visual, weight);

  /// Create a copy of UnifiedTagModel
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$UnifiedTagModelImplCopyWith<_$UnifiedTagModelImpl> get copyWith =>
      __$$UnifiedTagModelImplCopyWithImpl<_$UnifiedTagModelImpl>(
          this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$UnifiedTagModelImplToJson(
      this,
    );
  }
}

abstract class _UnifiedTagModel implements UnifiedTagModel {
  const factory _UnifiedTagModel(
      {required final String id,
      required final String label,
      required final String category,
      required final String iconAsset,
      required final VisualConfig visual,
      final double weight}) = _$UnifiedTagModelImpl;

  factory _UnifiedTagModel.fromJson(Map<String, dynamic> json) =
      _$UnifiedTagModelImpl.fromJson;

  @override
  String get id;
  @override
  String get label;
  @override
  String get category; // flavor, ingredient, cuisine, scene, nutrition, meta
  @override
  String get iconAsset;
  @override
  VisualConfig get visual;
  @override
  double get weight;

  /// Create a copy of UnifiedTagModel
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$UnifiedTagModelImplCopyWith<_$UnifiedTagModelImpl> get copyWith =>
      throw _privateConstructorUsedError;
}

VisualConfig _$VisualConfigFromJson(Map<String, dynamic> json) {
  return _VisualConfig.fromJson(json);
}

/// @nodoc
mixin _$VisualConfig {
  String get shapeType =>
      throw _privateConstructorUsedError; // circle, chili, leaf, fire, drop, star, hexagon, squircle
  List<String> get colors => throw _privateConstructorUsedError; // Hex strings
  String get particleEffect => throw _privateConstructorUsedError;

  /// Serializes this VisualConfig to a JSON map.
  Map<String, dynamic> toJson() => throw _privateConstructorUsedError;

  /// Create a copy of VisualConfig
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  $VisualConfigCopyWith<VisualConfig> get copyWith =>
      throw _privateConstructorUsedError;
}

/// @nodoc
abstract class $VisualConfigCopyWith<$Res> {
  factory $VisualConfigCopyWith(
          VisualConfig value, $Res Function(VisualConfig) then) =
      _$VisualConfigCopyWithImpl<$Res, VisualConfig>;
  @useResult
  $Res call({String shapeType, List<String> colors, String particleEffect});
}

/// @nodoc
class _$VisualConfigCopyWithImpl<$Res, $Val extends VisualConfig>
    implements $VisualConfigCopyWith<$Res> {
  _$VisualConfigCopyWithImpl(this._value, this._then);

  // ignore: unused_field
  final $Val _value;
  // ignore: unused_field
  final $Res Function($Val) _then;

  /// Create a copy of VisualConfig
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? shapeType = null,
    Object? colors = null,
    Object? particleEffect = null,
  }) {
    return _then(_value.copyWith(
      shapeType: null == shapeType
          ? _value.shapeType
          : shapeType // ignore: cast_nullable_to_non_nullable
              as String,
      colors: null == colors
          ? _value.colors
          : colors // ignore: cast_nullable_to_non_nullable
              as List<String>,
      particleEffect: null == particleEffect
          ? _value.particleEffect
          : particleEffect // ignore: cast_nullable_to_non_nullable
              as String,
    ) as $Val);
  }
}

/// @nodoc
abstract class _$$VisualConfigImplCopyWith<$Res>
    implements $VisualConfigCopyWith<$Res> {
  factory _$$VisualConfigImplCopyWith(
          _$VisualConfigImpl value, $Res Function(_$VisualConfigImpl) then) =
      __$$VisualConfigImplCopyWithImpl<$Res>;
  @override
  @useResult
  $Res call({String shapeType, List<String> colors, String particleEffect});
}

/// @nodoc
class __$$VisualConfigImplCopyWithImpl<$Res>
    extends _$VisualConfigCopyWithImpl<$Res, _$VisualConfigImpl>
    implements _$$VisualConfigImplCopyWith<$Res> {
  __$$VisualConfigImplCopyWithImpl(
      _$VisualConfigImpl _value, $Res Function(_$VisualConfigImpl) _then)
      : super(_value, _then);

  /// Create a copy of VisualConfig
  /// with the given fields replaced by the non-null parameter values.
  @pragma('vm:prefer-inline')
  @override
  $Res call({
    Object? shapeType = null,
    Object? colors = null,
    Object? particleEffect = null,
  }) {
    return _then(_$VisualConfigImpl(
      shapeType: null == shapeType
          ? _value.shapeType
          : shapeType // ignore: cast_nullable_to_non_nullable
              as String,
      colors: null == colors
          ? _value._colors
          : colors // ignore: cast_nullable_to_non_nullable
              as List<String>,
      particleEffect: null == particleEffect
          ? _value.particleEffect
          : particleEffect // ignore: cast_nullable_to_non_nullable
              as String,
    ));
  }
}

/// @nodoc
@JsonSerializable()
class _$VisualConfigImpl implements _VisualConfig {
  const _$VisualConfigImpl(
      {required this.shapeType,
      required final List<String> colors,
      this.particleEffect = 'none'})
      : _colors = colors;

  factory _$VisualConfigImpl.fromJson(Map<String, dynamic> json) =>
      _$$VisualConfigImplFromJson(json);

  @override
  final String shapeType;
// circle, chili, leaf, fire, drop, star, hexagon, squircle
  final List<String> _colors;
// circle, chili, leaf, fire, drop, star, hexagon, squircle
  @override
  List<String> get colors {
    if (_colors is EqualUnmodifiableListView) return _colors;
    // ignore: implicit_dynamic_type
    return EqualUnmodifiableListView(_colors);
  }

// Hex strings
  @override
  @JsonKey()
  final String particleEffect;

  @override
  String toString() {
    return 'VisualConfig(shapeType: $shapeType, colors: $colors, particleEffect: $particleEffect)';
  }

  @override
  bool operator ==(Object other) {
    return identical(this, other) ||
        (other.runtimeType == runtimeType &&
            other is _$VisualConfigImpl &&
            (identical(other.shapeType, shapeType) ||
                other.shapeType == shapeType) &&
            const DeepCollectionEquality().equals(other._colors, _colors) &&
            (identical(other.particleEffect, particleEffect) ||
                other.particleEffect == particleEffect));
  }

  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  int get hashCode => Object.hash(runtimeType, shapeType,
      const DeepCollectionEquality().hash(_colors), particleEffect);

  /// Create a copy of VisualConfig
  /// with the given fields replaced by the non-null parameter values.
  @JsonKey(includeFromJson: false, includeToJson: false)
  @override
  @pragma('vm:prefer-inline')
  _$$VisualConfigImplCopyWith<_$VisualConfigImpl> get copyWith =>
      __$$VisualConfigImplCopyWithImpl<_$VisualConfigImpl>(this, _$identity);

  @override
  Map<String, dynamic> toJson() {
    return _$$VisualConfigImplToJson(
      this,
    );
  }
}

abstract class _VisualConfig implements VisualConfig {
  const factory _VisualConfig(
      {required final String shapeType,
      required final List<String> colors,
      final String particleEffect}) = _$VisualConfigImpl;

  factory _VisualConfig.fromJson(Map<String, dynamic> json) =
      _$VisualConfigImpl.fromJson;

  @override
  String
      get shapeType; // circle, chili, leaf, fire, drop, star, hexagon, squircle
  @override
  List<String> get colors; // Hex strings
  @override
  String get particleEffect;

  /// Create a copy of VisualConfig
  /// with the given fields replaced by the non-null parameter values.
  @override
  @JsonKey(includeFromJson: false, includeToJson: false)
  _$$VisualConfigImplCopyWith<_$VisualConfigImpl> get copyWith =>
      throw _privateConstructorUsedError;
}
