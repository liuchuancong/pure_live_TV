import 'remote_sync_device.dart';
import 'remote_sync_protocol.dart';

/// Everything the kit reports back to the host app, as a broadcast stream.
sealed class RemoteSyncEvent {
  const RemoteSyncEvent();
}

/// A text push from the phone: a streamer/room search or a video link.
class RemoteTextInputEvent extends RemoteSyncEvent {
  const RemoteTextInputEvent({required this.kind, required this.text});

  /// `streamer`, `room` or `movie`.
  final String kind;
  final String text;
}

/// A per-channel push (or the result of a channel read the host served).
class RemoteChannelEvent extends RemoteSyncEvent {
  const RemoteChannelEvent({required this.channel, required this.data});

  /// One of [RemoteSyncProtocol.channels] — `cookie`, `danmaku_filter`,
  /// `tags`, `proxy` or `iptv`.
  final String channel;
  final Object? data;
}

/// A peer appeared, updated or disappeared on the LAN.
class RemoteDevicesChangedEvent extends RemoteSyncEvent {
  const RemoteDevicesChangedEvent({required this.devices});

  /// Unmodifiable snapshot of the current device list.
  final List<RemoteSyncDevice> devices;
}

/// A log line, for the host's debug log surface.
class RemoteLogEvent extends RemoteSyncEvent {
  const RemoteLogEvent({required this.message});

  final String message;
}
