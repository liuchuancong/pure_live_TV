import 'package:pure_live/exports/common_export.dart';
import 'package:pure_live/services/settings/settings.dart';

/// Resolves the HTTP headers used to read a platform's media stream.
///
/// Covers bilibili, douyu, huya, douyin, kuaishou, cc and iptv; platforms
/// without a specific policy get an empty header set.
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
        headers = <String, String>{
          'origin': 'https://www.douyu.com',
          'referer': 'https://www.douyu.com/$normalizedRoomId',
          'user-agent': _desktopUserAgent,
        };
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
