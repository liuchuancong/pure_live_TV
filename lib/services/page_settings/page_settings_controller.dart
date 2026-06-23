import 'page_settings_model.dart';
import 'package:flutter/material.dart';
import 'package:pure_live/utils/hive_pref_util.dart';
import 'package:pure_live/services/settings/settings.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'page_settings_controller.g.dart';

@riverpod
class PageSettingsController extends _$PageSettingsController {
  static PageSettingsController get to => SettingsService.to.page;
  @override
  PageSettingsModel build() {
    return PageSettingsModel(
      showPageSizeSelector: HivePrefUtil.getBool('page_show_size_selector') ?? true,
      showGotoButton: HivePrefUtil.getBool('page_show_goto_button') ?? true,
      showScrollToTopBtn: HivePrefUtil.getBool('page_show_scroll_top') ?? true,
      defaultPageSize: HivePrefUtil.getInt('page_default_size') ?? _getInitPageSize(),
      pageSizeOptions:
          HivePrefUtil.getObject('page_size_options_raw', (json) => (json as List).cast<int>()) ??
          _getInitPageSizeOptions(),
    );
  }

  void updateSettings(PageSettingsModel newModel) {
    var validDefault = newModel.defaultPageSize;
    if (!newModel.pageSizeOptions.contains(validDefault)) {
      validDefault = newModel.pageSizeOptions.isNotEmpty ? newModel.pageSizeOptions.first : 12;
    }

    state = newModel.copyWith(defaultPageSize: validDefault);
    _persist();
  }

  void _persist() {
    HivePrefUtil.setBool('page_show_size_selector', state.showPageSizeSelector);
    HivePrefUtil.setBool('page_show_goto_button', state.showGotoButton);
    HivePrefUtil.setBool('page_show_scroll_top', state.showScrollToTopBtn);
    HivePrefUtil.setInt('page_default_size', state.defaultPageSize);
    HivePrefUtil.setObject('page_size_options_raw', state.pageSizeOptions);
  }

  static int _getInitPageSize() {
    final width = WidgetsBinding.instance.platformDispatcher.views.first.physicalSize.width;
    final pixelRatio = WidgetsBinding.instance.platformDispatcher.views.first.devicePixelRatio;
    return (width / (pixelRatio > 0 ? pixelRatio : 1)) > 960 ? 20 : 12;
  }

  static List<int> _getInitPageSizeOptions() {
    final width = WidgetsBinding.instance.platformDispatcher.views.first.physicalSize.width;
    final pixelRatio = WidgetsBinding.instance.platformDispatcher.views.first.devicePixelRatio;
    return (width / (pixelRatio > 1 ? pixelRatio : 1)) > 960 ? [20, 40, 60, 80] : [12, 24, 36, 48];
  }

  Map<String, dynamic> toJson() => state.toJson();

  void importFromJson(Map<String, dynamic> json) {
    state = PageSettingsModel.fromJson(json);
    _persist();
  }
}
