import 'dart:io';
import 'dart:async';
import 'package:pure_live/common/utils/app_path_manager.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class CustomImageCacheManager {
  static const _cacheKey = 'customImageCacheKey';
  static CacheManager? _instance;
  static CacheManager get instance {
    if (_instance == null) {
      throw StateError("CustomImageCacheManager 尚未初始化，请先在 main 中调用 initialize()");
    }
    return _instance!;
  }

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

/// 限制并发下载数的信号量
class _Semaphore {
  final int maxCount;
  int _currentCount = 0;
  final List<Completer<void>> _waiters = [];

  _Semaphore(this.maxCount);

  Future<void> acquire() async {
    if (_currentCount < maxCount) {
      _currentCount++;
      return;
    }
    final completer = Completer<void>();
    _waiters.add(completer);
    await completer.future;
  }

  void release() {
    if (_waiters.isNotEmpty) {
      _waiters.removeAt(0).complete();
    } else {
      _currentCount--;
    }
  }
}

class HttpFileServiceWithRetry extends HttpFileService {
  static final _semaphore = _Semaphore(4);

  @override
  Future<FileServiceResponse> get(String url, {Map<String, String>? headers}) async {
    await _semaphore.acquire();
    int retryCount = 0;
    const int maxRetries = 3;

    try {
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
    } finally {
      _semaphore.release();
    }
  }
}
