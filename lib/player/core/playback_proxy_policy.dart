import 'package:pure_live/core/common/proxy_routing.dart';
import 'package:pure_live/services/settings/settings.dart';

/// 代理出口后面会拒绝吐流、而直连可达的媒体主机后缀。
///
/// Steam 广播 CDN（`*.steamcontent.com`）按请求 IP 做缓存会话亲和：代理出口拉
/// master/变体清单都是 200，分片却答 410 Gone；直连同一分片 200。Steam 的 CDN
/// 本身直连可达，所以这条线路不该进代理。
const List<String> proxyDirectHostSuffixes = ['steamcontent.com'];

/// [uri] 的主机是否命中 [proxyDirectHostSuffixes]。
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

  /// 全局播放代理指令，但代理出口会被 CDN 拒吐流的主机（Steam 广播）逐条直连。
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
