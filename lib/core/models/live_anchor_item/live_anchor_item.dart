import 'package:freezed_annotation/freezed_annotation.dart';

part 'live_anchor_item.freezed.dart';
part 'live_anchor_item.g.dart';

@freezed
abstract class LiveAnchorItem with _$LiveAnchorItem {
  const factory LiveAnchorItem({
    required String roomId,
    required String avatar,
    required String userName,
    required bool liveStatus,
  }) = _LiveAnchorItem;

  factory LiveAnchorItem.fromJson(Map<String, dynamic> json) => _$LiveAnchorItemFromJson(json);
}
