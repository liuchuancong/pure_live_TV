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

    /// 当前在线壁纸的图片直链。
    ///
    /// `currentBoxImageBase64` 才是真正渲染的那份（本机/内置/在线三种图片源都走它），
    /// 这里额外留一份直链是为了「下载壁纸」「记住上次换壁纸时间」这类操作，
    /// 不必再从 base64 还原。
    @Default('') String currentImageUrl,

    /// 上一次更换在线壁纸的时间。
    ///
    /// 自动换壁纸的定时器已经由后台任务调度器接管，判断「该不该换」需要跨启动
    /// 的时间戳，所以必须持久化（对应 iTab 的 `wallpaper.time`）。
    DateTime? lastSwitchAt,

    /// 最近换过的在线壁纸直链（去重，新的在前），供「上一张」翻回去。
    @Default(<String>[]) List<String> recentImageUrls,

    /// 用户手填的图片直链（iTab「自定义壁纸 → 使用在线图片链接」）。
    ///
    /// 与 [networkImageUrl] 的区别：那个存的是刚下载成功的地址，这个是用户输入框
    /// 里的原文。分开存才能在拉取失败时把用户输的地址留在输入框里，不用重敲。
    @Default('') String customImageUrl,

    /// 用户手填的在线视频直链（动态壁纸）。
    @Default('') String customVideoUrl,

    /// 在线动态壁纸接口返回的封面图，`TvScaffold` 的占位/预览用得上。
    String? networkVideoCover,

    /// 上一次用过的在线视频图源下标（[BackgroundVideoSources]）。
    @Default(0) int videoSourceIndex,

    /// 上一次用过的在线视频分类下标。
    @Default(0) int videoTagIndex,

    /// 用户自定义的动态壁纸接口地址（支持 `{page}` `{tag}` `{random}` 占位符）。
    ///
    /// 内置公开接口的 CDN 很不稳定，这条是让用户接自己后端的口子：
    /// 只要响应里有 `url`/`video` 字段就被认成视频，`cover`/`thumb` 被认成封面。
    @Default('') String customVideoApiUrl,
  }) = _BackgroundConfigModel;

  factory BackgroundConfigModel.fromJson(Map<String, dynamic> json) => _$BackgroundConfigModelFromJson(json);
}
