import 'dart:io';
import 'dart:convert';
import 'package:pure_live/services/settings/settings.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'backup_controller.g.dart';

@riverpod
class BackupController extends _$BackupController {
  static const int backupVersion = 2;

  @override
  void build() {}

  Map<String, dynamic> exportAllSettings() {
    final s = SettingsService.to;
    return {
      'backupVersion': backupVersion,
      'app': s.app.toJson(),
      'theme': s.theme.toJson(),
      'font': s.font.toJson(),
      'player': s.player.toJson(),
      'danmaku': s.danmaku.toJson(),
      'volume': s.volume.toJson(),
      'favorite': s.fav.toJson(),
      'history': s.history.toJson(),
      'webdav': s.webDav.toJson(),
      'iptv': s.iptv.toJson(),
      'cookie': s.cookieManager.toJson(),
      'proxy': s.proxy.toJson(),
      'exit': s.exit.toJson(),
      'startup': s.startup.toJson(),
      'tags': s.tag.toJson(),
      'refresh': s.refresh.toJson(),
      'page': s.page.toJson(),
    };
  }

  void importAllSettings(Map<String, dynamic> data) {
    final s = SettingsService.to;

    if (data.containsKey('app')) s.app.importFromJson(Map<String, dynamic>.from(data['app']));
    if (data.containsKey('theme')) s.theme.importFromJson(Map<String, dynamic>.from(data['theme']));
    if (data.containsKey('font')) s.font.importFromJson(Map<String, dynamic>.from(data['font']));
    if (data.containsKey('player')) s.player.importFromJson(Map<String, dynamic>.from(data['player']));
    if (data.containsKey('danmaku')) s.danmaku.importFromJson(Map<String, dynamic>.from(data['danmaku']));
    if (data.containsKey('volume')) s.volume.importFromJson(Map<String, dynamic>.from(data['volume']));
    if (data.containsKey('favorite')) s.fav.importFromJson(Map<String, dynamic>.from(data['favorite']));
    if (data.containsKey('history')) s.history.importFromJson(Map<String, dynamic>.from(data['history']));
    if (data.containsKey('webdav')) s.webDav.importFromJson(Map<String, dynamic>.from(data['webdav']));
    if (data.containsKey('iptv')) s.iptv.importFromJson(Map<String, dynamic>.from(data['iptv']));
    if (data.containsKey('cookie')) s.cookieManager.importFromJson(Map<String, dynamic>.from(data['cookie']));
    if (data.containsKey('proxy')) s.proxy.importFromJson(Map<String, dynamic>.from(data['proxy']));
    if (data.containsKey('exit')) s.exit.importFromJson(Map<String, dynamic>.from(data['exit']));
    if (data.containsKey('startup')) s.startup.importFromJson(Map<String, dynamic>.from(data['startup']));
    if (data.containsKey('refresh')) s.refresh.importFromJson(Map<String, dynamic>.from(data['refresh']));
    if (data.containsKey('page')) s.page.importFromJson(Map<String, dynamic>.from(data['page']));
    if (data.containsKey('tags')) s.tag.importFromJson(Map<String, dynamic>.from(data['tags']));
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

  bool recover(File file) {
    try {
      final json = file.readAsStringSync();
      final data = jsonDecode(json);
      if (data is! Map<String, dynamic>) return false;
      importAllSettings(data);
      return true;
    } catch (_) {
      return false;
    }
  }
}
