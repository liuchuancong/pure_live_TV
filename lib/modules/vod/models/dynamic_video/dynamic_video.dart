import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:pure_live/modules/vod/models/json_converters.dart';
import 'package:pure_live/modules/vod/models/music_archive/music_archive.dart';

part 'dynamic_video.freezed.dart';

/// One video dynamic row (`x/polymer/web-dynamic/v1/feed/all?type=video`):
/// the payload buries the archive under `modules.module_dynamic.major` (which
/// doubles as `archive` or `pgc`) — hand-mapped.
@freezed
abstract class DynamicVideo with _$DynamicVideo {
  const factory DynamicVideo({
    required MusicArchive archive,
    @Default('') String pubTime,
  }) = _DynamicVideo;

  factory DynamicVideo.fromJson(Map<dynamic, dynamic> json) {
    final author = json['modules']?['module_author'];
    final dynamicModule = json['modules']?['module_dynamic'];
    final major = dynamicModule?['major'];
    final archiveJson = major?['archive'] ?? major?['pgc'];
    if (archiveJson == null) {
      return const DynamicVideo(archive: MusicArchive(aid: 0, bvid: '', title: '', cover: '', upName: ''));
    }
    return DynamicVideo(
      archive: MusicArchive(
        aid: int.tryParse(archiveJson['aid']?.toString() ?? '') ?? 0,
        bvid: archiveJson['bvid']?.toString() ?? '',
        title: archiveJson['title']?.toString() ?? '',
        cover: httpsUrl(archiveJson['cover']?.toString() ?? ''),
        duration: durationTextToSeconds(archiveJson['duration_text']?.toString() ?? ''),
        upName: author?['name']?.toString() ?? '',
        upMid: int.tryParse(author?['mid']?.toString() ?? '') ?? 0,
        upFace: httpsUrl(author?['face']?.toString() ?? ''),
      ),
      pubTime: author?['pub_time']?.toString() ?? '',
    );
  }

  const DynamicVideo._();

  bool get isEmpty => archive.bvid.isEmpty && archive.aid == 0;
}
