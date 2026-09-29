// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'subtitle_track.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_SubtitleTrack _$SubtitleTrackFromJson(Map<String, dynamic> json) =>
    _SubtitleTrack(
      lan: json['lan'] as String? ?? '',
      lanDoc: json['lan_doc'] as String? ?? '',
      url: json['subtitle_url'] == null ? '' : httpsUrlOf(json['subtitle_url']),
    );

Map<String, dynamic> _$SubtitleTrackToJson(_SubtitleTrack instance) =>
    <String, dynamic>{
      'lan': instance.lan,
      'lan_doc': instance.lanDoc,
      'subtitle_url': instance.url,
    };
