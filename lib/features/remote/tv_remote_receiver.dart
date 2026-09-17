import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:alfred/alfred.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pure_live/exports/package_export.dart';
import 'package:pure_live/features/iptv/services/iptv_import_manager.dart';
import 'package:pure_live/services/backup/backup_controller.dart';
import 'package:pure_live/services/cookie_manager/cookie_controller.dart';
import 'package:pure_live/services/proxy_settings/proxy_settings_controller.dart';
import 'package:pure_live/services/proxy_settings/proxy_settings_model.dart';
import 'package:pure_live/services/webdav/webdav_config.dart';
import 'package:pure_live/services/webdav/webdav_controller.dart';
import 'package:pure_live/shared/common/http_client.dart';
import 'package:pure_live/shared/common/http_header_policy.dart';
import 'package:pure_live/shared/utils/log.dart';
import 'package:pure_live/features/remote/models/server_state.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:pure_live/shared/i18n/locale_helper.dart';

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
    'webdav_list': <Map<String, dynamic>>[],
  };

  Function(String videoUrl)? onMovieReceived;
  Function(String streamerName)? onStreamerSearch;
  Function(String roomId)? onRoomPush;
  Function(List<String> filters)? onDanmakuFilterUpdated;

  @override
  FutureOr<ServerState> build() {
    ref.onDispose(stopServer);
    return ServerState(isRunning: false, serverUrl: '', port: 8888);
  }

  Future<void> startServer({int port = 8888}) async {
    // Already listening: starting again would bind a second port and leave two
    // servers racing for the same state.
    if (state.value?.isRunning == true) return;
    state = const AsyncLoading();
    await _startServerWithRetry(port: port);
  }

  /// The cookie the phone asks for, by the site id the web remote uses.
  String _cookieForSite(String site) {
    final cookies = ref.read(cookieControllerProvider);
    return switch (site) {
      'bilibili' => cookies.bilibiliCookie,
      'huya' => cookies.huyaCookie,
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

  /// Seeds the danmaku filter cache.
  ///
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
      final interfaces = await NetworkInterface.list(type: InternetAddressType.IPv4, includeLoopback: false);
      for (final iface in interfaces) {
        for (final addr in iface.addresses) {
          if (!addr.address.startsWith('127.') && !addr.address.startsWith('169.254.')) {
            return addr.address;
          }
        }
      }
      return null;
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
      onRoomPush?.call(roomInfo);
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
      try {
        await ref.read(backupControllerProvider.notifier).restoreAllSettings(settings.cast<String, dynamic>());
      } catch (error) {
        _addLog('Settings sync failed: $error', color: Colors.red);
        return _fail(res, msg: i18n('ui_import_failed_or_file_not_found'));
      }
      _addLog('Settings sync received over the LAN');
      return _ok(res, msg: i18n('webdav_sync_success'));
    });

    // Compatibility with the mobile app's 同步TV数据 row.
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

      try {
        await backup.restoreAllSettings(settings);
      } catch (_) {
        // The flat document (danmaku, favorites, history, cookies, IPTV) is not
        // a sectioned backup; hand each section the whole map so every parser
        // picks its own keys out of it.
        try {
          await backup.restoreAllSettings(<String, dynamic>{
            'backupVersion': 1,
            'danmaku': settings,
            'favorite': settings,
            'history': settings,
            'cookie': settings,
            'iptv': settings,
          });
        } catch (error) {
          _addLog('Phone sync failed: $error', color: Colors.red);
          return _fail(res, msg: i18n('ui_import_failed_or_file_not_found'));
        }
      }
      _addLog('Settings received from the phone (setSettings)');
      return _ok(res, data: true);
    });

    _app!.get('/api/webdav/list', (req, res) {
      // Real configs, not the in-memory cache: the phone page listed (and saved)
      // entries the TV never used, so a "saved" WebDAV account simply was not there.
      final controller = ref.read(webDavControllerProvider);
      return _ok(res, data: <Map<String, dynamic>>[
        for (final config in controller.webDavConfigs) config.toJson(),
      ]);
    });

    _app!.post('/api/webdav/save', (req, res) async {
      final body = await req.body;
      final Map<String, dynamic> payload = body is Map
          ? Map<String, dynamic>.from(body)
          : <String, dynamic>{'address': body.toString()};
      try {
        final config = WebDAVConfig.fromJson(payload);
        if (config.address.trim().isEmpty) return _fail(res, msg: i18n('ui_parameter_error'));
        final controller = ref.read(webDavControllerProvider.notifier);
        final bool ok = controller.isWebDavConfigExist(config.name)
            ? controller.updateWebDavConfig(config)
            : controller.addWebDavConfig(config);
        if (!ok) return _fail(res, msg: i18n('ui_save_failed'));
        _addLog('WebDAV settings updated from the phone');
        return _ok(res, msg: i18n('ui_saved'));
      } catch (error) {
        _addLog('WebDAV save failed: $error', color: Colors.red);
        return _fail(res, msg: i18n('ui_parameter_error'));
      }
    });

    // 网络代理 — the web remote had no route for it at all, so a phone could not
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

    // IPTV 直播源 + 请求头. The phone sends a playlist address and the headers its
    // operator requires; the headers are written onto the imported channels
    // (`#EXTHTTP:`), exactly like the LAN-sync channel does.
    _app!.post('/api/iptv', (req, res) async {
      final body = await req.body;
      if (body is! Map) return _fail(res, msg: i18n('ui_parameter_error'));
      final String url = (body['url'] ?? body['link'] ?? '').toString().trim();
      final String name = (body['name'] ?? '').toString().trim();
      final rawHeaders = body['headers'] ?? body['httpHeaders'];
      final headers = rawHeaders is Map ? HttpHeaderPolicy.normalize(rawHeaders) : const <String, String>{};
      if (!url.startsWith('http')) return _fail(res, msg: i18n('ui_parameter_error'));
      try {
        final content = await HttpClient.instance.getText(
          url,
          header: <String, String>{'user-agent': HttpClient.iptvUserAgent, ...headers},
        );
        final dir = await getTemporaryDirectory();
        final file = File(
          '${dir.path}${Platform.pathSeparator}iptv_remote_${DateTime.now().millisecondsSinceEpoch}.m3u',
        );
        await file.writeAsString(HttpHeaderPolicy.mergeIntoM3u(content, headers));
        final ok = await IptvImportManager().importIptvFile(
          file: file,
          providerName: name.isNotEmpty ? name : 'remote_${DateTime.now().millisecondsSinceEpoch}',
          url: url,
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

    _app!.get('/api/backup/export', (req, res) {
      final settings = ref.read(backupControllerProvider.notifier).exportAllSettings();
      final backup = {'version': _appVersion, 'export_time': DateTime.now().toIso8601String(), 'config': settings};
      final fileName = 'pure_live_backup_${DateTime.now().millisecondsSinceEpoch}.json';
      res.headers.set('Content-Disposition', 'attachment; filename=$fileName');
      res.headers.contentType = ContentType('application', 'json', charset: 'utf-8');
      _addLog('Exported a configuration backup');
      return backup;
    });

    _app!.post('/api/backup/import', (req, res) async {
      final body = await req.body as Map<String, dynamic>?;
      if (body == null || body['config'] == null) {
        return _fail(res, msg: i18n('remote_bad_backup'));
      }
      // Importing used to write the payload into the local cache, which nothing reads:
      // the page said success and the TV kept its old settings.
      try {
        await ref
            .read(backupControllerProvider.notifier)
            .restoreAllSettings(Map<String, dynamic>.from(body['config'] as Map));
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

  void _addLog(String msg, {Color color = Colors.blue}) {
    Log.addDebugLog(msg, color);
    final time = DateTime.now().toString().substring(0, 19);
    _broadcastWs({'type': 'log', 'msg': msg, 'time': time});
  }

  Map<String, dynamic> _ok(HttpResponse res, {String msg = 'ok', dynamic data}) {
    res.statusCode = HttpStatus.ok;
    return {'code': 200, 'msg': msg, 'data': data};
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

