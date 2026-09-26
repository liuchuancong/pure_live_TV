import 'package:pure_live/exports/common_export.dart';
import 'package:pure_live/services/settings/settings.dart';

/// Resolves the HTTP headers used to read a platform's media stream.
///
/// Mirrors the reference client's per-platform header policy: account cookies
/// are attached for the platforms that accept them, and platforms that need a
/// signed Referer/Origin get their own static header set. Platforms without a
/// specific policy get an empty header set.
class PlaybackHeaderResolver {
  const PlaybackHeaderResolver._();

  static const String _desktopUserAgent =
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) '
      'AppleWebKit/537.36 (KHTML, like Gecko) '
      'Chrome/140.0.0.0 Safari/537.36';

  static const String _kuaishouUserAgent =
      'Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7) '
      'AppleWebKit/537.36 (KHTML, like Gecko) '
      'Chrome/140.0.0.0 Safari/537.36';

  static Future<Map<String, String>> resolve({
    required String platform,
    String roomId = '',
    Map<String, String> roomHeaders = const <String, String>{},
  }) async {
    final normalizedPlatform = platform.trim().toLowerCase();
    final normalizedRoomId = Uri.encodeComponent(roomId.trim());
    Map<String, String> headers;

    switch (normalizedPlatform) {
      case Sites.bilibiliSite:
        final cookie = _configuredCookie((settings) => settings.cookieState.bilibiliCookie);
        final anonymousCookie = <String>[
          if (BiliBiliSite.buvid3.isNotEmpty) 'buvid3=${BiliBiliSite.buvid3}',
          if (BiliBiliSite.buvid4.isNotEmpty) 'buvid4=${BiliBiliSite.buvid4}',
        ].join(';');
        headers = <String, String>{
          'user-agent': BiliBiliSite.kDefaultUserAgent,
          'origin': 'https://live.bilibili.com',
          'referer': normalizedRoomId.isEmpty
              ? BiliBiliSite.kDefaultReferer
              : 'https://live.bilibili.com/$normalizedRoomId',
          if (cookie.isNotEmpty) 'cookie': cookie else if (anonymousCookie.isNotEmpty) 'cookie': anonymousCookie,
        };
        break;
      case Sites.douyuSite:
        // The signer did and playback share one Cookie, so an optional account
        // session travels with the media request as well.
        headers = DouyuUtils.playbackHeaders(roomId.trim());
        break;
      case Sites.huyaSite:
        // Huya's URL signer refreshes this process-wide value while resolving
        // the stream. Falling back here avoids a second network request solely
        // for headers and keeps deterministic callers offline-safe.
        final userAgent = HuyaSite.playUserAgent ?? _desktopUserAgent;
        final cookie = _configuredCookie((settings) => settings.cookieState.huyaCookie);
        headers = <String, String>{
          'user-agent': userAgent,
          'origin': 'https://www.huya.com',
          'referer': normalizedRoomId.isEmpty ? 'https://www.huya.com/' : 'https://www.huya.com/$normalizedRoomId',
          if (cookie.isNotEmpty) 'cookie': cookie,
        };
        break;
      case Sites.douyinSite:
        final configuredCookie = _configuredCookie((settings) => settings.cookieState.douyinCookie);
        final cookie = configuredCookie.isNotEmpty ? configuredCookie : DouyinSite.cookie.trim();
        headers = <String, String>{
          'user-agent': _desktopUserAgent,
          'origin': 'https://live.douyin.com',
          'referer': normalizedRoomId.isEmpty
              ? 'https://live.douyin.com/'
              : 'https://live.douyin.com/$normalizedRoomId',
          if (cookie.isNotEmpty) 'cookie': cookie,
        };
        break;
      case Sites.kuaishouSite:
        final cookie = _configuredCookie((settings) => settings.cookieState.kuaishouCookie);
        headers = <String, String>{
          'user-agent': _kuaishouUserAgent,
          'origin': 'https://live.kuaishou.com',
          'referer': normalizedRoomId.isEmpty
              ? 'https://live.kuaishou.com/'
              : 'https://live.kuaishou.com/u/$normalizedRoomId',
          if (cookie.isNotEmpty) 'cookie': cookie,
        };
        break;
      case Sites.ccSite:
        headers = <String, String>{
          'user-agent': _desktopUserAgent,
          'origin': 'https://cc.163.com',
          'referer': normalizedRoomId.isEmpty ? 'https://cc.163.com/' : 'https://cc.163.com/$normalizedRoomId/',
        };
        break;
      case Sites.iptvSite:
        headers = {...HttpHeaderPolicy.normalize(roomHeaders)};
        break;
      case Sites.twitchSite:
        final cookie = _configuredCookie((settings) => settings.cookieManager.twitchCookie.value);
        headers = <String, String>{
          'user-agent': TwitchSite.defaultUa,
          'origin': TwitchSite.baseUrl,
          'referer': normalizedRoomId.isEmpty ? '${TwitchSite.baseUrl}/' : '${TwitchSite.baseUrl}/$normalizedRoomId',
          if (cookie.isNotEmpty) 'cookie': cookie,
        };
        break;
      case Sites.soopSite:
        final cookie = _configuredCookie((settings) => settings.cookieManager.soopCookie.value);
        headers = <String, String>{
          'user-agent': _desktopUserAgent,
          'origin': 'https://www.sooplive.co.kr',
          'referer': normalizedRoomId.isEmpty
              ? 'https://www.sooplive.co.kr/'
              : 'https://play.sooplive.co.kr/$normalizedRoomId',
          if (cookie.isNotEmpty) 'cookie': cookie,
        };
        break;
      case Sites.yySite:
        final cookie = _configuredCookie((settings) => settings.cookieManager.yyCookie.value);
        headers = <String, String>{
          'origin': 'https://www.yy.com',
          'referer': 'https://www.yy.com/',
          'user-agent': _desktopUserAgent,
          if (cookie.isNotEmpty) 'cookie': cookie,
        };
        break;
      case Sites.picartoSite:
        headers = {...PicartoApi.playHeaders, 'User-Agent': _desktopUserAgent};
        break;
      case Sites.twitcastingSite:
        headers = TwitcastingApi.playHeaders;
        break;
      case Sites.missevanSite:
        headers = MissevanApi.playHeaders;
        break;
      case Sites.xiaohongshuSite:
        headers = XiaohongshuApi.headers;
        break;
      case Sites.kilakilaSite:
        headers = KilakilaApi.playHeaders;
        break;
      case Sites.inkeSite:
        headers = InkeApi.playHeaders;
        break;
      case Sites.acfunSite:
        headers = {...AcfunApi.playHeaders, 'origin': AcfunApi.origin};
        break;
      case Sites.showroomSite:
        headers = ShowroomApi.mediaHeaders;
        break;
      case Sites.chzzkSite:
        headers = ChzzkApi.mediaHeaders;
        break;
      case Sites.kickSite:
        headers = KickApi.mediaHeaders(roomId);
        break;
      case Sites.seventeenLiveSite:
        headers = SeventeenLiveApi.mediaHeaders(roomId);
        break;
      case Sites.liveMeSite:
        headers = LiveMeApi.mediaHeaders(roomId);
        break;
      case Sites.tiktokSite:
        headers = TikTokApi.mediaHeaders(roomId);
        break;
      case Sites.youtubeSite:
        headers = YouTubeApi.mediaHeaders(roomId);
        break;
      case Sites.bigoSite:
        headers = BigoApi.headers;
        break;
      case Sites.pandaLiveSite:
        headers = PandaLiveApi.mediaHeaders(roomId);
        break;
      default:
        headers = const <String, String>{};
    }

    return HttpHeaderPolicy.normalize(headers);
  }

  static String _configuredCookie(String Function(SettingsService settings) read) => _configuredValue(read);

  static String _configuredValue(String Function(SettingsService settings) read) {
    try {
      return read(SettingsService.to).trim();
    } catch (_) {
      return '';
    }
  }
}
