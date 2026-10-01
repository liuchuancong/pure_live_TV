import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:pure_live/modules/vod/models/json_converters.dart';

part 'comment_item.freezed.dart';

/// One comment (`x/v2/reply/wbi/main` root rows and `x/v2/reply/reply`
/// sub-rows share the shape): author fields live in `member`, the text in
/// `content.message`, the author level in `member.level_info`, any attached
/// images in `content.pictures`, and the top-3 sub-replies ride along —
/// hand-mapped to mirror newBV's `Comment.fromJson`.
@freezed
abstract class CommentItem with _$CommentItem {
  const factory CommentItem({
    @Default(0) int rpid,
    @Default(0) int oid,
    @Default(1) int type,
    @Default(0) int mid,
    @Default('') String uname,
    @Default('') String face,
    @Default(0) int level,
    @Default('') String content,
    @Default([]) List<String> pictures,
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
    final content = json['content'];
    final control = json['reply_control'];
    final replies = (json['replies'] as List?) ?? const [];
    // The like state lives in reply_control on the paged feed and falls back
    // to the root user_action; new reply rows carry neither until toggled.
    final action = int.tryParse((control?['action'] ?? json['user_action'])?.toString() ?? '') ?? 0;
    final pictures = [
      for (final p in (content?['pictures'] as List?) ?? const [])
        httpsUrl(p?['img_src']?.toString() ?? ''),
    ].where((url) => url.isNotEmpty).toList();
    return CommentItem(
      rpid: int.tryParse(json['rpid']?.toString() ?? '') ?? 0,
      oid: int.tryParse(json['oid']?.toString() ?? '') ?? 0,
      type: int.tryParse(json['type']?.toString() ?? '') ?? 1,
      mid: int.tryParse(member?['mid']?.toString() ?? '') ?? 0,
      uname: member?['uname']?.toString() ?? '',
      face: httpsUrl(member?['avatar']?.toString() ?? ''),
      level: int.tryParse(member?['level_info']?['current_level']?.toString() ?? '') ?? 0,
      content: content?['message']?.toString() ?? '',
      pictures: pictures,
      ctime: int.tryParse(json['ctime']?.toString() ?? '') ?? 0,
      like: int.tryParse(json['like']?.toString() ?? '') ?? 0,
      rcount: int.tryParse(json['rcount']?.toString() ?? '') ?? 0,
      liked: action == 1,
      isTop: (int.tryParse(json['upper_forbid']?['status']?.toString() ?? '-1') ?? -1) == 0 || json['isTop'] == true,
      isUp: control?['up_like'] == true || control?['is_up_top'] == true,
      replies: [for (final r in replies.take(3)) CommentItem.fromJson(r)],
    );
  }
}
