import 'dart:async';

import 'danmaku_settings_model.dart';
import 'package:pure_live/services/settings/settings.dart';
import 'package:pure_live/shared/models/index.dart';
import 'package:pure_live/shared/i18n/locale_helper.dart';
import 'package:pure_live/shared/utils/toast_util.dart';
import 'package:pure_live/shared/platform/font_download_manager.dart';
import 'package:pure_live/shared/utils/hive_pref_util.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:pure_live/services/settings/settings_value.dart';

part 'danmaku_settings_controller.g.dart';

@riverpod
class DanmakuSettingsController extends _$DanmakuSettingsController {
  static DanmakuSettingsController get to => SettingsService.to.danmaku;

  static const String _familyKey = 'danmakuFontFamilyName';
  static const String _fileNameKey = 'danmakuFontFamilyFileName';

  /// The weight file the danmaku family is locked to, or `''` for the whole family.
  ///
  /// Device-local, like the app font's own weight lock, so it lives beside the family
  /// in Hive instead of in the shared settings model.
  String get danmakuFontFamilyFileName => HivePrefUtil.getString(_fileNameKey) ?? '';

  // Exposed as a reactive value for non-widget code such as the player core.
  SettingsValue<bool> get filterDouyuSuspectedAutomatedMessages =>
      SettingsValue(() => state.filterDouyuSuspectedAutomatedMessages);

  @override
  DanmakuSettingsModel build() {
    final model = DanmakuSettingsModel(
      hideDanmaku: HivePrefUtil.getBool('hideDanmaku') ?? false,
      noEmojiMode: HivePrefUtil.getBool('noEmojiMode') ?? false,
      danmakuTopArea: DanmakuSettingsModel.normalizeDistance(HivePrefUtil.getDouble('danmakuTopArea')),
      danmakuArea: (HivePrefUtil.getDouble('danmakuArea') ?? 1.0).clamp(
        DanmakuSettingsModel.minArea,
        DanmakuSettingsModel.maxArea,
      ),
      danmakuBottomArea: DanmakuSettingsModel.normalizeDistance(HivePrefUtil.getDouble('danmakuBottomArea')),
      danmakuSpeed: DanmakuSettingsModel.normalizeSpeed(HivePrefUtil.getDouble('danmakuSpeed')),
      danmakuFontSize: (HivePrefUtil.getDouble('danmakuFontSize') ?? 16.0).clamp(8.0, 72.0),
      danmakuFontWeight: DanmakuSettingsModel.normalizeFontWeight(HivePrefUtil.getInt('danmakuFontWeight')),
      danmakuFontBorder: (HivePrefUtil.getDouble('danmakuFontBorder') ?? 4.0).clamp(0.0, 8.0),
      danmakuOpacity: (HivePrefUtil.getDouble('danmakuOpacity') ?? 1.0).clamp(0.05, 1.0),
      enableDanmakuDisplay: HivePrefUtil.getBool('enableDanmakuDisplay') ?? true,
      enableDanmakuStroke: HivePrefUtil.getBool('enableDanmakuStroke') ?? true,
      danmakuFps: (HivePrefUtil.getInt('danmakuFps') ?? 60).clamp(30, 240),
      danmakuAutoFps: HivePrefUtil.getBool('danmakuAutoFps') ?? true,
      enableDanmakuTapInteraction: HivePrefUtil.getBool('enableDanmakuTapInteraction') ?? true,
      enableDanmakuLongPressInteraction: HivePrefUtil.getBool('enableDanmakuLongPressInteraction') ?? true,
      collapseRepeatedDanmaku: HivePrefUtil.getBool('collapseRepeatedDanmaku') ?? false,
      repeatedDanmakuWindowSeconds: HivePrefUtil.getInt('repeatedDanmakuWindowSeconds') ?? 5,
      danmakuInteractionMigration: HivePrefUtil.getInt('danmakuInteractionMigration') ?? 0,
      savedDanmakuTemplate: HivePrefUtil.getString('savedDanmakuTemplate') ?? '',
      danmakuFontFamilyName: HivePrefUtil.getString(_familyKey) ?? 'Default',
      enablePipDanmaku: HivePrefUtil.getBool('enablePipDanmaku') ?? true,
      pipDanmakuAutoScale: HivePrefUtil.getBool('pipDanmakuAutoScale') ?? true,
      pipDanmakuNoEmojiMode: HivePrefUtil.getBool('pipDanmaNoEmojiMode') ?? false,
      pipDanmakuUseOriginalColor: HivePrefUtil.getBool('pipDanmakuUseOriginalColor') ?? true,
      pipDanmakuColor: HivePrefUtil.getInt('pipDanmakuColor') ?? 0xFFFFFFFF,
      pipDanmakuFontSize: HivePrefUtil.getDouble('pipDanmakuFontSize') ?? 12.0,
      pipDanmakuFontWeight: HivePrefUtil.getInt('pipDanmakuFontWeight') ?? 500,
      pipDanmakuSpeed: HivePrefUtil.getDouble('pipDanmakuSpeed') ?? 90.0,
      pipDanmakuOpacity: HivePrefUtil.getDouble('pipDanmakuOpacity') ?? 0.9,
      pipDanmakuArea: HivePrefUtil.getDouble('pipDanmakuArea') ?? 0.5,
      pipDanmakuMaxVisibleCount: HivePrefUtil.getInt('pipDanmakuMaxVisibleCount') ?? 6,
      pipDanmakuEmitInterval: HivePrefUtil.getDouble('pipDanmakuEmitInterval') ?? 0.35,
      pipDanmakuFps: HivePrefUtil.getInt('pipDanmakuFps') ?? 30,
      pipDanmakuAutoFps: HivePrefUtil.getBool('pipDanmakuAutoFps') ?? true,
      filterDouyuSuspectedAutomatedMessages: HivePrefUtil.getBool('filterDouyuSuspectedAutomatedMessages') ?? true,
      enableDanmakuSimilarityFilter: HivePrefUtil.getBool('enableDanmakuSimilarityFilter') ?? false,
      danmakuSimilarityThreshold: HivePrefUtil.getInt('danmakuSimilarityThreshold') ?? 85,
      danmakuSimilarityCacheDuration: HivePrefUtil.getInt('danmakuSimilarityCacheDuration') ?? 3,
      danmakuSimilarityMaxCacheSize: HivePrefUtil.getInt('danmakuSimilarityMaxCacheSize') ?? 100,
    );

    // Re-register a previously downloaded danmaku font so danmaku renders in
    // it right after a restart, without a re-download (same lifecycle the app
    // font uses in FontSettingsController — weight lock and fallback included).
    final family = model.danmakuFontFamilyName;
    if (family != 'Default' && family.isNotEmpty) {
      unawaited(_restoreFontFamily(family));
    }
    return model;
  }

  /// Re-registers [family] after a restart, dropping to the bundled font when its files
  /// (or the weight it was locked to) are gone.
  Future<void> _restoreFontFamily(String family) async {
    try {
      if (!await FontDownloadManager.instance.checkFontDownloaded(family)) {
        await resetDanmakuFontFamily();
        return;
      }

      final String storedFile = danmakuFontFamilyFileName;
      bool loaded = await FontDownloadManager.instance.loadFont(family, fileName: storedFile);
      if (!loaded && storedFile.isNotEmpty) {
        // The locked weight was removed but the family is still usable.
        loaded = await FontDownloadManager.instance.loadFont(family);
        if (loaded) await HivePrefUtil.setString(_fileNameKey, '');
      }
      if (!loaded) await resetDanmakuFontFamily();
    } catch (_) {
      // Missing files fall back to the default family silently.
      await resetDanmakuFontFamily();
    }
  }

  /// Applies [font] to danmaku, optionally locked to a single weight file.
  ///
  /// Registration is verified first, so a family whose files are gone leaves the current
  /// danmaku font alone and only reports why.
  Future<bool> activateDanmakuFontFamily(FontModel font, {String? targetFileName}) async {
    final bool loaded = await FontDownloadManager.instance.loadFont(font.id, fileName: targetFileName ?? '');
    if (!loaded) {
      ToastUtil.show(i18n('font_not_downloaded_or_corrupted'));
      return false;
    }
    updateSettings(state.copyWith(danmakuFontFamilyName: font.id));
    await HivePrefUtil.setString(_fileNameKey, targetFileName ?? '');
    return true;
  }

  /// Drops danmaku back to the font bundled with the app.
  Future<void> resetDanmakuFontFamily() async {
    updateSettings(state.copyWith(danmakuFontFamilyName: 'Default'));
    await HivePrefUtil.setString(_fileNameKey, '');
  }

  /// Drops the danmaku selection when [fontId] is the family in force.
  Future<void> resetIfActive(String fontId) async {
    if (state.danmakuFontFamilyName == fontId) await resetDanmakuFontFamily();
  }

  void updateSettings(DanmakuSettingsModel newSettings) {
    state = newSettings;
    _persist();
  }

  void _persist() {
    HivePrefUtil.setBool('hideDanmaku', state.hideDanmaku);
    HivePrefUtil.setBool('noEmojiMode', state.noEmojiMode);
    HivePrefUtil.setDouble('danmakuTopArea', state.danmakuTopArea);
    HivePrefUtil.setDouble('danmakuArea', state.danmakuArea);
    HivePrefUtil.setDouble('danmakuBottomArea', state.danmakuBottomArea);
    HivePrefUtil.setDouble('danmakuSpeed', state.danmakuSpeed);
    HivePrefUtil.setDouble('danmakuFontSize', state.danmakuFontSize);
    HivePrefUtil.setInt('danmakuFontWeight', state.danmakuFontWeight);
    HivePrefUtil.setDouble('danmakuFontBorder', state.danmakuFontBorder);
    HivePrefUtil.setDouble('danmakuOpacity', state.danmakuOpacity);
    HivePrefUtil.setBool('enableDanmakuDisplay', state.enableDanmakuDisplay);
    HivePrefUtil.setBool('enableDanmakuStroke', state.enableDanmakuStroke);
    HivePrefUtil.setInt('danmakuFps', state.danmakuFps);
    HivePrefUtil.setBool('danmakuAutoFps', state.danmakuAutoFps);
    HivePrefUtil.setBool('enableDanmakuTapInteraction', state.enableDanmakuTapInteraction);
    HivePrefUtil.setBool('enableDanmakuLongPressInteraction', state.enableDanmakuLongPressInteraction);
    HivePrefUtil.setBool('collapseRepeatedDanmaku', state.collapseRepeatedDanmaku);
    HivePrefUtil.setInt('repeatedDanmakuWindowSeconds', state.repeatedDanmakuWindowSeconds);
    HivePrefUtil.setInt('danmakuInteractionMigration', state.danmakuInteractionMigration);
    HivePrefUtil.setString('savedDanmakuTemplate', state.savedDanmakuTemplate);
    HivePrefUtil.setString('danmakuFontFamilyName', state.danmakuFontFamilyName);
    HivePrefUtil.setBool('enablePipDanmaku', state.enablePipDanmaku);
    HivePrefUtil.setBool('pipDanmakuAutoScale', state.pipDanmakuAutoScale);
    HivePrefUtil.setBool('pipDanmaNoEmojiMode', state.pipDanmakuNoEmojiMode);
    HivePrefUtil.setBool('pipDanmakuUseOriginalColor', state.pipDanmakuUseOriginalColor);
    HivePrefUtil.setInt('pipDanmakuColor', state.pipDanmakuColor);
    HivePrefUtil.setDouble('pipDanmakuFontSize', state.pipDanmakuFontSize);
    HivePrefUtil.setInt('pipDanmakuFontWeight', state.pipDanmakuFontWeight);
    HivePrefUtil.setDouble('pipDanmakuSpeed', state.pipDanmakuSpeed);
    HivePrefUtil.setDouble('pipDanmakuOpacity', state.pipDanmakuOpacity);
    HivePrefUtil.setDouble('pipDanmakuArea', state.pipDanmakuArea);
    HivePrefUtil.setInt('pipDanmakuMaxVisibleCount', state.pipDanmakuMaxVisibleCount);
    HivePrefUtil.setDouble('pipDanmakuEmitInterval', state.pipDanmakuEmitInterval);
    HivePrefUtil.setInt('pipDanmakuFps', state.pipDanmakuFps);
    HivePrefUtil.setBool('pipDanmakuAutoFps', state.pipDanmakuAutoFps);
    HivePrefUtil.setBool('filterDouyuSuspectedAutomatedMessages', state.filterDouyuSuspectedAutomatedMessages);
    HivePrefUtil.setBool('enableDanmakuSimilarityFilter', state.enableDanmakuSimilarityFilter);
    HivePrefUtil.setInt('danmakuSimilarityThreshold', state.danmakuSimilarityThreshold);
    HivePrefUtil.setInt('danmakuSimilarityCacheDuration', state.danmakuSimilarityCacheDuration);
    HivePrefUtil.setInt('danmakuSimilarityMaxCacheSize', state.danmakuSimilarityMaxCacheSize);
  }

  /// Applies a backup/peer document, clamped into the engine's units.
  ///
  /// `DanmakuSettingsModel.fromJson` keeps whatever the document says — including the
  /// mobile app's own defaults, or an old install's "speed level" — so the value goes
  /// through the same bounds the Hive read does before it can reach the renderer.
  void importFromJson(Map<String, dynamic> json) {
    final imported = DanmakuSettingsModel.fromJson(json);
    state = imported.copyWith(
      danmakuTopArea: DanmakuSettingsModel.normalizeDistance(imported.danmakuTopArea),
      danmakuBottomArea: DanmakuSettingsModel.normalizeDistance(imported.danmakuBottomArea),
      danmakuSpeed: DanmakuSettingsModel.normalizeSpeed(imported.danmakuSpeed),
      danmakuArea: imported.danmakuArea.clamp(DanmakuSettingsModel.minArea, DanmakuSettingsModel.maxArea),
      danmakuFontSize: imported.danmakuFontSize.clamp(8.0, 72.0),
      danmakuFontWeight: DanmakuSettingsModel.normalizeFontWeight(imported.danmakuFontWeight),
      danmakuFontBorder: imported.danmakuFontBorder.clamp(0.0, 8.0),
      danmakuOpacity: imported.danmakuOpacity.clamp(0.05, 1.0),
      danmakuFps: imported.danmakuFps.clamp(30, 240),
    );
    _persist();
  }

  Map<String, dynamic> toJson() => state.toJson();
}
