import 'package:freezed_annotation/freezed_annotation.dart';

part 'app_settings_model.freezed.dart';
part 'app_settings_model.g.dart';

/// 与 pure_live 的应用设置字段全量对齐：
/// enableMultiView / enableNewWindowPlay 为 Windows 独占功能，
/// TV 无 UI 也不消费，仅保留在模型中使备份导出/导入双向兼容。
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
    // Windows 独占（TV 不消费，仅同步保留）
    @Default(true) bool enableMultiView,
    @Default(true) bool enableNewWindowPlay,
    @Default([]) List<String> savedMenuIds,
  }) = _AppSettingsModel;

  factory AppSettingsModel.fromJson(Map<String, dynamic> json) => _$AppSettingsModelFromJson(json);
}
