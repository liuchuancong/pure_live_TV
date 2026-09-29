import 'package:freezed_annotation/freezed_annotation.dart';

part 'ugc_my_info.freezed.dart';

/// The logged-in account (`x/web-interface/nav`), the login gate's state
/// source beyond "a cookie exists". The nav answer's level/vip fields are
/// nested or flag-shaped, so the mapping stays hand-written; [LenientInt]/
/// [LenientString] style leniency is applied inline.
@freezed
abstract class UgcMyInfo with _$UgcMyInfo {
  const factory UgcMyInfo({
    required bool isLogin,
    @Default(0) int mid,
    @Default('') String uname,
    @Default('') String face,
    @Default(0) int level,
    @Default(0) double coin,
    @Default(false) bool vip,
  }) = _UgcMyInfo;

  factory UgcMyInfo.fromNavJson(Map<dynamic, dynamic> json) {
    return UgcMyInfo(
      isLogin: json['isLogin'] == true,
      mid: int.tryParse(json['mid']?.toString() ?? '') ?? 0,
      uname: json['uname']?.toString() ?? '',
      face: json['face']?.toString() ?? '',
      level: int.tryParse(json['level_info']?['current_level']?.toString() ?? '') ?? 0,
      coin: double.tryParse(json['money']?.toString() ?? '') ?? 0,
      vip: (int.tryParse(json['vipStatus']?.toString() ?? '') ?? 0) > 0,
    );
  }
}
