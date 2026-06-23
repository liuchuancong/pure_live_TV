import 'proxy_settings_model.dart';
import 'package:pure_live/utils/hive_pref_util.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pure_live/core/network/http_client.dart';
import 'package:pure_live/services/settings/settings.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

// proxy_settings_controller.dart

part 'proxy_settings_controller.g.dart';

@riverpod
class ProxySettingsController extends _$ProxySettingsController {
  static ProxySettingsController get to => SettingsService.to.proxy;
  @override
  ProxySettingsModel build() {
    ref.listen(proxySettingsControllerProvider.select((s) => [s.enableAppProxy, s.appProxyHost, s.appProxyPort]), (
      _,
      _,
    ) {
      _refreshDioConnections();
    });

    return ProxySettingsModel(
      enableProxy: HivePrefUtil.getBool('enableProxy') ?? false,
      proxyHost: HivePrefUtil.getString('proxyHost') ?? '',
      proxyPort: HivePrefUtil.getInt('proxyPort') ?? 7897,
      enableAppProxy: HivePrefUtil.getBool('enableAppProxy') ?? false,
      appProxyHost: HivePrefUtil.getString('appProxyHost') ?? '',
      appProxyPort: HivePrefUtil.getInt('appProxyPort') ?? 7897,
    );
  }

  void _refreshDioConnections() {
    try {
      HttpClient.instance.rebuildDio();
    } catch (_) {}
  }

  void updateSettings(ProxySettingsModel newModel) {
    state = newModel;
    _persist();
  }

  void _persist() {
    HivePrefUtil.setBool('enableProxy', state.enableProxy);
    HivePrefUtil.setString('proxyHost', state.proxyHost);
    HivePrefUtil.setInt('proxyPort', state.proxyPort);
    HivePrefUtil.setBool('enableAppProxy', state.enableAppProxy);
    HivePrefUtil.setString('appProxyHost', state.appProxyHost);
    HivePrefUtil.setInt('appProxyPort', state.appProxyPort);
  }

  Map<String, dynamic> toJson() => state.toJson();

  void importFromJson(Map<String, dynamic> json) {
    state = ProxySettingsModel.fromJson(json);
    _persist();
  }
}
