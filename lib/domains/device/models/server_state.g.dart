// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'server_state.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_ServerState _$ServerStateFromJson(Map<String, dynamic> json) => _ServerState(
  isRunning: json['isRunning'] as bool,
  serverUrl: json['serverUrl'] as String,
  port: (json['port'] as num).toInt(),
  error: json['error'] as String?,
);

Map<String, dynamic> _$ServerStateToJson(_ServerState instance) =>
    <String, dynamic>{
      'isRunning': instance.isRunning,
      'serverUrl': instance.serverUrl,
      'port': instance.port,
      'error': instance.error,
    };
