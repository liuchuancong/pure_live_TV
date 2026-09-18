/// Wire format and address helpers of the LAN sync protocol.
///
/// Ported from the old PureLive app's RemoteSyncProtocol so the existing
/// mobile client can talk to this kit unchanged.
class RemoteSyncProtocol {
  const RemoteSyncProtocol._();

  /// HTTP port the sync server prefers; the binder walks upwards when taken.
  static const int defaultHttpPort = 39888;

  /// mDNS service type shared with the mobile client.
  static const String mdnsServiceType = '_my-service._tcp';

  static const String discoveryType = 'pure_live_discovery';
  static const String syncType = 'pure_live_sync';

  static const String apiStatus = '/api/remote-sync/status';

  /// Every JSON route starts with this; anything else is a web-remote file.
  static const String apiPrefix = '/api/';
  static const String apiSettings = '/api/remote-sync/settings';
  static const String apiSetSettings = '/api/setSettings';
  static const String apiChannelPrefix = '/api/channel/';
  static const String apiSearchStreamer = '/api/search/streamer';
  static const String apiSearchRoom = '/api/search/room';
  static const String apiMovie = '/api/movie';

  /// Channels served under [apiChannelPrefix], in the order the settings
  /// pages present them.
  static const List<String> channels = [
    'cookie',
    'danmaku_filter',
    'tags',
    'proxy',
    'iptv',
  ];

  /// The page the phone opens; served at `/`.
  static const String webRemotePath = '/';

  /// The payload a phone encodes into a QR scan.
  ///
  /// An **http** address on purpose: scanning it with a camera app opens the web form
  /// ([webRemotePath]), which is where cookies, IPTV headers, WebDAV and the proxy are
  /// typed. The `purelive://ip:port/sync` form the old app used is still *accepted* by
  /// [parseQr], so an already-printed QR keeps working.
  static Uri createQrUri({required String ip, required int port}) {
    return Uri(scheme: 'http', host: ip, port: port, path: webRemotePath);
  }

  /// TXT attributes every broadcast carries, so a peer can build a device
  /// entry before mDNS resolution completes.
  static Map<String, String> broadcastAttributes({
    required String id,
    required String name,
    required String platform,
    required String version,
    required String ip,
  }) {
    return {'id': id, 'name': name, 'platform': platform, 'version': version, 'ip': ip};
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
