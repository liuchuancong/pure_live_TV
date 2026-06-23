import 'dart:io';
import 'cache_model.dart';
import 'package:pure_live/global/app_path_manager.dart';
import 'package:pure_live/services/settings/settings.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'cache_controller.g.dart';

@riverpod
class CacheController extends _$CacheController {
  static CacheController get to => SettingsService.to.cache;
  @override
  CacheModel build() {
    getCacheSize();
    return const CacheModel();
  }

  Future<void> getCacheSize() async {
    final dirs = await _getTargetDirs();
    double totalSizeBytes = 0;

    for (final dir in dirs) {
      if (!dir.existsSync()) continue;
      try {
        final files = dir.listSync(recursive: true);
        for (final file in files) {
          if (file is File) totalSizeBytes += file.lengthSync();
        }
      } catch (_) {}
    }

    state = state.copyWith(cacheSizeMB: totalSizeBytes / 1024 / 1024);
  }

  Future<void> clearCache() async {
    final dirs = await _getTargetDirs();
    for (final dir in dirs) {
      if (!dir.existsSync()) continue;
      try {
        dir.deleteSync(recursive: true);
        dir.createSync(recursive: true);
      } catch (_) {}
    }
    state = state.copyWith(cacheSizeMB: 0);
  }

  Future<void> handleManualRefresh() async {
    state = state.copyWith(refreshTurns: state.refreshTurns + 1.0);
    await getCacheSize();
  }

  Future<List<Directory>> _getTargetDirs() async {
    final path = AppPathManager();
    return [await path.recordsDir, await path.imageCacheDir, await path.downloadDir, await path.iptvCacheDir];
  }
}
