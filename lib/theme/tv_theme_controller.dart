import 'tv_theme_data.dart';
import 'themes/dark_theme.dart';
import 'themes/blue_theme.dart';
import 'themes/anime_theme.dart';
import 'themes/cyber_theme.dart';
import 'package:pure_live/common/index.dart';

class TvThemeController extends GetxController {
  static TvThemeController get to => Get.find();

  final RxString currentThemeId = hiveString('tvThemeId', darkTvTheme.id);

  TvThemeData get currentTheme {
    return themes.firstWhere((e) => e.id == currentThemeId.value, orElse: () => darkTvTheme);
  }

  final List<TvThemeData> themes = [darkTvTheme, blueTvTheme, animeTvTheme, cyberTvTheme];

  void switchTheme(TvThemeData theme) {
    currentThemeId.value = theme.id;
  }

  void switchById(String id) {
    final theme = themes.firstWhere((e) => e.id == id, orElse: () => darkTvTheme);
    currentThemeId.value = theme.id;
  }

  Map<String, dynamic> toJson() {
    return {'currentThemeId': currentThemeId.value};
  }

  void fromJson(Map<String, dynamic> json) {
    currentThemeId.value = json['currentThemeId'] ?? darkTvTheme.id;
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
