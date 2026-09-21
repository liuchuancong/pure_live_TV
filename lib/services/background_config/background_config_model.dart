import 'package:flutter/widgets.dart';
import 'package:pure_live/exports/common_export.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'background_config_model.freezed.dart';
part 'background_config_model.g.dart';

@freezed
abstract class BackgroundConfigModel with _$BackgroundConfigModel {
  const factory BackgroundConfigModel({
    @Default(BackgroundSource.none) BackgroundSource source,
    @Default(BoxFit.cover) BoxFit boxFit,
    @Default(0.35) double maskOpacity,
    /// 高斯模糊强度（sigma）；0 表示关闭。只作用于媒体类背景
    /// （图片/视频/海报帧），纯色与渐变模糊没有意义。
    @Default(0) double blurSigma,
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
