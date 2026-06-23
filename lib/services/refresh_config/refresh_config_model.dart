import 'package:freezed_annotation/freezed_annotation.dart';

part 'refresh_config_model.freezed.dart';
part 'refresh_config_model.g.dart';

@freezed
abstract class RefreshConfigModel with _$RefreshConfigModel {
  const factory RefreshConfigModel({
    @Default(false) bool autoRefreshFavorite,
    @Default(30) int autoRefreshInterval,
    @Default(2) int maxConcurrentRefresh,
  }) = _RefreshConfigModel;

  factory RefreshConfigModel.fromJson(Map<String, dynamic> json) => _$RefreshConfigModelFromJson(json);
}
