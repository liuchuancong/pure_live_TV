import 'package:file/local.dart';
import 'package:path/path.dart' as p;
import 'package:file/file.dart'; // 确保引入 File 接口
import 'package:path_provider/path_provider.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';

class CustomCacheManager {
  static const String _key = 'customCacheKey';

  // 1. 使用单例模式确保全局唯一性
  static final CacheManager instance = CacheManager(
    Config(
      _key,
      stalePeriod: const Duration(days: 7),
      maxNrOfCacheObjects: 100,
      repo: JsonCacheInfoRepository(databaseName: _key),
      fileService: HttpFileService(),
    ),
  );

  /// 获取缓存大小 (单位: MB)
  static Future<double> getCacheSize() async {
    final baseDir = await getTemporaryDirectory();
    final path = p.join(baseDir.path, _key);
    final fs = const LocalFileSystem();
    final directory = fs.directory(path);

    if (!await directory.exists()) return 0.0;

    int totalSize = 0;
    try {
      // 2. 必须遍历子文件累加大小，directory.stat().size 只是文件夹本身的大小（通常是4KB）
      await for (final file in directory.list(recursive: true, followLinks: false)) {
        if (file is File) {
          totalSize += await file.length();
        }
      }
    } catch (e) {
      return 0.0;
    }

    // 3. 换算单位：Bytes / 1024 / 1024 = MB
    return totalSize / (1024 * 1024);
  }

  /// 清除缓存
  static Future<void> clearCache() async {
    await instance.emptyCache();
  }
}
