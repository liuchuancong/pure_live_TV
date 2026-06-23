import 'dart:async';
import 'package:pure_live/core/models/index.dart';
import 'package:pure_live/utils/web_socket_util.dart';
import 'package:pure_live/core/sites/interface/live_danmaku.dart';

class EmptyDanmaku implements LiveDanmaku {
  @override
  int heartbeatTime = 60 * 1000;
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

  @override
  Function(LiveMessage msg)? onMessage;
  @override
  Function(String msg)? onClose;
  @override
  Function()? onReady;

  WebScoketUtils? webScoketUtils;

  @override
  Future start(dynamic args) async {}

  void joinRoom() {}

  @override
  void heartbeat() {}

  @override
  Future stop() async {
    onMessage = null;
    onClose = null;
  }
}
