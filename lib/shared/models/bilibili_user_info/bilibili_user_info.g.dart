// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bilibili_user_info.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BilibiliUserInfo _$BilibiliUserInfoFromJson(Map<String, dynamic> json) =>
    _BilibiliUserInfo(
      mid: (json['mid'] as num?)?.toInt(),
      uname: json['uname'] as String?,
      userid: json['userid'] as String?,
      sign: json['sign'] as String?,
      birthday: json['birthday'] as String?,
      sex: json['sex'] as String?,
      nickFree: json['nick_free'] as bool?,
      rank: json['rank'] as String?,
    );

Map<String, dynamic> _$BilibiliUserInfoToJson(_BilibiliUserInfo instance) =>
    <String, dynamic>{
      'mid': instance.mid,
      'uname': instance.uname,
      'userid': instance.userid,
      'sign': instance.sign,
      'birthday': instance.birthday,
      'sex': instance.sex,
      'nick_free': instance.nickFree,
      'rank': instance.rank,
    };
