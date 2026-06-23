// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'background_config_model.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

_BackgroundConfigModel _$BackgroundConfigModelFromJson(
  Map<String, dynamic> json,
) => _BackgroundConfigModel(
  source:
      $enumDecodeNullable(_$BackgroundSourceEnumMap, json['source']) ??
      BackgroundSource.none,
  boxFit: $enumDecodeNullable(_$BoxFitEnumMap, json['boxFit']) ?? BoxFit.cover,
  maskOpacity: (json['maskOpacity'] as num?)?.toDouble() ?? 0.35,
  solidColor: json['solidColor'] == null
      ? const Color(0xFF141e30)
      : const HexColorConverter().fromJson(json['solidColor'] as String),
  gradientColors: json['gradientColors'] == null
      ? const [Color(0xFF141e30), Color(0xFF243b55), Color(0xFF141e30)]
      : const HexColorListConverter().fromJson(
          json['gradientColors'] as String,
        ),
  assetImagePath: json['assetImagePath'] as String?,
  localImagePath: json['localImagePath'] as String?,
  networkImageUrl: json['networkImageUrl'] as String?,
  currentBoxImageBase64: json['currentBoxImageBase64'] as String? ?? '',
  assetVideoPath: json['assetVideoPath'] as String?,
  localVideoPath: json['localVideoPath'] as String?,
  networkVideoUrl: json['networkVideoUrl'] as String?,
);

Map<String, dynamic> _$BackgroundConfigModelToJson(
  _BackgroundConfigModel instance,
) => <String, dynamic>{
  'source': _$BackgroundSourceEnumMap[instance.source]!,
  'boxFit': _$BoxFitEnumMap[instance.boxFit]!,
  'maskOpacity': instance.maskOpacity,
  'solidColor': const HexColorConverter().toJson(instance.solidColor),
  'gradientColors': const HexColorListConverter().toJson(
    instance.gradientColors,
  ),
  'assetImagePath': instance.assetImagePath,
  'localImagePath': instance.localImagePath,
  'networkImageUrl': instance.networkImageUrl,
  'currentBoxImageBase64': instance.currentBoxImageBase64,
  'assetVideoPath': instance.assetVideoPath,
  'localVideoPath': instance.localVideoPath,
  'networkVideoUrl': instance.networkVideoUrl,
};

const _$BackgroundSourceEnumMap = {
  BackgroundSource.none: 'none',
  BackgroundSource.color: 'color',
  BackgroundSource.gradient: 'gradient',
  BackgroundSource.localImage: 'localImage',
  BackgroundSource.assetImage: 'assetImage',
  BackgroundSource.networkImage: 'networkImage',
  BackgroundSource.assetVideo: 'assetVideo',
  BackgroundSource.localVideo: 'localVideo',
  BackgroundSource.networkVideo: 'networkVideo',
};

const _$BoxFitEnumMap = {
  BoxFit.fill: 'fill',
  BoxFit.contain: 'contain',
  BoxFit.cover: 'cover',
  BoxFit.fitWidth: 'fitWidth',
  BoxFit.fitHeight: 'fitHeight',
  BoxFit.none: 'none',
  BoxFit.scaleDown: 'scaleDown',
};
