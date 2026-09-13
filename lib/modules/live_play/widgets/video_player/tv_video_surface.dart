import 'package:dpad/dpad.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil_plus/flutter_screenutil_plus.dart';
import 'package:pure_live/modules/live_play/controllers/live_play_controller.dart';
import 'package:pure_live/modules/live_play/models/live_play_args.dart';
import 'package:pure_live/modules/live_play/states/live_play_state.dart';
import 'package:pure_live/modules/live_play/widgets/danmaku/danmaku_overlay.dart';
import 'package:pure_live/modules/live_play/widgets/video_player/playback_failure_overlay.dart';
import 'package:pure_live/modules/live_play/widgets/video_player/video_controller_panel.dart';
import 'package:pure_live/player/global_player_service.dart';
import 'package:pure_live/player/core/player_manager.dart';
import 'package:pure_live/theme/styles/styles.dart';
import 'package:pure_live/theme/tv_theme_x.dart';

/// TV 视频渲染区（移植自 pure_live video_player.dart / video_controller.dart）。
///
/// 布局为 Stack：PlayerManager 视频层 + flame_barrage 弹幕层 +
/// 加载/错误覆盖层 + 自动隐藏的 D-pad 控制面板。
/// TV 交互约定：视频区按 OK 键呼出/隐藏控制面板。
///
/// 焦点结构：视频占位（DpadFocusable）、错误覆盖层、控制面板是 Stack 的
/// 兄弟节点（而非嵌套），保证面板按钮能被 D-pad 遍历到。
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
                      state.status == LivePlayStatus.loadingDetail ? '正在加载房间信息...' : '正在缓冲...',
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
            message: state.errorMessage ?? '播放失败',
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
