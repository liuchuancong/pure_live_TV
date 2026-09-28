import 'package:pure_live/modules/media/api/bilibili_music_api.dart';
import 'package:pure_live/modules/media/models/bilibili_music_models.dart';
import 'package:pure_live/modules/video/models/video_pgc_models.dart';
import 'package:pure_live/platforms/bilibili/bilibili_site.dart';
import 'package:pure_live/services/settings/settings.dart';
import 'package:pure_live/shared/common/http_client.dart';

/// The video module's PGC (影视/番剧) layer, newBV's pgc sections: the season
/// feed, the season detail with its episode list, and the episode playurl.
///
/// The web playurl for PGC shares the DASH shape with UGC, so the answer is
/// converted into the shared [MusicPlayUrls] model and handed to the common
/// VOD engine — the video module injects [resolvePlayUrls] as the
/// `modulePlayUrlResolver` hook. A paid episode answers with a preview range
/// as a guest; the muxed durl fallback covers it the same way UGC does.
class VideoPgcApi {
  VideoPgcApi._();

  static final VideoPgcApi instance = VideoPgcApi._();

  final BiliBiliSite _site = BiliBiliSite();

  String get _cookie => SettingsService.to.cookieManager.bilibiliCookie.v;

  Future<Map<String, String>> _headers({String referer = 'https://www.bilibili.com/'}) async {
    final base = await _site.getHeader();
    return {...base, 'referer': referer, if (_cookie.trim().isNotEmpty) 'cookie': _cookie};
  }

  Future<Map<dynamic, dynamic>?> _tryGet(String url, {Map<String, String>? query}) async {
    try {
      final result = await HttpClient.instance.getJson(url, queryParameters: query, header: await _headers());
      if (result is Map && result['code'] == 0) return result['data'] ?? result['result'];
      return null;
    } catch (_) {
      return null;
    }
  }

  /// The PGC feed: tries the web index feed first, then the season index
  /// result list (both guest-readable). [pgcType]: 1 番剧, 2 国创, 3 纪录片,
  /// 4 电影, 5 电视剧.
  Future<List<PgcItem>> getFeed({required int pgcType, int page = 1, int pageSize = 20}) async {
    final feed = await _tryGet('https://api.bilibili.com/pgc/api/web/index/feed', query: {
      'typed_id': '$pgcType',
      'page': '$page',
      'pagesize': '$pageSize',
    });
    final List<dynamic>? items = feed?['items'] ?? feed?['list'];
    if (items != null && items.isNotEmpty) {
      return [for (final item in items) PgcItem.fromJson(item)];
    }
    final index = await _tryGet('https://api.bilibili.com/pgc/season/index/result', query: {
      'season_type': '$pgcType',
      'page': '$page',
      'pagesize': '$pageSize',
    });
    final list = (index?['list'] as List?) ?? const [];
    return [for (final item in list) PgcItem.fromJson(item)];
  }

  /// The logged-in user's followed seasons (追番/追剧,
  /// `x/space/bangumi/follow/list`). [type]: 1 bangumi, 2 drama.
  Future<List<PgcItem>> getFollowedSeasons({int type = 1, int page = 1, int pageSize = 20}) async {
    final mid = RegExp(r'DedeUserID=([^;]+)').firstMatch(_cookie)?.group(1) ?? '';
    if (mid.isEmpty) throw Exception('bilibili login required');
    final data = await _tryGet('https://api.bilibili.com/x/space/bangumi/follow/list', query: {
      'vmid': mid,
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
    return PgcSeason.fromJson(data);
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
      header: await _headers(),
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

  /// Same AVC-first quality picker as [BilibiliMusicApi] uses; kept local so
  /// the video module owns its stream selection end to end.
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
      videoUrl: picked['baseUrl']?.toString() ?? '',
      audioUrl: audio?['baseUrl']?.toString(),
      videoBackupUrls: backupsOf(picked),
      quality: tiers.first,
      videoOptions: options,
    );
  }
}
