import 'package:freezed_annotation/freezed_annotation.dart';

part 'live_play_quality.freezed.dart';
part 'live_play_quality.g.dart';

@freezed
abstract class LivePlayQuality with _$LivePlayQuality {
  const LivePlayQuality._();

  const factory LivePlayQuality({
    required String quality,
    dynamic data,
    @Default(0) int sort,
    dynamic id,
    @Default(false) bool playbackUnconfirmed,
  }) = _LivePlayQuality;

  factory LivePlayQuality.fromJson(Map<String, dynamic> json) => _$LivePlayQualityFromJson(json);

  /// Stable identifier used when picking a stream: the site quality id when
  /// present, otherwise the label text.
  dynamic get selectionId {
    final value = id;
    if (value != null && value.toString().isNotEmpty) return value;
    return quality;
  }

  LivePlayQuality withPlaybackUnconfirmed(bool unconfirmed) =>
      unconfirmed == playbackUnconfirmed ? this : copyWith(playbackUnconfirmed: unconfirmed);
}
