import 'package:freezed_annotation/freezed_annotation.dart';
// proxy_settings_model.dart

part 'proxy_settings_model.freezed.dart';
part 'proxy_settings_model.g.dart';

@freezed
abstract class ProxySettingsModel with _$ProxySettingsModel {
  const factory ProxySettingsModel({
    @Default(false) bool enableProxy,
    @Default('') String proxyHost,
    @Default(7897) int proxyPort,
    @Default(false) bool enableAppProxy,
    @Default('') String appProxyHost,
    @Default(7897) int appProxyPort,
  }) = _ProxySettingsModel;

  factory ProxySettingsModel.fromJson(Map<String, dynamic> json) => _$ProxySettingsModelFromJson(json);
}
