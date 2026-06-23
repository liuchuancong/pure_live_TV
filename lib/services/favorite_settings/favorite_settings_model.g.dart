// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'favorite_settings_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_FavoriteSettingsModel _$FavoriteSettingsModelFromJson(
  Map<String, dynamic> json,
) => _FavoriteSettingsModel(
  shieldList:
      (json['shieldList'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  hotAreasList:
      (json['hotAreasList'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      const [],
  preferPlatform: json['preferPlatform'] as String? ?? '',
  favoriteRooms:
      (json['favoriteRooms'] as List<dynamic>?)
          ?.map((e) => LiveRoom.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
  favoriteAreas:
      (json['favoriteAreas'] as List<dynamic>?)
          ?.map((e) => LiveArea.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
);

Map<String, dynamic> _$FavoriteSettingsModelToJson(
  _FavoriteSettingsModel instance,
) => <String, dynamic>{
  'shieldList': instance.shieldList,
  'hotAreasList': instance.hotAreasList,
  'preferPlatform': instance.preferPlatform,
  'favoriteRooms': instance.favoriteRooms,
  'favoriteAreas': instance.favoriteAreas,
};
