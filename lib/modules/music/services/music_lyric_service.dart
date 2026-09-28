import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:pure_live/platforms/bilibili/bilibili_site.dart';
import 'package:pure_live/shared/common/http_client.dart';

/// Lyrics for music mode, ported from the bilibilimusic reference project's
/// chain plus the netease fallback this app already had:
///
/// 1. bilibili BGM (official music library): `player/wbi/v2`'s `bgm_info.music_id` →
///    `copyright-music-publicity/bgm/detail`'s lyric — the source the reference
///    app prefers, because it is the uploader's own BGM metadata;
/// 2. third-party LRC APIs (lrc.cx, rangotec — the reference's `lyricApiList`);
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
  ///
  /// lrc.cx serves plain LRC text from `/lyrics` (`/lrc` — what this list used
  /// to ask for — answers 404); rangotec wraps the same text in a JSON envelope.
  static const List<({String url, bool json})> _lrcApis = [
    (url: 'https://api.lrc.cx/lyrics?title={title}&artist={artist}', json: false),
    (url: 'https://tools.rangotec.com/api/anon/lrc?title={title}&artist={artist}', json: true),
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

  /// One body from an endpoint the chain is allowed to find nothing at.
  ///
  /// A `404` here is an answer, not a failure: routing these probes through the
  /// shared request helpers printed a full HTTP-error banner for every track the
  /// first endpoint did not know.
  static Future<String?> _probe(String url, {Map<String, String>? header}) async {
    try {
      final response = await HttpClient.instance.dio.get<dynamic>(
        url,
        options: Options(responseType: ResponseType.plain, headers: header, validateStatus: (_) => true),
      );
      if (response.statusCode != 200) return null;
      final data = response.data;
      return data is String ? data : data?.toString();
    } catch (_) {
      return null;
    }
  }

  static String _withQuery(String url, Map<String, dynamic> query) {
    final values = <String, String>{
      for (final entry in query.entries)
        if (entry.value != null) entry.key: entry.value.toString(),
    };
    return Uri.parse(url).replace(queryParameters: values).toString();
  }

  static dynamic _decode(String body) {
    try {
      return jsonDecode(body);
    } catch (_) {
      return null;
    }
  }

  /// The bilibili BGM chain: the archive's own background-music metadata.
  Future<String?> _fetchBgmLyric({required int aid, required String bvid, required int cid}) async {
    if (cid <= 0) return null;
    final header = await _site.getHeader();
    final signed = await _site.getWbiSign('https://api.bilibili.com/x/player/wbi/v2?aid=$aid&bvid=$bvid&cid=$cid');
    final playerBody = await _probe(
      _withQuery('https://api.bilibili.com/x/player/wbi/v2', signed),
      header: header,
    );
    if (playerBody == null) return null;
    final player = _decode(playerBody);
    final playerData = player is Map ? player['data'] : null;
    final bgm = playerData is Map ? playerData['bgm_info'] : null;
    final musicId = bgm is Map ? bgm['music_id']?.toString() ?? '' : '';
    if (musicId.isEmpty) return null;

    final detailBody = await _probe(
      _withQuery('https://api.bilibili.com/x/copyright-music-publicity/bgm/detail', {
        'music_id': musicId,
        'relation_from': 'bgm_page',
      }),
      header: header,
    );
    if (detailBody == null) return null;
    final detail = _decode(detailBody);
    final detailData = detail is Map ? detail['data'] : null;
    final lyric = detailData is Map ? detailData['mv_lyric']?.toString() ?? '' : '';
    return _normalize(lyric);
  }

  /// The third-party LRC list: first endpoint that answers with something that
  /// looks like timed lyrics wins.
  Future<String?> _fetchLrcApiLyric(String title, String hint) async {
    final cleaned = cleanTitle(title);
    for (final api in _lrcApis) {
      final url = api.url
          .replaceFirst('{title}', Uri.encodeQueryComponent(cleaned))
          .replaceFirst('{artist}', Uri.encodeQueryComponent(hint));
      final body = await _probe(url, header: _headers);
      if (body == null) continue;
      final text = api.json ? _envelopeLyric(body) : body;
      if (text == null) continue;
      final lyric = _normalize(text);
      if (lyric != null) return lyric;
    }
    return null;
  }

  /// Pulls the LRC out of a JSON envelope: rangotec answers
  /// `{"code":200,"data":[{"lrc":"…"}]}`, lrc.cx's `/jsonapi` a plain object.
  static String? _envelopeLyric(String body) {
    final decoded = _decode(body);
    if (decoded is Map) {
      final data = decoded['data'];
      if (data is List && data.isNotEmpty && data.first is Map) {
        final lrc = (data.first as Map)['lrc'];
        if (lrc != null) return lrc.toString();
      }
      if (data is Map && data['lrc'] != null) return data['lrc'].toString();
      for (final String key in const ['lrc', 'lyric']) {
        if (decoded[key] != null) return decoded[key].toString();
      }
    }
    return null;
  }

  /// The netease chain this app shipped first.
  Future<String?> _fetchNeteaseLyric(String title, String hint) async {
    final songId = await _searchSongId(title, hint);
    if (songId == null) return null;
    final body = await _probe(
      _withQuery('https://music.163.com/api/song/lyric', {'id': songId, 'lv': '1', 'kv': '1', 'tv': '-1'}),
      header: _headers,
    );
    if (body == null) return null;
    final result = _decode(body);
    final lrc = result is Map ? result['lrc'] : null;
    final lyric = lrc is Map ? lrc['lyric']?.toString() ?? '' : '';
    return _normalize(lyric);
  }

  Future<int?> _searchSongId(String title, String hint) async {
    final queries = [title, if (hint.isNotEmpty && hint != title) '$title $hint'];
    for (final query in queries) {
      final body = await _probe(
        _withQuery('https://music.163.com/api/search/get/web', {'s': query, 'type': '1', 'limit': '5'}),
        header: _headers,
      );
      if (body == null) continue;
      final result = _decode(body);
      final resultData = result is Map ? result['result'] : null;
      final songs = (resultData is Map ? resultData['songs'] as List? : null) ?? const [];
      if (songs.isEmpty) continue;
      final normalized = cleanTitle(title).toLowerCase();
      for (final song in songs) {
        final name = song['name']?.toString().toLowerCase() ?? '';
        if (normalized.isNotEmpty && name.contains(normalized)) {
          return int.tryParse(song['id']?.toString() ?? '');
        }
      }
      return int.tryParse(songs.first['id']?.toString() ?? '');
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
