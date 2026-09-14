import 'dart:io';
import 'dart:convert';
import 'package:pure_live/shared/utils/hive_pref_util.dart';
import 'package:pure_live/services/settings/settings.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'backup_controller.g.dart';

/// Full settings backup: export, validate, import and restore.
@riverpod
class BackupController extends _$BackupController {
  static const int backupVersion = 3;
  static const String backupDirectoryKey = 'backupDirectory';
  static bool _restoreInProgress = false;

  static const List<String> knownSections = <String>[
    'app',
    'theme',
    'font',
    'player',
    'danmaku',
    'volume',
    'favorite',
    'history',
    'webdav',
    'iptv',
    'cookie',
    'proxy',
    'exit',
    'startup',
    'refresh',
    'page',
    'log',
    'tags',
  ];

  @override
  void build() {}

  String get backupDirectory => HivePrefUtil.getString(backupDirectoryKey) ?? '';

  Future<void> setBackupDirectory(String value) async {
    await HivePrefUtil.setString(backupDirectoryKey, value);
  }

  Map<String, dynamic> exportAllSettings({bool includeSensitiveData = true}) {
    final s = SettingsService.to;
    final data = <String, dynamic>{
      'backupVersion': backupVersion,
      'sensitiveDataIncluded': includeSensitiveData,
      'app': s.app.toJson(),
      'theme': s.theme.toJson(),
      'font': s.font.toJson(),
      'player': s.player.toJson(),
      'danmaku': s.danmaku.toJson(),
      'volume': s.volume.toJson(),
      'favorite': s.fav.toJson(),
      'history': s.history.toJson(),
      'iptv': s.iptv.toJson(),
      'proxy': s.proxy.toJson(),
      'exit': s.exit.toJson(),
      'startup': s.startup.toJson(),
      'tags': s.tag.toJson(),
      'refresh': s.refresh.toJson(),
      'page': s.page.toJson(),
      'log': s.log.toJson(),
    };

    if (includeSensitiveData) {
      data['webdav'] = s.webDav.toJson();
      data['cookie'] = s.cookieManager.toJson();
    }
    return data;
  }

  /// 备份离开设备前移除凭据与会话 Cookie。
  static Map<String, dynamic> redactSensitiveData(Map<String, dynamic> source) {
    final result = Map<String, dynamic>.from(source)
      ..remove('webdav')
      ..remove('cookie');
    result['sensitiveDataIncluded'] = false;
    return result;
  }

  static int countConfigSections(Map<String, dynamic> data) {
    return knownSections.where(data.containsKey).length;
  }

  /// 拒绝结构错误的分区，在任何控制器持久化之前抛出。
  static void validateSectionStructure(Map<String, dynamic> data) {
    for (final name in knownSections) {
      final section = data[name];
      if (section == null) continue;
      if (section is! Map || section.keys.any((key) => key is! String)) {
        throw FormatException('Invalid backup section: $name');
      }
    }
  }

  static void validateBackupIdentity(Map<String, dynamic> data) {
    final version = data['backupVersion'];
    if (version != null && (version is! int || version < 1)) {
      throw const FormatException('Invalid backup version');
    }
    var recognized = false;
    if (version == null) {
      // 旧版扁平备份：任意已知键出现即认可。
      final legacyTags = data['custom_tags_data'];
      recognized =
          (legacyTags is Map && legacyTags.keys.any((k) => k == 'tags' || k == 'roomTagsMap')) ||
          knownSections.any((section) => data.containsKey(section)) ||
          data.containsKey('pipDanmaNoEmojiMode') ||
          data.containsKey('hideDanmaku') ||
          data.containsKey('favoriteRooms');
    } else {
      validateSectionStructure(data);
      recognized = knownSections.any((section) => data[section] is Map);
    }
    if (!recognized) throw const FormatException('No recognized backup settings');
  }

  void importAllSettings(Map<String, dynamic> data) {
    validateBackupIdentity(data);
    final version = data['backupVersion'];
    final s = SettingsService.to;

    final sectionParsers = <String, void Function(Map<String, dynamic>)>{
      'app': s.app.importFromJson,
      'theme': s.theme.importFromJson,
      'font': s.font.importFromJson,
      'player': s.player.importFromJson,
      'danmaku': s.danmaku.importFromJson,
      'volume': s.volume.importFromJson,
      'favorite': s.fav.importFromJson,
      'history': s.history.importFromJson,
      'iptv': s.iptv.importFromJson,
      'proxy': s.proxy.importFromJson,
      'exit': s.exit.importFromJson,
      'startup': s.startup.importFromJson,
      'refresh': s.refresh.importFromJson,
      'page': s.page.importFromJson,
      'webdav': s.webDav.importFromJson,
      'cookie': s.cookieManager.importFromJson,
    };

    if (version == null) {
      // 旧版扁平备份：所有控制器直接消费整份数据（缺失键回落到默认值）。
      for (final parser in sectionParsers.values) {
        parser(data);
      }
      final legacyTags = data['custom_tags_data'];
      if (legacyTags is Map) {
        s.tag.importFromJson(Map<String, dynamic>.from(legacyTags));
      }
      return;
    }

    for (final entry in sectionParsers.entries) {
      if (data.containsKey(entry.key)) {
        entry.value(Map<String, dynamic>.from(data[entry.key] ?? {}));
      }
    }
    final tags = data['tags'];
    if (tags is Map) {
      s.tag.importFromJson(Map<String, dynamic>.from(tags));
    }
  }

  bool backup(File file) {
    try {
      final data = exportAllSettings();
      file.writeAsStringSync(const JsonEncoder.withIndent('  ').convert(data));
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Serializes restore runs so concurrent imports cannot interleave writes.
  Future<void> restoreAllSettings(Map<String, dynamic> data) async {
    if (_restoreInProgress) throw StateError('A settings restore is already running');
    _restoreInProgress = true;
    try {
      importAllSettings(data);
    } finally {
      _restoreInProgress = false;
    }
  }

  Future<bool> recover(File file) async {
    try {
      final json = await file.readAsString();
      final data = jsonDecode(json);
      if (data is! Map<String, dynamic>) return false;
      await restoreAllSettings(data);
      return true;
    } catch (_) {
      return false;
    }
  }

  /// Deletes the backup file and its parent directory after a restore.
  Future<bool> recoverAndDelete(File file) async {
    var restored = false;
    try {
      if (!await file.exists()) return false;
      final json = await file.readAsString();
      final data = jsonDecode(json);
      if (data is Map<String, dynamic>) {
        await restoreAllSettings(data);
        restored = true;
      }
    } catch (_) {
      restored = false;
    } finally {
      try {
        if (await file.exists()) await file.delete();
        final parent = file.parent;
        if (await parent.exists()) {
          try {
            await parent.delete();
          } catch (_) {}
        }
      } catch (_) {}
    }
    return restored;
  }

  /// Flat configuration (danmaku/favorites/history/cookies) pushed to a TV or LAN peer.
  Map<String, dynamic> exportToTVSettings({bool includeSensitiveData = true}) {
    final s = SettingsService.to;
    final danmaku = s.danmaku.toJson();
    final iptv = s.iptv.toJson();
    final favorite = s.fav.toJson();
    final history = s.history.toJson();

    final data = <String, dynamic>{
      ...danmaku,
      ...favorite,
      ...history,
      'customIptvUserAgent': iptv['customIptvUserAgent'],
    };
    if (includeSensitiveData) {
      data.addAll(s.cookieManager.toJson());
    }
    return data;
  }
}
