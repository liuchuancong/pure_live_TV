import 'proxy_settings_model.dart';
import 'package:pure_live/exports/common_export.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:pure_live/services/settings/settings.dart';
import 'package:pure_live/services/settings/settings_value.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

// proxy_settings_controller.dart

part 'proxy_settings_controller.g.dart';

@riverpod
class ProxySettingsController extends _$ProxySettingsController {
  static ProxySettingsController get to => SettingsService.to.proxy;

  // Read reactively by the player core and other non-widget code.
  SettingsValue<bool> get enableProxy => SettingsValue(() => state.enableProxy);
  SettingsValue<String> get proxyHost => SettingsValue(() => state.proxyHost);
  SettingsValue<int> get proxyPort => SettingsValue(() => state.proxyPort);
  SettingsValue<bool> get enableAppProxy => SettingsValue(() => state.enableAppProxy);
  SettingsValue<String> get appProxyHost => SettingsValue(() => state.appProxyHost);
  SettingsValue<int> get appProxyPort => SettingsValue(() => state.appProxyPort);

  @override
  ProxySettingsModel build() {
    ref.listen(proxySettingsControllerProvider.select((s) => [s.enableAppProxy, s.appProxyHost, s.appProxyPort]), (
      _,
      _,
    ) {
      _refreshDioConnections();
    });

    return _normalize(
      ProxySettingsModel(
        enableProxy: HivePrefUtil.getBool('enableProxy') ?? false,
        proxyHost: HivePrefUtil.getString('proxyHost') ?? '',
        proxyPort: HivePrefUtil.getInt('proxyPort') ?? defaultProxyPort,
        enableAppProxy: HivePrefUtil.getBool('enableAppProxy') ?? false,
        appProxyHost: HivePrefUtil.getString('appProxyHost') ?? '',
        appProxyPort: HivePrefUtil.getInt('appProxyPort') ?? defaultProxyPort,
      ),
    );
  }

  /// Repairs a stored or imported endpoint before it reaches any consumer.
  ///
  /// A keyboard can leave a full-width dot in the host and an older build could
  /// persist port 0, which would hand every application, player and recorder
  /// request an unusable proxy socket.
  static ProxySettingsModel _normalize(ProxySettingsModel model) => model.copyWith(
    proxyHost: normalizeProxyHost(model.proxyHost),
    proxyPort: normalizeStoredProxyPort(model.proxyPort),
    appProxyHost: normalizeProxyHost(model.appProxyHost),
    appProxyPort: normalizeStoredProxyPort(model.appProxyPort),
  );

  void _refreshDioConnections() {
    try {
      HttpClient.instance.rebuildDio();
    } catch (_) {}
  }

  void updateSettings(ProxySettingsModel newModel) {
    state = _normalize(newModel);
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
    updateSettings(ProxySettingsModel.fromJson(json));
  }
}
