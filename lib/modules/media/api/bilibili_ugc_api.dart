import 'package:pure_live/modules/media/models/bilibili_music_models.dart';
import 'package:pure_live/modules/media/models/bilibili_ugc_models.dart';
import 'package:pure_live/platforms/bilibili/bilibili_site.dart';
import 'package:pure_live/services/settings/settings.dart';
import 'package:pure_live/shared/common/http_client.dart';
import 'dart:convert' show utf8;
import 'package:dio/dio.dart' show Options, ResponseType;

/// The shared bilibili UGC account/social layer behind both modes.
///
/// Music (bmsc feature set) and video (newBV feature set) read the same
/// class: fav folders (the synced playlists), cloud history, watch later,
/// dynamics, comments, like/coin/triple, user space and search. Playback and
/// the archive grids stay in [BilibiliMusicApi]; everything here is metadata
/// around them. All state-changing calls need the QR-login cookie; they throw
/// a login-required exception instead of silently failing.
class BilibiliUgcApi {
  BilibiliUgcApi._();

  static final BilibiliUgcApi instance = BilibiliUgcApi._();

  final BiliBiliSite _site = BiliBiliSite();

  static const String _videoReferer = 'https://www.bilibili.com/';

  String get _cookie => SettingsService.to.cookieManager.bilibiliCookie.v;

  bool get _loggedIn => _cookie.trim().isNotEmpty;

  /// Whether a bilibili cookie exists — pages use it to decide whether an
  /// interaction row is actionable or toasts the login hint.
  bool get isLoggedIn => _loggedIn;

  /// Throws on every state-changing call when no QR login exists — the gate
  /// normally prevents reaching one, but a mid-session logout must not corrupt
  /// data.
  void _ensureLogin() {
    if (_loggedIn) return;
    throw Exception('bilibili login required');
  }

  /// The csrf token the POST endpoints require; it lives in the cookie.
  String get _csrf {
    final match = RegExp(r'bili_jct=([^;]+)').firstMatch(_cookie);
    return match?.group(1) ?? '';
  }

  int get _myMid => int.tryParse(RegExp(r'DedeUserID=([^;]+)').firstMatch(_cookie)?.group(1) ?? '') ?? 0;

  Future<Map<String, String>> _headers({String referer = _videoReferer}) async {
    final base = await _site.getHeader();
    return {...base, 'referer': referer, if (_loggedIn) 'cookie': _cookie};
  }

  Future<dynamic> _get(String url, {Map<String, String>? query, String referer = _videoReferer}) async {
    final params = query == null
        ? null
        : {for (final entry in query.entries) entry.key: entry.value};
    final result = await HttpClient.instance.getJson(url, queryParameters: params, header: await _headers(referer: referer));
    if (result is! Map || result['code'] != 0) {
      final message = result is Map ? result['message'] ?? result['msg'] : result;
      throw Exception('bili ugc $url failed: $message');
    }
    return result['data'];
  }

  Future<dynamic> _getWbi(String url, {Map<String, String>? query, String referer = _videoReferer}) async {
    final base = query == null
        ? url
        : '$url?${query.entries.map((e) => '${Uri.encodeQueryComponent(e.key)}=${Uri.encodeQueryComponent(e.value)}').join('&')}';
    final params = await _site.getWbiSign(base);
    final result = await HttpClient.instance.getJson(url, queryParameters: params, header: await _headers(referer: referer));
    if (result is! Map || result['code'] != 0) {
      final message = result is Map ? result['message'] ?? result['msg'] : result;
      throw Exception('bili ugc wbi $url failed: $message');
    }
    return result['data'];
  }

  Future<dynamic> _post(String url, Map<String, String> form, {String referer = _videoReferer}) async {
    _ensureLogin();
    final result = await HttpClient.instance.postJson(
      url,
      data: {...form, 'csrf': _csrf, 'csrf_token': _csrf},
      header: await _headers(referer: referer),
      formUrlEncoded: true,
    );
    if (result is! Map || result['code'] != 0) {
      final message = result is Map ? result['message'] ?? result['msg'] : result;
      throw Exception('bili ugc post $url failed: $message');
    }
    return result['data'];
  }

  // ------------------------------------------------------------------ account

  int get myMid => _myMid;

  /// The login state beyond "a cookie exists" (`x/web-interface/nav`).
  Future<UgcMyInfo> getMyInfo() async {
    final data = await _get('https://api.bilibili.com/x/web-interface/nav');
    return UgcMyInfo.fromNavJson(data);
  }

  /// The UP's signature line only (`x/space/wbi/acc/info` alone) — the
  /// followers/relation round-trips of [getUserSpace] are not worth it for a
  /// card caption.
  Future<String> getUserSign(int mid) async {
    final info = await _getWbi('https://api.bilibili.com/x/space/wbi/acc/info', query: {'mid': '$mid'});
    return info?['sign']?.toString() ?? '';
  }

  /// One user's space header (`x/space/wbi/acc/info`) plus the relation row.
  Future<UserSpaceInfo> getUserSpace(int mid) async {
    final info = await _getWbi('https://api.bilibili.com/x/space/wbi/acc/info', query: {'mid': '$mid'});
    var followers = 0;
    var following = 0;
    var isFollowed = false;
    try {
      final stat = await _get('https://api.bilibili.com/x/relation/stat', query: {'vmid': '$mid'});
      followers = int.tryParse(stat?['follower']?.toString() ?? '') ?? 0;
    } catch (_) {}
    try {
      final relation = await _get('https://api.bilibili.com/x/relation', query: {'mid': '$mid'});
      isFollowed = (int.tryParse(relation?['attribute']?.toString() ?? '') ?? 0) > 0;
      following = isFollowed ? 1 : 0;
    } catch (_) {}
    return UserSpaceInfo(
      mid: mid,
      name: info?['name']?.toString() ?? '',
      face: info?['face']?.toString() ?? '',
      sign: info?['sign']?.toString() ?? '',
      followers: followers,
      following: following,
      videoCount: int.tryParse(info?['count']?.toString() ?? '') ?? 0,
      isFollowed: isFollowed,
      level: int.tryParse(info?['level']?.toString() ?? '') ?? 0,
    );
  }

  /// One page of a user's uploads (`x/space/wbi/arc/search`).
  Future<List<MusicArchive>> getUserUploads(int mid, {int page = 1, int pageSize = 25, String order = 'pubdate'}) async {
    final data = await _getWbi(
      'https://api.bilibili.com/x/space/wbi/arc/search',
      query: {'mid': '$mid', 'pn': '$page', 'ps': '$pageSize', 'order': order, 'index': '1'},
      referer: 'https://space.bilibili.com/$mid/',
    );
    final list = (data?['list']?['vlist'] as List?) ?? const [];
    return [
      for (final item in list)
        MusicArchive(
          aid: int.tryParse(item['aid']?.toString() ?? '') ?? 0,
          bvid: item['bvid']?.toString() ?? '',
          title: item['title']?.toString() ?? '',
          cover: item['pic'].toString().startsWith('//') ? 'https:${item['pic']}' : item['pic']?.toString() ?? '',
          upName: item['author']?.toString() ?? '',
          upMid: mid,
          duration: int.tryParse(item['length']?.toString() ?? '') ?? 0,
          playCount: int.tryParse(item['play']?.toString() ?? '') ?? 0,
          barrageCount: int.tryParse(item['video_review']?.toString() ?? '') ?? 0,
          description: item['description']?.toString() ?? '',
        ),
    ];
  }

  /// Follows or unfollows a user (`x/relation/modify`).
  Future<void> setFollowing(int mid, {required bool follow}) =>
      _post('https://api.bilibili.com/x/relation/modify', {'fid': '$mid', 'act': follow ? '1' : '2'});

  /// The account's followed uploaders (`x/relation/followings`) — the real
  /// follow list newBV's 关注列表 reads, not a local mirror. Requires the QR
  /// login cookie; throws when logged out.
  Future<List<({int mid, String name, String face, String sign})>> getFollowings({
    int page = 1,
    int pageSize = 24,
  }) async {
    final mid = RegExp(r'DedeUserID=([^;]+)').firstMatch(_cookie)?.group(1) ?? '';
    if (mid.isEmpty) throw Exception('bilibili login required');
    final data = await _get('https://api.bilibili.com/x/relation/followings', query: {
      'vmid': mid,
      'pn': '$page',
      'ps': '$pageSize',
    });
    final list = (data?['list'] as List?) ?? const [];
    return [
      for (final item in list)
        (
          mid: int.tryParse(item['mid']?.toString() ?? '') ?? 0,
          name: item['uname']?.toString() ?? '',
          face: item['face']?.toString() ?? '',
          sign: item['sign']?.toString() ?? '',
        ),
    ];
  }

  // -------------------------------------------------------------- interactions

  /// Likes (or un-likes) an archive (`x/web-interface/archive/like`).
  Future<void> setLike(int aid, {required bool like}) =>
      _post('https://api.bilibili.com/x/web-interface/archive/like', {'aid': '$aid', 'like': like ? '1' : '2'});

  Future<bool> hasLiked(int aid) async {
    try {
      final data = await _get('https://api.bilibili.com/x/web-interface/archive/has/like', query: {'aid': '$aid'});
      return data is List && data.isNotEmpty && data.first.toString() == '1';
    } catch (_) {
      return false;
    }
  }

  /// Puts [multiply] coins on an archive (`x/web-interface/coin/add`).
  Future<void> addCoin(int aid, {int multiply = 1}) => _post('https://api.bilibili.com/x/web-interface/coin/add', {
    'aid': '$aid',
    'multiply': '$multiply',
    'select_like': '0',
  });

  /// The one-click triple action: like + coin + favourite
  /// (`x/web-interface/archive/like/triple`).
  Future<void> tripleAction(int aid) =>
      _post('https://api.bilibili.com/x/web-interface/archive/like/triple', {'aid': '$aid'});

  // ---------------------------------------------------------------- fav folders

  /// The logged-in user's own fav folders — the synced playlist source
  /// (`x/v3/fav/folder/created/list-all`).
  Future<List<FavFolder>> getMyFavFolders() async {
    _ensureLogin();
    final data = await _get(
      'https://api.bilibili.com/x/v3/fav/folder/created/list-all',
      query: {'up_mid': '$_myMid', 'type': '2', 'rid': '0'},
    );
    return [for (final item in (data?['list'] as List?) ?? const []) FavFolder.fromListJson(item)];
  }

  /// Folders collected from other users, paged
  /// (`x/v3/fav/folder/collected/list`).
  Future<List<FavFolder>> getCollectedFavFolders({int page = 1, int pageSize = 20}) async {
    _ensureLogin();
    final data = await _get('https://api.bilibili.com/x/v3/fav/folder/collected/list', query: {
      'up_mid': '$_myMid',
      'pn': '$page',
      'ps': '$pageSize',
      'platform': 'web',
    });
    return [for (final item in (data?['list'] as List?) ?? const []) FavFolder.fromListJson(item)];
  }

  /// One folder's archives, paged (`x/v3/fav/resource/list`).
  Future<List<FavResource>> getFavResources(int mediaId, {int page = 1, int pageSize = 20}) async {
    final data = await _get('https://api.bilibili.com/x/v3/fav/resource/list', query: {
      'media_id': '$mediaId',
      'pn': '$page',
      'ps': '$pageSize',
      'order': 'mtime',
      'type': '2',
      'tid': '0',
      'platform': 'web',
    });
    return [for (final item in (data?['medias'] as List?) ?? const []) FavResource.fromJson(item)];
  }

  /// Adds or removes an archive from folders (`x/v3/fav/resource/deal`).
  Future<void> favDeal({required int aid, List<int> addFolderIds = const [], List<int> delFolderIds = const []}) async {
    _post('https://api.bilibili.com/x/v3/fav/resource/deal', {
      'rid': '$aid',
      'type': '2',
      'add_media_ids': addFolderIds.join(','),
      'del_media_ids': delFolderIds.join(','),
    });
  }

  /// Whether the archive sits in any folder already (`x/v2/fav/video/favoured`).
  Future<bool> isFavoured(int aid) async {
    try {
      final data = await _get('https://api.bilibili.com/x/v2/fav/video/favoured', query: {'aid': '$aid'});
      return data?['favoured'] == true;
    } catch (_) {
      return false;
    }
  }

  /// Creates a folder (`x/v3/fav/folder/add`).
  Future<void> createFavFolder(String title) =>
      _post('https://api.bilibili.com/x/v3/fav/folder/add', {'title': title, 'privacy': '0'});

  // ----------------------------------------------------------- history / toview

  /// Cloud watch history, cursor-paged (`x/web-interface/history/cursor`).
  /// Returns `(rows, nextMax, nextViewAt)`.
  Future<(List<HistoryItem>, int, int)> getHistory({int max = 0, int viewAt = 0, String business = ''}) async {
    _ensureLogin();
    final data = await _get('https://api.bilibili.com/x/web-interface/history/cursor', query: {
      'type': 'archive',
      'business': business,
      'max': '$max',
      'view_at': '$viewAt',
      'ps': '20',
    });
    final rows = [for (final item in (data?['list'] as List?) ?? const []) HistoryItem.fromJson(item)];
    return (rows, int.tryParse(data?['cursor']?['max']?.toString() ?? '') ?? 0,
        int.tryParse(data?['cursor']?['view_at']?.toString() ?? '') ?? 0);
  }

  /// Reports one heartbeat so the bilibili history row tracks progress
  /// (`x/v2/history/report`), the way newBV's player does.
  Future<void> reportHistory({required int aid, required int cid, required int progress, String? bvid}) async {
    _post('https://api.bilibili.com/x/v2/history/report', {
      'aid': '$aid',
      'cid': '$cid',
      'progress': '$progress',
      'platform': 'web',
      if (bvid != null && bvid.isNotEmpty) 'bvid': bvid,
    });
  }

  /// Deletes one archive's row from the bilibili watch history
  /// (`x/v2/history/delete`, POST with the part's cid as `kid=1`).
  Future<void> deleteHistory({required int aid, required int cid}) async {
    _post('https://api.bilibili.com/x/v2/history/delete', {
      'kid': '1',
      'aid': '$aid',
      'cid': '$cid',
    });
  }

  /// The watch-later list (`x/v2/history/toview`).
  Future<List<ToViewItem>> getToView() async {
    _ensureLogin();
    final data = await _get('https://api.bilibili.com/x/v2/history/toview');
    return [for (final item in (data?['list'] as List?) ?? const []) ToViewItem.fromJson(item)];
  }

  Future<void> addToView(int aid) =>
      _post('https://api.bilibili.com/x/v2/history/toview/add', {'aid': '$aid'});

  Future<void> removeFromView(int aid) =>
      _post('https://api.bilibili.com/x/v2/history/toview/del', {'aid': '$aid'});

  // ------------------------------------------------------------------ dynamics

  /// The followed users' video feed, offset-paged
  /// (`x/polymer/web-dynamic/v1/feed/all?type=video`). Returns
  /// `(rows, nextOffset)`.
  Future<(List<DynamicVideo>, String)> getDynamics({String offset = ''}) async {
    _ensureLogin();
    final data = await _get('https://api.bilibili.com/x/polymer/web-dynamic/v1/feed/all', query: {
      'type': 'video',
      if (offset.isNotEmpty) 'offset': offset,
    });
    final rows = [for (final item in (data?['items'] as List?) ?? const []) DynamicVideo.fromJson(item)]
        .where((d) => !d.isEmpty)
        .toList();
    return (rows, data?['offset']?.toString() ?? '');
  }

  // ------------------------------------------------------------------ comments

  /// One page of an archive's comments, hot or newest first
  /// (`x/v2/reply/wbi/main`). Returns `(roots, nextOffset, hasMore)`.
  Future<(List<CommentItem>, String, bool)> getComments({
    required int oid,
    int type = 1,
    required int page,
    bool hot = true,
  }) async {
    final nextOffset = page > 1 ? '{"offset":$page}' : '';
    final data = await _getWbi('https://api.bilibili.com/x/v2/reply/wbi/main', query: {
      'oid': '$oid',
      'type': '$type',
      'mode': hot ? '3' : '2',
      'pagination_str': nextOffset.isEmpty ? '{"offset":""}' : nextOffset,
      'ps': '20',
      'web_location': '1315875',
    });
    final roots = [
      for (final item in (data?['replies'] as List?) ?? const []) CommentItem.fromJson(item),
    ];
    final top = data?['top_replies'];
    if (page == 1 && top is List && top.isNotEmpty) {
      roots.insert(0, CommentItem.fromJson(top.first));
    }
    final cursor = data?['cursor'];
    final hasMore = cursor?['is_end'] == false;
    return (roots, page.toString(), hasMore);
  }

  /// The sub-replies of one comment (`x/v2/reply/reply`).
  Future<List<CommentItem>> getCommentReplies({required int oid, required int rpid, int page = 1}) async {
    final data = await _get('https://api.bilibili.com/x/v2/reply/reply', query: {
      'oid': '$oid',
      'type': '1',
      'root': '$rpid',
      'pn': '$page',
      'ps': '20',
    });
    return [for (final item in (data?['replies'] as List?) ?? const []) CommentItem.fromJson(item)];
  }

  /// Likes or un-likes a comment (`x/v2/reply/action`).
  Future<void> likeComment({required int oid, required int rpid, required bool like}) =>
      _post('https://api.bilibili.com/x/v2/reply/action', {'oid': '$oid', 'type': '1', 'rpid': '$rpid', 'action': like ? '1' : '0'});

  /// Posts one danmaku comment to the archive's current part
  /// (`x/v2/dm/send`), the web shape with the csrf token.
  Future<void> sendDanmaku({required int aid, required int cid, required String message, String? bvid}) async {
    _post('https://api.bilibili.com/x/v2/dm/send', {
      'aid': '$aid',
      'cid': '$cid',
      'bvid': bvid ?? '',
      'message': message,
      'mode': '1',
      'fontsize': '25',
      'color': '16777215',
      'pool': '0',
      'plat': '1',
      'progress': '0',
      'rnd': '${DateTime.now().millisecondsSinceEpoch ~/ 1000}',
    });
  }

  // -------------------------------------------------------------------- search

  /// The trending search words (`x/web-interface/search/square`).
  Future<List<Hotword>> getHotwords() async {
    final data = await _get('https://api.bilibili.com/x/web-interface/search/square', query: {
      'limit': '10',
      'platform': 'web',
    }, referer: 'https://search.bilibili.com/');
    return [
      for (final item in (data?['trending']?['list'] as List?) ?? const [])
        Hotword(keyword: item['keyword']?.toString() ?? '', icon: item['icon']?.toString() ?? ''),
    ];
  }

  /// Live search suggestions (`s.search.bilibili.com/main/suggest`).
  Future<List<String>> getSuggestions(String term) async {
    if (term.trim().isEmpty) return const [];
    try {
      final result = await HttpClient.instance.getJson(
        'https://s.search.bilibili.com/main/suggest',
        queryParameters: {'term': term, 'main_ver': 'v1'},
        header: await _headers(referer: 'https://search.bilibili.com/'),
      );
      final tags = result?['result']?['tag'] as List?;
      if (tags != null) return [for (final t in tags) t['value']?.toString() ?? t['name']?.toString() ?? ''];
      final list = result?['list'] as List?;
      if (list != null) return [for (final t in list) t['value']?.toString() ?? t['term']?.toString() ?? ''];
      return const [];
    } catch (_) {
      return const [];
    }
  }

  /// Search result of type `user` / `bili_user` (the WBI search endpoint).
  Future<List<SearchUserItem>> searchUsers(String keyword, {int page = 1}) async {
    final data = await _searchType(keyword, 'user', page: page);
    return [for (final item in data) SearchUserItem.fromJson(item)];
  }

  /// Search result of type `live`.
  Future<List<SearchLiveItem>> searchLives(String keyword, {int page = 1}) async {
    final data = await _searchType(keyword, 'live', page: page);
    return [for (final item in data) SearchLiveItem.fromJson(item)];
  }

  /// Search result of type `movie` (PGC seasons).
  Future<List<SearchPgcItem>> searchPgc(String keyword, {int page = 1}) async {
    final data = await _searchType(keyword, 'movie', page: page);
    return [for (final item in data) SearchPgcItem.fromJson(item)];
  }

  Future<List<dynamic>> _searchType(String keyword, String searchType, {required int page}) async {
    final data = await _getWbi(
      'https://api.bilibili.com/x/web-interface/wbi/search/type',
      query: {
        'search_type': searchType,
        'keyword': keyword,
        'order': 'totalrank',
        'page': '$page',
        'page_size': '20',
      },
      referer: 'https://search.bilibili.com/',
    );
    return (data?['result'] as List?) ?? const [];
  }

  // ------------------------------------------------------------------ subtitles

  /// The subtitle tracks of one part (`x/player/wbi/v2`).
  Future<List<SubtitleTrack>> getSubtitles({required String bvid, required int cid}) async {
    final data = await _getWbi('https://api.bilibili.com/x/player/wbi/v2', query: {'bvid': bvid, 'cid': '$cid'});
    return [
      for (final item in (data?['subtitle']?['subtitles'] as List?) ?? const []) SubtitleTrack.fromJson(item),
    ];
  }

  /// The cues of one subtitle track (the json the track url points at).
  Future<List<SubtitleCue>> fetchSubtitleCues(String url) async {
    if (url.isEmpty) return const [];
    final json = await HttpClient.instance.getJson(
      url,
      header: {'user-agent': BiliBiliSite.kDefaultUserAgent, 'referer': _videoReferer},
    );
    return [
      for (final item in (json?['body'] as List?) ?? const [])
        SubtitleCue(
          from: double.tryParse(item['from']?.toString() ?? '') ?? 0,
          to: double.tryParse(item['to']?.toString() ?? '') ?? 0,
          text: item['content']?.toString() ?? '',
        ),
    ];
  }

  /// The viewers watching right now (`x/player/v2` → online_count), the
  /// "同时观看人数" the newBV player shows.
  Future<int> getOnlineCount({required String bvid, required int cid}) async {
    try {
      final data = await _get('https://api.bilibili.com/x/player/v2', query: {'bvid': bvid, 'cid': '$cid'});
      return int.tryParse(data?['online_count']?.toString() ?? '') ?? 0;
    } catch (_) {
      return 0;
    }
  }

  /// The number of danmaku segments for the part. `x/v2/dm/web/view` answers
  /// as protobuf (DmWebViewReply, non-WBI — newBV reads it the same way) whose
  /// field 4 carries the repeated dm_seg config; the first entry's field 2 is
  /// the segment total. Zero when the answer carries nothing — the caller
  /// falls back to the one-shot XML.
  Future<int> getDanmakuSegmentCount({required int aid, required int cid}) async {
    try {
      final response = await HttpClient.instance.dio.get<List<int>>(
        'https://api.bilibili.com/x/v2/dm/web/view',
        options: Options(
          responseType: ResponseType.bytes,
          headers: {'user-agent': 'Mozilla/5.0', 'referer': 'https://www.bilibili.com/'},
        ),
        queryParameters: {'type': '1', 'oid': '$cid', 'pid': '$aid'},
      );
      return _pbSegmentTotal(response.data ?? const <int>[]);
    } catch (_) {
      return 0;
    }
  }

  /// Reads one protobuf varint; returns (value, nextOffset).
  static (int, int) _pbVarint(List<int> source, int offset) {
    var value = 0;
    var shift = 0;
    var cursor = offset;
    while (cursor < source.length) {
      final b = source[cursor++];
      value |= (b & 0x7f) << shift;
      if (b & 0x80 == 0) return (value, cursor);
      shift += 7;
    }
    throw const FormatException('truncated varint');
  }

  static int _pbSkip(List<int> source, int offset, int wire) {
    switch (wire) {
      case 0:
        return _pbVarint(source, offset).$2;
      case 1:
        return offset + 8;
      case 2:
        final (length, after) = _pbVarint(source, offset);
        return after + length;
      case 5:
        return offset + 4;
      default:
        throw const FormatException('unsupported wire type');
    }
  }

  /// Total segments from the first `dm_seg` config (DmWebViewReply field 4 →
  /// DmSegConfig field 2), or 0 when absent.
  static int _pbSegmentTotal(List<int> bytes) {
    try {
      var at = 0;
      while (at < bytes.length) {
        final (key, keyNext) = _pbVarint(bytes, at);
        final field = key >> 3;
        final wire = key & 7;
        if (field != 4 || wire != 2) {
          at = _pbSkip(bytes, keyNext, wire);
          continue;
        }
        final (configLength, configStart) = _pbVarint(bytes, keyNext);
        final config = bytes.sublist(configStart, configStart + configLength);

        var inner = 0;
        while (inner < config.length) {
          final (innerKey, innerNext) = _pbVarint(config, inner);
          if ((innerKey >> 3) == 2 && (innerKey & 7) == 0) {
            final (total, _) = _pbVarint(config, innerNext);
            return total;
          }
          inner = _pbSkip(config, innerNext, innerKey & 7);
        }
        return 0;
      }
    } on FormatException {
      // Fall through: malformed protobuf reads as "no segments".
    }
    return 0;
  }

  /// One danmaku segment (`x/v2/dm/web/seg.so`) as protobuf. The response
  /// is a `DmSegMobileReply` whose repeated element (field 1) carries, per
  /// danmaku: progress (field 2, varint, milliseconds), mode (field 3,
  /// varint) and content (field 7, string) — the only fields this app uses.
  Future<List<({double time, String text})>> getDanmakuSegment({
    required int aid,
    required int cid,
    required int segment,
  }) async {
    // `/x/v2/dm/wbi/web/seg.so` — the WBI-signed web endpoint newBV uses
    // (`segment_index`, 1-based). The unsigned `dm/web/seg.so` answers an
    // empty reply to plain clients, which read as "no danmaku in this
    // segment".
    final base = 'https://api.bilibili.com/x/v2/dm/wbi/web/seg.so';
    final signed = await _site.getWbiSign('$base?type=1&oid=$cid&pid=$aid&segment_index=$segment');
    final response = await HttpClient.instance.dio.get<List<int>>(
      base,
      options: Options(
        responseType: ResponseType.bytes,
        headers: {'user-agent': 'Mozilla/5.0', 'referer': 'https://www.bilibili.com/'},
      ),
      queryParameters: signed,
    );
    return parseDanmakuSegment(response.data ?? const <int>[]);
  }

  /// Minimal protobuf walk for [getDanmakuSegment] — no generated bindings;
  /// the three fields above are all the player needs. Anything malformed
  /// yields what was parsed so far; the overlay then shows fewer danmaku.
  static List<({double time, String text})> parseDanmakuSegment(List<int> bytes) {
    final out = <({double time, String text})>[];
    var at = 0;

    /// Reads one varint, returns (value, nextOffset).
    (int, int) varint(List<int> source, int offset) {
      var value = 0;
      var shift = 0;
      var cursor = offset;
      while (cursor < source.length) {
        final b = source[cursor++];
        value |= (b & 0x7f) << shift;
        if (b & 0x80 == 0) return (value, cursor);
        shift += 7;
      }
      throw const FormatException('truncated varint');
    }

    int skip(int offset, int wire) {
      switch (wire) {
        case 0:
          return varint(bytes, offset).$2;
        case 1:
          return offset + 8;
        case 2:
          final (length, after) = varint(bytes, offset);
          return after + length;
        case 5:
          return offset + 4;
        default:
          throw const FormatException('unsupported wire type');
      }
    }

    try {
      while (at < bytes.length) {
        final (key, keyNext) = varint(bytes, at);
        final field = key >> 3;
        final wire = key & 7;
        if (field != 1 || wire != 2) {
          at = skip(keyNext, wire);
          continue;
        }
        final (elemLength, elemStart) = varint(bytes, keyNext);
        final elem = bytes.sublist(elemStart, elemStart + elemLength);
        at = elemStart + elemLength;

        var progressMs = 0;
        var mode = 1;
        var text = '';
        var inner = 0;
        while (inner < elem.length) {
          final (innerKey, innerNext) = varint(elem, inner);
          final innerField = innerKey >> 3;
          final innerWire = innerKey & 7;
          switch ((innerField, innerWire)) {
            case (2, 0):
              final (value, valueNext) = varint(elem, innerNext);
              progressMs = value;
              inner = valueNext;
            case (3, 0):
              final (modeValue, modeNext) = varint(elem, innerNext);
              mode = modeValue;
              inner = modeNext;
            case (7, 2):
              final (length, textStart) = varint(elem, innerNext);
              text = utf8.decode(elem.sublist(textStart, textStart + length), allowMalformed: true);
              inner = textStart + length;
            default:
              final (_, after) = varint(elem, inner); inner = after;
          }
        }
        if (text.isNotEmpty && mode <= 3) {
          out.add((time: progressMs / 1000.0, text: text));
        }
      }
    } on FormatException {
      return out;
    }
    out.sort((a, b) => a.time.compareTo(b.time));
    return out;
  }
}
