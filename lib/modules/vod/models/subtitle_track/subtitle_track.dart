import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:pure_live/modules/vod/models/json_converters.dart';

part 'subtitle_track.freezed.dart';
part 'subtitle_track.g.dart';

/// One subtitle track of a video (`x/player/wbi/v2` → `subtitle.subtitles`).
@freezed
abstract class SubtitleTrack with _$SubtitleTrack {
  const factory SubtitleTrack({
    @Default('') String lan,
    @JsonKey(name: 'lan_doc') @Default('') String lanDoc,
    @JsonKey(name: 'subtitle_url', fromJson: httpsUrlOf) @Default('') String url,
  }) = _SubtitleTrack;

  factory SubtitleTrack.fromJson(Map<String, dynamic> json) => _$SubtitleTrackFromJson(json);
}
