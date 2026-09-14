import 'package:bonsoir/bonsoir.dart';
import 'package:pure_live/features/sync/remote_sync_protocol.dart';

/// 局域网内一台可同步的 PureLive 设备（来自 Bonsoir 广播）。
class RemoteSyncDevice {
  const RemoteSyncDevice({
    required this.id,
    required this.name,
    required this.platform,
    required this.version,
    required this.ip,
    required this.port,
    required this.lastSeen,
    this.bonsoirName,
  });

  final String id;
  final String name;
  final String platform;
  final String version;
  final String ip;
  final int port;
  final DateTime lastSeen;
  final String? bonsoirName;

  String get address => '$ip:$port';

  RemoteSyncDevice touch() => RemoteSyncDevice(
    id: id,
    name: name,
    platform: platform,
    version: version,
    ip: ip,
    port: port,
    lastSeen: DateTime.now(),
    bonsoirName: bonsoirName,
  );

  /// 从广播属性还原设备；拿不到合法 IPv4 时返回 null（还没 resolve 完整）。
  static RemoteSyncDevice? fromService(BonsoirService service, {required String localIp}) {
    final attributes = service.attributes;
    final id = attributes['id']?.trim() ?? '';
    if (id.isEmpty) return null;

    // 优先用 Bonsoir 解析出的地址，其次用 TXT 里广播的 IP。
    final ip = _selectIp(service, localIp) ?? attributes['ip']?.trim();
    if (ip == null || !isValidIpv4(ip)) return null;

    final name = attributes['name']?.trim() ?? '';
    return RemoteSyncDevice(
      id: id,
      name: name.isNotEmpty ? name : service.name,
      platform: attributes['platform'] ?? '',
      version: attributes['version'] ?? '',
      ip: ip,
      // Bonsoir 尚未 resolve 时 port 可能是 0，而 PureLive 用的是固定端口。
      port: service.port > 0 ? service.port : RemoteSyncProtocol.httpPort,
      lastSeen: DateTime.now(),
      bonsoirName: service.name,
    );
  }

  static String? _selectIp(BonsoirService service, String localIp) {
    final ipv4 = service.hostAddresses.where(isValidIpv4).toList(growable: false);
    if (ipv4.isEmpty) return null;

    // 同网段优先，避免多网卡（有线 + 热点）挑错地址。
    final localPrefix = _prefix24(localIp);
    if (localPrefix != null) {
      for (final ip in ipv4) {
        if (_prefix24(ip) == localPrefix) return ip;
      }
    }
    for (final ip in ipv4) {
      if (_isPrivateIpv4(ip)) return ip;
    }
    return ipv4.first;
  }

  static bool isValidIpv4(String value) {
    final parts = value.trim().split('.');
    if (parts.length != 4) return false;
    for (final part in parts) {
      final octet = int.tryParse(part);
      if (octet == null || octet < 0 || octet > 255) return false;
    }
    return true;
  }

  static String? _prefix24(String ip) {
    final parts = ip.trim().split('.');
    if (parts.length != 4) return null;
    return '${parts[0]}.${parts[1]}.${parts[2]}';
  }

  static bool _isPrivateIpv4(String ip) {
    final parts = ip.split('.');
    if (parts.length != 4) return false;
    final first = int.tryParse(parts[0]);
    final second = int.tryParse(parts[1]);
    if (first == null || second == null) return false;
    if (first == 10) return true;
    if (first == 192 && second == 168) return true;
    if (first == 172 && second >= 16 && second <= 31) return true;
    return false;
  }
}
