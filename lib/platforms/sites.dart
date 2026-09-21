import 'package:meta/meta.dart';
import 'package:pure_live/platforms/index.dart';
import 'package:pure_live/shared/i18n/locale_helper.dart';
import 'package:pure_live/shared/contracts/live_site.dart';
import 'package:pure_live/services/settings/settings.dart';
import 'package:pure_live/features/iptv/platform/iptv_site.dart';
import 'package:pure_live/shared/models/live_room/live_room.dart';

class Sites {
  /// Hook for querying the room being played. The playback page registers it
  /// through its Riverpod controller and the site layer uses it to recover from
  /// errors.
  static LiveRoom? Function(String platform, String roomId)? currentRoomLookup;

  /// Test seam: substitutes the adapter [of] returns for one platform id.
  ///
  /// The registry is static and its adapters own real network state, so a test
  /// that needs to observe how a caller treats a platform response (a failing
  /// favourite refresh, for example) can install a fake here. Production code
  /// never sets this.
  @visibleForTesting
  static LiveSite? Function(String id)? siteLookupOverride;

  static LiveRoom? currentRoom(String platform, String roomId) {
    final lookup = currentRoomLookup;
    if (lookup == null) return null;
    final room = lookup(platform, roomId);
    if (room == null) return null;
    return room.hasIdentity(platform: platform, roomId: roomId) ? room : null;
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
  static const String huajiaoSite = 'huajiao';
  static const String openrecSite = 'openrec';
  static const String ttingSite = 'ttinglive';
  static const String xiaohongshuSite = 'xiaohongshu';
  static const String showroomSite = 'showroom';
  static const String chzzkSite = 'chzzk';
  static const String kickSite = 'kick';

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
    huajiaoSite,
    openrecSite,
    ttingSite,
    xiaohongshuSite,
    showroomSite,
    chzzkSite,
    kickSite,
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
    huajiaoSite: '$_assetRoot/huajiao.png',
    openrecSite: '$_assetRoot/openrec.png',
    ttingSite: '$_assetRoot/ttinglive.gif',
    xiaohongshuSite: '$_assetRoot/xiaohongshu.png',
    niconicoSite: '$_assetRoot/niconico.png',
    weiboSite: '$_assetRoot/weibo.png',
    showroomSite: '$_assetRoot/showroom.png',
    chzzkSite: '$_assetRoot/chzzk.png',
    kickSite: '$_assetRoot/kick.png',
  };

  /// Resolve a logo path from the central logo registry.
  ///
  /// Unknown platforms keep the generic application logo instead of
  /// accidentally returning an unrelated platform icon.
  static String logoOf(String id) {
    final normalizedId = id.trim().toLowerCase();

    return _logos[normalizedId] ?? '$_assetRoot/logo.png';
  }

  static bool isSupported(String id) {
    return supportedSiteIds.contains(id.trim().toLowerCase());
  }

  /// Create a single platform adapter.
  ///
  /// Keeping construction in one switch prevents `supportSites`,
  /// `availableSites` and `of` from drifting apart when a new platform
  /// is added.
  static Site _createSite(String id) {
    final normalizedId = id.trim().toLowerCase();

    return switch (normalizedId) {
      weiboSite => Site(id: weiboSite, name: i18n('site_weibo'), logo: logoOf(weiboSite), liveSite: WeiboSite()),
      niconicoSite => Site(id: niconicoSite, name: 'niconico', logo: logoOf(niconicoSite), liveSite: NiconicoSite()),
      bilibiliSite => Site(
        id: bilibiliSite,
        name: i18n('site_bilibili'),
        logo: logoOf(bilibiliSite),
        liveSite: BiliBiliSite(),
      ),
      douyuSite => Site(id: douyuSite, name: i18n('site_douyu'), logo: logoOf(douyuSite), liveSite: DouyuSite()),
      huyaSite => Site(id: huyaSite, name: i18n('site_huya'), logo: logoOf(huyaSite), liveSite: HuyaSite()),
      douyinSite => Site(id: douyinSite, name: i18n('site_douyin'), logo: logoOf(douyinSite), liveSite: DouyinSite()),
      kuaishouSite => Site(
        id: kuaishouSite,
        name: i18n('site_kuaishou'),
        logo: logoOf(kuaishouSite),
        liveSite: KuaishouSite(),
      ),
      ccSite => Site(id: ccSite, name: i18n('site_cc'), logo: logoOf(ccSite), liveSite: CCSite()),
      twitchSite => Site(id: twitchSite, name: i18n('site_twitch'), logo: logoOf(twitchSite), liveSite: TwitchSite()),
      soopSite => Site(id: soopSite, name: i18n('site_soop'), logo: logoOf(soopSite), liveSite: SoopSite()),
      yySite => Site(id: yySite, name: i18n('site_yy'), logo: logoOf(yySite), liveSite: YYSite()),
      acfunSite => Site(id: acfunSite, name: i18n('site_acfun'), logo: logoOf(acfunSite), liveSite: AcfunSite()),
      picartoSite => Site(id: picartoSite, name: 'Picarto', logo: logoOf(picartoSite), liveSite: PicartoSite()),
      twitcastingSite => Site(
        id: twitcastingSite,
        name: 'TwitCasting',
        logo: logoOf(twitcastingSite),
        liveSite: TwitcastingSite(),
      ),
      missevanSite => Site(
        id: missevanSite,
        name: i18n('site_missevan'),
        logo: logoOf(missevanSite),
        liveSite: MissevanSite(),
      ),
      inkeSite => Site(id: inkeSite, name: i18n('site_inke'), logo: logoOf(inkeSite), liveSite: InkeSite()),
      kilakilaSite => Site(
        id: kilakilaSite,
        name: i18n('site_kilakila'),
        logo: logoOf(kilakilaSite),
        liveSite: KilakilaSite(),
      ),
      huajiaoSite => Site(
        id: huajiaoSite,
        name: i18n('site_huajiao'),
        logo: logoOf(huajiaoSite),
        liveSite: HuajiaoSite(),
      ),
      openrecSite => Site(
        id: openrecSite,
        name: 'mellow-fan (OPENREC)',
        logo: logoOf(openrecSite),
        liveSite: OpenrecSite(),
      ),
      ttingSite => Site(id: ttingSite, name: 'FLEX TV (TTingLive)', logo: logoOf(ttingSite), liveSite: TtingSite()),
      xiaohongshuSite => Site(
        id: xiaohongshuSite,
        name: i18n('site_xiaohongshu'),
        logo: logoOf(xiaohongshuSite),
        liveSite: XiaohongshuSite(),
      ),
      showroomSite => Site(
        id: showroomSite,
        name: i18n('site_showroom'),
        logo: logoOf(showroomSite),
        liveSite: ShowroomSite(),
      ),
      chzzkSite => Site(
        id: chzzkSite,
        name: i18n('site_chzzk'),
        logo: logoOf(chzzkSite),
        liveSite: ChzzkSite(),
      ),
      kickSite => Site(id: kickSite, name: i18n('site_kick'), logo: logoOf(kickSite), liveSite: KickSite()),
      iptvSite => Site(id: iptvSite, name: i18n('site_iptv'), logo: logoOf(iptvSite), liveSite: IptvSite()),
      _ => throw StateError('Unsupported live site: $normalizedId'),
    };
  }

  /// Build the complete supported-site list.
  ///
  /// The list is cached because platform adapters can contain session,
  /// authentication or request-related state. Recreating them every time
  /// `supportSites` is accessed would unnecessarily discard that state.
  static final List<Site> _supportedSites = List<Site>.unmodifiable([
    for (final id in [
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
      huajiaoSite,
      openrecSite,
      ttingSite,
      xiaohongshuSite,
      showroomSite,
      chzzkSite,
      kickSite,
      niconicoSite,
      weiboSite,
      iptvSite,
    ])
      _createSite(id),
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
  /// Popular and search controllers deliberately retain their [Site]
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
