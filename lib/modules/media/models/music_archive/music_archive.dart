import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:pure_live/modules/media/models/json_converters.dart';
import 'package:pure_live/modules/media/models/music_part/music_part.dart';
import 'package:pure_live/modules/media/models/music_track/music_track.dart';

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
    @Default([]) List<MusicPart> parts,
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
      parts: parts,
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
