import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:alfred/alfred.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pure_live/exports/package_export.dart';
import 'package:pure_live/features/iptv/services/iptv_import_manager.dart';
import 'package:pure_live/services/backup/backup_controller.dart';
import 'package:pure_live/services/cookie_manager/cookie_controller.dart';
import 'package:pure_live/services/tag_management/tag_management_controller.dart';
import 'package:pure_live/services/proxy_settings/proxy_settings_controller.dart';
import 'package:pure_live/services/proxy_settings/proxy_settings_model.dart';
import 'package:pure_live/services/iptv_settings/iptv_settings_controller.dart';
import 'package:pure_live/shared/common/http_client.dart';
import 'package:pure_live/shared/common/http_header_policy.dart';
import 'package:pure_live/shared/utils/hive_pref_util.dart';
import 'package:pure_live/shared/utils/log.dart';
import 'package:pure_live/shared/utils/toast_util.dart';
import 'package:pure_live/app/bootstrap/app_navigator.dart';
import 'package:pure_live/features/remote/models/server_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:pure_live/shared/i18n/locale_helper.dart';
import 'package:pure_live/shared/dialog/backup_import_dialog.dart';

part 'tv_remote_receiver.g.dart';

/// LAN services (web remote on 8888, plus the callbacks every page binds for
/// phone pushes) live for the whole session: auto-dispose tore the server down
/// whenever the page that happened to start it was left, and an in-flight
/// start could then write `state` after disposal and crash the isolate.
@Riverpod(keepAlive: true)
class TvRemoteReceiver extends _$TvRemoteReceiver {
  Alfred? _app;
  HttpServer? _server;
  final List<WebSocket> _wsClients = [];
  static const int _maxPortRetry = 100;
  static const String _appVersion = '1.0.0';

  /// Identity the LAN protocol reports for this device, so the mobile app's
  /// device list can name it instead of showing a bare address.
  String get _deviceId => 'pure_live_tv_${Platform.localHostname}';
  String get _deviceName => 'PureLive TV (${Platform.operatingSystem})';

  /// LAN address the server is reachable at; set when it starts listening.
  String _localAddress = '';

  final Map<String, dynamic> _configCache = {
    'douyin_cookie': <String, String>{'ttwid': '', 'cookie': ''},
    'danmaku_filter': <String>[],
  };

  Function(String videoUrl)? onMovieReceived;
  Function(String streamerName)? onStreamerSearch;
  Function(String roomId)? onRoomPush;
  Function(List<String> filters)? onDanmakuFilterUpdated;

  /// Room pushes that no page claimed: the search pages bind [onRoomPush] while
  /// they are on top and unbind on dispose; the global overlay owns this slot,
  /// so a push arriving anywhere else still asks the user whether to open the
  /// room instead of vanishing.
  Function(String roomId)? onRoomPushFallback;

  /// Routes one room push to the page-bound callback, or to the global
  /// fallback when no page is listening.
  void dispatchRoomPush(String roomId) => (onRoomPush ?? onRoomPushFallback)?.call(roomId);

  @override
  FutureOr<ServerState> build() {
    ref.onDispose(stopServer);
    return ServerState(isRunning: false, serverUrl: '', port: 8888);
  }

  /// The in-flight start, so concurrent callers await the same attempt
  /// instead of racing the bind (a lost race would retry onto port+1 while
  /// every QR still prints `port`).
  Future<void>? _pendingStart;

  Future<void> startServer({int port = 8888}) async {
    // Already listening: starting again would bind a second port and leave two
    // servers racing for the same state.
    if (state.value?.isRunning == true) return;
    return _pendingStart ??= _startServer(port);
  }

  Future<void> _startServer(int port) async {
    state = const AsyncLoading();
    try {
      await _startServerWithRetry(port: port);
    } finally {
      _pendingStart = null;
    }
  }

  /// The cookie the phone asks for, by the site id the web remote uses.
  String _cookieForSite(String site) {
    final cookies = ref.read(cookieControllerProvider);
    return switch (site) {
      'bilibili' => cookies.bilibiliCookie,
      'huya' => cookies.huyaCookie,
      'douyu' => cookies.douyuCookie,
      'douyin' => cookies.douyinCookie,
      'kuaishou' => cookies.kuaishouCookie,
      'yy' => cookies.yyCookie,
      'soop' => cookies.soopCookie,
      'twitch' => cookies.twitchCookie,
      _ => '',
    };
  }

  /// Stores a cookie pushed from the phone. Returns false for a site this app
  /// has no field for.
  bool _setCookieForSite(String site, String cookie) {
    final controller = ref.read(cookieControllerProvider.notifier);
    switch (site) {
      case 'bilibili':
        controller.setBilibiliCookie(cookie);
      case 'huya':
        controller.setHuyaCookie(cookie);
      case 'douyu':
        controller.setDouyuCookie(cookie);
      case 'douyin':
        controller.setDouyinCookie(cookie);
      case 'kuaishou':
        controller.setKuaishouCookie(cookie);
      case 'yy':
        controller.setYyCookie(cookie);
      case 'soop':
        controller.setSoopCookie(cookie);
      case 'twitch':
        controller.setTwitchCookie(cookie);
      default:
        return false;
    }
    return true;
  }

  /// The phone scan page reads this cache through `GET /api/danmaku_filter`.
  /// Opening the filter panel on TV writes the current words in first, so the
  /// phone shows them straight away.
  void seedDanmakuFilters(List<String> filters) {
    _configCache['danmaku_filter'] = List<String>.from(filters);
  }

  Future<void> _startServerWithRetry({required int port, int retry = 0}) async {
    // The start spans several async gaps (IP lookup, port bind, retries); the
    // provider can be disposed (or the app torn down) in between, and every
    // `state =` below would then throw "Ref used after disposed".
    if (!ref.mounted) return;
    try {
      final ip = await _getLocalIp();
      if (!ref.mounted) return;
      if (ip == null) {
        state = AsyncValue.data(
          ServerState(
          isRunning: false,
          serverUrl: '',
          port: port,
          error: i18n('remote_no_lan_ip'),
          ),
        );
        return;
      }

      _app = Alfred();
      _setupCors();
      _registerWebSocket();
      _registerApiRoutes();
      _registerStaticRoutes();

      _server = await _app!.listen(port, '0.0.0.0');
      if (!ref.mounted) {
        // Disposed while binding: the freshly bound server must not linger.
        await _server?.close(force: true);
        _server = null;
        _app = null;
        return;
      }
      final fullUrl = 'http://$ip:$port';
      _localAddress = ip;
      _addLog('Remote service started at $fullUrl');

      state = AsyncValue.data(ServerState(isRunning: true, serverUrl: fullUrl, port: port, error: null));
    } catch (e) {
      if (!ref.mounted) return;
      if (e.toString().contains('Address already in use') && retry < _maxPortRetry) {
        _addLog('Port $port is taken, trying ${port + 1}');
        await _startServerWithRetry(port: port + 1, retry: retry + 1);
      } else {
        _addLog('Failed to start the service: $e');
        state = AsyncValue.data(
        ServerState(
        isRunning: false,
        serverUrl: '',
        port: port,
        error: i18n('remote_start_failed', args: {'error': '$e'}),
        ),
        );
      }
    }
  }

  Future<String?> _getLocalIp() async {
    try {
      // Multi-NIC boxes surface virtual adapters first (VPN/TUN, bridges,
      // emulator NAT), so "first non-loopback IPv4" used to advertise a
      // 10.x address the phone could not reach. Rank the candidates the same
      // way the LAN-sync service does and honor its manual pick, so the
      // selector on the device sync page fixes both services' QR codes.
      final candidates = <String>[];
      final interfaces = await NetworkInterface.list(type: InternetAddressType.IPv4, includeLoopback: false);
      for (final iface in interfaces) {
        for (final addr in iface.addresses) {
          final ip = addr.address;
          if (!ip.startsWith('127.') && !ip.startsWith('169.254.')) candidates.add(ip);
        }
      }
      if (candidates.isEmpty) return null;

      final manual = HivePrefUtil.getString('syncSelectedIp');
      if (manual != null && manual.isNotEmpty && candidates.contains(manual)) return manual;

      int score(String ip) {
        if (ip.startsWith('192.168.')) return 3;
        if (ip.startsWith('10.')) return 2;
        if (ip.startsWith('172.')) {
          final second = int.tryParse(ip.split('.')[1]);
          if (second != null && second >= 16 && second <= 31) return 1;
        }
        return 0;
      }

      candidates.sort((a, b) => score(b).compareTo(score(a)));
      return candidates.first;
    } catch (e) {
      _addLog('Failed to read the IP address: $e');
      return null;
    }
  }

  void _setupCors() {
    _app!.all('*', (req, res) {
      res.headers.set('Access-Control-Allow-Origin', '*');
      res.headers.set('Access-Control-Allow-Methods', 'GET, POST, OPTIONS');
      res.headers.set('Access-Control-Allow-Headers', 'Origin, Content-Type, Accept');
      if (req.method == 'OPTIONS') {
        res.statusCode = HttpStatus.ok;
        res.close();
      }
    });
  }

  void _registerWebSocket() {
    _app!.get('/ws', (req, res) async {
      final nativeReq = req;
      if (WebSocketTransformer.isUpgradeRequest(nativeReq)) {
        final socket = await WebSocketTransformer.upgrade(nativeReq);
        _wsClients.add(socket);

        socket.add(
          jsonEncode({
            'type': 'init',
            'device': Platform.operatingSystem,
            'version': _appVersion,
            'timestamp': DateTime.now().millisecondsSinceEpoch,
          }),
        );

        socket.listen(
          (msg) => _handleWsMessage(msg, socket),
          onDone: () => _wsClients.remove(socket),
          onError: (_) => _wsClients.remove(socket),
        );
      }
    });
  }

  void _registerApiRoutes() {
    _app!.get(
      '/api/status',
      (req, res) => _ok(res, data: {'device': Platform.operatingSystem, 'version': _appVersion}),
    );

    _app!.get('/api/version', (req, res) => _ok(res, data: {'version': _appVersion}));

    _app!.post('/api/movie', (req, res) async {
      final body = await req.body;
      final url = body.toString().trim();
      if (url.isEmpty) return _fail(res, msg: i18n('toolbox_empty_link'));
      _addLog('Video push received: $url');
      onMovieReceived?.call(url);
      _broadcastWs({'type': 'movie_push', 'url': url});
      return _ok(res, msg: i18n('remote_push_success'));
    });

    _app!.post('/api/search/streamer', (req, res) async {
      final body = await req.body;
      final name = body.toString().trim();
      _addLog('Anchor search received: $name');
      onStreamerSearch?.call(name);
      return _ok(res);
    });

    _app!.post('/api/search/room', (req, res) async {
      final body = await req.body;
      final roomInfo = body.toString().trim();
      _addLog('Room id push received: $roomInfo');
      dispatchRoomPush(roomInfo);
      return _ok(res);
    });

    _app!.get('/api/cookie/douyin', (req, res) {
      return _ok(res, data: _configCache['douyin_cookie']);
    });

    // Generic cookie bridge for the phone pages: the web remote reads a
    // platform's cookie and pushes an edited one back. A remote-only TV has no
    // practical way to type a cookie, so this is the only sensible input path.
    _app!.get('/api/cookie', (req, res) {
      final String site = (req.uri.queryParameters['site'] ?? '').trim().toLowerCase();
      return _ok(res, data: _cookieForSite(site));
    });

    _app!.post('/api/cookie', (req, res) async {
      final body = await req.body as Map<String, dynamic>?;
      if (body == null) return _fail(res, msg: i18n('remote_bad_request'));
      final String site = (body['site'] ?? '').toString().trim().toLowerCase();
      final String data = (body['data'] ?? '').toString();
      if (!_setCookieForSite(site, data)) {
        _addLog('Cookie push ignored for unknown site: $site');
        return _fail(res, msg: i18n('remote_bad_request'));
      }
      _addLog('Cookie updated from the phone: $site');
      _broadcastWs({'type': 'cookie_push', 'site': site});
      return _ok(res, msg: i18n('ui_saved'));
    });

    _app!.post('/api/cookie/douyin', (req, res) async {
      final body = await req.body as Map<String, dynamic>?;
      if (body == null) return _fail(res, msg: i18n('remote_bad_request'));
      final String cookie = (body['cookie'] ?? '').toString();
      _configCache['douyin_cookie'] = {'ttwid': body['ttwid'] ?? '', 'cookie': cookie};
      // The bundled Douyin phone page still posts to this legacy route. Writing
      // only the local cache meant the cookie never reached the store the site
      // implementation reads, so a scan looked successful and changed nothing.
      if (cookie.isNotEmpty) _setCookieForSite('douyin', cookie);
      _addLog('Douyin cookie updated');
      _broadcastWs({'type': 'cookie_push', 'site': 'douyin'});
      return _ok(res, msg: i18n('ui_saved'));
    });

    // Tag management bridge for the phone pages: list + add/update/delete.
    _app!.get('/api/tags', (req, res) {
      final tags = ref.read(tagManagementControllerProvider).tags;
      return _ok(
        res,
        data: [
          for (final tag in tags) {'id': tag.id, 'name': tag.name, 'description': tag.description, 'order': tag.order},
        ],
      );
    });

    _app!.post('/api/tags', (req, res) async {
      final body = await req.body as Map<String, dynamic>?;
      if (body == null) return _fail(res, msg: i18n('remote_bad_request'));
      final action = (body['action'] ?? '').toString();
      final id = (body['id'] ?? '').toString();
      final name = (body['name'] ?? '').toString();
      final description = (body['description'] ?? '').toString();
      final controller = ref.read(tagManagementControllerProvider.notifier);
      final bool ok = switch (action) {
        'add' => controller.addTag(name, description),
        'update' => id.isNotEmpty && controller.updateTag(id, name, description),
        'delete' => id.isNotEmpty && controller.deleteTagById(id),
        _ => false,
      };
      if (!ok) {
        _addLog('Tag action rejected: $action');
        return _fail(res, msg: i18n('remote_bad_request'));
      }
      _addLog('Tags updated from the phone: $action');
      _broadcastWs({'type': 'tags_updated', 'action': action});
      return _ok(res, msg: i18n('ui_saved'));
    });

    _app!.get('/api/danmaku_filter', (req, res) {
      return _ok(res, data: _configCache['danmaku_filter']);
    });

    _app!.post('/api/danmaku_filter', (req, res) async {
      final body = await req.body;
      List<String> filters;
      if (body is List) {
        filters = body.map((e) => e.toString()).toList();
      } else {
        filters = body.toString().split('\n').where((e) => e.trim().isNotEmpty).toList();
      }
      _configCache['danmaku_filter'] = filters;
      _addLog('Danmaku filter rules updated: ${filters.length} entries');
      onDanmakuFilterUpdated?.call(filters);
      return _ok(res, msg: i18n('ui_saved'));
    });

    // LAN settings sync: a phone on the same network can read this device's
    // settings or push its own, using the same packet shape as the desktop app.
    _app!.get('/api/remote-sync/status', (req, res) {
      return _ok(
        res,
        data: {
          'type': 'pure_live_sync',
          'version': 1,
          'platform': Platform.operatingSystem,
          'appVersion': _appVersion,
          // The mobile app's device list identifies a peer by these fields, so
          // they are part of the protocol rather than decoration.
          'id': _deviceId,
          'name': _deviceName,
          'ip': _localAddress,
          'port': state.value?.port ?? 0,
        },
      );
    });

    _app!.get('/api/remote-sync/settings', (req, res) {
      return _ok(res, data: ref.read(backupControllerProvider.notifier).exportAllSettings());
    });

    _app!.post('/api/remote-sync/settings', (req, res) async {
      final body = await req.body;
      final settings = body is Map && body['settings'] is Map ? body['settings'] : body;
      if (settings is! Map) return _fail(res, msg: i18n('ui_parameter_error'));

      final sections = await _askModules(settings.cast<String, dynamic>());
      if (sections == null) return _fail(res, msg: i18n('cancel'));

      try {
        await ref
            .read(backupControllerProvider.notifier)
            .restoreAllSettings(settings.cast<String, dynamic>(), sections: sections);
      } catch (error) {
        _addLog('Settings sync failed: $error', color: Colors.red);
        ToastUtil.show(i18n('remote_sync_receive_failed'));
        return _fail(res, msg: i18n('ui_import_failed_or_file_not_found'));
      }
      _addLog('Settings sync received over the LAN');
      // The phone gets the result in its own page; this TV has to say so too,
      // otherwise whoever is watching it cannot tell the push landed.
      ToastUtil.show(i18n('remote_sync_receive_success'));
      return _ok(res, msg: i18n('webdav_sync_success'));
    });

    // Compatibility with the mobile app's TV data sync row.
    //
    // That row scans this device's QR, then posts the flat TV document as a
    // *query parameter* to `/api/setSettings`. The route did not exist, so the
    // request fell through to the static handler, the phone got the web page
    // back and reported success while nothing had been applied.
    _app!.post('/api/setSettings', (req, res) async {
      final backup = ref.read(backupControllerProvider.notifier);
      final raw = req.uri.queryParameters['settings'];
      final body = await req.body;

      Map<String, dynamic>? settings;
      if (raw != null && raw.isNotEmpty) {
        try {
          final decoded = jsonDecode(raw);
          if (decoded is Map) settings = decoded.cast<String, dynamic>();
        } catch (error) {
          _addLog('Sync payload could not be read: $error', color: Colors.red);
        }
      }
      if (settings == null && body is Map) {
        final nested = body['settings'];
        settings = nested is Map ? nested.cast<String, dynamic>() : body.cast<String, dynamic>();
      }
      if (settings == null) return _fail(res, msg: i18n('ui_parameter_error'));

      // The phone's document is flat (danmaku, favorites, history, cookies,
      // IPTV). Its modules are chosen the same way as any other import's, so the
      // danmaku and IPTV parts it carries are no longer silently dropped — they
      // start unticked instead, and the viewer decides.
      final sections = await _askModules(settings);
      if (sections == null) return _fail(res, msg: i18n('cancel'));

      try {
        await backup.restoreAllSettings(settings, sections: sections);
      } catch (error) {
        _addLog('Phone sync failed: $error', color: Colors.red);
        ToastUtil.show(i18n('remote_sync_receive_failed'));
        return _fail(res, msg: i18n('ui_import_failed_or_file_not_found'));
      }
      _addLog('Settings received from the phone (setSettings)');
      ToastUtil.show(i18n('remote_sync_receive_success'));
      return _ok(res, data: true);
    });

    // proxy — the web remote had no route for it at all, so a phone could not
    // read or set the proxy the app actually uses.
    _app!.get('/api/proxy', (req, res) {
      return _ok(res, data: ref.read(proxySettingsControllerProvider).toJson());
    });

    _app!.post('/api/proxy', (req, res) async {
      final body = await req.body;
      if (body is! Map) return _fail(res, msg: i18n('ui_parameter_error'));
      try {
        final model = ProxySettingsModel.fromJson(Map<String, dynamic>.from(body));
        ref.read(proxySettingsControllerProvider.notifier).updateSettings(model);
        _addLog('Proxy settings updated from the phone');
        return _ok(res, msg: i18n('ui_saved'));
      } catch (error) {
        _addLog('Proxy update failed: $error', color: Colors.red);
        return _fail(res, msg: i18n('ui_parameter_error'));
      }
    });

    // IPTV source + headers. The phone sends a playlist URL or an uploaded
    // playlist body plus the headers its operator requires; the headers are
    // written onto the imported channels (`#EXTHTTP:`), exactly like the
    // LAN-sync channel does. The headers also arrive as separate
    // userAgent/referer/cookie fields — the web page's split inputs.
    _app!.post('/api/iptv', (req, res) async {
      final body = await req.body;
      if (body is! Map) return _fail(res, msg: i18n('ui_parameter_error'));
      final String url = (body['url'] ?? body['link'] ?? '').toString().trim();
      final String name = (body['name'] ?? '').toString().trim();
      final String content = (body['content'] ?? '').toString();
      final headers = _iptvHeadersFromBody(body);
      final hasContent = content.trim().startsWith('#EXTM3U') || content.contains(',#genre#');
      if (!hasContent && !url.startsWith('http')) return _fail(res, msg: i18n('ui_parameter_error'));
      try {
        final playlist = hasContent ? content : await HttpClient.instance.getText(url, header: HttpClient.iptvHeaders(headers));
        final dir = await getTemporaryDirectory();
        final file = File(
          '${dir.path}${Platform.pathSeparator}iptv_remote_${DateTime.now().millisecondsSinceEpoch}.m3u',
        );
        await file.writeAsString(HttpHeaderPolicy.mergeIntoM3u(playlist, headers));
        final ok = await IptvImportManager().importIptvFile(
          file: file,
          providerName: name.isNotEmpty ? name : 'remote_${DateTime.now().millisecondsSinceEpoch}',
          url: hasContent ? '' : url,
          forceUpdate: true,
          showTips: false,
        );
        await file.delete();
        _addLog(ok ? 'IPTV source imported from the phone' : 'IPTV import failed', color: ok ? Colors.blue : Colors.red);
        return ok ? _ok(res, msg: i18n('ui_saved')) : _fail(res, msg: i18n('ui_import_failed_or_file_not_found'));
      } catch (error) {
        _addLog('IPTV import failed: $error', color: Colors.red);
        return _fail(res, msg: i18n('ui_import_failed_or_file_not_found'));
      }
    });

    // The global IPTV request headers, so the phone page can prefill and edit
    // the same UA/Referer/Cookie the TV itself uses.
    _app!.get('/api/iptv/headers', (req, res) {
      final settings = ref.read(iptvSettingsControllerProvider);
      return _ok(res, data: {
        'userAgent': settings.customIptvUserAgent,
        'referer': settings.customIptvReferer,
        'cookie': settings.customIptvCookie,
      });
    });

    _app!.post('/api/iptv/headers', (req, res) async {
      final body = await req.body;
      if (body is! Map) return _fail(res, msg: i18n('ui_parameter_error'));
      try {
        final settings = ref.read(iptvSettingsControllerProvider);
        ref.read(iptvSettingsControllerProvider.notifier).updateSettings(
          settings.copyWith(
            customIptvUserAgent: (body['userAgent'] ?? '').toString().trim(),
            customIptvReferer: (body['referer'] ?? '').toString().trim(),
            customIptvCookie: (body['cookie'] ?? '').toString().trim(),
          ),
        );
        _addLog('IPTV request headers updated from the phone');
        return _ok(res, msg: i18n('ui_saved'));
      } catch (error) {
        _addLog('IPTV header update failed: $error', color: Colors.red);
        return _fail(res, msg: i18n('ui_parameter_error'));
      }
    });

    _app!.get('/api/backup/export', (req, res) {
      // The document the device sync and the local backups use: the sectioned
      // backup with its `platformIsTv` marker, written under the backup file name.
      // It used to be wrapped in an envelope of its own, which only this page's
      // import knew how to open — a file exported here could not be restored from
      // the backup list, and re-importing it here classified it as a foreign one.
      final settings = ref.read(backupControllerProvider.notifier).exportAllSettings();
      final fileName = BackupController.backupFileName(DateTime.now());
      res.headers.set('Content-Disposition', 'attachment; filename=$fileName');
      res.headers.contentType = ContentType('text', 'plain', charset: 'utf-8');
      _addLog('Exported a configuration backup');
      return settings;
    });

    _app!.post('/api/backup/import', (req, res) async {
      final body = await req.body as Map<String, dynamic>?;
      if (body == null) return _fail(res, msg: i18n('remote_bad_backup'));

      // The page posts back what it exported. Older pages wrapped the document in
      // an envelope (`config`); a fresh export is the document itself.
      final nested = body['config'];
      final document = nested is Map ? Map<String, dynamic>.from(nested) : body;

      final sections = await _askModules(document);
      if (sections == null) return _fail(res, msg: i18n('cancel'));

      // Importing used to write the payload into the local cache, which nothing reads:
      // the page said success and the TV kept its old settings.
      try {
        await ref
            .read(backupControllerProvider.notifier)
            .restoreAllSettings(document, sections: sections);
      } catch (error) {
        _addLog('Backup import failed: $error', color: Colors.red);
        return _fail(res, msg: i18n('ui_import_failed_or_file_not_found'));
      }
      _addLog('Configuration backup imported');
      return _ok(res, msg: i18n('ui_imported'));
    });

    _app!.get('/api/log/stream', (req, res) {
      return _ok(res, data: Log.formattedLogs.reversed.toList());
    });

    _app!.get('/api/log/download', (req, res) {
      final content = Log.formattedLogs.join('\n');
      final fileName = 'pure_live_log_${DateTime.now().millisecondsSinceEpoch}.txt';
      res.headers.set('Content-Disposition', 'attachment; filename=$fileName');
      res.headers.contentType = ContentType('text', 'plain', charset: 'utf-8');
      return content;
    });

    _app!.post('/api/log/clear', (req, res) {
      Log.clearAllDebugLogs();
      _addLog('Log cleared', color: Colors.orange);
      return _ok(res, msg: i18n('remote_clear_success'));
    });
  }

  void _registerStaticRoutes() {
    _app!.get('*', (req, res) async {
      final path = req.uri.path;
      final assetSuffixes = {'.js', '.css', '.png', '.svg', '.json', '.ico', '.txt'};
      final isStaticFile = assetSuffixes.any((suf) => path.endsWith(suf));

      if (isStaticFile) {
        final assetPath = path.substring(1);
        final data = await _loadAsset(assetPath);
        if (data == null) {
          res.statusCode = HttpStatus.notFound;
          return 'Resource Not Found';
        }
        _setMimeType(assetPath, res);
        return data;
      } else {
        _addLog('Web route requested: $path');
        final indexHtml = await _loadAsset('index.html');
        if (indexHtml == null) {
          res.statusCode = HttpStatus.notFound;
          return 'Web Remote Frontend Missing';
        }
        res.headers.contentType = ContentType('text', 'html', charset: 'utf-8');
        return indexHtml;
      }
    });
  }

  Future<Uint8List?> _loadAsset(String path) async {
    try {
      final byteData = await rootBundle.load('assets/web_remote/$path');
      return byteData.buffer.asUint8List();
    } catch (e) {
      return null;
    }
  }

  void _setMimeType(String path, HttpResponse res) {
    if (path.endsWith('.js')) {
      res.headers.contentType = ContentType('application', 'javascript', charset: 'utf-8');
    } else if (path.endsWith('.css')) {
      res.headers.contentType = ContentType('text', 'css', charset: 'utf-8');
    } else if (path.endsWith('.png')) {
      res.headers.contentType = ContentType('image', 'png');
    } else if (path.endsWith('.svg')) {
      res.headers.contentType = ContentType('image', 'svg+xml', charset: 'utf-8');
    } else if (path.endsWith('.json')) {
      res.headers.contentType = ContentType('application', 'json', charset: 'utf-8');
    } else if (path.endsWith('.html')) {
      res.headers.contentType = ContentType('text', 'html', charset: 'utf-8');
    }
  }

  /// Asks the viewer which modules an inbound document should apply.
  ///
  /// Null when the dialog was cancelled — the caller then imports nothing. With
  /// no UI to ask (a request arriving before the first frame) the document's own
  /// defaults decide: a TV document restores everything it carries, anything else
  /// only the user-data modules.
  Future<Set<String>?> _askModules(Map<String, dynamic> document) async {
    final BuildContext? context = appNavigatorContext;
    final List<String> modules = BackupController.importableSections(document);
    final Set<String> defaults = BackupController.defaultSections(document);

    if (context == null) return defaults;

    return showBackupImportPicker(
      context,
      modules: modules,
      defaults: defaults,
      sourceIsTv: BackupController.sourceIsTv(document),
    );
  }

  void _addLog(String msg, {Color color = Colors.blue}) {
    Log.addDebugLog(msg, color);
    final time = DateTime.now().toString().substring(0, 19);
    _broadcastWs({'type': 'log', 'msg': msg, 'time': time});
  }

  Map<String, dynamic> _ok(HttpResponse res, {String msg = 'ok', dynamic data}) {
    res.statusCode = HttpStatus.ok;
    return {'code': 200, 'msg': msg, 'data': data};
  }

  /// The IPTV request headers of a push body: either the `headers` map or the
  /// web page's separate `userAgent`/`referer`/`cookie` fields, with the map
  /// entries winning when both are present.
  Map<String, String> _iptvHeadersFromBody(Map body) {
    final rawHeaders = body['headers'] ?? body['httpHeaders'];
    final headers = rawHeaders is Map
        ? HttpHeaderPolicy.normalize(rawHeaders)
        : <String, String>{};
    final separate = <String, String>{
      if ((body['userAgent'] ?? '').toString().trim().isNotEmpty)
        'user-agent': body['userAgent'].toString().trim(),
      if ((body['referer'] ?? '').toString().trim().isNotEmpty) 'referer': body['referer'].toString().trim(),
      if ((body['cookie'] ?? '').toString().trim().isNotEmpty) 'cookie': body['cookie'].toString().trim(),
    };
    return HttpHeaderPolicy.normalize({...separate, ...headers});
  }

  Map<String, dynamic> _fail(HttpResponse res, {String? msg, int code = 400}) {
    msg ??= i18n('record_failed');
    res.statusCode = HttpStatus.badRequest;
    return {'code': code, 'msg': msg, 'data': null};
  }

  void _handleWsMessage(dynamic message, WebSocket sender) {
    try {
      final data = jsonDecode(message.toString());
      debugPrint('WS message: $data');
    } catch (e) {
      debugPrint('Failed to parse a WS message: $e');
    }
  }

  void _broadcastWs(Map<String, dynamic> data) {
    final payload = jsonEncode(data);
    for (var client in _wsClients) {
      if (client.readyState == WebSocket.open) {
        client.add(payload);
      }
    }
  }

  Future<void> stopServer() async {
    for (var client in _wsClients) {
      await client.close();
    }
    _wsClients.clear();

    if (_server != null) {
      await _server!.close(force: true);
      _server = null;
      _app = null;
      _addLog('Service stopped');
    }
  }
}

