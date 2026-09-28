import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pure_live/shared/common/http_client.dart';
import 'package:pure_live/shared/utils/core_log.dart';

/// Persistent audio cache for music mode: one file per track, downloaded in the
/// background while the network stream plays, and preferred over the network on
/// every later play — so a track heard once no longer depends on CDN links,
/// which expire, or on the network at all.
///
/// Video is deliberately not cached: a music track's audio is a few megabytes,
/// its video tens, and the picture is exactly what 纯音乐 mode does not show.
class MusicAudioCache {
  MusicAudioCache._();

  static final MusicAudioCache instance = MusicAudioCache._();

  Directory? _dir;
  final Set<String> _downloading = <String>{};

  /// Directory holding the cached tracks, created on first use. Null when the
  /// platform gives no usable storage — the caller then always streams.
  Future<Directory?> _ensureDir() async {
    final dir = _dir;
    if (dir != null) return dir;
    try {
      final support = await getApplicationSupportDirectory();
      final cache = Directory('${support.path}${Platform.pathSeparator}music_cache');
      if (!cache.existsSync()) cache.createSync(recursive: true);
      _dir = cache;
      return cache;
    } catch (error) {
      CoreLog.w('MusicAudioCache: no storage: $error');
      return null;
    }
  }

  /// The cached audio for [trackId], or null when it has not finished
  /// downloading.
  Future<File?> cachedFile(String trackId) async {
    final dir = await _ensureDir();
    if (dir == null) return null;
    final file = File('${dir.path}${Platform.pathSeparator}$trackId.m4a');
    return file.existsSync() ? file : null;
  }

  /// Whether a download for [trackId] is running right now.
  bool isDownloading(String trackId) => _downloading.contains(trackId);

  /// Downloads [url] as [trackId]'s cached audio. Silent: the network stream is
  /// already playing, so a failed prefetch only costs the next play.
  void prefetch({required String trackId, required String url, required Map<String, String> headers}) {
    if (_downloading.contains(trackId)) return;
    _downloading.add(trackId);
    unawaited(() async {
      try {
        final dir = await _ensureDir();
        if (dir == null) return;
        final target = File('${dir.path}${Platform.pathSeparator}$trackId.m4a');
        if (target.existsSync()) return;
        // A partial download must never be mistaken for a complete one: the
        // part file is renamed only after the response has been written whole.
        final part = File('${target.path}.part');
        await HttpClient.instance.dio.download(
          url,
          part.path,
          options: Options(headers: headers, responseType: ResponseType.bytes),
        );
        if (part.existsSync() && part.lengthSync() > 0) {
          await part.rename(target.path);
        } else {
          part.deleteSync();
        }
      } catch (_) {
        // The leftover part file is replaced on the next attempt.
        try {
          final dir = await _ensureDir();
          if (dir != null) {
            File('${dir.path}${Platform.pathSeparator}$trackId.m4a.part').deleteSync();
          }
        } catch (_) {}
      } finally {
        _downloading.remove(trackId);
      }
    }());
  }
}
