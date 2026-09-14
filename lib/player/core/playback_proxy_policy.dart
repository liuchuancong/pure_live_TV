import 'package:pure_live/shared/common/proxy_routing.dart';
import 'package:pure_live/services/settings/settings.dart';

/// Proxy policy for media transport, independent from the API layer.
///
/// Configured values are read through the SettingsService facade.
class PlaybackProxyPolicy {
  const PlaybackProxyPolicy._();

  static String currentDirective() {
    try {
      final proxy = SettingsService.to.proxyState;
      return buildProxyDirective(
        enabled: proxy.enableProxy,
        host: proxy.proxyHost,
        port: proxy.proxyPort,
      );
    } catch (_) {
      return 'DIRECT';
    }
  }

  static String nativeUrl(String directive, {required bool privateInput}) {
    if (privateInput || !directive.startsWith('PROXY ')) return '';
    return 'http://${directive.substring(6)}';
  }

  static String currentNativeUrl({required bool privateInput}) =>
      privateInput ? '' : nativeUrl(currentDirective(), privateInput: false);
}
