import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_settings_model.freezed.dart';
part 'app_settings_model.g.dart';

@freezed
abstract class AppSettingsModel with _$AppSettingsModel {
  const factory AppSettingsModel({
    @Default(3) int autoRefreshTime,
    @Default(true) bool enableDenseFavorites,
    @Default(false) bool enableBackgroundPlay,
    @Default(false) bool enableRotateScreen,
    @Default(true) bool enableScreenKeepOn,
    @Default(true) bool enableAutoCheckUpdate,
    @Default(false) bool enableFullScreenDefault,
    @Default(true) bool showSplashPage,
    @Default([]) List<String> savedMenuIds,
  }) = _AppSettingsModel;

  factory AppSettingsModel.fromJson(Map<String, dynamic> json) => _$AppSettingsModelFromJson(json);
}
