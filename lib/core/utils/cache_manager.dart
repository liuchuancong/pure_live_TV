import 'dart:io';
import 'package:http/io_client.dart';
import 'package:flutter/foundation.dart';
import 'package:pure_live/app/bootstrap/app_path_manager.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

/// Dedicated cache manager for cover images.
///
/// Fully isolated from [DefaultCacheManager] (own key, own directory, own
/// database). As a result, clearing must explicitly call [emptyCache];
/// clearing only DefaultCacheManager will not touch this cache.
///
/// The instance mixes in [ImageCacheManager] because every cover widget asks
/// for `memCacheWidth`/`maxWidthDiskCache`: `cached_network_image` asserts that
/// a resizing request goes to an [ImageCacheManager] and — in debug builds —
/// that assertion is swallowed by its own error handler and turned into an
/// image load failure, so a plain [CacheManager] silently shows no images.
class CustomImageCacheManager {
  static const _cacheKey = 'customImageCacheKey';

  static CacheManager? _instance;
  static Directory? _cacheDir;

  static String Function()? _proxyDirectiveProvider;

  static Future<void>? _initializeFuture;

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

  static Future<void> initialize({String Function()? proxyDirectiveProvider}) {
    if (_instance != null) {
      if (proxyDirectiveProvider != null) {
        _proxyDirectiveProvider = proxyDirectiveProvider;
      }

      return Future.value();
    }

    final existingFuture = _initializeFuture;

    if (existingFuture != null) {
      return existingFuture;
    }

    _proxyDirectiveProvider = proxyDirectiveProvider;

    final future = _initializeInternal();

    _initializeFuture = future;

    return future.whenComplete(() {
      _initializeFuture = null;
    });
  }

  static Future<void> _initializeInternal() async {
    debugPrint('CustomImageCacheManager.initialize: start');

    try {
      final Directory imageCacheDir = await AppPathManager().getDir(AppPathManager.dirImageCache);

      if (!imageCacheDir.existsSync()) {
        await imageCacheDir.create(recursive: true);
      }

      _cacheDir = imageCacheDir;

      debugPrint('CustomImageCacheManager: dir=${imageCacheDir.path}');

      final customFileSystem = IOFileSystem(imageCacheDir.path);

      _instance = _ResizingImageCacheManager(
        Config(
          _cacheKey,
          stalePeriod: const Duration(days: 7),
          // 200 objects thrashed on deep scrolls (12-per-page grids exceed it by
          // page ~17); covers are disk-capped at 1280px so the memory cost stays
          // bounded.
          maxNrOfCacheObjects: 600,
          fileSystem: customFileSystem,
          fileService: HttpFileServiceWithRetry(
            proxyDirectiveProvider: () {
              return _proxyDirectiveProvider?.call() ?? 'DIRECT';
            },
          ),
        ),
      );

      debugPrint('CustomImageCacheManager.initialize: done');
    } catch (error, stack) {
      _instance = null;
      _cacheDir = null;

      debugPrint('CustomImageCacheManager.initialize failed: $error\n$stack');

      rethrow;
    }
  }

  /// Called after the underlying directory has been purged externally, so the
  /// manager is rebuilt and JsonCacheInfoRepository no longer holds stale
  /// records pointing to deleted files.
  static Future<void> reset() async {
    final manager = _instance;

    _instance = null;
    _cacheDir = null;

    if (manager != null) {
      try {
        await manager.emptyCache();
      } catch (error, stack) {
        debugPrint('CustomImageCacheManager.reset cleanup failed: $error\n$stack');
      }
    }

    await initialize(proxyDirectiveProvider: _proxyDirectiveProvider);
  }

  /// Used by `_purgeDirectory` to detect whether a given directory is the one
  /// backing the image cache.
  static bool ownsDirectory(Directory directory) {
    final dir = _cacheDir;

    if (dir == null) {
      return false;
    }

    return _sameDirectory(dir, directory);
  }

  /// Returns the directory used by this image cache.
  static Future<Directory> cacheDirectory() async {
    final dir = _cacheDir;

    if (dir != null) {
      return dir;
    }

    final imageCacheDir = await AppPathManager().getDir(AppPathManager.dirImageCache);

    if (!imageCacheDir.existsSync()) {
      await imageCacheDir.create(recursive: true);
    }

    return imageCacheDir;
  }

  /// Removes one cached image.
  ///
  /// Windows may temporarily keep the file locked by another process, so the
  /// delete operation is retried a few times before giving up.
  static Future<void> remove(String url) async {
    final manager = _instance;

    if (manager == null) {
      return;
    }

    try {
      final fileInfo = await manager.getFileFromCache(url);

      if (fileInfo == null) {
        return;
      }

      final file = fileInfo.file;

      for (var i = 0; i < 5; i++) {
        try {
          if (!await file.exists()) {
            return;
          }

          await file.delete();
          return;
        } on PathAccessException catch (error, stack) {
          if (i == 4) {
            debugPrint(
              'CustomImageCacheManager.remove failed: '
              '$url: $error\n$stack',
            );
            return;
          }

          await Future.delayed(Duration(milliseconds: 100 * (i + 1)));
        } catch (error, stack) {
          debugPrint(
            'CustomImageCacheManager.remove failed: '
            '$url: $error\n$stack',
          );
          return;
        }
      }
    } catch (error, stack) {
      debugPrint(
        'CustomImageCacheManager.remove lookup failed: '
        '$url: $error\n$stack',
      );
    }
  }

  static bool _sameDirectory(Directory first, Directory second) {
    return _normalizePath(first.absolute.path) == _normalizePath(second.absolute.path);
  }

  static String _normalizePath(String path) {
    var normalized = path;

    if (Platform.isWindows) {
      normalized = normalized.toLowerCase();
    }

    while (normalized.endsWith(Platform.pathSeparator)) {
      normalized = normalized.substring(0, normalized.length - Platform.pathSeparator.length);
    }

    return normalized;
  }
}

/// A [CacheManager] that can also resize images on disk, as required by
/// `cached_network_image`'s `maxWidthDiskCache`/`maxHeightDiskCache`.
class _ResizingImageCacheManager extends CacheManager with ImageCacheManager {
  _ResizingImageCacheManager(super.config);
}

class HttpFileServiceWithRetry extends HttpFileService {
  HttpFileServiceWithRetry({this.proxyDirectiveProvider})
    : super(httpClient: IOClient(_createHttpClient(proxyDirectiveProvider)));

  final String Function()? proxyDirectiveProvider;

  static HttpClient _createHttpClient(String Function()? proxyDirectiveProvider) {
    final client = HttpClient()
      ..idleTimeout = const Duration(seconds: 30)
      ..badCertificateCallback = (X509Certificate cert, String host, int port) {
        // Ignore all HTTPS certificate validation errors.
        return true;
      };

    client.findProxy = (Uri uri) {
      try {
        final directive = proxyDirectiveProvider?.call();

        return directive ?? 'DIRECT';
      } catch (_) {
        return 'DIRECT';
      }
    };

    return client;
  }

  @override
  Future<FileServiceResponse> get(String url, {Map<String, String>? headers}) async {
    int retryCount = 0;

    const maxRetries = 3;

    while (true) {
      try {
        return await super.get(url, headers: headers);
      } catch (error) {
        retryCount++;

        if (retryCount >= maxRetries || _isPermanentError(error)) {
          rethrow;
        }

        await Future.delayed(Duration(milliseconds: 500 * retryCount));
      }
    }
  }

  bool _isPermanentError(Object error) {
    if (error is HttpException) {
      final message = error.message;

      return message.startsWith('HTTP 4') && !message.startsWith('HTTP 408') && !message.startsWith('HTTP 429');
    }

    return false;
  }
}
