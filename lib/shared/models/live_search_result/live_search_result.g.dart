// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'live_search_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_LiveSearchRoomResult _$LiveSearchRoomResultFromJson(
  Map<String, dynamic> json,
) => _LiveSearchRoomResult(
  hasMore: json['hasMore'] as bool? ?? false,
  items:
      (json['items'] as List<dynamic>?)
          ?.map((e) => LiveRoom.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
);

Map<String, dynamic> _$LiveSearchRoomResultToJson(
  _LiveSearchRoomResult instance,
) => <String, dynamic>{'hasMore': instance.hasMore, 'items': instance.items};

_LiveSearchAnchorResult _$LiveSearchAnchorResultFromJson(
  Map<String, dynamic> json,
) => _LiveSearchAnchorResult(
  hasMore: json['hasMore'] as bool? ?? false,
  items:
      (json['items'] as List<dynamic>?)
          ?.map((e) => LiveAnchorItem.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
);

Map<String, dynamic> _$LiveSearchAnchorResultToJson(
  _LiveSearchAnchorResult instance,
) => <String, dynamic>{'hasMore': instance.hasMore, 'items': instance.items};
