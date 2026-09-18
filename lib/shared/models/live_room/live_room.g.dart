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
  popularity: json['popularity'] as String? ?? '',
  onlineViewers: json['onlineViewers'] as String? ?? '',
  totalViewers: json['totalViewers'] as String? ?? '',
  followers: json['followers'] as String? ?? '',
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
  audienceMetricType:
      $enumDecodeNullable(
        _$AudienceMetricTypeEnumMap,
        json['audienceMetricType'],
      ) ??
      AudienceMetricType.unknown,
  catchUpUrl: json['catchUpUrl'] as String?,
  isCatchUp: json['isCatchUp'] as bool? ?? false,
  catchUpStart: (json['catchUpStart'] as num?)?.toInt(),
  catchUpEnd: (json['catchUpEnd'] as num?)?.toInt(),
  catchUpMode: json['catchUpMode'] as String?,
  catchUpSource: json['catchUpSource'] as String?,
  catchUpDays: (json['catchUpDays'] as num?)?.toDouble(),
  catchUpCorrectionHours: (json['catchUpCorrectionHours'] as num?)?.toDouble(),
  httpHeaders:
      (json['httpHeaders'] as Map<String, dynamic>?)?.map(
        (k, e) => MapEntry(k, e as String),
      ) ??
      const <String, String>{},
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
  'popularity': instance.popularity,
  'onlineViewers': instance.onlineViewers,
  'totalViewers': instance.totalViewers,
  'followers': instance.followers,
  'platform': instance.platform,
  'tagIds': instance.tagIds,
  'introduction': instance.introduction,
  'notice': instance.notice,
  'status': instance.status,
  'isRecord': instance.isRecord,
  'liveStatus': _$LiveStatusEnumMap[instance.liveStatus]!,
  'audienceMetricType':
      _$AudienceMetricTypeEnumMap[instance.audienceMetricType]!,
  'catchUpUrl': instance.catchUpUrl,
  'isCatchUp': instance.isCatchUp,
  'catchUpStart': instance.catchUpStart,
  'catchUpEnd': instance.catchUpEnd,
  'catchUpMode': instance.catchUpMode,
  'catchUpSource': instance.catchUpSource,
  'catchUpDays': instance.catchUpDays,
  'catchUpCorrectionHours': instance.catchUpCorrectionHours,
  'httpHeaders': instance.httpHeaders,
};

const _$LiveStatusEnumMap = {
  LiveStatus.live: 'live',
  LiveStatus.offline: 'offline',
  LiveStatus.replay: 'replay',
  LiveStatus.unknown: 'unknown',
  LiveStatus.banned: 'banned',
};

const _$AudienceMetricTypeEnumMap = {
  AudienceMetricType.unknown: 'unknown',
  AudienceMetricType.watching: 'watching',
  AudienceMetricType.popularity: 'popularity',
  AudienceMetricType.onlineViewers: 'onlineViewers',
  AudienceMetricType.totalViewers: 'totalViewers',
  AudienceMetricType.followers: 'followers',
};
