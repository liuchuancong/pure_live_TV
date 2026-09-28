/// Models for the bilibili music (UGC archive) mode.
///
/// A "song" here is one part (part) of a bilibili video archive: the ranking
/// grid and the search grid show archives, and opening one flattens its parts
/// into the play queue. Keeping the archive and the part separate is what lets
/// Continuous play walks "parts of this archive first, then the next archive" — the rule
/// the reference TV client (newBV) uses.
library;

/// A bilibili video archive as the music grids show it.
class MusicArchive {
  const MusicArchive({
    required this.aid,
    required this.bvid,
    required this.title,
    required this.cover,
    required this.upName,
    this.tid = 0,
    this.upMid = 0,
    this.upFace = '',
    this.duration = 0,
    this.playCount = 0,
    this.barrageCount = 0,
    this.description = '',
    this.tname = '',
    this.publishDate = '',
    this.parts = const [],
  });

  factory MusicArchive.fromRankingJson(Map<dynamic, dynamic> json) {
    return MusicArchive(
      aid: int.tryParse(json['aid']?.toString() ?? '') ?? 0,
      bvid: json['bvid']?.toString() ?? '',
      title: _stripHighlight(json['title']?.toString() ?? ''),
      cover: _https(json['pic']?.toString() ?? ''),
      upName: json['owner']?['name']?.toString() ?? '',
      tid: int.tryParse(json['tid']?.toString() ?? '') ?? 0,
      upMid: int.tryParse(json['owner']?['mid']?.toString() ?? '') ?? 0,
      upFace: _https(json['owner']?['face']?.toString() ?? ''),
      duration: int.tryParse(json['duration']?.toString() ?? '') ?? 0,
      playCount: int.tryParse(json['stat']?['view']?.toString() ?? '') ?? 0,
      barrageCount: int.tryParse(json['stat']?['danmaku']?.toString() ?? '') ?? 0,
      tname: json['tname']?.toString() ?? '',
    );
  }

  factory MusicArchive.fromSearchJson(Map<dynamic, dynamic> json) {
    return MusicArchive(
      aid: int.tryParse(json['aid']?.toString() ?? '') ?? 0,
      bvid: json['bvid']?.toString() ?? '',
      title: _stripHighlight(json['title']?.toString() ?? ''),
      cover: _https(json['pic']?.toString() ?? ''),
      upName: json['author']?.toString() ?? '',
      tid: int.tryParse(json['tid']?.toString() ?? '') ?? 0,
      tname: json['typename']?.toString() ?? '',
      upFace: _https(json['upic']?.toString() ?? ''),
      duration: _parseDurationText(json['duration']?.toString() ?? ''),
      playCount: int.tryParse(json['play']?.toString() ?? '') ?? 0,
      barrageCount: int.tryParse(json['video_review']?.toString() ?? '') ?? 0,
      description: json['description']?.toString() ?? '',
    );
  }

  /// The `view` API payload: the archive plus its full part list.
  factory MusicArchive.fromViewJson(Map<dynamic, dynamic> json) {
    final pages = (json['pages'] as List?) ?? const [];
    final duration = int.tryParse(json['duration']?.toString() ?? '') ?? 0;
    final parts = [
      for (final page in pages)
        MusicPart(
          cid: int.tryParse(page['cid']?.toString() ?? '') ?? 0,
          page: int.tryParse(page['page']?.toString() ?? '') ?? 1,
          title: page['part']?.toString().isNotEmpty == true ? page['part'].toString() : (json['title']?.toString() ?? ''),
          duration: int.tryParse(page['duration']?.toString() ?? '') ?? 0,
        ),
    ];
    return MusicArchive(
      aid: int.tryParse(json['aid']?.toString() ?? '') ?? 0,
      bvid: json['bvid']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      cover: _https(json['pic']?.toString() ?? ''),
      upName: json['owner']?['name']?.toString() ?? '',
      upMid: int.tryParse(json['owner']?['mid']?.toString() ?? '') ?? 0,
      upFace: _https(json['owner']?['face']?.toString() ?? ''),
      duration: duration,
      playCount: int.tryParse(json['stat']?['view']?.toString() ?? '') ?? 0,
      barrageCount: int.tryParse(json['stat']?['danmaku']?.toString() ?? '') ?? 0,
      description: json['desc']?.toString() ?? '',
      tname: json['tname']?.toString() ?? '',
      publishDate: _formatTimestamp(int.tryParse(json['pubdate']?.toString() ?? '') ?? 0),
      parts: parts,
    );
  }

  final int aid;
  final String bvid;
  final String title;
  final String cover;
  final String upName;
  final int tid;
  final int upMid;
  final String upFace;
  final int duration;
  final int playCount;
  final int barrageCount;
  final String description;
  final String tname;
  final String publishDate;
  final List<MusicPart> parts;

  /// One part per queue entry; a single-part archive still yields one track.
  List<MusicTrack> get tracks {
    if (parts.isEmpty) {
      return [MusicTrack(archive: this, part: MusicPart(cid: 0, page: 1, title: title, duration: duration))];
    }
    return [for (final part in parts) MusicTrack(archive: this, part: part)];
  }

  /// JSON round-trip for the music library's Hive persistence (favorites and
  /// recent plays survive restarts as JSON string lists).
  Map<String, dynamic> toJson() => {
    'aid': aid,
    'bvid': bvid,
    'title': title,
    'cover': cover,
    'upName': upName,
    'upMid': upMid,
    'upFace': upFace,
    'duration': duration,
    'playCount': playCount,
    'barrageCount': barrageCount,
    'description': description,
    'tname': tname,
    'publishDate': publishDate,
    'parts': [for (final p in parts) p.toJson()],
  };

  factory MusicArchive.fromJson(Map<String, dynamic> json) => MusicArchive(
    aid: int.tryParse(json['aid']?.toString() ?? '') ?? 0,
    bvid: json['bvid']?.toString() ?? '',
    title: json['title']?.toString() ?? '',
    cover: json['cover']?.toString() ?? '',
    upName: json['upName']?.toString() ?? '',
    upMid: int.tryParse(json['upMid']?.toString() ?? '') ?? 0,
    upFace: json['upFace']?.toString() ?? '',
    duration: int.tryParse(json['duration']?.toString() ?? '') ?? 0,
    playCount: int.tryParse(json['playCount']?.toString() ?? '') ?? 0,
    barrageCount: int.tryParse(json['barrageCount']?.toString() ?? '') ?? 0,
    description: json['description']?.toString() ?? '',
    tname: json['tname']?.toString() ?? '',
    publishDate: json['publishDate']?.toString() ?? '',
    parts: [
      for (final p in (json['parts'] as List?) ?? const <dynamic>[])
        if (p is Map<String, dynamic>) MusicPart.fromJson(p),
    ],
  );

  /// One entry of `archive/related` — the daily-recommendation seed payload.
  factory MusicArchive.fromRelatedJson(Map<dynamic, dynamic> json) {
    return MusicArchive(
      aid: int.tryParse(json['aid']?.toString() ?? '') ?? 0,
      bvid: json['bvid']?.toString() ?? '',
      title: _stripHighlight(json['title']?.toString() ?? ''),
      cover: _https(json['pic']?.toString() ?? ''),
      upName: json['owner']?['name']?.toString() ?? '',
      upMid: int.tryParse(json['owner']?['mid']?.toString() ?? '') ?? 0,
      upFace: _https(json['owner']?['face']?.toString() ?? ''),
      tid: int.tryParse(json['tid']?.toString() ?? '') ?? 0,
      tname: json['tname']?.toString() ?? '',
      duration: int.tryParse(json['duration']?.toString() ?? '') ?? 0,
      playCount: int.tryParse(json['stat']?['view']?.toString() ?? '') ?? 0,
    );
  }

  static String _stripHighlight(String text) => text.replaceAll(RegExp(r'</?em>'), '');

  static String _https(String url) => url.startsWith('//') ? 'https:$url' : url;

  /// Search results carry "mm:ss" strings instead of seconds.
  static int _parseDurationText(String text) {
    final parts = text.split(':');
    if (parts.length == 2) {
      return (int.tryParse(parts[0]) ?? 0) * 60 + (int.tryParse(parts[1]) ?? 0);
    }
    return 0;
  }

  static String _formatTimestamp(int seconds) {
    if (seconds <= 0) return '';
    final date = DateTime.fromMillisecondsSinceEpoch(seconds * 1000);
    return '${date.year}/${date.month.toString().padLeft(2, '0')}/${date.day.toString().padLeft(2, '0')}';
  }
}

/// One part (part) of an archive — the unit the queue plays.
class MusicPart {
  const MusicPart({required this.cid, required this.page, required this.title, required this.duration, this.epId = 0});

  final int cid;
  final int page;
  final String title;
  final int duration;

  /// PGC episodes play through the pgc playurl endpoint instead; 0 = plain UGC.
  final int epId;

  Map<String, dynamic> toJson() => {'cid': cid, 'page': page, 'title': title, 'duration': duration, 'epId': epId};

  factory MusicPart.fromJson(Map<String, dynamic> json) => MusicPart(
    cid: int.tryParse(json['cid']?.toString() ?? '') ?? 0,
    page: int.tryParse(json['page']?.toString() ?? '') ?? 1,
    title: json['title']?.toString() ?? '',
    duration: int.tryParse(json['duration']?.toString() ?? '') ?? 0,
    epId: int.tryParse(json['epId']?.toString() ?? '') ?? 0,
  );
}

/// A queue entry: which part of which archive.
class MusicTrack {
  const MusicTrack({required this.archive, required this.part});

  final MusicArchive archive;
  final MusicPart part;

  String get id => '${archive.bvid}_p${part.page}_${part.cid}';

  /// Display name: the part title; the archive title already is the part title
  /// for single-part uploads.
  String get title => part.title;
}

/// A followed uploader — the 作者 side of the music 关注 page. Stored by mid,
/// so a follow survives the archive rows it was made from.
class MusicUp {
  const MusicUp({required this.mid, required this.name, this.face = ''});

  final int mid;
  final String name;
  final String face;

  Map<String, dynamic> toJson() => {'mid': mid, 'name': name, 'face': face};

  factory MusicUp.fromJson(Map<String, dynamic> json) => MusicUp(
    mid: int.tryParse(json['mid']?.toString() ?? '') ?? 0,
    name: json['name']?.toString() ?? '',
    face: json['face']?.toString() ?? '',
  );
}

/// One DASH video rendition (a quality/codec candidate). The playurl answer
/// carries them all at once, so switching quality re-opens a URL from here
/// instead of asking the API again.
class MusicStreamOption {
  const MusicStreamOption({
    required this.quality,
    required this.url,
    this.codecs = '',
    this.backupUrls = const [],
  });

  final int quality;
  final String url;
  final String codecs;
  final List<String> backupUrls;
}

/// Resolved playback URLs for one track.
class MusicPlayUrls {
  const MusicPlayUrls({
    required this.videoUrl,
    this.audioUrl,
    this.videoBackupUrls = const [],
    this.quality = 0,
    this.isDash = true,
    this.videoOptions = const [],
  });

  /// The stream to hand the player as the primary source. For DASH this is the
  /// video-only m4s (the audio rides along through the player's audio-file
  /// input); for the mp4 fallback it is the muxed file.
  final String videoUrl;

  /// The DASH audio m4s. Null for the muxed mp4 fallback (and for audio-only
  /// playback the audio URL itself becomes the primary source).
  final String? audioUrl;

  final List<String> videoBackupUrls;

  /// The quality id actually served (see [BilibiliMusicApi.qualityLabel]).
  final int quality;

  final bool isDash;

  /// Every quality the current answer can serve, AVC-preferred per tier.
  final List<MusicStreamOption> videoOptions;
}

/// Queue advance rules, cycled by one button.
enum MusicPlayMode {
  /// Wrap around the queue after the last track.
  sequence,

  /// Replay the current track.
  loopOne,

  /// Jump to a random different track.
  random;

  String get i18nKey => switch (this) {
    sequence => 'music_mode_sequence',
    loopOne => 'music_mode_loop_one',
    random => 'music_mode_random',
  };

  MusicPlayMode get next => switch (this) {
    sequence => loopOne,
    loopOne => random,
    random => sequence,
  };
}
