import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:bonsoir/bonsoir.dart';
import 'package:pure_live/exports/package_export.dart';
import 'package:pure_live/features/sync/remote_sync_device.dart';
import 'package:pure_live/features/sync/remote_sync_protocol.dart';
import 'package:pure_live/features/sync/sync_groups.dart';
import 'package:pure_live/services/backup/backup_controller.dart';
import 'package:pure_live/shared/i18n/locale_helper.dart';
import 'package:pure_live/shared/utils/hive_pref_util.dart';

final lanSyncControllerProvider = NotifierProvider<LanSyncController, LanSyncState>(LanSyncController.new);

/// 局域网同步的可视状态。
class LanSyncState {
  const LanSyncState({
    this.running = false,
    this.discovering = false,
    this.busy = false,
    this.localIp = '',
    this.devices = const <RemoteSyncDevice>[],
    this.groups = SyncGroups.defaultSelection,
    this.status = '',
  });

  final bool running;
  final bool discovering;
  final bool busy;
  final String localIp;
  final List<RemoteSyncDevice> devices;
  final Set<SyncGroup> groups;

  /// 一句话结果/错误提示，空串表示无提示。
  final String status;

  LanSyncState copyWith({
    bool? running,
    bool? discovering,
    bool? busy,
    String? localIp,
    List<RemoteSyncDevice>? devices,
    Set<SyncGroup>? groups,
    String? status,
  }) {
    return LanSyncState(
      running: running ?? this.running,
      discovering: discovering ?? this.discovering,
      busy: busy ?? this.busy,
      localIp: localIp ?? this.localIp,
      devices: devices ?? this.devices,
      groups: groups ?? this.groups,
      status: status ?? this.status,
    );
  }
}

/// 局域网同步：Bonsoir mDNS 发现 + 独立的 39888 HTTP 服务。
///
/// 为什么不用现成的 8888 手机遥控服务：那条通道是给「手机扫码当遥控器」用的，
/// 路由和生命周期都绑在 `TvRemoteReceiver` 上；同步需要长期在线、要能和局域网里
/// 其他 PureLive 实例互相发现，所以按参考实现 `D:\flutter\pure_live` 的做法单开
/// 一条通道（mDNS 类型与服务端口都与它一致，便于跨端互通）。
class LanSyncController extends Notifier<LanSyncState> {
  static const String _appVersion = '1.0.0';
  static const String _deviceIdKey = 'lan_sync_device_id';
  static const Duration _cleanupInterval = Duration(seconds: 15);
  static const Duration _deviceStaleAfter = Duration(seconds: 120);

  HttpServer? _server;
  BonsoirBroadcast? _broadcast;
  BonsoirDiscovery? _discovery;
  StreamSubscription<BonsoirDiscoveryEvent>? _discoverySub;
  Timer? _cleanupTimer;
  String _deviceId = '';
  bool _disposed = false;

  @override
  LanSyncState build() {
    ref.onDispose(_teardown);
    _deviceId = _loadDeviceId();
    return const LanSyncState();
  }

  String get deviceName {
    if (Platform.isAndroid) return 'PureLive TV';
    switch (Platform.operatingSystem) {
      case 'ios':
        return 'PureLive iPhone';
      case 'windows':
        return 'PureLive Windows';
      case 'macos':
        return 'PureLive macOS';
      case 'linux':
        return 'PureLive Linux';
      default:
        return 'PureLive';
    }
  }

  String get broadcastName {
    final suffix = _deviceId.length > 6 ? _deviceId.substring(_deviceId.length - 6) : _deviceId;
    return 'PureLive-$suffix';
  }

  // ---------------------------------------------------------------------------
  // 生命周期
  // ---------------------------------------------------------------------------

  Future<void> start() async {
    if (state.running || _disposed) return;
    state = state.copyWith(status: i18nOr('ui_lan_starting', '正在启动局域网同步…'));

    final ip = await _resolveLocalIp();
    if (ip.isEmpty) {
      state = state.copyWith(running: false, status: i18nOr('ui_lan_no_ip', '未找到局域网 IP，请检查网络连接'));
      return;
    }

    if (!await _startServer()) {
      state = state.copyWith(
        running: false,
        status: i18nOr('ui_lan_port_busy', '端口 39888 被占用，同步服务未启动'),
      );
      return;
    }

    final discovering = await _startDiscovery(ip);
    _startCleanup();
    state = state.copyWith(
      running: true,
      discovering: discovering,
      localIp: ip,
      status: discovering ? '' : i18nOr('ui_lan_discovery_failed', '已开启接收，但设备发现失败'),
    );
  }

  Future<void> stop() async {
    await _stopBroadcastAndDiscovery();
    final server = _server;
    _server = null;
    if (server != null) {
      try {
        await server.close(force: true);
      } catch (_) {}
    }
    _cleanupTimer?.cancel();
    _cleanupTimer = null;
    if (ref.mounted) {
      state = state.copyWith(running: false, discovering: false, devices: const <RemoteSyncDevice>[], status: '');
    }
  }

  Future<void> toggle() => state.running ? stop() : start();

  void toggleGroup(SyncGroup group) {
    final next = Set<SyncGroup>.from(state.groups);
    if (!next.remove(group)) next.add(group);
    state = state.copyWith(groups: next);
  }

  /// 清掉过期的对端设备（对方关掉服务后 mDNS 不一定能及时通知）。
  void _startCleanup() {
    _cleanupTimer?.cancel();
    _cleanupTimer = Timer.periodic(_cleanupInterval, (_) {
      if (_disposed || !ref.mounted) return;
      final now = DateTime.now();
      final alive = state.devices
          .where((device) => now.difference(device.lastSeen) < _deviceStaleAfter)
          .toList(growable: false);
      if (alive.length != state.devices.length) {
        state = state.copyWith(devices: alive);
      }
    });
  }

  // ---------------------------------------------------------------------------
  // HTTP 服务
  // ---------------------------------------------------------------------------

  Future<bool> _startServer() async {
    try {
      final server = await HttpServer.bind(InternetAddress.anyIPv4, RemoteSyncProtocol.httpPort);
      _server = server;
      server.listen(
        (request) => unawaited(_handleRequest(request)),
        onError: (_) {},
        cancelOnError: false,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _handleRequest(HttpRequest request) async {
    try {
      final path = request.uri.path;
      if (path == RemoteSyncProtocol.apiStatus) {
        await _writeJson(request, <String, dynamic>{
          'type': RemoteSyncProtocol.syncType,
          'version': 1,
          'platform': Platform.operatingSystem,
          'name': deviceName,
          'appVersion': _appVersion,
        });
        return;
      }

      if (path == RemoteSyncProtocol.apiSettings) {
        if (request.method == 'GET') {
          await _writeJson(request, <String, dynamic>{
            'type': RemoteSyncProtocol.syncType,
            'version': 1,
            'settings': _buildPayload(),
          });
          return;
        }
        if (request.method == 'POST') {
          final body = await utf8.decoder.bind(request).join();
          final decoded = body.isEmpty ? null : jsonDecode(body);
          final applied = _applyIncoming(
            decoded is Map ? Map<String, dynamic>.from(decoded) : const <String, dynamic>{},
          );
          await _writeJson(request, <String, dynamic>{'ok': applied});
          return;
        }
      }

      request.response.statusCode = HttpStatus.notFound;
      await request.response.close();
    } catch (_) {
      try {
        await request.response.close();
      } catch (_) {}
    }
  }

  Future<void> _writeJson(HttpRequest request, Map<String, dynamic> payload) async {
    request.response
      ..statusCode = HttpStatus.ok
      ..headers.contentType = ContentType.json
      ..write(jsonEncode(payload));
    await request.response.close();
  }

  // ---------------------------------------------------------------------------
  // 设置载荷
  // ---------------------------------------------------------------------------

  /// 只导出被勾选分组覆盖的分区。
  Map<String, dynamic> _buildPayload() {
    final includeSensitive = state.groups.contains(SyncGroup.sensitive);
    final all = ref
        .read(backupControllerProvider.notifier)
        .exportAllSettings(includeSensitiveData: includeSensitive);
    final scoped = <String, dynamic>{};
    for (final section in SyncGroups.sectionsOf(state.groups)) {
      if (all.containsKey(section)) scoped[section] = all[section];
    }
    return scoped;
  }

  /// 只应用载荷里真实存在的分区，避免把对方没勾选的设置清成默认值。
  bool _applyIncoming(Map<String, dynamic> data) {
    final raw = data['settings'];
    final settings = raw is Map ? Map<String, dynamic>.from(raw) : data;

    final scoped = <String, dynamic>{
      'backupVersion': BackupController.backupVersion,
      'sensitiveDataIncluded': true,
    };
    for (final section in BackupController.knownSections) {
      if (settings.containsKey(section)) scoped[section] = settings[section];
    }
    if (scoped.length <= 2) return false;

    try {
      ref.read(backupControllerProvider.notifier).importAllSettings(scoped);
      return true;
    } catch (_) {
      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // 推送 / 拉取
  // ---------------------------------------------------------------------------

  /// 把本机勾选的设置推给 [device]。
  Future<bool> syncTo(RemoteSyncDevice device) => _pushTo(device.ip, device.port, device.name);

  Future<bool> _pushTo(String ip, int port, String label) async {
    if (state.busy) return false;
    state = state.copyWith(busy: true, status: '');

    final payload = _buildPayload();
    if (payload.isEmpty) {
      state = state.copyWith(busy: false, status: i18nOr('ui_lan_nothing_selected', '没有勾选任何要同步的内容'));
      return false;
    }

    try {
      final dio = _dio();
      final response = await dio.post<dynamic>(
        '${RemoteSyncProtocol.httpBase(ip, port)}${RemoteSyncProtocol.apiSettings}',
        data: jsonEncode(<String, dynamic>{
          'type': RemoteSyncProtocol.syncType,
          'version': 1,
          'settings': payload,
        }),
        options: Options(contentType: Headers.jsonContentType),
      );
      final ok = response.statusCode == HttpStatus.ok;
      state = state.copyWith(
        busy: false,
        status: ok ? i18nOr('ui_lan_sent', '已发送到 $label') : i18nOr('ui_lan_send_failed', '发送失败'),
      );
      return ok;
    } catch (_) {
      state = state.copyWith(busy: false, status: i18nOr('ui_lan_send_failed', '发送失败，请确认在同一局域网'));
      return false;
    }
  }

  /// 从 [device] 拉取设置并应用到本机。
  Future<bool> pullFrom(RemoteSyncDevice device) async {
    if (state.busy) return false;
    state = state.copyWith(busy: true, status: '');

    try {
      final dio = _dio();
      final response = await dio.get<dynamic>(
        '${RemoteSyncProtocol.httpBase(device.ip, device.port)}${RemoteSyncProtocol.apiSettings}',
      );
      final data = response.data;
      final ok = data is Map && _applyIncoming(Map<String, dynamic>.from(data));
      state = state.copyWith(
        busy: false,
        status: ok
            ? i18nOr('ui_lan_received', '已从 ${device.name} 接收设置')
            : i18nOr('ui_lan_receive_failed', '接收失败或对方没有可同步的设置'),
      );
      return ok;
    } catch (_) {
      state = state.copyWith(busy: false, status: i18nOr('ui_lan_receive_failed', '接收失败，请确认设备在线'));
      return false;
    }
  }

  Dio _dio() => Dio(
    BaseOptions(
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 15),
      sendTimeout: const Duration(seconds: 15),
    ),
  );

  // ---------------------------------------------------------------------------
  // Bonsoir 发现 / 广播
  // ---------------------------------------------------------------------------

  Future<bool> _startDiscovery(String localIp) async {
    await _stopBroadcastAndDiscovery();
    if (_disposed) return false;

    try {
      final discovery = BonsoirDiscovery(type: RemoteSyncProtocol.mdnsServiceType);
      _discovery = discovery;
      await discovery.initialize();
      if (_disposed) {
        await discovery.stop();
        return false;
      }

      final events = discovery.eventStream;
      if (events == null) return false;

      _discoverySub = events.listen(
        (event) => unawaited(_handleDiscoveryEvent(event, discovery, localIp)),
        onError: (_) {},
      );

      await discovery.start();
      if (_disposed) {
        await discovery.stop();
        return false;
      }

      await _startBroadcast(localIp);
      return true;
    } catch (_) {
      return false;
    }
  }

  Future<void> _handleDiscoveryEvent(BonsoirDiscoveryEvent event, BonsoirDiscovery discovery, String localIp) async {
    if (_disposed || !ref.mounted) return;

    switch (event) {
      case BonsoirDiscoveryServiceFoundEvent():
        final service = event.service;
        if (_isSelfService(service, localIp)) return;
        // TXT 里已经带了 IP，先落一个设备，再后台 resolve 拿更准的地址。
        _addOrUpdateDevice(service, localIp);
        try {
          service.resolve(discovery.serviceResolver);
        } catch (_) {}
      case BonsoirDiscoveryServiceResolvedEvent():
        if (_isSelfService(event.service, localIp)) return;
        _addOrUpdateDevice(event.service, localIp);
      case BonsoirDiscoveryServiceUpdatedEvent():
        if (_isSelfService(event.service, localIp)) return;
        _addOrUpdateDevice(event.service, localIp);
      case BonsoirDiscoveryServiceLostEvent():
        _removeDevice(event.service);
      default:
        break;
    }
  }

  bool _isSelfService(BonsoirService service, String localIp) {
    final id = service.attributes['id']?.trim();
    if (id != null && id.isNotEmpty && id == _deviceId) return true;
    final ip = service.attributes['ip']?.trim();
    return ip != null && ip.isNotEmpty && ip == localIp;
  }

  void _addOrUpdateDevice(BonsoirService service, String localIp) {
    if (_disposed || !ref.mounted) return;
    final device = RemoteSyncDevice.fromService(service, localIp: localIp);
    if (device == null || device.id == _deviceId) return;

    final devices = List<RemoteSyncDevice>.from(state.devices);
    final byId = devices.indexWhere((item) => item.id == device.id);
    if (byId >= 0) {
      devices[byId] = device;
    } else {
      final byIp = devices.indexWhere((item) => item.ip == device.ip);
      if (byIp >= 0) {
        devices[byIp] = device;
      } else {
        devices.add(device);
      }
    }
    state = state.copyWith(devices: devices);
  }

  void _removeDevice(BonsoirService service) {
    if (_disposed || !ref.mounted) return;
    final id = service.attributes['id']?.trim();
    final devices = state.devices
        .where((device) => id != null && id.isNotEmpty ? device.id != id : device.bonsoirName != service.name)
        .toList(growable: false);
    if (devices.length != state.devices.length) {
      state = state.copyWith(devices: devices);
    }
  }

  Future<void> _startBroadcast(String localIp) async {
    if (_disposed) return;
    try {
      final service = BonsoirService(
        name: broadcastName,
        type: RemoteSyncProtocol.mdnsServiceType,
        port: RemoteSyncProtocol.httpPort,
        attributes: <String, String>{
          'id': _deviceId,
          'name': deviceName,
          'platform': Platform.operatingSystem,
          'version': _appVersion,
          'ip': localIp,
        },
      );
      final broadcast = BonsoirBroadcast(service: service);
      _broadcast = broadcast;
      await broadcast.initialize();
      if (_disposed) {
        await broadcast.stop();
        return;
      }
      await broadcast.start();
    } catch (_) {}
  }

  Future<void> _stopBroadcastAndDiscovery() async {
    final sub = _discoverySub;
    _discoverySub = null;
    if (sub != null) {
      try {
        await sub.cancel();
      } catch (_) {}
    }

    final discovery = _discovery;
    _discovery = null;
    if (discovery != null) {
      try {
        await discovery.stop();
      } catch (_) {}
    }

    final broadcast = _broadcast;
    _broadcast = null;
    if (broadcast != null) {
      try {
        await broadcast.stop();
      } catch (_) {}
    }
  }

  // ---------------------------------------------------------------------------
  // 工具
  // ---------------------------------------------------------------------------

  String _loadDeviceId() {
    final existing = HivePrefUtil.getString(_deviceIdKey);
    if (existing != null && existing.isNotEmpty) return existing;
    final id = '${Platform.operatingSystem}-${DateTime.now().microsecondsSinceEpoch}';
    HivePrefUtil.setString(_deviceIdKey, id);
    return id;
  }

  /// 取一个可用的局域网 IPv4（优先私有网段，跳回环）。
  Future<String> _resolveLocalIp() async {
    try {
      final interfaces = await NetworkInterface.list(type: InternetAddressType.IPv4, includeLoopback: false);
      String? fallback;
      for (final interface in interfaces) {
        for (final address in interface.addresses) {
          final ip = address.address;
          if (!RemoteSyncDevice.isValidIpv4(ip)) continue;
          fallback ??= ip;
          if (ip.startsWith('192.168.') || ip.startsWith('10.') || ip.startsWith('172.')) return ip;
        }
      }
      return fallback ?? '';
    } catch (_) {
      return '';
    }
  }

  void _teardown() {
    _disposed = true;
    _cleanupTimer?.cancel();
    _cleanupTimer = null;
    unawaited(_stopBroadcastAndDiscovery());
    final server = _server;
    _server = null;
    if (server != null) {
      unawaited(server.close(force: true).catchError((Object _) {}));
    }
  }
}
