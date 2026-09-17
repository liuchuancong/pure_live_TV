import 'package:freezed_annotation/freezed_annotation.dart';

part 'refresh_config_model.freezed.dart';
part 'refresh_config_model.g.dart';

@freezed
abstract class RefreshConfigModel with _$RefreshConfigModel {
  const factory RefreshConfigModel({
    @Default(false) bool autoRefreshFavorite,
    @Default(30) int autoRefreshInterval,
    @Default(2) int maxConcurrentRefresh,

    /// Whether the home shell keeps its tab pages alive in an IndexedStack.
    /// Off = every switch rebuilds the page, which also clears any cached
    /// tab/platform state after config changes.
    @Default(true) bool homeKeepAlive,
  }) = _RefreshConfigModel;

  factory RefreshConfigModel.fromJson(Map<String, dynamic> json) => _$RefreshConfigModelFromJson(json);
}
