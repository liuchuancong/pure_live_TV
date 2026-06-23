import 'dart:convert';
import 'font_settings_model.dart';
import 'package:flutter/services.dart';
import 'package:pure_live/utils/hive_pref_util.dart';
import 'package:pure_live/services/settings/settings.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:pure_live/plugins/font_download_manager.dart';
import 'package:pure_live/core/models/font_model/font_model.dart';

part 'font_settings_controller.g.dart';

@riverpod
class FontSettingsController extends _$FontSettingsController {
  static FontSettingsController get to => SettingsService.to.font;

  List<FontModel> fontList = [];

  @override
  Future<FontSettingsModel> build() async {
    await _loadInitialFontManifest();

    final model = FontSettingsModel(
      textScaleFactor: HivePrefUtil.getDouble('textScaleFactor') ?? 1.0,
      fontSizeBodySmall: HivePrefUtil.getDouble('fontSizeBodySmall') ?? 12.0,
      fontSizeBodyMedium: HivePrefUtil.getDouble('fontSizeBodyMedium') ?? 13.0,
      fontSizeBodyLarge: HivePrefUtil.getDouble('fontSizeBodyLarge') ?? 14.0,
      fontSizeTitleMedium: HivePrefUtil.getDouble('fontSizeTitleMedium') ?? 15.0,
      fontSizeTitleLarge: HivePrefUtil.getDouble('fontSizeTitleLarge') ?? 20.0,
      fontFamilyName: HivePrefUtil.getString('fontFamilyName') ?? 'Default',
    );

    await _initUserFontLifecycle(model.fontFamilyName);
    return model;
  }

  Future<void> _loadInitialFontManifest() async {
    try {
      final jsonStr = await rootBundle.loadString('assets/fonts/fonts-manifest.json');
      final list = jsonDecode(jsonStr) as List;
      fontList = list.map((e) => FontModel.fromJson(e)).toList();
    } catch (_) {}
  }

  Future<void> _initUserFontLifecycle(String id) async {
    if (id != 'Default' && await FontDownloadManager.instance.checkFontDownloaded(id)) {
      await FontDownloadManager.instance.loadFont(id);
    }
  }

  Future<void> updateSettings(FontSettingsModel newModel) async {
    state = AsyncData(newModel);
    HivePrefUtil.setDouble('textScaleFactor', newModel.textScaleFactor);
    HivePrefUtil.setDouble('fontSizeBodySmall', newModel.fontSizeBodySmall);
    HivePrefUtil.setDouble('fontSizeBodyMedium', newModel.fontSizeBodyMedium);
    HivePrefUtil.setDouble('fontSizeBodyLarge', newModel.fontSizeBodyLarge);
    HivePrefUtil.setDouble('fontSizeTitleMedium', newModel.fontSizeTitleMedium);
    HivePrefUtil.setDouble('fontSizeTitleLarge', newModel.fontSizeTitleLarge);
    HivePrefUtil.setString('fontFamilyName', newModel.fontFamilyName);
  }

  Future<void> activateFontFamily(FontModel fontModel, {String? targetFileName}) async {
    final current = state.value!;
    await updateSettings(current.copyWith(fontFamilyName: fontModel.id));
    await FontDownloadManager.instance.loadFont(fontModel.id, fileName: targetFileName ?? '');
  }

  void importFromJson(Map<String, dynamic> json) {
    state = AsyncData(FontSettingsModel.fromJson(json));
  }

  Map<String, dynamic> toJson() {
    return state.value?.toJson() ?? const FontSettingsModel().toJson();
  }
}
