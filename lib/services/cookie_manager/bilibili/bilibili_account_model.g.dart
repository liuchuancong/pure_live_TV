// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'bilibili_account_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BilibiliAccountModel _$BilibiliAccountModelFromJson(
  Map<String, dynamic> json,
) => _BilibiliAccountModel(
  isLogined: json['isLogined'] as bool? ?? false,
  name: json['name'] as String? ?? '',
  uid: (json['uid'] as num?)?.toInt() ?? 0,
);

Map<String, dynamic> _$BilibiliAccountModelToJson(
  _BilibiliAccountModel instance,
) => <String, dynamic>{
  'isLogined': instance.isLogined,
  'name': instance.name,
  'uid': instance.uid,
};
