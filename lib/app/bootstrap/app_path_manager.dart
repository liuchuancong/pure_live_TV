import 'dart:io';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

class AppPathManager {
  static final AppPathManager _instance = AppPathManager._internal();
  factory AppPathManager() => _instance;
  AppPathManager._internal();

  static const String dirIptvCache = 'IPTV_CACHE';
  static const String iptvTable = 'pure_live_tv';
  static const String dirDownload = 'DOWNLOADS';
  static const String fontDirectoryName = 'fonts';
  static const String dirLogs = 'LOGS';
  static const String dirHiveDB = 'HIVE_DB';
  static const String dirBackup = 'BACKUP';
  static const String dirImageCache = 'IMAGE_CACHE';
  static const String dirRecords = 'RECORDS';
  static const String iptvCategoryFile = 'categories.json';
  static const String iptvHotFile = 'hot.m3u';
  static const String iptvHotRemoteFile = 'https://raw.githubusercontent.com/YueChan/Live/main/GNTV.m3u';

  String? _secureBasePath;
  String? _cacheBasePath;

  Future<void> initialize() async {
    final Directory supportDir = await getApplicationSupportDirectory();
    _secureBasePath = supportDir.path;

    List<Directory>? externalCacheDirs = await getExternalCacheDirectories();
    if (externalCacheDirs != null && externalCacheDirs.isNotEmpty && externalCacheDirs.first.path.isNotEmpty) {
      _cacheBasePath = externalCacheDirs.first.path;
    } else {
      final Directory tempDir = await getTemporaryDirectory();
      _cacheBasePath = tempDir.path;
    }
  }

  Future<Directory> getDir(String segment) async {
    final String base = (segment == dirHiveDB) ? secureBasePath : cacheBasePath;
    final Directory directory = Directory(p.join(base, segment));
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return directory;
  }

  /// `BACKUP` under the persistent support directory — the TV's default save
  /// location for local backups (survives cache clears, unlike DOWNLOADS).
  Future<Directory> get backupDir async {
    final Directory directory = Directory(p.join(secureBasePath, dirBackup));
    if (!await directory.exists()) {
      await directory.create(recursive: true);
    }
    return directory;
  }

  Future<Directory> get iptvCacheDir => getDir(dirIptvCache);
  Future<Directory> get downloadDir => getDir(dirDownload);
  Future<Directory> get logsDir => getDir(dirLogs);
  Future<Directory> get hiveDbDir => getDir(dirHiveDB);
  Future<Directory> get imageCacheDir => getDir(dirImageCache);
  Future<Directory> get recordsDir => getDir(dirRecords);

  /// `DOWNLOADS/fonts` — the root every downloaded font family lives under.
  Future<Directory> get fontRootDir async {
    final Directory downloadDir = await getDir(dirDownload);
    final Directory fontRoot = Directory(p.join(downloadDir.path, fontDirectoryName));
    if (!await fontRoot.exists()) {
      await fontRoot.create(recursive: true);
    }
    return fontRoot;
  }

  /// The folder holding every weight file of one downloaded family.
  ///
  /// The same layout the mobile app uses (`AppPathManager.getFontFamilyFolderPath`),
  /// so a family downloaded by either app is found by the other.
  Future<String> getFontFamilyFolderPath(String fontId) async =>
      p.join((await fontRootDir).path, fontId);

  String get secureBasePath => _secureBasePath ?? (throw StateError('AppPathManager is not initialized'));
  String get cacheBasePath => _cacheBasePath ?? (throw StateError('AppPathManager is not initialized'));
}
