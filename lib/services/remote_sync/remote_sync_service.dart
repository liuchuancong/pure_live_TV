import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:bonsoir/bonsoir.dart';
import 'package:flutter/widgets.dart';
import 'package:pure_live/shared/utils/hive_pref_util.dart';
import 'package:pure_live/shared/utils/toast_util.dart';
import 'package:pure_live/shared/utils/date_time_utils.dart';
import 'package:pure_live/shared/i18n/locale_helper.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:pure_live/app/bootstrap/app_navigator.dart';
import 'package:pure_live/services/backup/backup_controller.dart';
import 'package:pure_live/shared/dialog/backup_import_dialog.dart';
import 'package:pure_live/services/remote_sync/remote_sync_device.dart';
import 'package:pure_live/services/remote_sync/remote_sync_protocol.dart';
import 'package:pure_live/shared/platform/local_network_access.dart';

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

  /// Result of the most recent inbound settings push (a phone sending its own
  /// settings to this TV), empty until one arrives, formatted as message plus
  /// time. A push only rewrites settings, so without this line the TV looks
  /// exactly as it did before and the operator cannot tell whether it landed.
  final String lastReceiveNotice;

  /// Whether that push was applied.
  final bool lastReceiveOk;

  /// Code the other device must present, shown on screen and carried by the
  /// QR; empty while the service is stopped.
  final String pairingCode;

  /// Account cookies travel only when the user opts in on this device.
  final bool includeAccounts;

  const RemoteSyncSnapshot({
    this.started = false,
    this.qrData = '',
    this.address = '',
    this.error,
    this.devices = const [],
    this.localIps = const [],
    this.lastReceiveNotice = '',
    this.lastReceiveOk = true,
    this.pairingCode = '',
    this.includeAccounts = false,
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
  String _lastReceiveNotice = '';
  bool _lastReceiveOk = true;

  /// One settings transfer at a time, in both directions — the reference's
  /// `isSyncing` / `isApplying` guards.
  bool _syncing = false;
  bool _applying = false;

  /// Regenerated every time the server starts, so a code seen once is useless
  /// after the service was stopped.
  String _pairingCode = '';
  bool _includeAccounts = false;

  /// The name other devices see in their LAN list, per platform like the
  /// reference ('PureLive Android' / 'PureLive Windows' / ...).
  static String get _deviceName => switch (Platform.operatingSystem) {
    'android' => 'PureLive Android',
    'ios' => 'PureLive iPhone',
    'windows' => 'PureLive Windows',
    'macos' => 'PureLive macOS',
    'linux' => 'PureLive Linux',
    _ => 'PureLive',
  };

  /// Asks the user whether [remoteAddress] may read ('export') or overwrite
  /// ('import') this device's settings. Requests are refused without it.
  Future<bool> Function(String action, String remoteAddress)? confirmRequest;

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
    // Same shape as the reference: platform-prefixed, so devices of different
    // kinds are tellable apart in logs and pair lists.
    final id = '${Platform.operatingSystem}-${DateTime.now().microsecondsSinceEpoch}';
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
      // Android 17 blocks LAN sockets without the local-network permission.
      if (!await LocalNetworkAccess.ensure()) return;
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
    _pairingCode = '';

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
    _pairingCode = RemoteSyncProtocol.newPairingCode();
    server.listen(
      _handleRequest,
      onError: (_) {
        // The reference marks the server down when its socket dies, so the
        // page stops advertising a service that can no longer answer.
        if (!_disposed && _running) {
          _running = false;
          _publish();
        }
      },
      onDone: () {},
    );

    _cleanupTimer?.cancel();
    _cleanupTimer = Timer.periodic(const Duration(seconds: 15), (_) => _cleanupDevices());
    return true;
  }

  Future<void> _handleRequest(HttpRequest request) async {
    final response = request.response;
    final path = request.uri.path;

    // No CORS headers: a web page in a browser on the network must not be able
    // to read this device's settings.
    response.headers.contentType = ContentType('application', 'json', charset: 'utf-8');
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
        'name': _deviceName,
        'platform': Platform.operatingSystem,
        'version': '1.0.0',
        'ip': _localIp,
        'port': _localPort,
      },
    });
  }

  Future<void> _handleSettings(HttpRequest request) async {
    if (!RemoteSyncProtocol.pairingCodesMatch(
      _pairingCode,
      request.headers.value(RemoteSyncProtocol.pairingHeader),
    )) {
      request.response.statusCode = HttpStatus.forbidden;
      await _write(request.response, {'code': 403, 'msg': 'Pairing code required', 'data': false});
      return;
    }
    // Both directions are confirmed by the operator, exactly like the reference
    // client: reading hands out account cookies, a push can overwrite this
    // device's own setup. The module picker in [_applySettings] narrows WHAT a
    // push lands afterwards, on top of this consent.
    final action = switch (request.method) {
      'GET' => 'export',
      'POST' => 'import',
      _ => null,
    };
    if (action != null && !await _confirm(action, request)) {
      request.response.statusCode = HttpStatus.forbidden;
      await _write(request.response, {'code': 403, 'msg': 'Rejected on the device', 'data': false});
      return;
    }
    switch (request.method) {
      case 'GET':
        try {
          final settings = ref
              .read(backupControllerProvider.notifier)
              .exportAllSettings(includeSensitiveData: _includeAccounts);
          await _write(request.response, {'code': 200, 'msg': 'ok', 'data': settings});
          // The paired app imports this TV's settings: nothing changes here, so
          // the toast is the only sign that the sync happened at all.
          ToastUtil.show(i18n('remote_sync_send_success'));
        } catch (_) {
          await _write(request.response, {'code': 500, 'msg': 'Export settings failed', 'data': false});
        }
      case 'POST':
        final body = await _readJson(request);
        if (body is! Map || body['type']?.toString() != RemoteSyncProtocol.syncType) {
          await _write(request.response, {'code': 400, 'msg': 'Invalid sync type', 'data': false});
          return;
        }
        final settings = body['settings'] is Map ? Map<String, dynamic>.from(body['settings'] as Map) : null;
        if (settings == null) {
          await _write(request.response, {'code': 400, 'msg': 'Settings is empty', 'data': false});
          return;
        }
        if (_applying) {
          await _write(request.response, {'code': 409, 'msg': 'Busy', 'data': false});
          return;
        }
        _applying = true;
        bool ok;
        try {
          ok = await _applySettings(settings);
        } finally {
          _applying = false;
        }
        _announceReceive(ok);
        await _write(request.response, {
          'code': ok ? 200 : 500,
          'msg': ok ? 'ok' : 'apply settings failed',
          'data': ok,
        });
      default:
        await _methodNotAllowed(request.response);
    }
  }

  /// Asks the page (which owns the UI) to confirm an inbound request. No page
  /// is listening when the sync page is closed — and the service is stopped
  /// with it — so an unanswered request is refused.
  Future<bool> _confirm(String action, HttpRequest request) async {
    final ask = confirmRequest;
    if (ask == null || _disposed) return false;
    final remote = request.connectionInfo?.remoteAddress.address ?? '';
    try {
      return await ask(action, remote);
    } catch (_) {
      return false;
    }
  }

  Future<bool> _applySettings(Map<String, dynamic> settings) async {
    // The viewer picks the modules before anything lands: an inbound document can
    // come from another TV, from the phone or from the web page, and only the two
    // TV kinds are trusted with the device's own player/theme/proxy setup. No UI
    // to ask (a request arriving before the first frame) falls back to the
    // document's own defaults.
    final BuildContext? context = appNavigatorContext;
    final Set<String> defaults = BackupController.defaultSections(settings);
    final Set<String>? sections = context == null
        ? defaults
        : await showBackupImportPicker(
            context,
            modules: BackupController.importableSections(settings),
            defaults: defaults,
            sourceIsTv: BackupController.sourceIsTv(settings),
          );

    if (sections == null) {
      debugPrint('[sync] applySettings cancelled');
      return false;
    }

    try {
      await ref.read(backupControllerProvider.notifier).restoreAllSettings(settings, sections: sections);
      debugPrint('[sync] applySettings ok');
      return true;
    } catch (e, st) {
      debugPrint('[sync] applySettings failed: $e\n$st');
      return false;
    }
  }

  /// Reports an inbound settings push on the TV: a toast for the moment it
  /// lands, and the line the device sync page keeps on screen afterwards.
  void _announceReceive(bool ok) {
    final String message = i18n(ok ? 'remote_sync_receive_success' : 'remote_sync_receive_failed');
    _lastReceiveOk = ok;
    _lastReceiveNotice = '$message · ${DateTimeUtils.parseTime(DateTime.now())}';
    _publish();
    ToastUtil.show(message);
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
        'name': _deviceName,
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

  Future<bool> syncToDevice(RemoteSyncDevice device, {String? code}) =>
      syncToAddress(device.ip, device.port, code: code);

  Future<bool> syncToAddress(String ip, int port, {String? code}) async {
    if (_disposed || _syncing) return false;
    _syncing = true;
    try {
      final settings = ref
          .read(backupControllerProvider.notifier)
          .exportAllSettings(includeSensitiveData: _includeAccounts);
      final client = HttpClient();
      try {
        final request = await client.postUrl(Uri.parse('http://$ip:$port${RemoteSyncProtocol.apiSettings}'));
        request.headers.contentType = ContentType('application', 'json', charset: 'utf-8');
        // Always carried and normalized, exactly like the reference sender: a
        // code with a stray space must not turn into a header-less request
        // that dies as 403 on the far side.
        request.headers.set(RemoteSyncProtocol.pairingHeader, RemoteSyncProtocol.normalizePairingCode(code));
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
    } finally {
      _syncing = false;
    }
  }

  /// The peer's raw settings document — the reference's `getRemoteSettings`.
  /// Does NOT apply anything; [receiveFromAddress] is the applying wrapper.
  Future<Map<String, dynamic>?> getRemoteSettings(String ip, int port, {String? code}) async {
    if (_disposed) return null;
    final client = HttpClient();
    try {
      final request = await client.getUrl(Uri.parse('http://$ip:$port${RemoteSyncProtocol.apiSettings}'));
      request.headers.set(RemoteSyncProtocol.pairingHeader, RemoteSyncProtocol.normalizePairingCode(code));
      final response = await request.close();
      final body = await utf8.decoder.bind(response).join();
      if (response.statusCode != HttpStatus.ok) return null;
      final result = jsonDecode(body);
      if (result is! Map || result['code'] != 200 || result['data'] is! Map) return null;
      return Map<String, dynamic>.from(result['data'] as Map);
    } catch (_) {
      return null;
    } finally {
      client.close(force: true);
    }
  }

  /// Whether the peer answers at all — the reference's reachability check
  /// (GET /status, no settings, no pairing code).
  Future<bool> checkRemoteDevice(String ip, int port) async {
    if (_disposed) return false;
    final client = HttpClient();
    try {
      final request = await client.getUrl(Uri.parse('http://$ip:$port${RemoteSyncProtocol.apiStatus}'));
      final response = await request.close();
      return response.statusCode == HttpStatus.ok;
    } catch (_) {
      return false;
    } finally {
      client.close(force: true);
    }
  }

  Future<bool> receiveFromAddress(String ip, int port, {String? code}) async {
    if (_disposed || _applying) return false;
    _applying = true;
    try {
      final settings = await getRemoteSettings(ip, port, code: code);
      if (settings == null) return false;
      return await _applySettings(settings);
    } catch (e) {
      debugPrint('[sync] receiveFromAddress $ip:$port failed: $e');
      return false;
    } finally {
      _applying = false;
    }
  }

  Future<bool> receiveFromQrOrAddress(String value, {String? code}) async {
    final parsed = RemoteSyncProtocol.parseQr(value);
    if (parsed == null) return false;
    return receiveFromAddress(parsed.ip, parsed.port, code: code ?? parsed.code);
  }

  Future<bool> syncByAddress(String value, {String? code}) async {
    final parsed = RemoteSyncProtocol.parseHttpAddress(value);
    if (parsed == null) return false;
    return syncToAddress(parsed.ip, parsed.port, code: code);
  }

  Future<bool> syncByQr(String value, {String? code}) async {
    final parsed = RemoteSyncProtocol.parseQr(value);
    if (parsed == null) return false;
    return syncToAddress(parsed.ip, parsed.port, code: code ?? parsed.code);
  }

  Future<bool> receiveByQr(String value, {String? code}) async {
    final parsed = RemoteSyncProtocol.parseQr(value);
    if (parsed == null) return false;
    return receiveFromAddress(parsed.ip, parsed.port, code: code ?? parsed.code);
  }

  /// Account cookies travel only when the user opts in here.
  void setIncludeAccounts(bool value) {
    if (_includeAccounts == value) return;
    _includeAccounts = value;
    _publish();
  }

  // ---------------------------------------------------------------------------
  // Publish
  // ---------------------------------------------------------------------------

  /// `purelive://ip:port/sync?code=NNNNNN`, built by interpolation and
  /// validated: the QR must carry the live address or it is useless to the
  /// phone, and a degenerate payload (an empty host once rendered as bare
  /// `purelive://`) must not be published as if pairing were possible.
  String _buildQrData() {
    if (_localIp.isEmpty || _localPort <= 0 || _pairingCode.isEmpty) return '';
    final payload = RemoteSyncProtocol.createQrUri(ip: _localIp, port: _localPort, code: _pairingCode).toString();
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
      lastReceiveNotice: _lastReceiveNotice,
      lastReceiveOk: _lastReceiveOk,
      pairingCode: _running ? _pairingCode : '',
      includeAccounts: _includeAccounts,
    );
  }
}
