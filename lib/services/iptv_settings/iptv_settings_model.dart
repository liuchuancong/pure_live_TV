import 'package:freezed_annotation/freezed_annotation.dart';

part 'iptv_settings_model.freezed.dart';
part 'iptv_settings_model.g.dart';

@freezed
abstract class IptvSettingsModel with _$IptvSettingsModel {
  const factory IptvSettingsModel({
    @Default(false) bool isAutoSyncEnabled,
    @Default(24) int autoSyncHoursInterval,
    @Default('') String customIptvUserAgent,
    @Default('') String customIptvReferer,
    @Default('') String customIptvCookie,
    @Default('m3uDirectory') String m3uDirectory,
  }) = _IptvSettingsModel;

  factory IptvSettingsModel.fromJson(Map<String, dynamic> json) => _$IptvSettingsModelFromJson(json);
}
