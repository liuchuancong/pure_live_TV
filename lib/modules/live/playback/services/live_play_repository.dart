import 'package:pure_live/exports/common_export.dart';

/// Single access point to Sites for the live playback page.
///
/// It is funnelled through one file so pages and controllers never reach into
/// core/sites directly. A missing site method is adapted here rather than
/// added to core/sites.
class LivePlayRepository {
  const LivePlayRepository();

  /// Loads room details. [hintRoom] carries the platform/room id and the
  /// display fields already on screen; the site response stays authoritative
  /// for playback (its stream payload and identity win), while whatever it
  /// leaves blank is padded from [hintRoom] so a partial response never blanks
  /// the header mid-session.
  Future<LiveRoom> fetchRoomDetail({required LiveRoom hintRoom}) {
    return Sites.of(hintRoom.normalizedPlatformId).liveSite.getRoomDetailForRoom(hintRoom);
  }

  Future<List<LivePlayQuality>> fetchPlayQualities(LiveRoom detail) async {
    try {
      return await Sites.of(detail.normalizedPlatformId).liveSite.getPlayQualites(detail: detail);
    } catch (_) {
      return const <LivePlayQuality>[];
    }
  }

  Future<List<String>> fetchPlayUrls(LiveRoom detail, LivePlayQuality quality) async {
    return await Sites.of(detail.normalizedPlatformId).liveSite.getPlayUrls(detail: detail, quality: quality);
  }

  /// Refetches playback URLs when the player must retry on another engine.
  ///
  /// Routes through [LiveSite.resolvePlayUrlsForRecovery]: platforms that
  /// declare `LivePlayRecoveryResolver` (signed, single-use URLs — huya,
  /// douyu, youtube, …) reacquire a fresh signature here, while the others
  /// simply resolve the normal URL list again. Returning an empty list
  /// makes the player reuse the lines it already holds.
  Future<List<String>> fetchPlayUrlsForRecovery(LiveRoom detail, LivePlayQuality quality) async {
    final resolution = await Sites.of(detail.normalizedPlatformId).liveSite.resolvePlayUrlsForRecovery(
          detail: detail,
          quality: quality,
        );

    return resolution.urls;
  }

  /// Creates the danmaku transport for this platform. Unsupported platforms get
  /// EmptyDanmaku from the site layer.
  LiveDanmaku createDanmaku(LiveRoom detail) {
    return Sites.of(detail.normalizedPlatformId).liveSite.getDanmaku();
  }

  /// When [url] stops starting new connections, for platforms that declare a
  /// transport lease ([LivePlayLeaseMetadata]). `null` — the usual answer —
  /// means the source has no known expiry and keeps the error-driven path.
  /// Whether this platform's lease ends the open connection, i.e. whether the
  /// source is worth renewing underneath the stream (see [LivePlaySpliceableLease]).
  bool leaseEndsStream(LiveRoom detail) {
    try {
      return Sites.of(detail.normalizedPlatformId).liveSite.playUrlLeaseEndsStream;
    } catch (_) {
      return false;
    }
  }

  DateTime? playUrlRefreshAt(LiveRoom detail, String url) {
    try {
      return Sites.of(detail.normalizedPlatformId).liveSite.playUrlRefreshAt(url);
    } catch (_) {
      // A lease is an optimisation; it must never fail the stream it describes.
      return null;
    }
  }
}
