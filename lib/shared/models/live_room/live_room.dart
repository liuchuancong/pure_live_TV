import 'package:pure_live/shared/i18n/locale_helper.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:pure_live/player/core/live_room_volume_manager.dart';

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
    'openrec': AudiencePlatformCapability(
      hasPopularity: false,
      hasTotalViewers: false,
      onlineAvailability: AudienceOnlineAvailability.roomList,
    ),
    'ttinglive': AudiencePlatformCapability(
      hasPopularity: false,
      hasTotalViewers: false,
      onlineAvailability: AudienceOnlineAvailability.roomList,
    ),
    'huajiao': AudiencePlatformCapability(
      hasPopularity: true,
      hasTotalViewers: false,
      onlineAvailability: AudienceOnlineAvailability.unsupported,
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
    // The watch page exposes a dedicated concurrent-view renderer while a
    // broadcast is live. Historical viewCount is deliberately not reused.
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
    return watching.trim();
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

  // ---------- Remembered volume ----------

  double getSavedVolume() => LiveRoomVolumeManager.getRoomVolume(platform, roomId);

  Future<void> saveCurrentVolume(double volume) => LiveRoomVolumeManager.saveRoomVolume(platform, roomId, volume);

  // ---------- Error fallback ----------

  /// Showable room built when the detail fetch fails: existing fields are kept
  /// and the room is marked offline. The error message goes into [data] for the
  /// playback layer to read.
  LiveRoom getLiveRoomWithError({Object? error}) {
    return copyWith(
      liveStatus: isExplicitlyOfflineNow ? liveStatus : LiveStatus.offline,
      data: error ?? data ?? Exception(i18n('room_info_load_failed')),
    );
  }
}
