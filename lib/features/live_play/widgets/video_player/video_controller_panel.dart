import 'package:dpad/dpad.dart';
import 'package:pure_live/shared/theme/index.dart';
import 'package:pure_live/exports/package_export.dart';
import 'package:pure_live/features/live_play/controllers/live_play_controller.dart';
import 'package:pure_live/features/live_play/models/live_play_args.dart';
import 'package:pure_live/features/live_play/states/live_play_state.dart';
import 'package:pure_live/services/danmaku_settings/danmaku_settings_controller.dart';

/// Bottom control bar of the video area, driven entirely by D-pad focus.
class VideoControllerPanel extends ConsumerStatefulWidget {
  final LivePlayArgs args;

  const VideoControllerPanel({super.key, required this.args});

  @override
  ConsumerState<VideoControllerPanel> createState() => _VideoControllerPanelState();
}

class _VideoControllerPanelState extends ConsumerState<VideoControllerPanel> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(livePlayControllerProvider(widget.args));
    final controller = ref.read(livePlayControllerProvider(widget.args).notifier);
    final danmakuSettings = ref.watch(danmakuSettingsControllerProvider);
    final danmakuNotifier = ref.read(danmakuSettingsControllerProvider.notifier);
    final tvTheme = context.tvTheme;

    final bool playing = state.status == LivePlayStatus.playing || state.status == LivePlayStatus.buffering;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topCenter,
          colors: [Colors.black.withValues(alpha: 0.85), Colors.black.withValues(alpha: 0.0)],
        ),
      ),
      padding: EdgeInsets.symmetric(horizontal: 24.sp, vertical: 16.sp),
      child: Row(
        children: [
          _PanelButton(
            icon: playing ? Icons.pause : Icons.play_arrow,
            label: playing ? '暂停' : '播放',
            autofocus: true,
            onFocusChange: (_) => controller.keepControlsAlive(),
            onSelect: () {
              controller.keepControlsAlive();
              controller.togglePlayPause();
            },
          ),
          SizedBox(width: 16.sp),
          _PanelButton(
            icon: Icons.volume_down,
            label: '音量-',
            onFocusChange: (_) => controller.keepControlsAlive(),
            onSelect: () {
              controller.keepControlsAlive();
              controller.volumeDown();
            },
          ),
          SizedBox(width: 16.sp),
          _PanelButton(
            icon: Icons.volume_up,
            label: '音量+',
            onFocusChange: (_) => controller.keepControlsAlive(),
            onSelect: () {
              controller.keepControlsAlive();
              controller.volumeUp();
            },
          ),
          SizedBox(width: 16.sp),
          _PanelButton(
            icon: Icons.aspect_ratio,
            label: kLivePlayFitLabels[state.fitIndex.clamp(0, kLivePlayFitLabels.length - 1)],
            onFocusChange: (_) => controller.keepControlsAlive(),
            onSelect: () {
              controller.keepControlsAlive();
              controller.cycleFit();
            },
          ),
          SizedBox(width: 16.sp),
          _PanelButton(
            icon: Icons.subtitles,
            label: danmakuSettings.hideDanmaku || !danmakuSettings.enableDanmakuDisplay ? '弹幕关' : '弹幕开',
            onFocusChange: (_) => controller.keepControlsAlive(),
            onSelect: () {
              controller.keepControlsAlive();
              final next = danmakuSettings.copyWith(
                enableDanmakuDisplay: !danmakuSettings.enableDanmakuDisplay || danmakuSettings.hideDanmaku,
                hideDanmaku: false,
              );
              danmakuNotifier.updateSettings(next);
            },
          ),
          SizedBox(width: 16.sp),
          _PanelButton(
            icon: Icons.refresh,
            label: '重试',
            onFocusChange: (_) => controller.keepControlsAlive(),
            onSelect: () {
              controller.keepControlsAlive();
              controller.retry();
            },
          ),
          const Spacer(),
          Text(
            '${(state.volume.clamp(0.0, 1.0) * 100).round()}%',
            style: AppTextStyles.t18W500.copyWith(color: tvTheme.secondaryTextColor),
          ),
          SizedBox(width: 16.sp),
        ],
      ),
    );
  }
}

class _PanelButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onSelect;
  final ValueChanged<bool> onFocusChange;
  final bool autofocus;

  const _PanelButton({
    required this.icon,
    required this.label,
    required this.onSelect,
    required this.onFocusChange,
    this.autofocus = false,
  });

  @override
  Widget build(BuildContext context) {
    final tvTheme = context.tvTheme;
    return DpadFocusable(
      autofocus: autofocus,
      effects: [
        DpadScaleEffect(scale: 1.05),
        DpadGlowEffect(color: tvTheme.focusColor.withValues(alpha: 0.5)),
      ],
      onFocusChange: onFocusChange,
      onSelect: onSelect,
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: 18.sp, vertical: 10.sp),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(10.sp),
          border: Border.all(color: Colors.white.withValues(alpha: 0.18)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 20.sp, color: Colors.white),
            SizedBox(width: 8.sp),
            Text(label, style: AppTextStyles.t16W500.copyWith(color: Colors.white)),
          ],
        ),
      ),
    );
  }
}
