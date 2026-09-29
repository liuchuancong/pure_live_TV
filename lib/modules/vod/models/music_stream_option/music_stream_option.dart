import 'package:freezed_annotation/freezed_annotation.dart';

part 'music_stream_option.freezed.dart';

/// One DASH video rendition (a quality/codec candidate). The playurl answer
/// carries them all at once, so switching quality re-opens a URL from here
/// instead of asking the API again.
@freezed
abstract class MusicStreamOption with _$MusicStreamOption {
  const factory MusicStreamOption({
    required int quality,
    required String url,
    @Default('') String codecs,
    @Default([]) List<String> backupUrls,
  }) = _MusicStreamOption;
}
