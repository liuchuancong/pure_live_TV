import 'dart:io';

import 'package:dio/dio.dart';
import 'package:dio/io.dart';
import 'package:pure_live/services/settings/settings.dart';
import 'package:pure_live/shared/common/proxy_routing.dart';

/// Proxy policy for the interface (API) layer.
///
/// This is the settings page's interface-proxy switch (`enableAppProxy`) — the
/// one the shared [HttpClient] follows. [PlaybackProxyPolicy] owns the separate
/// media-transport switch (`enableProxy`), so the two can be turned on
/// independently.
///
/// A client that builds its own Dio — a site API, an update check, a download —
/// has to answer to this switch too, or the user's proxy silently covers some
/// requests and not others.
class ApiProxyPolicy {
  const ApiProxyPolicy._();

  /// The `HttpClient.findProxy` directive for the current settings.
  ///
  /// Invalid or half-edited values stay direct: [buildProxyDirective] decides
  /// that, and the facade values are read per request, so this never has to be
  /// cached or rebuilt.
  static String directiveFor(Uri uri) => currentDirective();

  /// [currentDirective] for the consumers whose hook takes no URI (the image
  /// cache loader).
  static String currentDirective() {
    try {
      final proxy = SettingsService.to.proxyState;
      return buildProxyDirective(
        enabled: proxy.enableAppProxy,
        host: proxy.appProxyHost,
        port: proxy.appProxyPort,
      );
    } catch (_) {
      return 'DIRECT';
    }
  }

  /// A Dio adapter that routes every request through the interface proxy.
  ///
  /// `findProxy` is evaluated per request, so a settings change applies here as
  /// well — these clients need no rebuild path of their own.
  static HttpClientAdapter get dioAdapter =>
      IOHttpClientAdapter(createHttpClient: () => HttpClient()..findProxy = directiveFor);
}
