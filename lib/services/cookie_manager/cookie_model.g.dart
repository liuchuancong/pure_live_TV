// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'cookie_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_CookieModel _$CookieModelFromJson(Map<String, dynamic> json) => _CookieModel(
  bilibiliCookie: json['bilibiliCookie'] as String? ?? '',
  bilibiliUid: (json['bilibiliUid'] as num?)?.toInt() ?? 0,
  huyaCookie: json['huyaCookie'] as String? ?? '',
  douyinCookie: json['douyinCookie'] as String? ?? '',
  kuaishouCookie: json['kuaishouCookie'] as String? ?? '',
);

Map<String, dynamic> _$CookieModelToJson(_CookieModel instance) =>
    <String, dynamic>{
      'bilibiliCookie': instance.bilibiliCookie,
      'bilibiliUid': instance.bilibiliUid,
      'huyaCookie': instance.huyaCookie,
      'douyinCookie': instance.douyinCookie,
      'kuaishouCookie': instance.kuaishouCookie,
    };
