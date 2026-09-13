// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'history_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_HistoryModel _$HistoryModelFromJson(Map<String, dynamic> json) =>
    _HistoryModel(
      historyRooms:
          (json['historyRooms'] as List<dynamic>?)
              ?.map((e) => LiveRoom.fromJson(e as Map<String, dynamic>))
              .toList() ??
          const [],
      historyLimit: (json['historyLimit'] as num?)?.toInt() ?? 50,
    );

Map<String, dynamic> _$HistoryModelToJson(_HistoryModel instance) =>
    <String, dynamic>{
      'historyRooms': instance.historyRooms,
      'historyLimit': instance.historyLimit,
    };
