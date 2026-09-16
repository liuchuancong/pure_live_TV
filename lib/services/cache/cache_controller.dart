import 'dart:io';
import 'cache_model.dart';
import 'package:pure_live/exports/package_export.dart';
import 'package:pure_live/shared/utils/cache_manager.dart';
import 'package:pure_live/services/settings/settings.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:pure_live/app/bootstrap/app_path_manager.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

// NOTE: adjust to the actual path in your project.

part 'cache_controller.g.dart';

typedef CacheDirectoryResolver = Future<List<Directory>> Function();
typedef CacheDirectoryPurger = Future<bool> Function(Directory directory);
typedef EncodedImageCacheClearer = Future<void> Function();

int _measureDirectoryBytes(List<String> paths) {
  var total = 0;
  for (final path in paths.toSet()) {
    final directory = Directory(path);
    if (!directory.existsSync()) continue;
    try {
      for (final entity in directory.listSync(recursive: true, followLinks: false)) {
        if (entity is File) {
          try {
            total += entity.lengthSync();
          } on FileSystemException {
            // Cached files may be replaced while a background scan is running.
          }
        }
      }
    } on FileSystemException {
      // A platform cache directory may disappear during an explicit clear.
    }
  }
  return total;
}

class CacheClearResult {
  const CacheClearResult({required this.remainingSizeMB, required this.failedOperations});

  final double remainingSizeMB;
  final int failedOperations;

  bool get succeeded => failedOperations == 0;
}

/// Cache maintenance: scan partitions, purge entries, refresh thumbnails.
@riverpod
class CacheController extends _$CacheController {
  static CacheController get to => SettingsService.to.cache;

  CacheController({
    CacheDirectoryResolver? cacheDirectoryResolver,
    CacheDirectoryPurger? cacheDirectoryPurger,
    EncodedImageCacheClearer? encodedImageCacheClearer,
  }) : _cacheDirectoryResolver = cacheDirectoryResolver ?? _defaultCacheDirectories,
       _cacheDirectoryPurger = cacheDirectoryPurger ?? _purgeDirectory,
       _encodedImageCacheClearer = encodedImageCacheClearer ?? _clearDefaultEncodedImageCache;

  final CacheDirectoryResolver _cacheDirectoryResolver;
  final CacheDirectoryPurger _cacheDirectoryPurger;
  final EncodedImageCacheClearer _encodedImageCacheClearer;

  Future<double>? _cacheSizeScan;
  Future<CacheClearResult>? _cacheClearOperation;
  Future<void>? _imageRefreshOperation;

  bool get isBusy => state.isScanning || state.isClearing || state.isRefreshingImages;

  static Future<List<Directory>> _defaultCacheDirectories() async {
    final manager = AppPathManager();
    return [await manager.imageCacheDir, await manager.iptvCacheDir];
  }

  /// Clears both the custom image cache and the default one.
  ///
  /// `CustomImageCacheManager` uses its own directory and its own database.
  /// Calling `DefaultCacheManager().emptyCache()` alone leaves it untouched
  /// and desynchronizes the custom manager's DB from the filesystem, which
  /// later causes cover reads to fail.
  static Future<void> _clearDefaultEncodedImageCache() async {
    try {
      await CustomImageCacheManager.emptyCache();
    } catch (error) {
      debugPrint('Failed to clear custom image cache: $error');
    }
    try {
      await DefaultCacheManager().emptyCache();
    } catch (_) {
      // flutter_cache_manager can throw IO errors on some platforms.
    }
  }

  static Future<bool> _purgeDirectory(Directory directory) async {
    try {
      if (await directory.exists()) {
        await directory.delete(recursive: true);
      }
      await directory.create(recursive: true);
      // If the purged directory is the image cache directory, rebuild the
      // manager so stale DB records do not cause persistent
      // FileSystemExceptions when reading covers.
      if (CustomImageCacheManager.ownsDirectory(directory)) {
        await CustomImageCacheManager.reset();
      }
      return true;
    } on FileSystemException {
      return false;
    }
  }

  @override
  CacheModel build() {
    // build() must not read or write `state` synchronously, otherwise
    // Riverpod throws:
    //   "Bad state: Tried to read the state of an uninitialized provider".
    // Schedule the initial scan on a microtask so it runs after build() has
    // returned and the initial state has been assigned.
    Future.microtask(() async {
      if (!ref.mounted) return;
      try {
        await getCacheSize();
      } catch (error, stack) {
        debugPrint('Initial cache size scan failed: $error\n$stack');
      }
    });
    return const CacheModel();
  }

  Future<double> getCacheSize() async {
    if (!ref.mounted) return 0;

    final clearing = _cacheClearOperation;
    if (clearing != null) {
      await clearing;
      return state.cacheSizeMB;
    }
    final refreshing = _imageRefreshOperation;
    if (refreshing != null) {
      await refreshing;
      return state.cacheSizeMB;
    }

    final active = _cacheSizeScan;
    if (active != null) return active;

    late final Future<double> operation;
    state = state.copyWith(isScanning: true);
    operation = _scanCacheSize().whenComplete(() {
      if (identical(_cacheSizeScan, operation)) {
        _cacheSizeScan = null;
        state = state.copyWith(isScanning: false);
      }
    });
    _cacheSizeScan = operation;
    return operation;
  }

  Future<double> _scanCacheSize({List<Directory>? directories}) async {
    final roots = _uniqueDirectories(directories ?? await _cacheDirectoryResolver());
    final totalSizeBytes = await compute(
      _measureDirectoryBytes,
      roots.map((directory) => directory.absolute.path).toList(growable: false),
    );
    final size = totalSizeBytes / 1024 / 1024;
    if (ref.mounted) {
      state = state.copyWith(cacheSizeMB: size);
    }
    return size;
  }

  Future<CacheClearResult> clearCache() {
    final active = _cacheClearOperation;
    if (active != null) return active;

    late final Future<CacheClearResult> operation;
    state = state.copyWith(isClearing: true);
    operation = _clearCache().whenComplete(() {
      if (identical(_cacheClearOperation, operation)) {
        _cacheClearOperation = null;
        state = state.copyWith(isClearing: false);
      }
    });
    _cacheClearOperation = operation;
    return operation;
  }

  Future<CacheClearResult> _clearCache() async {
    final refreshing = _imageRefreshOperation;
    if (refreshing != null) {
      try {
        await refreshing;
      } catch (error) {
        debugPrint('Previous thumbnail cache refresh failed before clear: $error');
      }
    }
    final activeScan = _cacheSizeScan;
    if (activeScan != null) {
      try {
        await activeScan;
      } catch (error) {
        debugPrint('Previous cache size scan failed before clear: $error');
      }
    }

    var failedOperations = 0;

    // 1) Clear the custom image cache and the default cache.
    try {
      await _encodedImageCacheClearer();
    } catch (error) {
      failedOperations++;
      debugPrint('Failed to clear the encoded image cache: $error');
    }

    // 2) Clear the in-memory image cache.
    try {
      PaintingBinding.instance.imageCache
        ..clear()
        ..clearLiveImages();
    } catch (error) {
      failedOperations++;
      debugPrint('Failed to clear the in-memory image cache: $error');
    }

    // 3) Purge the on-disk cache directories.
    List<Directory>? directories;
    try {
      directories = _uniqueDirectories(await _cacheDirectoryResolver());
    } catch (error) {
      failedOperations++;
      debugPrint('Failed to resolve local cache directories: $error');
    }

    for (final directory in directories ?? const <Directory>[]) {
      var cleared = false;
      try {
        cleared = await _cacheDirectoryPurger(directory);
      } catch (error) {
        debugPrint('Failed to clear cache directory ${directory.path}: $error');
      }
      if (!cleared) failedOperations++;
    }

    // 4) Re-scan the remaining size.
    var remainingSizeMB = state.cacheSizeMB;
    if (directories != null) {
      try {
        remainingSizeMB = await _scanCacheSize(directories: directories);
      } catch (error) {
        failedOperations++;
        debugPrint('Failed to refresh cache size after clearing: $error');
      }
    }
    if (ref.mounted) {
      state = state.copyWith(imageCacheEpoch: state.imageCacheEpoch + 1);
    }
    return CacheClearResult(remainingSizeMB: remainingSizeMB, failedOperations: failedOperations);
  }

  /// Drops the encoded thumbnail cache. A manual refresh rolls the visible
  /// image providers onto a new cache key.
  Future<void> refreshImageCache({bool refreshVisible = true}) {
    final active = _imageRefreshOperation;
    if (active != null) return active;

    late final Future<void> operation;
    state = state.copyWith(isRefreshingImages: true);
    operation = _refreshImageCache(refreshVisible: refreshVisible).whenComplete(() {
      if (identical(_imageRefreshOperation, operation)) {
        _imageRefreshOperation = null;
        state = state.copyWith(isRefreshingImages: false);
      }
    });
    _imageRefreshOperation = operation;
    return operation;
  }

  Future<void> _refreshImageCache({required bool refreshVisible}) async {
    final clearing = _cacheClearOperation;
    if (clearing != null) await clearing;

    final activeScan = _cacheSizeScan;
    if (activeScan != null) {
      try {
        await activeScan;
      } catch (error) {
        debugPrint('Previous cache size scan failed before thumbnail refresh: $error');
      }
    }

    await _encodedImageCacheClearer();
    // Live streams keep their current pixels; clearing them would flash
    // placeholders across the grid and trigger a decode storm.
    PaintingBinding.instance.imageCache.clear();
    if (!refreshVisible) return;
    if (ref.mounted) {
      state = state.copyWith(imageCacheEpoch: state.imageCacheEpoch + 1);
    }
    await _scanCacheSize();
  }

  Future<void> handleManualRefresh() async {
    if (!ref.mounted) return;
    state = state.copyWith(refreshTurns: state.refreshTurns + 1.0);
    await getCacheSize();
  }

  List<Directory> _uniqueDirectories(Iterable<Directory> directories) {
    final unique = <String, Directory>{};
    for (final directory in directories) {
      var key = directory.absolute.path.replaceAll('\\', '/');
      if (Platform.isWindows || Platform.isMacOS) key = key.toLowerCase();
      unique.putIfAbsent(key, () => directory);
    }
    return unique.values.toList(growable: false);
  }
}
