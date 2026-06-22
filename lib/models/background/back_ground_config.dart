import 'package:flutter/material.dart';
import 'package:pure_live/consts/back_ground_source.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'back_ground_config.freezed.dart';

@freezed
abstract class BackgroundConfigModel with _$BackgroundConfigModel {
  const factory BackgroundConfigModel({
    required BackgroundSource source,
    required BoxFit boxFit,
    required double maskOpacity,
    required Color solidColor,
    required List<Color> gradientColors,
    String? assetImagePath,
    String? localImagePath,
    String? networkImageUrl,
    required String currentBoxImageBase64,
    String? assetVideoPath,
    String? localVideoPath,
    String? networkVideoUrl,
  }) = _BackgroundConfigModel;
}
