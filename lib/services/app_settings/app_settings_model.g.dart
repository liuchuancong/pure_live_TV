// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_settings_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_AppSettingsModel _$AppSettingsModelFromJson(Map<String, dynamic> json) =>
    _AppSettingsModel(
      autoRefreshTime: (json['autoRefreshTime'] as num?)?.toInt() ?? 3,
      enableDenseFavorites: json['enableDenseFavorites'] as bool? ?? true,
      enableBackgroundPlay: json['enableBackgroundPlay'] as bool? ?? false,
      enableAsmrSleepMode: json['enableAsmrSleepMode'] as bool? ?? false,
      asmrSleepMinutes: (json['asmrSleepMinutes'] as num?)?.toInt() ?? 60,
      enableRotateScreen: json['enableRotateScreen'] as bool? ?? false,
      enableScreenKeepOn: json['enableScreenKeepOn'] as bool? ?? true,
      enableAutoCheckUpdate: json['enableAutoCheckUpdate'] as bool? ?? true,
      useGitHubOriginForUpdates:
          json['useGitHubOriginForUpdates'] as bool? ?? false,
      enableFullScreenDefault:
          json['enableFullScreenDefault'] as bool? ?? false,
      showSplashPage: json['showSplashPage'] as bool? ?? true,
      refreshRateMode: json['refreshRateMode'] as String? ?? '',
      preferRealOnlineCounts: json['preferRealOnlineCounts'] as bool? ?? false,
      realOnlinePlatforms:
          (json['realOnlinePlatforms'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
      audienceMetricMigration:
          (json['audienceMetricMigration'] as num?)?.toInt() ?? 0,
      enableMultiView: json['enableMultiView'] as bool? ?? true,
      enableNewWindowPlay: json['enableNewWindowPlay'] as bool? ?? true,
      savedMenuIds:
          (json['savedMenuIds'] as List<dynamic>?)
              ?.map((e) => e as String)
              .toList() ??
          const [],
    );

Map<String, dynamic> _$AppSettingsModelToJson(_AppSettingsModel instance) =>
    <String, dynamic>{
      'autoRefreshTime': instance.autoRefreshTime,
      'enableDenseFavorites': instance.enableDenseFavorites,
      'enableBackgroundPlay': instance.enableBackgroundPlay,
      'enableAsmrSleepMode': instance.enableAsmrSleepMode,
      'asmrSleepMinutes': instance.asmrSleepMinutes,
      'enableRotateScreen': instance.enableRotateScreen,
      'enableScreenKeepOn': instance.enableScreenKeepOn,
      'enableAutoCheckUpdate': instance.enableAutoCheckUpdate,
      'useGitHubOriginForUpdates': instance.useGitHubOriginForUpdates,
      'enableFullScreenDefault': instance.enableFullScreenDefault,
      'showSplashPage': instance.showSplashPage,
      'refreshRateMode': instance.refreshRateMode,
      'preferRealOnlineCounts': instance.preferRealOnlineCounts,
      'realOnlinePlatforms': instance.realOnlinePlatforms,
      'audienceMetricMigration': instance.audienceMetricMigration,
      'enableMultiView': instance.enableMultiView,
      'enableNewWindowPlay': instance.enableNewWindowPlay,
      'savedMenuIds': instance.savedMenuIds,
    };
