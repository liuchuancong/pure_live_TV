import 'package:pure_live/platforms/bilibili/bilibili_site.dart';
import 'package:pure_live/shared/common/http_client.dart';

/// Lyrics for music mode, ported from the bilibilimusic reference project's
/// chain plus the netease fallback this app already had:
///
/// 1. bilibili BGM (official music library): `player/wbi/v2`'s `bgm_info.music_id` →
///    `copyright-music-publicity/bgm/detail`'s lyric — the source the reference
///    app prefers, because it is the uploader's own BGM metadata;
/// 2. third-party LRC API list (lrc.cx / rangotec, the reference's `lyricApiList`);
/// 3. netease search + lyric (this app's original fallback).
///
/// All results are cached per title for the session — misses too, so a
/// lyric-less track does not refetch every open.
class MusicLyricService {
  MusicLyricService._();

  static final MusicLyricService instance = MusicLyricService._();

  final Map<String, String?> _cache = {};

  /// Shares the buvid and WBI key caches with the live/music sites.
  final BiliBiliSite _site = BiliBiliSite();

  /// The third-party LRC endpoints, in preference order (reference:
  /// settings_service.dart `lyricApiList`). `{title}` / `{artist}` are replaced.
  static const List<String> _lrcApis = [
    'https://api.lrc.cx/lrc?title={title}&artist={artist}',
    'https://tools.rangotec.com/api/anon/lrc?title={title}&artist={artist}',
  ];

  static const Map<String, String> _headers = {
    'user-agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0.0.0 Safari/537.36',
    'referer': 'https://music.163.com/',
  };

  /// LRC text for the track. [title] is the part name; [hint] joins the query
  /// when the bare title is too generic; [aid]/[bvid]/[cid] enable the bilibili
  /// BGM chain when available.
  Future<String?> fetchLyric(
    String title, {
    String hint = '',
    int aid = 0,
    String bvid = '',
    int cid = 0,
  }) async {
    final key = title;
    if (_cache.containsKey(key)) return _cache[key];

    String? lyric;
    try {
      lyric = await _fetchBgmLyric(aid: aid, bvid: bvid, cid: cid);
    } catch (_) {}
    lyric ??= await _fetchLrcApiLyric(title, hint);
    lyric ??= await _fetchNeteaseLyric(title, hint);
    _cache[key] = lyric;
    return lyric;
  }

  /// The bilibili BGM chain: the archive's own background-music metadata.
  Future<String?> _fetchBgmLyric({required int aid, required String bvid, required int cid}) async {
    if (cid <= 0) return null;
    final header = await _site.getHeader();
    final signed = await _site.getWbiSign(
      'https://api.bilibili.com/x/player/wbi/v2?aid=$aid&bvid=$bvid&cid=$cid',
    );
    final player = await HttpClient.instance.getJson(
      'https://api.bilibili.com/x/player/wbi/v2',
      queryParameters: signed,
      header: header,
    );
    final musicId = player['data']?['bgm_info']?['music_id']?.toString() ?? '';
    if (musicId.isEmpty) return null;

    final detail = await HttpClient.instance.getJson(
      'https://api.bilibili.com/x/copyright-music-publicity/bgm/detail',
      queryParameters: {'music_id': musicId, 'relation_from': 'bgm_page'},
      header: header,
    );
    final lyric = detail['data']?['mv_lyric']?.toString() ?? '';
    return _normalize(lyric);
  }

  /// The third-party LRC list: first endpoint that answers with something that
  /// looks like timed lyrics wins.
  Future<String?> _fetchLrcApiLyric(String title, String hint) async {
    final cleaned = cleanTitle(title);
    for (final template in _lrcApis) {
      try {
        final url = template
            .replaceFirst('{title}', Uri.encodeQueryComponent(cleaned))
            .replaceFirst('{artist}', Uri.encodeQueryComponent(hint));
        final text = await HttpClient.instance.getText(url, header: _headers);
        final lyric = _normalize(text);
        if (lyric != null) return lyric;
      } catch (_) {
        // Next endpoint.
      }
    }
    return null;
  }

  /// The netease chain this app shipped first.
  Future<String?> _fetchNeteaseLyric(String title, String hint) async {
    try {
      final songId = await _searchSongId(title, hint);
      if (songId == null) return null;
      final result = await HttpClient.instance.getJson(
        'https://music.163.com/api/song/lyric',
        queryParameters: {'id': songId.toString(), 'lv': '1', 'kv': '1', 'tv': '-1'},
        header: _headers,
      );
      return _normalize(result['lrc']?['lyric']?.toString() ?? '');
    } catch (_) {
      return null;
    }
  }

  Future<int?> _searchSongId(String title, String hint) async {
    final queries = [title, if (hint.isNotEmpty && hint != title) '$title $hint'];
    for (final query in queries) {
      try {
        final result = await HttpClient.instance.getJson(
          'https://music.163.com/api/search/get/web',
          queryParameters: {'s': query, 'type': '1', 'limit': '5'},
          header: _headers,
        );
        final songs = (result['result']?['songs'] as List?) ?? const [];
        if (songs.isEmpty) continue;
        final normalized = cleanTitle(title).toLowerCase();
        for (final song in songs) {
          final name = song['name']?.toString().toLowerCase() ?? '';
          if (normalized.isNotEmpty && name.contains(normalized)) {
            return int.tryParse(song['id']?.toString() ?? '');
          }
        }
        return int.tryParse(songs.first['id']?.toString() ?? '');
      } catch (_) {
        // Try the next query shape.
      }
    }
    return null;
  }

  /// Accepts only text with timed lines, and normalizes the timestamp shapes
  /// the reference project converts (`[mm:ss,mmm]`, `[hh:mm:ss.mmm]`) into the
  /// `[mm:ss.xx]` flutter_lyric parses.
  String? _normalize(String raw) {
    if (raw.trim().isEmpty || !raw.contains('[00:')) return null;
    var text = raw.replaceAll('\r\n', '\n');
    text = text.replaceAllMapped(RegExp(r'\[(\d{1,2}):(\d{1,2})[,:.](\d{1,3})\]'), (m) {
      final mm = m.group(1)!.padLeft(2, '0');
      final ss = m.group(2)!.padLeft(2, '0');
      var frac = m.group(3)!;
      // 1-3 digit fraction → centiseconds.
      final fracMs = int.tryParse(frac.padRight(3, '0').substring(0, 3)) ?? 0;
      final cs = (fracMs / 10).round().clamp(0, 99).toString().padLeft(2, '0');
      return '[$mm:$ss.$cs]';
    });
    return text.contains(RegExp(r'\[\d{2}:\d{2}\.\d{2}\]')) ? text : null;
  }

  /// Strips the decoration bilibili uploaders put in part names: 【】 brackets,
  /// parenthesised credits and runs of whitespace.
  static String cleanTitle(String title) {
    var text = title;
    text = text.replaceAll(RegExp(r'【[^】]*】|\([^)]*\)|\[[^\]]*\]'), ' ');
    text = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    return text;
  }
}
