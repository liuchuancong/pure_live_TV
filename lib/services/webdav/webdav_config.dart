import 'package:freezed_annotation/freezed_annotation.dart';

part 'webdav_config.freezed.dart';
part 'webdav_config.g.dart';

@freezed
abstract class WebDAVConfig with _$WebDAVConfig {
  const WebDAVConfig._();

  const factory WebDAVConfig({
    @Default('') String name,
    @Default('') String address,
    @Default('') String username,
    @Default('') String password,
  }) = _WebDAVConfig;

  factory WebDAVConfig.fromJson(Map<String, dynamic> json) => _$WebDAVConfigFromJson(json);

  String get fullUrl => address;
}
