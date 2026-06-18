import 'package:flutter/material.dart';
import 'package:pure_live/services/background/back_ground_source.dart';

class BackgroundConfigModel {
  final BackgroundSource source;
  final BoxFit boxFit;
  final double maskOpacity;

  // 纯色
  final Color solidColor;

  // 渐变
  final List<Color> gradientColors;

  // 图片路径
  final String? assetImagePath;
  final String? localImagePath;
  final String? networkImageUrl;
  final String currentBoxImageBase64;

  // 视频路径
  final String? assetVideoPath;
  final String? localVideoPath;
  final String? networkVideoUrl;

  BackgroundConfigModel({
    required this.source,
    required this.boxFit,
    required this.maskOpacity,
    required this.solidColor,
    required this.gradientColors,
    this.assetImagePath,
    this.localImagePath,
    this.networkImageUrl,
    required this.currentBoxImageBase64,
    this.assetVideoPath,
    this.localVideoPath,
    this.networkVideoUrl,
  });
}
