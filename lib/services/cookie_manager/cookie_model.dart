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
    // When the Douyu cookie was saved, in seconds: the web dy_auth is opaque,
    // so its seven-day lifetime is counted from this timestamp.
    @Default(0) int douyuCookieSavedAt,
    @Default('') String douyinCookie,
    @Default('') String kuaishouCookie,
    @Default('') String yyCookie,
    @Default('') String soopCookie,
    @Default('') String twitchCookie,
  }) = _CookieModel;

  factory CookieModel.fromJson(Map<String, dynamic> json) => _$CookieModelFromJson(json);
}
