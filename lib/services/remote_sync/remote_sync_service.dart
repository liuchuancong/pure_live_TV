import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:bonsoir/bonsoir.dart';
import 'package:flutter/foundation.dart';
import 'package:pure_live/shared/utils/hive_pref_util.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:pure_live/services/backup/backup_controller.dart';
import 'package:pure_live/services/remote_sync/remote_sync_device.dart';
import 'package:pure_live/services/remote_sync/remote_sync_protocol.dart';

part 'remote_sync_service.g.dart';

/// What the UI needs to know about the LAN sync service.
class RemoteSyncSnapshot {
  final bool started;
  final String qrData;
  final String address;
  final String? error;
  final List<RemoteSyncDevice> devices;

  /// Every usable IPv4 this device owns, best-guess order. More than one
  /// means multiple NICs (ethernet + Wi-Fi, virtual adapters) and the auto
  /// pick may advertise an address the phone cannot reach — the page then
  /// offers a manual choice.
  final List<String> localIps;

  const RemoteSyncSnapshot({
    this.started = false,
    this.qrData = '',
    this.address = '',
    this.error,
    this.devices = const [],
    this.localIps = const [],
  });
}

/// Device sync only: mDNS broadcast + discovery over bonsoir and a small HTTP
/// server on 39888 (walking upwards when taken). Same logic as the web side's
/// `RemoteSyncService`, hosted in Riverpod for the TV pages.
@Riverpod(keepAlive: false)
class RemoteSyncController extends _$RemoteSyncController {
  HttpServer? _server;
  BonsoirBroadcast? _broadcast;
  BonsoirDiscovery? _discovery;
  StreamSubscription<BonsoirDiscoveryEvent>? _discoverySub;
  Timer? _cleanupTimer;

  final List<RemoteSyncDevice> _devices = [];
  final Set<String> _localIps = {};

  String _deviceId = '';
  String _localIp = '';
  int _localPort = 0;

  bool _running = false;
  bool _starting = false;
  bool _disposed = false;
  String? _lastError;

  /// Kept so the pages that call `kit.syncToDevice` / `kit.receiveFromQrOrAddress`
  /// keep working: this controller exposes the same methods.
  RemoteSyncController get kit => this;

  @override
  RemoteSyncSnapshot build() {
    _deviceId = _loadDeviceId();
    ref.onDispose(() {
      _disposed = true;
      unawaited(stop());
    });
    unawaited(start());
    return const RemoteSyncSnapshot();
  }

  static String _loadDeviceId() {
    const key = 'remote_sync_device_id';
    final existing = HivePrefUtil.getString(key);
    if (existing != null && existing.isNotEmpty) return existing;
    final id = 'tv-${DateTime.now().microsecondsSinceEpoch}';
    HivePrefUtil.setString(key, id);
    return id;
  }

  // ---------------------------------------------------------------------------
  // Lifecycle
  // ---------------------------------------------------------------------------

  Future<void> start() async {
    if (_disposed || _running || _starting) return;
    _starting = true;
    _lastError = null;
    try {
      await _refreshNetworkInfo();
      if (_disposed) return;
      if (_localIp.isEmpty) {
        _lastError = 'no LAN address';
        _publish();
        return;
      }
      final bound = await _startServer();
      if (_disposed) return;
      if (!bound) {
        _lastError = 'port unavailable';
        _publish();
        return;
      }
      _running = true;
      await _startDiscoveryAndBroadcast();
      _publish();
    } catch (e) {
      _lastError = '$e';
      _publish();
    } finally {
      _starting = false;
    }
  }

  Future<void> stop() async {
    debugPrint('[sync] stop() called, running=$_running');
    _running = false;

    _cleanupTimer?.cancel();
    _cleanupTimer = null;

    await _discoverySub?.cancel();
    _discoverySub = null;
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

    _devices.clear();
    _publish();
  }

  Future<void> restart() async {
    await stop();
    _disposed = false;
    await start();
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
      for (final i in interfaces) {
        for (final a in i.addresses) {
          final ip = a.address.trim();
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

      // A manual pick (multi-NIC boxes) wins while its interface still exists;
      // otherwise fall back to the priority guess.
      final manual = HivePrefUtil.getString('syncSelectedIp');
      if (manual != null && manual.isNotEmpty && ips.contains(manual)) {
        _localIp = manual;
      } else {
        _localIp = privateIp ?? fallbackIp ?? '';
      }
    } catch (_) {
      _localIps.clear();
      _localIp = '';
    }
  }

  /// Candidates best-first, for the page's manual selector.
  List<String> get localIpCandidates {
    final list = _localIps.toList();
    list.sort((a, b) {
      final pri = _ipv4Priority(b).compareTo(_ipv4Priority(a));
      return pri != 0 ? pri : a.compareTo(b);
    });
    return list;
  }

  /// Advertises [ip] instead of the auto-picked one. The server binds
  /// 0.0.0.0, so only the advertised address, QR and mDNS TXT change.
  Future<void> selectLocalIp(String ip) async {
    if (!_localIps.contains(ip) || ip == _localIp) return;
    HivePrefUtil.setString('syncSelectedIp', ip);
    _localIp = ip;
    _publish();
    // Re-advertise the new address over mDNS.
    try {
      await _broadcast?.stop();
      _broadcast = null;
      await _startBroadcast();
    } catch (_) {}
  }

  bool _isValidIpv4(String ip) {
    final p = ip.split('.');
    if (p.length != 4) return false;
    return p.every((e) {
      final v = int.tryParse(e);
      return v != null && v >= 0 && v <= 255;
    });
  }

  bool _isPrivateIpv4(String ip) {
    final p = ip.split('.');
    if (p.length != 4) return false;
    final a = int.tryParse(p[0]);
    final b = int.tryParse(p[1]);
    if (a == null || b == null) return false;
    return a == 10 || (a == 172 && b >= 16 && b <= 31) || (a == 192 && b == 168);
  }

  int _ipv4Priority(String ip) {
    if (ip.startsWith('192.168.')) return 3;
    if (ip.startsWith('10.')) return 2;
    final p = ip.split('.');
    if (p.length == 4 && p[0] == '172') {
      final s = int.tryParse(p[1]);
      if (s != null && s >= 16 && s <= 31) return 1;
    }
    return 0;
  }

  String? _ipv4Prefix(String ip) {
    final p = ip.split('.');
    return p.length == 4 ? '${p[0]}.${p[1]}.${p[2]}' : null;
  }

  // ---------------------------------------------------------------------------
  // HTTP server
  // ---------------------------------------------------------------------------

  Future<bool> _startServer() async {
    HttpServer? server;
    var port = RemoteSyncProtocol.defaultHttpPort;
    for (var i = 0; i < 100; i++) {
      try {
        server = await HttpServer.bind(InternetAddress.anyIPv4, port, shared: true);
        break;
      } catch (_) {
        port++;
      }
    }
    if (server == null || _disposed) {
      try {
        await server?.close(force: true);
      } catch (_) {}
      return false;
    }
    _server = server;
    _localPort = port;
    server.listen(_handleRequest, onError: (_) {}, onDone: () {});

    _cleanupTimer?.cancel();
    _cleanupTimer = Timer.periodic(const Duration(seconds: 15), (_) => _cleanupDevices());
    return true;
  }

  Future<void> _handleRequest(HttpRequest request) async {
    final response = request.response;
    final path = request.uri.path;

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
      if (path == RemoteSyncProtocol.apiStatus) {
        await _handleStatus(request);
      } else if (path == RemoteSyncProtocol.apiSettings) {
        await _handleSettings(request);
      } else {
        response.statusCode = HttpStatus.notFound;
        await _write(response, {'code': 404, 'msg': 'Not Found', 'data': false});
      }
    } catch (_) {
      try {
        response.statusCode = HttpStatus.internalServerError;
        await _write(response, {'code': 500, 'msg': 'Internal Server Error', 'data': false});
      } catch (_) {}
    }
  }

  Future<void> _handleStatus(HttpRequest request) async {
    if (request.method != 'GET') {
      await _methodNotAllowed(request.response);
      return;
    }
    await _write(request.response, {
      'code': 200,
      'msg': 'ok',
      'data': {
        'id': _deviceId,
        'name': 'PureLive TV (${Platform.operatingSystem})',
        'platform': Platform.operatingSystem,
        'version': '1.0.0',
        'ip': _localIp,
        'port': _localPort,
      },
    });
  }

  Future<void> _handleSettings(HttpRequest request) async {
    switch (request.method) {
      case 'GET':
        try {
          final settings = ref.read(backupControllerProvider.notifier).exportAllSettings();
          await _write(request.response, {'code': 200, 'msg': 'ok', 'data': settings});
        } catch (_) {
          await _write(request.response, {'code': 500, 'msg': 'Export settings failed', 'data': false});
        }
      case 'POST':
        final body = await _readJson(request);
        final settings = body is Map && body['settings'] is Map
            ? Map<String, dynamic>.from(body['settings'] as Map)
            : null;
        if (settings == null) {
          await _write(request.response, {'code': 400, 'msg': 'Settings is empty', 'data': false});
          return;
        }
        final ok = await _applySettings(settings);
        await _write(request.response, {
          'code': ok ? 200 : 500,
          'msg': ok ? 'ok' : 'apply settings failed',
          'data': ok,
        });
      default:
        await _methodNotAllowed(request.response);
    }
  }

  Future<bool> _applySettings(Map<String, dynamic> settings) async {
    try {
      await ref.read(backupControllerProvider.notifier).restoreAllSettings(settings);
      debugPrint('[sync] applySettings ok');
      return true;
    } catch (e, st) {
      debugPrint('[sync] applySettings failed: $e\n$st');
      return false;
    }
  }

  Future<Object?> _readJson(HttpRequest request) async {
    final content = await utf8.decoder.bind(request).join();
    if (content.trim().isEmpty) return null;
    try {
      return jsonDecode(content);
    } catch (_) {
      return null;
    }
  }

  Future<void> _methodNotAllowed(HttpResponse response) async {
    response.statusCode = HttpStatus.methodNotAllowed;
    await _write(response, {'code': 405, 'msg': 'Method Not Allowed', 'data': false});
  }

  Future<void> _write(HttpResponse response, Map<String, dynamic> data) async {
    response.write(jsonEncode(data));
    await response.close();
  }

  // ---------------------------------------------------------------------------
  // Bonsoir discovery + broadcast
  // ---------------------------------------------------------------------------

  Future<void> _startDiscoveryAndBroadcast() async {
    try {
      final discovery = BonsoirDiscovery(type: RemoteSyncProtocol.mdnsServiceType);
      await discovery.initialize();
      final stream = discovery.eventStream;
      if (stream == null) return;
      _discovery = discovery;
      _discoverySub = stream.listen(_handleDiscovery, onError: (_) {});
      await discovery.start();
      await _startBroadcast();
    } catch (e) {
      _lastError = 'mDNS failed: $e';
    }
  }

  Future<void> _handleDiscovery(BonsoirDiscoveryEvent event) async {
    switch (event) {
      case BonsoirDiscoveryServiceFoundEvent():
        final service = event.service;
        if (_isSelf(service)) return;
        _addOrUpdate(service);
        final resolver = _discovery?.serviceResolver;
        if (resolver != null) {
          try {
            await service.resolve(resolver);
          } catch (_) {}
        }
      case BonsoirDiscoveryServiceResolvedEvent():
      case BonsoirDiscoveryServiceUpdatedEvent():
        final service = event.service;
        if (service == null || _isSelf(service)) return;
        _addOrUpdate(service);
      case BonsoirDiscoveryServiceLostEvent():
        _remove(event.service);
      default:
        break;
    }
  }

  bool _isSelf(BonsoirService service) {
    final id = service.attributes['id']?.trim();
    if (id == _deviceId) return true;
    final ip = service.attributes['ip']?.trim();
    return ip != null && ip.isNotEmpty && _localIps.contains(ip);
  }

  void _addOrUpdate(BonsoirService service) {
    final attrs = service.attributes;
    final id = attrs['id']?.trim() ?? '';
    if (id.isEmpty || id == _deviceId) return;

    final name = (attrs['name']?.trim().isNotEmpty == true) ? attrs['name']!.trim() : service.name;
    final ip = _selectIp(service) ?? attrs['ip']?.trim();
    if (ip == null || !_isValidIpv4(ip)) return;
    final port = service.port > 0 ? service.port : RemoteSyncProtocol.defaultHttpPort;

    final device = RemoteSyncDevice(
      id: id,
      name: name,
      platform: attrs['platform'] ?? '',
      version: attrs['version'] ?? '',
      ip: ip,
      port: port,
      lastSeen: DateTime.now(),
      bonsoirName: service.name,
    );

    final byId = _devices.indexWhere((d) => d.id == device.id);
    if (byId >= 0) {
      _devices[byId] = device;
      _publish();
      return;
    }
    final byIp = _devices.indexWhere((d) => d.ip == device.ip);
    if (byIp >= 0) {
      _devices[byIp] = device;
      _publish();
      return;
    }
    _devices.add(device);
    _publish();
  }

  void _remove(BonsoirService service) {
    final id = service.attributes['id']?.trim();
    final before = _devices.length;
    if (id != null && id.isNotEmpty) {
      _devices.removeWhere((d) => d.id == id);
    } else {
      _devices.removeWhere((d) => d.bonsoirName == service.name);
    }
    if (_devices.length != before) _publish();
  }

  String? _selectIp(BonsoirService service) {
    final addresses = service.hostAddresses.where(_isValidIpv4).toList();
    if (addresses.isNotEmpty) {
      final prefix = _ipv4Prefix(_localIp);
      if (prefix != null) {
        for (final ip in addresses) {
          if (_ipv4Prefix(ip) == prefix) return ip;
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
    final suffix = _deviceId.length > 6 ? _deviceId.substring(_deviceId.length - 6) : _deviceId;
    final service = BonsoirService(
      name: 'PureLive-$suffix',
      type: RemoteSyncProtocol.mdnsServiceType,
      port: _localPort,
      attributes: {
        'id': _deviceId,
        'name': 'PureLive TV (${Platform.operatingSystem})',
        'platform': Platform.operatingSystem,
        'version': '1.0.0',
        'ip': _localIp,
      },
    );
    final broadcast = BonsoirBroadcast(service: service);
    await broadcast.initialize();
    await broadcast.start();
    _broadcast = broadcast;
  }

  void _cleanupDevices() {
    final now = DateTime.now();
    final before = _devices.length;
    _devices.removeWhere((d) => now.difference(d.lastSeen).inSeconds > 120);
    if (_devices.length != before) _publish();
  }

  // ---------------------------------------------------------------------------
  // Outgoing sync
  // ---------------------------------------------------------------------------

  Future<bool> syncToDevice(RemoteSyncDevice device) => syncToAddress(device.ip, device.port);

  Future<bool> syncToAddress(String ip, int port) async {
    try {
      final settings = ref.read(backupControllerProvider.notifier).exportAllSettings();
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
    } catch (_) {
      return false;
    }
  }

  Future<bool> receiveFromAddress(String ip, int port) async {
    final client = HttpClient();
    try {
      final request = await client.getUrl(Uri.parse('http://$ip:$port${RemoteSyncProtocol.apiSettings}'));
      final response = await request.close();
      final body = await utf8.decoder.bind(response).join();

      if (response.statusCode != HttpStatus.ok) return false;
      final result = jsonDecode(body);
      if (result is! Map || result['code'] != 200 || result['data'] is! Map) return false;
      return await _applySettings(Map<String, dynamic>.from(result['data'] as Map));
    } catch (e) {
      debugPrint('[sync] receiveFromAddress $ip:$port failed: $e');
      return false;
    } finally {
      client.close(force: true);
    }
  }

  Future<bool> receiveFromQrOrAddress(String value) async {
    final parsed = RemoteSyncProtocol.parseQr(value);
    if (parsed == null) return false;
    return receiveFromAddress(parsed.ip, parsed.port);
  }

  Future<bool> syncByAddress(String value) async {
    final parsed = RemoteSyncProtocol.parseHttpAddress(value);
    if (parsed == null) return false;
    return syncToAddress(parsed.ip, parsed.port);
  }

  Future<bool> syncByQr(String value) async {
    final parsed = RemoteSyncProtocol.parseQr(value);
    if (parsed == null) return false;
    return syncToAddress(parsed.ip, parsed.port);
  }

  Future<bool> receiveByQr(String value) async {
    final parsed = RemoteSyncProtocol.parseQr(value);
    if (parsed == null) return false;
    return receiveFromAddress(parsed.ip, parsed.port);
  }

  // ---------------------------------------------------------------------------
  // Publish
  // ---------------------------------------------------------------------------

  /// `purelive://ip:port/sync`, built by interpolation and validated: the QR
  /// must carry the live address or it is useless to the phone, and a degenerate
  /// payload (an empty host once rendered as bare `purelive://`) must not be
  /// published as if pairing were possible.
  String _buildQrData() {
    if (_localIp.isEmpty || _localPort <= 0) return '';
    final payload = 'purelive://$_localIp:$_localPort/sync';
    return payload.contains('://$_localIp:') ? payload : '';
  }

  void _publish() {
    debugPrint('[sync] publish ip=$_localIp port=$_localPort running=$_running');
    if (!ref.mounted) return;
    state = RemoteSyncSnapshot(
      started: _running,
      qrData: _buildQrData(),
      address: _localIp.isEmpty ? '' : '$_localIp:$_localPort',
      error: _running ? null : _lastError,
      devices: List.unmodifiable(_devices),
      localIps: localIpCandidates,
    );
  }
}
