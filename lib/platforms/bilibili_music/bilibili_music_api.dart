import 'package:pure_live/platforms/bilibili/bilibili_site.dart';
import 'package:pure_live/platforms/bilibili_music/bilibili_music_models.dart';
import 'package:pure_live/services/settings/settings.dart';
import 'package:pure_live/shared/common/http_client.dart';

/// The bilibili UGC endpoints the music mode reads.
///
/// Everything here runs against the *video* site (api.bilibili.com), not the
/// live site, but it rides on the same stored bilibili cookie and the same WBI
/// signer [BiliBiliSite] already maintains — one login serves both modes.
///
/// Two risk-control lessons from the reference TV client are baked in:
/// - playurl uses the plain `/x/player/playurl` endpoint, never the WBI one
///   (the signed variant trips `v_voucher` after a couple of plays);
/// - guest requests carry the anonymous-preview params instead of a login.
class BilibiliMusicApi {
  BilibiliMusicApi._();

  static final BilibiliMusicApi instance = BilibiliMusicApi._();

  /// Shares the buvid cache and the WBI key cache with the live site.
  final BiliBiliSite _site = BiliBiliSite();

  String get _cookie => SettingsService.to.cookieManager.bilibiliCookie.v;

  bool get _loggedIn => _cookie.trim().isNotEmpty;

  /// Referer every video-site request must carry.
  static const String _videoReferer = 'https://www.bilibili.com/';

  Future<Map<String, String>> _headers({String referer = _videoReferer}) async {
    final base = await _site.getHeader();
    return {...base, 'referer': referer};
  }

  /// The headers the CDN asks for when fetching the media streams themselves.
  Future<Map<String, String>> streamHeaders(String bvid) async {
    return {
      'user-agent': BiliBiliSite.kDefaultUserAgent,
      'referer': 'https://www.bilibili.com/video/$bvid/',
      if (_cookie.trim().isNotEmpty) 'cookie': _cookie,
    };
  }

  Map<String, String> _guestParams() => const {
    'web_location': '1315873',
    'gaia_source': 'pre-load',
    'isGaiaAvoided': 'true',
    'try_look': '1',
  };

  /// The music region leaderboard. Guest-friendly, no paging (fixed list).
  Future<List<MusicArchive>> getMusicRanking() async {
    final result = await HttpClient.instance.getJson(
      'https://api.bilibili.com/x/web-interface/ranking/v2',
      queryParameters: {'rid': '3', 'type': 'all'},
      header: await _headers(),
    );
    if (result['code'] != 0) {
      throw Exception('music ranking failed: ${result['code']} ${result['message']}');
    }
    final list = (result['data']?['list'] as List?) ?? const [];
    return [for (final item in list) MusicArchive.fromRankingJson(item)];
  }

  /// The general popular feed, paged. Guest-friendly.
  Future<List<MusicArchive>> getPopularVideos({required int page, int pageSize = 12}) async {
    final result = await HttpClient.instance.getJson(
      'https://api.bilibili.com/x/web-interface/popular',
      queryParameters: {'pn': page.toString(), 'ps': pageSize.toString()},
      header: await _headers(),
    );
    if (result['code'] != 0) {
      throw Exception('popular failed: ${result['code']} ${result['message']}');
    }
    final list = (result['data']?['list'] as List?) ?? const [];
    return [for (final item in list) MusicArchive.fromRankingJson(item)];
  }

  /// The personalized recommendation feed, paged through `fresh_idx` (WBI).
  Future<List<MusicArchive>> getRecommendFeed({required int page, int pageSize = 12}) async {
    const baseUrl = 'https://api.bilibili.com/x/web-interface/wbi/index/top/feed/rcmd';
    final url =
        '$baseUrl?fresh_type=4&ps=$pageSize&fresh_idx=$page&fresh_idx_1h=$page&platform=web'
        '&web_location=1430654&x-tra-code=20001';
    final params = await _site.getWbiSign(url);
    final result = await HttpClient.instance.getJson(baseUrl, queryParameters: params, header: await _headers());
    if (result['code'] != 0) {
      throw Exception('recommend feed failed: ${result['code']} ${result['message']}');
    }
    final list = (result['data']?['item'] as List?) ?? const [];
    return [for (final item in list) MusicArchive.fromRankingJson(item)];
  }

  /// Related archives of one video (the detail page's Related videos row).
  Future<List<MusicArchive>> getRelatedVideos({required int aid}) async {
    final result = await HttpClient.instance.getJson(
      'https://api.bilibili.com/x/web-interface/archive/related',
      queryParameters: {'aid': aid.toString()},
      header: await _headers(),
    );
    if (result['code'] != 0) {
      throw Exception('related failed: ${result['code']} ${result['message']}');
    }
    final list = (result['data'] as List?) ?? const [];
    return [for (final item in list) MusicArchive.fromRankingJson(item)];
  }

  /// Video search (the same endpoint the search page uses, typed `video`).
  ///
  /// Requires the WBI signature; the referer switches to the search host.
  Future<List<MusicArchive>> searchVideos(String keyword, {int page = 1, int pageSize = 20}) async {
    const baseUrl = 'https://api.bilibili.com/x/web-interface/wbi/search/type';
    final url =
        '$baseUrl?search_type=video&keyword=${Uri.encodeQueryComponent(keyword)}'
        '&order=totalrank&page=$page&page_size=$pageSize&highlight=1&single_column=0';
    final params = await _site.getWbiSign(url);
    final result = await HttpClient.instance.getJson(
      baseUrl,
      queryParameters: params,
      header: await _headers(referer: 'https://search.bilibili.com/'),
    );
    if (result['code'] != 0) {
      throw Exception('music search failed: ${result['code']} ${result['message']}');
    }
    final list = (result['data']?['result'] as List?) ?? const [];
    // Each archive arrives with one page-less stub; the archive page refetches
    // the full part list before anything plays.
    return [for (final item in list) if (item['type']?.toString() == 'video') MusicArchive.fromSearchJson(item)];
  }

  /// The archive detail (view API): metadata plus every part.
  Future<MusicArchive> getArchiveDetail(String bvid) async {
    final result = await HttpClient.instance.getJson(
      'https://api.bilibili.com/x/web-interface/view',
      queryParameters: {'bvid': bvid},
      header: await _headers(),
    );
    if (result['code'] != 0) {
      throw Exception('music archive detail failed: ${result['code']} ${result['message']}');
    }
    return MusicArchive.fromViewJson(result['data']);
  }

  /// Playback URLs for one part.
  ///
  /// DASH first: the video-only m4s plays as the primary source with the audio
  /// m4s attached through mpv's audio-file input (the player takes one URI).
  /// When the answer carries no DASH (a paid preview, an ancient codec) the
  /// muxed mp4 durl stands in.
  Future<MusicPlayUrls> getPlayUrls({required String bvid, required int cid}) async {
    final params = <String, String>{
      'bvid': bvid,
      'cid': cid.toString(),
      'qn': '127',
      'fnval': '4048',
      'fnver': '0',
      'fourk': '1',
      'platform': 'oc',
      if (!_loggedIn) ..._guestParams(),
    };
    final result = await HttpClient.instance.getJson(
      'https://api.bilibili.com/x/player/playurl',
      queryParameters: params,
      header: await _headers(referer: 'https://www.bilibili.com/video/$bvid/'),
    );
    if (result['code'] != 0) {
      throw Exception('music playurl failed: ${result['code']} ${result['message']}');
    }
    final data = result['data'] as Map<dynamic, dynamic>? ?? {};
    final dash = data['dash'] as Map<dynamic, dynamic>?;

    if (dash != null) {
      final urls = _pickDashStreams(dash, servedQuality: int.tryParse(data['quality']?.toString() ?? '') ?? 0);
      if (urls != null) return urls;
    }

    final durl = data['durl'] as List?;
    if (durl != null && durl.isNotEmpty) {
      final order = (durl.first['order'] ?? 1) as int;
      // Multi-segment mp4 answers cannot be concatenated by the player; only
      // the single-segment shape is playable, which is what this endpoint
      // returns outside of very long paid previews.
      if (durl.length == 1 || order > 1) {
        return MusicPlayUrls(
          videoUrl: durl.first['url']?.toString() ?? '',
          quality: int.tryParse(data['quality']?.toString() ?? '') ?? 0,
          isDash: false,
        );
      }
    }
    throw Exception('music playurl: no playable stream');
  }

  /// Best compatible DASH pair: video at or below the served quality with AVC
  /// preferred (every TV decodes it), audio at the highest ordinary bitrate.
  /// Every quality tier the answer offers also lands in [MusicPlayUrls.videoOptions],
  /// so the player page can switch quality without another request.
  MusicPlayUrls? _pickDashStreams(Map<dynamic, dynamic> dash, {required int servedQuality}) {
    final videos = (dash['video'] as List?) ?? const [];
    final audios = (dash['audio'] as List?) ?? const [];
    if (videos.isEmpty) return null;

    // One candidate per quality tier, AVC before HEVC/AV1 (the widest decoder
    // coverage on TV boxes), highest tier first.
    final Map<int, Map<dynamic, dynamic>> byQuality = {};
    for (final v in videos) {
      final id = int.tryParse(v['id']?.toString() ?? '') ?? 0;
      if (servedQuality > 0 && id > servedQuality) continue;
      final existing = byQuality[id];
      final isAvc = v['codecs']?.toString().startsWith('avc') == true;
      if (existing == null || (isAvc && existing['codecs']?.toString().startsWith('avc') != true)) {
        byQuality[id] = v;
      }
    }
    final tiers = byQuality.keys.toList()..sort((a, b) => b - a);
    if (tiers.isEmpty) return null;

    final picked = byQuality[tiers.first]!;
    final videoUrl = picked['baseUrl']?.toString() ?? '';
    if (videoUrl.isEmpty) return null;
    List<String> backupsOf(Map<dynamic, dynamic> v) => [
      for (final url in (v['backupUrl'] as List?) ?? const <dynamic>[])
      if (url.toString().isNotEmpty) url.toString(),
    ];
    final options = [
      for (final id in tiers)
        MusicStreamOption(
          quality: id,
          url: byQuality[id]!['baseUrl']?.toString() ?? '',
          codecs: byQuality[id]!['codecs']?.toString() ?? '',
          backupUrls: backupsOf(byQuality[id]!),
        ),
    ];

    Map<dynamic, dynamic>? pickAudio() {
      // 30280 = 192k, 30232 = 132k, 30216 = 64k. Dolby / Hi-Res need codec
      // support not every box has, so the ordinary tiers come first.
      const preference = [30280, 30232, 30216];
      for (final id in preference) {
        for (final audio in audios) {
          if (int.tryParse(audio['id']?.toString() ?? '') == id) return audio;
        }
      }
      return audios.isEmpty ? null : audios.last;
    }

    final audio = pickAudio();
    return MusicPlayUrls(
      videoUrl: videoUrl,
      audioUrl: audio?['baseUrl']?.toString(),
      videoBackupUrls: backupsOf(picked),
      quality: tiers.first,
      videoOptions: options,
    );
  }

  /// Human label for a bilibili quality id.
  static String qualityLabel(int quality) {
    return switch (quality) {
      127 => '8K',
      126 => '杜比视界',
      125 => 'HDR',
      120 => '4K',
      116 => '1080P60',
      112 => '1080P+',
      80 => '1080P',
      74 => '720P60',
      64 => '720P',
      32 => '480P',
      16 => '360P',
      _ => '',
    };
  }
}
