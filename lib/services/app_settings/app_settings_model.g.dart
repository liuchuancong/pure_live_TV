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
      enableRotateScreen: json['enableRotateScreen'] as bool? ?? false,
      enableScreenKeepOn: json['enableScreenKeepOn'] as bool? ?? true,
      enableAutoCheckUpdate: json['enableAutoCheckUpdate'] as bool? ?? true,
      enableFullScreenDefault:
          json['enableFullScreenDefault'] as bool? ?? false,
      showSplashPage: json['showSplashPage'] as bool? ?? true,
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
      'enableRotateScreen': instance.enableRotateScreen,
      'enableScreenKeepOn': instance.enableScreenKeepOn,
      'enableAutoCheckUpdate': instance.enableAutoCheckUpdate,
      'enableFullScreenDefault': instance.enableFullScreenDefault,
      'showSplashPage': instance.showSplashPage,
      'savedMenuIds': instance.savedMenuIds,
    };
