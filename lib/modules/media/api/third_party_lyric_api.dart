import 'dart:convert';

import 'package:dio/dio.dart' show Options, ResponseType;
import 'package:pure_live/shared/common/http_client.dart';

/// The third-party lyric sources behind the music mode's fallback chain: the
/// LRC aggregators (lrc.cx, rangotec — the bilibilimusic reference's
/// `lyricApiList`) and netease search/lyric. HTTP and response shapes only —
/// title verification and timestamp normalization stay in the music service,
/// which also owns the preference order between these sources.
class ThirdPartyLyricApi {
  ThirdPartyLyricApi._();

  static final ThirdPartyLyricApi instance = ThirdPartyLyricApi._();

  /// The browser-ish headers every probe here rides on. The netease referer
  /// works for the LRC aggregators too — it is what the chain shipped with.
  static const Map<String, String> _headers = {
    'user-agent':
        'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/126.0.0.0 Safari/537.36',
    'referer': 'https://music.163.com/',
  };

  /// lrc.cx's plain LRC text for the song, or null. A 404 is an answer ("not
  /// in the library"), not a failure — these probes must never surface an
  /// HTTP-error banner over the player.
  Future<String?> fetchLrcCx({required String title, required String artist}) async {
    final url = 'https://api.lrc.cx/lyrics'
        '?title=${Uri.encodeQueryComponent(title)}&artist=${Uri.encodeQueryComponent(artist)}';
    return _probe(url);
  }

  /// rangotec's JSON envelope `{"code":200,"data":[{"title","artist","lrc"}]}`
  /// flattened to its entries (capped at [limit]); defensive shapes — a
  /// single object or top-level `lrc`/`lyric` — come back as one entry with
  /// an empty title the caller cannot check against.
  Future<List<({String title, String artist, String lrc})>> fetchRangotec({
    required String title,
    required String artist,
    int limit = 6,
  }) async {
    final url = 'https://tools.rangotec.com/api/anon/lrc'
        '?title=${Uri.encodeQueryComponent(title)}&artist=${Uri.encodeQueryComponent(artist)}';
    final body = await _probe(url);
    final decoded = body == null ? null : _decode(body);
    if (decoded is! Map) return const [];

    final data = decoded['data'];
    if (data is List) {
      final out = <({String title, String artist, String lrc})>[];
      for (final entry in data) {
        if (out.length >= limit) break;
        if (entry is! Map) continue;
        final lrc = entry['lrc']?.toString() ?? '';
        if (lrc.isEmpty) continue;
        out.add((title: entry['title']?.toString() ?? '', artist: entry['artist']?.toString() ?? '', lrc: lrc));
      }
      return out;
    }
    if (data is Map) {
      final lrc = data['lrc']?.toString() ?? '';
      if (lrc.isNotEmpty) return [(title: '', artist: '', lrc: lrc)];
    }
    for (final key in const ['lrc', 'lyric']) {
      final lrc = decoded[key]?.toString() ?? '';
      if (lrc.isNotEmpty) return [(title: '', artist: '', lrc: lrc)];
    }
    return const [];
  }

  /// One netease search page: the raw song hits (`id`, `name`, artist) —
  /// the caller owns the title filtering.
  Future<List<({String id, String name, String artist})>> searchNeteaseSongs({
    required String text,
    int limit = 10,
  }) async {
    final body = await _probe(
      'https://music.163.com/api/search/get/web'
      '?s=${Uri.encodeQueryComponent(text)}&type=1&limit=$limit',
    );
    final result = body == null ? null : _decode(body);
    final resultData = result is Map ? result['result'] : null;
    final songs = (resultData is Map ? resultData['songs'] as List? : null) ?? const [];
    final out = <({String id, String name, String artist})>[];
    for (final song in songs) {
      if (song is! Map) continue;
      final id = song['id']?.toString() ?? '';
      if (id.isEmpty) continue;
      final artists = song['artists'];
      out.add((
        id: id,
        name: song['name']?.toString() ?? '',
        artist: artists is List && artists.isNotEmpty && artists.first is Map
            ? (artists.first as Map)['name']?.toString() ?? ''
            : '',
      ));
    }
    return out;
  }

  /// netease's lyric for [songId] (`lrc.lyric`), raw and unverified.
  Future<String?> fetchNeteaseLyric(String songId) async {
    final body = await _probe(
      'https://music.163.com/api/song/lyric?id=$songId&lv=1&kv=1&tv=-1',
    );
    final result = body == null ? null : _decode(body);
    final lrc = result is Map ? result['lrc'] : null;
    final lyric = lrc is Map ? lrc['lyric']?.toString() ?? '' : '';
    return lyric.isEmpty ? null : lyric;
  }

  static dynamic _decode(String body) {
    try {
      return jsonDecode(body);
    } catch (_) {
      return null;
    }
  }

  /// One probe: status ignored, body as text or null.
  Future<String?> _probe(String url) async {
    try {
      final response = await HttpClient.instance.dio.get<dynamic>(
        url,
        options: Options(responseType: ResponseType.plain, headers: _headers, validateStatus: (_) => true),
      );
      if (response.statusCode != 200) return null;
      final data = response.data;
      return data is String ? data : data?.toString();
    } catch (_) {
      return null;
    }
  }
}
