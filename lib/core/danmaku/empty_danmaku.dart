import 'dart:async';
import 'package:pure_live/common/models/live_message.dart';
import 'package:pure_live/core/common/web_socket_util.dart';
import 'package:pure_live/core/interface/live_danmaku.dart';
// ignore_for_file: no_leading_underscores_for_local_identifiers



class EmptyDanmaku implements LiveDanmaku {
  @override
  int heartbeatTime = 60 * 1000;

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
