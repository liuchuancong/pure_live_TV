import 'dart:async';

/// 全局事件
class EventBus {
  static EventBus? _instance;

  static EventBus get instance {
    _instance ??= EventBus();
    return _instance!;
  }

  final Map<String, StreamController> _streams = {};

  /// 触发事件
  void emit<T>(String name, T data) {
    if (!_streams.containsKey(name)) {
      _streams.addAll({name: StreamController.broadcast()});
    }
    _streams[name]!.add(data);
  }

  /// 监听事件
  StreamSubscription<dynamic> listen(String name, Function(dynamic)? onData) {
    if (!_streams.containsKey(name)) {
      _streams.addAll({name: StreamController.broadcast()});
    }
    return _streams[name]!.stream.listen(onData);
  }
}
