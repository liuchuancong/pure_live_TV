import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:pure_live/services/webdav/webdav_config.dart';
// webdav_model.dart

part 'webdav_model.freezed.dart';
part 'webdav_model.g.dart';

@freezed
abstract class WebDavModel with _$WebDavModel {
  const factory WebDavModel({@Default('') String currentWebDavConfig, @Default([]) List<WebDAVConfig> webDavConfigs}) =
      _WebDavModel;

  factory WebDavModel.fromJson(Map<String, dynamic> json) => _$WebDavModelFromJson(json);
}
