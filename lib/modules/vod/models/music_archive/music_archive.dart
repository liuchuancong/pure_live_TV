import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:pure_live/modules/vod/models/json_converters.dart';
import 'package:pure_live/modules/vod/models/music_part/music_part.dart';
import 'package:pure_live/modules/vod/models/music_track/music_track.dart';

part 'music_archive.freezed.dart';
part 'music_archive.g.dart';

/// A bilibili video archive as the music grids show it.
///
/// A "song" here is one part of an archive: the ranking grid and the search
/// grid show archives, and opening one flattens its parts into the play
/// queue. Keeping the archive and the part separate is what lets continuous
/// play walk "parts of this archive first, then the next archive" — the rule
/// the reference TV client (newBV) uses.
///
/// [fromJson]/[toJson] are the Hive round-trip shape (the music library's
/// favorites and recent plays survive restarts as JSON string lists); the
/// `from<X>Json` factories map the web API's answer shapes.
@freezed
abstract class MusicArchive with _$MusicArchive {
  const factory MusicArchive({
    @Default(0) int aid,
    @Default('') String bvid,
    @Default('') String title,
    @Default('') String cover,
    @Default('') String upName,
    @Default(0) int tid,
    @Default(0) int upMid,
    @Default('') String upFace,
    @Default(0) int duration,
    @Default(0) int playCount,
    @Default(0) int barrageCount,
    @Default('') String description,
    @Default('') String tname,
    @Default('') String publishDate,
    @Default(0) int likeCount,
    @Default(0) int coinCount,
    @Default(0) int favCount,
    @Default(0) int replyCount,
    @Default([]) List<MusicPart> parts,
    MusicSeason? season,
  }) = _MusicArchive;

  factory MusicArchive.fromJson(Map<String, dynamic> json) => _$MusicArchiveFromJson(json);

  /// The ranking / region leaderboard row (`ranking/v2?rid=`) and the
  /// related-archive row: owner and stat arrive nested.
  factory MusicArchive.fromRankingJson(Map<dynamic, dynamic> json) {
    return MusicArchive(
      aid: int.tryParse(json['aid']?.toString() ?? '') ?? 0,
      bvid: json['bvid']?.toString() ?? '',
      title: stripHtml(json['title']?.toString() ?? ''),
      cover: httpsUrl(json['pic']?.toString() ?? ''),
      upName: json['owner']?['name']?.toString() ?? '',
      tid: int.tryParse(json['tid']?.toString() ?? '') ?? 0,
      upMid: int.tryParse(json['owner']?['mid']?.toString() ?? '') ?? 0,
      upFace: httpsUrl(json['owner']?['face']?.toString() ?? ''),
      duration: int.tryParse(json['duration']?.toString() ?? '') ?? 0,
      playCount: int.tryParse(json['stat']?['view']?.toString() ?? '') ?? 0,
      barrageCount: int.tryParse(json['stat']?['danmaku']?.toString() ?? '') ?? 0,
      tname: json['tname']?.toString() ?? '',
    );
  }

  /// The WBI search row: flat fields, "mm:ss" durations, `upic`/`play` keys.
  factory MusicArchive.fromSearchJson(Map<dynamic, dynamic> json) {
    return MusicArchive(
      aid: int.tryParse(json['aid']?.toString() ?? '') ?? 0,
      bvid: json['bvid']?.toString() ?? '',
      title: stripHtml(json['title']?.toString() ?? ''),
      cover: httpsUrl(json['pic']?.toString() ?? ''),
      upName: json['author']?.toString() ?? '',
      tid: int.tryParse(json['tid']?.toString() ?? '') ?? 0,
      tname: json['typename']?.toString() ?? '',
      upFace: httpsUrl(json['upic']?.toString() ?? ''),
      duration: durationTextToSeconds(json['duration']?.toString() ?? ''),
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
      cover: httpsUrl(json['pic']?.toString() ?? ''),
      upName: json['owner']?['name']?.toString() ?? '',
      upMid: int.tryParse(json['owner']?['mid']?.toString() ?? '') ?? 0,
      upFace: httpsUrl(json['owner']?['face']?.toString() ?? ''),
      duration: duration,
      playCount: int.tryParse(json['stat']?['view']?.toString() ?? '') ?? 0,
      barrageCount: int.tryParse(json['stat']?['danmaku']?.toString() ?? '') ?? 0,
      description: json['desc']?.toString() ?? '',
      tname: json['tname']?.toString() ?? '',
      publishDate: formatTimestamp(int.tryParse(json['pubdate']?.toString() ?? '') ?? 0),
      likeCount: int.tryParse(json['stat']?['like']?.toString() ?? '') ?? 0,
      coinCount: int.tryParse(json['stat']?['coin']?.toString() ?? '') ?? 0,
      favCount: int.tryParse(json['stat']?['favorite']?.toString() ?? '') ?? 0,
      replyCount: int.tryParse(json['stat']?['reply']?.toString() ?? '') ?? 0,
      parts: parts,
      season: json['ugc_season'] is Map ? MusicSeason.fromViewJson(json['ugc_season']) : null,
    );
  }

  /// A `region/feed/rcmd` archive (newBV's 分区 list): cover/author lead the
  /// record (`cover` not `pic`, `author` not `owner`), the play/danmaku counts
  /// nest under `stat`.
  factory MusicArchive.fromRegionFeedJson(Map<dynamic, dynamic> json) {
    return MusicArchive(
      aid: int.tryParse(json['aid']?.toString() ?? '') ?? 0,
      bvid: json['bvid']?.toString() ?? '',
      title: stripHtml(json['title']?.toString() ?? ''),
      cover: httpsUrl(json['cover']?.toString() ?? ''),
      upName: json['author']?['name']?.toString() ?? '',
      upMid: int.tryParse(json['author']?['mid']?.toString() ?? '') ?? 0,
      duration: int.tryParse(json['duration']?.toString() ?? '') ?? 0,
      playCount: int.tryParse(json['stat']?['view']?.toString() ?? '') ?? 0,
      barrageCount: int.tryParse(json['stat']?['danmaku']?.toString() ?? '') ?? 0,
      publishDate: formatTimestamp(int.tryParse(json['pubdate']?.toString() ?? '') ?? 0),
    );
  }

  /// One entry of `archive/related` — the daily-recommendation seed payload.
  factory MusicArchive.fromRelatedJson(Map<dynamic, dynamic> json) {
    return MusicArchive(
      aid: int.tryParse(json['aid']?.toString() ?? '') ?? 0,
      bvid: json['bvid']?.toString() ?? '',
      title: stripHtml(json['title']?.toString() ?? ''),
      cover: httpsUrl(json['pic']?.toString() ?? ''),
      upName: json['owner']?['name']?.toString() ?? '',
      upMid: int.tryParse(json['owner']?['mid']?.toString() ?? '') ?? 0,
      upFace: httpsUrl(json['owner']?['face']?.toString() ?? ''),
      tid: int.tryParse(json['tid']?.toString() ?? '') ?? 0,
      tname: json['tname']?.toString() ?? '',
      duration: int.tryParse(json['duration']?.toString() ?? '') ?? 0,
      playCount: int.tryParse(json['stat']?['view']?.toString() ?? '') ?? 0,
    );
  }

  const MusicArchive._();

  /// One part per queue entry; a single-part archive still yields one track.
  List<MusicTrack> get tracks {    if (parts.isEmpty) {
      return [MusicTrack(archive: this, part: MusicPart(cid: 0, page: 1, title: title, duration: duration))];
    }
    return [for (final part in parts) MusicTrack(archive: this, part: part)];
  }
}

/// An archive's 合集 (`view`'s `ugc_season`): the UP grouped the videos into
/// sections of episodes, each episode being another archive.
@freezed
abstract class MusicSeason with _$MusicSeason {
  const factory MusicSeason({
    @Default(0) int id,
    @Default('') String title,
    @Default([]) List<MusicSeasonSection> sections,
  }) = _MusicSeason;

  factory MusicSeason.fromJson(Map<String, dynamic> json) => _$MusicSeasonFromJson(json);

  factory MusicSeason.fromViewJson(Map<dynamic, dynamic> json) {
    return MusicSeason(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      title: json['title']?.toString() ?? '',
      sections: [
        for (final section in (json['sections'] as List?) ?? const [])
          if (section is Map) MusicSeasonSection.fromViewJson(section),
      ],
    );
  }
}

@freezed
abstract class MusicSeasonSection with _$MusicSeasonSection {
  const factory MusicSeasonSection({
    @Default('') String title,
    @Default([]) List<MusicArchive> episodes,
  }) = _MusicSeasonSection;

  factory MusicSeasonSection.fromJson(Map<String, dynamic> json) => _$MusicSeasonSectionFromJson(json);

  /// Episodes arrive as partial archives — enough identity for the detail
  /// page to reopen each one by bvid; the cover/duration keys the section
  /// payload uses differ from the archive ones (`arc` nesting), so this maps
  /// them explicitly rather than reusing `fromViewJson`.
  factory MusicSeasonSection.fromViewJson(Map<dynamic, dynamic> json) {
    return MusicSeasonSection(
      title: json['title']?.toString() ?? '',
      episodes: [
        for (final ep in (json['episodes'] as List?) ?? const [])
          if (ep is Map && (ep['bvid']?.toString() ?? '').isNotEmpty)
            MusicArchive(
              aid: int.tryParse(ep['aid']?.toString() ?? '') ?? 0,
              bvid: ep['bvid'].toString(),
              title: ep['title']?.toString() ?? '',
              cover: httpsUrl(ep['cover']?.toString() ?? ep['arc']?['cover']?.toString() ?? ''),
              duration: int.tryParse(ep['duration']?.toString() ?? ep['arc']?['duration']?.toString() ?? '') ?? 0,
              upName: ep['author']?.toString() ?? '',
            ),
      ],
    );
  }
}
