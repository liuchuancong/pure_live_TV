import 'package:dpad/dpad.dart';
import 'package:pure_live/player/index.dart';
import 'package:pure_live/shared/theme/index.dart';
import 'package:pure_live/exports/package_export.dart';
import 'package:pure_live/features/live_play/controllers/live_play_controller.dart';
import 'package:pure_live/features/live_play/models/live_play_args.dart';
import 'package:pure_live/features/live_play/states/live_play_state.dart';
import 'package:pure_live/features/live_play/widgets/danmaku/danmaku_overlay.dart';
import 'package:pure_live/features/live_play/widgets/video_player/playback_failure_overlay.dart';
import 'package:pure_live/features/live_play/widgets/video_player/video_controller_panel.dart';
import 'package:pure_live/shared/i18n/locale_helper.dart';

/// Video surface: a Stack of the PlayerManager video layer, the flame_barrage
/// overlay, loading/error overlays and an auto-hiding D-pad control panel.
///
/// Focus structure: the video placeholder, error overlay and control panel are
/// Stack siblings (not nested) so the D-pad can reach the panel buttons.
class TvVideoSurface extends ConsumerStatefulWidget {
  final LivePlayArgs args;

  const TvVideoSurface({super.key, required this.args});

  @override
  ConsumerState<TvVideoSurface> createState() => _TvVideoSurfaceState();
}

class _TvVideoSurfaceState extends ConsumerState<TvVideoSurface> {
  PlayerManager get _playerManager => GlobalPlayerService.instance.playerManager;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(livePlayControllerProvider(widget.args));
    final controller = ref.read(livePlayControllerProvider(widget.args).notifier);
    final tvTheme = context.tvTheme;

    final bool showLoading =
        state.status == LivePlayStatus.loadingDetail ||
        state.status == LivePlayStatus.preparing ||
        state.status == LivePlayStatus.buffering;
    final bool showError = state.status == LivePlayStatus.error;

    Widget video;
    if (_playerManager.initialized && !showError) {
      video = _playerManager.getVideoWidget(state.fitIndex, fitList: kLivePlayFitList);
    } else {
      video = Container(color: Colors.black);
    }

    final children = <Widget>[
      // 视频层 + 弹幕层 + 加载指示：整体作为视频区的 D-pad 焦点占位。
      DpadFocusable(
        autofocus: true,
        excludeChildFocus: true,
        effects: const [],
        onSelect: controller.toggleControls,
        onFocusChange: (focused) {
          if (focused && state.showControls) controller.keepControlsAlive();
        },
        child: Stack(
          fit: StackFit.expand,
          children: [
            video,
            DanmakuOverlay(args: widget.args),
            if (showLoading && !showError)
              Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(strokeWidth: 2),
                    SizedBox(height: 12.sp),
                    Text(
                      state.status == LivePlayStatus.loadingDetail ? i18n('ui_loading_room_info') : i18n('ui_buffering'),
                      style: AppTextStyles.t16W500.copyWith(color: tvTheme.secondaryTextColor),
                    ),
                  ],
                ),
              ),
            // 房间标题信息条（无控制面板时展示）。
            if (!state.showControls && !showError && state.room != null)
              Positioned(
                left: 24.sp,
                top: 16.sp,
                child: IgnorePointer(
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12.sp, vertical: 6.sp),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.35),
                      borderRadius: BorderRadius.circular(8.sp),
                    ),
                    child: Text(
                      state.room!.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.t14W500.copyWith(color: Colors.white),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    ];

    if (showError) {
      children.add(
        Positioned.fill(
          child: PlaybackFailureOverlay(
            message: state.errorMessage ?? i18n('multiview_play_failed'),
            onRetry: controller.retry,
            onRefreshRoom: controller.refreshRoom,
          ),
        ),
      );
    } else if (state.showControls) {
      children.add(Positioned(left: 0, right: 0, bottom: 0, child: VideoControllerPanel(args: widget.args)));
    }

    return Stack(fit: StackFit.expand, children: children);
  }
}
