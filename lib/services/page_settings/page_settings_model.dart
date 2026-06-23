import 'package:freezed_annotation/freezed_annotation.dart';

part 'page_settings_model.freezed.dart';
part 'page_settings_model.g.dart';

@freezed
abstract class PageSettingsModel with _$PageSettingsModel {
  const factory PageSettingsModel({
    @Default(true) bool showPageSizeSelector,
    @Default(true) bool showGotoButton,
    @Default(true) bool showScrollToTopBtn,
    @Default(12) int defaultPageSize,
    @Default([12, 24, 36, 48]) List<int> pageSizeOptions,
  }) = _PageSettingsModel;

  factory PageSettingsModel.fromJson(Map<String, dynamic> json) => _$PageSettingsModelFromJson(json);
}
