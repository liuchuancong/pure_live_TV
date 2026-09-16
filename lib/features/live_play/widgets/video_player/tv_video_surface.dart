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
      // The video area is NOT a d-pad node any more: the whole player is key
      // handled by [LivePlayPage], exactly like the reference player. Keys reach
      // it through the page-level [Focus], so nothing here competes for focus.
      Stack(
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
          // 房间信息 lives at the top of the screen, as in the reference player:
          // channel, streamer, platform, quality and line. The danmaku list that
          // used to sit in a side panel is gone — the danmaku are on the screen
          // already.
          if (!showError && state.room != null)
            Positioned(
              left: 0,
              right: 0,
              top: 0,
              child: IgnorePointer(
                child: Container(
                  height: 48.sp,
                  padding: EdgeInsets.symmetric(horizontal: 24.sp),
                  color: Colors.black.withValues(alpha: 0.45),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          <String>[
                            state.room!.title,
                            if (state.room!.nick.isNotEmpty) state.room!.nick,
                            if (state.room!.platform.isNotEmpty) state.room!.platform,
                            if (state.qualities.isNotEmpty) state.room!.platform.isEmpty ? '' : '',
                          ].where((part) => part.isNotEmpty).join('  ·  '),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.t16W500.copyWith(color: Colors.white),
                        ),
                      ),
                      if (state.qualities.isNotEmpty)
                        Text(
                          state.qualities[state.qualityIndex.clamp(0, state.qualities.length - 1)].quality,
                          style: AppTextStyles.t16W500.copyWith(color: Colors.white70),
                        ),
                      SizedBox(width: 16.sp),
                      Text(
                        i18n('multiview_line', args: {'index': ''}),
                        style: AppTextStyles.t16W500.copyWith(color: Colors.white70),
                      ),
                    ],
                  ),
                ),
              ),
            ),            // Channel name toast shown after an up/down switch.
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
