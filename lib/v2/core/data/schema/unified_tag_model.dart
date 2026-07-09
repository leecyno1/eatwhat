import 'package:freezed_annotation/freezed_annotation.dart';

part 'unified_tag_model.freezed.dart';
part 'unified_tag_model.g.dart';

@freezed
class UnifiedTagModel with _$UnifiedTagModel {
  const factory UnifiedTagModel({
    required String id,
    required String label,
    required String
        category, // flavor, ingredient, cuisine, scene, nutrition, meta
    required String iconAsset,
    required VisualConfig visual,
    @Default(0.5) double weight,
  }) = _UnifiedTagModel;

  factory UnifiedTagModel.fromJson(Map<String, dynamic> json) =>
      _$UnifiedTagModelFromJson(json);
}

@freezed
class VisualConfig with _$VisualConfig {
  const factory VisualConfig({
    required String
        shapeType, // circle, chili, leaf, fire, drop, star, hexagon, squircle
    required List<String> colors, // Hex strings
    @Default('none')
    String particleEffect, // none, steam, sparkle, glow, bubble
  }) = _VisualConfig;

  factory VisualConfig.fromJson(Map<String, dynamic> json) =>
      _$VisualConfigFromJson(json);
}
