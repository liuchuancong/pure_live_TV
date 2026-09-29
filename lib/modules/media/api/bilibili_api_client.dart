import 'package:pure_live/platforms/bilibili/bilibili_site.dart';
import 'package:pure_live/services/settings/settings.dart';
import 'package:pure_live/shared/common/http_client.dart';

/// The shared bilibili web-API plumbing behind every `media/api` endpoint
/// file: the stored QR-login cookie and its csrf/mid derivatives, plus the
/// header set every request must carry. WBI signing shares the site's key
/// cache, so the live platform and the media modules sign with one key pair.
///
/// The cookie rides on **every** bilibili call, logged in or not:
/// [BiliBiliSite.getHeader] embeds the stored login cookie when present and
/// the anonymous buvid pair otherwise, so `{...base, 'referer': ...}` always
/// carries a cookie. Per-file referers still matter (search wants
/// search.bilibili.com, streams want the archive page).
class BilibiliApiClient {
  BilibiliApiClient._();

  static final BilibiliApiClient instance = BilibiliApiClient._();

  final BiliBiliSite _site = BiliBiliSite();

  /// The referer video-site endpoints expect; only search and the stream CDN
  /// need something else.
  static const String videoReferer = 'https://www.bilibili.com/';

  String get cookie => SettingsService.to.cookieManager.bilibiliCookie.v;

  bool get loggedIn => cookie.trim().isNotEmpty;

  /// The csrf token the POST endpoints require; it lives in the cookie.
  String get csrf => RegExp(r'bili_jct=([^;]+)').firstMatch(cookie)?.group(1) ?? '';

  int get myMid => int.tryParse(RegExp(r'DedeUserID=([^;]+)').firstMatch(cookie)?.group(1) ?? '') ?? 0;

  /// Throws on every state-changing call when no QR login exists — the login
  /// gate normally prevents reaching one, but a mid-session logout must not
  /// corrupt data.
  void ensureLogin() {
    if (loggedIn) return;
    throw Exception('bilibili login required');
  }

  /// Browser UA + cookie (login or buvid) from the site, with [referer] —
  /// every bilibili web API goes out through here.
  Future<Map<String, String>> headers({String referer = videoReferer}) async {
    final base = await _site.getHeader();
    return {...base, 'referer': referer};
  }

  /// The full browser UA, for the raw (non-JSON) fetches that hand-build
  /// their headers.
  String get userAgent => BiliBiliSite.kDefaultUserAgent;

  /// WBI-signed query params for [url], which must already carry its query
  /// string (the signer consumes the whole thing).
  Future<Map<String, String>> wbiSign(String url) => _site.getWbiSign(url);

  /// POSTs [form] (+csrf) url-encoded — the shape every state-changing web
  /// endpoint takes. Returns the `data` payload; a non-zero code throws with
  /// the API's own message.
  Future<dynamic> postForm(String url, Map<String, String> form, {String referer = videoReferer}) async {
    ensureLogin();
    final result = await HttpClient.instance.postJson(
      url,
      data: {...form, 'csrf': csrf, 'csrf_token': csrf},
      header: await headers(referer: referer),
      formUrlEncoded: true,
    );
    if (result is! Map || result['code'] != 0) {
      final message = result is Map ? result['message'] ?? result['msg'] : result;
      throw Exception('bili post $url failed: $message');
    }
    return result['data'];
  }
}
