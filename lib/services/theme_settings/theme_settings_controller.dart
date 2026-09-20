import 'theme_settings_model.dart';
import 'package:flutter/material.dart';
import 'package:pure_live/exports/common_export.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:pure_live/services/settings/settings.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'theme_settings_controller.g.dart';

@riverpod
class ThemeSettingsController extends _$ThemeSettingsController {
  static ThemeSettingsController get to => SettingsService.to.theme;

  static const String defaultThemeModeName = 'System';
  static const String defaultLanguageName = '简体中文';
  static const double defaultSpacing = 6;
  static const double minSpacing = 0;
  static const double maxSpacing = 64;
  static const int defaultRoomCardColumns = 4;

  /// Dense-room-layout levels, as grid columns: standard / dense.
  static const List<int> roomCardColumnsOptions = <int>[4, 5];

  /// Grid cell aspect (width / height) for the room-card grids at [columns].
  ///
  /// Denser levels make every cell narrower; a fixed ratio would then leave too
  /// little height under the 16:9 cover for the info row (a bottom overflow),
  /// so the cell relatively heightens as the density grows.
  static double roomCardAspectRatio(int columns) => switch (columns) {
    5 => 1.25,
    _ => 1.3,
  };

  static bool _hasSwitchedOnce = false;
  static final Set<String> _loadingStyleKeys = AppConsts.allStyles
      .map((item) => item['key'] ?? '')
      .where((key) => key.isNotEmpty)
      .toSet();

  @override
  ThemeSettingsModel build() {
    final savedJson = HivePrefUtil.getObject(
      'theme_settings',
      (json) => json as Map<String, dynamic>,
    );
    final model = savedJson != null
        ? ThemeSettingsModel.fromJson(savedJson)
        : const ThemeSettingsModel();
    return _normalize(model);
  }

  /// Repairs stored visual settings that another build or an imported backup
  /// can leave outside the supported range.
  ///
  /// An unknown theme mode or loading style would render nothing at all, and an
  /// unbounded grid spacing makes the room grids unreadable.
  static ThemeSettingsModel _normalize(ThemeSettingsModel model) {
    return model.copyWith(
      themeModeName: normalizeThemeMode(model.themeModeName),
      languageName: normalizeLanguage(model.languageName),
      loadingStyle: normalizeLoadingStyle(model.loadingStyle),
      crossAxisSpacing: normalizeSpacing(model.crossAxisSpacing),
      mainAxisSpacing: normalizeSpacing(model.mainAxisSpacing),
      denseRoomLayout: normalizeRoomCardColumns(model.denseRoomLayout),
    );
  }

  /// Matches a stored mode against [AppConsts.themeModes] ignoring case.
  static String normalizeThemeMode(String value) {
    final normalized = value.trim().toLowerCase();
    return AppConsts.themeModes.keys.firstWhere(
      (candidate) => candidate.toLowerCase() == normalized,
      orElse: () => defaultThemeModeName,
    );
  }

  /// Matches a stored language against [AppConsts.languages] ignoring case.
  static String normalizeLanguage(String value) {
    final normalized = value.trim().toLowerCase();
    return AppConsts.languages.keys.firstWhere(
      (candidate) => candidate.toLowerCase() == normalized,
      orElse: () => defaultLanguageName,
    );
  }

  static String normalizeLoadingStyle(String value) {
    final normalized = value.trim();
    return _loadingStyleKeys.contains(normalized)
        ? normalized
        : AppConsts.defaultLoadingStyleKey;
  }

  static double normalizeSpacing(num value) {
    final converted = value.toDouble();
    if (!converted.isFinite) return defaultSpacing;
    return converted.clamp(minSpacing, maxSpacing).toDouble();
  }

  /// Stored/imported column counts snap to the nearest offered option.
  static int normalizeRoomCardColumns(num value) {
    final converted = value.toDouble();
    if (!converted.isFinite) return defaultRoomCardColumns;
    return roomCardColumnsOptions.reduce(
      (a, b) => (converted - a).abs() <= (converted - b).abs() ? a : b,
    );
  }

  void updateSettings(ThemeSettingsModel newModel) {
    state = _normalize(newModel);
    _persist();
  }

  void changeThemeMode(String mode) {
    updateSettings(state.copyWith(themeModeName: mode));
  }

  void changeThemeColor(Color color) {
    updateSettings(state.copyWith(themeColor: color));
  }

  Future<void> changeLanguageWithRetry(
    BuildContext context, {
    required String languageName,
  }) async {
    changeLanguage(languageName);

    final targetLocale = AppConsts.languages[languageName];
    if (targetLocale == null) return;
    if (!_hasSwitchedOnce) {
      final pivotLanguage = AppConsts.languages.keys.firstWhere(
        (key) => key != languageName,
        orElse: () => languageName,
      );
      final pivotLocale = AppConsts.languages[pivotLanguage]!;
      await context.setLocale(Locale(targetLocale.languageCode));
      // ignore: use_build_context_synchronously
      await context.setLocale(Locale(pivotLocale.languageCode));
      // ignore: use_build_context_synchronously
      await context.setLocale(Locale(targetLocale.languageCode));

      _hasSwitchedOnce = true;
    } else {
      // succeeds on the next attempt
      await context.setLocale(Locale(targetLocale.languageCode));
    }
  }

  void changeLanguage(String lang) {
    updateSettings(state.copyWith(languageName: lang));
  }

  void changeSpacing({double? crossAxis, double? mainAxis}) {
    updateSettings(
      state.copyWith(
        crossAxisSpacing: crossAxis ?? state.crossAxisSpacing,
        mainAxisSpacing: mainAxis ?? state.mainAxisSpacing,
      ),
    );
  }

  void _persist() {
    HivePrefUtil.setObject('theme_settings', state.toJson());
  }

  // Accessor helpers
  ThemeMode get themeMode =>
      AppConsts.themeModes[state.themeModeName] ?? ThemeMode.system;
  Locale get locale =>
      AppConsts.languages[state.languageName] ?? const Locale('zh', 'CN');

  // Backup and restore
  Map<String, dynamic> toJson() => state.toJson();

  void importFromJson(Map<String, dynamic> json) {
    updateSettings(ThemeSettingsModel.fromJson(json));
  }
}
