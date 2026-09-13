import 'package:pure_live/core/network/proxy_routing.dart';
import 'package:pure_live/services/settings/settings.dart';

/// 媒体传输代理策略，独立于应用/API 层代理。
/// 同步自 pure_live 的 PlaybackProxyPolicy，读取改走 TV 的 SettingsService 外观。
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
