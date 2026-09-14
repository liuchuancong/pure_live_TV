import 'package:pure_live/exports/exports.dart';


class TtingSite extends LiveSite
    implements
        LiveSiteDirectoryPager,
        LiveDirectoryNotice,
        LiveSiteRoomRefresher,
        LiveSiteRecordRoomResolver,
        LivePlayUrlResolver,
        LivePlayRecoveryResolver,
        LivePlayLeaseMetadata {
  TtingSite({TtingApi? api, DateTime Function()? now}) : _api = api ?? TtingApi(now: now), _now = now ?? DateTime.now;
  final TtingApi _api;
  final DateTime Function() _now;
  @override
  String get id => 'ttinglive';
  @override
  String get name => 'FLEX TV (TTingLive)';
  @override
  String get directoryNoticeKey => 'tting_directory_scope';
  @override
  LiveDanmaku getDanmaku() => EmptyDanmaku();

  int _channelId(String roomId, String platform) {
    if (platform != id || !RegExp(r'^[1-9][0-9]{0,15}$').hasMatch(roomId)) {
      throw const TtingException(TtingFailure.identity);
    }
    return TtingApi.positiveId(int.parse(roomId));
  }

  LiveRoom _owner(TtingChannel channel) => LiveRoom(
    platform: id,
    roomId: '${channel.id}',
    userId: '${channel.ownerId}',
    nick: channel.nickname,
    title: channel.name,
    avatar: channel.avatar,
    cover: channel.avatar,
    link: TtingLink.url(channel.id),
    liveStatus: channel.isLive ? LiveStatus.live : LiveStatus.offline,
    notice: channel.restricted ? i18n('tting_restricted') : '',
  );

  @override
  Future<LiveDirectoryPage> getDirectoryPage({int page = 1, LiveArea? category, CancelToken? cancel}) async {
    if (page < 1 ||
        (category != null &&
            (category.platform != id || category.areaId != 'live' || category.areaType != 'directory'))) {
      throw const TtingException(TtingFailure.schema);
    }
    if (page > 1) return LiveDirectoryPage(page: page, rooms: const [], hasMore: false);
    final cards = await _api.directory(cancel: cancel);
    return LiveDirectoryPage(
      page: page,
      hasMore: false,
      rooms: [
        for (final card in cards)
          LiveRoom(
            platform: id,
            roomId: '${card.id}',
            title: card.title,
            nick: card.nickname,
            cover: card.cover,
            avatar: card.avatar,
            link: TtingLink.url(card.id),
            liveStatus: LiveStatus.live,
            onlineViewers: card.viewers?.toString() ?? '',
            audienceMetricType: AudienceMetricType.onlineViewers,
          ),
      ],
    );
  }

  @override
  Future<List<LiveRoom>> getRecommendRooms({int page = 1, int pageSize = 30}) async =>
      (await getDirectoryPage(page: page)).rooms;
  @override
  Future<List<LiveRoom>> getCategoryRooms(LiveArea category, {int page = 1, int pageSize = 30}) async =>
      (await getDirectoryPage(page: page, category: category)).rooms;
  @override
  Future<List<LiveCategory>> getCategores(int page, int pageSize) async => page == 1
      ? [
          LiveCategory(
            id: id,
            name: name,
            children: [
              LiveArea(
                platform: id,
                areaType: 'directory',
                areaId: 'live',
                areaName: i18n('tting_public_directory'),
                typeName: name,
              ),
            ],
          ),
        ]
      : [];

  @override
  Future<LiveRoom> getRoomDetail({required String roomId, required String platform}) async {
    final result = await _api.room(_channelId(roomId, platform));
    final room = _owner(result.channel);
    final broadcast = result.broadcast;
    if (broadcast != null) {
      return room.copyWith(title: broadcast.title, cover: broadcast.cover, data: broadcast);
    }
    return room;
  }

  @override
  Future<LiveRoom> getRoomDetailForRecording({required String roomId, required String platform}) =>
      getRoomDetail(roomId: roomId, platform: platform);
  @override
  Future<LiveRoom> getRoomDetailForRefresh({required String roomId, required String platform}) async =>
      _owner(await _api.channel(_channelId(roomId, platform)));
  @override
  Future<bool> getLiveStatus({required String roomId, required String platform}) async =>
      (await getRoomDetailForRefresh(roomId: roomId, platform: platform)).isLiveNow;
  @override
  Future<List<LiveRoom>> searchRooms(String keyword, {int page = 1, int pageSize = 30}) async {
    if (page != 1) return [];
    final channel = TtingLink.parse(keyword);
    if (channel == null) return [];
    try {
      return [_owner(await _api.channel(channel))];
    } on TtingException catch (error) {
      if (error.kind == TtingFailure.missing) return [];
      rethrow;
    }
  }

  TtingBroadcast _broadcast(LiveRoom detail) {
    final channel = _channelId(detail.roomId ?? '', detail.platform ?? '');
    final data = detail.data;
    if (data is! TtingBroadcast || !detail.isLiveNow) throw const TtingException(TtingFailure.mediaUnavailable);
    if (data.channel.id != channel || detail.userId != '${data.channel.ownerId}') {
      throw const TtingException(TtingFailure.identity);
    }
    return data;
  }

  LivePlayQuality _quality(TtingSource source) => LivePlayQuality(
    id: source.resolution,
    quality:
        '${source.resolution == 0 ? i18n('tting_auto') : '${source.resolution}p'} · ${source.family == 'ncp_llh' ? 'LL-HLS' : 'HLS'}',
    sort: source.resolution,
  );
  @override
  Future<List<LivePlayQuality>> getPlayQualites({required LiveRoom detail}) async {
    _channelId(detail.roomId ?? '', detail.platform ?? '');
    if (detail.isExplicitlyOfflineNow) return [];
    return List.unmodifiable(_broadcast(detail).sources.map(_quality));
  }

  Future<LivePlayUrlResolution> _resolve(LiveRoom detail, LivePlayQuality quality, {required bool refresh}) async {
    var data = _broadcast(detail);
    if (refresh || data.sources.any((s) => !s.expiresAt.isAfter(_now().toUtc()))) {
      final fresh = await getRoomDetail(roomId: detail.roomId!, platform: id);
      if (!fresh.isLiveNow) throw const TtingException(TtingFailure.notLive);
      data = _broadcast(fresh);
      if ('${data.channel.ownerId}' != detail.userId) throw const TtingException(TtingFailure.identity);
    }
    final matching = data.sources
        .where((source) => source.resolution.toString() == quality.selectionId.toString())
        .toList();
    if (matching.length != 1) throw const TtingException(TtingFailure.mediaUnavailable);
    final source = matching.single;
    return LivePlayUrlResolution.withSourcePolicies(
      urls: [source.url],
      sourceQueryPolicies: {source.url: source.policy},
      appliedQualityData: source.resolution,
    );
  }

  @override
  Future<LivePlayUrlResolution> resolvePlayUrlsRaw({required LiveRoom detail, required LivePlayQuality quality}) =>
      _resolve(detail, quality, refresh: false);
  @override
  Future<LivePlayUrlResolution> resolvePlayUrlsForRecoveryRaw({
    required LiveRoom detail,
    required LivePlayQuality quality,
  }) => _resolve(detail, quality, refresh: true);
  @override
  Future<List<String>> getPlayUrls({required LiveRoom detail, required LivePlayQuality quality}) async =>
      (await resolvePlayUrlsRaw(detail: detail, quality: quality)).urls;
  @override
  DateTime? getPlayUrlInvalidAt(String url, {DateTime? now}) {
    try {
      final uri = Uri.parse(url);
      if (uri.scheme != 'https' ||
          !uri.host.endsWith('.edge.naverncp.com') ||
          uri.userInfo.isNotEmpty ||
          uri.port != 443 ||
          uri.hasFragment ||
          !uri.path.endsWith('.m3u8')) {
        return null;
      }
      final tokens = uri.queryParametersAll['token'];
      if (tokens == null || tokens.length != 1) return null;
      final fields = tokens.single.split('~').where((s) => s.startsWith('exp=')).toList();
      if (fields.length != 1 || !RegExp(r'^exp=[0-9]{1,10}$').hasMatch(fields.single)) return null;
      return DateTime.fromMillisecondsSinceEpoch(int.parse(fields.single.substring(4)) * 1000, isUtc: true);
    } catch (_) {
      return null;
    }
  }

  @override
  DateTime? getPlayUrlRefreshAt(String url, {DateTime? now}) =>
      getPlayUrlInvalidAt(url)?.subtract(const Duration(seconds: 30));
}
