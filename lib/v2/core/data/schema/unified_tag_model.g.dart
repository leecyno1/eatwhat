// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'unified_tag_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_$UnifiedTagModelImpl _$$UnifiedTagModelImplFromJson(
        Map<String, dynamic> json) =>
    _$UnifiedTagModelImpl(
      id: json['id'] as String,
      label: json['label'] as String,
      category: json['category'] as String,
      iconAsset: json['iconAsset'] as String,
      visual: VisualConfig.fromJson(json['visual'] as Map<String, dynamic>),
      weight: (json['weight'] as num?)?.toDouble() ?? 0.5,
    );

Map<String, dynamic> _$$UnifiedTagModelImplToJson(
        _$UnifiedTagModelImpl instance) =>
    <String, dynamic>{
      'id': instance.id,
      'label': instance.label,
      'category': instance.category,
      'iconAsset': instance.iconAsset,
      'visual': instance.visual,
      'weight': instance.weight,
    };

_$VisualConfigImpl _$$VisualConfigImplFromJson(Map<String, dynamic> json) =>
    _$VisualConfigImpl(
      shapeType: json['shapeType'] as String,
      colors:
          (json['colors'] as List<dynamic>).map((e) => e as String).toList(),
      particleEffect: json['particleEffect'] as String? ?? 'none',
    );

Map<String, dynamic> _$$VisualConfigImplToJson(_$VisualConfigImpl instance) =>
    <String, dynamic>{
      'shapeType': instance.shapeType,
      'colors': instance.colors,
      'particleEffect': instance.particleEffect,
    };
