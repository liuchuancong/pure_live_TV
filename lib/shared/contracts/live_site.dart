import 'package:pure_live/shared/models/index.dart';
import 'package:pure_live/shared/contracts/live_danmaku.dart';

import 'live_input_recipe.dart';
import 'package:pure_live/shared/common/hls_source_query_policy.dart';

/// URLs for one requested quality plus the quality the platform actually
/// applied — some platforms silently downgrade guest requests, so adapters
/// that can inspect the response set [appliedQualityData] to the server's
/// stable quality identifier.
class LivePlayUrlResolution {
  const LivePlayUrlResolution({required this.urls, this.appliedQualityData, this.qualityUnconfirmed = false})
    : sourceQueryPolicies = const {},
      inputRecipe = null;

  /// An owned input is a real source but has no exportable media URL.
  const LivePlayUrlResolution.owned({
    required LiveInputRecipe input,
    this.appliedQualityData,
    this.qualityUnconfirmed = false,
  }) : inputRecipe = input,
       urls = const [],
       sourceQueryPolicies = const {};

  LivePlayUrlResolution._({
    required this.urls,
    required this.sourceQueryPolicies,
    this.appliedQualityData,
    this.qualityUnconfirmed = false,
  }) : inputRecipe = null;

  /// Policy-bearing sources are copied and validated together. Keys identify
  /// exact signed URLs, never only CDN positions or quality labels.
  factory LivePlayUrlResolution.withSourcePolicies({
    required List<String> urls,
    required Map<String, HlsSourceQueryPolicy> sourceQueryPolicies,
    Object? appliedQualityData,
    bool qualityUnconfirmed = false,
  }) {
    final normalized = normalizeResolvedPlayUrls(urls);
    final policies = <String, HlsSourceQueryPolicy>{};
    for (final entry in sourceQueryPolicies.entries) {
      final uri = Uri.tryParse(entry.key);
      if (!normalized.contains(entry.key) || uri == null || !entry.value.matchesSource(uri)) {
        throw const FormatException('Source query policy does not match resolved URLs');
      }
      policies[entry.key] = entry.value;
    }
    return LivePlayUrlResolution._(
      urls: normalized,
      sourceQueryPolicies: Map.unmodifiable(policies),
      appliedQualityData: appliedQualityData,
      qualityUnconfirmed: qualityUnconfirmed,
    );
  }

  LivePlayUrlResolution normalized() => inputRecipe != null
      ? this
      : LivePlayUrlResolution.withSourcePolicies(
          urls: urls,
          sourceQueryPolicies: sourceQueryPolicies,
          appliedQualityData: appliedQualityData,
          qualityUnconfirmed: qualityUnconfirmed,
        );

  final List<String> urls;
  final LiveInputRecipe? inputRecipe;
  int get lineCount => inputRecipe == null ? urls.length : 1;
  bool get hasSources => lineCount > 0;
  final Object? appliedQualityData;
  final Map<String, HlsSourceQueryPolicy> sourceQueryPolicies;

  /// An adapter expected an acknowledgement but the response did not contain a
  /// usable one. False preserves the legacy contract for platforms with no ack.
  final bool qualityUnconfirmed;
}

/// Keeps request identity and display evidence separate; a stale-menu id does
/// not confirm the visible name.
LivePlayQuality resolveAppliedPlayQuality({
  required List<LivePlayQuality> qualities,
  required LivePlayQuality requested,
  required LivePlayUrlResolution resolution,
}) {
  final appliedId = resolution.appliedQualityData?.toString();
  LivePlayQuality? matched;
  if (appliedId != null) {
    for (final quality in qualities) {
      if (quality.selectionId.toString() == appliedId) {
        matched = quality;
        break;
      }
    }
  }
  return (matched ?? requested).withPlaybackUnconfirmed(
    resolution.qualityUnconfirmed || (appliedId != null && matched == null),
  );
}

/// Removes blank and duplicate lines while preserving priority; scheme
/// validation stays adapter-specific (IPTV allows non-HTTP protocols).
List<String> normalizeResolvedPlayUrls(Iterable<String> urls) {
  final result = <String>[];
  final seen = <String>{};

  for (final rawUrl in urls) {
    final url = rawUrl.trim();

    if (url.isNotEmpty && seen.add(url)) {
      result.add(url);
    }
  }

  return List<String>.unmodifiable(result);
}

/// Optional capability for platforms whose play API reports the applied
/// quality (bilibili guest requests can be downgraded silently).
abstract interface class LivePlayUrlResolver {
  Future<LivePlayUrlResolution> resolvePlayUrlsRaw({required LiveRoom detail, required LivePlayQuality quality});
}

/// Optional contract for adapters that need one request per CDN line:
/// recording resolves only the current attempt's line and fetches the next
/// failure. Implementations return an empty URL list when [lineIndex] is beyond
/// the platform's advertised lines.
abstract interface class LivePlayUrlCursorResolver {
  Future<LivePlayUrlResolution> resolvePlayUrlAtRaw({
    required LiveRoom detail,
    required LivePlayQuality quality,
    required int lineIndex,
  });
}

/// Optional recovery contract for signed platforms whose room metadata and
/// playback URLs have a shorter lifetime than the visible room session.
///
/// Implementations must reacquire every identity/token/room field needed for
/// a new connection. Returning the same cached URL list defeats the purpose of
/// this contract and can reopen an already-expired source indefinitely.
abstract interface class LivePlayRecoveryResolver {
  Future<LivePlayUrlResolution> resolvePlayUrlsForRecoveryRaw({
    required LiveRoom detail,
    required LivePlayQuality quality,
  });
}

/// Optional lease metadata for short-lived signed playback URLs.
///
/// A player can refresh the token before this timestamp rather than waiting for
/// the server to reject a later reconnect. Windows can use its first-frame
/// gated replacement transaction for sources whose transport lease is shorter
/// than the signed URL; other platforms may cache the lease for recovery.
/// Returning `null` keeps ordinary long-lived sources on the error-driven path.
abstract interface class LivePlayLeaseMetadata {
  DateTime? getPlayUrlRefreshAt(String url, {DateTime? now});

  /// The final instant at which a prefetched URL can start a new connection.
  ///
  /// Separate from [getPlayUrlRefreshAt]. A source
  /// prefetched shortly before the active connection fails remains usable until
  /// this deadline, while an expired cache entry must be discarded.
  DateTime? getPlayUrlInvalidAt(String url, {DateTime? now});
}

class LiveSite {
  String id = "";
  String name = "";

  LiveDanmaku getDanmaku() {
    throw UnimplementedError();
  }

  Future<List<LiveCategory>> getCategores(int page, int pageSize) async {
    return Future.value(<LiveCategory>[]);
  }

  Future<List<LiveRoom>> searchRooms(String keyword, {int page = 1, int pageSize = 30}) async {
    return Future.value(<LiveRoom>[]);
  }

  Future<List<LiveAnchorItem>> searchAnchors(String keyword, {int page = 1, int pageSize = 30}) async {
    return Future.value(<LiveAnchorItem>[]);
  }

  Future<List<LiveRoom>> getCategoryRooms(LiveArea category, {int page = 1, int pageSize = 30}) async {
    return Future.value(<LiveRoom>[]);
  }

  Future<List<LiveRoom>> getRecommendRooms({int page = 1, int pageSize = 30}) async {
    return Future.value(<LiveRoom>[]);
  }

  Future<LiveRoom> getRoomDetail({required String roomId, required String platform}) async {
    return Future.value(
      LiveRoom(
        cover: '',
        watching: '',
        roomId: '',
        // The base implementation has no platform evidence. Treat it as
        // pending/unknown instead of fabricating an authoritative offline
        // response; concrete adapters must explicitly report offline/banned.
        // LiveRoom.status is non-nullable on TV; the pending state lives in liveStatus.
        status: false,
        platform: platform,
        liveStatus: LiveStatus.unknown,
        title: '',
        link: '',
        avatar: '',
        nick: '',
        isRecord: false,
      ),
    );
  }

  Future<List<LivePlayQuality>> getPlayQualites({required LiveRoom detail}) async {
    return Future.value(<LivePlayQuality>[]);
  }

  Future<List<String>> getPlayUrls({required LiveRoom detail, required LivePlayQuality quality}) async {
    return Future.value(<String>[]);
  }

  Future<bool> getLiveStatus({required String platform, required String roomId}) async {
    return Future.value(false);
  }

  Future<List<LiveSuperChatMessage>> getSuperChatMessage({required String roomId}) async {
    return Future.value([]);
  }
}

/// Unified playback URL resolution.
///
/// Capability-aware adapters can return the quality actually applied by
/// the server through [LivePlayUrlResolver.resolvePlayUrlsRaw].
///
/// Other adapters continue using [LiveSite.getPlayUrls] and assume that
/// the requested quality was applied.
extension LiveSitePlayUrlResolution on LiveSite {
  Future<LivePlayUrlResolution> resolvePlayUrls({required LiveRoom detail, required LivePlayQuality quality}) async {
    final site = this;

    if (site is LivePlayUrlResolver) {
      final resolver = site as LivePlayUrlResolver;

      final resolution = await resolver.resolvePlayUrlsRaw(detail: detail, quality: quality);

      return resolution.normalized();
    }

    return LivePlayUrlResolution(
      urls: normalizeResolvedPlayUrls(await getPlayUrls(detail: detail, quality: quality)),
      appliedQualityData: quality.selectionId,
    );
  }

  Future<LivePlayUrlResolution> resolvePlayUrlsForRecovery({
    required LiveRoom detail,
    required LivePlayQuality quality,
  }) async {
    final site = this;
    if (site is LivePlayRecoveryResolver) {
      final resolution = await (site as LivePlayRecoveryResolver).resolvePlayUrlsForRecoveryRaw(
        detail: detail,
        quality: quality,
      );
      return resolution.normalized();
    }
    return resolvePlayUrls(detail: detail, quality: quality);
  }
}

/// Optional fast metadata path used by favourites/background verification.
///
/// Entering a room needs playback URLs, signing material and chat credentials;
/// refreshing a card needs only status/title/cover/audience metadata.
///
/// Keeping this as a separate capability lets platforms skip those extra
/// calls without changing the full room-entry contract for every site
/// implementation.
abstract interface class LiveSiteRoomRefresher {
  Future<LiveRoom> getRoomDetailForRefresh({required String roomId, required String platform});
}

/// Fetches the snapshot a favourite/history card refresh should use.
///
/// [LiveSiteRoomRefresher] is preferred whenever the adapter provides it: the
/// ordinary [LiveSite.getRoomDetail] is a *presentation* contract, and several
/// adapters answer a transport or response-shape failure with an
/// offline-looking fallback room (see [LiveSiteRoomRefresher]'s note above).
/// Calling that from a card refresh silently turned a network hiccup into an
/// authoritative offline card, which is the "followed room status is wrong"
/// defect this dispatch fixes.
///
/// Adapters without the fast path keep the old call and are expected to
/// propagate their failures to the caller.
Future<LiveRoom> fetchRoomDetailForRefresh({
  required LiveSite site,
  required String roomId,
  required String platform,
}) {
  final refresher = site;

  if (refresher is LiveSiteRoomRefresher) {
    return (refresher as LiveSiteRoomRefresher).getRoomDetailForRefresh(roomId: roomId, platform: platform);
  }

  return site.getRoomDetail(roomId: roomId, platform: platform);
}

/// Strict, playback-complete room lookup used before a recording starts.
///
/// The ordinary [LiveSite.getRoomDetail] contract is UI-oriented. Several
/// adapters turn transport/shape errors into an offline-looking
/// fallback room so an already mounted player can keep its last metadata.
/// That behaviour is useful for presentation, but it is unsafe for recording:
/// one temporary metadata error was interpreted as an authoritative offline
/// state and the recorder stopped before it ever asked for a stream URL.
///
/// [LiveSiteRoomRefresher] is not a substitute for this capability. Refresh
/// implementations may omit signed playback descriptors to keep
/// favourite-card refreshes cheap. Implementations of this interface must:
///
/// * propagate transport and response-shape failures;
/// * return an explicit offline/banned room only when the platform said so;
/// * retain every field required by [LiveSite.getPlayQualites].
abstract interface class LiveSiteRecordRoomResolver {
  Future<LiveRoom> getRoomDetailForRecording({required String roomId, required String platform});
}
