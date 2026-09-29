import 'package:freezed_annotation/freezed_annotation.dart';
part 'video_settings_model.freezed.dart';
part 'video_settings_model.g.dart';

@freezed
abstract class VideoSettingsModel with _$VideoSettingsModel {
  const factory VideoSettingsModel({
    /// The rendition (B站 qn) the video player prefers on open. 0 = the play-url
    /// answer's own pick.
    @Default(0) int preferredQuality,

    /// Playback rate a video starts at when nothing was restored.
    @Default(1.0) double defaultSpeed,

    /// Card tap opens the detail page first (newBV's 显示视频详情); off = straight
    /// into the player.
    @Default(true) bool showVideoDetail,

    /// newBV's persistent mini progress line on the player's bottom edge.
    @Default(true) bool persistentProgress,

    /// The video section the sidebar lands on: index into [VideoSection.values].
    @Default(0) int startSection,

    /// The video home's landing top tab: 0 动态 / 1 推荐 / 2 热门.
    @Default(1) int homeTabIndex,

    /// The personal page's landing tab: index into its tab list.
    @Default(0) int personalTabIndex,
  }) = _VideoSettingsModel;

  factory VideoSettingsModel.fromJson(Map<String, dynamic> json) => _$VideoSettingsModelFromJson(json);
}
