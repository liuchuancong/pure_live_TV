// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cookie_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CookieModel _$CookieModelFromJson(Map<String, dynamic> json) => _CookieModel(
  bilibiliCookie: json['bilibiliCookie'] as String? ?? '',
  bilibiliUid: (json['bilibiliUid'] as num?)?.toInt() ?? 0,
  huyaCookie: json['huyaCookie'] as String? ?? '',
  douyuCookie: json['douyuCookie'] as String? ?? '',
  douyuLtp0: json['douyuLtp0'] as String? ?? '',
  douyuDid: json['douyuDid'] as String? ?? '',
  douyuCookieSavedAt: (json['douyuCookieSavedAt'] as num?)?.toInt() ?? 0,
  douyinCookie: json['douyinCookie'] as String? ?? '',
  kuaishouCookie: json['kuaishouCookie'] as String? ?? '',
  yyCookie: json['yyCookie'] as String? ?? '',
  soopCookie: json['soopCookie'] as String? ?? '',
  twitchCookie: json['twitchCookie'] as String? ?? '',
);

Map<String, dynamic> _$CookieModelToJson(_CookieModel instance) =>
    <String, dynamic>{
      'bilibiliCookie': instance.bilibiliCookie,
      'bilibiliUid': instance.bilibiliUid,
      'huyaCookie': instance.huyaCookie,
      'douyuCookie': instance.douyuCookie,
      'douyuLtp0': instance.douyuLtp0,
      'douyuDid': instance.douyuDid,
      'douyuCookieSavedAt': instance.douyuCookieSavedAt,
      'douyinCookie': instance.douyinCookie,
      'kuaishouCookie': instance.kuaishouCookie,
      'yyCookie': instance.yyCookie,
      'soopCookie': instance.soopCookie,
      'twitchCookie': instance.twitchCookie,
    };
