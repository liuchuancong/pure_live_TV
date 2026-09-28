import 'package:dio/dio.dart';

/// Track triples from the other music platforms — the bmsc playlist importer's
/// provider layer, ported endpoint for endpoint. A triple is
/// `{'name', 'artist', 'duration'}`; the matcher (see PlaylistMatcher) turns
/// each one into a bilibili archive by search.
///
/// null = the fetch itself failed; an empty list = the platform answered but
/// knows no such playlist. The importer treats the two differently.
class MusicProvider {
  static final Dio _dio = Dio();

  /// 网易云音乐: a community NeteaseCloudMusicApi mirror.
  static Future<List<Map<String, dynamic>>?> fetchNeteasePlaylistTracks(String playlistId) async {
    try {
      final response = await _dio.get(
        'https://rp.u2x1.work/playlist/track/all',
        queryParameters: {'id': playlistId},
      );
      final List<Map<String, dynamic>> tracks = [];
      for (final song in response.data['songs']) {
        tracks.add({
          'name': song['name'],
          'artist': song['ar'][0]['name'],
          'duration': song['dt'] ~/ 1000,
        });
      }
      return tracks;
    } on DioException catch (e) {
      if (e.response?.statusCode == 404) {
        return [];
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// QQ 音乐: timelessq's songList endpoint.
  static Future<List<Map<String, dynamic>>?> fetchTencentPlaylistTracks(String playlistId) async {
    try {
      final response = await _dio.get(
        'https://api.timelessq.com/music/tencent/songList',
        queryParameters: {'disstid': playlistId},
      );
      if (response.data['errno'] != 0) {
        return [];
      }
      final List<Map<String, dynamic>> tracks = [];
      for (final song in response.data['data']['songlist']) {
        tracks.add({
          'name': song['songname'],
          'artist': song['singer'].map((e) => e['name']).join(', '),
          'duration': song['interval'],
        });
      }
      return tracks;
    } catch (e) {
      return null;
    }
  }

  /// 酷狗音乐: a community mirror; `gcid_...` share links resolve to the real
  /// global id through the songlist page first. Pages of 300.
  static Future<List<Map<String, dynamic>>?> fetchKuGouPlaylistTracks(String playlistId) async {
    try {
      if (playlistId.startsWith('gcid')) {
        final response = await _dio.get('https://www.kugou.com/songlist/$playlistId/');
        final html = response.data as String;
        final RegExp regExp = RegExp(r'"list_create_gid":"([^"]+)"');
        final match = regExp.firstMatch(html);
        if (match != null) {
          playlistId = match.group(1)!;
        }
      }

      final response = await _dio.get(
        'https://kg.u2x1.work/playlist/track/all?id=$playlistId&pagesize=300',
      );
      if (response.data['status'] == 0) {
        return [];
      }
      final total = response.data['data']['count'];
      final List<Map<String, dynamic>> tracks = [];
      for (final song in response.data['data']['info']) {
        final fullname = song['name'];
        final pos = fullname.indexOf('-');
        final name = pos == -1 ? fullname : fullname.substring(0, pos);
        final artist = pos == -1 ? '' : fullname.substring(pos + 1).trim();
        tracks.add({
          'name': name,
          'artist': artist,
          'duration': song['timelen'] ~/ 1000,
        });
      }
      if (total > 300) {
        final pageSize = (total / 300).ceil();
        for (int i = 2; i <= pageSize; i++) {
          final response = await _dio.get(
            'https://kg.u2x1.work/playlist/track/all?id=$playlistId&pagesize=300&page=$i',
          );
          for (final song in response.data['data']['info']) {
            final fullname = song['name'];
            final pos = fullname.indexOf('-');
            final name = pos == -1 ? fullname : fullname.substring(0, pos);
            final artist = pos == -1 ? '' : fullname.substring(pos + 1).trim();
            tracks.add({
              'name': name,
              'artist': artist,
              'duration': song['timelen'] ~/ 1000,
            });
          }
        }
      }
      return tracks;
    } catch (e) {
      return null;
    }
  }
}
