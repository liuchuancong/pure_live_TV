import 'package:freezed_annotation/freezed_annotation.dart';

part 'user_space_info.freezed.dart';

/// The UP-facing profile of a user space page (`x/space/wbi/acc/info`).
/// The api layer assembles it from the acc-info and relation round-trips, so
/// there is no single JSON shape to map.
@freezed
abstract class UserSpaceInfo with _$UserSpaceInfo {
  const factory UserSpaceInfo({
    @Default(0) int mid,
    @Default('') String name,
    @Default('') String face,
    @Default('') String sign,
    @Default(0) int followers,
    @Default(0) int following,
    @Default(0) int videoCount,
    @Default(false) bool isFollowed,
    @Default(0) int level,
  }) = _UserSpaceInfo;
}
