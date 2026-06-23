import 'package:flutter/widgets.dart';
import 'package:pure_live/utils/color_converter.dart';
import 'package:pure_live/consts/back_ground_source.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'background_config_model.freezed.dart';
part 'background_config_model.g.dart';

@freezed
abstract class BackgroundConfigModel with _$BackgroundConfigModel {
  const factory BackgroundConfigModel({
    @Default(BackgroundSource.none) BackgroundSource source,
    @Default(BoxFit.cover) BoxFit boxFit,
    @Default(0.35) double maskOpacity,
    @HexColorConverter() @Default(Color(0xFF141e30)) Color solidColor,
    @HexColorListConverter()
    @Default([Color(0xFF141e30), Color(0xFF243b55), Color(0xFF141e30)])
    List<Color> gradientColors,
    String? assetImagePath,
    String? localImagePath,
    String? networkImageUrl,
    @Default('') String currentBoxImageBase64,
    String? assetVideoPath,
    String? localVideoPath,
    String? networkVideoUrl,
  }) = _BackgroundConfigModel;

  factory BackgroundConfigModel.fromJson(Map<String, dynamic> json) => _$BackgroundConfigModelFromJson(json);
}
