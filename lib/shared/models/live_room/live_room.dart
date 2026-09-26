import 'package:pure_live/shared/i18n/locale_helper.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'live_room.freezed.dart';
part 'live_room.g.dart';

enum LiveStatus { live, offline, replay, unknown, banned }

/// Source of the audience number, used to decide whether two values are
/// comparable at all.
enum AudienceMetricType { unknown, watching, popularity, onlineViewers, totalViewers, followers }

extension AudienceMetricTypeRank on AudienceMetricType {
  /// Ranking weight: concurrent viewers > cumulative viewers > heat > followers.
  int get rankingRank => switch (this) {
    AudienceMetricType.onlineViewers => 4,
    AudienceMetricType.watching => 3,
    AudienceMetricType.totalViewers => 2,
    AudienceMetricType.popularity => 1,
    AudienceMetricType.followers => 1,
    AudienceMetricType.unknown => 0,
  };
}

/// Where a platform publishes an explicit concurrent audience number.
enum AudienceOnlineAvailability {
  /// The public API exposes no concurrent head count at all.
  unsupported,

  /// The count only arrives while a room is open (realtime messages).
  roomRealtime,

  /// Room lists and details already carry the count, so lists can rank by it.
  roomList,
}

/// Audience fields a platform really exposes.
///
/// A platform may publish heat and cumulative viewers without ever publishing
/// a concurrent head count; the room card must not present heat as an audience.
class AudiencePlatformCapability {
  const AudiencePlatformCapability({
    required this.hasPopularity,
    required this.hasTotalViewers,
    required this.onlineAvailability,
  });

  final bool hasPopularity;
  final bool hasTotalViewers;
  final AudienceOnlineAvailability onlineAvailability;

  bool get supportsConcurrentOnline => onlineAvailability != AudienceOnlineAvailability.unsupported;

  bool get onlineAvailableInRoomLists => onlineAvailability == AudienceOnlineAvailability.roomList;
}

/// Comparable audience key used when rooms from different metric scales share
/// one list.
///
/// In concurrent-viewer mode an explicit concurrent value must rank ahead of a
/// pending value, and a pending supported room must stay ahead of a heat or
/// cumulative fallback. This stops a multi-million heat score from outranking a
/// real audience of a few thousand people.
class AudienceRankKey {
  const AudienceRankKey({required this.metricPriority, required this.value});

  final int metricPriority;
  final int value;
}

@freezed
abstract class LiveRoom with _$LiveRoom {
  const LiveRoom._();

  /// Audience fields each platform actually publishes.
  ///
  /// Only [AudienceOnlineAvailability.roomList] and
  /// [AudienceOnlineAvailability.roomRealtime] platforms may show a concurrent
  /// viewer badge; everything else keeps ranking by heat or cumulative views.
  static const Map<String, AudiencePlatformCapability> audienceCapabilities = {
    // Bilibili's room `online` field and operation-3 heartbeat are heat;
    // WATCHED_CHANGE is cumulative. Neither is a concurrent head count.
    'bilibili': AudiencePlatformCapability(
      hasPopularity: true,
      hasTotalViewers: true,
      onlineAvailability: AudienceOnlineAvailability.unsupported,
    ),
    'douyu': AudiencePlatformCapability(
      hasPopularity: true,
      hasTotalViewers: false,
      onlineAvailability: AudienceOnlineAvailability.unsupported,
    ),
    // Huya's website URI 8006 calls the field iAttendeeCount, but live captures
    // stay in the same multi-million heat range as totalCount.
    'huya': AudiencePlatformCapability(
      hasPopularity: true,
      hasTotalViewers: false,
      onlineAvailability: AudienceOnlineAvailability.unsupported,
    ),
    'douyin': AudiencePlatformCapability(
      hasPopularity: false,
      hasTotalViewers: true,
      onlineAvailability: AudienceOnlineAvailability.roomList,
    ),
    'kuaishou': AudiencePlatformCapability(
      hasPopularity: false,
      hasTotalViewers: false,
      onlineAvailability: AudienceOnlineAvailability.roomList,
    ),
    'cc': AudiencePlatformCapability(
      hasPopularity: true,
      hasTotalViewers: false,
      onlineAvailability: AudienceOnlineAvailability.roomList,
    ),
    // Twitch GraphQL exposes viewersCount as the concurrent count in directory,
    // search and room metadata responses.
    'twitch': AudiencePlatformCapability(
      hasPopularity: false,
      hasTotalViewers: false,
      onlineAvailability: AudienceOnlineAvailability.roomList,
    ),
    // SOOP lists expose total_view_cnt/view_cnt (PC + mobile concurrent);
    // current_view_cnt alone is PC-only and must not be shown as the audience.
    'soop': AudiencePlatformCapability(
      hasPopularity: false,
      hasTotalViewers: false,
      onlineAvailability: AudienceOnlineAvailability.roomList,
    ),
    // YY's public `users` value follows the platform heat scale and the web API
    // exposes no separate concurrent audience field.
    'yy': AudiencePlatformCapability(
      hasPopularity: true,
      hasTotalViewers: false,
      onlineAvailability: AudienceOnlineAvailability.unsupported,
    ),
    // Picarto's viewers and total_views have distinct concurrent/cumulative
    // meanings.
    'picarto': AudiencePlatformCapability(
      hasPopularity: false,
      hasTotalViewers: true,
      onlineAvailability: AudienceOnlineAvailability.roomList,
    ),
    'twitcasting': AudiencePlatformCapability(
      hasPopularity: false,
      hasTotalViewers: false,
      onlineAvailability: AudienceOnlineAvailability.roomList,
    ),
    // SHOWROOM's view_num is session traffic and is not documented as a
    // concurrent audience. Keep it in the cumulative column.
    'showroom': AudiencePlatformCapability(
      hasPopularity: false,
      hasTotalViewers: true,
      onlineAvailability: AudienceOnlineAvailability.unsupported,
    ),
    // CHZZK exposes concurrentUserCount and separately tells clients whether
    // the value may be shown through cvExposure.
    'chzzk': AudiencePlatformCapability(
      hasPopularity: false,
      hasTotalViewers: false,
      onlineAvailability: AudienceOnlineAvailability.roomList,
    ),
    'kick': AudiencePlatformCapability(
      hasPopularity: false,
      hasTotalViewers: false,
      onlineAvailability: AudienceOnlineAvailability.roomList,
    ),
    'missevan': AudiencePlatformCapability(
      hasPopularity: true,
      hasTotalViewers: false,
      onlineAvailability: AudienceOnlineAvailability.unsupported,
    ),
    // AcFun's onlineCount is independent of likes/followers; author search
    // omits it.
    'acfun': AudiencePlatformCapability(
      hasPopularity: false,
      hasTotalViewers: false,
      onlineAvailability: AudienceOnlineAvailability.roomList,
    ),
    // Niconico publishes cumulative view counts only.
    'niconico': AudiencePlatformCapability(
      hasPopularity: false,
      hasTotalViewers: true,
      onlineAvailability: AudienceOnlineAvailability.unsupported,
    ),
    // The finite public directory exposes user_count for current broadcasts.
    // Room detail has no verified concurrent field and therefore keeps it unknown.
    'bigo': AudiencePlatformCapability(
      hasPopularity: false,
      hasTotalViewers: false,
      onlineAvailability: AudienceOnlineAvailability.roomList,
    ),
    // TikTok LIVE exposes liveRoomStats.userCount as concurrent viewers and
    // enterCount as cumulative room entries; keep those metrics separate.
    'tiktok': AudiencePlatformCapability(
      hasPopularity: false,
      hasTotalViewers: true,
      onlineAvailability: AudienceOnlineAvailability.roomRealtime,
    ),
    // LiveMe exposes platform heat, current playnumber and cumulative
    // watchnumber as separate fields in both its directory and room response.
    'liveme': AudiencePlatformCapability(
      hasPopularity: true,
      hasTotalViewers: true,
      onlineAvailability: AudienceOnlineAvailability.roomList,
    ),
    // PandaTV's `user` value is the concurrent audience in the official
    // directory and play response. `playCnt` remains a separate session value.
    'pandalive': AudiencePlatformCapability(
      hasPopularity: false,
      hasTotalViewers: false,
      onlineAvailability: AudienceOnlineAvailability.roomList,
    ),
    // PopkonTV documents `watchCnt` as the current audience while
    // `totalWatchCnt` is a separate cumulative session counter.
    // The homepage live feed and session detail expose `view_count` and
    // `viewer_count` respectively as the visible current audience metric.
    // VK Video Live exposes `count.viewers` as concurrent viewers and
    // `count.views` as a separate cumulative stream metric.
    // The homepage card and mobile room bootstrap both expose current viewers.
    // The public API identifies live/offline state but exposes no verified
    // concurrent audience value. Historical views are not reused here.
    // Live directory cards expose a dedicated current-viewer badge. The
    // VideoObject interaction count is cumulative and stays in totalViewers.
    // GoodGame's public directory and channel endpoint expose `viewers` as
    // the live audience. Rating and premium counters are separate concepts.
    // FC2 exposes current `count` and cumulative `total` independently in
    // both its public directory and member metadata.
    'fc2live': AudiencePlatformCapability(
      hasPopularity: false,
      hasTotalViewers: true,
      onlineAvailability: AudienceOnlineAvailability.roomList,
    ),
    // Steam community cards and getbroadcastmpd both expose the current
    // concurrent audience independently from the broadcast identity.
    'steambroadcast': AudiencePlatformCapability(
      hasPopularity: false,
      hasTotalViewers: false,
      onlineAvailability: AudienceOnlineAvailability.roomList,
    ),
    // JD labels the public-directory `pv` value as views rather than current
    // concurrency, so it remains a cumulative audience field.
    'jdlive': AudiencePlatformCapability(
      hasPopularity: false,
      hasTotalViewers: true,
      onlineAvailability: AudienceOnlineAvailability.unsupported,
    ),
    // Kugou keeps directory viewerNum/getViewerNum, platform hot and
    // broadcaster fansCount as three independent metrics.
    'kugoulive': AudiencePlatformCapability(
      hasPopularity: true,
      hasTotalViewers: false,
      onlineAvailability: AudienceOnlineAvailability.roomList,
    ),
    // Baidu's PC feed audience_count and room online_users are live audience
    // values. Fan counts stay in the independent follower field.
    'baidulive': AudiencePlatformCapability(
      hasPopularity: false,
      hasTotalViewers: false,
      onlineAvailability: AudienceOnlineAvailability.roomList,
    ),
    // Zhanqi keeps a separate public online count in its room response.
    'zhanqi': AudiencePlatformCapability(
      hasPopularity: false,
      hasTotalViewers: false,
      onlineAvailability: AudienceOnlineAvailability.roomList,
    ),
    // The room detail keeps current liveViewerCount separate from cumulative viewerCount.
    '17live': AudiencePlatformCapability(
      hasPopularity: false,
      hasTotalViewers: true,
      onlineAvailability: AudienceOnlineAvailability.roomRealtime,
    ),
    // LOOK keeps recommendation popularity and onlineNumber as independent
    // values. The latter is the current audience shown on official web cards.
    'looklive': AudiencePlatformCapability(
      hasPopularity: true,
      hasTotalViewers: false,
      onlineAvailability: AudienceOnlineAvailability.roomList,
    ),
    // The watch page exposes a dedicated concurrent-view renderer while a
    // broadcast is live. Historical viewCount is not reused.
    'youtube': AudiencePlatformCapability(
      hasPopularity: false,
      hasTotalViewers: false,
      onlineAvailability: AudienceOnlineAvailability.roomRealtime,
    ),
    // Six Rooms exposes a homepage `count` used by its ranking cards, without
    // a stable public contract proving unique concurrent viewers. Keep it as
    // platform popularity; room fans remain an independent follower metric.
    'sixroom': AudiencePlatformCapability(
      hasPopularity: true,
      hasTotalViewers: false,
      onlineAvailability: AudienceOnlineAvailability.unsupported,
    ),
  };

  static const AudiencePlatformCapability _unknownAudienceCapability = AudiencePlatformCapability(
    hasPopularity: false,
    hasTotalViewers: false,
    onlineAvailability: AudienceOnlineAvailability.unsupported,
  );

  /// Capability for a platform id; unknown platforms expose nothing.
  static AudiencePlatformCapability audienceCapabilityFor(String? platform) =>
      audienceCapabilities[platform?.trim().toLowerCase()] ?? _unknownAudienceCapability;

  static bool _hasAudienceValue(String? value) {
    final text = value?.trim() ?? '';
    return text.isNotEmpty && text != 'null' && parseAudienceNumber(text) > 0;
  }

  static final RegExp _digitPattern = RegExp(r'[0-9]');

  static bool _hasExplicitAudienceValue(String? value) {
    final text = value?.trim() ?? '';
    return text.isNotEmpty && text != 'null' && _digitPattern.hasMatch(text);
  }

  const factory LiveRoom({
    @Default('') String roomId,
    @Default('') String userId,
    @Default('') String link,
    @Default('') String title,
    @Default('') String nick,
    @Default('') String avatar,
    @Default('') String cover,
    @Default('') String area,
    @Default('0') String watching,
    @Default('') String popularity,
    @Default('') String onlineViewers,
    @Default('') String totalViewers,
    @Default('') String followers,
    @Default('UNKNOWN') String platform,
    @Default([]) List<String> tagIds,
    @Default('') String introduction,
    @Default('') String notice,
    @Default(false) bool status,
    @Default(false) bool isRecord,
    @Default(LiveStatus.offline) LiveStatus liveStatus,
    @Default(AudienceMetricType.unknown) AudienceMetricType audienceMetricType,
    String? catchUpUrl,
    @Default(false) bool isCatchUp,
    int? catchUpStart,
    int? catchUpEnd,
    // ---------- IPTV timeshift and catch-up metadata (M3U catchup-* tags) ----------
    String? catchUpMode,
    String? catchUpSource,
    double? catchUpDays,
    double? catchUpCorrectionHours,
    @Default(<String, String>{}) Map<String, String> httpHeaders,
    @JsonKey(includeFromJson: false, includeToJson: false) dynamic data,
    @JsonKey(includeFromJson: false, includeToJson: false) dynamic danmakuData,
  }) = _LiveRoom;

  factory LiveRoom.fromJson(Map<String, dynamic> json) =>
      _$LiveRoomFromJson({...json, 'liveStatus': _normalizeLiveStatus(json['liveStatus'])});

  /// The phone app (and older builds) write `liveStatus` as an int; freezed's
  /// `@JsonEnum` only accepts the names. Both forms land on the same enum.
  static Object? _normalizeLiveStatus(Object? value) {
    if (value is String) return value; // 已经是 'live' / 'offline' / ...
    if (value is int) {
      return switch (value) {
        0 => 'offline',
        1 => 'live',
        2 => 'replay',
        3 => 'banned',
        _ => 'unknown',
      };
    }
    return 'unknown';
  }

  // ---------- Identity ----------

  String get normalizedPlatformId => platform.trim().toLowerCase();

  String get normalizedRoomId => roomId.trim();

  /// Stable platform plus room-id key, used to deduplicate favourites and history.
  String get identityKey => '$normalizedPlatformId:$normalizedRoomId';

  bool hasIdentity({required String platform, required String roomId}) =>
      normalizedPlatformId == platform.trim().toLowerCase() && normalizedRoomId == roomId.trim();

  bool hasSameIdentity(LiveRoom other) => identityKey == other.identityKey;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is _LiveRoom && other.runtimeType == runtimeType && other.platform == platform && other.roomId == roomId);

  @override
  int get hashCode => Object.hash(platform, roomId);

  // ---------- Playback state ----------

  bool get isLiveNow => liveStatus == LiveStatus.live || (liveStatus == LiveStatus.unknown && status);

  bool get isExplicitlyOfflineNow => liveStatus == LiveStatus.offline || liveStatus == LiveStatus.banned;

  /// Replays and timeshift are playable too.
  bool get isPlayableNow => isLiveNow || liveStatus == LiveStatus.replay || isRecord;

  LiveStatus get effectiveLiveStatus =>
      liveStatus == LiveStatus.unknown ? (status ? LiveStatus.live : LiveStatus.offline) : liveStatus;

  /// Whether the room carries anything a viewer could identify it by.
  ///
  /// A room built from a platform id alone (the hint a route carries) and the
  /// shell a platform returns when its detail request fails both have none: the
  /// avatar is deliberately not counted, because several sites hand out a
  /// default one to rooms they know nothing about.
  bool get hasMetadata =>
      title.trim().isNotEmpty ||
      nick.trim().isNotEmpty ||
      cover.trim().isNotEmpty ||
      area.trim().isNotEmpty ||
      introduction.trim().isNotEmpty ||
      notice.trim().isNotEmpty;

  /// Whether this room is the shell a platform builds when its detail request
  /// failed: the reason sits in [data] and nothing usable took its place.
  ///
  /// [getLiveRoomWithError] is the only producer - it keeps the last known
  /// identity and metadata, and records the failure where the playback layer
  /// reads it. A room that still carries a payload from an earlier response is
  /// not a failure shell: there is something to play with.
  bool get isDetailFailureShell => data is Exception;

  /// One line naming this room: title, else streamer, else room id.
  ///
  /// Used where the room has to be identified before its title is known. An
  /// error screen that cannot say which room failed is no help at all.
  String get displayTitle {
    for (final String candidate in <String>[title, nick, roomId]) {
      final String value = candidate.trim();
      if (value.isNotEmpty) return value;
    }

    return i18n('untitled_room');
  }

  // ---------- Audience values ----------

  /// Parses audience text with 10^4/10^8 unit suffixes or comma separators.
  static int parseAudienceNumber(String? text) {
    if (text == null) return 0;
    var cleaned = text.trim().replaceAll(',', '');
    if (cleaned.isEmpty) return 0;
    double multiplier = 1;
    // The suffix comes from the platform response, not from the UI language,
    // so it must be matched literally. Looking it up through i18n returned the
    // key itself under a non-Chinese locale, which silently dropped the
    // multiplier and reported zero viewers.
    if (cleaned.endsWith('万')) {
      multiplier = 10000;
      cleaned = cleaned.substring(0, cleaned.length - 1);
    } else if (cleaned.endsWith('亿')) {
      multiplier = 100000000;
      cleaned = cleaned.substring(0, cleaned.length - 1);
    } else if (cleaned.endsWith('w') || cleaned.endsWith('W')) {
      multiplier = 10000;
      cleaned = cleaned.substring(0, cleaned.length - 1);
    }
    final value = double.tryParse(cleaned);
    if (value == null) return 0;
    return (value * multiplier).round();
  }

  /// Audience fields this platform publishes, independent of whether this room
  /// already received its first list value or realtime heartbeat.
  AudiencePlatformCapability get audienceCapability => audienceCapabilityFor(platform);

  /// Whether this platform can ever report a concurrent audience number.
  bool get supportsRealOnlineCount => audienceCapability.supportsConcurrentOnline;

  /// Whether an explicit concurrent count has already arrived for this room.
  bool get hasRealOnlineCount => _hasExplicitAudienceValue(effectiveOnlineViewers);

  /// Concurrent viewers, falling back to the legacy single audience field when
  /// the site marks that field as the concurrent metric.
  String get effectiveOnlineViewers {
    if (_hasExplicitAudienceValue(onlineViewers)) return onlineViewers.trim();
    // `watching` keeps the legacy "0" sentinel; only a positive legacy value is
    // treated as a concurrent count, while a platform that genuinely reports
    // zero writes it to [onlineViewers] and stays valid.
    return effectiveAudienceMetricType == AudienceMetricType.onlineViewers && _hasAudienceValue(watching)
        ? watching.trim()
        : '';
  }

  /// Platform heat, falling back to the legacy audience field when the site
  /// marks that field as heat.
  String get effectivePopularity {
    if (_hasAudienceValue(popularity)) return popularity.trim();
    return effectiveAudienceMetricType == AudienceMetricType.popularity ? watching.trim() : '';
  }

  /// Cumulative viewers, falling back to the legacy audience field when the
  /// site marks that field as cumulative.
  String get effectiveTotalViewers {
    if (_hasAudienceValue(totalViewers)) return totalViewers.trim();
    return effectiveAudienceMetricType == AudienceMetricType.totalViewers ? watching.trim() : '';
  }

  /// Metric this room ranks by when the site did not tag the value itself.
  AudienceMetricType get effectiveAudienceMetricType {
    if (audienceMetricType != AudienceMetricType.unknown) return audienceMetricType;
    return switch (normalizedPlatformId) {
      'bilibili' || 'douyu' || 'huya' || 'cc' || 'yy' || 'missevan' => AudienceMetricType.popularity,
      'kuaishou' || 'twitch' || 'soop' => AudienceMetricType.onlineViewers,
      'douyin' => AudienceMetricType.totalViewers,
      _ => AudienceMetricType.unknown,
    };
  }

  /// i18n key describing [effectiveAudienceMetricType].
  String get audienceMetricI18nKey => switch (effectiveAudienceMetricType) {
    AudienceMetricType.popularity => 'audience_popularity',
    AudienceMetricType.onlineViewers => 'audience_online',
    AudienceMetricType.totalViewers => 'audience_total',
    AudienceMetricType.followers => 'audience_followers',
    AudienceMetricType.watching => 'audience_count',
    AudienceMetricType.unknown => 'audience_count',
  };

  /// Audience text to display under the current display policy.
  ///
  /// Concurrent mode only wins for a platform that really publishes the count
  /// and that the user enabled; otherwise the platform's native metric is used.
  String audienceValue({required bool preferRealOnline, required bool platformEnabled}) {
    if (preferRealOnline && platformEnabled && supportsRealOnlineCount) {
      return hasRealOnlineCount ? effectiveOnlineViewers : '';
    }
    if (_hasAudienceValue(effectivePopularity)) return effectivePopularity;
    if (_hasAudienceValue(effectiveTotalViewers)) return effectiveTotalViewers;
    if (hasRealOnlineCount) return effectiveOnlineViewers;
    final legacy = watching.trim();
    // The legacy default "0" is not a measurement. Unknown-metric adapters
    // must not render it as a verified audience count.
    if (effectiveAudienceMetricType == AudienceMetricType.unknown && !_hasAudienceValue(legacy)) return '';
    return legacy;
  }

  /// Metric type behind [audienceValue], used to label the displayed number.
  AudienceMetricType audienceType({required bool preferRealOnline, required bool platformEnabled}) {
    if (preferRealOnline && platformEnabled && supportsRealOnlineCount) return AudienceMetricType.onlineViewers;
    if (_hasAudienceValue(effectivePopularity)) return AudienceMetricType.popularity;
    if (_hasAudienceValue(effectiveTotalViewers)) return AudienceMetricType.totalViewers;
    if (hasRealOnlineCount) return AudienceMetricType.onlineViewers;
    return effectiveAudienceMetricType;
  }

  /// Ranking tier and value for the current display policy.
  AudienceRankKey audienceRankKey({required bool preferRealOnline, required bool platformEnabled}) {
    if (preferRealOnline && platformEnabled && supportsRealOnlineCount) {
      return AudienceRankKey(
        metricPriority: hasRealOnlineCount ? 3 : 2,
        value: hasRealOnlineCount ? parseAudienceNumber(effectiveOnlineViewers) : 0,
      );
    }

    final nativeValue = audienceValue(preferRealOnline: false, platformEnabled: false);
    return AudienceRankKey(
      metricPriority: _hasExplicitAudienceValue(nativeValue) ? 1 : 0,
      value: parseAudienceNumber(nativeValue),
    );
  }

  /// Ranking value with the platform's own metric, ignoring display policy.
  int get audienceRankingValue {
    final candidate = switch (audienceMetricType) {
      AudienceMetricType.onlineViewers => onlineViewers,
      AudienceMetricType.watching => watching,
      AudienceMetricType.totalViewers => totalViewers,
      AudienceMetricType.popularity => popularity,
      AudienceMetricType.followers => followers,
      AudienceMetricType.unknown => watching,
    };
    final parsed = parseAudienceNumber(candidate);
    if (parsed > 0) return parsed;
    return parseAudienceNumber(watching) + parseAudienceNumber(onlineViewers) + parseAudienceNumber(popularity);
  }

  /// Fills audience fields that a room-detail response omitted, so the header
  /// does not flicker back to zero after a list value was already shown.
  LiveRoom withAudienceFallbackFrom(LiveRoom other) {
    if (identical(this, other)) return this;
    var result = this;
    String pick(String mine, String theirs) => mine.trim().isEmpty ? theirs : mine;
    if (watching.trim().isEmpty && other.watching.trim().isNotEmpty) {
      result = result.copyWith(watching: other.watching);
    }
    if (popularity.trim().isEmpty && other.popularity.trim().isNotEmpty) {
      result = result.copyWith(popularity: pick(popularity, other.popularity));
    }
    if (onlineViewers.trim().isEmpty && other.onlineViewers.trim().isNotEmpty) {
      result = result.copyWith(onlineViewers: pick(onlineViewers, other.onlineViewers));
    }
    if (totalViewers.trim().isEmpty && other.totalViewers.trim().isNotEmpty) {
      result = result.copyWith(totalViewers: pick(totalViewers, other.totalViewers));
    }
    if (audienceMetricType == AudienceMetricType.unknown && other.audienceMetricType != AudienceMetricType.unknown) {
      result = result.copyWith(audienceMetricType: other.audienceMetricType);
    }
    return result;
  }

  /// Merges [fresh] over this room, field by field: a value [fresh] carries wins,
  /// and this room fills whatever [fresh] left blank. In one line — the newer
  /// information replaces the older, and a value replaces an empty one.
  ///
  /// Two things are deliberately outside the merge:
  ///
  /// * **Identity** (`roomId`, `platform`): a card is stored, tagged and looked
  ///   up under the id it was followed with, and platforms answer with their
  ///   canonical id, which can differ (Douyin reports its web rid). The caller
  ///   decides which id survives.
  /// * **The runtime payload** ([data], [danmakuData]): those belong to a
  ///   playback session. A stored room is not one, and a card read back from
  ///   settings must not carry them.
  ///
  /// Playback state (`status`, `liveStatus`, `isRecord`, the audience metric)
  /// always follows [fresh]: there is no empty value to protect there, and
  /// correcting it is the whole point of a refresh.
  LiveRoom withRefreshFrom(LiveRoom fresh) {
    if (identical(this, fresh)) return this;

    /// [value] when it says anything, this room's own otherwise.
    String keepIfEmpty(String value, String fallback) => value.trim().isEmpty ? fallback : value;

    // The legacy audience field keeps "0" as "unknown" (see [_hasAudienceValue]).
    String keepAudienceIfEmpty(String value, String fallback) => _hasAudienceValue(value) ? value : fallback;

    return copyWith(
      userId: keepIfEmpty(fresh.userId, userId),
      link: keepIfEmpty(fresh.link, link),
      title: keepIfEmpty(fresh.title, title),
      nick: keepIfEmpty(fresh.nick, nick),
      avatar: keepIfEmpty(fresh.avatar, avatar),
      cover: keepIfEmpty(fresh.cover, cover),
      area: keepIfEmpty(fresh.area, area),
      watching: keepAudienceIfEmpty(fresh.watching, watching),
      popularity: keepIfEmpty(fresh.popularity, popularity),
      onlineViewers: keepIfEmpty(fresh.onlineViewers, onlineViewers),
      totalViewers: keepIfEmpty(fresh.totalViewers, totalViewers),
      followers: keepIfEmpty(fresh.followers, followers),
      tagIds: fresh.tagIds.isEmpty ? tagIds : fresh.tagIds,
      introduction: keepIfEmpty(fresh.introduction, introduction),
      notice: keepIfEmpty(fresh.notice, notice),
      status: fresh.status,
      isRecord: fresh.isRecord,
      liveStatus: fresh.liveStatus,
      audienceMetricType: fresh.audienceMetricType == AudienceMetricType.unknown
          ? audienceMetricType
          : fresh.audienceMetricType,
      catchUpUrl: fresh.catchUpUrl ?? catchUpUrl,
      catchUpStart: fresh.catchUpStart ?? catchUpStart,
      catchUpEnd: fresh.catchUpEnd ?? catchUpEnd,
      catchUpMode: fresh.catchUpMode ?? catchUpMode,
      catchUpSource: fresh.catchUpSource ?? catchUpSource,
      catchUpDays: fresh.catchUpDays ?? catchUpDays,
      catchUpCorrectionHours: fresh.catchUpCorrectionHours ?? catchUpCorrectionHours,
      httpHeaders: fresh.httpHeaders.isEmpty ? httpHeaders : fresh.httpHeaders,
    );
  }

  /// Drops the playback-session payload, leaving a room that is safe to keep in
  /// settings: [data] and [danmakuData] are runtime objects (a line model, a
  /// socket's connection arguments), they are excluded from the stored JSON, and
  /// nothing should hold on to them once the session that produced them is over.
  LiveRoom withoutRuntimePayload() =>
      data == null && danmakuData == null ? this : copyWith(data: null, danmakuData: null);

  /// Fills what a room-detail response left blank from [hint] — the room the
  /// viewer entered with.
  ///
  /// The response wins wherever it has a value, exactly as in
  /// [withRefreshFrom]. A response with no metadata at all is not a statement
  /// about the broadcast: it is either the shell a platform builds when its
  /// detail request failed, or a room reconstructed from an id, and both default
  /// to `offline`. Taking those defaults at face value reported a live room as
  /// ended and wiped the very card the viewer had just tapped, so the hint —
  /// playback state included — is taken over whole.
  LiveRoom withHintFallbackFrom(LiveRoom? hint) {
    if (hint == null || identical(this, hint) || !hint.hasMetadata) return this;

    // The payload stays with the answer. [data] is the platform's own handle on
    // this room's stream, and one carried over from the hint - a list snapshot, or
    // the line model of an earlier session - would send playback at expired URLs
    // and hide the failed lookup the answer is reporting. The danmaku arguments
    // are neither signed nor session-bound, so those are safe to fill in: a
    // platform that only publishes them in its list responses would otherwise
    // open the room without a danmaku connection.
    final dynamic danmaku = danmakuData ?? hint.danmakuData;

    // Nothing to show here: the hint is the room, only the identity the caller
    // asked for is kept (a platform may answer with a different canonical id).
    if (!hasMetadata) {
      return hint.copyWith(roomId: roomId, platform: platform, data: data, danmakuData: danmaku);
    }

    // The hint is the base and this answer wins wherever it has a value - the
    // other way round from [withRefreshFrom]'s usual caller, where the receiver
    // is the older card. The identity stays this answer's, and so does the
    // payload ([withRefreshFrom] leaves both alone).
    return hint.withRefreshFrom(this).copyWith(roomId: roomId, platform: platform, data: data, danmakuData: danmaku);
  }

  /// Sorts two rooms by the selected metric policy and then by stable room
  /// identity, so equal or still-pending values keep a fixed order.
  static int compareAudienceRanking(
    LiveRoom a,
    LiveRoom b, {
    bool preferRealOnline = true,
    bool Function(String platform)? platformEnabled,
  }) {
    AudienceRankKey keyOf(LiveRoom room) => room.audienceRankKey(
      preferRealOnline: preferRealOnline,
      platformEnabled: platformEnabled?.call(room.normalizedPlatformId) ?? true,
    );

    final left = keyOf(a);
    final right = keyOf(b);
    final metricOrder = right.metricPriority.compareTo(left.metricPriority);
    if (metricOrder != 0) return metricOrder;
    final valueOrder = right.value.compareTo(left.value);
    if (valueOrder != 0) return valueOrder;
    return a.identityKey.compareTo(b.identityKey);
  }

  // ---------- Error fallback ----------

  /// Showable room built when the detail fetch fails: existing fields are kept
  /// and the room is left pending. The error message goes into [data] for the
  /// playback layer to read.
  LiveRoom getLiveRoomWithError({Object? error}) {
    // A failed detail request is not evidence that a broadcast ended. Keep the
    // last known identity/metadata, but make playback status pending, and drop
    // the legacy "0" audience sentinel for the same reason.
    return copyWith(
      liveStatus: isExplicitlyOfflineNow ? liveStatus : LiveStatus.unknown,
      watching: watching.trim() == '0' ? '' : watching,
      data: error ?? data ?? Exception(i18n('room_info_load_failed')),
    );
  }
}
