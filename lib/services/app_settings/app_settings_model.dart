import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_settings_model.freezed.dart';
part 'app_settings_model.g.dart';

/// Application settings model.
///
/// enableMultiView and enableNewWindowPlay have no UI here and are kept only so
/// backup export/import stays compatible with older backups.
@freezed
abstract class AppSettingsModel with _$AppSettingsModel {
  const factory AppSettingsModel({
    @Default(3) int autoRefreshTime,
    @Default(true) bool enableDenseFavorites,
    @Default(false) bool enableBackgroundPlay,
    @Default(false) bool enableAsmrSleepMode,
    @Default(60) int asmrSleepMinutes,
    @Default(false) bool enableRotateScreen,
    @Default(true) bool enableScreenKeepOn,
    @Default(true) bool enableAutoCheckUpdate,
    @Default(false) bool useGitHubOriginForUpdates,
    @Default(false) bool enableFullScreenDefault,
    @Default(true) bool showSplashPage,
    @Default('') String refreshRateMode,
    @Default(false) bool preferRealOnlineCounts,
    @Default([]) List<String> realOnlinePlatforms,
    @Default(0) int audienceMetricMigration,
    // Windows only. Synced across devices but never consumed on TV.
    @Default(true) bool enableMultiView,
    @Default(true) bool enableNewWindowPlay,
    @Default([]) List<String> savedMenuIds,
  }) = _AppSettingsModel;

  factory AppSettingsModel.fromJson(Map<String, dynamic> json) => _$AppSettingsModelFromJson(json);
}
