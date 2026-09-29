import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:pure_live/modules/vod/models/json_converters.dart';

part 'subtitle_cue.freezed.dart';
part 'subtitle_cue.g.dart';

/// One subtitle cue (the fetched json's `body` entries).
@freezed
abstract class SubtitleCue with _$SubtitleCue {
  const factory SubtitleCue({
    @JsonKey(fromJson: lenientDoubleOf) @Default(0) double from,
    @JsonKey(fromJson: lenientDoubleOf) @Default(0) double to,
    @Default('') String text,
  }) = _SubtitleCue;

  factory SubtitleCue.fromJson(Map<String, dynamic> json) => _$SubtitleCueFromJson(json);
}
