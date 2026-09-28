/// Models for the shared bilibili UGC account/social layer.
///
/// Both module modes read these: music (bmsc feature set — synced fav
/// folders, cloud history, dynamics, comments, UP space) and video (newBV
/// feature set — the same endpoints plus personal center). Playback models
/// stay in [MusicArchive]/[MusicTrack]; everything here is metadata around
/// them.
library;

import 'package:pure_live/modules/media/models/bilibili_music_models.dart';


/// The logged-in account (`x/web-interface/nav`), the login gate's state
/// source beyond "a cookie exists".
class UgcMyInfo {
  const UgcMyInfo({
    required this.isLogin,
    this.mid = 0,
    this.uname = '',
    this.face = '',
    this.level = 0,
    this.coin = 0,
    this.vip = false,
  });

  factory UgcMyInfo.fromNavJson(Map<dynamic, dynamic> json) {
    return UgcMyInfo(
      isLogin: json['isLogin'] == true,
      mid: int.tryParse(json['mid']?.toString() ?? '') ?? 0,
      uname: json['uname']?.toString() ?? '',
      face: json['face']?.toString() ?? '',
      level: int.tryParse(json['level_info']?['current_level']?.toString() ?? '') ?? 0,
      coin: double.tryParse(json['money']?.toString() ?? '') ?? 0,
      vip: (int.tryParse(json['vipStatus']?.toString() ?? '') ?? 0) > 0,
    );
  }

  final bool isLogin;
  final int mid;
  final String uname;
  final String face;
  final int level;
  final double coin;
  final bool vip;
}

/// One fav folder (收藏夹) — the unit of the synced playlist.
class FavFolder {
  const FavFolder({
    required this.id,
    required this.title,
    this.mediaCount = 0,
    this.cover = '',
    this.isPublic = true,
  });

  factory FavFolder.fromListJson(Map<dynamic, dynamic> json) {
    final cover = json['cover'];
    return FavFolder(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      title: json['title']?.toString() ?? '',
      mediaCount: int.tryParse(json['media_count']?.toString() ?? '') ?? 0,
      cover: cover is Map ? cover['url']?.toString() ?? '' : cover?.toString() ?? '',
      isPublic: (int.tryParse(json['privacy']?.toString() ?? '') ?? 0) == 0,
    );
  }

  final int id;
  final String title;
  final int mediaCount;
  final String cover;
  final bool isPublic;

  Map<String, dynamic> toJson() => {'id': id, 'title': title, 'mediaCount': mediaCount, 'cover': cover, 'isPublic': isPublic};

  factory FavFolder.fromJson(Map<String, dynamic> json) => FavFolder(
    id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
    title: json['title']?.toString() ?? '',
    mediaCount: int.tryParse(json['mediaCount']?.toString() ?? '') ?? 0,
    cover: json['cover']?.toString() ?? '',
    isPublic: json['isPublic'] != false,
  );
}

/// One archive inside a fav folder (`x/v3/fav/resource/list`).
class FavResource {
  const FavResource({
    required this.aid,
    required this.bvid,
    required this.title,
    required this.cover,
    this.duration = 0,
    this.playCount = 0,
    this.barrageCount = 0,
    this.upName = '',
    this.upMid = 0,
    this.upFace = '',
    this.invalid = false,
  });

  factory FavResource.fromJson(Map<dynamic, dynamic> json) {
    // attr bit 31 (1 << 31) marks a UP-deleted / invalid archive.
    final attr = int.tryParse(json['attr']?.toString() ?? '') ?? 0;
    final cnt = json['cnt_info'];
    return FavResource(
      aid: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      bvid: json['bvid']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      cover: _https(json['cover']?.toString() ?? ''),
      duration: int.tryParse(json['duration']?.toString() ?? '') ?? 0,
      playCount: int.tryParse(cnt?['play']?.toString() ?? '') ?? 0,
      barrageCount: int.tryParse(cnt?['danmaku']?.toString() ?? '') ?? 0,
      upName: json['upper']?['name']?.toString() ?? '',
      upMid: int.tryParse(json['upper']?['mid']?.toString() ?? '') ?? 0,
      upFace: _https(json['upper']?['face']?.toString() ?? ''),
      invalid: (attr >> 31 & 1) == 1 || json['title']?.toString() == '已失效视频',
    );
  }

  final int aid;
  final String bvid;
  final String title;
  final String cover;
  final int duration;
  final int playCount;
  final int barrageCount;
  final String upName;
  final int upMid;
  final String upFace;
  final bool invalid;

  /// Folders feed the same queue models the grids use.
  MusicArchive toArchive() => MusicArchive(
    aid: aid,
    bvid: bvid,
    title: title,
    cover: cover,
    upName: upName,
    upMid: upMid,
    upFace: upFace,
    duration: duration,
    playCount: playCount,
    barrageCount: barrageCount,
  );

  static String _https(String url) => url.startsWith('//') ? 'https:$url' : url;
}

/// One row of the bilibili cloud history (`x/web-interface/history/cursor`).
class HistoryItem {
  const HistoryItem({
    required this.archive,
    this.cid = 0,
    this.page = 1,
    this.progress = 0,
    this.duration = 0,
    this.viewAt = 0,
    this.epid = 0,
    this.seasonId = 0,
  });

  factory HistoryItem.fromJson(Map<dynamic, dynamic> json) {
    final history = json['history'];
    return HistoryItem(
      archive: MusicArchive(
        aid: int.tryParse(history?['oid']?.toString() ?? '') ?? 0,
        bvid: history?['bvid']?.toString() ?? '',
        title: json['show_title']?.toString() ?? json['title']?.toString() ?? '',
        cover: _https(json['cover']?.toString() ?? ''),
        upName: json['author_name']?.toString() ?? '',
        upMid: int.tryParse(json['author_mid']?.toString() ?? '') ?? 0,
        upFace: _https(json['author_face']?.toString() ?? ''),
        duration: int.tryParse(json['duration']?.toString() ?? '') ?? 0,
      ),
      cid: int.tryParse(history?['cid']?.toString() ?? '') ?? 0,
      page: int.tryParse(history?['page']?.toString() ?? '') ?? 1,
      progress: int.tryParse(json['progress']?.toString() ?? '') ?? 0,
      duration: int.tryParse(json['duration']?.toString() ?? '') ?? 0,
      viewAt: int.tryParse(json['view_at']?.toString() ?? '') ?? 0,
      epid: int.tryParse(history?['epid']?.toString() ?? '') ?? 0,
      seasonId: int.tryParse(history?['sid']?.toString() ?? '') ?? 0,
    );
  }

  final MusicArchive archive;
  final int cid;
  final int page;
  final int progress;
  final int duration;
  final int viewAt;

  /// PGC rows carry an episode id; video-mode history mixes both.
  final int epid;
  final int seasonId;

  bool get finished => duration > 0 && progress >= duration;
}

/// One 稍后再看 row (`x/v2/history/toview`).
class ToViewItem {
  const ToViewItem({required this.archive, this.cid = 0, this.addAt = 0});

  factory ToViewItem.fromJson(Map<dynamic, dynamic> json) => ToViewItem(
    archive: MusicArchive(
      aid: int.tryParse(json['aid']?.toString() ?? '') ?? 0,
      bvid: json['bvid']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      cover: _https(json['pic']?.toString() ?? ''),
      upName: json['owner']?['name']?.toString() ?? '',
      upMid: int.tryParse(json['owner']?['mid']?.toString() ?? '') ?? 0,
      duration: int.tryParse(json['duration']?.toString() ?? '') ?? 0,
    ),
    cid: int.tryParse(json['cid']?.toString() ?? '') ?? 0,
    addAt: int.tryParse(json['add_at']?.toString() ?? '') ?? 0,
  );

  final MusicArchive archive;
  final int cid;
  final int addAt;
}

/// One video dynamic row (`x/polymer/web-dynamic/v1/feed/all?type=video`).
class DynamicVideo {
  const DynamicVideo({
    required this.archive,
    this.pubTime = '',
  });

  factory DynamicVideo.fromJson(Map<dynamic, dynamic> json) {
    final author = json['modules']?['module_author'];
    final dynamicModule = json['modules']?['module_dynamic'];
    final major = dynamicModule?['major'];
    final archiveJson = major?['archive'] ?? major?['pgc'];
    if (archiveJson == null) return const DynamicVideo(archive: MusicArchive(aid: 0, bvid: '', title: '', cover: '', upName: ''));
    return DynamicVideo(
      archive: MusicArchive(
        aid: int.tryParse(archiveJson['aid']?.toString() ?? '') ?? 0,
        bvid: archiveJson['bvid']?.toString() ?? '',
        title: archiveJson['title']?.toString() ?? '',
        cover: _https(archiveJson['cover']?.toString() ?? ''),
        duration: _parseDurationText(archiveJson['duration_text']?.toString() ?? ''),
        upName: author?['name']?.toString() ?? '',
        upMid: int.tryParse(author?['mid']?.toString() ?? '') ?? 0,
        upFace: _https(author?['face']?.toString() ?? ''),
      ),
      pubTime: author?['pub_time']?.toString() ?? '',
    );
  }

  final MusicArchive archive;
  final String pubTime;

  bool get isEmpty => archive.bvid.isEmpty && archive.aid == 0;

  static String _https(String url) => url.startsWith('//') ? 'https:$url' : url;

  static int _parseDurationText(String text) {
    final parts = text.split(':');
    if (parts.length == 2) return (int.tryParse(parts[0]) ?? 0) * 60 + (int.tryParse(parts[1]) ?? 0);
    if (parts.length == 3) {
      return (int.tryParse(parts[0]) ?? 0) * 3600 + (int.tryParse(parts[1]) ?? 0) * 60 + (int.tryParse(parts[2]) ?? 0);
    }
    return 0;
  }
}

/// One comment (`x/v2/reply/wbi/main` root rows and `x/v2/reply/reply`
/// sub-rows share the shape).
class CommentItem {
  const CommentItem({
    required this.rpid,
    required this.oid,
    required this.type,
    required this.mid,
    required this.uname,
    required this.face,
    required this.content,
    required this.ctime,
    this.like = 0,
    this.rcount = 0,
    this.liked = false,
    this.isTop = false,
    this.isUp = false,
    this.replies = const [],
  });

  factory CommentItem.fromJson(Map<dynamic, dynamic> json) {
    final member = json['member'];
    final replies = (json['replies'] as List?) ?? const [];
    return CommentItem(
      rpid: int.tryParse(json['rpid']?.toString() ?? '') ?? 0,
      oid: int.tryParse(json['oid']?.toString() ?? '') ?? 0,
      type: int.tryParse(json['type']?.toString() ?? '') ?? 1,
      mid: int.tryParse(member?['mid']?.toString() ?? '') ?? 0,
      uname: member?['uname']?.toString() ?? '',
      face: _https(member?['avatar']?.toString() ?? ''),
      content: json['content']?['message']?.toString() ?? '',
      ctime: int.tryParse(json['ctime']?.toString() ?? '') ?? 0,
      like: int.tryParse(json['like']?.toString() ?? '') ?? 0,
      rcount: int.tryParse(json['rcount']?.toString() ?? '') ?? 0,
      liked: (int.tryParse(json['action']?.toString() ?? '') ?? 0) == 1,
      isTop: (int.tryParse(json['upper_forbid']?['status']?.toString() ?? '-1') ?? -1) == 0 || json['isTop'] == true,
      isUp: (int.tryParse(json['up_action']?['like']?.toString() ?? '-1') ?? -1) >= 0 && json['isUp'] == true,
      replies: [for (final r in replies.take(3)) CommentItem.fromJson(r)],
    );
  }

  final int rpid;
  final int oid;
  final int type;
  final int mid;
  final String uname;
  final String face;
  final String content;
  final int ctime;
  final int like;
  final int rcount;
  final bool liked;
  final bool isTop;
  final bool isUp;
  final List<CommentItem> replies;
}

/// The UP-facing profile of a user space page (`x/space/wbi/acc/info`).
class UserSpaceInfo {
  const UserSpaceInfo({
    this.mid = 0,
    this.name = '',
    this.face = '',
    this.sign = '',
    this.followers = 0,
    this.following = 0,
    this.videoCount = 0,
    this.isFollowed = false,
    this.level = 0,
  });

  final int mid;
  final String name;
  final String face;
  final String sign;
  final int followers;
  final int following;
  final int videoCount;
  final bool isFollowed;
  final int level;
}

/// One search result of type `user` / `bili_user`.
class SearchUserItem {
  const SearchUserItem({
    required this.mid,
    required this.uname,
    required this.face,
    this.sign = '',
    this.fans = 0,
    this.videoCount = 0,
  });

  factory SearchUserItem.fromJson(Map<dynamic, dynamic> json) => SearchUserItem(
    mid: int.tryParse(json['mid']?.toString() ?? '') ?? 0,
    uname: _strip(json['uname']?.toString() ?? ''),
    face: _https(json['upic']?.toString() ?? json['face']?.toString() ?? ''),
    sign: _strip(json['usign']?.toString() ?? ''),
    fans: int.tryParse(json['fans']?.toString() ?? '') ?? 0,
    videoCount: int.tryParse(json['videos']?.toString() ?? '') ?? 0,
  );

  final int mid;
  final String uname;
  final String face;
  final String sign;
  final int fans;
  final int videoCount;
}

/// One search result of type `live`.
class SearchLiveItem {
  const SearchLiveItem({
    required this.roomId,
    required this.title,
    required this.cover,
    required this.uname,
    this.online = 0,
    this.liveStatus = 0,
  });

  factory SearchLiveItem.fromJson(Map<dynamic, dynamic> json) => SearchLiveItem(
    roomId: int.tryParse(json['roomid']?.toString() ?? '') ?? 0,
    title: _strip(json['title']?.toString() ?? ''),
    cover: _https(json['cover']?.toString() ?? json['user_cover']?.toString() ?? ''),
    uname: _strip(json['uname']?.toString() ?? ''),
    online: int.tryParse(json['online']?.toString() ?? '') ?? 0,
    liveStatus: int.tryParse(json['live_status']?.toString() ?? '') ?? 0,
  );

  final int roomId;
  final String title;
  final String cover;
  final String uname;
  final int online;
  final int liveStatus;
}

/// One search result of type `movie` (a PGC season).
class SearchPgcItem {
  const SearchPgcItem({required this.seasonId, required this.title, required this.cover, this.episodeCount = 0});

  factory SearchPgcItem.fromJson(Map<dynamic, dynamic> json) => SearchPgcItem(
    seasonId: int.tryParse(json['season_id']?.toString() ?? '') ?? 0,
    title: _strip(json['title']?.toString() ?? ''),
    cover: _https(json['cover']?.toString() ?? ''),
    episodeCount: (json['episodes'] as List?)?.length ?? 0,
  );

  final int seasonId;
  final String title;
  final String cover;
  final int episodeCount;
}

/// One hot-search word (`x/web-interface/search/square`).
class Hotword {
  const Hotword({required this.keyword, this.icon = '', this.hotValue = 0});

  final String keyword;
  final String icon;
  final int hotValue;
}

/// One subtitle track of a video (`x/player/wbi/v2` → `subtitle.subtitles`).
class SubtitleTrack {
  const SubtitleTrack({required this.lan, required this.lanDoc, required this.url});

  factory SubtitleTrack.fromJson(Map<dynamic, dynamic> json) {
    var url = json['subtitle_url']?.toString() ?? '';
    if (url.startsWith('//')) url = 'https:$url';
    return SubtitleTrack(lan: json['lan']?.toString() ?? '', lanDoc: json['lan_doc']?.toString() ?? '', url: url);
  }

  final String lan;
  final String lanDoc;
  final String url;
}

/// One subtitle cue (the fetched json's `body` entries).
class SubtitleCue {
  const SubtitleCue({required this.from, required this.to, required this.text});

  final double from;
  final double to;
  final String text;
}

String _https(String url) => url.startsWith('//') ? 'https:$url' : url;

String _strip(String text) => text.replaceAll(RegExp(r'</?em[^>]*>'), '');
