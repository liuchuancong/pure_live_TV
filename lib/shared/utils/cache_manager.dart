import 'dart:io';
import 'package:pure_live/app/bootstrap/app_path_manager.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class CustomImageCacheManager {
  static const _cacheKey = 'customImageCacheKey';
  static CacheManager? _instance;

  /// Falls back to the default cache manager until [initialize] completes, so a
  /// widget built before the cache directory is ready cannot crash.
  static CacheManager get instance => _instance ?? DefaultCacheManager();

  static Future<void> initialize() async {
    if (_instance != null) return;
    final Directory imageCacheDir = await AppPathManager().getDir(AppPathManager.dirImageCache);
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
