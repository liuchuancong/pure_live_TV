import 'package:pure_live/modules/media/api/bilibili_api_client.dart';
import 'package:pure_live/modules/media/models/models.dart';
import 'package:pure_live/player/core/playback_header_resolver.dart';
import 'package:pure_live/shared/common/http_client.dart';

/// The bilibili UGC endpoints the music mode reads.
///
/// Everything here runs against the *video* site (api.bilibili.com), not the
/// live site, but it rides on the same stored bilibili cookie and the same WBI
/// signer the live site maintains — one login serves both modes. The request
/// plumbing lives in [BilibiliApiClient]; this file owns the playback and
/// feed reads.
///
/// Two risk-control lessons from the reference TV client are baked in:
/// - playurl uses the plain `/x/player/playurl` endpoint, never the WBI one
///   (the signed variant trips `v_voucher` after a couple of plays);
/// - guest requests carry the anonymous-preview params instead of a login.
class BilibiliMusicApi {
  BilibiliMusicApi._();

  static final BilibiliMusicApi instance = BilibiliMusicApi._();

  final BilibiliApiClient _client = BilibiliApiClient.instance;

  /// The headers the CDN asks for when fetching the media streams themselves.
  ///
  /// Delegates to the central per-platform policy ([PlaybackHeaderResolver]):
  /// same cookie + buvid fallback and UA as live playback, only the Referer is
  /// the video page. Guests keep playing through the anonymous buvid cookie.
  Future<Map<String, String>> streamHeaders(String bvid) {
    return PlaybackHeaderResolver.resolveVod(bvid: bvid);
  }

  Map<String, String> _guestParams() => const {
    'web_location': '1315873',
    'gaia_source': 'pre-load',
    'isGaiaAvoided': 'true',
    'try_look': '1',
  };

  /// The music region leaderboard. Guest-friendly, no paging (fixed list).
  Future<List<MusicArchive>> getMusicRanking() => getRegionRanking(rid: 3);

  /// Any region's leaderboard (`ranking/v2?rid=`) — the guest-readable
  /// endpoint the region browser and the ranking tabs ride on.
  Future<List<MusicArchive>> getRegionRanking({required int rid}) async {
    final result = await HttpClient.instance.getJson(
      'https://api.bilibili.com/x/web-interface/ranking/v2',
      queryParameters: {'rid': '$rid', 'type': 'all'},
      header: await _client.headers(),
    );
    if (result['code'] != 0) {
      throw Exception('ranking failed: ${result['code']} ${result['message']}');
    }
    final list = (result['data']?['list'] as List?) ?? const [];
    return [for (final item in list) MusicArchive.fromRankingJson(item)];
  }

  /// The general popular feed, paged. Guest-friendly.
  Future<List<MusicArchive>> getPopularVideos({required int page, int pageSize = 12}) async {
    final result = await HttpClient.instance.getJson(
      'https://api.bilibili.com/x/web-interface/popular',
      queryParameters: {'pn': page.toString(), 'ps': pageSize.toString()},
      header: await _client.headers(),
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
    final params = await _client.wbiSign(url);
    final result = await HttpClient.instance.getJson(baseUrl, queryParameters: params, header: await _client.headers());
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
      header: await _client.headers(),
    );
    if (result['code'] != 0) {
      throw Exception('related failed: ${result['code']} ${result['message']}');
    }
    // The endpoint answered `data` as the bare list before, `data.list` today.
    final dynamic data = result['data'];
    final list = data is List ? data : (data?['list'] as List?) ?? const [];
    return [for (final item in list) MusicArchive.fromRelatedJson(item)];
  }

  /// Video search (the same endpoint the search page uses, typed `video`).
  ///
  /// Requires the WBI signature; the referer switches to the search host.
  Future<List<MusicArchive>> searchVideos(String keyword, {int page = 1, int pageSize = 20}) async {
    const baseUrl = 'https://api.bilibili.com/x/web-interface/wbi/search/type';
    final url =
        '$baseUrl?search_type=video&keyword=${Uri.encodeQueryComponent(keyword)}'
        '&order=totalrank&page=$page&page_size=$pageSize&highlight=1&single_column=0';
    final params = await _client.wbiSign(url);
    final result = await HttpClient.instance.getJson(
      baseUrl,
      queryParameters: params,
      header: await _client.headers(referer: 'https://search.bilibili.com/'),
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
      header: await _client.headers(),
    );
    if (result['code'] != 0) {
      throw Exception('music archive detail failed: ${result['code']} ${result['message']}');
    }
    return MusicArchive.fromViewJson(result['data']);
  }

  /// Playback URLs for one part.
  ///
  /// The muxed mp4 route only (`fnval=0` + `format=mp4` + `platform=html5`):
  /// bilibili merges video and audio server-side into a single `durl` mp4 that
  /// every backend plays with no attachment machinery. The DASH route (separate
  /// video/audio m4s streams) was removed on 2026-09-29 — its CDN dispatch
  /// increasingly hands out COS/edge-cloud nodes that answer ffmpeg-based
  /// players with HTTP 400 (measured: `os=bcache` demuxed in 250ms while
  /// `os=cosbv`/`estgcos`/`estgoss` refused every header combination), and no
  /// client-side selection could route around that reliably. The trade is the
  /// rendition ceiling — no 4K / high-bitrate tiers and no per-tier rendition
  /// list — the same shape every ExoPlayer-based bilibili client gets.
  Future<MusicPlayUrls> getPlayUrls({required String bvid, required int cid}) async {
    final params = <String, String>{
      'bvid': bvid,
      'cid': cid.toString(),
      'qn': '80',
      'fnval': '0',
      'fnver': '0',
      'fourk': '1',
      'platform': 'html5',
      'format': 'mp4',
      'type': 'video',
      'otype': 'json',
      'high_quality': '1',
      if (!_client.loggedIn) ..._guestParams(),
    };
    final result = await HttpClient.instance.getJson(
      'https://api.bilibili.com/x/player/playurl',
      queryParameters: params,
      header: await _client.headers(referer: 'https://www.bilibili.com/video/$bvid/'),
    );
    if (result['code'] != 0) {
      throw Exception('music playurl failed: ${result['code']} ${result['message']}');
    }
    final data = result['data'] as Map<dynamic, dynamic>? ?? {};

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
