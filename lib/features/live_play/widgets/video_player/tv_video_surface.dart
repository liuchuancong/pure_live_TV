import 'dart:async';

import 'package:dpad/dpad.dart';
import 'package:pure_live/app/router/app_routes.dart';
import 'package:pure_live/player/index.dart';
import 'package:pure_live/shared/theme/index.dart';
import 'package:pure_live/exports/package_export.dart';
import 'package:pure_live/features/live_play/controllers/live_play_controller.dart';
import 'package:pure_live/features/live_play/models/live_play_args.dart';
import 'package:pure_live/features/live_play/states/live_play_state.dart';
import 'package:pure_live/features/live_play/widgets/danmaku/danmaku_overlay.dart';
import 'package:pure_live/features/live_play/widgets/video_player/playback_failure_overlay.dart';
import 'package:pure_live/features/live_play/widgets/video_player/video_controller_panel.dart';
import 'package:pure_live/services/favorites/favorite_room_controller.dart';
import 'package:pure_live/shared/i18n/locale_helper.dart';
import 'package:pure_live/shared/utils/toast_util.dart';

/// Video surface: a Stack of the PlayerManager video layer, the flame_barrage
/// overlay, loading/error overlays and an auto-hiding D-pad control panel.
///
/// 遥控器分工（移植自老项目 live_play 的 `handleKeyNoPanel`）：
/// - 上 / 下：上一个 / 下一个频道（循环，走播放列表 / 观看历史）
/// - 左：双击关注 / 取消关注
/// - 右：打开播放列表面板
/// - 确认：呼出底部控制栏
///
/// 方向键在这里全部被消费，焦点不会跑出播放器，避免电视上「遥控器失灵」。
class TvVideoSurface extends ConsumerStatefulWidget {
  final LivePlayArgs args;

  const TvVideoSurface({super.key, required this.args});

  @override
  ConsumerState<TvVideoSurface> createState() => _TvVideoSurfaceState();
}

class _TvVideoSurfaceState extends ConsumerState<TvVideoSurface> {
  PlayerManager get _playerManager => GlobalPlayerService.instance.playerManager;

  /// 左键双击判定（老项目用 VideoConstants.doubleClickDuration = 500ms）。
  static const Duration _doubleClickWindow = Duration(milliseconds: 500);
  int _lastLeftTapAt = 0;
  Timer? _leftTapTimer;

  @override
  void dispose() {
    _leftTapTimer?.cancel();
    super.dispose();
  }

  LivePlayController get _controller =>
      ref.read(livePlayControllerProvider(widget.args).notifier);

  /// 按 [delta]（-1 上一个 / 1 下一个）切台。
  void _switchChannel(int delta) {
    final controller = _controller;
    final rooms = controller.channelRooms;
    final target = controller.relativeChannel(delta);
    if (target == null) {
      ToastUtil.show(i18nOr('ui_no_switchable_channel', '没有可切换的频道'));
      return;
    }
    // 换台沿用路由 replace，上一路播放会话会被正常释放。
    context.replace(
      AppRoutes.kLivePlay,
      extra: LivePlayArgs.fromRoom(target, playlist: rooms, showChannelBanner: true),
    );
  }

  /// 左键双击 = 关注 / 取消关注。
  void _handleLeftKey() {
    final room = ref.read(livePlayControllerProvider(widget.args)).room;
    if (room == null) return;
    final fav = ref.read(favoriteRoomControllerProvider.notifier);
    final isFavorite = fav.isFavorite(room);

    final now = DateTime.now().millisecondsSinceEpoch;
    final isDoubleClick = _lastLeftTapAt != 0 && now - _lastLeftTapAt < _doubleClickWindow.inMilliseconds;
    if (!isDoubleClick) {
      _lastLeftTapAt = now;
      ToastUtil.show(isFavorite ? i18nOr('ui_double_click_unfollow', '双击取消关注') : i18nOr('ui_double_click_follow', '双击关注'));
      _leftTapTimer?.cancel();
      _leftTapTimer = Timer(const Duration(milliseconds: 600), () => _lastLeftTapAt = 0);
      return;
    }

    _lastLeftTapAt = 0;
    _leftTapTimer?.cancel();
    if (isFavorite) {
      fav.removeRoom(room);
      ToastUtil.show(i18nOr('ui_unfollowed', '已取消关注'));
    } else {
      fav.addRoom(room);
      ToastUtil.show(i18n('followed'));
    }
  }

  /// 视频区方向键：命中即消费，摄像头（焦点）不会离开播放器。
  bool _handleDirection(TraversalDirection direction) {
    final controller = _controller;
    switch (direction) {
      case TraversalDirection.up:
        _switchChannel(-1);
        return true;
      case TraversalDirection.down:
        _switchChannel(1);
        return true;
      case TraversalDirection.left:
        _handleLeftKey();
        return true;
      case TraversalDirection.right:
        controller.togglePanel(LivePlayPanel.playlist);
        return true;
    }
  }

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
        onDirection: _handleDirection,
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
            // 上下键切台后的频道名提示条。
            if (state.showChannelBanner)
              Positioned(
                left: 0,
                right: 0,
                top: 64.sp,
                child: IgnorePointer(
                  child: Center(
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 24.sp, vertical: 12.sp),
                      decoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.7),
                        borderRadius: BorderRadius.circular(12.sp),
                        border: Border.all(color: tvTheme.focusColor.withValues(alpha: 0.6)),
                      ),
                      child: Text(
                        state.channelBanner!,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.t24W600.copyWith(color: Colors.white),
                      ),
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
