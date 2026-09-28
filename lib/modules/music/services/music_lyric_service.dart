import 'dart:convert';

import 'package:dio/dio.dart';
import 'package:pure_live/platforms/bilibili/bilibili_site.dart';
import 'package:pure_live/shared/common/http_client.dart';
import 'package:pure_live/shared/utils/string_similarity.dart';

/// Lyrics for music mode, ported from the bilibilimusic reference project's
/// chain plus the netease fallback this app already had:
///
/// 1. bilibili BGM (official music library): `player/wbi/v2`'s `bgm_info.music_id` →
///    `copyright-music-publicity/bgm/detail`'s lyric — the source the reference
///    app prefers, because it is the uploader's own BGM metadata;
/// 2. third-party LRC APIs (lrc.cx, rangotec — the reference's `lyricApiList`);
/// 3. netease search + lyric (this app's original fallback).
///
/// **Every candidate is checked against the track before its lyric is used.** The
/// APIs answer with their best fuzzy guess, and a compilation's part name
/// (「002. 可能」) or an uploader's background music gets a *different* song back —
/// a wrong lyric is worse than none, so an unmatched candidate is dropped and the
/// page shows 暂无歌词 instead.
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
  /// lrc.cx serves plain LRC text from `/lyrics` (`/lrc` — what this list used to
  /// ask for — answers 404); rangotec wraps the same text in a JSON envelope that
  /// carries the candidate's own title.
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

    // The query is the track name alone: a compilation part is named 「002. 可能」
    // and every source below would otherwise search for that literal string.
    final query = cleanTitle(title);
    if (query.isEmpty) {
      _cache[key] = null;
      return null;
    }

    String? lyric;
    try {
      lyric = await _fetchBgmLyric(query, aid: aid, bvid: bvid, cid: cid);
    } catch (_) {}
    lyric ??= await _fetchLrcApiLyric(query, hint);
    lyric ??= await _fetchNeteaseLyric(query, hint);
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

  static String? _firstString(Map data, List<String> keys) {
    for (final key in keys) {
      final value = data[key]?.toString().trim() ?? '';
      if (value.isNotEmpty) return value;
    }
    return null;
  }

  /// The bilibili BGM chain: the archive's own background-music metadata.
  ///
  /// Checked like the others — a compilation's BGM is whatever the uploader laid
  /// under the video, not the track that plays, so a BGM whose own title
  /// disagrees with the part is not this part's lyric.
  Future<String?> _fetchBgmLyric(
    String query, {
    required int aid,
    required String bvid,
    required int cid,
  }) async {
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
    if (bgm is! Map) return null;

    final bgmTitle = _firstString(bgm, const ['music_title', 'title', 'song_title']);
    if (bgmTitle != null && !plausible(query, bgmTitle)) return null;

    final musicId = bgm['music_id']?.toString() ?? '';
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
    return verified(query, _normalize(lyric));
  }

  /// The third-party LRC list: first endpoint that answers with something that
  /// looks like timed lyrics for *this* track wins.
  Future<String?> _fetchLrcApiLyric(String query, String hint) async {
    for (final api in _lrcApis) {
      final url = api.url
          .replaceFirst('{title}', Uri.encodeQueryComponent(query))
          .replaceFirst('{artist}', Uri.encodeQueryComponent(hint));
      final body = await _probe(url, header: _headers);
      if (body == null) continue;
      final text = api.json ? _envelopeLyric(body, query) : body;
      final lyric = verified(query, _normalize(text ?? ''));
      if (lyric != null) return lyric;
    }
    return null;
  }

  /// Pulls the LRC out of a JSON envelope: rangotec answers
  /// `{"code":200,"data":[{"title":"…","lrc":"…"}]}`. The candidate's own title has
  /// to line up with the query — the list is a search result, not an answer.
  static String? _envelopeLyric(String body, String query) {
    final decoded = _decode(body);
    if (decoded is! Map) return null;

    final data = decoded['data'];
    if (data is List) {
      for (final entry in data) {
        if (entry is! Map) continue;
        final lrc = entry['lrc']?.toString() ?? '';
        if (lrc.isEmpty) continue;
        final title = entry['title']?.toString() ?? '';
        if (title.isEmpty || plausible(query, title)) return lrc;
      }
      return null;
    }
    if (data is Map) {
      final lrc = data['lrc']?.toString() ?? '';
      if (lrc.isNotEmpty) return lrc;
    }
    for (final key in const ['lrc', 'lyric']) {
      final lrc = decoded[key]?.toString() ?? '';
      if (lrc.isNotEmpty) return lrc;
    }
    return null;
  }

  /// The netease chain this app shipped first.
  Future<String?> _fetchNeteaseLyric(String query, String hint) async {
    final songId = await _searchSongId(query, hint);
    if (songId == null) return null;
    final body = await _probe(
      _withQuery('https://music.163.com/api/song/lyric', {'id': songId, 'lv': '1', 'kv': '1', 'tv': '-1'}),
      header: _headers,
    );
    if (body == null) return null;
    final result = _decode(body);
    final lrc = result is Map ? result['lrc'] : null;
    final lyric = lrc is Map ? lrc['lyric']?.toString() ?? '' : '';
    return verified(query, _normalize(lyric));
  }

  /// The id of the search hit whose name actually is the track, or `null`.
  ///
  /// The top hit used to be taken as-is: searching a part name like 「002. 可能」
  /// ranks 不可能 first, and the page then played a different song's words.
  Future<int?> _searchSongId(String query, String hint) async {
    for (final text in [query, if (hint.isNotEmpty && hint != query) '$query $hint']) {
      final body = await _probe(
        _withQuery('https://music.163.com/api/search/get/web', {'s': text, 'type': '1', 'limit': '10'}),
        header: _headers,
      );
      if (body == null) continue;
      final result = _decode(body);
      final resultData = result is Map ? result['result'] : null;
      final songs = (resultData is Map ? resultData['songs'] as List? : null) ?? const [];
      for (final song in songs) {
        if (song is! Map) continue;
        if (!plausible(query, song['name']?.toString() ?? '')) continue;
        final id = int.tryParse(song['id']?.toString() ?? '');
        if (id != null) return id;
      }
    }
    return null;
  }

  /// Drops an LRC whose own `[ti:]` tag names another song.
  ///
  /// These files carry the title they were made for; when that title does not
  /// line up with the track, the file belongs to something else. Files without
  /// the tag cannot be checked and stay.
  static String? verified(String query, String? lyric) {
    if (lyric == null) return null;
    final tag = _tagValue(lyric, 'ti');
    if (tag == null) return lyric;
    return plausible(query, tag) ? lyric : null;
  }

  static String? _tagValue(String lrc, String name) {
    final match = RegExp('\\[$name:([^\\]]*)\\]', caseSensitive: false).firstMatch(lrc);
    final value = match?.group(1)?.trim();
    return value == null || value.isEmpty ? null : value;
  }

  /// Whether [candidate] plausibly names the same song as [query].
  ///
  /// Equality, a shared prefix (「起风了」 / 「起风了 (旧版)」) or a high Sørensen-Dice
  /// score. Suffix-only overlap is not enough: 「不可能」 is not 「可能」.
  static bool plausible(String query, String candidate) {
    final a = _fold(query);
    final b = _fold(candidate);
    if (a.isEmpty || b.isEmpty) return true;
    if (a == b || a.startsWith(b) || b.startsWith(a)) return true;
    return compareTwoStrings(a, b) >= 0.7;
  }

  static String _fold(String text) =>
      text.toLowerCase().replaceAll(RegExp(r'[^\p{L}\p{N}]', unicode: true), '');

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

  /// The track name inside a part's title.
  ///
  /// Compilations number their parts (「002. 可能」, 「01 - 夜曲」, 「第 3 首 晴天」,
  /// 「P4 可能」) and that decoration is not part of the song: searching for it
  /// finds nothing, and the fuzzy APIs answer with a wrong song.
  static String cleanTitle(String title) {
    var text = title.trim();
    // Brackets first: 「【高音质】002、可能」 only shows its ordinal once the
    // decoration is gone.
    text = text.replaceAll(RegExp(r'【[^】]*】|\([^)]*\)|\[[^\]]*\]'), ' ').trim();
    // 「第 3 首」/「第三曲」 before the plain-number rule, which would eat the 第
    // and leave the classifier behind.
    text = text.replaceFirst(RegExp(r'^第\s*[0-9一二三四五六七八九十]{1,3}\s*[首曲集部]?\s*'), '');
    text = text.replaceFirst(RegExp(r'^p\s*\d{1,3}\s*[\.、\-—_:：]?\s*', caseSensitive: false), '');
    // A numbered part needs a separator or a zero-padded number: 「002. 可能」 and
    // 「002 可能」 are parts, while 「7 Years」 is a song that starts with a digit.
    text = text.replaceFirst(RegExp(r'^(?:\d{1,3}\s*[\.、\-—_:：]\s*|0\d{1,2}\s+)'), '');
    text = text.replaceAll(RegExp(r'\s+'), ' ').trim();
    return text.isEmpty ? title.trim() : text;
  }
}
