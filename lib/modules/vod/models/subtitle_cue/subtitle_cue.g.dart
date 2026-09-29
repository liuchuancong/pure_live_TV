// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subtitle_cue.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SubtitleCue _$SubtitleCueFromJson(Map<String, dynamic> json) => _SubtitleCue(
  from: json['from'] == null ? 0 : lenientDoubleOf(json['from']),
  to: json['to'] == null ? 0 : lenientDoubleOf(json['to']),
  text: json['text'] as String? ?? '',
);

Map<String, dynamic> _$SubtitleCueToJson(_SubtitleCue instance) =>
    <String, dynamic>{
      'from': instance.from,
      'to': instance.to,
      'text': instance.text,
    };
