import 'package:freezed_annotation/freezed_annotation.dart';
part 'video_settings_model.freezed.dart';
part 'video_settings_model.g.dart';

@freezed
abstract class VideoSettingsModel with _$VideoSettingsModel {
  const factory VideoSettingsModel({
    /// answer's own pick.
    @Default(0) int preferredQuality,

    /// Playback rate a video starts at when nothing was restored.
    @Default(1.0) double defaultSpeed,

    /// into the player.
    @Default(true) bool showVideoDetail,

    /// newBV's persistent mini progress line on the player's bottom edge.
    @Default(true) bool persistentProgress,

    /// The video section the sidebar lands on: index into [VideoSection.values].
    @Default(0) int startSection,

    @Default(1) int homeTabIndex,

    /// The personal page's landing tab: index into its tab list.
    @Default(0) int personalTabIndex,

    /// newBV's ClosedCaptionMenu appearance knobs, applied live to the CC
    /// overlay. [subtitleFontSize] is a design size (8-48),
    /// [subtitleBgOpacity] the line background alpha (0-1), and
    /// [subtitleBottomPadding] extra offset (0-48) above the base position.
    @Default(20) int subtitleFontSize,
    @Default(0.55) double subtitleBgOpacity,
    @Default(0) int subtitleBottomPadding,

    /// newBV's PictureMenu 宽高比: 0 = 默认 (native), 1 = 4:3, 2 = 16:9. The
    /// last two stretch the picture into a fixed-ratio box.
    @Default(0) int aspectRatioMode,
  }) = _VideoSettingsModel;

  factory VideoSettingsModel.fromJson(Map<String, dynamic> json) => _$VideoSettingsModelFromJson(json);
}
