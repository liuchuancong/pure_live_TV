import 'package:pure_live/exports/exports.dart';
import 'package:pure_live/features/iptv/data/database.dart';

class IptvSite implements LiveSite, LiveSiteRecordRoomResolver {
  @override
  String id = Sites.iptvSite;

  @override
  String name = i18n('network');

  String defaultAvatar =
      "https://img95.699pic.com/xsj/0q/x6/7p.jpg%21/fw/700/watermark/url/L3hzai93YXRlcl9kZXRhaWwyLnBuZw/align/southeast";

  /// The subtitle a channel card shows: the group the channel was filed under,
  /// which is the source label a TV viewer expects, or the playlist's own name
  /// when it ships no groups so the line is never blank.
  static String _sourceLabel(String? group, String fallback) {
    final value = group?.trim() ?? '';
    return value.isEmpty ? fallback : value;
  }

  /// Provider display names by id. The system hot list is imported from a file
  /// called `hot`, which is not a name a viewer should read on a card.
  Future<Map<String, String>> _providerNames() async {
    final providers = await DbService.to.db.getAllProviders();
    return {
      for (final provider in providers)
        provider.id: provider.id == FileUtils.systemHotProviderId || provider.name == 'hot'
            ? i18n('hot')
            : provider.name,
    };
  }

  /// Global IPTV request headers under the channel's own directives: a channel
  /// that carries its own UA/Referer/Cookie keeps them; a channel with none
  /// still plays with the configured ones instead of bare defaults.
  static Map<String, String> _channelHeaders(Map<String, String>? channelHeaders) {
    final settings = SettingsService.to.iptvState;
    final customUa = settings.customIptvUserAgent.trim();
    final referer = settings.customIptvReferer.trim();
    final cookie = settings.customIptvCookie.trim();
    return Map.unmodifiable(<String, String>{
      if (customUa.isNotEmpty) 'user-agent': customUa,
      if (referer.isNotEmpty) 'referer': referer,
      if (cookie.isNotEmpty) 'cookie': cookie,
      ...?channelHeaders,
    });
  }

  @override
  Future<List<LiveCategory>> getCategores(int page, int pageSize) async {
    final db = DbService.to.db;
    final providers = await db.getAllProviders();

    // One query for every visible channel, then group in memory: issuing a query
    // per provider scales badly once several playlists are installed.
    final channelsByProvider = <String, List<Channel>>{};
    for (final channel in await db.getAllVisibleChannels()) {
      (channelsByProvider[channel.providerId] ??= []).add(channel);
    }

    final categoryTypes = <LiveCategory>[];
    for (final provider in providers) {
      if (provider.id == FileUtils.systemHotProviderId || provider.name == 'hot') {
        continue;
      }
      final channels = channelsByProvider[provider.id];
      if (channels == null || channels.isEmpty) continue;
      categoryTypes.add(
        LiveCategory(
          id: provider.id,
          name: provider.name,
          children: [
            for (final ch in channels)
              LiveArea(
                areaId: ch.id,
                areaName: ch.name,
                areaPic: ch.tvgLogo ?? '',
                typeName: provider.name,
                areaType: provider.id,
                platform: Sites.iptvSite,
              ),
          ],
        ),
      );
    }
    return categoryTypes;
  }

  // =========================================================
  // Channels inside a category.
  // =========================================================

  @override
  Future<List<LiveRoom>> getCategoryRooms(LiveArea category, {int page = 1, int pageSize = 30}) async {
    final db = DbService.to.db;
    final items = <LiveRoom>[];

    final ch = await db.getChannelById(category.areaId);
    if (ch == null) return [];

    items.add(
      LiveRoom(
        roomId: ch.id,
        title: ch.name,
        nick: _sourceLabel(ch.groupTitle, category.typeName),
        cover: ch.tvgLogo ?? '',
        area: ch.groupTitle ?? '',
        watching: '',
        avatar: defaultAvatar,
        status: true,
        liveStatus: LiveStatus.live,
        platform: Sites.iptvSite,
        link: ch.streamUrl,
        data: ch.streamUrl,
        catchUpMode: ch.catchupMode,
        catchUpSource: ch.catchupSource,
        catchUpDays: ch.catchupDays,
        catchUpCorrectionHours: ch.catchupCorrectionHours,
        httpHeaders: _channelHeaders(HttpHeaderPolicy.decode(ch.httpHeadersJson)),
      ),
    );

    return items;
  }

  // =========================================================
  // Room details.
  // =========================================================

  @override
  Future<LiveRoom> getRoomDetail({required String platform, required String roomId}) async {
    final db = DbService.to.db;
    final channel = await db.getChannelById(roomId);
    if (channel == null) {
      if (channel == null) {
        return LiveRoom(
          cover: '',
          watching: '',
          roomId: roomId,
          area: '',
          title: '',
          nick: '',
          avatar: defaultAvatar,
          introduction: '',
          notice: '',
          status: true,
          liveStatus: LiveStatus.live,
          platform: Sites.iptvSite,
          link: roomId,
          data: roomId,
        );
      }
    }
    return _buildLiveRoom(channel);
  }

  @override
  Future<LiveRoom> getRoomDetailForRecording({required String platform, required String roomId}) {
    // Imported channels already store their playback URL as room data. The
    // database lookup is authoritative and does not use a presentation
    // fallback, so the same loader is the strict recording contract.
    return getRoomDetail(platform: platform, roomId: roomId);
  }

  LiveRoom _buildLiveRoom(Channel channel) {
    return LiveRoom(
      roomId: channel.id,
      title: channel.name,
      nick: channel.tvgName ?? channel.name,
      cover: channel.tvgLogo ?? '',
      area: channel.groupTitle ?? '',
      watching: '',
      avatar: defaultAvatar,
      status: true,
      liveStatus: LiveStatus.live,
      platform: Sites.iptvSite,
      link: channel.streamUrl,
      data: channel.streamUrl,
      catchUpMode: channel.catchupMode,
      catchUpSource: channel.catchupSource,
      catchUpDays: channel.catchupDays,
      catchUpCorrectionHours: channel.catchupCorrectionHours,
      httpHeaders: _channelHeaders(HttpHeaderPolicy.decode(channel.httpHeadersJson)),
    );
  }

  // =========================================================
  // Recommendations (popular).
  // =========================================================

  @override
  Future<List<LiveRoom>> getRecommendRooms({int page = 1, int pageSize = 30}) async {
    var channels = await IptvRepository().getChannels(FileUtils.systemHotProviderId);
    if (channels.isEmpty) {
      await AutoSyncScheduler.instance.loadHotResources();
    }
    channels = await IptvRepository().getChannels(FileUtils.systemHotProviderId);
    final providerNames = await _providerNames();
    final items = <LiveRoom>[];
    for (final ch in channels) {
      items.add(
        LiveRoom(
          roomId: ch.id,
          title: ch.name,
          nick: _sourceLabel(ch.groupTitle, providerNames[ch.providerId] ?? ''),
          cover: ch.tvgLogo ?? '',
          area: ch.groupTitle ?? '',
          watching: '',
          avatar: defaultAvatar,
          introduction: ch.name,
          notice: '',
          status: true,
          liveStatus: LiveStatus.live,
          platform: Sites.iptvSite,
          link: ch.streamUrl,
          data: ch.streamUrl,
          catchUpMode: ch.catchupMode,
          catchUpSource: ch.catchupSource,
          catchUpDays: ch.catchupDays,
          catchUpCorrectionHours: ch.catchupCorrectionHours,
          httpHeaders: _channelHeaders(ch.httpHeaders),
        ),
      );
    }

    return items;
  }

  // =========================================================
  // Playback quality.
  // =========================================================

  @override
  Future<List<LivePlayQuality>> getPlayQualites({required LiveRoom detail}) async {
    final url = detail.data?.toString().trim() ?? '';
    if (url.isEmpty) return const <LivePlayQuality>[];
    return [
      LivePlayQuality(quality: i18n('default_option'), id: 'default', sort: 1, data: <String>[url]),
    ];
  }

  // =========================================================
  // Playback address.
  // =========================================================

  @override
  Future<List<String>> getPlayUrls({required LiveRoom detail, required LivePlayQuality quality}) async {
    final data = quality.data;
    if (data is! List) return const <String>[];
    return data.map((item) => item.toString().trim()).where((url) => url.isNotEmpty).toList(growable: false);
  }

  // =========================================================
  // Danmaku.
  // =========================================================

  @override
  LiveDanmaku getDanmaku() => EmptyDanmaku();

  // =========================================================
  // Live status.
  // =========================================================

  @override
  Future<bool> getLiveStatus({required String platform, required String roomId}) async {
    return true;
  }

  // =========================================================
  // Super chat.
  // =========================================================

  @override
  Future<List<LiveSuperChatMessage>> getSuperChatMessage({required String roomId}) async {
    return [];
  }

  // =========================================================
  // Search anchors.
  // =========================================================

  @override
  Future<List<LiveAnchorItem>> searchAnchors(String keyword, {int page = 1, int pageSize = 30}) async {
    return [];
  }

  // =========================================================
  // Search channels.
  // =========================================================

  @override
  Future<List<LiveRoom>> searchRooms(String keyword, {int page = 1, int pageSize = 30}) async {
    final db = DbService.to.db;
    if (keyword.trim().isEmpty) return [];
    final matched = await db.searchChannelsByName(keyword);
    final providerNames = await _providerNames();
    final items = matched.map((ch) {
      return LiveRoom(
        roomId: ch.id,
        title: ch.name,
        nick: _sourceLabel(ch.groupTitle, providerNames[ch.providerId] ?? ''),
        cover: ch.tvgLogo ?? '',
        area: ch.groupTitle ?? '',
        watching: '',
        avatar: defaultAvatar,
        status: true,
        liveStatus: LiveStatus.live,
        platform: Sites.iptvSite,
        link: ch.streamUrl,
        data: ch.streamUrl,
        catchUpMode: ch.catchupMode,
        catchUpSource: ch.catchupSource,
        catchUpDays: ch.catchupDays,
        catchUpCorrectionHours: ch.catchupCorrectionHours,
        httpHeaders: _channelHeaders(HttpHeaderPolicy.decode(ch.httpHeadersJson)),
      );
    }).toList();
    return items;
  }
}
