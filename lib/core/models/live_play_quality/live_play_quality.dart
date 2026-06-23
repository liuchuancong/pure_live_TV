import 'package:freezed_annotation/freezed_annotation.dart';

part 'live_play_quality.freezed.dart';
part 'live_play_quality.g.dart';

@freezed
abstract class LivePlayQuality with _$LivePlayQuality {
  const factory LivePlayQuality({required String quality, dynamic data, @Default(0) int sort}) = _LivePlayQuality;

  factory LivePlayQuality.fromJson(Map<String, dynamic> json) => _$LivePlayQualityFromJson(json);
}
