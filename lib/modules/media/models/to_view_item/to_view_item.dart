import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:pure_live/modules/media/models/json_converters.dart';
import 'package:pure_live/modules/media/models/music_archive/music_archive.dart';

part 'to_view_item.freezed.dart';

/// One 稍后再看 row (`x/v2/history/toview`).
@freezed
abstract class ToViewItem with _$ToViewItem {
  const factory ToViewItem({
    required MusicArchive archive,
    @Default(0) int cid,
    @Default(0) int addAt,
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
    );
  }
}
