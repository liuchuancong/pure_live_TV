// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'hotword.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_Hotword _$HotwordFromJson(Map<String, dynamic> json) => _Hotword(
  keyword: json['keyword'] as String? ?? '',
  icon: json['icon'] as String? ?? '',
  hotValue: (json['hotValue'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$HotwordToJson(_Hotword instance) => <String, dynamic>{
  'keyword': instance.keyword,
  'icon': instance.icon,
  'hotValue': instance.hotValue,
};
