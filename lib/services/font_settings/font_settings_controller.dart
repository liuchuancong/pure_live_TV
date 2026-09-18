import 'dart:convert';
import 'dart:io';
import 'package:path/path.dart' as p;
import 'font_settings_model.dart';
import 'package:flutter/services.dart';
import 'package:pure_live/app/bootstrap/app_path_manager.dart';
import 'package:pure_live/exports/common_export.dart';
import 'package:pure_live/services/settings/settings.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'font_settings_controller.g.dart';

@riverpod
class FontSettingsController extends _$FontSettingsController {
  static FontSettingsController get to => SettingsService.to.font;

  /// The cloud-font manifest bundled with the app.
  List<FontModel> fontList = [];

  /// Disk usage of every downloaded family, e.g. `{'SourceHanSans': '12.4 MB'}`.
  ///
  /// A family being present here *is* what "downloaded" means for the manager page —
  /// the same source of truth the mobile app uses (`fontFolderSizes`), so a family
  /// deleted behind the app's back stops looking installed on the next refresh.
  Map<String, String> fontFolderSizes = <String, String>{};

  static const String _familyKey = 'fontFamilyName';
  static const String _fileNameKey = 'fontFamilyFileName';

  DateTime? _lastDiskSizeRefresh;
  Future<void>? _diskSizeRefresh;

  /// The weight file the active family is locked to, or `''` for the whole family.
  ///
  /// Kept in Hive next to the family rather than in [FontSettingsModel]: the model is
  /// mirrored into the settings file the desktop app reads, and this is device-local,
  /// exactly as on mobile.
  String get fontFamilyFileName => HivePrefUtil.getString(_fileNameKey) ?? '';

  /// Whether a downloaded family (not the bundled one) is in force.
  bool get hasCustomFamily {
    final String id = state.value?.fontFamilyName ?? 'Default';
    return id != 'Default' && id.isNotEmpty;
  }

  @override
  Future<FontSettingsModel> build() async {
    await _loadInitialFontManifest();
    // Restore before the model is built: the lifecycle below may fall back to the
    // bundled font, and the model has to carry the value the app will actually render.
    await _restoreFontFamily(HivePrefUtil.getString(_familyKey) ?? 'Default');

    return FontSettingsModel(
      textScaleFactor: HivePrefUtil.getDouble('textScaleFactor') ?? 1.0,
      fontSizeBodySmall: HivePrefUtil.getDouble('fontSizeBodySmall') ?? 12.0,
      fontSizeBodyMedium: HivePrefUtil.getDouble('fontSizeBodyMedium') ?? 13.0,
      fontSizeBodyLarge: HivePrefUtil.getDouble('fontSizeBodyLarge') ?? 14.0,
      fontSizeTitleMedium: HivePrefUtil.getDouble('fontSizeTitleMedium') ?? 15.0,
      fontSizeTitleLarge: HivePrefUtil.getDouble('fontSizeTitleLarge') ?? 20.0,
      fontFamilyName: HivePrefUtil.getString(_familyKey) ?? 'Default',
    );
  }

  Future<void> _loadInitialFontManifest() async {
    try {
      final jsonStr = await rootBundle.loadString('assets/fonts/fonts-manifest.json');
      final list = jsonDecode(jsonStr) as List;
      fontList = list.map((e) => FontModel.fromJson(e)).toList();
    } catch (_) {}
  }

  /// Re-registers the family in force after a restart, and falls back to the bundled
  /// font when it cannot be rendered any more.
  ///
  /// Three cases, all of them the mobile app's startup lifecycle: the family's files
  /// are gone, the weight it was locked to is gone, or everything is fine. The stored
  /// weight is cleared whenever it had to be dropped, so the next start does not retry
  /// a file that is not there. Without this a restart showed the family name in settings
  /// while every glyph fell back to the platform font font missing after restart.
  Future<void> _restoreFontFamily(String id) async {
    if (id == 'Default' || id.isEmpty) return;

    final String storedFile = fontFamilyFileName;
    if (!await FontDownloadManager.instance.checkFontDownloaded(id)) {
      await _clearFamily();
      return;
    }

    bool loaded = await FontDownloadManager.instance.loadFont(id, fileName: storedFile);
    if (!loaded && storedFile.isNotEmpty) {
      // The locked weight was removed but the family is still usable: keep the family
      // and drop the lock.
      loaded = await FontDownloadManager.instance.loadFont(id);
      if (loaded) await HivePrefUtil.setString(_fileNameKey, '');
    }
    if (!loaded) await _clearFamily();
  }

  Future<void> _clearFamily() async {
    await HivePrefUtil.setString(_familyKey, 'Default');
    await HivePrefUtil.setString(_fileNameKey, '');
  }

  Future<void> updateSettings(FontSettingsModel newModel) async {
    state = AsyncData(newModel);
    HivePrefUtil.setDouble('textScaleFactor', newModel.textScaleFactor);
    HivePrefUtil.setDouble('fontSizeBodySmall', newModel.fontSizeBodySmall);
    HivePrefUtil.setDouble('fontSizeBodyMedium', newModel.fontSizeBodyMedium);
    HivePrefUtil.setDouble('fontSizeBodyLarge', newModel.fontSizeBodyLarge);
    HivePrefUtil.setDouble('fontSizeTitleMedium', newModel.fontSizeTitleMedium);
    HivePrefUtil.setDouble('fontSizeTitleLarge', newModel.fontSizeTitleLarge);
    HivePrefUtil.setString(_familyKey, newModel.fontFamilyName);
  }

  /// Applies [fontModel], optionally locked to a single weight file.
  ///
  /// The family is registered **before** anything is persisted, so a family whose files
  /// are gone — or a weight that is missing — leaves the current selection alone and
  /// only says why (the mobile app's `activateFontFamily`).
  Future<bool> activateFontFamily(FontModel fontModel, {String? targetFileName}) async {
    final bool loaded = await FontDownloadManager.instance.loadFont(fontModel.id, fileName: targetFileName ?? '');
    if (!loaded) {
      ToastUtil.show(i18n('font_not_downloaded_or_corrupted'));
      return false;
    }

    final FontSettingsModel? current = state.value;
    if (current != null) {
      await updateSettings(current.copyWith(fontFamilyName: fontModel.id));
    } else {
      await HivePrefUtil.setString(_familyKey, fontModel.id);
    }
    await HivePrefUtil.setString(_fileNameKey, targetFileName ?? '');

    if (targetFileName != null) {
      ToastUtil.show(
        i18n(
          'font_toast_exclusive',
          args: {'name': fontModel.name, 'subName': FontDownloadManager.weightLabelOf(targetFileName)},
        ),
      );
    } else {
      ToastUtil.show(i18n('font_toast_global', args: {'name': fontModel.name}));
    }
    return true;
  }

  /// Drops back to the font bundled with the app.
  Future<void> resetAppFontFamily() async {
    final FontSettingsModel? current = state.value;
    if (current != null) {
      await updateSettings(current.copyWith(fontFamilyName: 'Default'));
    } else {
      await HivePrefUtil.setString(_familyKey, 'Default');
    }
    await HivePrefUtil.setString(_fileNameKey, '');
  }

  /// Deletes the downloaded files of [font], dropping the selection when it was the one
  /// in force. The danmaku family is handled by its own controller.
  Future<void> uninstallFontFamily(FontModel font) async {
    await FontDownloadManager.instance.deleteFontFamily(font, (_) {});
    if (state.value?.fontFamilyName == font.id) await resetAppFontFamily();
    await refreshFontDiskSizes(force: true);
  }

  /// Re-reads the size of every downloaded family, at most once every 30 seconds.
  ///
  /// The page calls this on open and after a download/delete; the throttle keeps the
  /// directory walk off the frame budget when the page is rebuilt repeatedly.
  Future<void> refreshFontDiskSizes({bool force = false}) {
    final Future<void>? inFlight = _diskSizeRefresh;
    if (inFlight != null) return inFlight;

    final DateTime? last = _lastDiskSizeRefresh;
    if (!force && last != null && DateTime.now().difference(last) < const Duration(seconds: 30)) {
      return Future<void>.value();
    }

    final Future<void> refresh = _readFontDiskSizes();
    _diskSizeRefresh = refresh;
    return refresh.whenComplete(() {
      if (identical(_diskSizeRefresh, refresh)) _diskSizeRefresh = null;
    });
  }

  Future<void> _readFontDiskSizes() async {
    final Directory fontRoot = await AppPathManager().fontRootDir;
    final Map<String, String> nextSizes = <String, String>{};

    await for (final entity in fontRoot.list()) {
      if (entity is! Directory) continue;
      int bytes = 0;
      await for (final file in entity.list(recursive: true)) {
        if (file is File) bytes += await file.length();
      }
      // A folder of empty files is a dead download, not an installed family.
      if (bytes <= 0) continue;
      nextSizes[p.basename(entity.path)] = '${(bytes / 1024 / 1024).toStringAsFixed(1)} MB';
    }

    fontFolderSizes = nextSizes;
    _lastDiskSizeRefresh = DateTime.now();
  }

  void importFromJson(Map<String, dynamic> json) {
    state = AsyncData(FontSettingsModel.fromJson(json));
  }

  Map<String, dynamic> toJson() {
    return state.value?.toJson() ?? const FontSettingsModel().toJson();
  }
}
