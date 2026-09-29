import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:pure_live/modules/vod/models/json_converters.dart';

part 'comment_item.freezed.dart';

/// One comment (`x/v2/reply/wbi/main` root rows and `x/v2/reply/reply`
/// sub-rows share the shape): author fields live in `member`, the text in
/// `content.message`, and the top-3 sub-replies ride along — hand-mapped.
@freezed
abstract class CommentItem with _$CommentItem {
  const factory CommentItem({
    @Default(0) int rpid,
    @Default(0) int oid,
    @Default(1) int type,
    @Default(0) int mid,
    @Default('') String uname,
    @Default('') String face,
    @Default('') String content,
    @Default(0) int ctime,
    @Default(0) int like,
    @Default(0) int rcount,
    @Default(false) bool liked,
    @Default(false) bool isTop,
    @Default(false) bool isUp,
    @Default([]) List<CommentItem> replies,
  }) = _CommentItem;

  factory CommentItem.fromJson(Map<dynamic, dynamic> json) {
    final member = json['member'];
    final replies = (json['replies'] as List?) ?? const [];
    return CommentItem(
      rpid: int.tryParse(json['rpid']?.toString() ?? '') ?? 0,
      oid: int.tryParse(json['oid']?.toString() ?? '') ?? 0,
      type: int.tryParse(json['type']?.toString() ?? '') ?? 1,
      mid: int.tryParse(member?['mid']?.toString() ?? '') ?? 0,
      uname: member?['uname']?.toString() ?? '',
      face: httpsUrl(member?['avatar']?.toString() ?? ''),
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
}
