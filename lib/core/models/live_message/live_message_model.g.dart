// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'live_message_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_LiveMessageColor _$LiveMessageColorFromJson(Map<String, dynamic> json) =>
    _LiveMessageColor(
      r: (json['r'] as num).toInt(),
      g: (json['g'] as num).toInt(),
      b: (json['b'] as num).toInt(),
    );

Map<String, dynamic> _$LiveMessageColorToJson(_LiveMessageColor instance) =>
    <String, dynamic>{'r': instance.r, 'g': instance.g, 'b': instance.b};

_LiveMessage _$LiveMessageFromJson(Map<String, dynamic> json) => _LiveMessage(
  type: $enumDecode(_$LiveMessageTypeEnumMap, json['type']),
  userName: json['userName'] as String,
  message: json['message'] as String,
  color: LiveMessageColor.fromJson(json['color'] as Map<String, dynamic>),
  data: json['data'],
  messageId: json['messageId'] as String?,
  userId: json['userId'] as String?,
  sentAt: json['sentAt'] == null
      ? null
      : DateTime.parse(json['sentAt'] as String),
  isLocal: json['isLocal'] as bool? ?? false,
);

Map<String, dynamic> _$LiveMessageToJson(_LiveMessage instance) =>
    <String, dynamic>{
      'type': _$LiveMessageTypeEnumMap[instance.type]!,
      'userName': instance.userName,
      'message': instance.message,
      'color': instance.color,
      'data': instance.data,
      'messageId': instance.messageId,
      'userId': instance.userId,
      'sentAt': instance.sentAt?.toIso8601String(),
      'isLocal': instance.isLocal,
    };

const _$LiveMessageTypeEnumMap = {
  LiveMessageType.chat: 'chat',
  LiveMessageType.gift: 'gift',
  LiveMessageType.online: 'online',
  LiveMessageType.superChat: 'superChat',
};

_LiveSuperChatMessage _$LiveSuperChatMessageFromJson(
  Map<String, dynamic> json,
) => _LiveSuperChatMessage(
  messageId: json['messageId'] as String? ?? '',
  userName: json['userName'] as String,
  face: json['face'] as String,
  message: json['message'] as String,
  price: (json['price'] as num).toInt(),
  startTime: DateTime.parse(json['startTime'] as String),
  endTime: DateTime.parse(json['endTime'] as String),
  backgroundColor: json['backgroundColor'] as String,
  backgroundBottomColor: json['backgroundBottomColor'] as String,
);

Map<String, dynamic> _$LiveSuperChatMessageToJson(
  _LiveSuperChatMessage instance,
) => <String, dynamic>{
  'messageId': instance.messageId,
  'userName': instance.userName,
  'face': instance.face,
  'message': instance.message,
  'price': instance.price,
  'startTime': instance.startTime.toIso8601String(),
  'endTime': instance.endTime.toIso8601String(),
  'backgroundColor': instance.backgroundColor,
  'backgroundBottomColor': instance.backgroundBottomColor,
};
