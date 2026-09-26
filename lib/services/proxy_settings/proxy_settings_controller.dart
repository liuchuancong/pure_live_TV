import 'proxy_settings_model.dart';
import 'package:pure_live/exports/common_export.dart';
import 'package:pure_live/services/settings/settings.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:pure_live/services/settings/settings_value.dart';
import 'package:pure_live/shared/platform/local_network_access.dart';

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
    // No ref.listen here: this provider listening to itself is a self
    // dependency, which Riverpod forbids ("A provider cannot depend on
    // itself") — and the assertion fires lazily on first read, i.e. inside
    // HttpClient's findProxy callback during a request, killing that request.
    // The shared Dio is rebuilt from updateSettings instead.
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
    final normalized = _normalize(newModel);
    // Rebuild the shared Dio only when the application-proxy endpoint really
    // changed; unrelated edits (player proxy fields) keep the client alive.
    final bool appProxyChanged =
        normalized.enableAppProxy != state.enableAppProxy ||
        normalized.appProxyHost != state.appProxyHost ||
        normalized.appProxyPort != state.appProxyPort;
    state = normalized;
    _persist();
    if (appProxyChanged) {
      _refreshDioConnections();
    }
    _ensureLocalNetworkAccess();
  }

  /// An enabled proxy on the PC or router is a local-network address, which
  /// Android 17 gates behind ACCESS_LOCAL_NETWORK.
  void _ensureLocalNetworkAccess() {
    LocalNetworkAccess.ensureForProxies([
      (enabled: state.enableAppProxy, host: state.appProxyHost),
      (enabled: state.enableProxy, host: state.proxyHost),
    ]);
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
