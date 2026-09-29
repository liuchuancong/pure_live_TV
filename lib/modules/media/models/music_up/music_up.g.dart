// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'music_up.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_MusicUp _$MusicUpFromJson(Map<String, dynamic> json) => _MusicUp(
  mid: (json['mid'] as num?)?.toInt() ?? 0,
  name: json['name'] as String? ?? '',
  face: json['face'] as String? ?? '',
);

Map<String, dynamic> _$MusicUpToJson(_MusicUp instance) => <String, dynamic>{
  'mid': instance.mid,
  'name': instance.name,
  'face': instance.face,
};
