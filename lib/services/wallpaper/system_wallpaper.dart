import 'package:flutter/services.dart';

/// Sets the Android system (launcher) wallpaper through the platform channel
/// registered in MainActivity.
class SystemWallpaper {
  static const MethodChannel _channel = MethodChannel('pure_live/system_wallpaper');

  /// Returns true when the launcher wallpaper was replaced with [bytes].
  static Future<bool> setImage(Uint8List bytes) async {
    try {
      final ok = await _channel.invokeMethod<bool>('setWallpaper', bytes);
      return ok == true;
    } catch (_) {
      return false;
    }
  }
}
