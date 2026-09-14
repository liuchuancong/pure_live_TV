/// 局域网同步（TV ↔ 手机 / 桌面）的协议常量。
///
/// 与 `D:\flutter\pure_live` 的 `RemoteSyncProtocol` 保持一致，这样 TV 端能和
/// 已有的手机/桌面端直接互相发现和同步。
class RemoteSyncProtocol {
  RemoteSyncProtocol._();

  /// 同步专用 HTTP 端口（与手机遥控扫码的 8888 分开，互不影响）。
  static const int httpPort = 39888;

  /// mDNS 服务类型。
  static const String mdnsServiceType = '_my-service._tcp';

  /// 设备发现包类型标识。
  static const String discoveryType = 'pure_live_discovery';

  /// 设置同步包类型标识。
  static const String syncType = 'pure_live_sync';

  static const String apiStatus = '/api/remote-sync/status';
  static const String apiSettings = '/api/remote-sync/settings';

  static String httpBase(String ip, int port) => 'http://$ip:$port';
}
