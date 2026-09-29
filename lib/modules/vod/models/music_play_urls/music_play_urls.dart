import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:pure_live/modules/vod/models/music_stream_option/music_stream_option.dart';

part 'music_play_urls.freezed.dart';

/// Resolved playback URLs for one track.
@freezed
abstract class MusicPlayUrls with _$MusicPlayUrls {
  const factory MusicPlayUrls({
    /// The stream to hand the player as the primary source. For DASH this is
    /// the video-only m4s (the audio rides along through the player's
    /// audio-file input); for the mp4 fallback it is the muxed file.
    required String videoUrl,

    /// The DASH audio m4s. Null for the muxed mp4 fallback (and for
    /// audio-only playback the audio URL itself becomes the primary source).
    String? audioUrl,
    @Default([]) List<String> videoBackupUrls,

    /// The quality id actually served.
    @Default(0) int quality,
    @Default(true) bool isDash,

    /// Every quality the current answer can serve, AVC-preferred per tier.
    @Default([]) List<MusicStreamOption> videoOptions,
  }) = _MusicPlayUrls;
}
