import 'dart:io';
import 'dart:async';
import 'dart:convert';
import 'package:alfred/alfred.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/foundation.dart';
import 'package:pure_live/utils/log.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:pure_live/core/utils/remote_receiver/model.dart/server_state.dart';

part 'tv_remote_receiver.g.dart';

@riverpod
class TvRemoteReceiver extends _$TvRemoteReceiver {
  Alfred? _app;
  HttpServer? _server;
  final List<WebSocket> _wsClients = [];
  static const int _maxPortRetry = 100;
  static const String _appVersion = '1.0.0';

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
    state = const AsyncLoading();
    await _startServerWithRetry(port: port);
  }

  Future<void> _startServerWithRetry({required int port, int retry = 0}) async {
    try {
      final ip = await _getLocalIp();
      if (ip == null) {
        state = AsyncValue.data(
          ServerState(isRunning: false, serverUrl: '', port: port, error: '未找到可用局域网IP，请检查Wi-Fi连接'),
        );
        return;
      }

      _app = Alfred();
      _setupCors();
      _registerWebSocket();
      _registerApiRoutes();
      _registerStaticRoutes();

      _server = await _app!.listen(port, '0.0.0.0');
      final fullUrl = 'http://$ip:$port';
      _addLog('遥控服务启动成功，访问地址: $fullUrl');

      state = AsyncValue.data(ServerState(isRunning: true, serverUrl: fullUrl, port: port, error: null));
    } catch (e) {
      if (e.toString().contains('Address already in use') && retry < _maxPortRetry) {
        _addLog('端口 $port 被占用，尝试端口 ${port + 1}');
        await _startServerWithRetry(port: port + 1, retry: retry + 1);
      } else {
        _addLog('服务启动失败: $e');
        state = AsyncValue.data(ServerState(isRunning: false, serverUrl: '', port: port, error: '启动异常: $e'));
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
      _addLog('获取IP失败: $e');
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
      if (url.isEmpty) return _fail(res, msg: '链接不能为空');
      _addLog('收到视频推送: $url');
      onMovieReceived?.call(url);
      _broadcastWs({'type': 'movie_push', 'url': url});
      return _ok(res, msg: '推送成功');
    });

    _app!.post('/api/search/streamer', (req, res) async {
      final body = await req.body;
      final name = body.toString().trim();
      _addLog('收到主播搜索: $name');
      onStreamerSearch?.call(name);
      return _ok(res);
    });

    _app!.post('/api/search/room', (req, res) async {
      final body = await req.body;
      final roomInfo = body.toString().trim();
      _addLog('收到房间号推送: $roomInfo');
      onRoomPush?.call(roomInfo);
      return _ok(res);
    });

    _app!.get('/api/cookie/douyin', (req, res) {
      return _ok(res, data: _configCache['douyin_cookie']);
    });

    _app!.post('/api/cookie/douyin', (req, res) async {
      final body = await req.body as Map<String, dynamic>?;
      if (body == null) return _fail(res, msg: '参数错误');
      _configCache['douyin_cookie'] = {'ttwid': body['ttwid'] ?? '', 'cookie': body['cookie'] ?? ''};
      _addLog('抖音Cookie已更新');
      return _ok(res, msg: '保存成功');
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
      _addLog('弹幕过滤规则已更新，共 ${filters.length} 条');
      onDanmakuFilterUpdated?.call(filters);
      return _ok(res, msg: '保存成功');
    });

    _app!.get('/api/webdav/list', (req, res) {
      return _ok(res, data: _configCache['webdav_list']);
    });

    _app!.post('/api/webdav/save', (req, res) async {
      final body = await req.body;
      _configCache['webdav_list'] = body;
      _addLog('WebDAV配置已更新');
      return _ok(res, msg: '保存成功');
    });

    _app!.get('/api/backup/export', (req, res) {
      final backup = {'version': _appVersion, 'export_time': DateTime.now().toIso8601String(), 'config': _configCache};
      final fileName = 'pure_live_backup_${DateTime.now().millisecondsSinceEpoch}.json';
      res.headers.set('Content-Disposition', 'attachment; filename=$fileName');
      res.headers.contentType = ContentType('application', 'json', charset: 'utf-8');
      _addLog('导出配置备份');
      return backup;
    });

    _app!.post('/api/backup/import', (req, res) async {
      final body = await req.body as Map<String, dynamic>?;
      if (body == null || body['config'] == null) return _fail(res, msg: '备份文件格式错误');
      _configCache.addAll(body['config']);
      _addLog('导入配置备份成功');
      return _ok(res, msg: '导入成功');
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
      _addLog('日志已清空', color: Colors.orange);
      return _ok(res, msg: '清空成功');
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
        _addLog('访问前端页面路由: $path');
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

  Map<String, dynamic> _fail(HttpResponse res, {String msg = '失败', int code = 400}) {
    res.statusCode = HttpStatus.badRequest;
    return {'code': code, 'msg': msg, 'data': null};
  }

  void _handleWsMessage(dynamic message, WebSocket sender) {
    try {
      final data = jsonDecode(message.toString());
      debugPrint('WS消息: $data');
    } catch (e) {
      debugPrint('WS消息解析失败: $e');
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
      _addLog('服务已停止');
    }
  }
}
