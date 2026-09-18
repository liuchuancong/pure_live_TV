import 'remote_sync_protocol.dart';

/// One peer on the LAN, discovered over mDNS or entered by hand.
class RemoteSyncDevice {
  final String id;
  final String name;
  final String platform;
  final String version;
  final String ip;
  final int port;
  final DateTime lastSeen;

  /// The mDNS instance name the service was seen as, used to match
  /// service-lost events when no TXT id is available.
  final String? bonsoirName;

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

  factory RemoteSyncDevice.fromJson(Map<String, dynamic> json) {
    return RemoteSyncDevice(
      id: json['id']?.toString() ?? '',
      name: json['name']?.toString() ?? 'PureLive',
      platform: json['platform']?.toString() ?? '',
      version: json['version']?.toString() ?? '',
      ip: json['ip']?.toString() ?? '',
      port: int.tryParse(json['port']?.toString() ?? '') ?? RemoteSyncProtocol.defaultHttpPort,
      lastSeen: DateTime.now(),
      bonsoirName: json['bonsoirName']?.toString(),
    );
  }

  RemoteSyncDevice copyWith({
    String? id,
    String? name,
    String? platform,
    String? version,
    String? ip,
    int? port,
    DateTime? lastSeen,
    String? bonsoirName,
  }) {
    return RemoteSyncDevice(
      id: id ?? this.id,
      name: name ?? this.name,
      platform: platform ?? this.platform,
      version: version ?? this.version,
      ip: ip ?? this.ip,
      port: port ?? this.port,
      lastSeen: lastSeen ?? this.lastSeen,
      bonsoirName: bonsoirName ?? this.bonsoirName,
    );
  }

  String get address => '$ip:$port';

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'platform': platform,
    'version': version,
    'ip': ip,
    'port': port,
    if (bonsoirName != null) 'bonsoirName': bonsoirName,
  };
}
