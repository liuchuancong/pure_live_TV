// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'webdav_config.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_WebDAVConfig _$WebDAVConfigFromJson(Map<String, dynamic> json) =>
    _WebDAVConfig(
      name: json['name'] as String? ?? '',
      address: json['address'] as String? ?? '',
      username: json['username'] as String? ?? '',
      password: json['password'] as String? ?? '',
    );

Map<String, dynamic> _$WebDAVConfigToJson(_WebDAVConfig instance) =>
    <String, dynamic>{
      'name': instance.name,
      'address': instance.address,
      'username': instance.username,
      'password': instance.password,
    };
