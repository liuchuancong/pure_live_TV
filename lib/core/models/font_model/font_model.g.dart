// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'font_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_FontModel _$FontModelFromJson(Map<String, dynamic> json) => _FontModel(
  id: json['id'] as String? ?? '',
  name: json['name'] as String? ?? '',
  files:
      (json['files'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  desc: json['desc'] as String? ?? '',
  official: json['official'] as String? ?? '',
  license: json['license'] as Map<String, dynamic>? ?? const {},
);

Map<String, dynamic> _$FontModelToJson(_FontModel instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'files': instance.files,
      'desc': instance.desc,
      'official': instance.official,
      'license': instance.license,
    };
