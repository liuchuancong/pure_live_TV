// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'page_settings_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_PageSettingsModel _$PageSettingsModelFromJson(Map<String, dynamic> json) =>
    _PageSettingsModel(
      showPageSizeSelector: json['showPageSizeSelector'] as bool? ?? true,
      showGotoButton: json['showGotoButton'] as bool? ?? true,
      showScrollToTopBtn: json['showScrollToTopBtn'] as bool? ?? true,
      defaultPageSize: (json['defaultPageSize'] as num?)?.toInt() ?? 12,
      pageSizeOptions:
          (json['pageSizeOptions'] as List<dynamic>?)
              ?.map((e) => (e as num).toInt())
              .toList() ??
          const [12, 24, 36, 48],
    );

Map<String, dynamic> _$PageSettingsModelToJson(_PageSettingsModel instance) =>
    <String, dynamic>{
      'showPageSizeSelector': instance.showPageSizeSelector,
      'showGotoButton': instance.showGotoButton,
      'showScrollToTopBtn': instance.showScrollToTopBtn,
      'defaultPageSize': instance.defaultPageSize,
      'pageSizeOptions': instance.pageSizeOptions,
    };
