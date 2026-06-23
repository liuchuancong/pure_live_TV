// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'live_room.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_LiveRoom _$LiveRoomFromJson(Map<String, dynamic> json) => _LiveRoom(
  roomId: json['roomId'] as String? ?? '',
  userId: json['userId'] as String? ?? '',
  link: json['link'] as String? ?? '',
  title: json['title'] as String? ?? '',
  nick: json['nick'] as String? ?? '',
  avatar: json['avatar'] as String? ?? '',
  cover: json['cover'] as String? ?? '',
  area: json['area'] as String? ?? '',
  watching: json['watching'] as String? ?? '0',
  followers: json['followers'] as String? ?? '0',
  platform: json['platform'] as String? ?? 'UNKNOWN',
  tagIds:
      (json['tagIds'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      const [],
  introduction: json['introduction'] as String? ?? '',
  notice: json['notice'] as String? ?? '',
  status: json['status'] as bool? ?? false,
  isRecord: json['isRecord'] as bool? ?? false,
  liveStatus:
      $enumDecodeNullable(_$LiveStatusEnumMap, json['liveStatus']) ??
      LiveStatus.offline,
  epgId: json['epgId'] as String? ?? '',
  currentProgramme: json['currentProgramme'] as String? ?? '',
  currentProgrammeDescription:
      json['currentProgrammeDescription'] as String? ?? '',
  catchUpUrl: json['catchUpUrl'] as String?,
  isCatchUp: json['isCatchUp'] as bool? ?? false,
  catchUpStart: (json['catchUpStart'] as num?)?.toInt(),
  catchUpEnd: (json['catchUpEnd'] as num?)?.toInt(),
);

Map<String, dynamic> _$LiveRoomToJson(_LiveRoom instance) => <String, dynamic>{
  'roomId': instance.roomId,
  'userId': instance.userId,
  'link': instance.link,
  'title': instance.title,
  'nick': instance.nick,
  'avatar': instance.avatar,
  'cover': instance.cover,
  'area': instance.area,
  'watching': instance.watching,
  'followers': instance.followers,
  'platform': instance.platform,
  'tagIds': instance.tagIds,
  'introduction': instance.introduction,
  'notice': instance.notice,
  'status': instance.status,
  'isRecord': instance.isRecord,
  'liveStatus': _$LiveStatusEnumMap[instance.liveStatus]!,
  'epgId': instance.epgId,
  'currentProgramme': instance.currentProgramme,
  'currentProgrammeDescription': instance.currentProgrammeDescription,
  'catchUpUrl': instance.catchUpUrl,
  'isCatchUp': instance.isCatchUp,
  'catchUpStart': instance.catchUpStart,
  'catchUpEnd': instance.catchUpEnd,
};

const _$LiveStatusEnumMap = {
  LiveStatus.live: 'live',
  LiveStatus.offline: 'offline',
  LiveStatus.replay: 'replay',
  LiveStatus.unknown: 'unknown',
  LiveStatus.banned: 'banned',
};
