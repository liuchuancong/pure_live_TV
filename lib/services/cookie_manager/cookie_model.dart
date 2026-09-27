import 'package:freezed_annotation/freezed_annotation.dart';

part 'cookie_model.freezed.dart';
part 'cookie_model.g.dart';

@freezed
abstract class CookieModel with _$CookieModel {
  const factory CookieModel({
    @Default('') String bilibiliCookie,
    @Default(0) int bilibiliUid,
    @Default('') String huyaCookie,
    @Default('') String douyuCookie,
    // Renewal credentials for the Douyu session (see DouyuUtils): they come
    // from the passport request, not the page cookie, so they live next to it.
    @Default('') String douyuLtp0,
    @Default('') String douyuDid,
    // Kept for backup compatibility: the seven-day rule it used to feed was
    // replaced by reading the JWT, but old backups still carry the field.
    @Default(0) int douyuCookieSavedAt,
    // Whether playback renews a Douyu FLV that states no lease before the CDN
    // closes it. A signed-in session's link carries `expire=0` while Douyu still
    // cuts it on its own schedule, so the renewed stream is opt-in from the
    // cookie page: anonymous links already say `expire=300` and need no switch.
    @Default(false) bool douyuForceRenewal,
    @Default('') String douyinCookie,
    @Default('') String kuaishouCookie,
    @Default('') String yyCookie,
    @Default('') String soopCookie,
    @Default('') String twitchCookie,
  }) = _CookieModel;

  factory CookieModel.fromJson(Map<String, dynamic> json) => _$CookieModelFromJson(json);
}
