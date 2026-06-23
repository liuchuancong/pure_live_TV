// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'webdav_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_WebDavModel _$WebDavModelFromJson(Map<String, dynamic> json) => _WebDavModel(
  currentWebDavConfig: json['currentWebDavConfig'] as String? ?? '',
  webDavConfigs:
      (json['webDavConfigs'] as List<dynamic>?)
          ?.map((e) => WebDAVConfig.fromJson(e as Map<String, dynamic>))
          .toList() ??
      const [],
);

Map<String, dynamic> _$WebDavModelToJson(_WebDavModel instance) =>
    <String, dynamic>{
      'currentWebDavConfig': instance.currentWebDavConfig,
      'webDavConfigs': instance.webDavConfigs,
    };
