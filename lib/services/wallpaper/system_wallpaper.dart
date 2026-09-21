import 'package:async_wallpaper/async_wallpaper.dart';
import 'package:flutter/services.dart';

/// Sets the Android system (home) wallpaper through `async_wallpaper`, which
/// handles sampling, capability checks and exceptions natively.
class SystemWallpaper {
  /// Sets a static wallpaper; null on success, a user-facing reason otherwise.
  ///
  /// The reason is the plugin's real error code/message (e.g.
  /// `wallpaper-not-allowed`, what Android TV ROMs answer when the launcher
  /// forbids third-party wallpaper changes) — a bare `failed` here hid the
  /// actual blocker and made the TV failure undiagnosable.
  static Future<String?> setImage(Uint8List bytes) async {
    try {
      final result = await AsyncWallpaper.applyWallpaper(
        StaticWallpaperRequest(
          source: WallpaperSource.bytes(bytes),
          target: WallpaperTarget.home,
          // Centre-crop to the screen so a tall image is not stretched.
          scaleMode: WallpaperScaleMode.centerCrop,
        ),
      );

      // The automatic strategy falls back to the system cropper when a direct
      // apply is blocked: from that point the user confirms in the system UI,
      // which is progress, not failure.
      switch (result.status) {
        case WallpaperOperationStatus.applied:
        case WallpaperOperationStatus.previewOpened:
        case WallpaperOperationStatus.awaitingUserConfirmation:
          return null;
        case WallpaperOperationStatus.foregroundRequired:
          return 'foreground_required';
        case WallpaperOperationStatus.cancelled:
          return 'cancelled';
        case WallpaperOperationStatus.unsupported:
        case WallpaperOperationStatus.failed:
          final home = result.home;
          return <String?>[
            home?.errorCode,
            home?.errorMessage,
            result.errorCode,
            result.errorMessage,
          ].firstWhere((part) => part != null && part.isNotEmpty, orElse: () => 'failed')!;
      }
    } on MissingPluginException {
      return 'plugin_missing';
    } on PlatformException catch (e) {
      return e.message ?? e.code;
    } catch (e) {
      return e.toString();
    }
  }

  /// Sets a video live wallpaper. Android never applies one silently: the
  /// plugin prepares the source and the system confirm screen opens, so null
  /// means the screen is up, not that the wallpaper is live. [filePath] is
  /// preferred over [url] to skip a round trip and some CDN referer checks.
  static Future<String?> setVideo({String? filePath, String? url}) async {
    final hasFile = filePath != null && filePath.isNotEmpty;
    final hasUrl = url != null && url.isNotEmpty;
    if (!hasFile && !hasUrl) return 'no_source';

    try {
      final request = VideoWallpaperRequest(
        source: hasFile ? WallpaperSource.filePath(filePath) : WallpaperSource.url(url!),
        target: WallpaperTarget.home,
        scaleMode: WallpaperScaleMode.centerCrop,
      );

      final prepared = await AsyncWallpaper.setVideoWallpaper(request);
      final prepareFailure = _operationFailure(prepared);
      if (prepareFailure != null) return prepareFailure;

      final preview = await AsyncWallpaper.openLiveWallpaperPreview(request);
      return _operationFailure(preview);
    } on MissingPluginException {
      return 'plugin_missing';
    } on PlatformException catch (e) {
      return e.message ?? e.code;
    } catch (e) {
      return e.toString();
    }
  }

  /// A failure is `failed`/`unsupported`; anything else (applied, preview
  /// opened, waiting for the user) counts as success.
  static String? _operationFailure(WallpaperOperationResult result) {
    switch (result.status) {
      case WallpaperOperationStatus.failed:
        return result.errorMessage ?? result.errorCode ?? 'failed';
      case WallpaperOperationStatus.unsupported:
        return 'unsupported';
      case WallpaperOperationStatus.cancelled:
        return 'cancelled';
      case WallpaperOperationStatus.applied:
      case WallpaperOperationStatus.previewOpened:
      case WallpaperOperationStatus.awaitingUserConfirmation:
      case WallpaperOperationStatus.foregroundRequired:
        return null;
    }
  }
}
