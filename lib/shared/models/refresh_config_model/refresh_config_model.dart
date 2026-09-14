import 'package:freezed_annotation/freezed_annotation.dart';

part 'refresh_config_model.freezed.dart';
part 'refresh_config_model.g.dart';

@freezed
abstract class RefreshConfig with _$RefreshConfig {
  const factory RefreshConfig({
    @Default(true) bool autoRefreshFavorite,
    @Default(60) int autoRefreshInterval,
    @Default(3) int maxConcurrentRefresh,
  }) = _RefreshConfig;

  factory RefreshConfig.fromJson(Map<String, dynamic> json) => _$RefreshConfigFromJson(json);
}
