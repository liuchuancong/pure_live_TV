import 'package:pure_live/core/common/proxy_routing.dart';
import 'package:pure_live/services/settings/settings.dart';

/// Media hosts that refuse to serve through a proxy exit but are directly
/// reachable.
///
/// The Steam broadcast CDN pins cache sessions to the requesting IP: through a
/// proxy the manifests are 200 and the segments 410; direct, the same segment
/// is 200. So its lines bypass the proxy entirely.
const List<String> proxyDirectHostSuffixes = ['steamcontent.com'];

/// Whether [uri]'s host matches [proxyDirectHostSuffixes].
bool playsDirectBehindProxy(Uri uri) {
  final host = uri.host.toLowerCase();
  return proxyDirectHostSuffixes.any((suffix) => host == suffix || host.endsWith('.$suffix'));
}

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

  /// The global media directive, with hosts the proxy exit cannot serve
  /// forced DIRECT per host.
  static String currentDirectiveFor(Uri uri) =>
      playsDirectBehindProxy(uri) ? 'DIRECT' : currentDirective();

  static String nativeUrl(String directive, {required bool privateInput}) {
    if (privateInput || !directive.startsWith('PROXY ')) return '';
    return 'http://${directive.substring(6)}';
  }

  static String currentNativeUrl({required bool privateInput}) =>
      privateInput ? '' : nativeUrl(currentDirective(), privateInput: false);

  static String currentNativeUrlFor(Uri uri, {required bool privateInput}) =>
      privateInput ? '' : nativeUrl(currentDirectiveFor(uri), privateInput: false);
}
