import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:pure_live/modules/media/models/json_converters.dart';
import 'package:pure_live/modules/media/models/music_archive/music_archive.dart';

part 'history_item.freezed.dart';

/// One row of the bilibili cloud history (`x/web-interface/history/cursor`):
/// the progress bookkeeping lives at the top level while the archive fields
/// hide inside `history` — hand-mapped.
@freezed
abstract class HistoryItem with _$HistoryItem {
  const factory HistoryItem({
    required MusicArchive archive,
    @Default(0) int cid,
    @Default(1) int page,
    @Default(0) int progress,
    @Default(0) int duration,
    @Default(0) int viewAt,

    /// PGC rows carry an episode id; video-mode history mixes both.
    @Default(0) int epid,
    @Default(0) int seasonId,
  }) = _HistoryItem;

  factory HistoryItem.fromJson(Map<dynamic, dynamic> json) {
    final history = json['history'];
    return HistoryItem(
      archive: MusicArchive(
        aid: int.tryParse(history?['oid']?.toString() ?? '') ?? 0,
        bvid: history?['bvid']?.toString() ?? '',
        title: json['show_title']?.toString() ?? json['title']?.toString() ?? '',
        cover: httpsUrl(json['cover']?.toString() ?? ''),
        upName: json['author_name']?.toString() ?? '',
        upMid: int.tryParse(json['author_mid']?.toString() ?? '') ?? 0,
        upFace: httpsUrl(json['author_face']?.toString() ?? ''),
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

  const HistoryItem._();

  bool get finished => duration > 0 && progress >= duration;
}
