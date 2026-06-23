import 'package:freezed_annotation/freezed_annotation.dart';

part 'cookie_model.freezed.dart';
part 'cookie_model.g.dart';

@freezed
abstract class CookieModel with _$CookieModel {
  const factory CookieModel({
    @Default('') String bilibiliCookie,
    @Default(0) int bilibiliUid,
    @Default('') String huyaCookie,
    @Default('') String douyinCookie,
    @Default('') String kuaishouCookie,
  }) = _CookieModel;

  factory CookieModel.fromJson(Map<String, dynamic> json) => _$CookieModelFromJson(json);
}
