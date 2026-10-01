import 'package:meta/meta.dart';
import 'package:pure_live/platforms/index.dart';
import 'package:pure_live/core/i18n/locale_helper.dart';
import 'package:pure_live/core/contracts/live_site.dart';
import 'package:pure_live/services/settings/settings.dart';
import 'package:pure_live/modules/live/iptv/platform/iptv_site.dart';
import 'package:pure_live/core/models/live_room/live_room.dart';

class Sites {
  /// Hook for querying the room being played. The playback page registers it
  /// through its Riverpod controller and the site layer uses it to recover from
  /// errors.
  static LiveRoom? Function(LiveRoom room)? currentRoomLookup;

  /// Test seam: substitutes the adapter [of] returns for one platform id.
  ///
  /// The registry is static and its adapters own real network state, so a test
  /// that needs to observe how a caller treats a platform response (a failing
  /// favourite refresh, for example) can install a fake here. Production code
  /// never sets this.
  @visibleForTesting
  static LiveSite? Function(String id)? siteLookupOverride;

  static LiveRoom? currentRoom(LiveRoom room) {
    final lookup = currentRoomLookup;
    if (lookup == null) return null;
    final found = lookup(room);
    return found != null && found.hasSameIdentity(room) ? found : null;
  }

  static const String weiboSite = 'weibo';
  static const String niconicoSite = 'niconico';
  static const String allSite = 'all';
  static const String bilibiliSite = 'bilibili';
  static const String douyuSite = 'douyu';
  static const String huyaSite = 'huya';
  static const String douyinSite = 'douyin';
  static const String kuaishouSite = 'kuaishou';
  static const String ccSite = 'cc';
  static const String iptvSite = 'iptv';
  static const String twitchSite = 'twitch';
  static const String soopSite = 'soop';
  static const String yySite = 'yy';
  static const String acfunSite = 'acfun';
  static const String picartoSite = 'picarto';
  static const String twitcastingSite = 'twitcasting';
  static const String missevanSite = 'missevan';
  static const String inkeSite = 'inke';
  static const String kilakilaSite = 'kilakila';
  static const String xiaohongshuSite = 'xiaohongshu';
  static const String showroomSite = 'showroom';
  static const String chzzkSite = 'chzzk';
  static const String kickSite = 'kick';
  static const String liveMeSite = 'liveme';
  static const String tiktokSite = 'tiktok';
  static const String youtubeSite = 'youtube';
  static const String bigoSite = 'bigo';
  static const String pandaLiveSite = 'pandalive';
  static const String fc2LiveSite = 'fc2live';
  static const String steamBroadcastSite = 'steambroadcast';
  static const String jdLiveSite = 'jdlive';
  static const String kugouLiveSite = 'kugoulive';
  static const String baiduLiveSite = 'baidulive';
  static const String lookLiveSite = 'looklive';
  static const String seventeenLiveSite = '17live';
  static const String sixRoomSite = 'sixroom';

  static const Set<String> supportedSiteIds = {
    weiboSite,
    niconicoSite,
    bilibiliSite,
    douyuSite,
    huyaSite,
    douyinSite,
    kuaishouSite,
    ccSite,
    twitchSite,
    soopSite,
    yySite,
    acfunSite,
    picartoSite,
    twitcastingSite,
    missevanSite,
    inkeSite,
    kilakilaSite,
    xiaohongshuSite,
    showroomSite,
    chzzkSite,
    kickSite,
    liveMeSite,
    tiktokSite,
    youtubeSite,
    bigoSite,
    pandaLiveSite,
    fc2LiveSite,
    steamBroadcastSite,
    jdLiveSite,
    kugouLiveSite,
    baiduLiveSite,
    sixRoomSite,
    lookLiveSite,
    seventeenLiveSite,
    iptvSite,
  };

  static const String _assetRoot = 'assets/images';

  /// Keep all platform logos in one place.
  ///
  /// The platform-specific files are preferred over the old generic
  /// `logo.png` placeholder so every site has its own visual identity.
  static const Map<String, String> _logos = {
    bilibiliSite: '$_assetRoot/bilibili_2.png',
    douyuSite: '$_assetRoot/douyu.png',
    huyaSite: '$_assetRoot/huya.png',
    douyinSite: '$_assetRoot/douyin.png',
    kuaishouSite: '$_assetRoot/kuaishou.png',
    ccSite: '$_assetRoot/cc.png',
    iptvSite: '$_assetRoot/iptv.png',
    twitchSite: '$_assetRoot/twitch.png',
    soopSite: '$_assetRoot/soop.png',
    yySite: '$_assetRoot/yy.png',
    acfunSite: '$_assetRoot/acfun.png',
    picartoSite: '$_assetRoot/picarto.png',
    twitcastingSite: '$_assetRoot/twitcasting.png',
    missevanSite: '$_assetRoot/missevan.png',
    inkeSite: '$_assetRoot/inke.png',
    kilakilaSite: '$_assetRoot/kilakila.png',
    xiaohongshuSite: '$_assetRoot/xiaohongshu.png',
    niconicoSite: '$_assetRoot/niconico.png',
    weiboSite: '$_assetRoot/weibo.png',
    showroomSite: '$_assetRoot/showroom.png',
    chzzkSite: '$_assetRoot/chzzk.png',
    kickSite: '$_assetRoot/kick.png',
    pandaLiveSite: '$_assetRoot/panda.png',
    fc2LiveSite: '$_assetRoot/fc2.png',
    steamBroadcastSite: '$_assetRoot/steam.png',
    jdLiveSite: '$_assetRoot/jd.png',
    kugouLiveSite: '$_assetRoot/kugou.png',
    baiduLiveSite: '$_assetRoot/baidu.png',
    lookLiveSite: '$_assetRoot/look.png',
    seventeenLiveSite: '$_assetRoot/17live.png',
    sixRoomSite: '$_assetRoot/sixroom.png',
    youtubeSite: '$_assetRoot/youtube.png',
    bigoSite: '$_assetRoot/bigo.png',
    liveMeSite: '$_assetRoot/liveme.png',
    tiktokSite: '$_assetRoot/tiktok.png',
  };

  /// Resolve a logo path from the central logo registry.
  ///
  /// Unknown platforms keep the generic application logo instead of
  /// accidentally returning an unrelated platform icon.
  static String logoOf(String id) {
    final normalizedId = id.trim().toLowerCase();

    // Retired platforms keep a neutral badge so saved follows still render.
    if (retiredSiteIds.contains(normalizedId)) return '$_assetRoot/logo.png';

    return _logos[normalizedId] ?? '$_assetRoot/logo.png';
  }

  /// Platforms retired upstream in 3.2.8 (hard to maintain, niche or no longer
  /// usable) and removed here for the same reasons.
  ///
  /// Saved follows, history and links for them stay readable: their `site_*`
  /// names are kept, [logoOf] hands out the neutral badge, and opening one is
  /// refused with `platform_retired` instead of failing as unknown.
  static const Set<String> retiredSiteIds = {
    'huajiao',
    'openrec',
    'ttinglive',
    'popkontv',
    'shopeelive',
    'vkvideolive',
    'nimotv',
    'dailymotion',
    'rumble',
    'goodgame',
    'taobaolive',
  };

  static bool isRetired(String id) => retiredSiteIds.contains(id.trim().toLowerCase());

  /// Web hosts of the retired platforms, so a shared link can be answered with
  /// the retired message instead of being ignored as unrecognised text.
  static const Set<String> _retiredHosts = {
    'huajiao.com',
    'openrec.tv',
    'flextv.co.kr',
    'ttinglive.com',
    'popkontv.com',
    'goodgame.ru',
    'vkvideo.ru',
    'vkplay.live',
    'dailymotion.com',
    'dai.ly',
    'rumble.com',
    'nimo.tv',
    'shopee.co.id',
    'taobao.com',
    'm.tb.cn',
  };

  static bool isRetiredLink(String text) {
    for (final match in RegExp(r'https?://[^\s]+', caseSensitive: false).allMatches(text)) {
      final host = Uri.tryParse(match.group(0)!)?.host.toLowerCase() ?? '';
      if (_retiredHosts.any((h) => host == h || host.endsWith('.$h'))) return true;
    }
    return false;
  }

  static bool isSupported(String id) {
    return supportedSiteIds.contains(id.trim().toLowerCase());
  }

  /// One row per platform, in the order the home tabs list them.
  ///
  /// This is the single source of truth for the adapter cache: both
  /// [_supportedSites] and [_createSite] derive from it, so the display list
  /// and the per-platform construction can never drift apart when a platform
  /// is added. `name` is only a fallback label — [Site.name] re-resolves the
  /// `site_*` string at paint, so an in-app language change is reflected
  /// without rebuilding the cached adapters.
  static final List<({String id, String name, LiveSite Function() create})> _platforms = [
    (id: bilibiliSite, name: i18n('site_bilibili'), create: BiliBiliSite.new),
    (id: douyuSite, name: i18n('site_douyu'), create: DouyuSite.new),
    (id: huyaSite, name: i18n('site_huya'), create: HuyaSite.new),
    (id: douyinSite, name: i18n('site_douyin'), create: DouyinSite.new),
    (id: kuaishouSite, name: i18n('site_kuaishou'), create: KuaishouSite.new),
    (id: ccSite, name: i18n('site_cc'), create: CCSite.new),
    (id: twitchSite, name: i18n('site_twitch'), create: TwitchSite.new),
    (id: soopSite, name: i18n('site_soop'), create: SoopSite.new),
    (id: yySite, name: i18n('site_yy'), create: YYSite.new),
    (id: acfunSite, name: i18n('site_acfun'), create: AcfunSite.new),
    (id: picartoSite, name: 'Picarto', create: PicartoSite.new),
    (id: twitcastingSite, name: 'TwitCasting', create: TwitcastingSite.new),
    (id: missevanSite, name: i18n('site_missevan'), create: MissevanSite.new),
    (id: inkeSite, name: i18n('site_inke'), create: InkeSite.new),
    (id: kilakilaSite, name: i18n('site_kilakila'), create: KilakilaSite.new),
    (id: xiaohongshuSite, name: i18n('site_xiaohongshu'), create: XiaohongshuSite.new),
    (id: showroomSite, name: i18n('site_showroom'), create: ShowroomSite.new),
    (id: chzzkSite, name: i18n('site_chzzk'), create: ChzzkSite.new),
    (id: kickSite, name: i18n('site_kick'), create: KickSite.new),
    (id: liveMeSite, name: i18n('site_liveme'), create: LiveMeSite.new),
    (id: tiktokSite, name: i18n('site_tiktok'), create: TikTokSite.new),
    (id: youtubeSite, name: i18n('site_youtube'), create: YouTubeSite.new),
    (id: bigoSite, name: i18n('site_bigo'), create: BigoSite.new),
    (id: pandaLiveSite, name: i18n('site_pandalive'), create: PandaLiveSite.new),
    (id: fc2LiveSite, name: i18n('site_fc2live'), create: Fc2Site.new),
    (id: steamBroadcastSite, name: i18n('site_steambroadcast'), create: SteamBroadcastSite.new),
    (id: jdLiveSite, name: i18n('site_jdlive'), create: JdLiveSite.new),
    (id: kugouLiveSite, name: i18n('site_kugoulive'), create: KugouLiveSite.new),
    (id: baiduLiveSite, name: i18n('site_baidulive'), create: BaiduLiveSite.new),
    (id: sixRoomSite, name: i18n('site_sixroom'), create: SixRoomSite.new),
    (id: lookLiveSite, name: i18n('site_looklive'), create: LookLiveSite.new),
    (id: seventeenLiveSite, name: i18n('site_17live'), create: SeventeenLiveSite.new),
    (id: niconicoSite, name: 'niconico', create: NiconicoSite.new),
    (id: weiboSite, name: i18n('site_weibo'), create: WeiboSite.new),
    (id: iptvSite, name: i18n('site_iptv'), create: IptvSite.new),
  ];

  /// Wrap a [_platforms] row in a freshly-constructed [Site].
  static Site _buildSite(({String id, String name, LiveSite Function() create}) entry) {
    return Site(id: entry.id, name: entry.name, logo: logoOf(entry.id), liveSite: entry.create());
  }

  /// Create a single platform adapter by id.
  static Site _createSite(String id) {
    final normalizedId = id.trim().toLowerCase();
    for (final entry in _platforms) {
      if (entry.id == normalizedId) return _buildSite(entry);
    }
    throw StateError('Unsupported live site: $normalizedId');
  }

  /// Build the complete supported-site list, in [_platforms] order.
  ///
  /// The list is cached because platform adapters can contain session,
  /// authentication or request-related state. Recreating them every time
  /// `supportSites` is accessed would unnecessarily discard that state.
  static final List<Site> _supportedSites = List<Site>.unmodifiable([
    for (final entry in _platforms) _buildSite(entry),
  ]);

  static List<Site> get supportSites => _supportedSites;

  static Site of(String id) {
    final normalizedId = id.trim().toLowerCase();

    final override = siteLookupOverride;
    if (override != null) {
      final substituted = override(normalizedId);
      if (substituted != null) {
        return Site(id: normalizedId, name: normalizedId, logo: logoOf(normalizedId), liveSite: substituted);
      }
    }

    // Reuse the cached adapter: constructing a fresh one per call (favourite
    // verification does this per room per refresh) discarded platform session
    // caches and allocated an adapter each time.
    for (final site in _supportedSites) {
      if (site.id == normalizedId) return site;
    }
    return _createSite(normalizedId);
  }

  List<Site> availableSites({bool containsAll = false}) {
    final List<String> savedIds = SettingsService.to.fav.hotAreasList.v;

    final supportedById = <String, Site>{for (final site in supportSites) site.id: site};

    final List<Site> result = [];
    final seen = <String>{};

    for (final rawId in savedIds) {
      final id = rawId.trim().toLowerCase();

      if (!seen.add(id)) {
        continue;
      }

      final match = supportedById[id];

      if (match != null) {
        result.add(match);
      }
    }

    if (containsAll) {
      result.insert(0, Site(id: allSite, name: i18n('site_all'), logo: '$_assetRoot/all.png', liveSite: LiveSite()));
    }

    return result;
  }
}

class Site {
  final String id;
  final String _fallbackName;
  final String logo;
  final LiveSite liveSite;

  Site({required this.id, required this.liveSite, required this.logo, required String name}) : _fallbackName = name;

  /// Resolve registry labels when they are painted instead of freezing the
  /// locale that happened to be active when an adapter was constructed.
  /// Popular and search controllers retain their [Site]
  /// instances so pagination/session state stays stable; the label must still
  /// follow an in-app language change without rebuilding those adapters.
  String get name {
    final normalizedId = id.trim().toLowerCase();

    if (normalizedId != Sites.allSite && !Sites.isSupported(normalizedId)) {
      return _fallbackName;
    }

    return i18nOr('site_$normalizedId', _fallbackName);
  }
}
