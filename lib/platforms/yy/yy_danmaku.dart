import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:pure_live/shared/utils/index.dart';
import 'package:uuid/uuid.dart';
import 'package:pure_live/shared/contracts/live_danmaku.dart';
import 'package:pure_live/shared/models/index.dart';
import 'yy_protocol.dart';
import 'yy_web_socket_channel.dart';
import 'package:pure_live/shared/i18n/locale_helper.dart';

class YyDanmakuArgs {
  final int topSid;
  final int subSid;

  YyDanmakuArgs({required this.topSid, required this.subSid});

  @override
  String toString() {
    return json.encode({'topSid': topSid, 'subSid': subSid});
  }
}

class YyDanmaku implements LiveDanmaku {
  @override
  int heartbeatTime = 5 * 1000;

  @override
  Function(String msg)? onReconnect;

  @override
  Function(String msg)? onClose;

  @override
  Function(LiveMessage msg)? onMessage;

  @override
  Function()? onReady;

  WebSocketUtils? webScoketUtils;

  bool _connected = false;

  @override
  bool get isConnected => _connected;

  @override
  void markConnected() {
    _connected = true;
  }

  @override
  void markDisconnected() {
    _connected = false;
  }

  final String uuid = const Uuid().v4();

  late YyDanmakuArgs danmakuArgs;
  YyProtocolSession? _protocol;
  Timer? _handshakeTimer;
  int _generation = 0;
  String _lastSocketFailure = '';

  String get serverUrl => buildYyH5ServiceWebSocketUrl(uuid);

  @override
  Future<void> start(dynamic args) async {
    final generation = ++_generation;
    _handshakeTimer?.cancel();
    await webScoketUtils?.close();
    webScoketUtils = null;
    if (generation != _generation) return;

    danmakuArgs = args as YyDanmakuArgs;
    markDisconnected();
    _lastSocketFailure = '';
    _protocol = YyProtocolSession(topSid: danmakuArgs.topSid, subSid: danmakuArgs.subSid, uuid: uuid);

    final headers = {
      'User-Agent':
          'Mozilla/5.0 (Windows NT 10.0; Win64; x64) '
          'AppleWebKit/537.36 (KHTML, like Gecko) '
          'Chrome/151.0.0.0 Safari/537.36',
      'Origin': 'https://www.yy.com',
    };
    webScoketUtils = WebSocketUtils(
      url: serverUrl,
      heartBeatTime: heartbeatTime,
      headers: headers,
      connector: connectYyWebSocket,
      inactivityTimeout: const Duration(seconds: 45),
      onMessage: (data) {
        if (generation != _generation) return;
        _decodeMessage(data);
      },
      onReady: () {
        if (generation != _generation) return;
        _beginProtocolHandshake(generation);
      },
      onHeartBeat: () {
        if (generation != _generation) return;
        heartbeat();
      },
      onReconnect: () {
        if (generation != _generation) return;
        _handshakeTimer?.cancel();
        markDisconnected();
        final detail = _lastSocketFailure.isEmpty ? '' : '（${_compactFailure(_lastSocketFailure)}）';
        onReconnect?.call('${i18n('danmaku_reconnecting')}$detail');
      },
      onFailure: (message) {
        if (generation != _generation) return;
        _lastSocketFailure = message;
        CoreLog.error('YY WebSocket：$message');
      },
      onClose: (error) {
        if (generation != _generation) return;
        _handshakeTimer?.cancel();
        markDisconnected();
        onClose?.call('${i18n('danmaku_connect_failed')}: $error');
      },
    );

    await webScoketUtils?.connect();
  }

  String _compactFailure(String message) {
    final oneLine = message.replaceAll(RegExp(r'\s+'), ' ').trim();
    return oneLine.length <= 120 ? oneLine : '${oneLine.substring(0, 117)}...';
  }

  void _beginProtocolHandshake(int generation) {
    final protocol = _protocol;
    if (protocol == null) return;
    markDisconnected();
    webScoketUtils?.sendMessage(protocol.beginHandshake());
    _handshakeTimer?.cancel();
    _handshakeTimer = Timer(const Duration(seconds: 15), () {
      if (generation != _generation || isConnected) return;
      CoreLog.error('YY danmaku handshake timed out, preparing to reconnect');
      onReconnect?.call(i18n('danmaku_connect_timeout'));
      webScoketUtils?.reconnect();
    });
  }

  void _decodeMessage(dynamic data) {
    final bytes = switch (data) {
      Uint8List value => value,
      ByteBuffer value => value.asUint8List(),
      List<int> value => Uint8List.fromList(value),
      _ => null,
    };
    if (bytes == null) {
      CoreLog.error('YY received an unknown WebSocket data type: ${data.runtimeType}');
      return;
    }

    final protocol = _protocol;
    if (protocol == null) return;
    final batch = protocol.consume(bytes);
    for (final warning in batch.warnings) {
      CoreLog.error(warning);
    }
    for (final packet in batch.outbound) {
      webScoketUtils?.sendMessage(packet);
    }
    if (batch.becameReady) {
      _handshakeTimer?.cancel();
      markConnected();
      onReady?.call();
    }
    for (final chat in batch.chats) {
      onMessage?.call(
        LiveMessage(
          type: LiveMessageType.chat,
          message: chat.message,
          userName: chat.userName,
          color: LiveMessageColor.white,
        ),
      );
    }
    final failure = batch.failure;
    if (failure != null) {
      _handshakeTimer?.cancel();
      markDisconnected();
      CoreLog.error(failure);
      onReconnect?.call('$failure, ${i18n('danmaku_reconnecting')}');
      webScoketUtils?.reconnect();
    }
  }

  @override
  void heartbeat() {
    final packet = _protocol?.buildHeartbeat();
    if (packet != null) webScoketUtils?.sendMessage(packet);
  }

  @override
  Future<void> stop() async {
    _generation++;
    _handshakeTimer?.cancel();
    _handshakeTimer = null;
    markDisconnected();
    _protocol = null;
    onMessage = null;
    onReconnect = null;
    onClose = null;
    onReady = null;
    await webScoketUtils?.close();
    webScoketUtils = null;
  }
}
