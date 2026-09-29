import 'package:pure_live/modules/media/api/bilibili_api_client.dart';
import 'package:pure_live/modules/media/api/bilibili_music_api.dart';
import 'package:pure_live/modules/media/models/models.dart';
import 'package:pure_live/shared/common/http_client.dart';

/// The bilibili PGC (影视/番剧) layer, newBV's pgc sections: the season
/// feed, the season detail with its episode list, and the episode playurl.
///
/// The web playurl for PGC shares the DASH shape with UGC, so the answer is
/// converted into the shared [MusicPlayUrls] model and handed to the common
/// VOD engine — the video module injects [resolvePlayUrls] as the
/// `modulePlayUrlResolver` hook. A paid episode answers with a preview range
/// as a guest; the muxed durl fallback covers it the same way UGC does.
class BilibiliPgcApi {
  BilibiliPgcApi._();

  static final BilibiliPgcApi instance = BilibiliPgcApi._();

  final BilibiliApiClient _client = BilibiliApiClient.instance;

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

  /// Feed names by the page's category id: 1 番剧, 2 国创, 3 纪录片, 4 电影,
  /// 5 电视剧.
  static const Map<int, String> _feedNames = {
    1: 'anime',
    2: 'guochuang',
    3: 'documentary',
    4: 'movie',
    5: 'tv',
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

  /// The logged-in user's followed seasons (追番/追剧,
  /// `x/space/bangumi/follow/list`). [type]: 1 bangumi, 2 drama.
  Future<List<PgcItem>> getFollowedSeasons({int type = 1, int page = 1, int pageSize = 20}) async {
    _client.ensureLogin();
    final data = await _tryGet('https://api.bilibili.com/x/space/bangumi/follow/list', query: {
      'vmid': '${_client.myMid}',
      'type': '$type',
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

  /// Playback URLs for one episode, converted into the shared playurl model.
  Future<MusicPlayUrls> getPlayUrls({required int epId, required int cid}) async {
    final result = await HttpClient.instance.getJson(
      'https://api.bilibili.com/pgc/player/web/playurl',
      queryParameters: {
        'ep_id': '$epId',
        'cid': '$cid',
        'qn': '127',
        'fnval': '4048',
        'fnver': '0',
        'fourk': '1',
        'try_look': '1',
      },
      header: await _client.headers(),
    );
    if (result is! Map || result['code'] != 0) {
      final message = result is Map ? result['message'] ?? result['msg'] : result;
      throw Exception('pgc playurl failed: $message');
    }
    final data = result['data'] as Map<dynamic, dynamic>? ?? {};
    final dash = data['dash'] as Map<dynamic, dynamic>?;

    if (dash != null) {
      // The UGC DASH picker is identical for PGC answers.
      final urls = _pickDash(dash, servedQuality: int.tryParse(data['quality']?.toString() ?? '') ?? 0);
      if (urls != null) return urls;
    }
    final durl = data['durl'] as List?;
    if (durl != null && durl.isNotEmpty) {
      return MusicPlayUrls(
        videoUrl: durl.first['url']?.toString() ?? '',
        quality: int.tryParse(data['quality']?.toString() ?? '') ?? 0,
        isDash: false,
      );
    }
    throw Exception('pgc playurl: no playable stream');
  }

  /// Same AVC-first quality picker as [BilibiliMusicApi] uses, including its
  /// `bestUrlOf` mcdn-edge avoidance — one stream-selection policy for every
  /// DASH answer in the app.
  MusicPlayUrls? _pickDash(Map<dynamic, dynamic> dash, {required int servedQuality}) {
    final videos = (dash['video'] as List?) ?? const [];
    final audios = (dash['audio'] as List?) ?? const [];
    if (videos.isEmpty) return null;

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

    List<String> backupsOf(Map<dynamic, dynamic> v) => [
      for (final url in (v['backupUrl'] as List?) ?? const <dynamic>[])
      if (url.toString().isNotEmpty) url.toString(),
    ];
    final picked = byQuality[tiers.first]!;
    final videoUrl = BilibiliMusicApi.bestUrlOf(picked);
    if (videoUrl.isEmpty) return null;
    final options = [
      for (final id in tiers)
        MusicStreamOption(
          quality: id,
          url: BilibiliMusicApi.bestUrlOf(byQuality[id]!),
          codecs: byQuality[id]!['codecs']?.toString() ?? '',
          backupUrls: backupsOf(byQuality[id]!),
        ),
    ];
    Map<dynamic, dynamic>? pickAudio() {
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
      audioUrl: audio == null ? null : BilibiliMusicApi.bestUrlOf(audio),
      videoBackupUrls: backupsOf(picked),
      quality: tiers.first,
      videoOptions: options,
    );
  }
}
