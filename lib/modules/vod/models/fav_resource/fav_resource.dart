import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:pure_live/modules/vod/models/json_converters.dart';
import 'package:pure_live/modules/vod/models/music_archive/music_archive.dart';

part 'fav_resource.freezed.dart';

/// One archive inside a fav folder (`x/v3/fav/resource/list`): flat fields
/// plus nested `upper` (the uploader) and `cnt_info` (counters), with the
/// invalid flag encoded as attr bit 31 — mapping too conditional for codegen.
@freezed
abstract class FavResource with _$FavResource {
  const factory FavResource({
    @Default(0) int aid,
    @Default('') String bvid,
    @Default('') String title,
    @Default('') String cover,
    @Default(0) int duration,
    @Default(0) int playCount,
    @Default(0) int barrageCount,
    @Default('') String upName,
    @Default(0) int upMid,
    @Default('') String upFace,
    @Default(false) bool invalid,
  }) = _FavResource;

  const FavResource._();

  factory FavResource.fromJson(Map<dynamic, dynamic> json) {
    // attr bit 31 (1 << 31) marks a UP-deleted / invalid archive.
    final attr = int.tryParse(json['attr']?.toString() ?? '') ?? 0;
    final cnt = json['cnt_info'];
    return FavResource(
      aid: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      bvid: json['bvid']?.toString() ?? '',
      title: json['title']?.toString() ?? '',
      cover: httpsUrl(json['cover']?.toString() ?? ''),
      duration: int.tryParse(json['duration']?.toString() ?? '') ?? 0,
      playCount: int.tryParse(cnt?['play']?.toString() ?? '') ?? 0,
      barrageCount: int.tryParse(cnt?['danmaku']?.toString() ?? '') ?? 0,
      upName: json['upper']?['name']?.toString() ?? '',
      upMid: int.tryParse(json['upper']?['mid']?.toString() ?? '') ?? 0,
      upFace: httpsUrl(json['upper']?['face']?.toString() ?? ''),
      invalid: (attr >> 31 & 1) == 1 || json['title']?.toString() == '已失效视频',
    );
  }

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
}
