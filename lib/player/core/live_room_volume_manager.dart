import 'dart:io';

import 'package:pure_live/services/settings/settings.dart';

/// Per-room volume memory with global mute taking precedence.
///
/// The player core is non-widget code, so it reads Riverpod state through the
/// SettingsService facade.
class LiveRoomVolumeManager {
  static double getRoomVolume(String platform, String roomId) {
    final volState = SettingsService.to.volumeState;

    // Muted globally.
    if (volState.globalVolumeMute) return 0.0;

    final volume = volState.roomVolumes[roomId];
    if (volume != null && volume.isFinite) return volume.clamp(0.0, 1.0).toDouble();

    // Fall back to the global default volume.
    final defaultValue = (Platform.isAndroid || Platform.isIOS) ? volState.defaultMobileVolume : volState.defaultDesktopVolume;
    return defaultValue.isFinite ? defaultValue.clamp(0.0, 1.0).toDouble() : 1.0;
  }

  static Future<void> saveRoomVolume(String platform, String roomId, double volume) async {
    if (!volume.isFinite) return;
    SettingsService.to.volume.setRoomVolume(roomId, volume.clamp(0.0, 1.0).toDouble());
  }
}
