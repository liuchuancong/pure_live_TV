import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:pure_live/modules/vod/models/json_converters.dart';
import 'package:pure_live/modules/vod/models/music_archive/music_archive.dart';

part 'to_view_item.freezed.dart';

@freezed
abstract class ToViewItem with _$ToViewItem {
  const factory ToViewItem({
    required MusicArchive archive,
    @Default(0) int cid,
    @Default(0) int addAt,

    /// Server-side watched seconds; `-1` answers for a finished video — the
    /// reference app partitions its 稍后再看 grid on exactly that.
    @Default(0) int progress,
  }) = _ToViewItem;

  factory ToViewItem.fromJson(Map<dynamic, dynamic> json) {
    return ToViewItem(
      archive: MusicArchive(
        aid: int.tryParse(json['aid']?.toString() ?? '') ?? 0,
        bvid: json['bvid']?.toString() ?? '',
        title: json['title']?.toString() ?? '',
        cover: httpsUrl(json['pic']?.toString() ?? ''),
        upName: json['owner']?['name']?.toString() ?? '',
        upMid: int.tryParse(json['owner']?['mid']?.toString() ?? '') ?? 0,
        duration: int.tryParse(json['duration']?.toString() ?? '') ?? 0,
      ),
      cid: int.tryParse(json['cid']?.toString() ?? '') ?? 0,
      addAt: int.tryParse(json['add_at']?.toString() ?? '') ?? 0,
      progress: int.tryParse(json['progress']?.toString() ?? '') ?? 0,
    );
  }
}
