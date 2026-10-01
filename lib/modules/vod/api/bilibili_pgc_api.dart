import 'dart:convert';

import 'package:pure_live/modules/vod/api/bilibili_api_client.dart';
import 'package:pure_live/modules/vod/models/models.dart';
import 'package:pure_live/core/common/http_client.dart';

/// feed, the season detail with its episode list, and the episode playurl.
///
/// The web playurl answer is converted into the shared [MusicPlayUrls] model
/// and handed to the common VOD engine — the video module injects
/// [resolvePlayUrls] as the `modulePlayUrlResolver` hook. A paid episode
/// answers with a preview range as a guest; the muxed mp4 durl covers it the
/// same way UGC does.
class BilibiliPgcApi {
  BilibiliPgcApi._();

  static final BilibiliPgcApi instance = BilibiliPgcApi._();

  final BilibiliApiClient _client = BilibiliApiClient.instance;

  /// The 追番 toggle's login gate.
  bool get isLoggedIn => _client.loggedIn;

  Future<Map<dynamic, dynamic>?> _tryGet(String url, {Map<String, String>? query}) async {
    try {
      final result = await HttpClient.instance.getJson(url, queryParameters: query, header: await _client.headers());
      if (result is Map && result['code'] == 0) return result['data'] ?? result['result'];
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Per-category feed cursors: the working web feed (`pgc/page/web/feed`,
  /// newBV's `getPgcFeed` — no WBI needed) is cursor-based, while the paging
  /// layer is page-based; the last cursor per category bridges the two. The
  /// old `pgc/api/web/index/feed` endpoint answers 404 since Bilibili retired
  /// it, and the season index result needs WBI — this feed is the only
  /// guest-readable source left.
  final Map<String, int> _feedCursor = {};

  static const Map<int, String> _feedNames = {
    1: 'anime',
    2: 'guochuang',
    3: 'documentary',
    4: 'movie',
    5: 'tv',
    6: 'variety',
  };

  Future<List<PgcItem>> getFeed({required int pgcType, int page = 1, int pageSize = 20}) async {
    final name = _feedNames[pgcType] ?? 'movie';
    final cursor = page <= 1 ? 0 : (_feedCursor[name] ?? 0);

    // 1) The flat web feed serves guochuang / documentary / movie / tv.
    var items = await _webFeedPage(name, cursor);

    // 2) Anime and guochuang ride the v3 ranking feed — its cards are nested
    //    in rank sections (`items[].sub_items`), flattened here.
    if (items.isEmpty) {
      items = await _v3FeedPage(name, cursor);
    }

    // A page past the feed's end returns nothing new: signal the end so the
    // paging layer stops instead of stacking duplicates.
    if (items.isEmpty && page > 1) return const [];
    return items;
  }

  /// The flat web feed page (`pgc/page/web/feed`), or an empty list.
  Future<List<PgcItem>> _webFeedPage(String name, int cursor) async {
    final feed = await _tryGet('https://api.bilibili.com/pgc/page/web/feed', query: {
      'name': name,
      'coursor': '$cursor',
      'new_cursor_status': 'true',
    });
    if (feed == null) return const [];
    _feedCursor[name] = int.tryParse(feed['coursor']?.toString() ?? '') ?? 0;
    return [for (final item in (feed['items'] as List?) ?? const []) PgcItem.fromJson(item)];
  }

  /// The v3 ranking feed page (`pgc/page/web/v3/feed`), flattened.
  Future<List<PgcItem>> _v3FeedPage(String name, int cursor) async {
    final feed = await _tryGet('https://api.bilibili.com/pgc/page/web/v3/feed', query: {
      'name': name,
      'coursor': '$cursor',
    });
    if (feed == null) return const [];
    _feedCursor[name] = int.tryParse(feed['coursor']?.toString() ?? '') ?? 0;
    final out = <PgcItem>[];
    final seen = <int>{};
    for (final section in (feed['items'] as List?) ?? const []) {
      if (section is! Map) continue;
      for (final card in (section['sub_items'] as List?) ?? const []) {
        if (card is! Map) continue;
        final item = PgcItem.fromJson(Map<String, dynamic>.from(card));
        if (item.seasonId != 0 && !seen.add(item.seasonId)) continue;
        out.add(item);
      }
    }
    return out;
  }

  /// `x/space/bangumi/follow/list`). [type]: 1 bangumi, 2 drama;
  /// [followStatus]: 0 all, 1 想看, 2 在看, 3 看过 (the reference's filter dialog).
  Future<List<PgcItem>> getFollowedSeasons({int type = 1, int followStatus = 0, int page = 1, int pageSize = 20}) async {
    _client.ensureLogin();
    final data = await _tryGet('https://api.bilibili.com/x/space/bangumi/follow/list', query: {
      'vmid': '${_client.myMid}',
      'type': '$type',
      if (followStatus != 0) 'follow_status': '$followStatus',
      'pn': '$page',
      'ps': '$pageSize',
    });
    return [for (final item in (data?['list'] as List?) ?? const []) PgcItem.fromJson(item)];
  }

  /// The full season detail by season id or episode id (`pgc/view/web/season`).
  Future<PgcSeason> getSeasonDetail({int? seasonId, int? epId}) async {
    final data = await _tryGet('https://api.bilibili.com/pgc/view/web/season', query: {
      if (seasonId != null) 'season_id': '$seasonId',
      if (epId != null) 'ep_id': '$epId',
    });
    if (data == null) {
      throw Exception('pgc season detail failed');
    }
    return PgcSeason.fromJson(Map<String, dynamic>.from(data));
  }

  /// 追番 — the pair of newBV's follow toggle (`pgc/web/follow/add`).
  Future<void> followSeason({required int seasonId}) async {
    await _client.postForm(
      'https://api.bilibili.com/pgc/web/follow/add',
      {'season_id': '$seasonId'},
      referer: 'https://www.bilibili.com/',
    );
  }

  Future<void> unfollowSeason({required int seasonId}) async {
    await _client.postForm(
      'https://api.bilibili.com/pgc/web/follow/del',
      {'season_id': '$seasonId'},
      referer: 'https://www.bilibili.com/',
    );
  }

  /// The category page's 轮播 (newBV's `getPgcWebInitialStateData`): the
  /// banner items only live in the SSR page's `__INITIAL_STATE__`, and the
  /// 影视 categories carry their ids in the link (`…/play/ss12345`) instead
  /// of a `season_id` field.
  Future<List<PgcItem>> getBanners(int pgcType) async {
    final name = _feedNames[pgcType];
    if (name == null) return const [];
    try {
      final html = await HttpClient.instance.getText(
        'https://www.bilibili.com/$name',
        header: await _client.headers(referer: 'https://www.bilibili.com/'),
      );
      final marker = '__INITIAL_STATE__=';
      final start = html.indexOf(marker);
      final end = html.indexOf(';(function', start);
      if (start < 0 || end <= start) return const [];
      final decoded = jsonDecode(html.substring(start + marker.length, end));
      final modules = decoded is Map ? decoded['modules'] : null;
      final banner = modules is Map ? modules['banner'] : null;
      if (banner is! Map) return const [];
      final parseFromLink = const [1668, 1675, 1682].contains(banner['module_id']);
      final out = <PgcItem>[];
      for (final item in (banner['items'] as List?) ?? const []) {
        if (item is! Map) continue;
        var seasonId = lenientIntOf(item['season_id']);
        final link = item['link']?.toString() ?? '';
        if (seasonId <= 0 && parseFromLink) {
          final seg = link.split('/').where((s) => s.isNotEmpty).last;
          if (seg.startsWith('ss')) seasonId = int.tryParse(seg.substring(2)) ?? 0;
        }
        if (seasonId <= 0) continue;
        var cover = (item['big_cover'] ?? item['cover'])?.toString() ?? '';
        if (cover.startsWith('//')) cover = 'https:$cover';
        out.add(PgcItem(seasonId: seasonId, title: item['title']?.toString() ?? '', cover: cover));
      }
      return out;
    } catch (_) {
      return const [];
    }
  }

  /// Playback URLs for one episode, converted into the shared playurl model.
  ///
  /// The muxed mp4 route only (`fnval=0`): bilibili merges video and audio
  /// server-side into a single `durl` mp4 — the same policy the UGC endpoint
  /// rides since the DASH route was removed (its COS/edge-cloud CDN dispatch
  /// answers ffmpeg-based players with HTTP 400). A paid episode answers with
  /// a preview range as a guest; the single-segment durl covers it the same
  /// way UGC does.
  Future<MusicPlayUrls> getPlayUrls({required int epId, required int cid}) async {
    final result = await HttpClient.instance.getJson(
      'https://api.bilibili.com/pgc/player/web/playurl',
      queryParameters: {
        'ep_id': '$epId',
        'cid': '$cid',
        'qn': '80',
        'fnval': '0',
        'fnver': '0',
        'fourk': '1',
        'platform': 'html5',
        'format': 'mp4',
        'type': 'video',
        'otype': 'json',
        'high_quality': '1',
        'try_look': '1',
      },
      header: await _client.headers(),
    );
    if (result is! Map || result['code'] != 0) {
      final message = result is Map ? result['message'] ?? result['msg'] : result;
      throw Exception('pgc playurl failed: $message');
    }
    final data = result['data'] as Map<dynamic, dynamic>? ?? {};
    final durl = data['durl'] as List?;
    if (durl != null && durl.isNotEmpty) {
      final order = (durl.first['order'] ?? 1) as int;
      if (durl.length == 1 || order > 1) {
        return MusicPlayUrls(
          videoUrl: durl.first['url']?.toString() ?? '',
          quality: int.tryParse(data['quality']?.toString() ?? '') ?? 0,
          isDash: false,
        );
      }
    }
    throw Exception('pgc playurl: no playable stream');
  }
}
