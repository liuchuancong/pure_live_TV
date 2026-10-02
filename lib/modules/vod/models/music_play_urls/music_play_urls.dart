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

  /// Builds the primary video+audio pair and the per-tier menu from a Bilibili
  /// DASH playurl answer (`dash.video` / `dash.audio`), AVC-preferred within
  /// each quality (widest TV-box decoder coverage), highest entitled tier
  /// first. Returns null when there is no usable video track (caller falls
  /// back to the muxed `durl`). Shared by the UGC and PGC endpoints so the two
  /// never drift.
  static MusicPlayUrls? fromDashAnswer(Map<dynamic, dynamic> data, {required int servedQuality}) {
    final dash = data['dash'] as Map<dynamic, dynamic>?;
    if (dash == null) return null;
    final videos = (dash['video'] as List?) ?? const [];
    final audios = (dash['audio'] as List?) ?? const [];
    if (videos.isEmpty) return null;

    String urlOf(Map<dynamic, dynamic> node) => node['base_url']?.toString() ?? '';
    List<String> backupsOf(Map<dynamic, dynamic> node) => [
      for (final u in (node['backup_url'] as List?) ?? (node['backupUrl'] as List?) ?? const <dynamic>[])
        if (u.toString().isNotEmpty) u.toString(),
    ];

    final Map<int, Map<dynamic, dynamic>> byQuality = {};
    for (final v in videos.whereType<Map<dynamic, dynamic>>()) {
      final id = int.tryParse(v['id']?.toString() ?? '') ?? 0;
      if (id <= 0) continue;
      if (servedQuality > 0 && id > servedQuality) continue;
      final existing = byQuality[id];
      final isAvc = v['codecs']?.toString().startsWith('avc') == true;
      if (existing == null || (isAvc && existing['codecs']?.toString().startsWith('avc') != true)) {
        byQuality[id] = v;
      }
    }
    final tiers = byQuality.keys.toList()..sort((a, b) => b.compareTo(a));
    if (tiers.isEmpty) return null;

    final picked = byQuality[tiers.first]!;
    final videoUrl = urlOf(picked);
    if (videoUrl.isEmpty) return null;

    final options = [
      for (final id in tiers)
        MusicStreamOption(
          quality: id,
          url: urlOf(byQuality[id]!),
          codecs: byQuality[id]!['codecs']?.toString() ?? '',
          backupUrls: backupsOf(byQuality[id]!),
        ),
    ];

    Map<dynamic, dynamic>? audio;
    for (final id in const [30280, 30232, 30216]) {
      for (final a in audios.whereType<Map<dynamic, dynamic>>()) {
        if (int.tryParse(a['id']?.toString() ?? '') == id) {
          audio = a;
          break;
        }
      }
      if (audio != null) break;
    }
    audio ??= (audios.whereType<Map<dynamic, dynamic>>()).lastOrNull;

    return MusicPlayUrls(
      videoUrl: videoUrl,
      audioUrl: audio == null ? null : urlOf(audio),
      videoBackupUrls: backupsOf(picked),
      quality: tiers.first,
      isDash: true,
      videoOptions: options,
    );
  }
}
