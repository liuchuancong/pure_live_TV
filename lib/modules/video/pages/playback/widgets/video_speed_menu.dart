import 'package:pure_live/exports/exports.dart';
import 'package:pure_live/modules/vod/controllers/video_player_controller.dart';

/// newBV's speed tab: one entry per preset rate, the live one checked.
class VideoSpeedMenu extends ConsumerWidget {
  const VideoSpeedMenu({super.key, required this.onClose});

  final VoidCallback onClose;

  static String _label(double speed) =>
      speed == speed.roundToDouble() ? '${speed.toInt()}.0x' : '${speed}x';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(videoPlayerControllerProvider);
    final controller = ref.read(videoPlayerControllerProvider.notifier);
    final tvTheme = context.tvTheme;
    final accent = tvTheme.focusColor;

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
                Icon(Icons.speed_rounded, size: 26.ts(context), color: accent),
                SizedBox(width: 10.ts(context)),
                Expanded(
                  child: Text(
                    i18n('video_speed_title'),
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
          for (final speed in VideoPlayerController.speedSteps)
            Padding(
              padding: EdgeInsets.only(left: 12.sp, right: 12.sp, bottom: 8.sp),
              child: TvFocusable(
                autofocus: speed == state.speed,
                onTap: () {
                  controller.setSpeed(speed);
                  onClose();
                },
                builder: (context, focused, child) {
                  final isCurrent = speed == state.speed;
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
                            _label(speed),
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
