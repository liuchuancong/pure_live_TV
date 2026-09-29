// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'search_user_item.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SearchUserItem _$SearchUserItemFromJson(Map<String, dynamic> json) =>
    _SearchUserItem(
      mid: json['mid'] == null ? 0 : lenientIntOf(json['mid']),
      uname: json['uname'] == null ? '' : stripHtmlOf(json['uname']),
      face: _readUpicOrFace(json, 'face') == null
          ? ''
          : httpsUrlOf(_readUpicOrFace(json, 'face')),
      sign: json['sign'] == null ? '' : stripHtmlOf(json['sign']),
      fans: json['fans'] == null ? 0 : lenientIntOf(json['fans']),
      videoCount: json['videos'] == null ? 0 : lenientIntOf(json['videos']),
    );

Map<String, dynamic> _$SearchUserItemToJson(_SearchUserItem instance) =>
    <String, dynamic>{
      'mid': instance.mid,
      'uname': instance.uname,
      'face': instance.face,
      'sign': instance.sign,
      'fans': instance.fans,
      'videos': instance.videoCount,
    };
