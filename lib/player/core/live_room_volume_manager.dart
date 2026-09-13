import 'dart:io';

import 'package:pure_live/services/settings/settings.dart';

/// 直播间音量记忆：按房间保存/恢复音量，全局静音优先。
/// 同步自 pure_live 的 LiveRoomVolumeManager；
/// 播放器核心是非 widget 代码，走 SettingsService 外观读取 Riverpod 状态。
class LiveRoomVolumeManager {
  static double getRoomVolume(String platform, String roomId) {
    final volState = SettingsService.to.volumeState;

    // 全局静音
    if (volState.globalVolumeMute) return 0.0;

    final volume = volState.roomVolumes[roomId];
    if (volume != null && volume.isFinite) return volume.clamp(0.0, 1.0).toDouble();

    // 使用全局默认音量
    final defaultValue = (Platform.isAndroid || Platform.isIOS) ? volState.defaultMobileVolume : volState.defaultDesktopVolume;
    return defaultValue.isFinite ? defaultValue.clamp(0.0, 1.0).toDouble() : 1.0;
  }

  static Future<void> saveRoomVolume(String platform, String roomId, double volume) async {
    if (!volume.isFinite) return;
    SettingsService.to.volume.setRoomVolume(roomId, volume.clamp(0.0, 1.0).toDouble());
  }
}
