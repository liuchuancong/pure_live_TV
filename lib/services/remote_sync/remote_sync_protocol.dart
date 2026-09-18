/// Wire format and address helpers of the LAN sync protocol (39888).
///
/// Device-sync only: the pairing QR, mDNS discovery and the settings push/pull
/// endpoints. The web remote and the search/movie pushes are the separate 8888
/// service and are not part of this class.
class RemoteSyncProtocol {
  const RemoteSyncProtocol._();

  /// HTTP port the sync server prefers; the binder walks upwards when taken.
  static const int defaultHttpPort = 39888;

  /// mDNS service type shared with the mobile client.
  static const String mdnsServiceType = '_my-service._tcp';

  static const String syncType = 'pure_live_sync';

  static const String apiStatus = '/api/remote-sync/status';
  static const String apiSettings = '/api/remote-sync/settings';

  /// The payload a phone app encodes/reads for *sync pairing*: a `purelive://`
  /// URI. Do not return an http URL here — a camera scan would open a web page
  /// instead of pairing.
  static Uri createQrUri({required String ip, required int port}) {
    return Uri(scheme: 'purelive', host: ip, port: port, path: '/sync');
  }

  static Map<String, dynamic> settingsPacket({required Map<String, dynamic> settings}) {
    return {'type': syncType, 'version': 1, 'settings': settings};
  }

  /// Parses `host:port`, `http://host:port` and bare-IP inputs.
  static ({String ip, int port})? parseHttpAddress(String value) {
    var text = value.trim();
    if (text.isEmpty) return null;
    if (!text.startsWith('http://') && !text.startsWith('https://')) {
      text = 'http://$text';
    }
    try {
      final uri = Uri.parse(text);
      final host = uri.host.trim();
      if (host.isEmpty) return null;
      final port = uri.hasPort ? uri.port : 80;
      if (port < 1 || port > 65535) return null;
      return (ip: host, port: port);
    } catch (_) {
      return null;
    }
  }

  /// Accepts a `purelive://` QR payload and falls back to an HTTP address, so
  /// both scan-based pairing and manual entry land in the same place.
  static ({String ip, int port})? parseQr(String value) {
    final text = value.trim();
    if (text.isEmpty) return null;
    try {
      final uri = Uri.parse(text);
      if (uri.scheme == 'purelive') {
        if (uri.host.isEmpty || !uri.hasPort) return null;
        return (ip: uri.host, port: uri.port);
      }
      return parseHttpAddress(text);
    } catch (_) {
      return null;
    }
  }
}
