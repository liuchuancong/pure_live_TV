import 'page_settings_model.dart';
import 'package:flutter/material.dart';
import 'package:pure_live/shared/utils/hive_pref_util.dart';
import 'package:pure_live/services/settings/settings.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'page_settings_controller.g.dart';

@riverpod
class PageSettingsController extends _$PageSettingsController {
  static PageSettingsController get to => SettingsService.to.page;

  /// Page sizes outside this range cannot be rendered or stored: a stored 0 or
  /// negative value would empty every grid, and a huge value would ask the
  /// backend for a page the lists never use.
  static const int minPageSize = 1;
  static const int maxPageSize = 100;

  @override
  PageSettingsModel build() {
    final options = normalizePageSizeOptions(
      HivePrefUtil.getObject('page_size_options_raw', (json) => (json as List).cast<int>()) ??
          _getInitPageSizeOptions(),
    );
    return PageSettingsModel(
      showPageSizeSelector: HivePrefUtil.getBool('page_show_size_selector') ?? true,
      showGotoButton: HivePrefUtil.getBool('page_show_goto_button') ?? true,
      showScrollToTopBtn: HivePrefUtil.getBool('page_show_scroll_top') ?? true,
      defaultPageSize: normalizeDefaultPageSize(HivePrefUtil.getInt('page_default_size') ?? _getInitPageSize(), options),
      pageSizeOptions: options,
    );
  }

  static bool isValidPageSize(int value) => value >= minPageSize && value <= maxPageSize;

  /// Keeps only usable, de-duplicated sizes in ascending order; an empty or
  /// fully invalid list falls back to the platform defaults.
  static List<int> normalizePageSizeOptions(Iterable<int> values) {
    final normalized = values.where(isValidPageSize).toSet().toList()..sort();
    if (normalized.isNotEmpty) return normalized;
    return _getInitPageSizeOptions().where(isValidPageSize).toSet().toList()..sort();
  }

  /// Repairs a default size that is no longer part of the selectable options.
  static int normalizeDefaultPageSize(int value, Iterable<int> options) {
    final normalizedOptions = normalizePageSizeOptions(options);
    return normalizedOptions.contains(value) ? value : normalizedOptions.first;
  }

  void updateSettings(PageSettingsModel newModel) {
    final options = normalizePageSizeOptions(newModel.pageSizeOptions);
    state = newModel.copyWith(
      pageSizeOptions: options,
      defaultPageSize: normalizeDefaultPageSize(newModel.defaultPageSize, options),
    );
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
    updateSettings(PageSettingsModel.fromJson(json));
  }
}
