import 'package:freezed_annotation/freezed_annotation.dart';

part 'hotword.freezed.dart';
part 'hotword.g.dart';

/// One hot-search word (`x/web-interface/search/square`).
@freezed
abstract class Hotword with _$Hotword {
  const factory Hotword({
    @Default('') String keyword,
    @Default('') String icon,
    @Default(0) int hotValue,
  }) = _Hotword;

  factory Hotword.fromJson(Map<String, dynamic> json) => _$HotwordFromJson(json);
}
