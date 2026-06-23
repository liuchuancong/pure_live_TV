import 'package:meta/meta.dart';
import 'package:pure_live/core/models/live_message/live_message_model.dart';

abstract class LiveDanmaku {
  Function(LiveMessage msg)? onMessage;
  Function(String msg)? onClose;
  Function()? onReady;

  int heartbeatTime = 0;

  bool _connected = false;

  bool get isConnected => _connected;

  @protected
  void markConnected() {
    _connected = true;
  }

  @protected
  void markDisconnected() {
    _connected = false;
  }

  void heartbeat() {}

  Future start(dynamic args) {
    return Future.value();
  }

  Future stop() {
    markDisconnected();
    return Future.value();
  }
}
