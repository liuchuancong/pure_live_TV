import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:pure_live/player/core/live_room_volume_manager.dart';

part 'live_room.freezed.dart';
part 'live_room.g.dart';

enum LiveStatus { live, offline, replay, unknown, banned }

/// 观众数值的来源类型，用于排序时决定可比性。
enum AudienceMetricType { unknown, watching, popularity, onlineViewers, totalViewers, followers }

extension AudienceMetricTypeRank on AudienceMetricType {
  /// 排序权重：真实在线人数 > 总观看 > 热度 > 关注数。
  int get rankingRank => switch (this) {
    AudienceMetricType.onlineViewers => 4,
    AudienceMetricType.watching => 3,
    AudienceMetricType.totalViewers => 2,
    AudienceMetricType.popularity => 1,
    AudienceMetricType.followers => 1,
    AudienceMetricType.unknown => 0,
  };
}

@freezed
abstract class LiveRoom with _$LiveRoom {
  const LiveRoom._();

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
    @Default('') String epgId,
    @Default('') String currentProgramme,
    @Default('') String currentProgrammeDescription,
    String? catchUpUrl,
    @Default(false) bool isCatchUp,
    int? catchUpStart,
    int? catchUpEnd,
    // ---------- IPTV 时移/回看元数据（来自 M3U catchup-* 标签） ----------
    String? catchUpMode,
    String? catchUpSource,
    double? catchUpDays,
    double? catchUpCorrectionHours,
    @Default(<String, String>{}) Map<String, String> httpHeaders,
    @JsonKey(includeFromJson: false, includeToJson: false) dynamic data,
    @JsonKey(includeFromJson: false, includeToJson: false) dynamic danmakuData,
  }) = _LiveRoom;

  factory LiveRoom.fromJson(Map<String, dynamic> json) => _$LiveRoomFromJson(json);

  // ---------- 身份 ----------

  String get normalizedPlatformId => platform.trim().toLowerCase();

  String get normalizedRoomId => roomId.trim();

  /// 平台 + 房间号的稳定标识，用于收藏/历史去重。
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

  // ---------- 播放状态 ----------

  bool get isLiveNow => liveStatus == LiveStatus.live || (liveStatus == LiveStatus.unknown && status);

  bool get isExplicitlyOfflineNow => liveStatus == LiveStatus.offline || liveStatus == LiveStatus.banned;

  /// 回放/时移同样可播放。
  bool get isPlayableNow => isLiveNow || liveStatus == LiveStatus.replay || isRecord;

  LiveStatus get effectiveLiveStatus => liveStatus == LiveStatus.unknown
      ? (status ? LiveStatus.live : LiveStatus.offline)
      : liveStatus;

  // ---------- 观众数值 ----------

  /// 解析 "1.2万"、"3,456"、"12亿" 之类的观众数文本。
  static int parseAudienceNumber(String? text) {
    if (text == null) return 0;
    var cleaned = text.trim().replaceAll(',', '');
    if (cleaned.isEmpty) return 0;
    double multiplier = 1;
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

  /// 当前排序使用的观众数值。
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

  /// 观众字段为空时，用旧房间的数据兜底（详情接口偶尔缺人数时保持展示稳定）。
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

  /// 按观众数值降序比较；优先真实在线人数，其次按指标权重。
  static int compareAudienceRanking(
    LiveRoom a,
    LiveRoom b, {
    bool preferRealOnline = true,
    bool Function(String platform)? platformEnabled,
  }) {
    int valueOf(LiveRoom room) {
      if (platformEnabled != null && !platformEnabled(room.normalizedPlatformId)) return 0;
      if (preferRealOnline) {
        final online = parseAudienceNumber(room.onlineViewers) > 0
            ? parseAudienceNumber(room.onlineViewers)
            : parseAudienceNumber(room.watching);
        if (online > 0) return online;
      }
      return room.audienceRankingValue;
    }

    final diff = valueOf(b) - valueOf(a);
    if (diff != 0) return diff;
    return a.identityKey.compareTo(b.identityKey);
  }

  // ---------- 音量记忆 ----------

  double getSavedVolume() => LiveRoomVolumeManager.getRoomVolume(platform, roomId);

  Future<void> saveCurrentVolume(double volume) => LiveRoomVolumeManager.saveRoomVolume(platform, roomId, volume);

  // ---------- 错误回退 ----------

  /// 详情拉取失败时构造的可展示房间：保留已有信息并标记为离线，
  /// 错误消息放在 [data] 中由播放层读取。
  LiveRoom getLiveRoomWithError({Object? error}) {
    return copyWith(
      liveStatus: isExplicitlyOfflineNow ? liveStatus : LiveStatus.offline,
      data: error ?? data ?? Exception('房间信息加载失败'),
    );
  }
}
