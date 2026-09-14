import 'package:freezed_annotation/freezed_annotation.dart';

part 'bilibili_user_info.freezed.dart';
part 'bilibili_user_info.g.dart';

@freezed
abstract class BilibiliUserInfo with _$BilibiliUserInfo {
  const factory BilibiliUserInfo({
    int? mid,
    String? uname,
    String? userid,
    String? sign,
    String? birthday,
    String? sex,
    @JsonKey(name: 'nick_free') bool? nickFree,
    String? rank,
  }) = _BilibiliUserInfo;

  factory BilibiliUserInfo.fromJson(Map<String, dynamic> json) => _$BilibiliUserInfoFromJson(json);
}
