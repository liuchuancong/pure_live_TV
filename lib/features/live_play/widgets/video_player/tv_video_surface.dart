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
/// Remote key layout, ported from handleKeyNoPanel in the legacy app:
/// - Up / Down: previous / next channel, wrapping through the playlist or
///   watch history
/// - Left: double press to follow or unfollow
/// - Right: open the playlist panel
/// - OK: show the bottom control bar
///
/// Every direction key is consumed here so focus cannot escape the player and
/// leave the remote apparently dead.
class TvVideoSurface extends ConsumerStatefulWidget {
  final LivePlayArgs args;

  const TvVideoSurface({super.key, required this.args});

  @override
  ConsumerState<TvVideoSurface> createState() => _TvVideoSurfaceState();
}

class _TvVideoSurfaceState extends ConsumerState<TvVideoSurface> {
  /// The player manager, or null until [GlobalPlayerService] has finished
  /// initializing.
  ///
  /// `GlobalPlayerService.playerManager` is a `late final` field: reading it
  /// before initialization throws `LateInitializationError`, and a build that
  /// throws tears down whatever the previous build had mounted — which disposed
  /// media_kit's video output and made the next successful frame create a new
  /// one. That is the whole `VideoOutputManager.create` → `dispose` →
  /// `Resize 0x0` → `Surface.release()` NPE sequence in logcat. Never read the
  /// field without this check.
  PlayerManager? get _playerManagerOrNull =>
      GlobalPlayerService.instance.initialized ? GlobalPlayerService.instance.playerManager : null;

  /// Double-press window for the left key, 500 ms in the legacy app.
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

  /// Switches channel by [delta] (-1 previous, 1 next).
  void _switchChannel(int delta) {
    final controller = _controller;
    final rooms = controller.channelRooms;
    final target = controller.relativeChannel(delta);
    if (target == null) {
      ToastUtil.show(i18nOr('ui_no_switchable_channel', 'No channel available to switch to'));
      return;
    }
    // Channel switching uses a route replace, so the previous session is released.
    context.replace(
      AppRoutes.kLivePlay,
      extra: LivePlayArgs.fromRoom(target, playlist: rooms, showChannelBanner: true),
    );
  }

  /// Double press on Left follows or unfollows.
  void _handleLeftKey() {
    final room = ref.read(livePlayControllerProvider(widget.args)).room;
    if (room == null) return;
    final fav = ref.read(favoriteRoomControllerProvider.notifier);
    final isFavorite = fav.isFavorite(room);

    final now = DateTime.now().millisecondsSinceEpoch;
    final isDoubleClick = _lastLeftTapAt != 0 && now - _lastLeftTapAt < _doubleClickWindow.inMilliseconds;
    if (!isDoubleClick) {
      _lastLeftTapAt = now;
      ToastUtil.show(isFavorite ? i18nOr('ui_double_click_unfollow', 'Double click to unfollow') : i18nOr('ui_double_click_follow', 'Double click to follow'));
      _leftTapTimer?.cancel();
      _leftTapTimer = Timer(const Duration(milliseconds: 600), () => _lastLeftTapAt = 0);
      return;
    }

    _lastLeftTapAt = 0;
    _leftTapTimer?.cancel();
    if (isFavorite) {
      fav.removeRoom(room);
      ToastUtil.show(i18nOr('ui_unfollowed', 'Unfollowed'));
    } else {
      fav.addRoom(room);
      ToastUtil.show(i18n('followed'));
    }
  }

  /// Direction keys inside the video area are consumed on match, so focus never
  /// leaves the player.
  bool _handleDirection(TraversalDirection direction) {
    final controller = _controller;
    // While the control layer is up it owns the arrow keys: the layer's selected
    // index is steered with Left/Right, and letting the video node answer them
    // too made the bar look frozen (the keys switched channels instead).
    if (ref.read(livePlayControllerProvider(widget.args)).showControls) return false;
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

    // The video widget stays mounted for the whole session, and the surface is
    // simply black until the player service is up.
    //
    // It used to be replaced by a black `Container` whenever `showError` was
    // true, and the manager getter threw while the service was still starting.
    // Either way the previously mounted `Video` was torn down, which disposed
    // media_kit's video output and made the next frame create a new one — the
    // `VideoOutputManager.create` → `dispose` → `Resize 0x0` → `Surface.release()`
    // NPE sequence in logcat (an output destroyed before it ever had a surface).
    // The failure overlay is drawn on top of the surface instead.
    final PlayerManager? manager = _playerManagerOrNull;
    final Widget video = manager != null
        ? manager.getVideoWidget(state.fitIndex, fitList: kLivePlayFitList)
        : const ColoredBox(color: Colors.black);

    final children = <Widget>[
      // Video, danmaku and the loading indicator together act as the D-pad focus
      // placeholder for the video area.
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
            // Room title bar, shown while no control panel is open.
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
            // Channel name toast shown after an up/down switch.
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
