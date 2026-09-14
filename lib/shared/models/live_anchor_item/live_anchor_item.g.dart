// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'live_anchor_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_LiveAnchorItem _$LiveAnchorItemFromJson(Map<String, dynamic> json) =>
    _LiveAnchorItem(
      roomId: json['roomId'] as String,
      avatar: json['avatar'] as String,
      userName: json['userName'] as String,
      liveStatus: json['liveStatus'] as bool,
    );

Map<String, dynamic> _$LiveAnchorItemToJson(_LiveAnchorItem instance) =>
    <String, dynamic>{
      'roomId': instance.roomId,
      'avatar': instance.avatar,
      'userName': instance.userName,
      'liveStatus': instance.liveStatus,
    };
