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

  /// 选流时使用的稳定标识：优先站点给的质量 id，否则退回标签文本。
  dynamic get selectionId {
    final value = id;
    if (value != null && value.toString().isNotEmpty) return value;
    return quality;
  }

  LivePlayQuality withPlaybackUnconfirmed(bool unconfirmed) =>
      unconfirmed == playbackUnconfirmed ? this : copyWith(playbackUnconfirmed: unconfirmed);
}
