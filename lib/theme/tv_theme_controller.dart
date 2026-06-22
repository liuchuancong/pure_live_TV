import 'tv_theme_data.dart';
import 'themes/dark_theme.dart';
import 'themes/blue_theme.dart';
import 'themes/anime_theme.dart';
import 'themes/cyber_theme.dart';
import 'package:pure_live/utils/hive_pref_util.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'tv_theme_controller.g.dart';

@riverpod
class TvThemeController extends _$TvThemeController {
  final List<TvThemeData> themes = [darkTvTheme, blueTvTheme, animeTvTheme, cyberTvTheme];

  @override
  TvThemeData build() {
    final themeId = HivePrefUtil.getString('tvThemeId') ?? darkTvTheme.id;
    return themes.firstWhere((e) => e.id == themeId, orElse: () => darkTvTheme);
  }

  void switchTheme(TvThemeData theme) {
    HivePrefUtil.setString('tvThemeId', theme.id);
    state = theme;
  }

  void switchById(String id) {
    final targetTheme = themes.firstWhere((e) => e.id == id, orElse: () => darkTvTheme);
    switchTheme(targetTheme);
  }

  void importFromJson(Map<String, dynamic> json) {
    final id = json['currentThemeId'] ?? darkTvTheme.id;
    switchById(id);
  }

  Map<String, dynamic> toJson() {
    return {'currentThemeId': state.id};
  }

  static Map<String, dynamic> extractConfig(Map<String, dynamic>? rootConfig) {
    final theme = rootConfig?['tvTheme'] as Map<String, dynamic>? ?? {};
    return {'currentThemeId': theme['currentThemeId'] ?? darkTvTheme.id};
  }

  static Map<String, dynamic> mergeConfig(Map<String, dynamic> rootConfig, Map<String, dynamic> updateFields) {
    final tvTheme = Map<String, dynamic>.from(rootConfig['tvTheme'] ?? {});
    updateFields.forEach((k, v) => tvTheme[k] = v);
    rootConfig['tvTheme'] = tvTheme;
    return rootConfig;
  }
}
