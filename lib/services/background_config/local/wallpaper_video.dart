import 'dart:io';

import 'package:media_kit_video/media_kit_video.dart';
import 'package:path/path.dart' as p;
import 'package:pure_live/app/bootstrap/app_path_manager.dart';
import 'package:pure_live/shared/common/http_client.dart';

/// Everything the live-wallpaper feature needs from the video stack.
///
/// Two things were wrong with the first cut of the video background:
///
/// * It streamed the clip from the CDN. The background layer mounts while the
///   network is still settling, so a failed open left a plain black screen.
///   [WallpaperVideoStore.download] saves the bytes once and the background then
///   plays a local file, which cannot half-open.
/// * The player used media_kit's default [VideoControllerConfiguration], which
///   attaches the Android surface before the video parameters are known — the
///   documented recipe for a one-pixel/black surface. The rest of the app
///   already works around that, and [wallpaperVideoControllerConfiguration]
///   applies the same fix here.
///
/// The download is stored as a **file**, not as a base64 blob in Hive: these
/// clips run to tens of megabytes, and a base64 string that size would sit in
/// memory and be rewritten into the settings box on every fill-mode change.
class WallpaperVideoStore {
  const WallpaperVideoStore._();

  static const String _dirName = 'WALLPAPER_VIDEO';

  /// Downloads [url] once and returns the local path.
  ///
  /// A file that already exists and is non-empty is reused, so re-applying the
  /// same wallpaper costs nothing.
  static Future<String> download(
    String url, {
    void Function(int received, int total)? onProgress,
  }) async {
    final Directory dir = await AppPathManager().getDir(_dirName);
    final File file = File(p.join(dir.path, _fileName(url)));
    if (await file.exists() && await file.length() > 0) return file.path;

    await HttpClient.instance.download(
      url,
      file.path,
      header: const <String, String>{
        'User-Agent':
            'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/152.0.0.0 Safari/537.36',
        'Referer': 'https://www.itab.link/',
      },
      onReceiveProgress: onProgress,
    );
    return file.path;
  }

  /// Whether [url] is already on disk, and where.
  static Future<String?> cachedPath(String url) async {
    final Directory dir = await AppPathManager().getDir(_dirName);
    final File file = File(p.join(dir.path, _fileName(url)));
    if (await file.exists() && await file.length() > 0) return file.path;
    return null;
  }

  /// A safe, unique-ish file name derived from the URL.
  static String _fileName(String url) {
    final String raw = url.split('?').first.split('/').last;
    if (raw.isEmpty) return 'wallpaper.mp4';
    return raw.replaceAll(RegExp(r'[^A-Za-z0-9._-]'), '_');
  }
}

/// The video-output configuration every wallpaper player should use.
///
/// This fork of media_kit always renders Android video through a
/// `TextureRegistry.SurfaceProducer` and drives the surface from the decoded
/// video parameters — `androidAttachSurfaceAfterVideoParameters` and
/// `enableAndroidSurfaceProducer` have no consumer in it, so only the knobs
/// that actually reach mpv are set here.
VideoControllerConfiguration wallpaperVideoControllerConfiguration() =>
    VideoControllerConfiguration(
      hwdec: Platform.isMacOS ? 'no' : null,
      enableHardwareAcceleration: !Platform.isMacOS,
    );

/// Headers the wallpaper CDN expects on direct streams.
///
/// Mirrors the [WallpaperVideoStore.download] request: without them the CDN
/// answers 403 and mpv never produces a frame — the background stays black
/// with no other symptom.
Map<String, String> wallpaperVideoHttpHeaders() => const <String, String>{
  'User-Agent':
      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/152.0.0.0 Safari/537.36',
  'Referer': 'https://www.itab.link/',
};
