import 'page_settings_model.dart';
import 'package:flutter/foundation.dart';
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

  /// Keeps only usable, de-duplicated sizes in ascending order; an empty list,
  /// or the set earlier builds wrote, falls back to the common multiples.
  static List<int> normalizePageSizeOptions(Iterable<int> values) {
    final normalized = values.where(isValidPageSize).toSet().toList()..sort();
    if (normalized.isEmpty || listEquals(normalized, _legacyPageSizeOptions)) {
      return _getInitPageSizeOptions();
    }
    return normalized;
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

  /// Page sizes that fill whole rows for every column count the grid offers.
  ///
  /// The grid can be set to 4 or 5 columns, so a page size has to divide by
  /// both or the last row comes out ragged - 12 items in a 5-column grid end as
  /// a row of two, which is what the old options (multiples of 4 only) did.
  /// Multiples of 20 divide evenly by both.
  static const List<int> commonPageSizes = <int>[20, 40, 60, 80];

  /// The list earlier builds offered, still sitting in some devices' storage.
  ///
  /// Recognised and replaced on read rather than migrated by version: it is the
  /// only value those builds could ever produce, so matching it loses nothing a
  /// user chose.
  static const List<int> _legacyPageSizeOptions = <int>[12, 24, 36, 48];

  static int _getInitPageSize() => commonPageSizes.first;

  static List<int> _getInitPageSizeOptions() => List<int>.of(commonPageSizes);

  Map<String, dynamic> toJson() => state.toJson();

  void importFromJson(Map<String, dynamic> json) {
    updateSettings(PageSettingsModel.fromJson(json));
  }
}
