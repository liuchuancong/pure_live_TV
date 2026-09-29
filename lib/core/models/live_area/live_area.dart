import 'package:freezed_annotation/freezed_annotation.dart';

part 'live_area.freezed.dart';
part 'live_area.g.dart';

@freezed
abstract class LiveArea with _$LiveArea {
  const factory LiveArea({
    @Default('') String platform,
    @Default('') String areaType,
    @Default('') String typeName,
    @Default('') String areaId,
    @Default('') String areaName,
    @Default('') String areaPic,
    @Default('') String shortName,
  }) = _LiveArea;

  factory LiveArea.fromJson(Map<String, dynamic> json) => _$LiveAreaFromJson(json);
}
