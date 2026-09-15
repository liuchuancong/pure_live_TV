import 'dart:async';

/// Global event.
class EventBus {
  static EventBus? _instance;

  static EventBus get instance {
    _instance ??= EventBus();
    return _instance!;
  }

  final Map<String, StreamController> _streams = {};

  /// Fires the event.
  void emit<T>(String name, T data) {
    if (!_streams.containsKey(name)) {
      _streams.addAll({name: StreamController.broadcast()});
    }

    _streams[name]!.add(data);
  }

  /// Subscribes to the event.
  StreamSubscription<dynamic> listen(String name, Function(dynamic)? onData) {
    if (!_streams.containsKey(name)) {
      _streams.addAll({name: StreamController.broadcast()});
    }
    return _streams[name]!.stream.listen(onData);
  }
}
