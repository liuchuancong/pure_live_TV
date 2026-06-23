import 'webdav_model.dart';
import 'package:pure_live/utils/hive_pref_util.dart';
import 'package:pure_live/services/settings/settings.dart';
import 'package:pure_live/services/webdav/webdav_config.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'webdav_controller.g.dart';

@riverpod
class WebDavController extends _$WebDavController {
  static WebDavController get to => SettingsService.to.webDav;
  @override
  WebDavModel build() {
    return WebDavModel(
      currentWebDavConfig: HivePrefUtil.getString('currentWebDavConfig') ?? '',
      webDavConfigs: HivePrefUtil.getObjectList('webDavConfigs', WebDAVConfig.fromJson),
    );
  }

  bool isWebDavConfigExist(String name) => state.webDavConfigs.any((e) => e.name == name);

  WebDAVConfig? getWebDavConfigByName(String name) => state.webDavConfigs.where((e) => e.name == name).firstOrNull;

  bool addWebDavConfig(WebDAVConfig config) {
    if (isWebDavConfigExist(config.name)) return false;
    state = state.copyWith(webDavConfigs: [...state.webDavConfigs, config]);
    _persist();
    return true;
  }

  bool removeWebDavConfig(WebDAVConfig config) {
    if (!state.webDavConfigs.contains(config)) return false;
    state = state.copyWith(webDavConfigs: state.webDavConfigs.where((e) => e != config).toList());
    _persist();
    return true;
  }

  bool updateWebDavConfig(WebDAVConfig config) {
    final idx = state.webDavConfigs.indexWhere((e) => e.name == config.name);
    if (idx == -1) return false;
    final newList = List<WebDAVConfig>.from(state.webDavConfigs);
    newList[idx] = config;
    state = state.copyWith(webDavConfigs: newList);
    _persist();
    return true;
  }

  Map<String, dynamic> toJson() => state.toJson();

  void importFromJson(Map<String, dynamic> json) {
    state = WebDavModel.fromJson(json);
    _persist();
  }

  void _persist() {
    HivePrefUtil.setString('currentWebDavConfig', state.currentWebDavConfig);
    HivePrefUtil.setObjectList('webDavConfigs', state.webDavConfigs, (c) => c.toJson());
  }
}
