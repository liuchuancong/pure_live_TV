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

    /// 背景模糊度（高斯 sigma），0 表示不模糊。
    @Default(0.0) double blur,

    /// 是否按 [autoSwitchIntervalHours] 自动更换壁纸（仅对随机网图源有意义）。
    @Default(false) bool autoSwitch,

    /// 自动更换间隔（小时）。
    @Default(6) int autoSwitchIntervalHours,

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
