import 'app_settings_model.dart';
import 'package:flutter/foundation.dart';
import 'package:pure_live/platforms/sites.dart';
import 'package:pure_live/shared/consts/app_consts.dart';
import 'package:pure_live/shared/models/live_room/live_room.dart';
import 'package:pure_live/shared/utils/hive_pref_util.dart';
import 'package:pure_live/services/settings/settings.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'app_settings_controller.g.dart';

@riverpod
class AppSettingsController extends _$AppSettingsController {
  static AppSettingsController get to => SettingsService.to.app;

  /// Platforms whose public API exposes a concurrent audience count, so
  /// concurrent mode has a real number to show out of the box.
  static const List<String> defaultRealOnlinePlatforms = [
    Sites.douyinSite,
    Sites.kuaishouSite,
    Sites.ccSite,
    Sites.twitchSite,
    Sites.soopSite,
    Sites.acfunSite,
    Sites.picartoSite,
    Sites.twitcastingSite,
    Sites.openrecSite,
    Sites.ttingSite,
  ];

  @override
  AppSettingsModel build() {
    return AppSettingsModel(
      autoRefreshTime: HivePrefUtil.getInt('autoRefreshTime') ?? 3,
      enableDenseFavorites: HivePrefUtil.getBool('enableDenseFavorites') ?? true,
      enableBackgroundPlay: HivePrefUtil.getBool('enableBackgroundPlay') ?? false,
      enableRotateScreen: HivePrefUtil.getBool('enableRotateScreen') ?? false,
      enableScreenKeepOn: HivePrefUtil.getBool('enableScreenKeepOn') ?? true,
      enableAutoCheckUpdate: HivePrefUtil.getBool('enableAutoCheckUpdate') ?? true,
      enableFullScreenDefault: HivePrefUtil.getBool('enableFullScreenDefault') ?? false,
      showSplashPage: HivePrefUtil.getBool('showSplashPage') ?? true,
      enableAsmrSleepMode: HivePrefUtil.getBool('enableAsmrSleepMode') ?? false,
      asmrSleepMinutes: HivePrefUtil.getInt('asmrSleepMinutes') ?? 60,
      useGitHubOriginForUpdates: HivePrefUtil.getBool('useGitHubOriginForUpdates') ?? false,
      refreshRateMode: HivePrefUtil.getString('refreshRateMode') ?? '',
      preferRealOnlineCounts: HivePrefUtil.getBool('preferRealOnlineCounts') ?? false,
      realOnlinePlatforms: normalizeRealOnlinePlatforms(
        HivePrefUtil.getStringList('realOnlinePlatforms') ?? defaultRealOnlinePlatforms,
      ),
      audienceMetricMigration: HivePrefUtil.getInt('audienceMetricMigration') ?? 0,
      enableMultiView: HivePrefUtil.getBool('enableMultiView') ?? true,
      enableNewWindowPlay: HivePrefUtil.getBool('enableNewWindowPlay') ?? true,
      savedMenuIds: HivePrefUtil.getStringList('savedMenuIds') ?? [],
    );
  }

  void update(AppSettingsModel newModel) {
    // Only concurrent-capable platforms may stay selected, so a stored or
    // imported entry can never present a heat value as a real audience.
    state = newModel.copyWith(realOnlinePlatforms: normalizeRealOnlinePlatforms(newModel.realOnlinePlatforms));
    _persist();
  }

  /// Visible menu ids in display order; an empty stored list means "all menus
  /// in the default order".
  static List<String> normalizeMenuIds(List<String> ids) {
    final known = HomeMenu.defaultOrder;
    final result = <String>[for (final id in ids) if (known.contains(id)) id];
    for (final id in known) {
      if (!result.contains(id)) result.add(id);
    }
    return result;
  }

  /// Repairs a stored or imported platform list: trimmed, lower-cased and
  /// limited to platforms that publish a concurrent audience count.
  static List<String> normalizeRealOnlinePlatforms(Iterable<String> platforms) {
    return platforms
        .map((platform) => platform.trim().toLowerCase())
        .where((platform) => LiveRoom.audienceCapabilityFor(platform).supportsConcurrentOnline)
        .toSet()
        .toList();
  }

  /// Selected platforms after dropping entries this build no longer supports.
  List<String> get resolvedRealOnlinePlatforms => normalizeRealOnlinePlatforms(state.realOnlinePlatforms);

  bool isRealOnlineEnabledFor(String? platform) =>
      resolvedRealOnlinePlatforms.contains(platform?.trim().toLowerCase());

  void setRealOnlineEnabledFor(String platform, bool enabled) {
    final normalized = platform.trim().toLowerCase();
    if (!LiveRoom.audienceCapabilityFor(normalized).supportsConcurrentOnline) return;
    final next = resolvedRealOnlinePlatforms;
    if (enabled) {
      if (!next.contains(normalized)) next.add(normalized);
    } else {
      next.remove(normalized);
    }
    update(state.copyWith(realOnlinePlatforms: next));
  }

  /// Moves [menuId] by [delta] positions inside the visible list.
  void moveMenu(String menuId, int delta) {
    final current = _visibleMenuIds();
    final index = current.indexOf(menuId);
    final target = index + delta;
    if (index < 0 || target < 0 || target >= current.length) return;
    update(state.copyWith(savedMenuIds: reorderMenuIds(current, menuId, target)));
  }

  /// Puts [menuId] at [targetIndex] of the visible list, shifting the entries it
  /// passes.
  ///
  /// This is the 排序 page's "pick an entry, then name its position" move: the
  /// entry the user chose lands exactly where they said, instead of being nudged
  /// there one step at a time.
  void moveMenuTo(String menuId, int targetIndex) {
    final current = _visibleMenuIds();
    final next = reorderMenuIds(current, menuId, targetIndex);
    if (listEquals(next, current)) return;
    update(state.copyWith(savedMenuIds: next));
  }

  /// The visible entries in display order, stored or defaulted.
  List<String> _visibleMenuIds() =>
      state.savedMenuIds.isEmpty ? List<String>.from(HomeMenu.defaultOrder) : normalizeMenuIds(state.savedMenuIds);

  /// [ids] with [menuId] placed at [targetIndex]; the entries it passes shift by
  /// one and nothing is dropped.
  ///
  /// Pure on purpose: the reorder rule is what the 排序 page promises, and this
  /// way it is testable without the preference store. [targetIndex] is clamped,
  /// and an unknown [menuId] leaves [ids] untouched.
  static List<String> reorderMenuIds(List<String> ids, String menuId, int targetIndex) {
    final index = ids.indexOf(menuId);
    if (index < 0 || ids.isEmpty) return List<String>.from(ids);
    final target = targetIndex.clamp(0, ids.length - 1);
    if (target == index) return List<String>.from(ids);
    final next = List<String>.from(ids)..removeAt(index);
    next.insert(target, menuId);
    return next;
  }

  void toggleMenuVisibility(String menuId, bool visible) {
    final ids = List<String>.from(state.savedMenuIds);
    if (visible) {
      if (!ids.contains(menuId)) ids.add(menuId);
    } else {
      ids.remove(menuId);
    }
    update(state.copyWith(savedMenuIds: ids));
  }

  void _persist() {
    HivePrefUtil.setInt('autoRefreshTime', state.autoRefreshTime);
    HivePrefUtil.setBool('enableDenseFavorites', state.enableDenseFavorites);
    HivePrefUtil.setBool('enableBackgroundPlay', state.enableBackgroundPlay);
    HivePrefUtil.setBool('enableRotateScreen', state.enableRotateScreen);
    HivePrefUtil.setBool('enableScreenKeepOn', state.enableScreenKeepOn);
    HivePrefUtil.setBool('enableAutoCheckUpdate', state.enableAutoCheckUpdate);
    HivePrefUtil.setBool('enableFullScreenDefault', state.enableFullScreenDefault);
    HivePrefUtil.setBool('showSplashPage', state.showSplashPage);
    HivePrefUtil.setStringList('savedMenuIds', state.savedMenuIds);
    HivePrefUtil.setBool('enableAsmrSleepMode', state.enableAsmrSleepMode);
    HivePrefUtil.setInt('asmrSleepMinutes', state.asmrSleepMinutes);
    HivePrefUtil.setBool('useGitHubOriginForUpdates', state.useGitHubOriginForUpdates);
    HivePrefUtil.setString('refreshRateMode', state.refreshRateMode);
    HivePrefUtil.setBool('preferRealOnlineCounts', state.preferRealOnlineCounts);
    HivePrefUtil.setStringList('realOnlinePlatforms', resolvedRealOnlinePlatforms);
    HivePrefUtil.setInt('audienceMetricMigration', state.audienceMetricMigration);
    HivePrefUtil.setBool('enableMultiView', state.enableMultiView);
    HivePrefUtil.setBool('enableNewWindowPlay', state.enableNewWindowPlay);
  }

  Map<String, dynamic> toJson() => state.toJson();

  void importFromJson(Map<String, dynamic> json) {
    update(AppSettingsModel.fromJson(json));
  }
}
