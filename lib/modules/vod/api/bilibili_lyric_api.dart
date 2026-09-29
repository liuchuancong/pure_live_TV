import 'dart:convert';

import 'package:dio/dio.dart' show Options, ResponseType;
import 'package:pure_live/modules/vod/api/bilibili_api_client.dart';
import 'package:pure_live/core/common/http_client.dart';

/// The bilibili BGM lyric chain: the archive's own background-music metadata.
/// `x/player/wbi/v2` names the BGM (`bgm_info`), and
/// `x/copyright-music-publicity/bgm/detail` hands back its official lyric —
/// the source the bilibilimusic reference prefers, because it is the
/// uploader's own BGM metadata.
///
/// Both steps probe with the status ignored and the body decoded by hand: a
/// missing BGM must read as "no lyric", not as an HTTP error banner over the
/// player. Title verification stays in the music service — this API only
/// reports what the BGM claims to be.
class BilibiliLyricApi {
  BilibiliLyricApi._();

  static final BilibiliLyricApi instance = BilibiliLyricApi._();

  final BilibiliApiClient _client = BilibiliApiClient.instance;

  /// The part's BGM metadata, or null when the part carries none. [title] is
  /// what the BGM claims to be (empty when unattributed), [musicId] the
  /// handle for [fetchBgmLyric].
  Future<({String title, String musicId})?> fetchBgmInfo({
    required int aid,
    required String bvid,
    required int cid,
  }) async {
    if (cid <= 0) return null;
    final base = 'https://api.bilibili.com/x/player/wbi/v2';
    final signed = await _client.wbiSign('$base?aid=$aid&bvid=$bvid&cid=$cid');
    final data = _dataOf(await _probe(base, signed));
    final bgm = data is Map ? data['bgm_info'] : null;
    if (bgm is! Map) return null;
    final musicId = bgm['music_id']?.toString() ?? '';
    if (musicId.isEmpty) return null;
    return (title: _firstString(bgm, const ['music_title', 'title', 'song_title']) ?? '', musicId: musicId);
  }

  /// The BGM's lyric text (`mv_lyric`), raw and unverified; null when the
  /// detail endpoint carries none.
  Future<String?> fetchBgmLyric({required String musicId}) async {
    final url = 'https://api.bilibili.com/x/copyright-music-publicity/bgm/detail';
    final data = _dataOf(await _probe(url, {
      'music_id': musicId,
      'relation_from': 'bgm_page',
    }));
    final lyric = data is Map ? data['mv_lyric']?.toString() ?? '' : '';
    return lyric.isEmpty ? null : lyric;
  }

  static dynamic _dataOf(dynamic body) => body is Map ? body['data'] : null;

  static String? _firstString(Map data, List<String> keys) {
    for (final key in keys) {
      final value = data[key]?.toString().trim() ?? '';
      if (value.isNotEmpty) return value;
    }
    return null;
  }

  /// One probe: status ignored, body as text, decoded JSON or null.
  Future<dynamic> _probe(String url, Map params) async {
    try {
      final values = <String, String>{
        for (final entry in params.entries) entry.key: entry.value.toString(),
      };
      final target = Uri.parse(url).replace(queryParameters: values).toString();
      final response = await HttpClient.instance.dio.get<dynamic>(
        target,
        options: Options(
          responseType: ResponseType.plain,
          headers: await _client.headers(),
          validateStatus: (_) => true,
        ),
      );
      if (response.statusCode != 200) return null;
      final text = response.data is String ? response.data as String : response.data?.toString() ?? '';
      if (text.isEmpty) return null;
      try {
        return jsonDecode(text);
      } catch (_) {
        return null;
      }
    } catch (_) {
      return null;
    }
  }
}
