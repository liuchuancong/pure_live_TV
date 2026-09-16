import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:bonsoir/bonsoir.dart';
import 'package:flutter/foundation.dart';

import 'remote_sync_device.dart';
import 'remote_sync_events.dart';
import 'remote_sync_protocol.dart';

/// Host-supplied state bridge. The kit never touches storage itself; every
/// channel read/write and the settings export/import land here.
abstract class RemoteSyncDelegate {
  const RemoteSyncDelegate();

  /// Current value of one [RemoteSyncProtocol.channels] entry, returned to the
  /// phone as-is (JSON-encodable).
  Future<Object?> channelState(String channel);

  /// Applies a pushed channel value. Return false to reject (unknown channel,
  /// invalid payload).
  Future<bool> applyChannel(String channel, Object? data);

  /// Full settings document this device exposes (GET /settings).
  Future<Map<String, dynamic>> exportSettings();

  /// Applies a settings document pushed by a peer (POST /settings, /setSettings).
  /// Return false to report failure to the sender.
  Future<bool> importSettings(Map<String, dynamic> settings);
}

/// LAN remote-sync service: mDNS broadcast + discovery over bonsoir and a
/// small HTTP server on [RemoteSyncProtocol.defaultHttpPort] (walking upwards
/// when taken).
///
/// Start it once at app bootstrap; consume [events] for pushes and [devices]
/// for the 设备同步 peer list.
class TvRemoteKit {
  TvRemoteKit({
    required String deviceId,
    required this.deviceName,
    required this.delegate,
    this.port = RemoteSyncProtocol.defaultHttpPort,
    String? platform,
    String version = '1.0.0',
  }) : _deviceId = deviceId,
       _platform = platform ?? defaultPlatform,
       _version = version;

  /// Identifier the host persists; peers match their own broadcasts against it
  /// to skip themselves.
  final String _deviceId;
  final String deviceName;
  final RemoteSyncDelegate delegate;
  final int port;
  final String _platform;
  final String _version;

  static String get defaultPlatform => Platform.operatingSystem;

  // ---------------------------------------------------------------------------
  // State
  // ---------------------------------------------------------------------------

  final _events = StreamController<RemoteSyncEvent>.broadcast();
  Stream<RemoteSyncEvent> get events => _events.stream;

  final List<RemoteSyncDevice> _devices = [];
  List<RemoteSyncDevice> get devices => List.unmodifiable(_devices);

  bool get isRunning => _running;
  bool get isDiscovering => _discovering;

  String _localIp = '';
  String get localIp => _localIp;
  int _localPort = 0;

  /// `ip:port` of this device, empty before [start] succeeds.
  String get address => _localIp.isEmpty ? '' : '$_localIp:$_localPort';

  /// QR payload for scan-based pairing: `purelive://ip:port/sync`.
  String get qrData {
    if (_localIp.isEmpty || _localPort <= 0) return '';
    return RemoteSyncProtocol.createQrUri(ip: _localIp, port: _localPort).toString();
  }

  // ---------------------------------------------------------------------------
  // Internals
  // ---------------------------------------------------------------------------

  final Set<String> _localIps = {};
  HttpServer? _server;
  BonsoirBroadcast? _broadcast;
  BonsoirDiscovery? _discovery;
  StreamSubscription<BonsoirDiscoveryEvent>? _discoverySubscription;
  Timer? _cleanupTimer;
  bool _running = false;
  bool _disposed = false;

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  Future<void> start() async {
    if (_disposed || _running) return;
    _running = true;
    try {
      await _refreshNetworkInfo();
      if (_disposed || _localIp.isEmpty) {
        _log('No usable LAN address; sync server not started');
        return;
      }
      await _startServer();
      if (_disposed || !_running) return;
      await _startDiscoveryAndBroadcast();
    } finally {
      _running = false;
    }
  }

  Future<void> stop() async {
    _disposed = true;
    _cleanupTimer?.cancel();
    _cleanupTimer = null;

    try {
      await _discoverySubscription?.cancel();
    } catch (_) {}
    _discoverySubscription = null;

    try {
      await _discovery?.stop();
    } catch (_) {}
    _discovery = null;

    try {
      await _broadcast?.stop();
    } catch (_) {}
    _broadcast = null;

    try {
      await _server?.close(force: true);
    } catch (_) {}
    _server = null;

    if (_devices.isNotEmpty) {
      _devices.clear();
      _emit(RemoteDevicesChangedEvent(devices: devices));
    }
  }

  // ---------------------------------------------------------------------------
  // Network info
  // ---------------------------------------------------------------------------

  Future<void> _refreshNetworkInfo() async {
    try {
      final interfaces = await NetworkInterface.list(type: InternetAddressType.IPv4, includeLoopback: false);
      final ips = <String>{};
      String? privateIp;
      String? fallbackIp;
      for (final interface in interfaces) {
        for (final address in interface.addresses) {
          final ip = address.address.trim();
          if (ip.isEmpty || ip.startsWith('127.') || ip.startsWith('169.254.')) continue;
          if (!_isValidIpv4(ip)) continue;
          ips.add(ip);
          fallbackIp ??= ip;
          if (_isPrivateIpv4(ip) && (privateIp == null || _ipv4Priority(ip) > _ipv4Priority(privateIp))) {
            privateIp = ip;
          }
        }
      }
      _localIps
        ..clear()
        ..addAll(ips);
      _localIp = privateIp ?? fallbackIp ?? '';
    } catch (_) {
      _localIps.clear();
      _localIp = '';
    }
  }

  bool _isValidIpv4(String ip) {
    final parts = ip.split('.');
    if (parts.length != 4) return false;
    return parts.every((part) {
      final value = int.tryParse(part);
      return value != null && value >= 0 && value <= 255;
    });
  }

  bool _isPrivateIpv4(String ip) {
    final parts = ip.split('.');
    if (parts.length != 4) return false;
    final a = int.tryParse(parts[0]);
    final b = int.tryParse(parts[1]);
    if (a == null || b == null) return false;
    return a == 10 || (a == 172 && b >= 16 && b <= 31) || (a == 192 && b == 168);
  }

  int _ipv4Priority(String ip) {
    if (ip.startsWith('192.168.')) return 3;
    if (ip.startsWith('10.')) return 2;
    final parts = ip.split('.');
    if (parts.length == 4 && parts[0] == '172') {
      final second = int.tryParse(parts[1]);
      if (second != null && second >= 16 && second <= 31) return 1;
    }
    return 0;
  }

  String? _ipv4Prefix(String ip) {
    final parts = ip.split('.');
    return parts.length == 4 ? '${parts[0]}.${parts[1]}.${parts[2]}' : null;
  }

  // ---------------------------------------------------------------------------
  // HTTP server
  // ---------------------------------------------------------------------------

  Future<void> _startServer() async {
    HttpServer? server;
    var bindPort = port;
    for (var i = 0; i < 100; i++) {
      try {
        server = await HttpServer.bind(InternetAddress.anyIPv4, bindPort, shared: true);
        break;
      } catch (_) {
        bindPort++;
      }
    }
    if (server == null || _disposed) {
      _log('Could not bind the sync server near port $port');
      return;
    }
    _server = server;
    _localPort = bindPort;
    server.listen(
      _handleRequest,
      onError: (_) {},
      onDone: () {},
    );
    _log('Sync server listening at $_localIp:$_localPort');

    _cleanupTimer?.cancel();
    _cleanupTimer = Timer.periodic(const Duration(seconds: 15), (_) => _cleanupDevices());
  }

  Future<void> _handleRequest(HttpRequest request) async {
    final response = request.response;
    response.headers.contentType = ContentType('application', 'json', charset: 'utf-8');
    response.headers.set('Access-Control-Allow-Origin', '*');
    response.headers.set('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
    response.headers.set('Access-Control-Allow-Headers', 'Content-Type');
    if (request.method == 'OPTIONS') {
      response.statusCode = HttpStatus.ok;
      await response.close();
      return;
    }
    try {
      final path = request.uri.path;
      if (path == RemoteSyncProtocol.apiStatus) {
        await _handleStatus(request);
      } else if (path == RemoteSyncProtocol.apiSettings) {
        await _handleSettings(request);
      } else if (path == RemoteSyncProtocol.apiSetSettings) {
        await _handleSetSettings(request);
      } else if (path.startsWith(RemoteSyncProtocol.apiChannelPrefix)) {
        await _handleChannel(request, path.substring(RemoteSyncProtocol.apiChannelPrefix.length));
      } else if (path == RemoteSyncProtocol.apiSearchStreamer) {
        await _handleTextInput(request, 'streamer');
      } else if (path == RemoteSyncProtocol.apiSearchRoom) {
        await _handleTextInput(request, 'room');
      } else if (path == RemoteSyncProtocol.apiMovie) {
        await _handleTextInput(request, 'movie');
      } else {
        await _writeJson(response, HttpStatus.notFound, {'code': 404, 'msg': 'Not Found', 'data': false});
      }
    } catch (_) {
      try {
        await _writeJson(response, HttpStatus.internalServerError, {'code': 500, 'msg': 'Internal Server Error', 'data': false});
      } catch (_) {}
    }
  }

  Future<void> _handleStatus(HttpRequest request) async {
    if (request.method != 'GET') {
      await _writeMethodNotAllowed(request.response);
      return;
    }
    await _writeJson(request.response, HttpStatus.ok, {
      'code': 200,
      'msg': 'ok',
      'data': {
        'id': _deviceId,
        'name': deviceName,
        'platform': _platform,
        'version': _version,
        'ip': _localIp,
        'port': _localPort,
      },
    });
  }

  Future<void> _handleSettings(HttpRequest request) async {
    switch (request.method) {
      case 'GET':
        try {
          final settings = await delegate.exportSettings();
          await _writeJson(request.response, HttpStatus.ok, {'code': 200, 'msg': 'ok', 'data': settings});
        } catch (_) {
          await _writeJson(request.response, HttpStatus.internalServerError, {'code': 500, 'msg': 'Export settings failed', 'data': false});
        }
      case 'POST':
        final body = await _readJsonBody(request);
        final settings = body is Map && body['settings'] is Map ? Map<String, dynamic>.from(body['settings'] as Map) : null;
        if (settings == null) {
          await _writeJson(request.response, HttpStatus.badRequest, {'code': 400, 'msg': 'Settings is empty', 'data': false});
          return;
        }
        final ok = await delegate.importSettings(settings);
        await _writeJson(request.response, ok ? HttpStatus.ok : HttpStatus.internalServerError, {
          'code': ok ? 200 : 500,
          'msg': ok ? 'ok' : 'apply settings failed',
          'data': ok,
        });
      default:
        await _writeMethodNotAllowed(request.response);
    }
  }

  /// Compatibility with the mobile app's 同步TV数据 row: the flat TV document
  /// arrives as a `settings` *query parameter* on POST /api/setSettings.
  Future<void> _handleSetSettings(HttpRequest request) async {
    final raw = request.uri.queryParameters['settings'];
    Map<String, dynamic>? settings;
    if (raw != null && raw.isNotEmpty) {
      try {
        final decoded = jsonDecode(raw);
        if (decoded is Map) settings = Map<String, dynamic>.from(decoded);
      } catch (_) {}
    }
    if (settings == null) {
      final body = await _readJsonBody(request);
      if (body is Map) {
        final nested = body['settings'];
        settings = nested is Map ? Map<String, dynamic>.from(nested) : Map<String, dynamic>.from(body);
      }
    }
    if (settings == null) {
      await _writeJson(request.response, HttpStatus.badRequest, {'code': 400, 'msg': 'Invalid request', 'data': false});
      return;
    }
    final ok = await delegate.importSettings(settings);
    await _writeJson(request.response, ok ? HttpStatus.ok : HttpStatus.internalServerError, {
      'code': ok ? 200 : 500,
      'msg': ok ? 'ok' : 'apply settings failed',
      'data': ok,
    });
  }

  Future<void> _handleChannel(HttpRequest request, String channel) async {
    switch (request.method) {
      case 'GET':
        final state = await delegate.channelState(channel);
        await _writeJson(request.response, HttpStatus.ok, {'code': 200, 'msg': 'ok', 'data': state});
      case 'POST':
        final body = await _readJsonBody(request);
        final ok = await delegate.applyChannel(channel, body);
        if (!ok) {
          await _writeJson(request.response, HttpStatus.badRequest, {'code': 400, 'msg': 'Rejected', 'data': false});
          return;
        }
        _emit(RemoteChannelEvent(channel: channel, data: body));
        await _writeJson(request.response, HttpStatus.ok, {'code': 200, 'msg': 'ok', 'data': true});
      default:
        await _writeMethodNotAllowed(request.response);
    }
  }

  Future<void> _handleTextInput(HttpRequest request, String kind) async {
    if (request.method != 'POST') {
      await _writeMethodNotAllowed(request.response);
      return;
    }
    final body = await _readBody(request);
    final text = body.toString().trim();
    if (text.isEmpty) {
      await _writeJson(request.response, HttpStatus.badRequest, {'code': 400, 'msg': 'Empty request', 'data': false});
      return;
    }
    _emit(RemoteTextInputEvent(kind: kind, text: text));
    await _writeJson(request.response, HttpStatus.ok, {'code': 200, 'msg': 'ok', 'data': true});
  }

  Future<Object?> _readBody(HttpRequest request) async {
    final content = await utf8.decoder.bind(request).join();
    if (content.trim().isEmpty) return '';
    try {
      return jsonDecode(content);
    } catch (_) {
      return content;
    }
  }

  Future<Object?> _readJsonBody(HttpRequest request) async {
    final content = await utf8.decoder.bind(request).join();
    if (content.trim().isEmpty) return null;
    try {
      return jsonDecode(content);
    } catch (_) {
      return null;
    }
  }

  Future<void> _writeMethodNotAllowed(HttpResponse response) async {
    await _writeJson(response, HttpStatus.methodNotAllowed, {'code': 405, 'msg': 'Method Not Allowed', 'data': false});
  }

  Future<void> _writeJson(HttpResponse response, int status, Map<String, dynamic> data) async {
    response.statusCode = status;
    response.write(jsonEncode(data));
    await response.close();
  }

  // ---------------------------------------------------------------------------
  // Bonsoir broadcast + discovery
  // ---------------------------------------------------------------------------

  Future<void> _startDiscoveryAndBroadcast() async {
    try {
      final discovery = BonsoirDiscovery(type: RemoteSyncProtocol.mdnsServiceType);
      await discovery.initialize();
      final eventStream = discovery.eventStream;
      if (eventStream == null) return;
      _discovery = discovery;
      _discoverySubscription = eventStream.listen(_handleDiscoveryEvent, onError: (_) {});
      await discovery.start();
      _discovering = true;
      await _startBroadcast();
    } catch (error) {
      _log('mDNS failed: $error');
    }
  }

  bool _discovering = false;
  bool get discovering => _discovering;

  Future<void> _handleDiscoveryEvent(BonsoirDiscoveryEvent event) async {
    switch (event) {
      case BonsoirDiscoveryServiceFoundEvent():
        final service = event.service;
        if (_isSelfService(service)) return;
        // TXT attributes already carry the ip; resolve in the background and
        // update again when the resolved addresses arrive.
        _addOrUpdateDevice(service);
        final resolver = _discovery?.serviceResolver;
        if (resolver != null) {
          try {
            await service.resolve(resolver);
          } catch (_) {}
        }
      case BonsoirDiscoveryServiceResolvedEvent():
      case BonsoirDiscoveryServiceUpdatedEvent():
        final service = event.service;
        if (service == null || _isSelfService(service)) return;
        _addOrUpdateDevice(service);
      case BonsoirDiscoveryServiceLostEvent():
        _removeDevice(event.service);
      default:
        break;
    }
  }

  bool _isSelfService(BonsoirService service) {
    final id = service.attributes['id']?.trim();
    if (id == _deviceId) return true;
    final ip = service.attributes['ip']?.trim();
    return ip != null && ip.isNotEmpty && _localIps.contains(ip);
  }

  void _addOrUpdateDevice(BonsoirService service) {
    final attributes = service.attributes;
    final id = attributes['id']?.trim() ?? '';
    if (id.isEmpty || id == _deviceId) return;

    final name = (attributes['name']?.trim().isNotEmpty == true) ? attributes['name']!.trim() : service.name;
    // Prefer resolved addresses; TXT ip is the fallback while unresolved, and
    // the protocol port fills in for the 0 an unresolved service reports.
    final ip = _selectServiceIp(service) ?? attributes['ip']?.trim();
    if (ip == null || !_isValidIpv4(ip)) return;
    final servicePort = service.port > 0 ? service.port : RemoteSyncProtocol.defaultHttpPort;

    final device = RemoteSyncDevice(
      id: id,
      name: name,
      platform: attributes['platform'] ?? '',
      version: attributes['version'] ?? '',
      ip: ip,
      port: servicePort,
      lastSeen: DateTime.now(),
      bonsoirName: service.name,
    );

    final indexById = _devices.indexWhere((item) => item.id == device.id);
    if (indexById >= 0) {
      _devices[indexById] = device;
      _emit(RemoteDevicesChangedEvent(devices: devices));
      return;
    }
    final indexByIp = _devices.indexWhere((item) => item.ip.trim() == device.ip.trim());
    if (indexByIp >= 0) {
      _devices[indexByIp] = device;
      _emit(RemoteDevicesChangedEvent(devices: devices));
      return;
    }
    _devices.add(device);
    _emit(RemoteDevicesChangedEvent(devices: devices));
  }

  void _removeDevice(BonsoirService service) {
    final id = service.attributes['id']?.trim();
    final before = _devices.length;
    if (id != null && id.isNotEmpty) {
      _devices.removeWhere((device) => device.id == id);
    } else {
      _devices.removeWhere((device) => device.bonsoirName == service.name);
    }
    if (_devices.length != before) {
      _emit(RemoteDevicesChangedEvent(devices: devices));
    }
  }

  String? _selectServiceIp(BonsoirService service) {
    final addresses = service.hostAddresses.where(_isValidIpv4).toList();
    if (addresses.isNotEmpty) {
      final localPrefix = _ipv4Prefix(_localIp);
      if (localPrefix != null) {
        for (final ip in addresses) {
          if (_ipv4Prefix(ip) == localPrefix) return ip;
        }
      }
      for (final ip in addresses) {
        if (_isPrivateIpv4(ip)) return ip;
      }
      return addresses.first;
    }
    final advertised = service.attributes['ip']?.trim();
    return (advertised != null && _isValidIpv4(advertised)) ? advertised : null;
  }

  Future<void> _startBroadcast() async {
    if (_localPort <= 0) return;
    try {
      final service = BonsoirService(
        name: _broadcastName,
        type: RemoteSyncProtocol.mdnsServiceType,
        port: _localPort,
        attributes: RemoteSyncProtocol.broadcastAttributes(
          id: _deviceId,
          name: deviceName,
          platform: _platform,
          version: _version,
          ip: _localIp,
        ),
      );
      final broadcast = BonsoirBroadcast(service: service);
      await broadcast.initialize();
      await broadcast.start();
      _broadcast = broadcast;
      _log('Broadcasting as ${service.name}');
    } catch (error) {
      _log('Broadcast failed: $error');
    }
  }

  String get _broadcastName {
    final suffix = _deviceId.length > 6 ? _deviceId.substring(_deviceId.length - 6) : _deviceId;
    return 'PureLive-$suffix';
  }

  // ---------------------------------------------------------------------------
  // Device bookkeeping
  // ---------------------------------------------------------------------------

  void _cleanupDevices() {
    final now = DateTime.now();
    final before = _devices.length;
    _devices.removeWhere((device) => now.difference(device.lastSeen).inSeconds > 120);
    if (_devices.length != before) {
      _emit(RemoteDevicesChangedEvent(devices: devices));
    }
  }

  // ---------------------------------------------------------------------------
  // Outgoing sync (设备同步)
  // ---------------------------------------------------------------------------

  /// Pushes this device's settings to [device]. Returns false on any failure.
  Future<bool> syncToDevice(RemoteSyncDevice device) => syncToAddress(device.ip, device.port);

  Future<bool> syncToAddress(String ip, int port) async {
    try {
      final settings = await delegate.exportSettings();
      final client = HttpClient();
      try {
        final request = await client.postUrl(Uri.parse('http://$ip:$port${RemoteSyncProtocol.apiSettings}'));
        request.headers.contentType = ContentType('application', 'json', charset: 'utf-8');
        request.write(jsonEncode(RemoteSyncProtocol.settingsPacket(settings: settings)));
        final response = await request.close();
        final body = await utf8.decoder.bind(response).join();
        if (response.statusCode != HttpStatus.ok) return false;
        final result = jsonDecode(body);
        return result is Map && result['data'] == true;
      } finally {
        client.close(force: true);
      }
    } catch (error) {
      _log('Sync to $ip:$port failed: $error');
      return false;
    }
  }

  /// Pulls the settings document from [ip:port] and applies it locally.
  Future<bool> receiveFromAddress(String ip, int port) async {
    try {
      final client = HttpClient();
      try {
        final request = await client.getUrl(Uri.parse('http://$ip:$port${RemoteSyncProtocol.apiSettings}'));
        final response = await request.close();
        final body = await utf8.decoder.bind(response).join();
        if (response.statusCode != HttpStatus.ok) return false;
        final result = jsonDecode(body);
        if (result is! Map || result['code'] != 200 || result['data'] is! Map) return false;
        return await delegate.importSettings(Map<String, dynamic>.from(result['data'] as Map));
      } finally {
        client.close(force: true);
      }
    } catch (error) {
      _log('Receive from $ip:$port failed: $error');
      return false;
    }
  }

  /// Connects by a scanned QR value or a manually typed `ip:port`.
  Future<bool> receiveFromQrOrAddress(String value) async {
    final parsed = RemoteSyncProtocol.parseQr(value);
    if (parsed == null) return false;
    return receiveFromAddress(parsed.ip, parsed.port);
  }

  // ---------------------------------------------------------------------------
  // Misc
  // ---------------------------------------------------------------------------

  void _emit(RemoteSyncEvent event) {
    if (!_events.isClosed) _events.add(event);
  }

  void _log(String message) {
    debugPrint('[tv_remote_kit] $message');
    if (!_events.isClosed) _events.add(RemoteLogEvent(message: message));
  }
}
