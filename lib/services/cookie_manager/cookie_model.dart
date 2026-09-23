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
    @Default('') String douyinCookie,
    @Default('') String kuaishouCookie,
    @Default('') String yyCookie,
    @Default('') String soopCookie,
    @Default('') String twitchCookie,
    @Default('') String taobaoCookie,
  }) = _CookieModel;

  factory CookieModel.fromJson(Map<String, dynamic> json) => _$CookieModelFromJson(json);
}
