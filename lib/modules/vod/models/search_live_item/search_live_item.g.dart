// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'search_live_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SearchLiveItem _$SearchLiveItemFromJson(Map<String, dynamic> json) =>
    _SearchLiveItem(
      roomId: json['roomid'] == null ? 0 : lenientIntOf(json['roomid']),
      title: json['title'] == null ? '' : stripHtmlOf(json['title']),
      cover: _readCoverOrUserCover(json, 'cover') == null
          ? ''
          : httpsUrlOf(_readCoverOrUserCover(json, 'cover')),
      uname: json['uname'] == null ? '' : stripHtmlOf(json['uname']),
      online: json['online'] == null ? 0 : lenientIntOf(json['online']),
      liveStatus: json['live_status'] == null
          ? 0
          : lenientIntOf(json['live_status']),
    );

Map<String, dynamic> _$SearchLiveItemToJson(_SearchLiveItem instance) =>
    <String, dynamic>{
      'roomid': instance.roomId,
      'title': instance.title,
      'cover': instance.cover,
      'uname': instance.uname,
      'online': instance.online,
      'live_status': instance.liveStatus,
    };
