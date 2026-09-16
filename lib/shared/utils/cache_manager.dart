import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:pure_live/app/bootstrap/app_path_manager.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// Dedicated cache manager for cover images.
///
/// Fully isolated from [DefaultCacheManager] (own key, own directory, own
/// database). As a result, clearing must explicitly call [emptyCache];
/// clearing only DefaultCacheManager will not touch this cache.
class CustomImageCacheManager {
  static const _cacheKey = 'customImageCacheKey';
  static CacheManager? _instance;
  static Directory? _cacheDir;

  /// Falls back to [DefaultCacheManager] until [initialize] completes, so a
  /// widget built before the cache directory is ready cannot crash.
  static CacheManager get instance => _instance ?? DefaultCacheManager();

  /// Intended for the "clear cache" flow. Semantically equivalent to
  /// `CustomImageCacheManager.instance.emptyCache()`, but silently skips when
  /// the manager has not been initialized yet.
  static Future<void> emptyCache() async {
    final manager = _instance;
    if (manager == null) {
      return;
    }
    try {
      await manager.emptyCache();
    } catch (error, stack) {
      debugPrint('CustomImageCacheManager.emptyCache failed: $error\n$stack');
    }
  }

  static Future<void> initialize() async {
    if (_instance != null) return;

    debugPrint('CustomImageCacheManager.initialize: start');
    final Directory imageCacheDir = await AppPathManager().getDir(AppPathManager.dirImageCache);
    if (!imageCacheDir.existsSync()) {
      imageCacheDir.createSync(recursive: true);
    }
    _cacheDir = imageCacheDir;
    debugPrint('CustomImageCacheManager: dir=${imageCacheDir.path}');

    final customFileSystem = IOFileSystem(imageCacheDir.path);

    _instance = CacheManager(
      Config(
        _cacheKey,
        stalePeriod: const Duration(days: 7),
        maxNrOfCacheObjects: 200,
        fileSystem: customFileSystem,
        fileService: HttpFileServiceWithRetry(),
      ),
    );
    debugPrint('CustomImageCacheManager.initialize: done');
  }

  /// Called after the underlying directory has been purged externally, so the
  /// manager is rebuilt and JsonCacheInfoRepository no longer holds stale
  /// records pointing to deleted files.
  static Future<void> reset() async {
    _instance = null;
    _cacheDir = null;
    await initialize();
  }

  /// Used by `_purgeDirectory` to detect whether a given directory is the one
  /// backing the image cache.
  static bool ownsDirectory(Directory directory) {
    final dir = _cacheDir;
    if (dir == null) return false;
    return dir.absolute.path == directory.absolute.path;
  }
}

class HttpFileServiceWithRetry extends HttpFileService {
  @override
  Future<FileServiceResponse> get(String url, {Map<String, String>? headers}) async {
    int retryCount = 0;
    const int maxRetries = 3;

    while (true) {
      try {
        return await super.get(url, headers: headers);
      } catch (e) {
        retryCount++;
        if (retryCount >= maxRetries || e.toString().contains('404')) {
          rethrow;
        }
        await Future.delayed(Duration(milliseconds: 500 * retryCount));
      }
    }
  }
}
