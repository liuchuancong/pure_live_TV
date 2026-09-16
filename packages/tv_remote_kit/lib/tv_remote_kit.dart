/// LAN remote-sync kit for the PureLive TV app.
///
/// One service does everything the phone side needs to reach this device:
/// a bonsoir mDNS broadcast so peers can discover it, a bonsoir discovery so
/// this device can list peers (设备同步), a small HTTP server that accepts
/// settings sync and per-channel pushes (search text, cookies, tags, proxy,
/// IPTV links, danmaku filters), and the `purelive://` QR payload that ties
/// the address together for scan-based pairing.
///
/// The kit is storage-free: the host supplies its persistent [TvRemoteKit.deviceId]
/// and a [RemoteSyncDelegate] that reads/writes the actual channels.
library;

export 'src/remote_sync_device.dart';
export 'src/remote_sync_events.dart';
export 'src/remote_sync_protocol.dart';
export 'src/tv_remote_kit_service.dart';
