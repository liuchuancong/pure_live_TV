import 'dart:io';
import 'dart:convert';
import 'package:path_provider/path_provider.dart';
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

  /// Sections a document from a non-TV device (the phone app, the LAN web page)
  /// is allowed to touch. A phone cannot know better than the TV about player
  /// kernels, themes or proxy ports, so only user data travels.
  static const List<String> nonTvAcceptedSections = <String>[
    'favorite',
    'history',
    'cookie',
    'tags',
  ];

  /// Whether [data] was produced by a TV build.
  ///
  /// The TV's own exports carry `platformIsTv: true`. Older TV builds only wrote
  /// the sectioned format (`backupVersion`), which the phone app does not, so a
  /// sectioned document without the marker is still trusted as a TV backup. A
  /// flat document — the mobile app's format — is always a non-TV source.
  static bool sourceIsTv(Map<String, dynamic> data) {
    final marker = data['platformIsTv'];
    if (marker is bool) return marker;
    return data['backupVersion'] != null;
  }

  /// The name a backup is written under, e.g. `purelive_2026-09-17T20_15_03.txt`.
  ///
  /// The mobile app's own name and extension (`BackupRecoveryService`), so the same file
  /// can be moved between the phone and the TV. The content is the indented JSON both apps
  /// write — a `.txt` suffix is what the mobile app uses for it, not a different format.
  static String backupFileName(DateTime now) {
    String two(int value) => value.toString().padLeft(2, '0');
    final stamp = '${now.year}-${two(now.month)}-${two(now.day)}'
        'T${two(now.hour)}_${two(now.minute)}_${two(now.second)}';
    return '$backupNamePrefix$stamp.txt';
  }

  /// File name prefix for a new backup.
  static const String backupNamePrefix = 'purelive_';

  /// Prefixes a backup list accepts, so files written by an older TV build stay visible.
  static const List<String> backupNamePrefixes = <String>['purelive_', 'pure_live_backup'];

  /// Extensions the backup pickers accept.
  ///
  /// `.txt` is the format; `.json` is accepted so backups an older TV build wrote can
  /// still be restored.
  static const List<String> backupExtensions = <String>['txt', 'json'];

  static bool isBackupFileName(String fileName) {
    final String name = fileName.toLowerCase();
    if (!backupExtensions.any(name.endsWith)) return false;
    return backupNamePrefixes.any(name.startsWith);
  }

  @override
  void build() {}

  String get backupDirectory => HivePrefUtil.getString(backupDirectoryKey) ?? '';

  Future<void> setBackupDirectory(String value) async {
    await HivePrefUtil.setString(backupDirectoryKey, value);
  }

  /// Where backups are written and listed from.
  ///
  /// The configured 备份目录 when the user picked one, otherwise the app
  /// documents directory. Both the create row and the backup list page resolve
  /// the directory here so they can never disagree about where the files are.
  Future<Directory> resolveBackupDirectory() async {
    final configured = backupDirectory;
    if (configured.isNotEmpty) {
      final directory = Directory(configured);
      if (!directory.existsSync()) {
        try {
          directory.createSync(recursive: true);
        } catch (_) {
          return getApplicationDocumentsDirectory();
        }
      }
      return directory;
    }
    return getApplicationDocumentsDirectory();
  }

  Map<String, dynamic> exportAllSettings({bool includeSensitiveData = true}) {
    final s = SettingsService.to;
    final data = <String, dynamic>{
      'backupVersion': backupVersion,
      // Lets the receiver of this document tell a TV from a phone: a TV-to-TV
      // transfer restores everything, anything else only the user-data sections.
      'platform': Platform.operatingSystem,
      'platformIsTv': true,
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
      data['cookie'] = s.cookieManager.toJson();
    }
    return data;
  }

  /// Strips session cookies — and the WebDAV credentials a backup imported from an older
  /// build may still carry — before a backup leaves the device.
  static Map<String, dynamic> redactSensitiveData(Map<String, dynamic> source) {
    final result = Map<String, dynamic>.from(source)
      ..remove('cookie')
      // The module is gone, but a file it wrote (or a peer's document) can still be
      // imported and re-exported; its passwords must not come along.
      ..remove('webdav');
    result['sensitiveDataIncluded'] = false;
    return result;
  }

  static int countConfigSections(Map<String, dynamic> data) {
    return knownSections.where(data.containsKey).length;
  }

  /// Rejects a malformed section before any controller persists it.
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
      // Legacy flat backup: any known key being present is enough to accept it.
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
      'cookie': s.cookieManager.importFromJson,
    };

    final sourceIsTv = BackupController.sourceIsTv(data);

    // Non-TV source: only 关注 / 历史记录 / Cookie / 标签 may land — a phone
    // must not rewrite the TV's own player, theme or proxy configuration.
    if (!sourceIsTv) {
      final tvParser = <String, void Function(Map<String, dynamic>)>{
        'favorite': s.fav.importFromJson,
        'history': s.history.importFromJson,
        'cookie': s.cookieManager.importFromJson,
      };
      if (version == null) {
        // Flat (mobile app) document: the accepted controllers read the whole map
        // and pick their own keys; the tags live under the legacy key.
        for (final parser in tvParser.values) {
          parser(data);
        }
        final legacyTags = data['custom_tags_data'];
        if (legacyTags is Map) {
          s.tag.importFromJson(Map<String, dynamic>.from(legacyTags));
        }
        return;
      }
      // Sectioned document from a non-TV build.
      for (final entry in tvParser.entries) {
        if (data.containsKey(entry.key)) {
          entry.value(Map<String, dynamic>.from(data[entry.key] ?? {}));
        }
      }
      final tags = data['tags'];
      if (tags is Map) {
        s.tag.importFromJson(Map<String, dynamic>.from(tags));
      }
      return;
    }

    if (version == null) {
      // Legacy flat backup: every controller reads the whole payload directly and
      // falls back to defaults for keys that are missing.
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

  /// Writes the settings document into [file].
  ///
  /// The file is the `.txt` the mobile app writes: same name shape, same indented JSON
  /// inside — a `.txt` filled with JSON is what "备份" means on both apps, so a phone
  /// backup opens here and a TV backup opens there.
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
