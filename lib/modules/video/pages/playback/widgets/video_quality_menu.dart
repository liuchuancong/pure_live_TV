import 'package:media_core/media_core.dart';
import 'package:pure_live/exports/exports.dart';
import 'package:pure_live/modules/vod/api/bilibili_music_api.dart';
import 'package:pure_live/modules/vod/controllers/video_player_controller.dart';

/// The quality menu, one entry per rendition the current stream answer ships.
class VideoQualityMenu extends ConsumerWidget {
  const VideoQualityMenu({super.key, required this.onClose});

  final VoidCallback onClose;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(videoPlayerControllerProvider);
    final controller = ref.read(videoPlayerControllerProvider.notifier);
    final tvTheme = context.tvTheme;
    final accent = tvTheme.focusColor;
    final aspectMode = ref.watch(videoSettingsControllerProvider.select((m) => m.aspectRatioMode));
    void setAspect(int mode) {
      final settings = ref.read(videoSettingsControllerProvider);
      ref.read(videoSettingsControllerProvider.notifier).updateSettings(
        settings.copyWith(aspectRatioMode: mode),
      );
    }

    const aspectOptions = [(0, 'video_aspect_default'), (1, '4:3'), (2, '16:9')];

    return Container(
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.86),
        borderRadius: BorderRadius.circular(20.ts(context)),
        border: Border.all(color: accent.withValues(alpha: 0.5)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: EdgeInsets.all(16.ts(context)),
            child: Row(
              children: [
                Icon(Icons.high_quality_outlined, size: 26.ts(context), color: accent),
                SizedBox(width: 10.ts(context)),
                Expanded(
                  child: Text(
                    i18n('video_quality'),
                    style: AppTextStyles.t18.copyWith(fontWeight: FontWeight.w600, color: Colors.white),
                  ),
                ),
                TvIconButton(
                  icon: const Icon(Icons.close_rounded),
                  size: TvIconButtonSize.small,
                  isSecondary: true,
                  onTap: onClose,
                ),
              ],
            ),
          ),
          for (final option in state.qualityOptions)
            Padding(
              padding: EdgeInsets.only(left: 12.sp, right: 12.sp, bottom: 8.sp),
              child: TvFocusable(
                autofocus: option.quality == state.quality,
                onTap: () {
                  controller.switchQuality(option.quality);
                  onClose();
                },
                builder: (context, focused, child) {
                  final isCurrent = option.quality == state.quality;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 120),
                    height: 56.ts(context),
                    padding: EdgeInsets.symmetric(horizontal: 14.ts(context)),
                    decoration: BoxDecoration(
                      color: isCurrent ? accent.withValues(alpha: 0.22) : Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(12.ts(context)),
                      border: Border.all(color: focused ? accent : Colors.transparent, width: 2.ts(context)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            BilibiliMusicApi.qualityLabel(option.quality).isEmpty
                                ? '${option.quality}'
                                : BilibiliMusicApi.qualityLabel(option.quality),
                            style: AppTextStyles.t16.copyWith(
                              fontWeight: FontWeight.w500,
                              color: isCurrent ? accent : Colors.white,
                            ),
                          ),
                        ),
                        if (isCurrent) Icon(Icons.check_rounded, size: 22.ts(context), color: accent),
                      ],
                    ),
                  );
                },
              ),
            ),
          Padding(
            padding: EdgeInsets.only(left: 16.ts(context), top: 4.ts(context), bottom: 8.ts(context)),
            child: Row(
              children: [
                Icon(Icons.aspect_ratio_rounded, size: 22.ts(context), color: accent),
                SizedBox(width: 8.ts(context)),
                Text(
                  i18n('video_aspect_title'),
                  style: AppTextStyles.t16.copyWith(fontWeight: FontWeight.w600, color: Colors.white),
                ),
              ],
            ),
          ),
          for (final (mode, labelKey) in aspectOptions)
            Padding(
              padding: EdgeInsets.only(left: 12.sp, right: 12.sp, bottom: 8.sp),
              child: TvFocusable(
                // Only autofocus when there is no quality row above to claim it —
                // two autofocus nodes in one menu fight over the opening highlight.
                autofocus: mode == aspectMode && state.qualityOptions.isEmpty,
                onTap: () => setAspect(mode),
                builder: (context, focused, child) {
                  final isCurrent = mode == aspectMode;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 120),
                    height: 56.ts(context),
                    padding: EdgeInsets.symmetric(horizontal: 14.ts(context)),
                    decoration: BoxDecoration(
                      color: isCurrent ? accent.withValues(alpha: 0.22) : Colors.white.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(12.ts(context)),
                      border: Border.all(color: focused ? accent : Colors.transparent, width: 2.ts(context)),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            labelKey.startsWith('video_') ? i18n(labelKey) : labelKey,
                            style: AppTextStyles.t16.copyWith(
                              fontWeight: FontWeight.w500,
                              color: isCurrent ? accent : Colors.white,
                            ),
                          ),
                        ),
                        if (isCurrent) Icon(Icons.check_rounded, size: 22.ts(context), color: accent),
                      ],
                    ),
                  );
                },
              ),
            ),
          SizedBox(height: 8.ts(context)),
        ],
      ),
    );
  }
}
